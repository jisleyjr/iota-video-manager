# IOTA Video Manager

Iota Video Manager is a self-hosted system for turning footage into short/long videos. It is designed for a library of snowmobiling, off-roading, and snowboarding videos and photos. It will also monitor videos that are uploaded to YouTube to change the stats.

## What it will do

### Processing Videos

1. Import media from watched server folders and browser uploads.
2. Analyze videos to identify high-quality action scenes, including their timestamps, subjects, activity, setting, and visual quality.
3. Analyze photos and associate them with related video clips and adventures.
4. Build a searchable media catalog of clips, photos, metadata, and AI-derived tags.
5. Recommend complete YouTube Short and Instagram Reel drafts, including a hook, selected media, pacing, captions, title, hashtags, and soundtrack suggestion.
6. Let the creator approve, reject, or request edits to each proposed draft.
7. Render approved videos in a vertical 9:16 format and make the final MP4 and thumbnail available for download.
8. Trace every rendered output to the exact draft version, source assets, and scene time ranges used to create it.

### Monitor Videos

1. Uploaded videos need to monitored for stats on views.
2. User and see a list of the videos and how they are doing.

## Initial operating model

The system will run on an Ubuntu server with two 12 GB GPUs. GPU work will include media analysis, creative-draft generation, and final video rendering. The first release will use manual uploading: after reviewing a finished video, the creator downloads it and uploads it to YouTube Shorts or Instagram Reels.

Future releases may integrate directly with YouTube and Instagram for publishing and scheduling.