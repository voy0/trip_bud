# INITIAL DOCUMENTATION

## SCREENS

### Login Screen

- Login page with email / password / google?

#### User stories

- As a user, I can create an account using email and password.
- As a user, I can log in to access my trips and data.
- As a user, I can reset my password if I forget it.
- As a user, I can log in with Google?.
- As a user, I can log out securely and keep my data in the cloud.

### Map Screen

- Map with user taken pictures, by accessing gallery and location the app will show pics on the map
- Trip stats, shortened stats containing:
  - hours:minutes:seconds +/- ahead / behind schedule
  - spare time at location
  - distance to next location

#### User Stories

- As a user, I can see my current position on the map.
- As a user, I can see daily trip status
- As a user, I can tap on a map marker to view the attached photo.
- As a user, I can view my trip route on a map

### Trip Overview & Details

- Day Summary with
  - distance covered by foot / steps / vechicle, distance to go for the day
  - day plan broken down by scheduled time frame with automatic visited spots detection
  - number of pictures taken

#### User Stories

- As a user, I can see my schedule, distance to covered, distance to go
- As a user, I can see trip statistics (time, distance, steps).
- As a user, I can view visited places during the trip.
- As a user, I can start or stop tracking a trip manually.

### Trips Overview

- List of users trips, linking to trip details
- Countries Visited

#### User Stories

- As a user, I can create a new trip plan with a name, description, and date.
- As a user, I can view a list of my planned trips.
- As a user, I can edit or delete a planned trip.
- As a user, I can browse previous trip summaries in my history.

### Trip Gallery

- Displays photos taken during the trip

#### User Stories

- As a user, I can select photos from my gallery to attach to a trip.
- As a user, I can see my photos automatically placed on the map based on GPS data.

### Trip Creation & Planner

- Create trip
- Plan trip

#### User Stories

- As a user, I can create and plan trips

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
