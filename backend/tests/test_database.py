import importlib

def test_database_url_normalization(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgres://user:pass@host/db")
    
    # Reload config and database to pick up new env var
    from app.core import config
    importlib.reload(config)
    settings = config.get_settings()
    
    assert settings.database_url == "postgres://user:pass@host/db"
    
    from app.core import database
    importlib.reload(database)
    
    assert database.db_url == "postgresql+psycopg://user:pass@host/db"
    assert str(database.engine.url.render_as_string(hide_password=False)) == "postgresql+psycopg://user:pass@host/db"
