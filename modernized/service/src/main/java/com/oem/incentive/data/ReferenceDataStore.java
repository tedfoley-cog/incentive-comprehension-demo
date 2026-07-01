package com.oem.incentive.data;

import com.oem.incentive.model.DealerRef;
import com.oem.incentive.model.ProgramRef;

import jakarta.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Loads dealer and program reference data from the legacy fixed-width flat
 * files. In production this would read from a database; for equivalence
 * testing it reads the same files the COBOL batch uses.
 */
@Component
public class ReferenceDataStore {

    private static final Logger log = LoggerFactory.getLogger(ReferenceDataStore.class);

    @Value("${incentive.dealers-file}")
    private String dealersFile;

    @Value("${incentive.programs-file}")
    private String programsFile;

    private final Map<String, DealerRef> dealers = new LinkedHashMap<>();
    private final Map<String, ProgramRef> programs = new LinkedHashMap<>();

    @PostConstruct
    void load() throws IOException {
        loadDealers();
        loadPrograms();
    }

    private void loadDealers() throws IOException {
        for (String line : Files.readAllLines(Path.of(dealersFile))) {
            if (line.isBlank()) {
                continue;
            }
            String id       = line.substring(0, 6).trim();
            String name     = line.substring(6, 36).trim();
            String region   = line.substring(36, 40).trim();
            boolean enrolled = line.charAt(40) == 'Y';
            char status      = line.charAt(41);

            dealers.put(id, new DealerRef(id, name, region, enrolled, status));
        }
        log.info("Loaded {} dealers", dealers.size());
    }

    private void loadPrograms() throws IOException {
        for (String line : Files.readAllLines(Path.of(programsFile))) {
            if (line.isBlank()) {
                continue;
            }
            // PROGREC layout: id6 desc30 type4 flat9 pct5 start8 end8
            //                 payee1 region4 stack1 reqPrior1 max9 filler14
            String id        = line.substring(0, 6).trim();
            String desc      = line.substring(6, 36).trim();
            String type      = line.substring(36, 40).trim();
            BigDecimal flat  = parsePic9v99(line.substring(40, 49));
            BigDecimal pct   = parsePic9v99_5(line.substring(49, 54));
            int startDate    = Integer.parseInt(line.substring(54, 62).trim());
            int endDate      = Integer.parseInt(line.substring(62, 70).trim());
            char payee       = line.charAt(70);
            String region    = line.substring(71, 75).trim();
            boolean stack    = line.charAt(75) == 'Y';
            boolean reqPrior = line.charAt(76) == 'Y';
            BigDecimal max   = parsePic9v99(line.substring(77, 86));

            programs.put(id, new ProgramRef(id, desc, type, flat, pct,
                    startDate, endDate, payee, region, stack, reqPrior, max));
        }
        log.info("Loaded {} programs", programs.size());
    }

    /** PIC 9(07)V99 : 9 digits, last 2 are decimal places. */
    private static BigDecimal parsePic9v99(String raw) {
        return new BigDecimal(raw.trim()).movePointLeft(2);
    }

    /** PIC 9(03)V99 : 5 digits, last 2 are decimal places. */
    private static BigDecimal parsePic9v99_5(String raw) {
        return new BigDecimal(raw.trim()).movePointLeft(2);
    }

    public DealerRef findDealer(String id) {
        return dealers.get(id);
    }

    public ProgramRef findProgram(String id) {
        return programs.get(id);
    }
}
