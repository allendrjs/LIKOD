package org.rocs.osdrmsa.service.handbook;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Splits one of the transcribed Student Handbook markdown files (see
 * src/main/resources/handbook/*.md) into a flat list of (title, body)
 * sections, one per markdown heading (# / ## / ###). Each heading's body is
 * everything up to the next heading of any level.
 *
 * This is intentionally simple -- the handbook files were transcribed with a
 * consistent, shallow heading structure (see their own headings for the
 * convention), so a plain heading-boundary split is enough to produce
 * reasonably sized, individually retrievable chunks. No attempt is made to
 * nest subsections under their parent section; every heading becomes its own
 * flat, independently-searchable chunk, which is what BM25 retrieval wants
 * anyway.
 */
public final class HandbookMarkdownParser {

    private static final Pattern HEADING = Pattern.compile("^(#{1,3})\\s+(.*)$");
    private static final int MIN_BODY_LENGTH = 20;

    private HandbookMarkdownParser() {
    }

    public record ParsedSection(String title, String body, int orderIndex) {
    }

    public static List<ParsedSection> parse(String markdown) {
        List<ParsedSection> sections = new ArrayList<>();
        if (markdown == null || markdown.isBlank()) {
            return sections;
        }

        String[] lines = markdown.split("\n", -1);

        String currentTitle = null;
        StringBuilder currentBody = new StringBuilder();
        int orderIndex = 0;

        for (String rawLine : lines) {
            String line = rawLine.stripTrailing();
            Matcher matcher = HEADING.matcher(line);

            if (matcher.matches()) {
                flush(sections, currentTitle, currentBody, orderIndex);
                if (currentTitle != null) {
                    orderIndex++;
                }
                currentTitle = matcher.group(2).trim();
                currentBody = new StringBuilder();
            } else {
                currentBody.append(line).append('\n');
            }
        }
        flush(sections, currentTitle, currentBody, orderIndex);

        return sections;
    }

    private static void flush(List<ParsedSection> sections, String title, StringBuilder body, int orderIndex) {
        if (title == null) {
            return;
        }
        String bodyText = body.toString().trim();
        if (bodyText.length() < MIN_BODY_LENGTH) {
            return;
        }
        sections.add(new ParsedSection(title, bodyText, orderIndex));
    }
}
