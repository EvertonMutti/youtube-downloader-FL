# YouTube Downloader MVP - Product Specification

**Project:** YouTube Downloader Cross-Platform
**Platforms:** Android, Windows
**Framework:** Flutter
**Date:** 2026-03-02
**Complexity Score:** 16/18 (Complex)

---

## 1. Context & Background

### 1.1 Problem Statement
Users need a simple, cross-platform application to download YouTube videos and audio for offline viewing/listening in personal/educational contexts.

### 1.2 Legal & Compliance
- **IMPORTANT**: This application is for personal/educational use only
- Downloads may violate YouTube Terms of Service
- User assumes full responsibility for usage
- No commercial distribution or monetization intended

### 1.3 Technical Context
- **Existing State**: Fresh Flutter project (SDK 3.11.1+)
- **Target Platforms**: Android + Windows
- **Download Strategy**: youtube_explode_dart (native Dart package)
- **Storage Strategy**: SharedPreferences for app settings
- **Architecture**: Clean Architecture with BLoC pattern (per flutter-dev-patterns skill)

---

## 2. User Stories

### US-01: Download Single Video
**As a** user
**I want to** download a single YouTube video by pasting its URL
**So that** I can watch it offline

**Acceptance Criteria:**
- User can paste a valid YouTube URL (e.g., https://youtube.com/watch?v=...)
- App validates the URL and displays video metadata (title, duration, thumbnail)
- User selects download type: Video or Audio-only
- User selects quality (Low/Medium/High)
- Download starts with progress indicator
- File is saved to default folder with sanitized filename
- User receives success/error notification

---

### US-02: Select Download Quality
**As a** user
**I want to** choose the quality of my downloads
**So that** I can balance file size and quality based on my needs

**Acceptance Criteria:**
- Quality options presented based on available streams:
  - **Audio-only**: 128kbps, 192kbps, 256kbps (if available)
  - **Video**: 360p, 720p, 1080p (if available)
- App shows estimated file size for each quality
- Selected quality is persisted as default for future downloads
- If preferred quality unavailable, app suggests closest alternative

---

### US-03: Configure Default Download Folder
**As a** user
**I want to** select and save a default download folder
**So that** I don't have to choose it every time

**Acceptance Criteria:**
- Settings screen accessible from main menu
- "Select Folder" button opens native folder picker
- Selected path is displayed and validated (write permissions)
- Path is persisted using SharedPreferences
- On first launch, app suggests platform-specific default:
  - **Android**: `/storage/emulated/0/Download/YouTubeDownloader`
  - **Windows**: `%USERPROFILE%/Downloads/YouTubeDownloader`
- App creates folder if it doesn't exist
- User can change folder at any time

---

### US-04: Download Playlist
**As a** user
**I want to** download all videos from a YouTube playlist
**So that** I can get multiple videos at once

**Acceptance Criteria:**
- User pastes playlist URL (e.g., https://youtube.com/playlist?list=...)
- App fetches and displays playlist metadata (title, video count)
- User selects download options (type, quality) applied to all videos
- Downloads start sequentially (one at a time to avoid rate limiting)
- Progress shows: current video, overall progress (X/Y videos)
- Failed downloads are logged but don't stop the queue
- Summary screen shows: successful downloads, failed downloads, errors

---

## 3. MVP Scope

### 3.1 In-Scope Features
✅ Single video download (URL input)
✅ Audio-only download option
✅ Quality selection (3 tiers: Low/Medium/High)
✅ Default folder selection & persistence
✅ Playlist download (sequential processing)
✅ Download progress tracking
✅ Basic error handling & user notifications
✅ Cross-platform UI (Android + Windows)

### 3.2 Out-of-Scope (Future Enhancements)
❌ Video search within app
❌ Download history/library management
❌ Concurrent playlist downloads
❌ Video format conversion
❌ Subtitles download
❌ YouTube channel bulk download
❌ Dark mode / theming
❌ Download scheduling
❌ Proxy/VPN configuration

---

## 4. Technical Architecture

### 4.1 Required Dependencies
```yaml
dependencies:
  # Core Flutter
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # YouTube Download
  youtube_explode_dart: ^2.2.1

  # File System
  path_provider: ^2.1.1
  file_picker: ^6.1.1
  permission_handler: ^11.1.0

  # Storage
  shared_preferences: ^2.2.2

  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # HTTP & Networking
  http: ^1.1.2

  # UI Utilities
  url_launcher: ^6.2.2
```

### 4.2 Project Structure (Clean Architecture)
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── theme/
├── features/
│   ├── download/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### 4.3 Key Technical Decisions
- **State Management**: BLoC pattern (aligns with flutter-dev-patterns)
- **Dependency Injection**: GetIt + Injectable
- **Error Handling**: Either<Failure, Success> pattern with Dartz
- **Navigation**: GoRouter (declarative routing)
- **YouTube API**: youtube_explode_dart (no API key needed)

---

## 5. BDD Acceptance Scenarios

### Feature: Download Single Video

#### Scenario: Successfully download video with default settings
```gherkin
Given the app is launched for the first time
And default download folder is created at platform default location
When user pastes URL "https://youtube.com/watch?v=dQw4w9WgXcQ"
And taps "Get Video Info"
Then video metadata is displayed with title, duration, thumbnail
When user selects "Video" download type
And selects "720p" quality
And taps "Download"
Then download progress bar appears
And video file is saved to default folder as "Video_Title_720p.mp4"
And success notification shows "Download completed"
```

#### Scenario: Handle invalid URL
```gherkin
Given user is on download screen
When user pastes invalid URL "not-a-url"
And taps "Get Video Info"
Then error message displays "Invalid YouTube URL"
And download button remains disabled
```

#### Scenario: Handle unavailable video
```gherkin
Given user pastes URL of deleted/private video
When user taps "Get Video Info"
Then error message displays "Video unavailable or private"
And user can try another URL
```

---

### Feature: Download Quality Selection

#### Scenario: Display available qualities
```gherkin
Given user has entered valid video URL
When video metadata is loaded
Then quality options show only available streams:
  | Type  | Quality | Est. Size |
  | Video | 360p    | 25 MB     |
  | Video | 720p    | 85 MB     |
  | Audio | 128kbps | 4 MB      |
```

#### Scenario: Persist quality preference
```gherkin
Given user selects "720p" quality
When download completes
And user starts new download
Then "720p" is pre-selected by default
```

---

### Feature: Configure Download Folder

#### Scenario: First launch default folder setup
```gherkin
Given app is launched for first time on Android
When user navigates to Settings
Then default folder shows "/storage/emulated/0/Download/YouTubeDownloader"
And folder is created automatically
And write permission is requested if needed
```

#### Scenario: Change download folder
```gherkin
Given user is on Settings screen
When user taps "Change Folder"
And selects folder "/sdcard/MyVideos"
And taps "Confirm"
Then new path is saved to SharedPreferences
And success message shows "Download folder updated"
When user downloads next video
Then file is saved to "/sdcard/MyVideos"
```

#### Scenario: Handle insufficient permissions
```gherkin
Given user selects folder without write permissions
When user taps "Confirm"
Then error shows "Cannot write to this folder. Please choose another."
And previous valid folder remains active
```

---

### Feature: Download Playlist

#### Scenario: Download entire playlist
```gherkin
Given user pastes playlist URL with 5 videos
When user taps "Get Playlist Info"
Then playlist metadata shows:
  | Title          | Video Count |
  | My Playlist    | 5           |
When user selects "Audio" type and "128kbps" quality
And taps "Download All"
Then downloads start sequentially
And progress shows "Downloading 1/5: Video Title 1"
When first download completes
Then progress updates to "Downloading 2/5: Video Title 2"
When all 5 downloads complete
Then summary screen shows:
  | Successful | Failed |
  | 5          | 0      |
```

#### Scenario: Handle partial playlist failures
```gherkin
Given playlist has 3 videos: Video1, Video2 (private), Video3
When user downloads playlist
Then Video1 downloads successfully
And Video2 fails with "Video unavailable"
And Video3 downloads successfully
And summary shows:
  | Successful | Failed    |
  | 2          | 1 (Video2) |
```

---

## 6. Non-Functional Requirements

### 6.1 Performance
- Video metadata fetch: < 3 seconds
- Download speed: Limited by user's internet connection
- UI responsiveness: No blocking operations on main thread
- Memory usage: Stream downloads to avoid loading entire video in RAM

### 6.2 Usability
- Minimalist UI: Focus on core download functionality
- Clear error messages with actionable guidance
- Progress indicators for all async operations
- Responsive design for different screen sizes

### 6.3 Reliability
- Graceful handling of network interruptions (show retry option)
- Validate URLs before processing
- Prevent duplicate simultaneous downloads
- Clean up partial downloads on failure

### 6.4 Security
- Request minimum required permissions (Storage on Android)
- Validate file paths to prevent directory traversal
- Sanitize filenames to prevent injection attacks
- No data collection or analytics

### 6.5 Platform-Specific
- **Android**: Handle scoped storage (Android 10+)
- **Windows**: Follow Windows file naming conventions
- Both: Respect platform-specific default paths

---

## 7. UI/UX Mockup Description

### Main Screen (Download Page)
```
┌─────────────────────────────────────┐
│ YouTube Downloader          [⚙️]    │
├─────────────────────────────────────┤
│                                     │
│  📎 Paste YouTube URL or Playlist   │
│  ┌─────────────────────────────┐   │
│  │ https://youtube.com/watch?v │   │
│  └─────────────────────────────┘   │
│                [Get Info]           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🎬 Video Title Here         │   │
│  │ Duration: 3:45              │   │
│  │ [Thumbnail Preview]         │   │
│  └─────────────────────────────┘   │
│                                     │
│  Download Type:                     │
│  ( ) Video  (•) Audio-only          │
│                                     │
│  Quality:                           │
│  ┌─────────────────────────────┐   │
│  │ 720p (85 MB)           ▼    │   │
│  └─────────────────────────────┘   │
│                                     │
│         [Download] 💾               │
│                                     │
│  Progress: ████████░░░░░░ 60%      │
│                                     │
└─────────────────────────────────────┘
```

### Settings Screen
```
┌─────────────────────────────────────┐
│ ← Settings                          │
├─────────────────────────────────────┤
│                                     │
│  Download Folder                    │
│  ┌─────────────────────────────┐   │
│  │ /storage/Download/YouTubeDL │   │
│  └─────────────────────────────┘   │
│                [Change Folder]      │
│                                     │
│  Default Quality                    │
│  ┌─────────────────────────────┐   │
│  │ 720p                    ▼   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Default Type                       │
│  ( ) Video  (•) Audio-only          │
│                                     │
│                [Save]               │
│                                     │
└─────────────────────────────────────┘
```

---

## 8. Implementation Phases

### Phase 1: Core Infrastructure (Foundation)
- Set up project structure (Clean Architecture)
- Configure dependencies
- Implement SharedPreferences service
- Set up BLoC architecture
- Create base error handling

### Phase 2: Settings Feature
- Default folder selection UI
- Folder picker integration
- Permission handling (Android)
- Settings persistence
- Validation logic

### Phase 3: Single Video Download
- URL input & validation
- YouTube metadata fetching (youtube_explode_dart)
- Quality selection UI
- Download logic with progress tracking
- File saving & naming
- Success/error notifications

### Phase 4: Playlist Download
- Playlist URL parsing
- Playlist metadata fetching
- Sequential download queue
- Batch progress tracking
- Summary screen
- Error aggregation

### Phase 5: Polish & Testing
- UI refinements
- Error message improvements
- Edge case handling
- Platform-specific testing (Android + Windows)
- Performance optimization

---

## 9. Testing Strategy

### 9.1 Unit Tests
- URL validation logic
- Filename sanitization
- Quality selection logic
- SharedPreferences service
- YouTube URL parsing

### 9.2 Widget Tests
- Download form validation
- Quality selector widget
- Progress indicator updates
- Error message display
- Settings screen interactions

### 9.3 Integration Tests
- End-to-end download flow
- Playlist processing
- Settings persistence
- Permission handling
- File system operations

### 9.4 Platform Tests
- Android APK testing on physical device
- Windows executable testing
- Permission flows on Android 10+
- Folder picker on both platforms

---

## 10. Success Metrics

### MVP Launch Criteria
✅ User can download single video successfully
✅ User can download playlist (minimum 3 videos)
✅ Settings persist across app restarts
✅ No crashes on happy path flows
✅ Both Android & Windows builds work
✅ Basic error handling covers 80% of common failures

### Future Metrics (Post-MVP)
- Average download success rate > 95%
- User retention (users downloading > 1 video)
- Average videos downloaded per session

---

## 11. Risk Assessment & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| YouTube changes API/structure | High | Medium | Use youtube_explode_dart (actively maintained), monitor for breaking changes |
| Google rate limiting | Medium | Low | Implement sequential downloads, add delays between requests |
| Large file memory issues | Medium | Medium | Use streaming downloads, don't load entire file in memory |
| Permission denials (Android) | Medium | Medium | Clear UI explanation, graceful degradation to public Downloads folder |
| Playlist with 100+ videos | Low | Low | Add warning for large playlists, allow cancellation |

---

## 12. Constraints & Assumptions

### Constraints
- No YouTube API key (using youtube_explode_dart parsing)
- Mobile data usage concerns (large video files)
- Android scoped storage limitations (API 29+)
- No background download service (MVP)

### Assumptions
- User has stable internet connection
- User has sufficient storage space
- User understands legal implications
- youtube_explode_dart remains functional

---

## 13. References & Resources

### Technical Documentation
- Flutter: https://docs.flutter.dev
- youtube_explode_dart: https://pub.dev/packages/youtube_explode_dart
- BLoC Pattern: https://bloclibrary.dev

### Compliance
- YouTube Terms of Service: https://www.youtube.com/t/terms
- Google Play Developer Policies (if distributing on Play Store)

---

**End of Specification**

---

## Approval & Next Steps

**Specification Status:** ✅ Ready for Technical Refinement

**Next Agent:** `feature-refiner`
**Expected Output:** Technical feasibility analysis, library evaluation, architecture validation

**Subsequent Workflow:**
feature-refiner → coder (with flutter-dev-patterns skill) → qa-code-reviewer
