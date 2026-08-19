package org.rocs.osdrmsa.dto.summary;

import java.time.LocalDateTime;

/**
 * The AI Support Module's generated note for an appeal's letter, as
 * returned by GET /api/appeals/{id}/suggestions (PREFECT/ADMIN only).
 */
public record AiSuggestionSummary(String generatedText, LocalDateTime generatedAt) {
}
