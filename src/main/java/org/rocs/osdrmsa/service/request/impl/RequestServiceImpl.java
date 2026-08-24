package org.rocs.osdrmsa.service.request.impl;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.domain.person.employee.Employee;
import org.rocs.osdrmsa.domain.request.Request;
import org.rocs.osdrmsa.domain.request.RequestStatus;
import org.rocs.osdrmsa.repository.request.RequestRepository;
import org.rocs.osdrmsa.service.employee.EmployeeService;
import org.rocs.osdrmsa.service.request.RequestService;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class RequestServiceImpl implements RequestService {

    private static final String ENTITY_TYPE = "Request";

    private final RequestRepository requestRepository;
    private final EmployeeService employeeService;

    @Override
    public Request submitRequest(Request request) {

        if (request.getEmployeeID() == null || request.getEmployeeID().isBlank()) {
            throw new IllegalArgumentException("Requesting employeeID is required.");
        }
        if (request.getType() == null || request.getType().isBlank()) {
            throw new IllegalArgumentException("Request type is required.");
        }

        request.setRequestID(0);
        request.setStatus(RequestStatus.PENDING);
        request.setDateFiled(new Date());
        request.setDateProcessed(null);
        request.setRemarks(null);

        Request saved = requestRepository.save(request);
        return saved;
    }

    @Override
    public Request processRequest(Long requestId, RequestStatus decision, String remarks) {

        if (decision != RequestStatus.APPROVED && decision != RequestStatus.DENIED) {
            throw new IllegalArgumentException(
                    "A request can only be processed to APPROVED or DENIED.");
        }

        Request request = requestRepository.findById(requestId)
                .orElseThrow(() -> new NoSuchElementException("Request not found: " + requestId));

        if (request.getStatus() != RequestStatus.PENDING) {
            throw new IllegalArgumentException(
                    "Request " + requestId + " has already been processed (" + request.getStatus() + ").");
        }

        request.setStatus(decision);
        request.setRemarks(remarks);
        request.setDateProcessed(new Date());

        Request saved = requestRepository.save(request);
        return saved;
    }

    @Override
    public List<Request> getByEmployeeId(String employeeId) {
        return requestRepository.findByEmployeeID(employeeId);
    }

    @Override
    public List<Request> getByStatus(RequestStatus status) {
        return requestRepository.findByStatus(status);
    }

    @Override
    public List<Request> getAll() {
        return requestRepository.findAll();
    }

    @Override
    public List<Request> getMyRequests(String username) {
        Employee employee = employeeService.getBySelf(username);
        return requestRepository.findByEmployeeID(employee.getEmployeeId());
    }
}
