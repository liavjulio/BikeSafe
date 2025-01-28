#!/bin/bash

# Set the project directory to the frontend directory
cd bikesafe_app

echo "Setting up Frontend (Flutter) Development Environment..."

# Check if Flutter is installed
flutter --version || { echo "Flutter is not installed. Please install Flutter first."; exit 1; }

# Fetch Flutter dependencies
flutter pub get

# Set environment variables if needed (optional)
export FLUTTER_ENV=development
export API_URL=http://localhost:5001  # Backend API URL for development

# Run the app in development mode
flutter run

echo "Frontend setup complete. Running the app in development mode."