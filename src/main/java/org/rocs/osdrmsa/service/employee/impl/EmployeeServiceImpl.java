package org.rocs.osdrmsa.service.employee.impl;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.domain.department.Department;
import org.rocs.osdrmsa.domain.login.Login;
import org.rocs.osdrmsa.domain.person.employee.Employee;
import org.rocs.osdrmsa.repository.employee.EmployeeRepository;
import org.rocs.osdrmsa.repository.login.LoginRepository;
import org.rocs.osdrmsa.service.employee.EmployeeService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class EmployeeServiceImpl implements EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final LoginRepository loginRepository;

    @Override
    public List<Employee> getAll() {
        return employeeRepository.findAll();
    }

    @Override
    public List<Employee> getByDepartment(Department department) {
        return employeeRepository.findByDepartment(department);
    }

    @Override
    public Optional<Employee> getById(String employeeId) {
        return employeeRepository.findById(employeeId);
    }

    @Override
    public Employee create(Employee employee) {
        if (employee.getEmployeeId() == null || employee.getEmployeeId().isBlank()) {
            throw new IllegalArgumentException("employeeId is required.");
        }
        if (employeeRepository.existsById(employee.getEmployeeId())) {
            throw new IllegalArgumentException(
                    "Employee " + employee.getEmployeeId() + " already exists.");
        }
        return employeeRepository.save(employee);
    }

    @Override
    public Employee update(String employeeId, Employee employee) {
        Employee existing = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new NoSuchElementException("Employee not found: " + employeeId));

        existing.setPerson(employee.getPerson());
        existing.setDepartment(employee.getDepartment());
        existing.setEmployeeRole(employee.getEmployeeRole());

        return employeeRepository.save(existing);
    }

    @Override
    public void delete(String employeeId) {
        employeeRepository.deleteById(employeeId);
    }

    @Override
    public Employee getBySelf(String username) {
        Login login = loginRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalStateException("No account found for the current session."));

        if (login.getPerson() == null) {
            throw new IllegalStateException("This account isn't linked to a person record.");
        }

        return employeeRepository.findByPerson_PersonId(login.getPerson().getPersonId())
                .orElseThrow(() -> new IllegalStateException("No employee profile found for the current session."));
    }
}
