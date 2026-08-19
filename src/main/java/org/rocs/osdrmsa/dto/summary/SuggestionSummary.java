package org.rocs.osdrmsa.dto.summary;

public record SuggestionSummary(
        Long suggestionId,
        String type,
        String suggestionText,
        Double score
) {
}
