package org.rocs.osdrmsa.repository.handbook;

import org.rocs.osdrmsa.domain.department.Department;
import org.rocs.osdrmsa.domain.handbook.HandbookSection;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HandbookSectionRepository extends JpaRepository<HandbookSection, Long> {

    List<HandbookSection> findByDepartment(Department department);
}
