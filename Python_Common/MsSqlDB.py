import pyodbc
from datetime import datetime
import Function 

# MSSQL 연결 설정 (환경에 맞게 수정)
def Def_GetSqlCon():
    return pyodbc.connect(
        "DRIVER={SQL Server};"
        "SERVER=localhost;"  # 또는 IP, 포트 포함
        "DATABASE=SRMAILOG;"
        "UID=pbs;"
        "PWD=!1p2k3p4c5l6c!@#;"
        "TrustServerCertificate=yes;"
    )

# 채팅 로그 저장
def Def_ChtLgMSQL(Is_CHTID, Is_SUCSS, Is_HSPCD, Is_HSPNM, Is_USRID, Is_QUEST, Is_QDBID, Is_REFER, Is_SCORE, Is_ANSWR, Is_MODEL, Is_PROMT):
    Ls_NowDy = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        Lv_DConn = Def_GetSqlCon()
        Lv_Cursr = Lv_DConn.cursor()
        Ls_Query = """
            Select * From SRMAILOG..CHTLTABLE
            Where CHTLCHTID = ?
        """
        Lv_Cursr.execute(Ls_Query, Is_CHTID)
        Ls_DBDta = Lv_Cursr.fetchone()
        if Ls_DBDta is None:
            Ls_Query = """
                INSERT INTO SRMAILOG..CHTLTABLE (CHTLCHTID, CHTLSUCSS, CHTLHSPCD, CHTLHSPNM, CHTLUSRID, CHTLQUEST, CHTLQDBID, CHTLREFNC, CHTLSCORE, CHTLANSWR, CHTLCDATE)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            Lv_Cursr.execute(Ls_Query, Is_CHTID, Is_SUCSS, Is_HSPCD, Is_HSPNM, Is_USRID, Is_QUEST, Is_QDBID, Is_REFER, Is_SCORE, Is_ANSWR, Ls_NowDy)
        else:
            Ls_Query = """
                Update SRMAILOG..CHTLTABLE Set 
                    CHTLSUCSS = ?, CHTLHSPCD = ?, CHTLHSPNM = ?, CHTLUSRID = ?, CHTLQUEST = ?, CHTLQDBID = ?, CHTLREFNC = ?, CHTLSCORE = ?,
                    CHTLANSWR = ?, CHTLCDATE = ?
                Where CHTLCHTID = ?
            """
            Lv_Cursr.execute(Ls_Query, Is_SUCSS, Is_HSPCD, Is_HSPNM, Is_USRID, Is_QUEST, Is_QDBID, Is_REFER, Is_SCORE, Is_ANSWR, Ls_NowDy, Is_CHTID)
            
        Lv_DConn.commit()
        # GPT 사용량 로그 저장
        if Is_SUCSS == "Y" and Is_MODEL.strip() != '':
            Def_LogGptUsg(Is_CHTID, Is_HSPCD, Is_USRID, Is_MODEL, Is_PROMT, Is_QUEST, Is_ANSWR, Ls_NowDy)
    except Exception as e:
        print("로그 저장 오류:", e)
    finally:
        Lv_DConn.close()

# GPT 사용량 로그 저장 함수
def Def_LogGptUsg(Is_CHTID, Is_HSPCD, Is_PATID, Is_MODEL, Is_PROMT, Is_QUEST, Is_ANSWR, Is_CDATE):
    # 인풋 아웃풋 토큰 계산
    Li_InPut = Function.Def_CountTokn(Is_PROMT, Is_MODEL) + Function.Def_CountTokn(Is_QUEST, Is_MODEL) 
    Li_OtPut = Function.Def_CountTokn(Is_ANSWR, Is_MODEL)

    # 비용 계산
    Lv_TRate = Function.GPT_PRICE_1K[Is_MODEL]
    Li_ICost = (Li_InPut / 1000) * Lv_TRate["in"] 
    Li_OCost = (Li_OtPut / 1000) * Lv_TRate["out"]
    Li_TCost = Li_ICost + Li_OCost

    # DB INSERT
    try:
        Lv_DConn = Def_GetSqlCon()
        Lv_Cursr = Lv_DConn.cursor()
        Ls_Query =  """
            INSERT INTO SRMAILOG..GPTCTABLE (GPTCCHTID, GPTCHSPCD, GPTCPATID, GPTCMODEL, GPTCINTKN, GPTCOTTKN, GPTCUCOST, GPTCPROMT, GPTCQUEST, GPTCANSWR, GPTCCDATE)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?)
        """
        Lv_Cursr.execute(Ls_Query, 
            Is_CHTID, Is_HSPCD, Is_PATID, Is_MODEL, Li_InPut, Li_OtPut, Li_TCost, Is_PROMT, Is_QUEST, Is_ANSWR, Is_CDATE
        )
        Lv_DConn.commit()
    except Exception as e:
        print("로그 저장 오류:", e)
    finally:
        Lv_DConn.close()
