package org.rocs.osdrmsa.dto.summary;

import java.time.LocalDate;

public record EmployeeSummary(
        String employeeId,
        String fullName,
        String employeeRole,
        String department,
        LocalDate dateOfBirth) {
}