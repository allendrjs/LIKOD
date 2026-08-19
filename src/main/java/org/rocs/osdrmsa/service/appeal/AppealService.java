package org.rocs.osdrmsa.service.appeal;

import org.rocs.osdrmsa.domain.appeal.Appeal;
import org.rocs.osdrmsa.dto.summary.AiSuggestionSummary;

import java.util.List;

public interface AppealService {

    List<Appeal> getAppealsByStatus(String status);

    List<Appeal> getAppealsByStudentId(String studentId);

    Appeal submitAppeal(Long recordId, Long enrollmentId, String message, Long documentId);

    void approveAppeal(Long appealId, String remarks);

    void denyAppeal(Long appealId, String remarks);

    /**
     * The AI Support Module's case-specific note for the appeal letter this
     * appeal was filed with. Null if the appeal has no attached document, or
     * if generation failed/produced nothing for that upload.
     */
    AiSuggestionSummary getSuggestionsForAppeal(Long appealId);
}
