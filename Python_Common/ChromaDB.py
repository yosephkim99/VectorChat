from chromadb import PersistentClient   
from chromadb.utils.embedding_functions import SentenceTransformerEmbeddingFunction
import uuid
import Function


print("▶▶▶ ChromaDB 모듈 초기화, CHROMA_DIR =", Function.CHROMA_DIR)
# 로컬에 저장할 경로 지정
Rv_Clint = PersistentClient(path=str(Function.CHROMA_DIR))
# bge-m3 임베딩 함수 준비
Lv_BgeEm = SentenceTransformerEmbeddingFunction(
    model_name = Function.EMBED_MODEL
)
# 3. 컬렉션 가져오기 혹은 생성 (임베딩 함수 등록)
Rv_Coltn = Rv_Clint.get_or_create_collection(
    name=Function.CHROMA_NAME
   ,embedding_function=Lv_BgeEm 
)
print("▶▶▶ 컬렉션 객체 생성 완료:", Function.CHROMA_NAME)

# 디비 인서트
def Def_InsertDoc(Is_QUEST: str, Is_ANSWR: str, Id_METDS: dict):
    # DocId 자동 생성
    Ls_AtDId = str(uuid.uuid4())

    # 문서 문자열 생성 (Q&A 합침)
    Ls_DOCMT = f"Q: {Is_QUEST}\nA: {Is_ANSWR}"
    #Ls_DOCMT = f"{Is_ANSWR}\n\n{Is_QUEST}" 
    Rv_Coltn.add(
        ids=[Ls_AtDId],
        documents=[Ls_DOCMT],
        metadatas=[Id_METDS]
    )
    return "Insert 성공!"

# 디비 검색
def Def_SrchSiDoc(
    Is_DBIDS: str = None, Is_QUEST: str = None, 
    Is_SUBJT: str = None, Is_CTGRY: str = None, Is_VENDR: str = None, 
    Is_ACCLV: str = None, Is_HSPCD: str = None,
    Is_GPTPS: str = None, Is_IMGYN: str = None,
    Is_RTALL: str = None, Is_MinSc: float = 0.8
):
    # where 필터 조건 구성
    Lv_Wher1 = []
    if Is_ACCLV == "ADMIN":
        pass
    elif Is_ACCLV == "A":
        Lv_Wher1.append({"ACCLV": {"$in": ["PUBLIC", "A"]}})
    elif Is_ACCLV and Is_ACCLV != "PUBLIC":
        Lv_Wher1.append({"ACCLV": {"$in": ["PUBLIC", Is_ACCLV]}})
    else:
        Lv_Wher1.append({"ACCLV": "PUBLIC"})

    if Is_SUBJT:
        Lv_Wher1.append({"SUBJT": Is_SUBJT})
    if Is_CTGRY:
        Lv_Wher1.append({"CTGRY": Is_CTGRY})
    if Is_VENDR:
        Lv_Wher1.append({"VENDR": Is_VENDR})
    if Is_HSPCD:
        Lv_Wher1.append({"HSPCD": {"$in": ["", Is_HSPCD]}})
    if Is_GPTPS:
        Lv_Wher1.append({"GPTPS": Is_GPTPS})
    if Is_IMGYN:
        Lv_Wher1.append({"IMGYN": Is_IMGYN})

    # 최종 Lv_Where 구성
    Lv_Where = {} 
    if len(Lv_Wher1) == 1:
        Lv_Where = Lv_Wher1[0]
    elif len(Lv_Wher1) > 1:
        Lv_Where = {"$and": Lv_Wher1}
    else:
        Lv_Where = {}
    Li_TopKy = 5
    if Is_RTALL is None:
        Li_TopKy = 1
    elif Is_RTALL == "Y":
        Li_TopKy = 20
    # 쿼리 검색
    if Is_QUEST:
        # 질문 검색
        if Lv_Where:
            Lv_Reslt = Rv_Coltn.query(
                query_texts=[f"Q: {Is_QUEST}"],
                n_results=Li_TopKy,
                where=Lv_Where,
            )
        else:
            Lv_Reslt = Rv_Coltn.query(
            query_texts=[f"Q: {Is_QUEST}"],
            n_results=Li_TopKy,
            )
    elif Is_DBIDS:
        # 아이디 검색
        Lv_Reslt = Rv_Coltn.get(
            ids=Is_DBIDS,
            include=['documents', 'metadatas']  # 필요에 따라 선택
        )   
    else:   
        #전체 검색 
        if Lv_Where:  
            Lv_Reslt = Rv_Coltn.get(
                where=Lv_Where,
                include=['documents', 'metadatas']  # 필요에 따라 선택
            )  
        else:  
            Lv_Reslt = Rv_Coltn.get( 
                include=['documents', 'metadatas']  # 필요에 따라 선택
            ) 
    
    if Is_QUEST:  # 내용 기반 유사도 검색
        Lv_ChrId, Lv_Docmt, Lv_Metas, Lv_Dists = Lv_Reslt['ids'][0], Lv_Reslt['documents'][0], Lv_Reslt['metadatas'][0], Lv_Reslt['distances'][0]
        Lj_Reslt = []
        for Fv_ChrId, Fv_Docmt, Fv_Metds, Fv_Dists in zip(Lv_ChrId, Lv_Docmt, Lv_Metas, Lv_Dists):
            if Fv_Dists > Is_MinSc:
                continue
            
            Lj_Reslt.append({
                "ids": Fv_ChrId,
                "document": Fv_Docmt,
                "metadatas": Fv_Metds,
                "score": Fv_Dists
            })

        if Li_TopKy == 1000:
            return Lj_Reslt
        else:
            return Lj_Reslt[:1]
    else:
        #전체 검색 or Id 검색
        Lj_Reslt = []
        for Fv_ChrId, Fv_Docmt, Fv_Metds in zip(Lv_Reslt['ids'], Lv_Reslt['documents'], Lv_Reslt['metadatas']):
            Lj_Reslt.append({
                "ids": Fv_ChrId,
                "document": Fv_Docmt,
                "metadatas": Fv_Metds,
                "score": "X"
            })
        return Lj_Reslt

# 디비 업데이트
def Def_UpdateDoc(Is_DocId: str, Is_QUEST: str = None, Is_ANSWR: str = None, Id_METDS: dict = None): 
    try:   
        # 문서 문자열 생성 (Q&A 합침)
        Ls_DOCMT = f"Q: {Is_QUEST}\nA: {Is_ANSWR}"

        Rv_Coltn.update(
            ids=[Is_DocId],
            documents=[Ls_DOCMT],
            metadatas=[Id_METDS]
        )

        return "Update 성공!"
    except Exception as e:
        return str(e)

# 디비 삭제
def Def_DeleteDoc(Is_DocId: str):
    try:
        Rv_Coltn.delete(ids=[Is_DocId])

        return "Delete 성공!"
    except Exception as e:
        return str(e)


