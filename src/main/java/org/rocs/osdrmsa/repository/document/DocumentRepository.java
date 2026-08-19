package org.rocs.osdrmsa.repository.document;

import org.rocs.osdrmsa.domain.document.Document;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    List<Document> findByStudentStudentId(String studentId);
}
