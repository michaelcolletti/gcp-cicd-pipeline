#!/bin/bash

# Test runner script for GCP CI/CD Pipeline
set -e

echo "🧪 Running GCP CI/CD Pipeline Tests"
echo "=================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Node.js tests should run
if [ -d "HelloWorldNodeJs" ]; then
    echo "📦 Running Node.js Application Tests..."
    cd HelloWorldNodeJs
    
    # Install dependencies if not already installed
    if [ ! -d "node_modules" ]; then
        echo "Installing Node.js dependencies..."
        npm install
    fi
    
    # Run tests
    echo "Running Jest tests..."
    npm test
    
    echo "Running test coverage..."
    npm run test:coverage
    
    cd ..
    echo "✅ Node.js tests completed"
    echo ""
fi

# Check if bats is available for shell script tests
if command_exists bats; then
    echo "🔧 Running Shell Script Tests..."
    
    if [ -f "tests/pipeline.bats" ]; then
        bats tests/pipeline.bats
        echo "✅ Shell script tests completed"
    else
        echo "⚠️  No shell script tests found"
    fi
else
    echo "⚠️  bats not installed. To run shell script tests:"
    echo "   macOS: brew install bats-core"
    echo "   Ubuntu: sudo apt-get install bats"
    echo "   Or install from: https://github.com/bats-core/bats-core"
fi

echo ""
echo "🎉 Test suite completed!"
echo ""
echo "To run individual test suites:"
echo "  Node.js tests: cd HelloWorldNodeJs && npm test"
echo "  Shell tests:   bats tests/pipeline.bats"
echo "  Coverage:      cd HelloWorldNodeJs && npm run test:coverage"