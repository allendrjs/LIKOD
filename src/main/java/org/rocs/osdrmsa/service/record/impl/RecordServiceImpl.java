package org.rocs.osdrmsa.service.record.impl;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.domain.department.Department;
import org.rocs.osdrmsa.domain.record.RecordStatus;
import org.rocs.osdrmsa.domain.record.Record;
import org.rocs.osdrmsa.repository.record.RecordRepository;
import org.rocs.osdrmsa.service.record.RecordService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class RecordServiceImpl implements RecordService {

    private static final String ENTITY_TYPE = "Record";

    private final RecordRepository recordRepository;

    @Override
    public Record createStudentRecord(Record record) {

        if (record == null
                || record.getEmployee() == null
                || record.getEmployee().getEmployeeId() == null
                || record.getDateOfViolation() == null) {
            throw new IllegalArgumentException(
                    "Record or record employee, employeeId, or Date of violation are null."
            );
        }

        if (record.getRemarks() != null
                && record.getRemarks().length() > 500) {
           throw new IllegalArgumentException(
                   "Record Remarks is null and must not exceed 500 characters."
           );
        }

        record.setRecordId(0L);
        record.setStatus(RecordStatus.PENDING);

        return recordRepository.save(record);
    }

    @Override
    public Record updateStudentRecord(Record record) {

        if (record == null
                || record.getRecordId() <= 0
                || record.getEmployee() == null
                || record.getEmployee().getEmployeeId() == null
                || record.getDateOfViolation() == null) {
            throw new IllegalArgumentException(
                    "Record or record employee, employeeId, or Date of violation are null."
            );
        }

        if (record.getRemarks() != null
                && record.getRemarks().length() > 500) {
            throw new IllegalArgumentException(
                    "Record Remarks is null and must not exceed 500 characters."
            );
        }

        // RecordUpdateRequest only carries the editable detail fields (enrollment,
        // employee, offense, date of violation, action, remarks) -- it has no
        // status or dateOfResolution. Building a fresh Record from that DTO and
        // saving it directly would blank out whichever status/resolution date the
        // record already had (e.g. wiping APPEALED back to null). Load the
        // existing row instead and only overwrite the fields this endpoint is
        // actually meant to edit, so status transitions set elsewhere
        // (create/resolve/appeal) survive an unrelated detail edit.
        Record existing = recordRepository.findById(record.getRecordId())
                .orElseThrow(() -> new NoSuchElementException("Record not found: " + record.getRecordId()));

        existing.setEnrollment(record.getEnrollment());
        existing.setEmployee(record.getEmployee());
        existing.setOffense(record.getOffense());
        existing.setDateOfViolation(record.getDateOfViolation());
        existing.setAction(record.getAction());
        existing.setRemarks(record.getRemarks());

        return recordRepository.save(existing);
    }

    @Override
    public Record resolveRecord(Long recordId) {

        Record record = recordRepository.findById(recordId)
                .orElse(null);

        if (record == null) {
            throw new IllegalArgumentException(
                    "Resolve Records are not found."
            );
        }

        record.setStatus(RecordStatus.RESOLVED);
        record.setDateOfResolution(LocalDate.now());

        return recordRepository.save(record);
    }

    @Override
    public List<Record> getRecordByStudentId(String studentId) {
        return recordRepository.findByEnrollmentStudentStudentId(studentId);
    }


    @Override
    public List<Record> getViolationsByDepartment(
            Department department,
            String schoolYear) {

        return recordRepository
                .findByEnrollmentDepartmentAndEnrollmentSchoolYear(
                        department,
                        schoolYear);
    }

}
