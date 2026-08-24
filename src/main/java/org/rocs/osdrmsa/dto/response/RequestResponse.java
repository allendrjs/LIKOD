package org.rocs.osdrmsa.dto.response;

import org.rocs.osdrmsa.domain.request.RequestStatus;

import java.time.LocalDate;

public record RequestResponse(
        long requestId,
        String employeeId,
        String details,
        String message,
        String type,
        RequestStatus status,
        LocalDate dateFiled,
        LocalDate dateProcessed,
        String remarks) {
}
