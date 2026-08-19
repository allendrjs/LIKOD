package org.rocs.osdrmsa.dto.request;

/**
 * documentId is optional -- it's the id returned from POST /api/documents/upload
 * when the student attached an appeal letter. Null means the appeal was filed
 * without going through the AI Support Module's upload step.
 */
public record AppealFileRequest(Long recordId, Long enrollmentId, String message, Long documentId) {
}