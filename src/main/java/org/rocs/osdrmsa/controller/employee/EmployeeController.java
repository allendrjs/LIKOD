package org.rocs.osdrmsa.controller.employee;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.dto.mapper.CommonDtoMapper;
import org.rocs.osdrmsa.dto.summary.EmployeeSummary;
import org.rocs.osdrmsa.service.employee.EmployeeService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Deliberately has NO employeeId path parameter for the "self" endpoint --
 * it always answers for whoever is authenticated, resolved server-side from
 * the JWT, same pattern used for students throughout the app.
 */
@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeService employeeService;

    @GetMapping("/me")
    @PreAuthorize("hasRole('STAFF')")
    public ResponseEntity<EmployeeSummary> getMyEmployeeInfo(Authentication authentication) {
        EmployeeSummary summary = CommonDtoMapper.toEmployeeSummary(
                employeeService.getBySelf(authentication.getName()));
        return ResponseEntity.ok(summary);
    }
}
