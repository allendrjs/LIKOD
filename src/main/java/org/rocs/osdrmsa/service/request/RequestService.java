package org.rocs.osdrmsa.service.request;

import org.rocs.osdrmsa.domain.request.Request;
import org.rocs.osdrmsa.domain.request.RequestStatus;

import java.util.List;

public interface RequestService {

    Request submitRequest(Request request);

    Request processRequest(Long requestId, RequestStatus decision, String remarks);

    List<Request> getByEmployeeId(String employeeId);

    List<Request> getByStatus(RequestStatus status);

    List<Request> getAll();

    /**
     * The requests filed by the currently authenticated STAFF user (e.g. a
     * Department Head viewing their own submitted requests) -- resolved
     * server-side from the JWT via Employee, never a client-supplied
     * employeeId.
     */
    List<Request> getMyRequests(String username);
}
