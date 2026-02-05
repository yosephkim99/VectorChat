import re, os
import json
import pathlib
import pdfplumber
import camelot
import pandas as pd
from tqdm import tqdm
from PageRange import PAGE_RANGES   # (start, end, TITLE, MNTTL, SBTTL)
import logging
from pdf2image import convert_from_path

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s:%(message)s')

Rv_SCDIR = pathlib.Path(__file__).resolve().parent
Rv_DYEAR  = "2025"

Rv_SCDIR = (Rv_SCDIR / f"{Rv_DYEAR}").resolve() 
Rv_PDFIN = (Rv_SCDIR / f"{Rv_DYEAR}년 건강검진 실시안내 책자 내지.pdf").resolve()
Rv_PFOCR = (Rv_SCDIR / f"{Rv_DYEAR}_OcrOutput.pdf").resolve()

# 1) OCR 수행: 내부 진행바 활성화
#ocrmypdf.ocr(Rv_PDFIN, PDF_OCR, language="kor+eng", deskew=False, progress_bar=True, image_dpi=400, 
#             force_ocr=False, skip_text=False, redo_ocr=True, output_type='pdfa-2')

# --- 텍스트 정제 함수 ------------------------------------------
def Def_CleanText(Is_Texts: str) -> str:
    # 1) 단어 중간 줄바꿈 제거: 문자-줄바꿈-문자 → 문자 공백 문자
    Is_Texts = re.sub(r'(?<=\S)\n(?=\S)', ' ', Is_Texts)
    # 2) 연속된 공백(스페이스, 탭, 줄바꿈)을 단일 스페이스로
    Is_Texts = re.sub(r'\s+', ' ', Is_Texts)
    return Is_Texts.strip()

# 2) pdfplumber로 OCR된 PDF 열기
Rv_SCTON = []
with pdfplumber.open(Rv_PFOCR) as pdf:
    for Fv_Start, Fv_PfEnd, Fv_Title, Fv_MNTTL, Fv_SBTTL in tqdm(PAGE_RANGES, desc="Processing ranges"):
        # 저장경로
        Lv_OsDir = (Rv_SCDIR / f"{Fv_Start}-{Fv_PfEnd}").resolve()
        if not os.path.exists(Lv_OsDir):
            os.mkdir(Lv_OsDir)

        # 본문 텍스트 합치기 + 정제
        Lv_Texts = [
            pdf.pages[p].extract_text(x_tolerance=2, y_tolerance=2) or ""
            for p in range(Fv_Start-1, Fv_PfEnd)
        ]
        Lv_Joind = "\n".join(Lv_Texts)
        Lv_CnTnt = Def_CleanText(Lv_Joind)

        # 페이지 이미지 추출 및 저장
        Lv_Image = convert_from_path(
            Rv_PFOCR,
            first_page=Fv_Start,
            last_page=Fv_PfEnd,
            dpi=200,
            fmt="png"
        )
        for Fv_Index, Fv_Image in enumerate(Lv_Image, start=Fv_Start):
            Fv_SafeT = Fv_Title.replace(" ", "_")
            Fv_ImgNm = f"{Fv_SafeT}_page_{Fv_Index}.png"
            Fv_Image.save(os.path.join(Lv_OsDir, Fv_ImgNm), "PNG")

        # MNTTL/SBTTL 기본값 처리
        if not Fv_MNTTL:
            Fv_MNTTL = Fv_Title
        if not Fv_SBTTL:
            Fv_SBTTL = Fv_Title

        # 저장
        Lv_FJsDr = (Lv_OsDir / f"{Fv_Start}-{Fv_PfEnd}.json").resolve()
        Fv_SCTON = []
        Fv_SCTON.append({
            "documents": Lv_CnTnt,
            "metadatas": {
                "DYEAR": Rv_DYEAR,
                "MNTTL": Fv_MNTTL,
                "SBTTL": Fv_SBTTL,
                "TITLE": Fv_Title,
                "ACCLV": "PUBLIC",
                "HSPCD": ""
            }
        }) 
        Lv_PJSON = pathlib.Path(Lv_FJsDr)
        with Lv_PJSON.open("w", encoding="utf-8") as f:
            json.dump(Fv_SCTON, f, ensure_ascii=False, indent=2)

# 4) 저장
print("작업이 완료되었습니다!")