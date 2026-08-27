package org.rocs.osdrmsa.service.handbook;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.domain.department.Department;
import org.rocs.osdrmsa.domain.handbook.HandbookSection;
import org.rocs.osdrmsa.repository.handbook.HandbookSectionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Loads the three transcribed Student Handbook markdown files (bundled as
 * classpath resources under src/main/resources/handbook/) into the
 * HANDBOOKSECTION table on application startup, one department at a time.
 *
 * Runs once: if the table already has rows, this is a no-op, so re-deploys
 * don't duplicate data. To re-ingest after editing a handbook file, truncate
 * HANDBOOKSECTION and restart the app.
 */
@Component
@RequiredArgsConstructor
public class HandbookSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(HandbookSeeder.class);

    private static final Map<Department, String> SOURCE_FILES = new LinkedHashMap<>();

    static {
        SOURCE_FILES.put(Department.JHS, "handbook/jhs.md");
        SOURCE_FILES.put(Department.SHS, "handbook/shs.md");
        SOURCE_FILES.put(Department.COLLEGE, "handbook/college.md");
    }

    private final HandbookSectionRepository handbookSectionRepository;

    @Override
    public void run(ApplicationArguments args) {
        if (handbookSectionRepository.count() > 0) {
            log.info("Handbook already ingested ({} sections on file) -- skipping seeding.",
                    handbookSectionRepository.count());
            return;
        }

        int totalSaved = 0;
        for (Map.Entry<Department, String> entry : SOURCE_FILES.entrySet()) {
            totalSaved += ingest(entry.getKey(), entry.getValue());
        }

        log.info("Handbook seeding complete: {} sections ingested across {} departments.",
                totalSaved, SOURCE_FILES.size());
    }

    private int ingest(Department department, String classpathLocation) {
        String markdown;
        try (InputStream in = new ClassPathResource(classpathLocation).getInputStream()) {
            markdown = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            log.warn("Could not read handbook source {} for department {} -- skipping. ({})",
                    classpathLocation, department, e.getMessage());
            return 0;
        }

        List<HandbookMarkdownParser.ParsedSection> parsed = HandbookMarkdownParser.parse(markdown);

        List<HandbookSection> sections = parsed.stream().map(p -> {
            HandbookSection section = new HandbookSection();
            section.setDepartment(department);
            section.setTitle(p.title());
            section.setBody(p.body());
            section.setOrderIndex(p.orderIndex());
            return section;
        }).toList();

        handbookSectionRepository.saveAll(sections);
        log.info("Ingested {} handbook sections for {} from {}.", sections.size(), department, classpathLocation);
        return sections.size();
    }
}
