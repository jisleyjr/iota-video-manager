model {
    creator = person "Creator" "Imports media, reviews proposed shorts, downloads approved videos, and monitors YouTube uploads"

    mediaSources = softwareSystem "Adventure Media Sources" "Cameras, phones, SD cards, and mounted drives containing original videos and photos." "external"
    youtube = softwareSystem "YouTube" "Receives manual uploads and exposes public video metadata and statistics through the YouTube Data API v3." "external"
    instagram = softwareSystem "Instagram" "Receives manually uploaded Reels in the first release." "external"

    iotaVideos = softwareSystem "Iota Video Manager" "Self-hosted system that catalogs adventure media and creates creator-approved short-form video drafts and monitors public YouTube uploads." "iota" {
        creatorPortal = container "Creator Portal" "Browser application for uploads, search, idea review, draft approval, final-video download, source-lineage inspection, and YouTube video monitoring." "Web application" "iota"

        applicationApi = container "Application API" "Serves the Creator Portal and manages media, catalog, idea, draft, and YouTube monitoring workflows." "Kotlin / REST API" "iota" {
            mediaManagement = component "Media Management" "Registers media and authorizes uploads and downloads." "" "iota"
            catalogSearch = component "Catalog Search" "Searches action scenes, photos, tags, and related adventures." "" "iota"
            ideaWorkflow = component "Idea and Draft Workflow" "Creates, retrieves, approves, rejects, and revises short-form video drafts." "" "iota"
            outputHistory = component "Output History" "Lists rendered videos and traces each output through its approved draft to source assets and scene time ranges." "" "iota"
            jobDispatcher = component "Job Dispatcher" "Submits analysis, idea-generation, and rendering work to background workers." "" "iota"

            youtubeVideoQueries = component "YouTube Video Queries" "Serves stored video metadata, current statistics, availability, and refresh times to the portal." "" "iota"
            youtubeSync = component "YouTube Synchronization" "Runs every six hours by default; discovers uploads, refreshes stored videos, and expires stale YouTube records." "Scheduled task" "iota"
            youtubeClient = component "YouTube API Client" "Calls the YouTube Data API v3 using a server-side API key with bounded retries and quota handling." "HTTPS/JSON" "iota"

            youtubeSync -> youtubeClient "Discovers public uploads and fetches metadata and statistics"
            mediaManagement -> jobDispatcher "Requests media analysis"
            ideaWorkflow -> jobDispatcher "Requests idea generation and rendering"
        }

        ingestionService = container "Media Ingestion Service" "Watches mounted folders and accepts uploaded media; records new assets for processing." "Background service" "iota"

        mediaIntelligence = container "Media Intelligence Service" "Uses GPU-assisted analysis to identify action scenes, enrich photos, link related assets, and propose short-form drafts." "GPU worker service" "gpu" {
            jobConsumer = component "Job Consumer" "Receives media-analysis and creative-generation jobs." "" "gpu"
            videoSceneAnalyzer = component "Video Scene Analyzer" "Extracts scenes and identifies action, motion, subjects, terrain, and quality." "" "gpu"
            photoAnalyzer = component "Photo Analyzer" "Generates photo descriptions, tags, and visual embeddings." "" "gpu"
            mediaLinker = component "Media Linker" "Connects photos with related clips and adventures." "" "gpu"
            shortPlanner = component "Short Planner" "Selects media and prepares hooks, captions, pacing, and publishing suggestions." "" "gpu"
            catalogWriter = component "Catalog Writer" "Persists analysis results, media associations, and draft metadata." "" "iota"

            jobConsumer -> videoSceneAnalyzer "Dispatches video-analysis jobs"
            jobConsumer -> photoAnalyzer "Dispatches photo-analysis jobs"
            jobConsumer -> mediaLinker "Dispatches media-linking jobs"
            jobConsumer -> shortPlanner "Dispatches creative-generation jobs"
            videoSceneAnalyzer -> catalogWriter "Provides scene insights"
            photoAnalyzer -> catalogWriter "Provides photo insights"
            mediaLinker -> catalogWriter "Provides asset associations"
            shortPlanner -> catalogWriter "Provides draft metadata"
        }

        videoRenderService = container "Video Render Service" "Creates approved 9:16 MP4 videos, captions, thumbnails, and final publishing metadata." "GPU worker service" "gpu"

        jobQueue = container "Job Queue" "Buffers background analysis, creative-generation, and video-rendering work." "Message queue" "Queue"
        mediaCatalog = container "Media Catalog" "Stores asset metadata, scene timestamps, tags, projects, versioned drafts, approval state, outputs, output-to-source lineage, and YouTube video metadata and current statistics." "PostgreSQL" "Database"
        semanticIndex = container "Semantic Search Index" "Stores embeddings for matching and semantically searching videos, scenes, and photos." "Vector search database" "Database"
        mediaStorage = container "Media Object Storage" "Stores original media, analysis derivatives, previews, rendered videos, and thumbnails." "S3-compatible object storage" "Database"

        creator -> creatorPortal "Uses" "HTTPS"
        mediaSources -> ingestionService "Supplies original videos and photos" "Mounted folders or HTTPS"
        creatorPortal -> applicationApi "Uses" "HTTPS/JSON"
        applicationApi -> mediaCatalog "Reads and writes catalog, draft, and YouTube video data" "SQL"
        applicationApi -> youtube "Reads public uploads, metadata, and current statistics" "HTTPS/JSON"
        applicationApi -> semanticIndex "Searches related media" "Query API"
        applicationApi -> mediaStorage "Authorizes uploads and downloads" "Object API"
        applicationApi -> jobQueue "Enqueues background work" "Message protocol"
        ingestionService -> mediaStorage "Stores original media" "Object API"
        ingestionService -> mediaCatalog "Registers assets" "SQL"
        ingestionService -> jobQueue "Enqueues media analysis" "Message protocol"
        mediaIntelligence -> jobQueue "Consumes analysis and creative jobs" "Message protocol"
        mediaIntelligence -> mediaStorage "Reads originals and stores derivatives" "Object API"
        mediaIntelligence -> mediaCatalog "Reads and writes analysis and drafts" "SQL"
        mediaIntelligence -> semanticIndex "Writes and searches embeddings" "Query API"
        videoRenderService -> jobQueue "Consumes render jobs" "Message protocol"
        videoRenderService -> mediaStorage "Reads source media and stores finished videos" "Object API"
        videoRenderService -> mediaCatalog "Reads draft instructions and records outputs" "SQL"

        mediaManagement -> mediaCatalog "Registers and retrieves media"
        mediaManagement -> mediaStorage "Authorizes asset transfer"
        catalogSearch -> mediaCatalog "Reads media metadata"
        catalogSearch -> semanticIndex "Finds related media"
        ideaWorkflow -> mediaCatalog "Reads and writes draft state"
        outputHistory -> mediaCatalog "Reads output history and source lineage"
        outputHistory -> mediaStorage "Authorizes finished-video and thumbnail downloads"
        youtubeVideoQueries -> mediaCatalog "Reads stored YouTube videos and optional output associations"
        youtubeSync -> mediaCatalog "Upserts YouTube videos and removes expired records"
        youtubeClient -> youtube "Calls channels.list, playlistItems.list, and videos.list" "HTTPS/JSON"
        jobDispatcher -> jobQueue "Enqueues background work"
        videoSceneAnalyzer -> mediaStorage "Reads video assets"
        photoAnalyzer -> mediaStorage "Reads photo assets"
        catalogWriter -> mediaCatalog "Writes analysis and draft data"
        catalogWriter -> semanticIndex "Writes embeddings"
    }


    creator -> iotaVideos "Uses to create and review videos and monitor YouTube uploads"
    mediaSources -> iotaVideos "Provides adventure media"
    creator -> youtube "Manually uploads approved videos"
    creator -> instagram "Manually uploads approved videos"
    iotaVideos -> youtube "Monitors public uploads and current statistics" "HTTPS/JSON"
}
