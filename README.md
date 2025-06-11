# AI기반 멘토-멘티 협업 프로젝트 추천 서비스 <br/>(AI-based, collaborative project Recommendation service<br/>for mentor-mentee)

충북대 소프트웨어학부 오픈소스 기초프로젝트
<br/>Chungbuk National University School of Computer Science
Fundamental of Open Source SW Project

개발기간(Development Period) : 2025.03 ~

## 프로젝트 소개
- 해당 서비스는 단순 매칭을 넘어 멘토 멘티의 관심사에 맞는 협업 프로젝트를 제시해줍니다.
- 게시판 글 작성 또는 게시판 선택을 통해 멘토 - 멘티를 구할 수 있습니다.
- 멘토 멘티 매칭 후 채팅기능을 통해 대화를 나눌 수 있습니다.(멘토링 일정 조정 또는 관심 주제에 대해 얘기를 나눠보세요)
- 프로젝트 생성 버튼을 누르면 AI가 게시판 및 사용자의 대화내용을 읽은 후 협업 프로젝트를 추천합니다
- 게시판의 내용 또는 나눈 대화의 내용이 많거나 상세하게 되어있으면 AI가 더 좋은 협업프로젝트를 추천합니다.

>English
- This service goes beyond simple matching — it suggests collaborative projects tailored to the shared interests of mentors and mentees.
- You can find mentors or mentees either by creating a post or browsing the bulletin board.
- Once matched, you can chat with your partner to schedule mentoring sessions or discuss topics of mutual interest.
- By clicking the "Create Project" button, the AI analyzes bulletin posts and your chat history to recommend a suitable collaborative project.
- The more detailed your posts and conversations are, the better the AI can suggest meaningful and relevant project ideas.


## 개발환경
- front : __Flutter__
- back-end : __Flask__
- version-control : __Github__
- design : __Flutter-Flow__

## 프로젝트 구조 - 주요폴더
```
┣backend
┃  ┣ routes
┃  ┃ ┗ ..     - 주요 API 라우팅 파일(.py)
┃  ┣ uploads  - 업로드된 이미지 자원
┃  ┗ app.py   - flask 백엔드 진입점
┃
┣ frontend
┃  ┣ assets   - 이미지 자원
┃  ┣ lib      - 주요 Dart파일
┃  ┗ pubspec.yaml - 패키지 및 의존성 설정
┣ .gitignore
┗ README.md
```

## 완성도 
80%
