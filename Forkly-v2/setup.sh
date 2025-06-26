#!/bin/bash
# Setup script for Forkly-v2
# This script helps set up the necessary configuration files for development

echo "Setting up Forkly-v2..."

# Create ApiKeys.swift from template if it doesn't exist
if [ ! -f "Utilities/ApiKeys.swift" ]; then
    echo "Creating ApiKeys.swift from template..."
    # Copy the template and replace the struct name
    cp "Utilities/ApiKeys.template.swift" "Utilities/ApiKeys.swift"
    # Replace ApiKeysTemplate with ApiKeys in the new file
    sed -i '' 's/struct ApiKeysTemplate/struct ApiKeys/g' "Utilities/ApiKeys.swift"
    # Update the file header
    sed -i '' 's/ApiKeys.template.swift/ApiKeys.swift/g' "Utilities/ApiKeys.swift"
    echo "✅ Created ApiKeys.swift"
    echo "⚠️  Please edit Utilities/ApiKeys.swift and add your actual API keys"
else
    echo "✅ ApiKeys.swift already exists"
fi

# Check for GoogleService-Info.plist
if [ ! -f "GoogleService-Info.plist" ]; then
    echo "⚠️  GoogleService-Info.plist not found"
    
    # Check if template exists and offer to create a placeholder
    if [ -f "GoogleService-Info.template.plist" ]; then
        echo "Would you like to create a placeholder GoogleService-Info.plist from the template?"
        echo "Note: You will need to replace the placeholder values with your actual Firebase configuration."
        read -p "Create placeholder? (y/n): " create_placeholder
        
        if [[ $create_placeholder == "y" || $create_placeholder == "Y" ]]; then
            cp "GoogleService-Info.template.plist" "GoogleService-Info.plist"
            echo "✅ Created placeholder GoogleService-Info.plist"
            echo "⚠️  Please replace the placeholder values in GoogleService-Info.plist with your actual Firebase configuration"
        else
            echo "Please download GoogleService-Info.plist from your Firebase console and place it in the Forkly-v2 directory"
        fi
    else
    echo "Please download GoogleService-Info.plist from your Firebase console and place it in the Forkly-v2 directory"
    fi
else
    echo "✅ GoogleService-Info.plist found"
fi

echo ""
echo "Setup complete! Please make sure to:"
echo "1. Edit Utilities/ApiKeys.swift with your actual API keys"
echo "2. Ensure GoogleService-Info.plist is properly configured with your Firebase details"
echo "3. Build and run the project"
echo ""
echo "For more information, see the README.md file" 