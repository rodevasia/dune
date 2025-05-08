#!/bin/bash

APP_NAME="dune" # Change this to your app name (no .exe)
EXE_FILE="$APP_NAME"

# Detect OS
OS="$(uname -s)"

# Windows (via Git Bash or similar)
if [[ "$OS" == "MINGW"* || "$OS" == "MSYS"* || "$OS" == "CYGWIN"* ]]; then
    echo "Detected Windows environment..."
    DEST="$USERPROFILE/AppData/Local/Microsoft/WindowsApps"
    EXE_FILE="$APP_NAME.exe"

    if [[ -f "./$EXE_FILE" ]]; then
        echo "Copying $EXE_FILE to $DEST"
        cp "$EXE_FILE" "$DEST" || { echo "Failed to copy. Try running as administrator."; exit 1; }
        echo "Installed! You can now run '$APP_NAME' from the command prompt."
    else
        echo "Error: ./$EXE_FILE not found!"
        exit 1
    fi

# macOS
elif [[ "$OS" == "Darwin" ]]; then
    echo "Detected macOS..."
    DEST="/usr/local/bin"

    if [[ -f "./$EXE_FILE" ]]; then
        echo "Copying $EXE_FILE to $DEST"
        sudo cp "$EXE_FILE" "$DEST/"
        sudo chmod +x "$DEST/$EXE_FILE"
        echo "Installed! You can now run '$APP_NAME' from the terminal."
    else
        echo "Error: ./$EXE_FILE not found!"
        exit 1
    fi

# Linux
elif [[ "$OS" == "Linux" ]]; then
    echo "Detected Linux..."
    DEST="/usr/bin"

    if [[ -f "./$EXE_FILE" ]]; then
        echo "Copying $EXE_FILE to $DEST"
        sudo cp "$EXE_FILE" "$DEST/"
        sudo chmod +x "$DEST/$EXE_FILE"
        echo "Installed! You can now run '$APP_NAME' from the terminal."
    else
        echo "Error: ./$EXE_FILE not found!"
        exit 1
    fi

else
    echo "Unsupported OS: $OS"
    exit 1
fi
