/*
 * Example: Multi-System Data Pipeline (Systems 1-5)
 *
 * Flow:
 * 1) Users enter details in System 1 app.
 * 2) System 1 stores data in its database.
 * 3) System 1 publishes events to queues consumed by System 2.
 * 4) System 3 pulls source data from System 1 API.
 * 5) System 2 processes/enriches data and sends output to System 4.
 * 6) System 4 compares System 2 output with System 3 pulled data.
 * 7) System 4 sends curated results to System 5 for webpage display.
 */

workspace "System 1-5 Data Pipeline" "A queue and API driven pipeline with enrichment, comparison, and web reporting." {

    !identifiers hierarchical

    model {

        user = person "Business User" "Enters records and reviews final results on a web page." "External"

        system1 = softwareSystem "System 1 - Data Capture" "Captures user-entered records and exposes source data via API." {
            app = container "Data Entry App" "Web app used by users to submit details." "React"
            api = container "System 1 API" "Validates input, stores records, and serves data to other systems." "Node.js"
            db = container "System 1 Database" "Primary source-of-truth for submitted records." "PostgreSQL"
            outboundQueue = container "Outbound Queue" "Publishes newly created and updated records." "AWS SQS"
        }

        system2 = softwareSystem "System 2 - Enrichment Engine" "Consumes queue events, applies business logic, and emits enriched data." {
            consumer = container "Queue Consumer" "Consumes record events from System 1 queue." "Python"
            engine = container "Processing Engine" "Applies transformations, scoring, and enrichment rules." "Python"
            outputQueue = container "Processed Queue" "Queues enriched results for System 4." "AWS SQS"
        }

        system3 = softwareSystem "System 3 - Source Pull Service" "Pulls source records from System 1 API for independent comparison input." {
            puller = container "API Pull Worker" "Periodically fetches source records from System 1 API." "Go"
            snapshotStore = container "Snapshot Store" "Stores fetched source snapshots." "PostgreSQL"
            publishApi = container "Comparison Feed API" "Exposes pulled snapshots to System 4." "Go"
        }

        system4 = softwareSystem "System 4 - Comparison Hub" "Compares enriched output with source snapshots and creates final decisions." {
            ingest = container "Result Ingestor" "Consumes enriched output from System 2." "Java"
            comparator = container "Comparison Service" "Compares System 2 results against System 3 source snapshots." "Java"
            resultsDb = container "Comparison Results DB" "Stores comparison outcomes and status." "PostgreSQL"
            resultsApi = container "Results API" "Serves final comparison data to System 5." "Java"
        }

        system5 = softwareSystem "System 5 - Web Reporting" "Displays comparison outcomes in a web page." {
            web = container "Reporting Web App" "Presents final outcomes and drill-down details." "Next.js"
            backend = container "Reporting Backend" "Fetches final results from System 4 and shapes UI responses." "Node.js"
        }

        user -> system1.app "Enters details"
        user -> system5.web "Views processed comparison results"

        system1.app -> system1.api "Submit details"
        system1.api -> system1.db "Create/update records"
        system1.api -> system1.outboundQueue "Publish record-created/updated event"

        system1.outboundQueue -> system2.consumer "Deliver record event"
        system2.consumer -> system2.engine "Pass payload for processing"
        system2.engine -> system2.outputQueue "Publish enriched result"

        system3.puller -> system1.api "Pull source records via API"
        system3.puller -> system3.snapshotStore "Persist pulled snapshots"
        system3.publishApi -> system3.snapshotStore "Read snapshot data"

        system2.outputQueue -> system4.ingest "Deliver enriched output"
        system4.ingest -> system4.comparator "Forward enriched payload"
        system4.comparator -> system3.publishApi "Fetch source snapshots for comparison"
        system4.comparator -> system4.resultsDb "Store comparison outcomes"
        system4.resultsApi -> system4.resultsDb "Read final outcomes"

        system5.web -> system5.backend "Load report page data"
        system5.backend -> system4.resultsApi "Fetch final comparison results"
    }

    views {

        systemLandscape "landscape" "System 1 to 5 high-level architecture" {
            include *
            autoLayout lr
        }

        container system1 "system1-containers" "System 1 containers" {
            include *
            autoLayout lr
        }

        dynamic system4 "endToEndFlow" "End-to-end processing and comparison flow" {
            user -> system1.app "1. Enter details"
            system1.app -> system1.api "2. Submit"
            system1.api -> system1.db "3. Save in DB"
            system1.api -> system1.outboundQueue "4. Publish event"
            system1.outboundQueue -> system2.consumer "5. Queue delivery"
            system2.consumer -> system2.engine "6. Process"
            system2.engine -> system2.outputQueue "7. Publish enriched output"
            system3.puller -> system1.api "8. Pull source data via API"
            system3.puller -> system3.snapshotStore "9. Store snapshot"
            system2.outputQueue -> system4.ingest "10. Send to System 4"
            system4.ingest -> system4.comparator "11. Compare prep"
            system4.comparator -> system3.publishApi "12. Pull source snapshot"
            system4.comparator -> system4.resultsDb "13. Store comparison result"
            system5.web -> system5.backend "14. Request report"
            system5.backend -> system4.resultsApi "15. Fetch results"
            autoLayout lr
        }

        styles {
            element "Person" {
                background "#0B7285"
                color "#ffffff"
                shape Person
            }
            element "Software System" {
                background "#1D4E89"
                color "#ffffff"
            }
            element "Container" {
                background "#2B8A3E"
                color "#ffffff"
            }
        }
    }
}
