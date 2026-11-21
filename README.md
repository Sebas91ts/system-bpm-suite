# System BPM Suite

> AI-assisted Business Process Management across web, mobile and backend services.

![Java](https://img.shields.io/badge/Java-17-ED8B00?style=flat-square&logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5-6DB33F?style=flat-square&logo=springboot&logoColor=white)
![Camunda](https://img.shields.io/badge/Camunda-7.23-FC5D0D?style=flat-square&logo=camunda&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=flat-square&logo=mongodb&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-FF6F00?style=flat-square&logo=tensorflow&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?style=flat-square&logo=google&logoColor=white)
![Angular](https://img.shields.io/badge/Angular-21-DD0031?style=flat-square&logo=angular&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind%20CSS-06B6D4?style=flat-square&logo=tailwindcss&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)

## Overview

BPM initiatives usually split process modelling, task execution, document handling and AI support across disconnected tools. **System BPM Suite** brings those pieces together in one repository:

- a **Spring Boot + Camunda core** for process definitions, instances, tasks, documents and permissions;
- a **FastAPI AI service** for process analysis, diagram generation, intelligent routing and an assistant;
- an **Angular web client** for administrators, analysts and clients;
- a **Flutter mobile client** for process tracking, tasks and notifications.

The result is a single platform where a process can be designed, executed, monitored and improved with AI assistance.

## Architecture

```text
system-bpm-suite/
├── backend-core/   Spring Boot 3.5 + Camunda 7.23 + MongoDB
├── ai-service/     FastAPI + Google Gemini + TensorFlow/Keras
├── frontend/       Angular 21 + BPMN.js + Yjs + Tailwind CSS
└── mobile/         Flutter + Riverpod + Dio + Firebase
```

```text
Angular web client ───────┐
                          ├── REST / WebSocket ──► backend-core ──► Camunda
Flutter mobile client ────┘                           │
                                                      ├──► MongoDB
                                                      └──► ai-service ──► Gemini API
                                                                  └──► Keras delay-risk model
```

The frontend also runs a small Yjs collaboration server for real-time BPMN editing.

## Modules

| Module | Stack | Responsibility |
|---|---|---|
| `backend-core/` | Java 17, Spring Boot 3.5, Camunda 7.23, MongoDB, JWT, OnlyOffice, AWS S3, Cloudinary, Firebase Admin | Process engine, task lifecycle, documents, areas, forms, notifications, audit, real-time events |
| `ai-service/` | Python, FastAPI, Pydantic, Google GenAI, TensorFlow/Keras | Assistant, process analysis, BPMN generation, form filling, routing recommendations, enterprise reports |
| `frontend/` | Angular 21, TypeScript, Tailwind CSS 4, BPMN.js, Yjs, PWA | Admin dashboards, process designer, task inbox, document workspace, client portal |
| `mobile/` | Flutter, Riverpod, Dio, Firebase Messaging, secure storage | Client process tracking, tasks, notifications, assistant, profile settings |

### Core backend modules

`ai`, `area`, `audit`, `bpmn`, `camunda`, `client`, `dashboard`, `document`, `file`, `form`, `notification`, `process`, `processinstance`, `processmonitoring`, `processtracking`, `realtime`, `security`, `taskexecutionlog`, `taskinstance`, `user`.

## Getting started

### Prerequisites

- Java 17+
- Node.js 20+ and npm 10+
- Python 3.11+
- Flutter 3.11+ / Dart 3.11+
- MongoDB 6+
- A Google Gemini API key
- Optional: Camunda 7 engine, OnlyOffice Document Server, AWS S3, Cloudinary, Firebase project

### 1. Backend core

```bash
cd backend-core/system-backend
cp .env.example .env
# Edit .env with MongoDB, JWT, Camunda, Cloudinary, S3 and Firebase values
./mvnw spring-boot:run
```

On Windows:

```powershell
cd backend-core\system-backend
copy .env.example .env
mvnw.cmd spring-boot:run
```

The API starts on `http://localhost:8080`. Camunda web apps are exposed by the embedded engine.

### 2. AI service

```bash
cd ai-service
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env             # set GEMINI_API_KEY and GEMINI_MODEL
uvicorn main:app --reload --port 8000
```

Interactive API docs: `http://localhost:8000/docs`.

### 3. Web client

```bash
cd frontend
npm ci
npm start
```

The app runs on `http://localhost:4200`. API endpoints are configured in `src/environments/environment.ts`.

For real-time BPMN collaboration:

```bash
npm run collab:server
```

### 4. Mobile client

```bash
cd mobile
flutter pub get
cp .env.example .env
flutter run
```

## AI service endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/ai/assistant` | Conversational assistant |
| `POST` | `/ai/fill-form` | AI-assisted form completion |
| `POST` | `/ai/analyze` | Task and area analysis |
| `POST` | `/ai/analyze-process` | End-to-end process analysis |
| `POST` | `/ai/generate-diagram` | Generate a BPMN diagram from a description |
| `POST` | `/ai/edit-diagram` | Edit an existing diagram with natural language |
| `POST` | `/ai/assist` | Enterprise AI assistance |
| `POST` | `/ai/recommend-process` | Process improvement recommendations |
| `POST` | `/ai/reports` | Report planning |
| `POST` | `/ai/document-analysis` | Document understanding |
| `POST` | `/ai/voice` | Voice-oriented assistance |
| `POST` | `/ai/routing/predict-task` | Task delay-risk prediction |
| `POST` | `/ai/routing/predict-instance` | Instance delay-risk prediction |
| `POST` | `/ai/routing/recommend-assignment` | Assignment recommendation |
| `POST` | `/ai/routing/dashboard` | Routing dashboard metrics |

## Environment variables

Each module has its own `.env.example`. Never commit a real `.env`.

| Module | Key variables |
|---|---|
| `backend-core` | `MONGODB_URI`, `MONGODB_DATABASE`, `JWT_SECRET`, `CAMUNDA_BASE_URL`, `CAMUNDA_ADMIN_PASSWORD`, `CLOUDINARY_*`, `AWS_*`, `FIREBASE_*`, `FASTAPI_BASE_URL` |
| `ai-service` | `GEMINI_API_KEY` or `GEMINI_API_KEYS`, `GEMINI_MODEL`, `GEMINI_MODEL_FALLBACKS` |
| `frontend` | `src/environments/environment.ts` (`apiUrl`, `camundaUrl`, `fastapiUrl`, `wsUrl`, `yjsUrl`) |
| `mobile` | `API_BASE_URL`, `FIREBASE_*` |

## Security

- No `.env` files, private keys or SMTP credentials are tracked.
- Secrets are read from environment variables in every module.
- Rotate any credential that was ever committed before deploying.
- Firebase client keys in the mobile app are public identifiers; restrict them in Google Cloud Console.

## A note on provenance

This monorepo consolidates the former `Examen-Software`, `system-ai`, `frontend-system` and `system_movile` repositories. Full commit history is preserved with `git subtree`; secrets found in the original history were redacted before publication.
