package com.bousselha.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.bousselha.application.service.FinancialService;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Met à jour le schéma MySQL lorsque ddl-auto=update ne modifie pas les colonnes ENUM existantes.
 */
@Component
public class DatabaseSchemaMigration implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(DatabaseSchemaMigration.class);

    private final JdbcTemplate jdbcTemplate;
    private final FinancialService financialService;

    public DatabaseSchemaMigration(JdbcTemplate jdbcTemplate, FinancialService financialService) {
        this.jdbcTemplate = jdbcTemplate;
        this.financialService = financialService;
    }

    @Override
    public void run(ApplicationArguments args) {
        migrateContractStatusColumn();
        migrateMaintenanceStatusColumn();
        financialService.syncLedgerFromExistingData();
    }

    private void migrateContractStatusColumn() {
        try {
            jdbcTemplate.execute("""
                    ALTER TABLE contracts
                    MODIFY COLUMN status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS'
                    """);
            log.info("Colonne contracts.status migrée vers VARCHAR(30) avec support IN_PROGRESS");
        } catch (Exception e) {
            log.warn("Migration contracts.status ignorée ou déjà appliquée: {}", e.getMessage());
        }
    }

    private void migrateMaintenanceStatusColumn() {
        try {
            jdbcTemplate.execute("""
                    ALTER TABLE maintenance
                    ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS'
                    """);
            log.info("Colonne maintenance.status ajoutée");
        } catch (Exception e) {
            log.warn("Migration maintenance.status ignorée ou déjà appliquée: {}", e.getMessage());
        }
    }
}
