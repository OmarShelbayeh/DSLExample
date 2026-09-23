/*
 * Enterprise E-Commerce Ecosystem
 *
 * Models eight interconnected internal systems communicating over an
 * AWS SNS/SQS event backbone, with the E-Commerce Platform exposing a
 * deeply queue-driven internal microservice mesh.
 *
 * Render with: https://structurizr.com/dsl  or  structurizr-cli
 */

workspace "Enterprise E-Commerce Ecosystem" "Event-driven, multi-system architecture using AWS SNS/SQS for inter-system and intra-system communication." {

    !identifiers hierarchical

    model {

        // ═══════════════════════════════════════════════════════════════════
        // PERSONAS
        // ═══════════════════════════════════════════════════════════════════

        customer     = person "Customer"            "End-user browsing, purchasing, and tracking orders." "External"
        adminOps = person "Operations Admin"    "Internal staff managing catalog, pricing, and fulfilment." "Internal"
        dataAnalyst = person "Data Analyst"        "BI team consuming dashboards and running ad-hoc reports." "Internal"
        fraudAnalyst = person "Fraud Analyst"       "Reviews flagged transactions and monitors model metrics." "Internal"
        warehouseOp = person "Warehouse Operator"  "Processes picking lists and dispatches parcels." "Internal"
        // ═══════════════════════════════════════════════════════════════════
        // THIRD-PARTY / EXTERNAL SYSTEMS
        // ═══════════════════════════════════════════════════════════════════

        stripeGateway      = softwareSystem "Stripe"                "Card payment authorisation, capture, refunds, and disputes." "External,ThirdParty"
        twilioSMS = softwareSystem "Twilio"                "SMS and voice notification delivery." "External,ThirdParty"
        sendgridEmail = softwareSystem "SendGrid"              "Transactional and campaign email delivery." "External,ThirdParty"
        googleAnalytics = softwareSystem "Google Analytics"      "Web/app usage telemetry." "External,ThirdParty"
        elasticCloud = softwareSystem "Elastic Cloud"         "Managed Elasticsearch for product and log search." "External,ThirdParty"
        dhlAPI = softwareSystem "DHL Express API"       "International parcel booking and tracking." "External,ThirdParty"
        fedexAPI = softwareSystem "FedEx Ship API"        "Domestic parcel booking and tracking." "External,ThirdParty"
        taxjarAPI = softwareSystem "TaxJar"                "Real-time sales-tax calculation." "External,ThirdParty"
        firebaseFCM = softwareSystem "Firebase FCM"          "Mobile push notification delivery." "External,ThirdParty"
        // ═══════════════════════════════════════════════════════════════════
        // SHARED EVENT STREAMING BACKBONE
        // SNS topics fan events out; dedicated SQS queues isolate consumers.
        // ═══════════════════════════════════════════════════════════════════

        backbone = softwareSystem "Event Streaming Backbone" "AWS SNS/SQS topology that connects all internal systems via domain events." {
            tags "Messaging,Infrastructure"

            // ── SNS Topics (fan-out) ───────────────────────────────────────
            snsOrders      = container "SNS: order-events"      "Fan-out for all order lifecycle events."                         "AWS SNS" "SNS,Topic"
            snsPayments = container "SNS: payment-events"    "Fan-out for payment authorisation, capture, and refund events."  "AWS SNS" "SNS,Topic"
            snsFraud = container "SNS: fraud-alerts"      "Fan-out for real-time fraud decisions and risk scores."          "AWS SNS" "SNS,Topic"
            snsShipments = container "SNS: shipment-events"   "Fan-out for pick-up, in-transit, and delivered events."          "AWS SNS" "SNS,Topic"
            snsInventory = container "SNS: inventory-events"  "Fan-out for stock-level changes across all warehouses."          "AWS SNS" "SNS,Topic"
            snsCustomers = container "SNS: customer-events"   "Fan-out for registration, profile changes, and opt-outs."        "AWS SNS" "SNS,Topic"
            snsReturns = container "SNS: return-events"     "Fan-out for RMA lifecycle: initiated, inspected, approved."      "AWS SNS" "SNS,Topic"
            // ── Cross-system SQS queues (one per producer→consumer pair) ──
            sqsOrdLogistics  = container "SQS: order→logistics"         "Logistics reads new orders to trigger warehouse picks."    "AWS SQS" "SQS,Queue"
            sqsOrdFraud = container "SQS: order→fraud"             "Fraud engine receives order payloads for async scoring."   "AWS SQS" "SQS,Queue"
            sqsOrdAnalytics = container "SQS: order→analytics"         "Analytics ingests raw order events."                       "AWS SQS" "SQS,Queue"
            sqsOrdInventory = container "SQS: order→inventory"         "Inventory adjusts reservations on new orders."             "AWS SQS" "SQS,Queue"
            sqsPayEcommerce = container "SQS: payment→ecommerce"       "E-Commerce receives payment status updates."               "AWS SQS" "SQS,Queue"
            sqsPayAnalytics = container "SQS: payment→analytics"       "Analytics ingests payment events."                         "AWS SQS" "SQS,Queue"
            sqsPayNotify = container "SQS: payment→notify"          "Notification hub triggers payment receipts."               "AWS SQS" "SQS,Queue"
            sqsFrdPayment = container "SQS: fraud→payment"           "Payment receives fraud hold/release decisions."            "AWS SQS" "SQS,Queue"
            sqsFrdEcommerce = container "SQS: fraud→ecommerce"         "E-Commerce blocks/unblocks orders on fraud decisions."     "AWS SQS" "SQS,Queue"
            sqsFrdAnalytics = container "SQS: fraud→analytics"         "Analytics records fraud rates and model metrics."          "AWS SQS" "SQS,Queue"
            sqsShpEcommerce = container "SQS: shipment→ecommerce"      "E-Commerce updates order tracking status."                 "AWS SQS" "SQS,Queue"
            sqsShpNotify = container "SQS: shipment→notify"         "Notification hub triggers shipping-update messages."       "AWS SQS" "SQS,Queue"
            sqsShpAnalytics = container "SQS: shipment→analytics"      "Analytics ingests shipment events."                        "AWS SQS" "SQS,Queue"
            sqsInvEcommerce = container "SQS: inventory→ecommerce"     "E-Commerce reflects real-time stock availability."         "AWS SQS" "SQS,Queue"
            sqsInvAnalytics = container "SQS: inventory→analytics"     "Analytics ingests inventory-level snapshots."              "AWS SQS" "SQS,Queue"
            sqsCustAnalytics = container "SQS: customer→analytics"      "Analytics ingests customer lifecycle events."              "AWS SQS" "SQS,Queue"
            sqsCustCDP = container "SQS: customer→cdp"            "Customer Data Platform ingests profile change events."     "AWS SQS" "SQS,Queue"
            sqsRetInventory = container "SQS: return→inventory"        "Inventory restocks SKUs on confirmed returns."             "AWS SQS" "SQS,Queue"
            sqsRetPayment = container "SQS: return→payment"          "Payment initiates refund on approved return."              "AWS SQS" "SQS,Queue"
            sqsRetAnalytics = container "SQS: return→analytics"        "Analytics tracks return rates and reasons."                "AWS SQS" "SQS,Queue"
            // ── Dead-Letter Queues ─────────────────────────────────────────
            dlqOrders      = container "DLQ: order-events"     "Receives unprocessable order events after max retries."      "AWS SQS" "SQS,DLQ"
            dlqPayments = container "DLQ: payment-events"   "Receives unprocessable payment events after max retries."    "AWS SQS" "SQS,DLQ"
            dlqFraud = container "DLQ: fraud-alerts"     "Receives unprocessable fraud events after max retries."      "AWS SQS" "SQS,DLQ"
            dlqShipments = container "DLQ: shipment-events"  "Receives unprocessable shipment events after max retries."   "AWS SQS" "SQS,DLQ"
        }

        // ═══════════════════════════════════════════════════════════════════
        // E-COMMERCE PLATFORM  (the complex system)
        // Dozens of microservices wired together via intra-platform SQS queues.
        // ═══════════════════════════════════════════════════════════════════

        ecommerce = softwareSystem "E-Commerce Platform" "Core commerce system: storefront, catalog, cart, checkout, orders, reviews, recommendations, and returns." {
            tags "Internal,Core"

            // ── Client-facing layer ───────────────────────────────────────
            webApp      = container "Web Application"   "Next.js SSR storefront served via CloudFront."              "Next.js / React" "Frontend"
            mobileApp = container "Mobile App"        "iOS and Android native apps."                               "React Native" "Frontend"
            adminPortal = container "Admin Portal"      "Internal ops portal for catalog, pricing, and orders."      "React / Vite" "Frontend,Internal"
            apiGateway = container "API Gateway"       "Routes REST/GraphQL requests; handles auth, rate-limiting." "AWS API Gateway + Kong" "Gateway"
            // ── Core microservices ────────────────────────────────────────
            userSvc = container "User Service" "Manages registration, OAuth2/JWT auth, sessions, and profiles." "Node.js / TypeScript" {
                tags "Service"
                userDb      = component "User DB"       "Stores accounts, credentials, and addresses."    "PostgreSQL" "Database"
                sessionCache = component "Session Cache" "JWT denylist and rate-limit counters."           "Redis" "Cache"
                userPub = component "Event Publisher" "Publishes customer-events to SNS."              "AWS SDK v3" "Messaging"
            }

            cartSvc = container "Cart Service" "Manages shopping carts with real-time price validation and coupon application." "Go / gRPC" {
                tags "Service"
                cartStore   = component "Cart Store"        "Per-user cart state with TTL eviction."       "Redis Cluster" "Cache"
                couponLogic = component "Coupon Validator"  "Validates and applies promotional codes."     "Go" "Logic"
                cartPub = component "Event Publisher"   "Publishes cart-submitted events."             "AWS SDK v2" "Messaging"
            }

            productSvc = container "Product Service" "Manages catalog items, variants, attributes, and media assets." "Python / FastAPI" {
                tags "Service"
                productDb   = component "Product DB"    "Master catalog with versioned records."           "PostgreSQL" "Database"
                mediaStore = component "Media Store"   "Product images and videos."                       "S3 + CloudFront" "Storage"
                productPub = component "Event Publisher" "Publishes product-updated events."              "AWS SDK boto3" "Messaging"
                productSub = component "Event Consumer"  "Consumes inventory events to update stock flags." "AWS SDK boto3" "Messaging"
            }

            pricingSvc = container "Pricing Service" "Dynamic pricing: base price, margin rules, geo-pricing, and demand surges." "Java / Spring Boot" {
                tags "Service"
                pricingRules = component "Rule Engine"      "Evaluates cascaded pricing rules."            "Drools" "Logic"
                pricingCache = component "Pricing Cache"    "Sub-ms price lookup for hot SKUs."            "Redis" "Cache"
                pricingSub = component "Event Consumer"   "Re-prices on product or inventory events."    "Spring Cloud AWS" "Messaging"
                pricingPub = component "Event Publisher"  "Publishes recalculated prices."               "Spring Cloud AWS" "Messaging"
            }

            searchSvc = container "Search Service" "Full-text, faceted, and vector-similarity search over catalog and content." "Python / FastAPI" {
                tags "Service"
                searchIndexer = component "Indexer"         "Consumes catalog changes and updates the Elastic index."  "Python Lambda" "Messaging"
                searchEngine = component "Query Engine"    "Executes searches against Elasticsearch."                 "Python" "Logic"
                searchPers = component "Personaliser"    "Re-ranks results using CDP user affinity scores."         "Python / Scikit" "ML"
            }

            recSvc = container "Recommendation Service" "Collaborative-filtering and content-based product recommendations." "Python / FastAPI" {
                tags "Service"
                recModelStore  = component "Model Store"      "Versioned ML models tracked in MLflow."           "S3 + MLflow" "Storage,ML"
                recFeatureStore = component "Feature Store"   "Pre-computed user and item embeddings."           "Redis + DynamoDB" "Cache,Database"
                recSub = component "Event Consumer"   "Updates user vectors on browse and purchase."     "AWS SDK boto3" "Messaging"
                recPub = component "Event Publisher"  "Publishes recommendation-served events."          "AWS SDK boto3" "Messaging"
            }

            checkoutSvc = container "Checkout Service" "Orchestrates checkout saga: cart lock → tax calc → payment auth → order creation." "Java / Spring Boot" {
                tags "Service"
                sagaOrch    = component "Saga Orchestrator"  "Manages checkout state machine and compensating transactions." "Java" "Logic"
                taxCalc = component "Tax Calculator"     "Calls TaxJar for real-time tax computation."                  "Java" "Logic"
                payClient = component "Payment Client"     "Calls Stripe; publishes payment-initiated events."            "Java" "Logic"
                checkoutPub = component "Event Publisher"    "Publishes order-placed and payment-initiated events."         "Spring Cloud AWS" "Messaging"
            }

            orderSvc = container "Order Service" "Manages full order lifecycle: created → confirmed → picking → shipped → delivered." "Java / Spring Boot" {
                tags "Service"
                orderDb     = component "Order DB"           "Durable order records with event-sourced history."    "PostgreSQL + EventStore" "Database"
                orderFSM = component "State Machine"      "Enforces valid order state transitions."              "Java" "Logic"
                orderPub = component "Event Publisher"    "Publishes order-lifecycle events to SNS."             "Spring Cloud AWS" "Messaging"
                orderSub = component "Event Consumer"     "Consumes payment, fraud, and shipment events."        "Spring Cloud AWS" "Messaging"
            }

            catalogSvc = container "Catalog Service" "Manages categories, taxonomy, SEO metadata, and merchandising rules." "Node.js / TypeScript" {
                tags "Service"
                catalogDb   = component "Catalog DB"        "Hierarchical category tree and SEO fields."   "PostgreSQL" "Database"
                catalogCDN = component "Edge Cache"        "CloudFront-cached category page responses."   "CloudFront" "Cache"
                catalogPub = component "Event Publisher"   "Publishes catalog-restructured events."       "AWS SDK v3" "Messaging"
            }

            reviewSvc = container "Review Service" "Accepts, moderates (AI + human), and publishes product reviews and Q&A." "Node.js / TypeScript" {
                tags "Service"
                reviewDb      = component "Review DB"         "Review content, star ratings, and helpfulness votes."  "MongoDB" "Database"
                moderatorAI = component "AI Moderator"      "Toxicity and spam detection via Lambda."               "Python Lambda" "ML"
                reviewPub = component "Event Publisher"   "Publishes review-published events."                    "AWS SDK v3" "Messaging"
            }

            wishlistSvc = container "Wishlist Service" "Manages wishlists and triggers price-drop and back-in-stock alerts." "Node.js / TypeScript" {
                tags "Service"
                wishlistDb    = component "Wishlist DB"       "Wishlists and per-item alert preferences."    "DynamoDB" "Database"
                alertConsumer = component "Alert Consumer"    "Consumes pricing and inventory events."       "AWS SDK v3" "Messaging"
                alertPub = component "Alert Publisher"   "Enqueues alert notifications."                "AWS SDK v3" "Messaging"
            }

            returnSvc = container "Return Service" "Manages RMA requests, return shipping labels, inspection, and refund triggers." "Go" {
                tags "Service"
                returnDb  = component "Return DB"         "RMA records and inspection results."             "PostgreSQL" "Database"
                returnPub = component "Event Publisher"   "Publishes return-approved/rejected events."      "AWS SDK v2" "Messaging"
            }

            notifyAdapter = container "Notification Adapter" "Routes internal notification requests to the Notification Hub." "Node.js" {
                tags "Service"
            }

            // ── Intra-platform SQS queues ─────────────────────────────────
            // Each arrow below models a distinct queue with its own DLQ.

            sqsCart2Checkout   = container "SQS: cart→checkout"           "Cart enqueues cart-submitted events for checkout orchestration."     "AWS SQS" "SQS,Internal"
            sqsCheckout2Order = container "SQS: checkout→order"          "Checkout enqueues order-create commands."                           "AWS SQS" "SQS,Internal"
            sqsPaymentResult = container "SQS: payment-result"          "Checkout publishes payment-auth results for order service."         "AWS SQS" "SQS,Internal"
            sqsFraudDecision = container "SQS: fraud-decision"          "Fraud decisions delivered to order service."                        "AWS SQS" "SQS,Internal"
            sqsProductUpdate = container "SQS: product-update"          "Product changes fanned to pricing, search, and wishlist."           "AWS SQS" "SQS,Internal"
            sqsPricingUpdate = container "SQS: pricing-update"          "Recalculated prices delivered to cart, wishlist, and search."       "AWS SQS" "SQS,Internal"
            sqsSearchIndex = container "SQS: search-index"            "Catalog and product events routed to search indexer."               "AWS SQS" "SQS,Internal"
            sqsRecTrigger = container "SQS: rec-trigger"             "Purchase and browse events trigger recommendation updates."         "AWS SQS" "SQS,Internal"
            sqsInvDecrease = container "SQS: inventory-decrease"      "Order-confirmed events request inventory reservation/decrement."    "AWS SQS" "SQS,Internal"
            sqsReviewMod = container "SQS: review-moderation"       "Submitted reviews queued for AI and optional human moderation."     "AWS SQS" "SQS,Internal"
            sqsCatalogSync = container "SQS: catalog-sync"            "Catalog restructures propagated to product and search services."    "AWS SQS" "SQS,Internal"
            sqsNotifyRequest = container "SQS: notify-request"          "Internal notification request bus consumed by notification adapter." "AWS SQS" "SQS,Internal"
            sqsWishlistAlert = container "SQS: wishlist-alert"          "Price-drop and back-in-stock triggers delivered to wishlist."       "AWS SQS" "SQS,Internal"
            sqsReturnCreated = container "SQS: return-created"          "New RMA events fanned to logistics for return-label generation."    "AWS SQS" "SQS,Internal"
            sqsStockAlert = container "SQS: stock-alert"             "Low-stock warnings consumed by catalog and notification adapter."   "AWS SQS" "SQS,Internal"
            // Intra-platform DLQs
            dlqCart2Checkout  = container "DLQ: cart→checkout"            "Unprocessable cart-checkout events for manual triage."             "AWS SQS" "SQS,DLQ,Internal"
            dlqCheckout2Order = container "DLQ: checkout→order"           "Failed checkout→order commands for replay."                        "AWS SQS" "SQS,DLQ,Internal"
            dlqReviewMod = container "DLQ: review-moderation"        "Stuck moderation jobs routed to human moderators."                 "AWS SQS" "SQS,DLQ,Internal"
            dlqRecTrigger = container "DLQ: rec-trigger"              "Failed recommendation-update messages."                            "AWS SQS" "SQS,DLQ,Internal"
        }

        // ═══════════════════════════════════════════════════════════════════
        // FRAUD DETECTION SYSTEM
        // ═══════════════════════════════════════════════════════════════════

        fraud = softwareSystem "Fraud Detection System" "Real-time transaction risk scoring using ML model ensembles and rule engines." {
            tags "Internal"

            fraudAPI      = container "Fraud API"             "Synchronous REST endpoint for inline pre-checkout fraud checks." "Python / FastAPI" "Service"
            riskEngine = container "Risk Model Engine"     "Runs XGBoost and neural-net ensemble on transaction features."   "Python / Ray Serve" "Service,ML"
            ruleEngine = container "Rule Engine"           "Hard-coded velocity, geo, and device fingerprint rules."         "Python" "Service"
            featExtractor = container "Feature Extractor"     "Derives real-time features from incoming raw events."            "Python" "Service"
            fraudConsumer = container "Event Consumer"        "Reads order events from SQS and triggers async scoring."        "Python / Lambda" "Service"
            fraudPublisher = container "Event Publisher"      "Publishes fraud decisions to SNS fraud-alerts topic."           "Python / Lambda" "Service"
            fraudCaseDB = container "Case DB"               "Historical fraud cases and analyst review labels."              "PostgreSQL" "Database"
            fraudFeatureDB = container "Feature Store"        "Rolling per-user/device behavioural feature windows."           "Redis + DynamoDB" "Cache,Database"
            fraudModelStore = container "Model Store"         "Versioned model artefacts tracked by MLflow."                   "S3 + MLflow" "Storage,ML"
        }

        // ═══════════════════════════════════════════════════════════════════
        // LOGISTICS & SHIPPING SYSTEM
        // ═══════════════════════════════════════════════════════════════════

        logistics = softwareSystem "Logistics & Shipping System" "Orchestrates warehouse picking, packing, carrier booking, and shipment tracking." {
            tags "Internal"

            warehouseSvc    = container "Warehouse Service"   "Manages picking lists, packing stations, and dispatch queues."  "Java / Spring Boot" "Service"
            carrierBroker = container "Carrier Broker"      "Selects optimal carrier and books shipment labels."             "Go" "Service"
            trackingSvc = container "Tracking Service"    "Polls carrier APIs and normalises tracking events."             "Go" "Service"
            logisticsConsumer = container "Event Consumer"    "Reads order and return events from SQS."                       "Java" "Service"
            logisticsPublisher = container "Event Publisher"  "Publishes shipment-events to SNS."                             "Java" "Service"
            logisticsDB = container "Logistics DB"        "Shipment records, carrier bookings, and SLA data."             "PostgreSQL" "Database"
            trackingCache = container "Tracking Cache"      "Latest tracking status per order for fast reads."              "Redis" "Cache"
        }

        // ═══════════════════════════════════════════════════════════════════
        // PAYMENT PROCESSING SYSTEM
        // ═══════════════════════════════════════════════════════════════════

        payments = softwareSystem "Payment Processing System" "Manages payment authorisation, capture, settlement, refunds, and disputes." {
            tags "Internal"

            paymentAPI      = container "Payment API"         "Orchestrates payment flows with idempotency keys."             "Java / Spring Boot" "Service"
            gatewayAdapter = container "Gateway Adapter"     "Abstracts Stripe API: auth, capture, void, and refund."       "Java" "Service"
            refundSvc = container "Refund Service"      "Processes refunds triggered by approved return events."       "Java" "Service"
            settlementSvc = container "Settlement Service"  "Reconciles captured amounts against Stripe payout reports."   "Java" "Service"
            paymentConsumer = container "Event Consumer"      "Reads fraud decisions and return events from SQS."            "Java" "Service"
            paymentPublisher = container "Event Publisher"    "Publishes payment-events (authorised, captured, refunded)."   "Java" "Service"
            paymentDB = container "Payment DB"          "Transactions, authorisations, refunds, and settlements."      "PostgreSQL" "Database"
            auditLedger = container "Audit Ledger"        "Immutable append-only log of all payment commands."           "DynamoDB" "Database"
        }

        // ═══════════════════════════════════════════════════════════════════
        // NOTIFICATION HUB
        // ═══════════════════════════════════════════════════════════════════

        notifyHub = softwareSystem "Notification Hub" "Multi-channel notification dispatcher: email, SMS, push, and in-app." {
            tags "Internal"

            notifyAPI       = container "Notify API"          "Accepts notification requests and schedules dispatch."        "Node.js" "Service"
            channelRouter = container "Channel Router"      "Routes to the correct channel adapter based on preference."  "Node.js" "Service"
            emailAdapter = container "Email Adapter"       "Sends transactional emails via SendGrid."                    "Node.js" "Service"
            smsAdapter = container "SMS Adapter"         "Sends SMS via Twilio."                                       "Node.js" "Service"
            pushAdapter = container "Push Adapter"        "Sends mobile push via Firebase FCM."                         "Node.js" "Service"
            inAppAdapter = container "In-App Adapter"      "Writes in-app notifications to DynamoDB for polling."        "Node.js" "Service"
            notifyConsumer = container "Event Consumer"      "Reads payment and shipment events from SQS."                 "Node.js" "Service"
            notifyDB = container "Notification DB"     "Delivery logs, templates, and user channel preferences."     "PostgreSQL" "Database"
            notifyQueue = container "Dispatch Queue"      "Internal queue before channel adapter dispatch."             "AWS SQS" "SQS,Internal"
        }

        // ═══════════════════════════════════════════════════════════════════
        // ANALYTICS & BI PLATFORM
        // ═══════════════════════════════════════════════════════════════════

        analytics = softwareSystem "Analytics & BI Platform" "Real-time streaming analytics, data warehouse, and BI dashboards." {
            tags "Internal"

            streamProcessor   = container "Stream Processor"   "Consumes all domain events and applies windowed transformations."  "Apache Flink" "Service"
            dataWarehouse = container "Data Warehouse"      "Columnar storage for historical reporting."                        "AWS Redshift" "Database"
            realtimeDash = container "Real-time Dashboard" "Live KPI dashboards for ops and leadership."                       "Grafana" "Frontend"
            analyticsBus = container "Internal Event Bus"  "Internal Kafka topic fan-out for derived event streams."           "Apache Kafka" "Messaging"
            dbtPipelines = container "dbt Pipelines"       "Scheduled SQL transformations for BI reporting models."            "dbt" "Service"
            analyticsAPI = container "Analytics API"       "Exposes aggregated KPIs to internal dashboards."                   "Python / FastAPI" "Service"
            analyticsConsumer = container "SQS Consumer"        "Polls all domain SQS queues and feeds events into Flink."          "Java / Flink" "Service"
        }

        // ═══════════════════════════════════════════════════════════════════
        // INVENTORY MANAGEMENT SYSTEM
        // ═══════════════════════════════════════════════════════════════════

        inventory = softwareSystem "Inventory Management System" "Real-time stock tracking across warehouses, with reservations and replenishment." {
            tags "Internal"

            inventoryAPI      = container "Inventory API"       "REST API for stock queries, adjustments, and transfers."      "Go" "Service"
            reservationSvc = container "Reservation Service" "Manages soft and hard stock reservations."                    "Go" "Service"
            replenishmentSvc = container "Replenishment Svc"   "Triggers POs when stock falls below reorder points."          "Go" "Service"
            inventoryConsumer = container "Event Consumer"      "Reads order and return events to adjust stock levels."        "Go" "Service"
            inventoryPublisher = container "Event Publisher"    "Publishes inventory-events to SNS."                           "Go" "Service"
            inventoryDB = container "Inventory DB"        "SKU stock levels per warehouse bin location."                 "PostgreSQL" "Database"
            inventoryCache = container "Inventory Cache"     "Hot-path stock availability reads."                           "Redis" "Cache"
        }

        // ═══════════════════════════════════════════════════════════════════
        // CUSTOMER DATA PLATFORM
        // ═══════════════════════════════════════════════════════════════════

        cdp = softwareSystem "Customer Data Platform" "Unified customer profile, segmentation, and activation layer." {
            tags "Internal"

            cdpIngestion    = container "Ingestion Service"   "Reads customer events from SQS and upserts unified profiles."  "Python" "Service"
            cdpSegmentation = container "Segmentation Engine" "Runs batch and streaming segment membership rules."            "Python / Spark" "Service,ML"
            cdpActivation = container "Activation Service"  "Pushes segment audiences to ad platforms and email tools."    "Python" "Service"
            cdpProfileDB = container "Profile Store"       "Canonical customer profiles with identity-merge history."     "MongoDB" "Database"
            cdpSegmentStore = container "Segment Store"       "Pre-computed segment memberships for fast lookup."            "Redis + DynamoDB" "Cache,Database"
            cdpAPI = container "CDP API"             "Serves profile and segment data to internal consumers."       "Python / FastAPI" "Service"
        }


        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — Personas → Systems
        // ═══════════════════════════════════════════════════════════════════

        customer     -> ecommerce   "Browses products, manages cart, and places orders"   "HTTPS"
        customer     -> notifyHub   "Receives email, SMS, and push notifications"          "HTTPS / FCM"
        adminOps     -> ecommerce   "Manages catalog, pricing, promotions, and orders"     "HTTPS"
        dataAnalyst  -> analytics   "Queries dashboards and runs ad-hoc reports"           "HTTPS"
        fraudAnalyst -> fraud       "Reviews flagged cases and retrains models"            "HTTPS"
        warehouseOp  -> logistics   "Processes picking lists and dispatches parcels"       "HTTPS"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — SNS Fan-out wiring
        // ═══════════════════════════════════════════════════════════════════

        backbone.snsOrders    -> backbone.sqsOrdLogistics   "Delivers to Logistics"    "AWS SQS"
        backbone.snsOrders    -> backbone.sqsOrdFraud       "Delivers to Fraud"        "AWS SQS"
        backbone.snsOrders    -> backbone.sqsOrdAnalytics   "Delivers to Analytics"    "AWS SQS"
        backbone.snsOrders    -> backbone.sqsOrdInventory   "Delivers to Inventory"    "AWS SQS"
        backbone.snsPayments  -> backbone.sqsPayEcommerce   "Delivers to E-Commerce"   "AWS SQS"
        backbone.snsPayments  -> backbone.sqsPayAnalytics   "Delivers to Analytics"    "AWS SQS"
        backbone.snsPayments  -> backbone.sqsPayNotify      "Delivers to Notify Hub"   "AWS SQS"
        backbone.snsFraud     -> backbone.sqsFrdPayment     "Delivers to Payment"      "AWS SQS"
        backbone.snsFraud     -> backbone.sqsFrdEcommerce   "Delivers to E-Commerce"   "AWS SQS"
        backbone.snsFraud     -> backbone.sqsFrdAnalytics   "Delivers to Analytics"    "AWS SQS"
        backbone.snsShipments -> backbone.sqsShpEcommerce   "Delivers to E-Commerce"   "AWS SQS"
        backbone.snsShipments -> backbone.sqsShpNotify      "Delivers to Notify Hub"   "AWS SQS"
        backbone.snsShipments -> backbone.sqsShpAnalytics   "Delivers to Analytics"    "AWS SQS"
        backbone.snsInventory -> backbone.sqsInvEcommerce   "Delivers to E-Commerce"   "AWS SQS"
        backbone.snsInventory -> backbone.sqsInvAnalytics   "Delivers to Analytics"    "AWS SQS"
        backbone.snsCustomers -> backbone.sqsCustAnalytics  "Delivers to Analytics"    "AWS SQS"
        backbone.snsCustomers -> backbone.sqsCustCDP        "Delivers to CDP"          "AWS SQS"
        backbone.snsReturns   -> backbone.sqsRetInventory   "Delivers to Inventory"    "AWS SQS"
        backbone.snsReturns   -> backbone.sqsRetPayment     "Delivers to Payment"      "AWS SQS"
        backbone.snsReturns   -> backbone.sqsRetAnalytics   "Delivers to Analytics"    "AWS SQS"

        // DLQ wiring on main consumer queues
        backbone.sqsOrdLogistics  -> backbone.dlqOrders    "Poison messages → DLQ"    "AWS SQS"
        backbone.sqsOrdFraud      -> backbone.dlqOrders    "Poison messages → DLQ"    "AWS SQS"
        backbone.sqsPayEcommerce  -> backbone.dlqPayments  "Poison messages → DLQ"    "AWS SQS"
        backbone.sqsFrdPayment    -> backbone.dlqFraud     "Poison messages → DLQ"    "AWS SQS"
        backbone.sqsShpNotify     -> backbone.dlqShipments "Poison messages → DLQ"    "AWS SQS"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — E-Commerce publishes to Backbone SNS
        // ═══════════════════════════════════════════════════════════════════

        ecommerce.orderSvc   -> backbone.snsOrders    "Publishes order lifecycle events"  "AWS SNS"
        ecommerce.checkoutSvc -> backbone.snsOrders   "Publishes order-placed events"     "AWS SNS"
        ecommerce.userSvc    -> backbone.snsCustomers "Publishes customer events"          "AWS SNS"
        ecommerce.returnSvc  -> backbone.snsReturns   "Publishes return lifecycle events"  "AWS SNS"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — Backbone SQS → downstream system consumers
        // ═══════════════════════════════════════════════════════════════════

        backbone.sqsOrdLogistics  -> logistics.logisticsConsumer    "Order events for warehouse"      "AWS SQS"
        backbone.sqsOrdFraud      -> fraud.fraudConsumer            "Order events for scoring"        "AWS SQS"
        backbone.sqsOrdAnalytics  -> analytics.analyticsConsumer    "Order events for analytics"      "AWS SQS"
        backbone.sqsOrdInventory  -> inventory.inventoryConsumer    "Order events for stock deduct"   "AWS SQS"
        backbone.sqsPayEcommerce  -> ecommerce.orderSvc             "Payment results to order svc"    "AWS SQS"
        backbone.sqsPayAnalytics  -> analytics.analyticsConsumer    "Payment events for analytics"    "AWS SQS"
        backbone.sqsPayNotify     -> notifyHub.notifyConsumer       "Payment events for notify hub"   "AWS SQS"
        backbone.sqsFrdPayment    -> payments.paymentConsumer       "Fraud decisions to payment"      "AWS SQS"
        backbone.sqsFrdEcommerce  -> ecommerce.orderSvc             "Fraud decisions to order svc"    "AWS SQS"
        backbone.sqsFrdAnalytics  -> analytics.analyticsConsumer    "Fraud events for analytics"      "AWS SQS"
        backbone.sqsShpEcommerce  -> ecommerce.orderSvc             "Tracking updates to order svc"   "AWS SQS"
        backbone.sqsShpNotify     -> notifyHub.notifyConsumer       "Tracking events for notify hub"  "AWS SQS"
        backbone.sqsShpAnalytics  -> analytics.analyticsConsumer    "Shipment events for analytics"   "AWS SQS"
        backbone.sqsInvEcommerce  -> ecommerce.productSvc           "Stock updates to product svc"    "AWS SQS"
        backbone.sqsInvAnalytics  -> analytics.analyticsConsumer    "Inventory events for analytics"  "AWS SQS"
        backbone.sqsCustAnalytics -> analytics.analyticsConsumer    "Customer events for analytics"   "AWS SQS"
        backbone.sqsCustCDP       -> cdp.cdpIngestion               "Customer events for CDP"         "AWS SQS"
        backbone.sqsRetInventory  -> inventory.inventoryConsumer    "Return events for restock"       "AWS SQS"
        backbone.sqsRetPayment    -> payments.paymentConsumer       "Return events for refund"        "AWS SQS"
        backbone.sqsRetAnalytics  -> analytics.analyticsConsumer    "Return events for analytics"     "AWS SQS"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — Other systems publish to Backbone SNS
        // ═══════════════════════════════════════════════════════════════════

        payments.paymentPublisher   -> backbone.snsPayments   "Publishes payment events"    "AWS SNS"
        fraud.fraudPublisher        -> backbone.snsFraud      "Publishes fraud decisions"   "AWS SNS"
        logistics.logisticsPublisher -> backbone.snsShipments "Publishes shipment events"   "AWS SNS"
        inventory.inventoryPublisher -> backbone.snsInventory "Publishes inventory events"  "AWS SNS"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — Intra-E-Commerce SQS flows
        // ═══════════════════════════════════════════════════════════════════

        // Cart → Checkout
        ecommerce.cartSvc        -> ecommerce.sqsCart2Checkout   "Enqueues cart-submitted event"            "AWS SQS"
        ecommerce.sqsCart2Checkout -> ecommerce.checkoutSvc      "Triggers checkout orchestration"          "AWS SQS"
        ecommerce.sqsCart2Checkout -> ecommerce.dlqCart2Checkout "Poison messages → DLQ"                   "AWS SQS"

        // Checkout → Order
        ecommerce.checkoutSvc    -> ecommerce.sqsCart2Checkout   "Enqueues cart-submitted event"            "AWS SQS"
        ecommerce.checkoutSvc    -> ecommerce.sqsCheckout2Order  "Enqueues order-create command"            "AWS SQS"
        ecommerce.sqsCheckout2Order -> ecommerce.orderSvc        "Triggers order creation"                  "AWS SQS"
        ecommerce.sqsCheckout2Order -> ecommerce.dlqCheckout2Order "Poison messages → DLQ"                 "AWS SQS"

        // Payment result → Order
        ecommerce.checkoutSvc    -> ecommerce.sqsPaymentResult   "Publishes payment-auth result"            "AWS SQS"
        ecommerce.sqsPaymentResult -> ecommerce.orderSvc         "Order transitions on payment result"      "AWS SQS"

        // Fraud decision → Order (intra-platform copy)
        ecommerce.sqsFraudDecision -> ecommerce.orderSvc         "Delivers hold/release decision"           "AWS SQS"

        // Product update fan-out
        ecommerce.productSvc     -> ecommerce.sqsProductUpdate   "Publishes product-updated event"          "AWS SQS"
        ecommerce.sqsProductUpdate -> ecommerce.pricingSvc       "Triggers pricing rule re-evaluation"      "AWS SQS"
        ecommerce.sqsProductUpdate -> ecommerce.searchSvc        "Triggers search index update"             "AWS SQS"
        ecommerce.sqsProductUpdate -> ecommerce.wishlistSvc      "Checks wishlisted items for changes"      "AWS SQS"
        ecommerce.sqsProductUpdate -> ecommerce.recSvc           "Refreshes item content embeddings"        "AWS SQS"

        // Pricing update fan-out
        ecommerce.pricingSvc     -> ecommerce.sqsPricingUpdate   "Publishes recalculated prices"            "AWS SQS"
        ecommerce.sqsPricingUpdate -> ecommerce.cartSvc          "Invalidates cached cart line prices"      "AWS SQS"
        ecommerce.sqsPricingUpdate -> ecommerce.sqsWishlistAlert "Triggers price-drop alert check"          "AWS SQS"
        ecommerce.sqsPricingUpdate -> ecommerce.searchSvc        "Updates price facets in search index"     "AWS SQS"

        // Wishlist alert
        ecommerce.sqsWishlistAlert -> ecommerce.wishlistSvc      "Delivers alert trigger to wishlist svc"   "AWS SQS"
        ecommerce.wishlistSvc      -> ecommerce.sqsNotifyRequest "Enqueues wishlist alert notification"     "AWS SQS"

        // Catalog sync fan-out
        ecommerce.catalogSvc     -> ecommerce.sqsCatalogSync     "Publishes catalog-restructured event"     "AWS SQS"
        ecommerce.sqsCatalogSync -> ecommerce.productSvc         "Syncs product category assignments"       "AWS SQS"
        ecommerce.sqsCatalogSync -> ecommerce.sqsSearchIndex     "Propagates category tree to search"       "AWS SQS"

        // Search index jobs
        ecommerce.sqsSearchIndex -> ecommerce.searchSvc          "Delivers search indexing jobs"            "AWS SQS"

        // Inventory decrease on order confirm
        ecommerce.orderSvc       -> ecommerce.sqsInvDecrease     "Requests inventory reservation"           "AWS SQS"
        ecommerce.sqsInvDecrease -> ecommerce.sqsStockAlert      "Low-stock threshold crossed → alert"      "AWS SQS"
        ecommerce.sqsStockAlert  -> ecommerce.catalogSvc         "Marks SKU as low-stock on PDP"            "AWS SQS"
        ecommerce.sqsStockAlert  -> ecommerce.notifyAdapter      "Notifies ops team of low stock"           "AWS SQS"

        // Review moderation pipeline
        ecommerce.reviewSvc      -> ecommerce.sqsReviewMod       "Enqueues submitted reviews for moderation" "AWS SQS"
        ecommerce.sqsReviewMod   -> ecommerce.reviewSvc          "Returns moderation verdict"               "AWS SQS"
        ecommerce.sqsReviewMod   -> ecommerce.dlqReviewMod       "Stuck jobs → DLQ for human review"        "AWS SQS"
        ecommerce.sqsReviewMod   -> ecommerce.sqsSearchIndex     "Approved reviews update search index"     "AWS SQS"

        // Recommendation trigger
        ecommerce.orderSvc       -> ecommerce.sqsRecTrigger      "Publishes purchase event"                 "AWS SQS"
        ecommerce.sqsRecTrigger  -> ecommerce.recSvc             "Updates user-item interaction vectors"    "AWS SQS"
        ecommerce.sqsRecTrigger  -> ecommerce.dlqRecTrigger      "Failed updates → DLQ"                    "AWS SQS"

        // Return created → Logistics (for return label)
        ecommerce.returnSvc      -> ecommerce.sqsReturnCreated   "Publishes new RMA event"                  "AWS SQS"
        ecommerce.sqsReturnCreated -> logistics.logisticsConsumer "Triggers return-label generation"        "AWS SQS"
        ecommerce.sqsReturnCreated -> ecommerce.sqsNotifyRequest "Notifies customer: RMA created"           "AWS SQS"

        // Internal notification request bus
        ecommerce.sqsNotifyRequest -> ecommerce.notifyAdapter    "Delivers notification request"            "AWS SQS"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — Synchronous service-to-service (gRPC / REST)
        // ═══════════════════════════════════════════════════════════════════

        customer                -> ecommerce.webApp              "Uses storefront"                     "HTTPS"
        adminOps                -> ecommerce.adminPortal          "Uses admin portal"                    "HTTPS"
        ecommerce.webApp         -> ecommerce.apiGateway         "HTTPS requests"                           "HTTPS"
        ecommerce.mobileApp      -> ecommerce.apiGateway         "HTTPS requests"                           "HTTPS"
        ecommerce.adminPortal    -> ecommerce.apiGateway         "HTTPS requests"                           "HTTPS"
        ecommerce.apiGateway     -> ecommerce.userSvc            "Auth and profile lookups"                 "gRPC"
        ecommerce.apiGateway     -> ecommerce.cartSvc            "Cart CRUD"                                "gRPC"
        ecommerce.apiGateway     -> ecommerce.productSvc         "Catalog reads"                            "gRPC"
        ecommerce.apiGateway     -> ecommerce.checkoutSvc        "Initiate checkout"                        "gRPC"
        ecommerce.apiGateway     -> ecommerce.orderSvc           "Order history queries"                    "gRPC"
        ecommerce.apiGateway     -> ecommerce.searchSvc          "Search queries"                           "gRPC"
        ecommerce.apiGateway     -> ecommerce.recSvc             "Personalised recommendations"             "gRPC"
        ecommerce.apiGateway     -> ecommerce.reviewSvc          "Review submissions and reads"             "gRPC"
        ecommerce.apiGateway     -> ecommerce.wishlistSvc        "Wishlist management"                      "gRPC"
        ecommerce.apiGateway     -> ecommerce.returnSvc          "RMA requests"                             "gRPC"
        ecommerce.apiGateway     -> ecommerce.pricingSvc         "Display price fetches"                    "gRPC"
        ecommerce.checkoutSvc    -> ecommerce.cartSvc            "Locks and reads cart before payment"      "gRPC"
        ecommerce.checkoutSvc    -> ecommerce.pricingSvc         "Final price confirmation"                 "gRPC"
        ecommerce.searchSvc      -> ecommerce.pricingSvc         "Fetches display prices for search results" "gRPC"
        ecommerce.recSvc         -> cdp.cdpAPI                   "Reads user segment affinity scores"       "gRPC"
        fraud.fraudAPI           -> ecommerce.checkoutSvc        "Inline fraud check during checkout"       "gRPC"
        inventory.inventoryAPI   -> ecommerce.productSvc         "Pushes real-time stock availability"      "gRPC"
        analytics.analyticsAPI   -> ecommerce.adminPortal        "Serves embedded KPI widgets"              "HTTPS"
        cdp.cdpAPI               -> ecommerce.recSvc             "Serves personalisation segments"          "gRPC"

        // ═══════════════════════════════════════════════════════════════════
        // RELATIONSHIPS — External integrations
        // ═══════════════════════════════════════════════════════════════════

        ecommerce.checkoutSvc    -> stripeGateway     "Authorises and captures card payments"           "HTTPS / REST"
        ecommerce.checkoutSvc    -> taxjarAPI          "Calculates real-time sales tax"                  "HTTPS / REST"
        payments.refundSvc      -> stripeGateway     "Issues refunds"                          "HTTPS / REST"
        payments.gatewayAdapter  -> stripeGateway     "Processes refunds, disputes, and payouts"        "HTTPS / REST"
        logistics.carrierBroker  -> dhlAPI             "Books international shipment labels"             "HTTPS / REST"
        logistics.carrierBroker  -> fedexAPI           "Books domestic shipment labels"                  "HTTPS / REST"
        logistics.trackingSvc    -> dhlAPI             "Polls DHL tracking status"                       "HTTPS / REST"
        logistics.trackingSvc    -> fedexAPI           "Polls FedEx tracking status"                     "HTTPS / REST"
        ecommerce.notifyAdapter  -> notifyHub.notifyAPI          "Posts notification requests"          "HTTPS / REST"
        notifyHub.notifyAPI      -> notifyHub.channelRouter      "Routes by channel preference"        "In-process"
        notifyHub.channelRouter  -> notifyHub.emailAdapter       "Routes to email channel"            "In-process"
        notifyHub.channelRouter  -> notifyHub.smsAdapter         "Routes to SMS channel"              "In-process"
        notifyHub.channelRouter  -> notifyHub.pushAdapter        "Routes to push channel"             "In-process"
        notifyHub.emailAdapter   -> sendgridEmail      "Sends transactional emails"                      "HTTPS / REST"
        notifyHub.smsAdapter     -> twilioSMS          "Sends SMS messages"                              "HTTPS / REST"
        notifyHub.pushAdapter    -> firebaseFCM        "Sends mobile push notifications"                 "HTTPS / REST"
        ecommerce.webApp         -> googleAnalytics    "Sends page-view and conversion telemetry"        "JS SDK"
        ecommerce.searchSvc      -> elasticCloud       "Executes full-text and vector queries"           "HTTPS / REST"
        ecommerce.searchSvc      -> elasticCloud       "Pushes document index updates"                   "HTTPS / REST"
        cdp.cdpActivation        -> sendgridEmail      "Pushes segment audiences for email campaigns"    "HTTPS / REST"
    }

    // ═════════════════════════════════════════════════════════════════════
    // VIEWS
    // ═════════════════════════════════════════════════════════════════════

    views {

        // 1. Full system landscape
        systemLandscape "landscape" "Enterprise E-Commerce Ecosystem — System Landscape" {
            include *
            autoLayout lr
        }

        // 2. E-Commerce Platform — context
        systemContext ecommerce "ecommerceCtx" "E-Commerce Platform: External Actors and System Neighbours" {
            include *
            autoLayout tb
        }

        // 3. E-Commerce Platform — containers (services + internal queues)
        container ecommerce "ecommerceContainers" "E-Commerce Platform: Microservices and Intra-Platform SQS Queues" {
            include *
            autoLayout lr
        }

        // 4. Event Streaming Backbone — containers (SNS + SQS + DLQs)
        container backbone "backboneContainers" "Event Streaming Backbone: SNS Topics, Cross-System SQS Queues, and DLQs" {
            include *
            autoLayout lr
        }

        // 5. Fraud Detection — containers
        container fraud "fraudContainers" "Fraud Detection: Services, ML Models, and Feature Stores" {
            include *
            autoLayout tb
        }

        // 6. Logistics — containers
        container logistics "logisticsContainers" "Logistics & Shipping: Warehouse, Carrier Broker, and Tracking" {
            include *
            autoLayout tb
        }

        // 7. Payment Processing — containers
        container payments "paymentContainers" "Payment Processing: Authorisation, Capture, Refund, and Settlement" {
            include *
            autoLayout tb
        }

        // 8. Analytics Platform — containers
        container analytics "analyticsContainers" "Analytics & BI: Stream Processor, Warehouse, and Dashboards" {
            include *
            autoLayout tb
        }

        // 9. Inventory — containers
        container inventory "inventoryContainers" "Inventory Management: Stock, Reservations, and Replenishment" {
            include *
            autoLayout tb
        }

        // 10. Customer Data Platform — containers
        container cdp "cdpContainers" "Customer Data Platform: Profiles, Segments, and Activation" {
            include *
            autoLayout tb
        }

        // 11. Notification Hub — containers
        container notifyHub "notifyContainers" "Notification Hub: Multi-channel Dispatch" {
            include *
            autoLayout tb
        }

        // 12. Order Service — components
        component ecommerce.orderSvc "orderComponents" "Order Service: Internal Components" {
            include *
            autoLayout tb
        }

        // 13. Checkout Service — components
        component ecommerce.checkoutSvc "checkoutComponents" "Checkout Service: Saga Orchestration Components" {
            include *
            autoLayout tb
        }

        // 14. User Service — components
        component ecommerce.userSvc "userComponents" "User Service: Auth, Profile, and Events" {
            include *
            autoLayout tb
        }

        // ── Dynamic views ──────────────────────────────────────────────────

        // 15. Checkout happy-path
        dynamic ecommerce "checkoutHappyPath" "Checkout: Happy-Path Saga" {
            customer                -> ecommerce.webApp              "Clicks Place Order"
        adminOps                -> ecommerce.adminPortal          "Uses admin portal"                    "HTTPS"
        customer                -> ecommerce.webApp              "Uses storefront"                     "HTTPS"
        adminOps                -> ecommerce.adminPortal          "Uses admin portal"                    "HTTPS"
            ecommerce.webApp        -> ecommerce.apiGateway          "POST /checkout"
            ecommerce.apiGateway    -> ecommerce.checkoutSvc         "Initiate checkout"
            ecommerce.checkoutSvc   -> ecommerce.cartSvc             "Lock cart"
            ecommerce.checkoutSvc   -> ecommerce.pricingSvc          "Confirm final prices"
            ecommerce.checkoutSvc   -> taxjarAPI                     "Calculate tax"
            ecommerce.checkoutSvc   -> stripeGateway                 "Authorise payment (sync)"
            ecommerce.checkoutSvc   -> ecommerce.sqsCart2Checkout    "Enqueue cart-submitted (idempotency)"
            ecommerce.checkoutSvc   -> ecommerce.sqsCheckout2Order   "Enqueue order-create"
            ecommerce.sqsCheckout2Order -> ecommerce.orderSvc        "Create order"
            ecommerce.orderSvc      -> ecommerce.sqsInvDecrease      "Reserve inventory"
            ecommerce.orderSvc      -> backbone.snsOrders            "Publish order-placed"
            backbone.snsOrders      -> backbone.sqsOrdFraud          "Route to Fraud"
            backbone.sqsOrdFraud    -> fraud.fraudConsumer           "Score transaction (async)"
            fraud.fraudPublisher    -> backbone.snsFraud             "Publish fraud-approved"
            backbone.snsFraud       -> backbone.sqsFrdEcommerce      "Route to E-Commerce"
            backbone.sqsFrdEcommerce -> ecommerce.orderSvc           "Confirm order state: CONFIRMED"
            backbone.snsOrders      -> backbone.sqsOrdLogistics      "Route to Logistics"
            backbone.sqsOrdLogistics -> logistics.logisticsConsumer  "Trigger warehouse pick"
            autoLayout lr
        }

        // 16. Return and refund flow
        dynamic ecommerce "returnRefundFlow" "Return: RMA → Restock → Refund Sequence" {
            customer                -> ecommerce.webApp              "Submits return request"
        adminOps                -> ecommerce.adminPortal          "Uses admin portal"                    "HTTPS"
        customer                -> ecommerce.webApp              "Uses storefront"                     "HTTPS"
        adminOps                -> ecommerce.adminPortal          "Uses admin portal"                    "HTTPS"
            ecommerce.webApp        -> ecommerce.apiGateway          "POST /returns"
            ecommerce.apiGateway    -> ecommerce.returnSvc           "Create RMA record"
            ecommerce.returnSvc     -> ecommerce.sqsReturnCreated    "Publish return-created"
            ecommerce.sqsReturnCreated -> logistics.logisticsConsumer "Generate return shipping label"
            ecommerce.sqsReturnCreated -> ecommerce.sqsNotifyRequest "Notify customer: RMA created"
            ecommerce.sqsNotifyRequest -> ecommerce.notifyAdapter    "Route notification"
            ecommerce.notifyAdapter -> notifyHub.notifyAPI           "POST /notifications"
            notifyHub.channelRouter -> notifyHub.emailAdapter        "Route to email channel"
            notifyHub.emailAdapter  -> sendgridEmail                 "Deliver RMA confirmation email"
            ecommerce.returnSvc     -> backbone.snsReturns           "Publish return-approved"
            backbone.snsReturns     -> backbone.sqsRetInventory      "Route to Inventory"
            backbone.sqsRetInventory -> inventory.inventoryConsumer  "Restock SKU in warehouse"
            backbone.snsReturns     -> backbone.sqsRetPayment        "Route to Payment"
            backbone.sqsRetPayment  -> payments.paymentConsumer      "Trigger refund processing"
            payments.refundSvc      -> stripeGateway                 "Issue Stripe refund"
            payments.paymentPublisher -> backbone.snsPayments        "Publish refund-completed"
            backbone.snsPayments    -> backbone.sqsPayNotify         "Route to Notify Hub"
            backbone.sqsPayNotify   -> notifyHub.notifyConsumer      "Deliver payment event"
            notifyHub.channelRouter -> notifyHub.emailAdapter        "Route refund email"
            notifyHub.emailAdapter  -> sendgridEmail                 "Deliver refund confirmation email"
            autoLayout lr
        }

        // 17. Price-drop wishlist alert flow
        dynamic ecommerce "priceDropAlert" "Price-Drop Wishlist Alert Flow" {
            adminOps                 -> ecommerce.adminPortal        "Updates product price"
            ecommerce.adminPortal    -> ecommerce.apiGateway         "PATCH /products/{id}/price"
            ecommerce.apiGateway     -> ecommerce.productSvc         "Update product price"
            ecommerce.productSvc     -> ecommerce.sqsProductUpdate   "Publish product-updated"
            ecommerce.sqsProductUpdate -> ecommerce.pricingSvc       "Re-evaluate pricing rules"
            ecommerce.pricingSvc     -> ecommerce.sqsPricingUpdate   "Publish recalculated price"
            ecommerce.sqsPricingUpdate -> ecommerce.sqsWishlistAlert "Trigger price-drop check"
            ecommerce.sqsWishlistAlert -> ecommerce.wishlistSvc      "Identify wishlisted users"
            ecommerce.wishlistSvc    -> ecommerce.sqsNotifyRequest   "Enqueue price-drop alerts (per user)"
            ecommerce.sqsNotifyRequest -> ecommerce.notifyAdapter    "Batch notification requests"
            ecommerce.notifyAdapter  -> notifyHub.notifyAPI          "POST /notifications (batch)"
            notifyHub.channelRouter  -> notifyHub.pushAdapter        "Route to push channel"
            notifyHub.pushAdapter    -> firebaseFCM                  "Deliver push notification"
            autoLayout lr
        }

        // ── Styles ────────────────────────────────────────────────────────

        styles {
            element "Person" {
                shape Person
                background #1168bd
                color #ffffff
                fontSize 14
            }
            element "Software System" {
                background #1168bd
                color #ffffff
                fontSize 13
            }
            element "External" {
                background #808080
                color #ffffff
            }
            element "ThirdParty" {
                background #555555
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
                fontSize 12
            }
            element "Component" {
                background #85bbf0
                color #000000
                fontSize 11
            }
            element "SNS" {
                background #c0392b
                color #ffffff
                shape Pipe
            }
            element "Topic" {
                background #c0392b
                color #ffffff
                shape Pipe
            }
            element "SQS" {
                background #e67e22
                color #ffffff
                shape Pipe
            }
            element "Queue" {
                background #e67e22
                color #ffffff
                shape Pipe
            }
            element "Internal" {
                background #27ae60
                color #ffffff
                shape Pipe
            }
            element "DLQ" {
                background #922b21
                color #ffffff
                shape Pipe
            }
            element "Database" {
                shape Cylinder
                background #1a5276
                color #ffffff
            }
            element "Cache" {
                shape Cylinder
                background #117a65
                color #ffffff
            }
            element "Storage" {
                shape Cylinder
                background #6c3483
                color #ffffff
            }
            element "ML" {
                background #7d3c98
                color #ffffff
            }
            element "Frontend" {
                background #154360
                color #ffffff
            }
            element "Gateway" {
                background #0e6655
                color #ffffff
            }
            element "Messaging" {
                background #c0392b
                color #ffffff
                shape Pipe
            }
            element "Infrastructure" {
                background #4a4a4a
                color #ffffff
            }
            element "Core" {
                border Dashed
            }

            relationship "AWS SNS" {
                color #c0392b
                thickness 2
                style Dashed
            }
            relationship "AWS SQS" {
                color #e67e22
                thickness 2
            }
            relationship "gRPC" {
                color #2471a3
                thickness 1
            }
            relationship "HTTPS" {
                color #1a5276
                thickness 1
            }
            relationship "HTTPS / REST" {
                color #4a4a4a
                thickness 1
                style Dashed
            }
        }

        theme default
    }
}
