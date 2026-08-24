package org.rocs.osdrmsa.domain.request;

import jakarta.persistence.*;
import lombok.Data;

import java.util.Date;

@Entity
@Data
public class Request {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "requestID", nullable = false, updatable = false)
    private long requestID;

    @Column(name = "employeeID", nullable = false)
    private String employeeID;

    @Column(name = "details", nullable = false)
    private String details;

    @Column(name = "message", nullable = false)
    private String message;

    @Column(name = "type", nullable = false)
    private String type;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private RequestStatus status;

    @Column(name = "dateFiled")
    private Date dateFiled;

    @Column(name = "dateProcessed")
    private Date dateProcessed;

    @Column(name = "remarks")
    private String remarks;

}
