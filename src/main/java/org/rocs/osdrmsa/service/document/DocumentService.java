package org.rocs.osdrmsa.service.document;

import org.rocs.osdrmsa.dto.response.DocumentUploadResponse;

public interface DocumentService {

    /**
     * Processes an appeal-letter upload on behalf of the currently
     * authenticated student: extracts its text (Tesseract OCR for images via
     * the AI sidecar, Apache Tika in-process for PDF/DOCX), saves it as a
     * Document, runs spaCy/BM25 keyword-and-policy matching against the
     * existing Suggestion templates, and persists any matches as
     * GeneratedSuggestion rows.
     *
     * @param username the authenticated principal's login username (not the
     *                 studentId) -- resolved server-side, same as the chat
     *                 endpoint, so a student can never upload on behalf of
     *                 someone else.
     */
    DocumentUploadResponse processAppealUpload(String username, byte[] fileBytes, String filename);
}
