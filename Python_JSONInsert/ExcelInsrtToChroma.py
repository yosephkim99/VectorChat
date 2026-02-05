import pandas as pd
from datetime import datetime
from chromadb import PersistentClient
from chromadb.utils import embedding_functions
import pathlib
import sys
from tqdm import tqdm 

# 공통 모듈 & 경로
Rv_SCDIR = pathlib.Path(__file__).resolve().parent
common_dir = Rv_SCDIR.parent / "Python_Common"
sys.path.insert(0, str(common_dir))
import ChromaDB 

# 읽을 엑셀 파일 경로
Rs_EPath = r"C:\Users\shn06\Desktop\라이프코치 질문 + 답변 정리.xlsx"

# 엑셀 파일 로드
Rd_ExcDf = pd.read_excel(Rs_EPath, dtype=str).fillna("")  # 모든 컬럼을 문자열로 읽어들임

# DataFrame 전체 개수
Ri_Total = len(Rd_ExcDf)

print("✅ 엑셀파일 로드 완료! 이제 인서트를 시작합니다.")
proceed = input("계속하려면 Y를, 취소하려면 아무 키나 누른 후 Enter를 눌러주세요: ")
if proceed.strip().lower() != 'y':
    print("❎ 인서트가 취소되었습니다.")
    sys.exit(0)

# 행 단위로 문서 삽입
for Fi_Index, Fv_RowDt in tqdm(Rd_ExcDf.iterrows(), total=Ri_Total, desc="Inserting to ChromaDB"):
    # INSERTYN이 'Y'인 경우에만 삽입하고, 그렇지 않으면 넘어가려면 아래 조건을 사용하세요.
    if Fv_RowDt.get("INSERTYN", "").upper() != "N":
        continue

    # 원본 질문/답변 가져오기
    Rs_QUEST = Fv_RowDt.get("QUEST", "").strip()
    # literal "\n"이 들어 있다면 실제 개행으로 바꿔주기
    Rs_ANSWR = Fv_RowDt.get("ANSWR", "").replace("\\n", "\n").strip()

    # 현재 날짜  정보 가져오기
    Rt_NowDT = datetime.now()
    Rs_NowDy = Rt_NowDT.strftime("%Y%m%d")

    # 메타데이터 딕셔너리
    Rs_MtDta = {
        "SUBJT": Fv_RowDt.get("SUBJT", ""),
        "CTGRY": Fv_RowDt.get("CTGRY", ""),
        "QUEST": Rs_QUEST,
        "ANSWR": Rs_ANSWR,
        "VENDR": Fv_RowDt.get("VENDR", ""),
        "ACCLV": Fv_RowDt.get("ACCLV", ""),
        "HSPCD": Fv_RowDt.get("HSPCD", ""),
        "DBSDT": Rs_NowDy
    }
    Rv_Reslt = ChromaDB.Def_InsertDoc(Rs_QUEST, Rs_ANSWR, Rs_MtDta)

    if Rv_Reslt != "Insert 성공!":
        print("인서트 중 에러가 발생했습니다.")
        sys.exit(1)

    # 삽입 성공 시 해당 행의 INSERTYN을 "Y"로 변경
    Rd_ExcDf.at[Fi_Index, "INSERTYN"] = "Y"

print("✅ 엑셀 데이터를 ChromaDB에 삽입 완료!")

# 변경된 DataFrame을 같은 파일(또는 새 파일)로 저장
Rd_ExcDf.to_excel(Rs_EPath, index=False)
print(f"✅ {Rs_EPath} 업데이트 완료!")