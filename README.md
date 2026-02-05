# VectorChat – RAG 기반 챗봇 서버

## 📌 프로젝트 소개
본 프로젝트는 Python API 서버와 Qdrant 벡터 DB, GPT 모델을 결합한 지식 기반 챗봇 시스템입니다.

델파이로 제작된 채팅 UI에서 사용자 질문을 서버로 전달하면,
서버는 저장된 지식을 검색하고 자연어 형태로 정리된 답변을 제공합니다.

단순 GPT 응답이 아니라 내부 DB 기반 검색을 우선 수행하는
RAG(Retrieval-Augmented Generation) 구조를 사용합니다.


## 🔄 동작 흐름
1. 사용자가 델파이 채팅 UI에서 질문 입력
2. Python API 서버로 질문 전달
3. Qdrant DB에서 벡터 유사도 검색 수행
4. 검색 실패 시 GPT를 이용해 질문을 검색 최적화 형태로 재작성
5. 재작성된 질문으로 DB 재검색 수행
6. 검색된 답변을 사용자에게 자연어 형태로 전달

동작 구조:

사용자 질문
    ↓
벡터 검색
    ↓ (실패 시)
질문 재작성 (GPT)
    ↓
재검색
    ↓
답변 반환


## ⭐ 주요 특징
- DB 기반 지식 검색 우선 처리
- 검색 실패 시 자동 질문 재구성 후 재검색 수행
- GPT는 답변 생성이 아닌 자연어 정리 역할 중심
- 델파이 프로그램과 실시간 연동
- 내부 지식 기반 챗봇 구축 가능


## ⚙ 사용 기술
Language: Python, Delphi  
API Server: FastAPI  
Vector DB: Qdrant (Docker)  
Embedding Model: BAAI/bge-m3  
LLM: GPT-4o-mini (OpenAI API)  
Encryption: AES-256  
Client UI: Delphi Chat Interface


## ▶ 실행 방법
1. Qdrant 실행
docker run -p 6333:6333 qdrant/qdrant

2. Python 서버 실행
uvicorn API:app --host 0.0.0.0 --port 8000

3. 델파이 프로그램에서 API 호출


## 💡 프로젝트 목적
- GPT + 벡터 검색 기반 챗봇 구조 구현
- 실서비스 연동 가능한 API 서버 구조 설계
- 내부 지식 기반 QA 자동화


## 📌 향후 개선 계획
- 검색 실패 시 fallback 응답 개선
- 다중 문서 참조 응답 생성
- 관리자 학습 데이터 자동 업데이트 기능