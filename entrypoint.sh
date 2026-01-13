#!/bin/bash
set -e

# Set environment for the hytale user
export HOME="/hytale"
DATA_DIR="/hytale/data"
DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"
JAR_FILE="HytaleServer.jar"

# Ensure correct permissions
echo ">> Fixing permissions for $DATA_DIR..."
# 775 ensures user and group (hytale) can read/write/execute
chmod 775 "$DATA_DIR"
chown -R hytale:hytale "$DATA_DIR"
chown -R hytale:hytale "$HOME"
cd "$DATA_DIR"

# Helper to check if server files exist
function check_files() {
    local found_zip=$(find . -maxdepth 1 -iname "*assets*.zip" | head -n 1)
    if [[ -f "$JAR_FILE" && -n "$found_zip" ]]; then
        ASSETS_FILE=$(basename "$found_zip")
        return 0
    fi
    return 1
}

# Download and run downloader if needed
if ! su-exec hytale:hytale bash -c "test -f '$JAR_FILE'" || ! check_files || [[ "${FORCE_UPDATE,,}" == "true" ]]; then
    echo ">> Server files missing or update requested."
    
    # Check if we need to download the downloader
    # We look for any executable with 'hytale-downloader' in the name
    DOWNLOADER_BIN=$(find . -name "hytale-downloader*" -type f -executable | head -n 1)

    if [[ -z "$DOWNLOADER_BIN" ]]; then
        echo ">> Downloading Hytale Downloader..."
        su-exec hytale:hytale curl -L -o downloader.zip "$DOWNLOADER_URL"
        su-exec hytale:hytale unzip -o downloader.zip
        su-exec hytale:hytale rm downloader.zip
        
        # Find it again
        # We need to find the file, it might not be executable yet if unzip didn't preserve it
        DOWNLOADER_BIN=$(find . -name "hytale-downloader*" -type f | grep -v ".zip" | head -n 1)
        
        if [[ -z "$DOWNLOADER_BIN" ]]; then
            echo "!! Error: Could not find hytale-downloader binary after unzip."
            ls -laR
            exit 1
        fi
        
        chmod +x "$DOWNLOADER_BIN"
        chown hytale:hytale "$DOWNLOADER_BIN"
    fi

    echo ">> Found downloader: $DOWNLOADER_BIN"
    echo ">> Running Hytale Downloader..."
    echo ">> IMPORTANT: You will likely see an authentication link below. Please open it in your browser."
    
    # Run as hytale user
    if ! su-exec hytale:hytale "$DOWNLOADER_BIN"; then
        echo "!! Error: Hytale Downloader exited with error."
    fi
    
    echo ">> Downloader finished. Verifying files..."
    ls -la

    # Check for the downloaded release zip if jar is missing
    if [[ ! -f "$JAR_FILE" ]]; then
        echo ">> HytaleServer.jar not found. Checking for release zip..."
        # Find the release zip (ignoring assets.zip if it exists, though it shouldn't yet)
        # Pattern: YYYY.MM.DD-*.zip
        RELEASE_ZIP=$(find . -maxdepth 1 -name "????.??.??-*.zip" | head -n 1)
        
        if [[ -n "$RELEASE_ZIP" ]]; then
            echo ">> Found release zip: $RELEASE_ZIP"
            echo ">> Extracting release zip..."
            if su-exec hytale:hytale unzip -o "$RELEASE_ZIP"; then
                echo ">> Extraction complete."
                
                # The zip extracts to a 'Server' subdirectory. We need to move files out.
                if [[ -d "Server" && -f "Server/$JAR_FILE" ]]; then
                    echo ">> Moving server files from subdirectory..."
                    # Move content of Server/* to .
                    # We use cp -r and rm because mv across volumes/filesystems can be tricky, 
                    # but here it's same dir. mv should work.
                    su-exec hytale:hytale mv Server/* .
                    su-exec hytale:hytale rmdir Server
                fi
                
            else
                echo "!! Error: Failed to extract $RELEASE_ZIP"
                exit 1
            fi
        else
            echo ">> No release zip found."
        fi
    fi
fi

# Check again
if [[ ! -f "$JAR_FILE" ]]; then
    echo "!! Error: $JAR_FILE not found."
    echo "!! Debugging: Listing all files..."
    ls -laR
    exit 1
fi

# Find the assets file again to be sure
FOUND_ZIP=$(find . -maxdepth 1 -iname "*assets*.zip" | head -n 1)
if [[ -n "$FOUND_ZIP" ]]; then
    ASSETS_FILE=$(basename "$FOUND_ZIP")
else
    echo "!! Error: Assets zip file not found."
    exit 1
fi

# Construct arguments
ARGS="--bind ${BIND_ADDRESS:-0.0.0.0}"
ARGS="$ARGS --assets $ASSETS_FILE"

if [[ "${DISABLE_SENTRY,,}" != "false" ]]; then
    ARGS="$ARGS --disable-sentry"
fi

if [[ "${DISABLE_AOT,,}" == "true" ]]; then
    ARGS="$ARGS --disable-aot-cache"
fi

# Append custom args
ARGS="$ARGS ${SERVER_ARGS}"

echo ">> Starting Hytale Server..."
echo ">> Command: java $HYTALE_OPTS -jar $JAR_FILE $ARGS"

exec su-exec hytale:hytale java $HYTALE_OPTS -jar "$JAR_FILE" $ARGS

# Find the assets file again to be sure
FOUND_ZIP=$(find . -maxdepth 1 -iname "*assets*.zip" | head -n 1)
if [[ -n "$FOUND_ZIP" ]]; then
    ASSETS_FILE=$(basename "$FOUND_ZIP")
else
    echo "!! Error: Assets zip file not found."
    exit 1
fi

# Construct arguments
ARGS="--bind ${BIND_ADDRESS:-0.0.0.0}"
ARGS="$ARGS --assets $ASSETS_FILE"

if [[ "${DISABLE_SENTRY,,}" != "false" ]]; then
    ARGS="$ARGS --disable-sentry"
fi

if [[ "${DISABLE_AOT,,}" == "true" ]]; then
    ARGS="$ARGS --disable-aot-cache"
fi

# Append custom args
ARGS="$ARGS ${SERVER_ARGS}"

echo ">> Starting Hytale Server..."
echo ">> Command: java $HYTALE_OPTS -jar $JAR_FILE $ARGS"

exec su-exec hytale:hytale java $HYTALE_OPTS -jar "$JAR_FILE" $ARGS
