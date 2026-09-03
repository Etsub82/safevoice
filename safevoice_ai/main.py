from fastapi import FastAPI
from routers import assess, transcribe, translate

app = FastAPI(title="SafeVoice AI Service", version="1.0.0")

app.include_router(assess.router, prefix="/ai")
app.include_router(transcribe.router, prefix="/ai")
app.include_router(translate.router, prefix="/ai")


@app.get("/health")
def health():
    return {"status": "ok"}
