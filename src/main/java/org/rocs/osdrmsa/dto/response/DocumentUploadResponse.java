package org.rocs.osdrmsa.dto.response;

/**
 * Returned to whoever called POST /api/documents/upload -- in practice,
 * always the student who uploaded their own appeal letter. `aiSuggestion` is
 * a case-specific note Ollama generated for this letter (grounded in the
 * letter's own text, the student's real violation history, and retrieved
 * policy hints) -- null if generation failed or the letter had no usable
 * text, since AI failures never block filing the appeal itself. This is an
 * informational note, not a decision -- the appeal's outcome is still
 * entirely up to the Prefect. The same note remains retrievable later via
 * the PREFECT/ADMIN-only GET /api/appeals/{id}/suggestions endpoint.
 */
public record DocumentUploadResponse(
        Long documentId,
        String extractedText,
        String aiSuggestion
) {
}
