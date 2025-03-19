#!/bin/bash

# Update package lists and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Install necessary dependencies
sudo apt install -y curl wget tar screen jq

# Define the t3rn directory path
T3RN_DIR="~/t3rn"

# Remove previous t3rn installations if they exist
if [ -d "$T3RN_DIR" ]; then
    echo "Removing existing t3rn installation..."
    rm -rf "$T3RN_DIR"
fi

# Recreate the t3rn directory
echo "Creating t3rn directory..."
mkdir -p "$T3RN_DIR"

# Change to t3rn directory
cd "$T3RN_DIR" || { echo "Failed to enter $T3RN_DIR, exiting..."; exit 1; }

# Download the latest Executor binary
echo "Downloading the latest t3rn Executor binary..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | jq -r '.tag_name')
EXECUTOR_FILE="executor-linux-${LATEST_VERSION}.tar.gz"
wget "https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/${EXECUTOR_FILE}"

# Extract the archive
echo "Extracting the Executor binary..."
tar -xzf "$EXECUTOR_FILE"

# Define executor binary path
EXECUTOR_BIN_DIR="$T3RN_DIR/executor/executor/bin"

# Ensure the directory exists before proceeding
if [ ! -d "$EXECUTOR_BIN_DIR" ]; then
    echo "Error: Executor binary directory not found!"
    exit 1
fi

# Navigate to executor binary directory
cd "$EXECUTOR_BIN_DIR" || { echo "Failed to enter $EXECUTOR_BIN_DIR, exiting..."; exit 1; }

# Prompt user for private key
read -p "Enter your private key: " PRIVATE_KEY_LOCAL
echo "PRIVATE_KEY_LOCAL=$PRIVATE_KEY_LOCAL" > .env

# Prompt user for maximum gas price
read -p "Enter your preferred maximum gas price in gwei (default is 100): " EXECUTOR_MAX_L3_GAS_PRICE
EXECUTOR_MAX_L3_GAS_PRICE=${EXECUTOR_MAX_L3_GAS_PRICE:-100}
echo "EXECUTOR_MAX_L3_GAS_PRICE=$EXECUTOR_MAX_L3_GAS_PRICE" >> .env

# Set environment variables
cat <<EOF >> .env
ENVIRONMENT=testnet
LOG_LEVEL=debug
LOG_PRETTY=false
EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true
ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'
RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
EOF

# Export variables from the .env file
export $(grep -v '^#' .env | xargs)

# Start the executor inside a screen session
screen -dmS t3rn-executor bash -c 'cd /root/t3rn/executor/executor/bin && source .env && ./executor; exec bash'

echo "t3rn Executor is running in the background. Use 'screen -r t3rn-executor' to view the session."
