package org.rocs.osdrmsa.service.employee;

import org.rocs.osdrmsa.domain.department.Department;
import org.rocs.osdrmsa.domain.person.employee.Employee;

import java.util.List;
import java.util.Optional;

public interface EmployeeService {

    List<Employee> getAll();

    List<Employee> getByDepartment(Department department);

    Optional<Employee> getById(String employeeId);

    /**
     * Resolves the Employee record for the currently authenticated STAFF
     * user, via Login -> Person -> Employee. Never trust a client-supplied
     * employeeId for "my own info" lookups -- identity always comes from
     * the JWT username, same pattern used for students throughout the app.
     */
    Employee getBySelf(String username);

    Employee create(Employee employee);

    Employee update(String employeeId, Employee employee);

    void delete(String employeeId);
}
