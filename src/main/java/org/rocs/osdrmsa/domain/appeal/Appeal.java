package org.rocs.osdrmsa.domain.appeal;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import org.rocs.osdrmsa.domain.document.Document;
import org.rocs.osdrmsa.domain.enrollment.Enrollment;
import org.rocs.osdrmsa.domain.record.Record;

import java.time.LocalDate;

@Entity
@Data
@Table(name = "APPEAL")
public class Appeal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "APPEALID")
    private Long appealId;

    @ManyToOne
    @JoinColumn(name = "RECORDID")
    private Record record;

    @ManyToOne
    @JoinColumn(name = "ENROLLMENTID")
    private Enrollment enrollment;

    /**
     * The appeal letter this appeal was filed with, if one was uploaded
     * through the AI Support Module (OCR/Tika extraction + suggestion
     * matching happens against this Document). Nullable -- older appeals
     * filed before the upload flow existed, or appeals filed without an
     * attachment, won't have one.
     *
     * @JsonIgnore: Appeal entities are returned directly (no DTO) from
     * several endpoints, including ones students can call for their own
     * appeals (GET /api/appeals/student/{studentId}). Serializing this
     * would leak the letter's extracted text -- and, by extension, the fact
     * that AI suggestions exist for it -- to the student. Suggestions stay
     * accessible only through the PREFECT/ADMIN-only
     * GET /api/appeals/{id}/suggestions endpoint, which looks this up
     * server-side without ever exposing it over JSON.
     */
    @ManyToOne
    @JoinColumn(name = "DOCUMENTID")
    @JsonIgnore
    private Document document;

    @Column(name = "MESSAGE")
    private String message;

    @Column(name = "DATEFILED")
    private LocalDate dateFiled;

    @Column(name = "STATUS")
    private String status;

    @Column(name = "DATEPROCESSED")
    private LocalDate dateProcessed;

    @Column(name = "REMARKS")
    private String remarks;
}
