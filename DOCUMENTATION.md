# INITIAL DOCUMENTATION

# SCREENS

## Account Creation & Login

### Login

### Register

## Current Trip

### Navigation

### Trip Details

## Trips

### My trips

### Trip Creation

#### Where and when screen

- Where to where
- When to when

#### Add places screen

- add places

#### Schedule

- edit schedule

#### Configuration

- set pace
- view places
- view schedule

# OPTIONAL REQUIREMENTS

## First

- 5p. Firebase Auth Sign-in
- 10p. Multi-Step form with validation (Trip Creation & Planner)

## Second

- 15p. Local Data Persistence (Saved offline data)
- 5p/15p. Platform Channels (Photos, Maps, Localization)

## Last

- 5p. Animations
- 10p. Internationalization (Multiple Languages)

```mermaid
graph TD
    %% --- INITIALIZATION ---
    Start((App Start)) --> CheckAuth{Is Logged In?}

    %% --- AUTHENTICATION MODULE ---
    subgraph Auth_Module [Authentication]
        style Auth_Module fill:#f9f9f9,stroke:#333,stroke-width:2px

        CheckAuth -- No --> Login[Login Screen<br/>Email/Pass OR Google]
        Login -- "Don't have account?" --> Register[Register Screen]
        Login -- "Forgot Password?" --> ResetPass[Reset Password Screen]

        Register -- Success --> CheckAuth
        ResetPass -- Email Sent --> Login
    end

    %% --- MAIN APP HUB ---
    subgraph Main_Hub [Home & Trips Overview]
        style Main_Hub fill:#e1f5fe,stroke:#0277bd,stroke-width:2px

        CheckAuth -- Yes --> TripsOverview[Trips Overview<br/>List of Planned & Past Trips]

        %% Profile Logic
        TripsOverview -- Profile Icon --> UserProfile[Profile Screen<br/>Languages/Settings]
        UserProfile -- Logout --> Login
    end

    %% --- TRIP CREATION (Multi-Step Form Requirement) ---
    subgraph Trip_Planner [Trip Creation Wizard]
        style Trip_Planner fill:#fff3e0,stroke:#ef6c00,stroke-width:2px

        TripsOverview -- "FAB: Create Trip" --> Step1

        Step1[Step 1: Trip Info<br/>Name, Dates, Desc] -->|Next| Step2
        Step2[Step 2: Planner<br/>Add Places/Countries] -->|Next| Step3
        Step3[Step 3: Schedule<br/>Time Frames & Estimations] -->|Save w/ Validation| SaveAction

        SaveAction(Save to Local DB & Cloud) --> TripsOverview
    end

    %% --- ACTIVE TRIP DASHBOARD ---
    subgraph Single_Trip_View [Specific Trip Dashboard]
        style Single_Trip_View fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px

        TripsOverview -- Select a Trip --> TripDetails

        %% 1. Details Screen
        TripDetails[Trip Overview & Details<br/>Day Summary, Steps, Distance]
        TripDetails -- "Toggle Tracking" --> TrackService{{Background Location Service}}

        %% 2. Map Screen
        TripDetails -- Tab: Map --> MapScreen[Map Screen<br/>Route, GPS Position, Photo Markers]
        MapScreen -- Tap Marker --> ImageViewer[View Attached Photo]

        %% 3. Gallery Screen
        TripDetails -- Tab: Gallery --> TripGallery[Trip Gallery<br/>Grid of Trip Photos]
        TripGallery -- "Add Photo" --> DeviceGallery[Platform Channel:<br/>Pick from Device Gallery]

        %% Cross Navigation
        MapScreen <--> TripGallery
    end

    %% --- DATA PERSISTENCE LAYER ---
    TrackService -.-> LocalDB[(Local DB<br/>Hive/Drift)]
    SaveAction -.-> LocalDB
    LocalDB -.-> CloudDB[(Firebase/Cloud)]

    %% Styling for clarity
    classDef action fill:#ffcc80,stroke:#e65100,stroke-width:1px;
    class SaveAction,TrackService action;

```
