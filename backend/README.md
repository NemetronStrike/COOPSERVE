# COOPSERVE Backend

FastAPI backend for COOPSERVE — SIH26089.

## Requirements

- Python 3.11+
- pip

## Setup

### 1. Create and activate a virtual environment

```bash
# Windows
python -m venv .venv
.venv\Scripts\activate

# macOS / Linux
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure environment variables

```bash
# Windows
copy .env.example .env

# macOS / Linux
cp .env.example .env
```

Edit `.env` as needed. The defaults work for local development without changes.

### 4. Start the server

```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

The `--reload` flag enables hot-reload during development.

### 5. Test the health endpoint

```bash
curl http://127.0.0.1:8000/health
```

Expected response:

```json
{"status": "healthy"}
```

### 6. Interactive API docs

Available at http://127.0.0.1:8000/docs (development mode only).

## Project Structure

```
backend/
├── app/
│   ├── main.py            # Application factory, CORS, router registration
│   ├── core/
│   │   └── config.py      # Settings loaded from .env via pydantic-settings
│   ├── api/
│   │   ├── router.py      # Central API router — registers all route modules
│   │   └── routes/
│   │       └── health.py  # GET /health
│   ├── models/            # SQLAlchemy ORM models (future)
│   ├── schemas/           # Pydantic request/response schemas (future)
│   ├── services/          # Business logic services (future)
│   └── repositories/      # Data access layer (future)
├── requirements.txt
├── .env.example
└── README.md
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | Runtime environment |
| `APP_DEBUG` | `true` | Enables `/docs` and `/redoc` |
| `APP_HOST` | `127.0.0.1` | Uvicorn bind host |
| `APP_PORT` | `8000` | Uvicorn bind port |
| `CORS_ORIGINS` | `http://localhost,...` | Comma-separated allowed origins |
| `DATABASE_URL` | _(empty)_ | PostgreSQL URL — not yet implemented |
| `SECRET_KEY` | _(empty)_ | JWT signing key — not yet implemented |
