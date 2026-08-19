# RC-OSD AI Support Module (side-service)

Implements the two pieces of the thesis's AI Support Module that need Python:
OCR (Tesseract, via pytesseract) for scanned/handwritten appeal letters, and
keyword/policy matching (spaCy + BM25) to pick relevant predefined Suggestion
templates for a Prefect reviewing an appeal.

PDF/DOCX text extraction does **not** go through this service — that's
handled directly in the Java backend via Apache Tika, which is a native Java
library and needs no extra runtime.

This service is only ever called by the Java backend (`AiAnalysisClient`). It
should not be exposed on a public port — same rule as the Ollama chatbot
integration.

## Setup

1. Install Tesseract itself (the OCR engine binary, not just the Python wrapper):
   - Windows: https://github.com/UB-Mannheim/tesseract/wiki — run the installer,
     then make sure the install folder is on PATH (or set the path explicitly,
     see below).
   - macOS: `brew install tesseract`
   - Linux: `apt install tesseract-ocr`

2. Create a virtual environment and install dependencies:
   ```
   python -m venv venv
   venv\Scripts\activate        (Windows)
   source venv/bin/activate     (macOS/Linux)
   pip install -r requirements.txt
   ```

3. Download the spaCy English model (small, ~15MB):
   ```
   python -m spacy download en_core_web_sm
   ```

4. Run the service:
   ```
   uvicorn app:app --host 0.0.0.0 --port 8001
   ```
   Confirm it's up: `http://localhost:8001/health` should return `{"status": "ok"}`.

5. The backend expects it at `http://localhost:8001` by default — configurable
   via `AI_SERVICE_BASE_URL` if you run it somewhere else.

## If pytesseract can't find Tesseract

If you get a `TesseractNotFoundError`, the tesseract binary isn't on PATH. Set
it explicitly at the top of `app.py`:
```python
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
```
