from openai import OpenAI
import json, base64, pathlib, tiktoken, hashlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend

# GPT API Key
Ge_client = OpenAI(api_key="")
# GPT 가격
GPT_PRICE_1K = {
    # 표준 Chat Completions API
    "gpt-4o":         {"in": 0.0025,  "out": 0.010},
    "gpt-4o-mini":    {"in": 0.00015, "out": 0.0006},
}

Rv_SCDIR = pathlib.Path(__file__).resolve().parent

EMBED_MODEL = "BAAI/bge-m3"

# 크로마DB 모델 설정 및 DB위치와 이름      
CHROMA_DIR  = Rv_SCDIR.parent / "TESTDIR01_DATA"
CHROMA_NAME = "SAEROMAI_DB"

# Qrdant DB 모델 설정 및 위치
QRDANT_DIR = Rv_SCDIR.parent / "DATA"
QRDANT_NAME = "SAEROMAI_DB_250511"

# AES256 키값
KEY_STRING = "srmXqcz35qqoSw1zUYbJFuRg9qa==srm"
IV_STRING = "SRIV1p2k3p4c5l6c"
AES_KEY = KEY_STRING.encode('utf-8')
AES_IV = IV_STRING.encode('utf-8')

PROMPT_NOIDX = """
당신은 건강검진 프로그램 'LifeCoach'의 메뉴 사용법을 안내하는 AI입니다.
사용자가 제공하는 "메뉴"와 "설명"을 읽고, 다음 규칙에 맞춰 출력하십시오.

규칙:
- 답변 시작 인사말은 "요청하신 사항에 대해 답변드리겠습니다." 또는 "요청하신 내용에 대해 안내드리겠습니다." 중 하나를 랜덤하게 선택합니다.
- 이어서, 메뉴와 설명을 분석하여 '메뉴를 사용하는 단계별 절차'를 작성합니다.
- 각 단계를 짧은 명령형 문장으로 정리합니다.
- 각 문장 앞에 1., 2., 3. 식으로 번호를 붙입니다.
- 생략 가능한 항목은 (필요 시 생략 가능합니다)처럼 표시합니다.
- 필요 없는 추가 설명이나 요약 없이 오직 단계 절차만 작성합니다.
- 항상 '버튼'이나 '메뉴' 같은 단어는 작은따옴표('')로 감싸라.
- 중간에 순서가 명확하지 않으면, 최대한 사용자 친화적인 순서로 재정렬해라.

출력 예시:
요청하신 사항에 대해 답변드리겠습니다.

1. 기초관리 메뉴로 들어가세요.
2. 기초정보1을 선택하세요.
3. 좌측 상단에서 검진의사 및 판정의사를 검색합니다.
(이와 같은 스타일로 작성하십시오.)
"""

RPOMPT_EXPLN = """
당신은 건강검진 프로그램 'LifeCoach'의 내부 메뉴 구조와 기능을 정확히 이해하고 있는 전문가 AI입니다.
사용자가 제공하는 "메뉴"와 "설명"을 참고하여, 해당 메뉴의 기능을 내부 설명처럼 자연스럽게 안내하십시오.

규칙:
- 참고 자료에 없는 단어(예: 'ADMIN', 'USER')를 메뉴 경로로 사용하지 마십시오.
- 각 문단은 1~2문장으로 작성하고, **문단 사이에 빈 줄 1줄**을 넣어 가독성을 높이십시오.
- 설명은 마치 메뉴를 직접 만든 사람이 말하는 듯, 친절하지만 전문가스럽게 작성하십시오.
- 불필요한 서두(예: "요청하신 메뉴는...")나 맺음말 없이 곧바로 설명을 시작합니다.
- 설명은 딱딱하거나 기술적으로 쓰지 말고, 사용자 눈높이에 맞춰 쉽게 작성합니다.
- 너무 길게 쓰지 말고, 핵심만 짧고 알기 쉽게 전하세요.
- '메뉴', '버튼' 같은 UI 용어는 작은따옴표('')로 감싸서 표시하십시오.
- 사용자에게 유용한 사용 목적(조회, 분석, 통계 등)을 함께 언급하십시오.
- **제공된 '설명' 외의 기능은 추가로 생성하지 마십시오. 추측하여 기능을 더하지 마십시오.**

출력 예시:
'공단검진관리 > 공단검진 마감 및 청구관리'에서는 수검자의 결과 입력 여부, 마감 처리, 청구 진행 상태 등을 한눈에 확인할 수 있습니다.

공단 검진 전체 진행 상황을 빠르게 파악하고, 누락 없이 마감 및 청구를 관리할 수 있도록 설계되어 있습니다.
"""

RPOMP_PPROC = """
너는 사용자의 질문을 벡터 검색 시스템에 적합하게 전처리하는 AI 도우미다.

목표:
- 질문에 담긴 의도를 명확히 파악하고, 그에 해당하는 기능이나 조치 중심의 문장으로 요약한다.

지시사항:
- 질문의 의도가 '어떤 시스템 기능을 사용하고 싶은가'에 집중되도록 바꿔라.
- 예의, 감탄사, 불필요한 부사어는 제거한다.
- '조회', '등록', '추가', '수정', '삭제'처럼 시스템 행위를 명시하라.
- 시스템명, 병원명 같은 고유명사는 생략해도 된다.
- 연락, 전화, 사람 간 커뮤니케이션은 포함하지 마라.
- 출력은 한 문장만 하라. 예시나 설명은 포함하지 마라.
"""


# GPT에게 답변 요청
def Def_AskChtGpt(Is_PRMPT: str, Is_Quest: str, Is_Refer: str):
    #Ls_ModNm = "gpt-4o"
    Ls_ModNm = "gpt-4o-mini"

    if Is_PRMPT == "NOIDX":
        Ls_RPMPT = PROMPT_NOIDX
    elif Is_PRMPT == "EXPLN":
        Ls_RPMPT = RPOMPT_EXPLN
    else:
        Ls_RPMPT = RPOMPT_EXPLN 

    Lv_RsPns = Ge_client.chat.completions.create(
        model = Ls_ModNm,
        messages=[
            {
                "role": "system",
                "content": Ls_RPMPT
            },
            {
                "role": "user",
                "content": f"질문: {Is_Quest}\n\n참고 자료: {Is_Refer}"
            }
        ]
    )
    return {"ANSWR":Lv_RsPns.choices[0].message.content, "MODEL":Ls_ModNm, "PROMT":Ls_RPMPT} 

# GPT 텍스트 임베딩 전처리
def Def_VecQAgent(Is_TData: str):
    Ls_ModNm = "gpt-4o-mini"
    Ls_RPMPT = RPOMP_PPROC 

    Lv_RsPns = Ge_client.chat.completions.create(
        model = Ls_ModNm,
        messages=[
            {
                "role": "system",
                "content": Ls_RPMPT
            },
            {
                "role": "user",
                "content": Is_TData
            }
        ]
    )
    return {"ANSWR":Lv_RsPns.choices[0].message.content, "MODEL":Ls_ModNm, "PROMT":Ls_RPMPT} 

# AES256 암호화 함수
def Def_Aes256Enc(Is_OData: str) -> str:
    if isinstance(Is_OData, dict):
        Is_OData = json.dumps(Is_OData, ensure_ascii=False)
    else:
        Is_OData = str(Is_OData)

    # 1. PKCS7 패딩
    Lv_Paddr = padding.PKCS7(128).padder()  # AES block size = 128bit = 16byte
    Lv_PadDt = Lv_Paddr.update(Is_OData.encode('utf-8')) + Lv_Paddr.finalize()

    # 2. 암호화
    Lv_Ciphr = Cipher(algorithms.AES(AES_KEY), modes.CBC(AES_IV), backend=default_backend())
    Lv_Enctr = Lv_Ciphr.encryptor()
    Lv_Enctd = Lv_Enctr.update(Lv_PadDt) + Lv_Enctr.finalize()

    # 3. Base64 인코딩해서 문자열로 반환
    return base64.b64encode(Lv_Enctd).decode('utf-8')

# AES256 복호화
def Def_Aes256Dec(Is_OData: str) -> str:
    Lv_VData = base64.b64decode(Is_OData)

    Lv_Ciphr = Cipher(algorithms.AES(AES_KEY), modes.CBC(AES_IV), backend=default_backend())
    Lv_Dectr = Lv_Ciphr.decryptor()
    Lv_DecPd = Lv_Dectr.update(Lv_VData) + Lv_Dectr.finalize()

    # PKCS7 패딩 제거
    unpadder = padding.PKCS7(128).unpadder()  # AES 블록사이즈는 128bit (16byte)
    decrypted = unpadder.update(Lv_DecPd) + unpadder.finalize()

    return decrypted.decode('utf-8')

# 토큰 수 계산
def Def_CountTokn(Is_SText, Is_MDLNM):
    Lv_EnCod = tiktoken.encoding_for_model(Is_MDLNM)
    return len(Lv_EnCod.encode(Is_SText))

# 리턴과 프린트 같이
def Def_RetnValue(Is_MsgTx, Is_SqlCd, Is_Reslt, Is_MsgPt = None):
    Ls_RtMsg = ""
    if Is_MsgPt:
        Ls_RtMsg = Is_MsgPt       
    else:
        Ls_RtMsg = Is_Reslt
        
    print({"Message": Is_MsgTx, "SqlCode": "1", "Result": Ls_RtMsg})
    return {"Message": Is_MsgTx, "SqlCode": Is_SqlCd, "Result": Def_Aes256Enc(Is_Reslt)}

# 해시값 만들기
def Def_MakeDHash(Is_Quest, Is_Answr):
    return hashlib.sha256(f"{Is_Quest}\n{Is_Answr}".encode()).hexdigest()


