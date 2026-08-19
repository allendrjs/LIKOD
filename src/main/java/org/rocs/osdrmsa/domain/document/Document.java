package org.rocs.osdrmsa.domain.document;

import jakarta.persistence.*;
import lombok.Data;
import org.rocs.osdrmsa.domain.person.student.Student;

/**
 * Stores information about an uploaded appeal document (a scanned/handwritten
 * letter or a directly uploaded PDF/DOCX). Matches Table 14 (Document Table) in
 * the thesis paper -- documentID, extractedText, linked to the Student who
 * uploaded it. The raw file itself is not persisted, only the text extracted
 * from it by the AI Support Module (Tesseract OCR for images, Apache Tika for
 * PDF/DOCX).
 */
@Entity
@Data
@Table(name = "DOCUMENT")
public class Document {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "DOCUMENTID")
    private Long documentId;

    @ManyToOne
    @JoinColumn(name = "STUDENTID")
    private Student student;

    @Lob
    @Column(name = "EXTRACTEDTEXT")
    private String extractedText;
}
