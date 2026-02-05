from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel, field_validator
import json, sys, os
from datetime import datetime
import uuid

sys.path.append(os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'Python_Common')
))
import Function 
import Qdrant 
import MsSqlDB 

# cd D:\AIRsViewr\Python_API
# uvicorn API:app --host 0.0.0.0 --port 8000
# uvicorn API:app --workers 4 --host 0.0.0.0 --port 8000
# py -3.12 -m uvicorn API:app --reload

app = FastAPI()

Rv_AuthU = ["SRMSOFT"]
Rv_AuthD = ["SRMDB!@#"]

class Cls_ReqstModl(BaseModel):
    Is_EncDt: str

# 새롬AI JSON 공통
class Cls_ChJSONMdl(BaseModel):
    CLs_WHORU: str
    CLs_DBIDS: str
    CLs_QUEST: str
    CLs_ANSWR: str
    CLs_GPTPS: str
    CLs_SUBJT: str
    CLs_CTGRY: str
    CLs_VENDR: str
    CLs_ACCLV: str
    CLs_HSPCD: str
    CLs_HSPNM: str
    CLs_USRID: str
    CLs_DBSDT: str
    CLs_RTALL: str
    CLs_IMGYN: str
    CLs_IMG01: str
    CLs_IMG02: str
    CLs_IMG03: str
    CLs_IMG04: str
    CLs_IMG05: str
    CLs_USEYN: str
    CLs_VECKD: str

# 챗GPT 질문 API
@app.post("/ask")
async def Def_AskQuestn(CIe_Param: Cls_ReqstModl, background_tasks: BackgroundTasks):
    try:
        # AES256 복호화
        Ls_DecDt = Function.Def_Aes256Dec(CIe_Param.Is_EncDt)
        # JSON 문자열을 dict로 파싱
        Lj_DicDt = json.loads(Ls_DecDt)
        # dict를 Pydantic 모델로 변환
        CLe_QData = Cls_ChJSONMdl(**Lj_DicDt)
    except:
        return Function.Def_RetnValue("AES256 암호화가 잘못되었습니다.", "-1", CIe_Param.Is_EncDt, "")
    
    Ls_CHTID = str(uuid.uuid4())
    # 우선 디비에 내용 인서트
    background_tasks.add_task(
                MsSqlDB.Def_ChtLgMSQL,
                Ls_CHTID, "N", CLe_QData.CLs_HSPCD, CLe_QData.CLs_HSPNM, CLe_QData.CLs_USRID, CLe_QData.CLs_QUEST, "", "", "", "", "", ""
            )
    try:
        # 허용되지 않은 접근
        if CLe_QData.CLs_WHORU not in Rv_AuthU:
            background_tasks.add_task(
                MsSqlDB.Def_ChtLgMSQL,
                Ls_CHTID, "N", CLe_QData.CLs_HSPCD, CLe_QData.CLs_HSPNM, CLe_QData.CLs_USRID, CLe_QData.CLs_QUEST, "", "", "", "허용되지 않은 접근입니다.", "", ""
            )
            return Function.Def_RetnValue("실패했습니다.", "-1", "허용되지 않은 접근입니다.", "")
     
        # DB에서 유사 문서 검색
        Lv_Reslt = Qdrant.Def_SrchSiDoc(CLe_QData.CLs_DBIDS, CLe_QData.CLs_QUEST, CLe_QData.CLs_SUBJT, CLe_QData.CLs_CTGRY, CLe_QData.CLs_VENDR, CLe_QData.CLs_ACCLV, 
                                        CLe_QData.CLs_HSPCD, CLe_QData.CLs_GPTPS, CLe_QData.CLs_IMGYN, CLe_QData.CLs_RTALL, 0.69, CLe_QData.CLs_USEYN, "")
        
        # 문서 결과가 없으면 GPT 전처리 후 재 검색
        if not Lv_Reslt or not Lv_Reslt[0]:
            # GPT 전처리
            Lv_PrGPT = Function.Def_VecQAgent(CLe_QData.CLs_QUEST)
            Ls_GPTAN = Lv_PrGPT["ANSWR"]
            Ls_GPTMO = Lv_PrGPT["MODEL"]
            Ls_GPTPR = Lv_PrGPT["PROMT"]
            background_tasks.add_task(
                MsSqlDB.Def_ChtLgMSQL,
                Ls_CHTID, "Y", CLe_QData.CLs_HSPCD, CLe_QData.CLs_HSPNM, CLe_QData.CLs_USRID, CLe_QData.CLs_QUEST, "", "", "", Ls_GPTAN, Ls_GPTMO, Ls_GPTPR
            )
            # DB에서 유사 문서 검색
            Lv_Reslt = Qdrant.Def_SrchSiDoc(CLe_QData.CLs_DBIDS, Ls_GPTAN, CLe_QData.CLs_SUBJT, CLe_QData.CLs_CTGRY, CLe_QData.CLs_VENDR, CLe_QData.CLs_ACCLV, 
                                            CLe_QData.CLs_HSPCD, CLe_QData.CLs_GPTPS, CLe_QData.CLs_IMGYN, CLe_QData.CLs_RTALL, 0.69, CLe_QData.CLs_USEYN, "")
            # 전처리 후에도 없으면 종료
            if not Lv_Reslt or not Lv_Reslt[0]:
                background_tasks.add_task(
                    MsSqlDB.Def_ChtLgMSQL,
                    Ls_CHTID, "N", CLe_QData.CLs_HSPCD, CLe_QData.CLs_HSPNM, CLe_QData.CLs_USRID, CLe_QData.CLs_QUEST, "", "", "", "관련 문서를 찾지 못했습니다.", "", ""
                )
                return Function.Def_RetnValue("실패했습니다.", "-1", "관련 문서를 찾지 못했습니다.", "")

        # 결과 문서 가져오기
        Ls_QDBID = Lv_Reslt[0]["id"] if Lv_Reslt else None 
        Ls_Cntnt = Lv_Reslt[0]["QDATA"]["ANSWR"] if Lv_Reslt else None
        Ls_GPTPS = Lv_Reslt[0]["QDATA"]["GPTPS"] if Lv_Reslt else None 
        Ls_IMGYN = Lv_Reslt[0]["QDATA"]["IMGYN"] if Lv_Reslt else None
        Ls_IMG01 = Lv_Reslt[0]["QDATA"]["IMG01"] if Lv_Reslt else None
        Ls_IMG02 = Lv_Reslt[0]["QDATA"]["IMG02"] if Lv_Reslt else None
        Ls_IMG03 = Lv_Reslt[0]["QDATA"]["IMG03"] if Lv_Reslt else None
        Ls_IMG04 = Lv_Reslt[0]["QDATA"]["IMG04"] if Lv_Reslt else None
        Ls_IMG05 = Lv_Reslt[0]["QDATA"]["IMG05"] if Lv_Reslt else None 
        Ls_SCORE = Lv_Reslt[0]["SCORE"] if Lv_Reslt else None 
        # GPT 응답
        Ls_Anser = ""
        Ls_MODEL = ""
        Ls_PROMT = ""
        if Ls_GPTPS is None or Ls_GPTPS == 'NOUSE':
            # GPT 사용 안하고 바로 대답
            Ls_Anser = Ls_Cntnt
        else:
            Lv_GPTRT = Function.Def_AskChtGpt(Ls_GPTPS, CLe_QData.CLs_ACCLV, Ls_Cntnt)
            Ls_Anser = Lv_GPTRT["ANSWR"]
            Ls_MODEL = Lv_GPTRT["MODEL"]
            Ls_PROMT = Lv_GPTRT["PROMT"]
        # 로그 저장 (MSSQL)
        background_tasks.add_task(
            MsSqlDB.Def_ChtLgMSQL,
            Ls_CHTID, "Y", CLe_QData.CLs_HSPCD, CLe_QData.CLs_HSPNM, CLe_QData.CLs_USRID, CLe_QData.CLs_QUEST, Ls_QDBID, Ls_Cntnt, Ls_SCORE, Ls_Anser, Ls_MODEL, Ls_PROMT
        )

        print({"Message":"성공했습니다.", "SqlCode":"1", "Result":"답변 성공!"})
        return {"Message":"성공했습니다.", "SqlCode":"1", "Result":Function.Def_Aes256Enc(Ls_Anser), "IMGYN":Function.Def_Aes256Enc(Ls_IMGYN),
                "IMG01":Function.Def_Aes256Enc(Ls_IMG01), "IMG02":Function.Def_Aes256Enc(Ls_IMG02), "IMG03":Function.Def_Aes256Enc(Ls_IMG03),
                "IMG04":Function.Def_Aes256Enc(Ls_IMG04), "IMG05":Function.Def_Aes256Enc(Ls_IMG05)}
    except Exception as e:
        # 로그 저장 (MSSQL)
        background_tasks.add_task(
            MsSqlDB.Def_ChtLgMSQL,
            Ls_CHTID, "N", "", "", "", CIe_Param.Is_EncDt, "", "", "", str(e), "", ""
        )
        return Function.Def_RetnValue("실패했습니다.", "-1", str(e), "")

# 문서 인서트 API
@app.post("/SRMInsertChr")
async def Def_IstChroma(CIe_Param: Cls_ReqstModl):
    try:
        # AES256 복호화
        Ls_DecDt = Function.Def_Aes256Dec(CIe_Param.Is_EncDt)
        # JSON 문자열을 dict로 파싱
        Lj_DicDt = json.loads(Ls_DecDt)
        # dict를 Pydantic 모델로 변환
        CLe_CData = Cls_ChJSONMdl(**Lj_DicDt)

        if CLe_CData.CLs_WHORU not in Rv_AuthD:
            return Function.Def_RetnValue("실패했습니다.", "-1", "허용되지 않은 접근입니다.", "")

        # 현재 날짜  정보 가져오기
        Lt_NowDT = datetime.now()
        Ls_NowDy = Lt_NowDT.strftime("%Y%m%d")
        print("1")    
        Ls_MtDta = {
            "DHASH" : Function.Def_MakeDHash(CLe_CData.CLs_QUEST, CLe_CData.CLs_ANSWR), # 해시값
            "SUBJT" : CLe_CData.CLs_SUBJT,  # 주제
            "CTGRY" : CLe_CData.CLs_CTGRY,  # 카테고리
            "QUEST" : CLe_CData.CLs_QUEST,  # 질문
            "ANSWR" : CLe_CData.CLs_ANSWR,  # 답변
            "GPTPS" : CLe_CData.CLs_GPTPS,  # GPT 프롬포트 종류
            "VENDR" : CLe_CData.CLs_VENDR,  # 외부연계업체
            "ACCLV" : CLe_CData.CLs_ACCLV,  # 권한 제어용(선택)
            "HSPCD" : CLe_CData.CLs_HSPCD,  # 병원 전용 문서라면 코드 입력
            "DBSDT" : Ls_NowDy,             # 디비 인서트 시간
            "IMGYN" : CLe_CData.CLs_IMGYN,  # 이미지유무
            "IMG01" : CLe_CData.CLs_IMG01,  # 이미지01
            "IMG02" : CLe_CData.CLs_IMG02,  # 이미지02
            "IMG03" : CLe_CData.CLs_IMG03,  # 이미지03
            "IMG04" : CLe_CData.CLs_IMG04,  # 이미지04
            "IMG05" : CLe_CData.CLs_IMG05,  # 이미지05
            "USEYN" : CLe_CData.CLs_USEYN   # 사용여부
        }
        print("2")    
        Lv_Reslt = Qdrant.Def_InsertDoc(CLe_CData.CLs_QUEST, CLe_CData.CLs_ANSWR, Ls_MtDta)
        if Lv_Reslt != "Insert 성공!":
            return Function.Def_RetnValue("실패했습니다.", "-1", Lv_Reslt, "")

        return Function.Def_RetnValue("성공했습니다.", "1", Lv_Reslt, "")
    except Exception as e:
        return Function.Def_RetnValue("실패했습니다.", "-1", str(e), "")

# 문서 셀렉트 API
@app.post("/SRMSelectChr")
async def Def_SlcChroma(CIe_Param: Cls_ReqstModl):
    try:
        # AES256 복호화
        Ls_DecDt = Function.Def_Aes256Dec(CIe_Param.Is_EncDt)
        # JSON 문자열을 dict로 파싱
        Lj_DicDt = json.loads(Ls_DecDt)
        # dict를 Pydantic 모델로 변환
        CLe_CData = Cls_ChJSONMdl(**Lj_DicDt)

        if CLe_CData.CLs_WHORU not in Rv_AuthD:
            return Function.Def_RetnValue("실패했습니다.", "-1", "허용되지 않은 접근입니다.", "")

        Lv_Reslt = Qdrant.Def_SrchSiDoc(CLe_CData.CLs_DBIDS, CLe_CData.CLs_QUEST, CLe_CData.CLs_SUBJT, CLe_CData.CLs_CTGRY, CLe_CData.CLs_VENDR, CLe_CData.CLs_ACCLV, 
                                        CLe_CData.CLs_HSPCD, CLe_CData.CLs_GPTPS, CLe_CData.CLs_IMGYN, CLe_CData.CLs_RTALL, 0.001, CLe_CData.CLs_USEYN, CLe_CData.CLs_VECKD)
        Lv_Reslt = json.dumps(Lv_Reslt, ensure_ascii=False)

        return Function.Def_RetnValue("성공했습니다.", "1", Lv_Reslt, "Select 성공!")
    except Exception as e:
        return Function.Def_RetnValue("실패했습니다.", "-1", str(e), "")

# 문서 업데이트 API
@app.post("/SRMUpdateChr")
async def Def_UpdChroma(CIe_Param: Cls_ReqstModl):  
    try:
        # AES256 복호화
        Ls_DecDt = Function.Def_Aes256Dec(CIe_Param.Is_EncDt)
        # JSON 문자열을 dict로 파싱
        Lj_DicDt = json.loads(Ls_DecDt)
        # dict를 Pydantic 모델로 변환
        CLe_CData = Cls_ChJSONMdl(**Lj_DicDt)

        # 허용되지 않은 접근입니다.
        if CLe_CData.CLs_WHORU not in Rv_AuthD:
            return Function.Def_RetnValue("실패했습니다.", "-1", "허용되지 않은 접근입니다.", "")
        
        # 아이디
        if CLe_CData.CLs_DBIDS is None :
            return Function.Def_RetnValue("실패했습니다.", "-1", "업데이트 번호가 없습니다.", "")

        Ls_QUEST = None
        if CLe_CData.CLs_QUEST is not None :
            Ls_QUEST = CLe_CData.CLs_QUEST
        else:
            return Function.Def_RetnValue("실패했습니다.", "-1", "QUEST 내용이 없습니다.", "")   
        Ls_ANSWR = None
        if CLe_CData.CLs_ANSWR is not None :
            Ls_ANSWR = CLe_CData.CLs_ANSWR
        else:
            return Function.Def_RetnValue("실패했습니다.", "-1", "ANSWR 내용이 없습니다.", "")

        # 현재 날짜  정보 가져오기
        Lt_NowDT = datetime.now()
        Ls_NowDy = Lt_NowDT.strftime("%Y%m%d")

        # 부가정보
        Ls_MtDta = {
            "DHASH" : Function.Def_MakeDHash(CLe_CData.CLs_QUEST, CLe_CData.CLs_ANSWR), # 해시값
            "SUBJT" : CLe_CData.CLs_SUBJT,  # 주제
            "CTGRY" : CLe_CData.CLs_CTGRY,  # 카테고리
            "QUEST" : CLe_CData.CLs_QUEST,  # 질문
            "ANSWR" : CLe_CData.CLs_ANSWR,  # 답변
            "GPTPS" : CLe_CData.CLs_GPTPS,  # GPT 프롬포트 종류
            "VENDR" : CLe_CData.CLs_VENDR,  # 외부연계업체
            "ACCLV" : CLe_CData.CLs_ACCLV,  # 권한 제어용(선택)
            "HSPCD" : CLe_CData.CLs_HSPCD,  # 병원 전용 문서라면 코드 입력
            "DBSDT" : Ls_NowDy,             # 디비 인서트 시간
            "IMGYN" : CLe_CData.CLs_IMGYN,  # 이미지유무
            "IMG01" : CLe_CData.CLs_IMG01,  # 이미지01
            "IMG02" : CLe_CData.CLs_IMG02,  # 이미지02
            "IMG03" : CLe_CData.CLs_IMG03,  # 이미지03
            "IMG04" : CLe_CData.CLs_IMG04,  # 이미지04
            "IMG05" : CLe_CData.CLs_IMG05,  # 이미지05
            "USEYN" : CLe_CData.CLs_USEYN   # 사용여부
        }

        if CLe_CData.CLs_CTGRY is None:
            return Function.Def_RetnValue("실패했습니다.", "-1", "카테고리 내용이 없습니다.", "")

        # 업데이트
        Lv_Reslt = Qdrant.Def_UpdateDoc(CLe_CData.CLs_DBIDS, Ls_QUEST, Ls_ANSWR, Ls_MtDta)

        if Lv_Reslt != "Update 성공!":
            return Function.Def_RetnValue("실패했습니다.", "-1", Lv_Reslt, "")

        return Function.Def_RetnValue("성공했습니다.", "1", Lv_Reslt, "")
    except Exception as e:
        return Function.Def_RetnValue("실패했습니다.", "-1", str(e), "")
    
# 문서 삭제 API
@app.post("/SRMDeleteChr")
async def Def_DelChroma(CIe_Param: Cls_ReqstModl):
    try:
        # AES256 복호화
        Ls_DecDt = Function.Def_Aes256Dec(CIe_Param.Is_EncDt)
        # JSON 문자열을 dict로 파싱
        Lj_DicDt = json.loads(Ls_DecDt)
        # dict를 Pydantic 모델로 변환
        CLe_CData = Cls_ChJSONMdl(**Lj_DicDt)

        if CLe_CData.CLs_WHORU not in Rv_AuthD:
            return Function.Def_RetnValue("실패했습니다.", "-1", "허용되지 않은 접근입니다.", "")
        
        # 아이디
        if CLe_CData.CLs_DBIDS is None :
            return Function.Def_RetnValue("실패했습니다.", "-1", "업데이트 번호가 없습니다.", "")

        Lv_Reslt = Qdrant.Def_DeleteDoc(CLe_CData.CLs_DBIDS)
        if Lv_Reslt != "Delete 성공!":
            return Function.Def_RetnValue("실패했습니다.", "-1", Lv_Reslt, "")

        return Function.Def_RetnValue("성공했습니다.", "1", Lv_Reslt, "")
    except Exception as e:
        return Function.Def_RetnValue("실패했습니다.", "-1", str(e), "")
    

