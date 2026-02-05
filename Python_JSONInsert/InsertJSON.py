import json, uuid, os
from chromadb.config import Settings
import openai                 # pip install openai
from tqdm import tqdm         # 진행률 표시 (선택)
import pathlib
import sys

# 공통 모듈 & 경로
Rv_SCDIR = pathlib.Path(__file__).resolve().parent
common_dir = Rv_SCDIR.parent / "Python_Common"
sys.path.insert(0, str(common_dir))
import Function
import ChromaDB 

# ──────────────────────────────────────────────
# JSON 로드
# ──────────────────────────────────────────────
Rv_JSDIR = r"D:\AIRsViewr\Python_PDF\2025"
Rv_AllDt = []

for Fv_RootA, Rv_DirNm, Fv_Files in os.walk(Rv_JSDIR):
    for Fv_FName in Fv_Files:
        if Fv_FName.lower().endswith('.json'):
            Fv_JPath = os.path.join(Fv_RootA, Fv_FName)
            with open(Fv_JPath, 'r', encoding='utf-8') as Fv_FILEA:
                Fv_FData = json.load(Fv_FILEA)
                if isinstance(Fv_FData, list):
                    for rec in Fv_FData:
                        if isinstance(rec, dict):
                            rec["_source_file"] = Fv_JPath
                            Rv_AllDt.append(rec)
                elif isinstance(Fv_FData, dict):
                    Fv_FData["_source_file"] = Fv_JPath
                    Rv_AllDt.append(Fv_FData)

print(f"🔍 총 {len(Rv_AllDt)}개의 문서 로드 완료.")
# ──────────────────────────────────────────────
# 임베딩 생성 + Chroma insert (배치 처리 권장)
# ──────────────────────────────────────────────
Rv_BATCH = 50                     # API 과금/속도 균형용
Rv_BfCnt = ChromaDB.Rv_Coltn.count() 

# ──────────────────────────────────────────────
# 키 검사: documents, metadatas 둘 다 있는지 확인
# ──────────────────────────────────────────────
for Fv_IntCt in tqdm(range(0, len(Rv_AllDt), Rv_BATCH)):
    batch = Rv_AllDt[Fv_IntCt : Fv_IntCt + Rv_BATCH]

    for idx, item in enumerate(batch):
        if not isinstance(item, dict) or \
           "documents" not in item or \
           "metadatas" not in item:
            src    = item.get("_source_file", "<unknown>")
            folder = os.path.dirname(src)
            print(f"❌ 파일: {src}")
            print(f"   폴더: {folder}")
            print(f"   배치 시작 인덱스: {Fv_IntCt}, 항목 번호: {idx}")
            print(f"   키 목록: {list(item.keys())}")
            sys.exit(1)
# ──────────────────────────────────────────────
# 사용자 확인
# ──────────────────────────────────────────────
print("✅ 검사 완료! 이제 인서트를 시작합니다.")
proceed = input("계속하려면 Y를, 취소하려면 아무 키나 누른 후 Enter를 눌러주세요: ")
if proceed.strip().lower() != 'y':
    print("❎ 인서트가 취소되었습니다.")
    sys.exit(0)

for Fv_IntCt in tqdm(range(0, len(Rv_AllDt), Rv_BATCH)):
    Fv_Batch = Rv_AllDt[Fv_IntCt : Fv_IntCt + Rv_BATCH]

    Fv_Texts = [item["documents"]  for item in Fv_Batch]
    Fv_MtDat = [item["metadatas"]  for item in Fv_Batch]
    Fv_ChIds = [str(uuid.uuid4())  for _    in Fv_Batch]

    # OpenAI 임베딩
    Fv_OResp = Function.Ge_client.embeddings.create(
        model = Function.EMBED_MODEL,
        input = Fv_Texts
    )
    Fv_Embed = [item.embedding for item in Fv_OResp.data]

    # Chroma insert
    ChromaDB.Rv_Coltn.add(
        ids         = Fv_ChIds,
        documents   = Fv_Texts,
        metadatas   = Fv_MtDat,
        embeddings  = Fv_Embed
    )

Rv_AfCnt = ChromaDB.Rv_Coltn.count()
print(f"✅  Done! 총 {Rv_AfCnt-Rv_BfCnt} 개 벡터 저장.")