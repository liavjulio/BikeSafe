#!/bin/bash

# Set the project directory to the backend directory
cd bikesafe-backend

echo "Setting up Backend (Node.js) Development Environment..."

# Check if Node.js is installed
node -v || { echo "Node.js is not installed. Please install Node.js first."; exit 1; }

# Install dependencies from package.json
npm install

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Please create one with the required environment variables."
    exit 1
fi

# Set up the database (example for MongoDB)
echo "Setting up MongoDB for Development..."
mongo "${MONGO_URI}" < scripts/setupDB.js  # Ensure your DB setup script works with the URI

# Start the backend server in development mode
npm run dev  # Assuming you have a dev script in package.json

echo "Backend setup complete. Server is running in development mode."