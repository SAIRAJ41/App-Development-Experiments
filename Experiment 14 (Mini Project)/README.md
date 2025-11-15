# 🌙 Lunaris – Entertainment and Media App

A Mini Project for App Development (Flutter + Firebase)

Lunaris is a modern movie-exploration application built using Flutter, powered by Firebase, OMDB API, and YouTube API.
It provides a visually rich experience with interactive UI, watchlists, likes, comments, trailer playback, premium features, and an admin dashboard.

# Feature 
## Authentication
-- Signup / Login using Firebase Auth
-- Email + password login
-- Guest mode with limited features
-- User profile with editable name, email, birthday & theme mode settings

## Home Screen
-- Displays multiple movie categories:
   1) ⭐ Top Rated
   2) 🚀 Sci-Fi
   3) 📈 Trending
   4) 🎭 Action Movies
   5) 😂 Comedy Movies
-- Each category shows 10 curated movie posters
-- Fetch movie data using OMDB API

## Movie Details
-- YouTube trailer auto-fetch
-- Like button with real-time like count
-- Add/remove from watchlist
-- User comments with avatars
-- Neon, glassmorphic, and gradient UI elements

## Watchlist System
-- Free users can save maximum of 5 movies
-- Premium users get unlimited watchlist
-- Real-time sync using Firestore

## Premium Membership
-- Premium users get:
1) Unlimited watchlist
2) No ads
3) AI Movie Assistant
4) Special "Premium Lounge" page
5) Premium badge on profile
6) AI Bot (Gemini API)
   Provides movie suggestions
   Answers user queries
   Integrated real-time chat system
   
## Admin Features
Admin can view all users
Toggle premium status for each user
View user’s likes, comments, watchlist
Admin is automatically treated as premium

##  🏛 Tech Stack
-- Frontend
1) Flutter
2) Dart
3) Provider (State Management)
4) Glassmorphism & advanced UI widgets

-- Backend
1) Firebase Authentication
2) Firebase Firestore
3) Firebase Storage (optional for profile pictures)

-- APIs
1) OMDB API → Movie details
2) YouTube API → Trailer search
3) Gemini API → AI Movie Assistant

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
