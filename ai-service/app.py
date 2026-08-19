"""
RC-OSD AI Support Module side-service.

Handles the two pieces of the thesis's AI Support Module that don't have a
native Java equivalent: OCR of scanned/handwritten appeal letters (pytesseract,
wrapping Tesseract) and keyword/policy matching (spaCy + BM25). PDF/DOCX text
extraction is handled directly in the Java backend via Apache Tika and never
reaches this service.

The Java backend is the only caller of this service -- like the Ollama
integration for the chatbot, it is not exposed on any public-facing port.
"""

import io
from typing import List

import pytesseract
import spacy
from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image
from pydantic import BaseModel
from rank_bm25 import BM25Okapi

app = FastAPI(title="RC-OSD AI Support Module")

_nlp = spacy.load("en_core_web_sm")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/ocr")
async def ocr(file: UploadFile = File(...)):
    """
    Extracts text from a scanned or handwritten appeal letter image using
    Tesseract OCR (via pytesseract).
    """
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        text = pytesseract.image_to_string(image)
        return {"text": text.strip()}
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Could not read image: {e}")


class SuggestionCandidate(BaseModel):
    suggestionId: int
    text: str


class AnalyzeRequest(BaseModel):
    text: str
    suggestions: List[SuggestionCandidate]
    topN: int = 3
    minScore: float = 0.0


class SuggestionMatch(BaseModel):
    suggestionId: int
    score: float


class AnalyzeResponse(BaseModel):
    keywords: List[str]
    matches: List[SuggestionMatch]


def _tokenize(text: str) -> List[str]:
    """
    Uses spaCy to lemmatize and filter down to meaningful keywords -- drops
    stopwords, punctuation, and whitespace tokens, keeps the base (lemma)
    form of each remaining word.
    """
    doc = _nlp(text.lower())
    return [
        token.lemma_
        for token in doc
        if not token.is_stop and not token.is_punct and not token.is_space and token.lemma_.strip()
    ]


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(request: AnalyzeRequest):
    """
    Extracts keywords from the appeal letter text with spaCy, then uses BM25
    to rank the given candidate Suggestion templates by relevance to those
    keywords. Only Suggestion templates already stored in the database are
    considered -- this endpoint decides which existing templates apply, it
    never generates new suggestion text itself.
    """
    if not request.suggestions:
        return AnalyzeResponse(keywords=[], matches=[])

    query_keywords = _tokenize(request.text)

    corpus_tokens = [_tokenize(s.text) for s in request.suggestions]
    bm25 = BM25Okapi(corpus_tokens)
    scores = bm25.get_scores(query_keywords)

    ranked = sorted(
        zip(request.suggestions, scores),
        key=lambda pair: pair[1],
        reverse=True,
    )

    matches = [
        SuggestionMatch(suggestionId=s.suggestionId, score=round(float(score), 4))
        for s, score in ranked
        if score > request.minScore
    ][: request.topN]

    return AnalyzeResponse(keywords=query_keywords[:30], matches=matches)
