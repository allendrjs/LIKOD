package org.rocs.osdrmsa.dto.request;

/**
 * No employeeId here on purpose -- the submitter is always resolved
 * server-side from the JWT (see RequestController.submit()), same
 * never-trust-a-client-supplied-ID convention used everywhere else in
 * this app (EmployeeService.getBySelf, RequestService.getMyRequests).
 */
public record RequestSubmitRequest(String details, String message, String type) {
}
