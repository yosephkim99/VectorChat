from qdrant_client import QdrantClient, models  
from qdrant_client.models import Distance, VectorParams, PointIdsList
#from sentence_transformers import SentenceTransformer
from FlagEmbedding import BGEM3FlagModel
from uuid import uuid4
import Function
import warnings

# docker run -p 6333:6333 -p 6334:6334 -v "D:/AIRsViewr/DATA:/qdrant/storage" qdrant/qdrant

# dense 공간
Rv_VecCf = {                       
    "q_vec": VectorParams(size=1024, distance=Distance.COSINE),
    "a_vec": VectorParams(size=1024, distance=Distance.COSINE),
    "qa_vec": VectorParams(size=1024, distance=Distance.COSINE),
}

print("▶▶▶ Qdrant DB 모듈 실행, Qdrant_DIR =", Function.QRDANT_NAME)
#Rv_Clint = QdrantClient(host="localhost", port=6333)
Rv_Clint = QdrantClient(url="http://localhost:6333")
if not Rv_Clint.collection_exists(collection_name=Function.QRDANT_NAME):
    Rv_Clint.create_collection(
        collection_name=Function.QRDANT_NAME, 
        #vectors_config=VectorParams(size=1024, distance=Distance.COSINE)
        vectors_config=Rv_VecCf,
        sparse_vectors_config={"text": {}}
    )
#Rv_Model = SentenceTransformer(Function.EMBED_MODEL) 
Rv_Model = BGEM3FlagModel(Function.EMBED_MODEL, use_fp16=True)
print("▶▶▶ 컬렉션 객체 생성 완료:", Function.QRDANT_NAME)

warnings.filterwarnings("ignore", message="You're using a XLMRobertaTokenizerFast tokenizer. Please note that with a fast tokenizer, using the `__call__` method is faster than using a method to encode the text followed by a call to the `pad` method to get a padded encoding.")

# 중복 체크
def Def_AlrdExist(Id_DHash, Iq_Dense, Is_Score):
    # 해시 중복 체크
    Lv_HshCk, _ = Rv_Clint.scroll(
        collection_name=Function.QRDANT_NAME,
        scroll_filter=models.Filter(must=[
            models.FieldCondition(key="DHASH",
                                  match=models.MatchValue(value=Id_DHash))
        ]),
        limit=1
    )
    if Lv_HshCk:
        return True     
    
    # 의미 중복 체크
    Lv_Reslt = Rv_Clint.search(
        collection_name=Function.QRDANT_NAME,
        query_vector=("q_vec", Iq_Dense),
        limit=1, 
        score_threshold=Is_Score,
        with_vectors=False
    )
    return bool(Lv_Reslt)   

# 디비 인서트
def Def_InsertDoc(Is_QUEST: str, Is_ANSWR: str, Id_METDS: dict):
    # 임베딩
    Lv_OutPt = Rv_Model.encode(
        [Is_QUEST, Is_ANSWR],
        return_dense=True, return_sparse=True, return_colbert_vecs=False,
    )

    # ─── Q + A 통합 벡터 (qna_vec) 생성 ───────────────────
    Ls_QATxt = f"Q:{Is_QUEST}\nA:{Is_ANSWR}"
    Lv_QnaPt = Rv_Model.encode([Ls_QATxt], return_dense=True)
    Lv_QAVec = Lv_QnaPt["dense_vecs"][0]  # 단일 벡터

    # Dense는 의미·유사도, Sparse는 키워드·정확도를 담당 → Hybrid Search.

    # 문장의 의미를 1024차원의 실수 벡터로 표현한 것.
    # 단어가 달라도 뜻이 비슷하면 가까운 벡터
    LQ_Dense, LA_dense = Lv_OutPt["dense_vecs"]   
    # 동일 문장을 키워드(토큰) → BM25(TF-IDF유사) 가중치 형태로 바꾼 것.
    # 같은 단어(토큰)를 공유하면 점수가 올라가는 희소(sparse) 벡터
    LQ_Lexic, LA_Lexic = Lv_OutPt["lexical_weights"] # <─ dict, dict
  
    # 중복체크
    if Def_AlrdExist(Function.Def_MakeDHash(Is_QUEST, Is_ANSWR), LQ_Dense, 0.95):
        return "비슷한 문서가 존재합니다."      

    Ld_Mergd = {}
    # 두 dict 를 순회하며 weight 병합
    # Qdrant 컬렉션 하나에 보통 “문서 전체”를 1포인트로 넣습니다.
    # 문서 = “질문 + 답변” 이므로 sparse(키워드) 정보도 두 문장을 합쳐서 1개로 만들어야 합니다.
    for Fv_Sorce in (LQ_Lexic, LA_Lexic):
        for Fv_IdxSt, Fv_WData in Fv_Sorce.items():
            Ls_Idxst = int(Fv_IdxSt)
            Ld_Mergd[Ls_Idxst] = max(Ld_Mergd.get(Ls_Idxst, 0.0), float(Fv_WData))   # max 또는 +=

    # Qdrant 형식으로 변환
    Lv_Indic = list(Ld_Mergd.keys())
    Lv_Value = [Ld_Mergd[Fi_Intgr] for Fi_Intgr in Lv_Indic]
    Ld_MerGe = models.SparseVector(indices=Lv_Indic, values=Lv_Value)

    Lv_Point = models.PointStruct(
        id=str(uuid4()),
        vector={
            "q_vec"  : LQ_Dense,
            "a_vec"  : LA_dense,
            "text"   : Ld_MerGe,  
            "qa_vec" : Lv_QAVec     
        },
        payload={**Id_METDS}
    )
    # 디비 인서트       
    Rv_Clint.upsert(collection_name=Function.QRDANT_NAME, points=[Lv_Point])
    return "Insert 성공!"

# 디비 검색
def Def_SrchSiDoc(
    Is_DBIDS: str = None, Is_QUEST: str = None, Is_SUBJT: str = None, Is_CTGRY: str = None, 
    Is_VENDR: str = None, Is_ACCLV: str = None, Is_HSPCD: str = None, Is_GPTPS: str = None, 
    Is_IMGYN: str = None, Is_RTALL: str = None, Is_MinSc: float = 0,  Is_USEYN: str = None,
    Is_VECKD: str = None,
):  
    # ID로 검색
    Lj_Reslt = []
    if Is_DBIDS:      
        Lv_Point = Rv_Clint.retrieve(
            collection_name=Function.QRDANT_NAME,
            ids=[Is_DBIDS]
        )
        for Fv_QData in Lv_Point:  # ← 리스트 안의 ScoredPoint
            Lj_Reslt.append({
                "id": Fv_QData.id,
                "ANSWR": Fv_QData.payload.get('ANSWR', ''),
                "QDATA": Fv_QData.payload,
                "SCORE": getattr(Fv_QData, "score", None) 
            })       
        return Lj_Reslt

    Li_TopKy = 1   
    if Is_RTALL == "Y":
        Li_TopKy = 1000000  
    Li_Limit = Li_TopKy     

    # 필터 조건 동적으로 생성
    Ls_QMust = []

    # ACCLV 조건 그룹 (should)
    if Is_ACCLV and Is_ACCLV != "ADMIN":
        Ls_QMust.append(models.Filter(
            should=[
                models.FieldCondition(key="ACCLV", match=models.MatchValue(value="PUBLIC")),
                models.FieldCondition(key="ACCLV", match=models.MatchValue(value=Is_ACCLV)),
            ]
        ))

    # HSPCD 조건 그룹 (should)
    if Is_HSPCD:
        Ls_QMust.append(models.Filter(
            should=[
                models.FieldCondition(key="HSPCD", match=models.MatchValue(value=Is_HSPCD)),
                models.FieldCondition(key="HSPCD", match=models.MatchValue(value="")),
            ]
        ))
    # 그 외 조건은 기존처럼 must로
    for Fv_DcKey, Fv_DcVal, Fv_DvTag in [
        ("SUBJT", Is_SUBJT, Ls_QMust),
        ("CTGRY", Is_CTGRY, Ls_QMust),
        ("VENDR", Is_VENDR, Ls_QMust),
        ("GPTPS", Is_GPTPS, Ls_QMust),
        ("IMGYN", Is_IMGYN, Ls_QMust),
        ("USEYN", Is_USEYN, Ls_QMust),
    ]:
        if Fv_DcVal:
            Fv_DvTag.append(models.FieldCondition(key=Fv_DcKey, match=models.MatchValue(value=Fv_DcVal)))

    # 최종 필터
    Lv_Filtr = None
    if Ls_QMust:
        Lv_Filtr = models.Filter(must=Ls_QMust)

    # 임베딩
    Lv_OutEc = Rv_Model.encode(
        [Is_QUEST], return_dense=True, return_sparse=True, return_colbert_vecs=False
    )
    LQ_Dense = Lv_OutEc["dense_vecs"][0]         
    LQ_Lexic = Lv_OutEc["lexical_weights"][0] 
    Lv_Sprte = models.SparseVector(
        indices=[int(Fv_Intgr)  for Fv_Intgr in LQ_Lexic.keys()],
        values=[float(Fv_Intgr) for Fv_Intgr in LQ_Lexic.values()],
    )
    
    # ── Hybrid search (dense + sparse) ───────────────────────
    # Lv_Reslt = Rv_Clint.query_points(
    #     collection_name=Function.QRDANT_NAME,
    #     prefetch=[
    #         models.Prefetch(query=LQ_Dense, using="q_vec", limit=Li_Limit),
    #         models.Prefetch(query=Lv_Sprte, using="text",  limit=Li_Limit),
    #     ],
    #     query=models.FusionQuery(fusion=models.Fusion.RRF),  # RRF로 두 결과 융합
    #     query_filter=Lv_Filtr,
    #     with_payload=True,
    #     score_threshold=Is_MinSc
    # )
    # for Fv_Index, Fv_QData in enumerate(Lv_Reslt.points):
    #    Ld_PayLd = dict(Fv_QData.payload)  # payload 복사

    #    if Fv_Index >= 7:
    #        for Fv_ImgKy in ['IMG01', 'IMG02', 'IMG03', 'IMG04', 'IMG05']:
    #            Ld_PayLd.pop(Fv_ImgKy, None)

    #    Lj_Reslt.append({
    #        "id": Fv_QData.id,
    #        "ANSWR": Ld_PayLd.get('ANSWR', ""),
    #        "QDATA": Ld_PayLd,
    #        "SCORE": Fv_QData.score
    #    })

    # 디비 검색
    if Is_VECKD:
        Lv_Reslt = Rv_Clint.search(
            collection_name=Function.QRDANT_NAME,
            query_vector=(Is_VECKD, LQ_Dense),   
            query_filter=Lv_Filtr,              
            limit=Li_TopKy,
            with_payload=True,
            score_threshold=Is_MinSc                
        )
    else:
        Lv_Reslt = Rv_Clint.search(
            collection_name=Function.QRDANT_NAME,
            query_vector=("qa_vec", LQ_Dense),   
            query_filter=Lv_Filtr,              
            limit=Li_TopKy,
            with_payload=True,
            score_threshold=Is_MinSc                
        )
        if not Lv_Reslt and Is_RTALL != "Y":
            Lv_Reslt = Rv_Clint.search(
                collection_name=Function.QRDANT_NAME,
                query_vector=("q_vec", LQ_Dense),   
                query_filter=Lv_Filtr,              
                limit=Li_TopKy,
                with_payload=True,
                score_threshold=Is_MinSc+0.03                
            )


    #유사도 점수 필터링 및 변환
    for Fv_Index, Fv_QData in enumerate(Lv_Reslt):
       Ld_PayLd = dict(Fv_QData.payload)  # payload 복사

       if Fv_Index >= 7:
        for Fv_ImgKy in ['IMG01', 'IMG02', 'IMG03', 'IMG04', 'IMG05']:
            if Fv_ImgKy in Ld_PayLd:
                Ld_PayLd[Fv_ImgKy] = ""  # 또는 None

       Lj_Reslt.append({
           "id": Fv_QData.id,
           "ANSWR": Ld_PayLd.get('ANSWR', ""),
           "QDATA": Ld_PayLd,
           "SCORE": Fv_QData.score
       })
    return Lj_Reslt[:Li_TopKy]

# 디비 업데이트
def Def_UpdateDoc(Is_DocId: str, Is_QUEST: str = None, Is_ANSWR: str = None, Id_METDS: dict = None): 
    try:   
        if not Is_DocId:
            return "❗문서 ID가 필요합니다."
        
        # 임베딩
        Lv_OutPt = Rv_Model.encode(
            [Is_QUEST, Is_ANSWR],
            return_dense=True, return_sparse=True, return_colbert_vecs=False,
        )
        # ─── Q + A 통합 벡터 (qna_vec) 생성 ───────────────────
        Ls_QATxt = f"Q:{Is_QUEST}\nA:{Is_ANSWR}"
        Lv_QnaPt = Rv_Model.encode([Ls_QATxt], return_dense=True)
        Lv_QAVec = Lv_QnaPt["dense_vecs"][0]  # 단일 벡터

        LQ_Dense, LA_dense = Lv_OutPt["dense_vecs"]   
        LQ_Lexic, LA_Lexic = Lv_OutPt["lexical_weights"] # <─ dict, dict  

        Ld_Mergd = {}
        # 두 dict 를 순회하며 weight 병합
        for source in (LQ_Lexic, LA_Lexic):
            for Fv_IdxSt, Fv_WData in source.items():
                Ls_Idxst = int(Fv_IdxSt)
                Ld_Mergd[Ls_Idxst] = max(Ld_Mergd.get(Ls_Idxst, 0.0), float(Fv_WData))   # max 또는 +=

        # Qdrant 형식으로 변환
        Lv_Indic = list(Ld_Mergd.keys())
        Lv_Value = [Ld_Mergd[Fi_Intgr] for Fi_Intgr in Lv_Indic]
        Ld_MerGe = models.SparseVector(indices=Lv_Indic, values=Lv_Value)

        Lv_Point = models.PointStruct(
            id=Is_DocId,
            vector={
                "q_vec"  : LQ_Dense,
                "a_vec"  : LA_dense,
                "text"   : Ld_MerGe,  
                "qa_vec" : Lv_QAVec     
            },
            payload={**Id_METDS}
        )
        # 디비 인서트       
        Rv_Clint.upsert(collection_name=Function.QRDANT_NAME, points=[Lv_Point])
        return "Update 성공!"
    except Exception as e:
        return str(e)

# 디비 삭제
def Def_DeleteDoc(Is_DocId: str):
    try:
        if not Is_DocId:
            return "❗문서 ID가 필요합니다."

        Rv_Clint.delete(
            collection_name=Function.QRDANT_NAME,
            points_selector=PointIdsList(points=[Is_DocId])
        )

        return "Delete 성공!"
    except Exception as e:
        return str(e)


