package org.rocs.osdrmsa.service.document;

import org.rocs.osdrmsa.dto.response.DocumentUploadResponse;

public interface DocumentService {

    /**
     * Processes an appeal-letter upload on behalf of the currently
     * authenticated student: extracts its text (Tess4j/Tesseract OCR for
     * images, Apache Tika for PDF/DOCX -- both in-process, no external
     * service), saves it as a Document, runs an in-process BM25 retrieval
     * step against the existing Suggestion templates to gather policy hints,
     * then sends those hints plus the student's case history to Ollama to
     * generate a case-specific suggestion, persisted as a GeneratedSuggestion
     * row.
     *
     * @param username the authenticated principal's login username (not the
     *                 studentId) -- resolved server-side, same as the chat
     *                 endpoint, so a student can never upload on behalf of
     *                 someone else.
     */
    DocumentUploadResponse processAppealUpload(String username, byte[] fileBytes, String filename);
}
