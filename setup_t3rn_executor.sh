#!/bin/bash

# Update package lists and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Install necessary dependencies
sudo apt install -y curl wget tar

# Define the t3rn directory path
T3RN_DIR="$HOME/t3rn"

# Remove previous t3rn installations if they exist
if [ -d "$T3RN_DIR" ]; then
    echo "Removing existing t3rn installation..."
    rm -rf "$T3RN_DIR"
fi

# Recreate the t3rn directory
echo "Creating t3rn directory..."
mkdir -p "$T3RN_DIR"
cd "$T3RN_DIR" || exit

# Download the latest Executor binary
echo "Downloading the latest t3rn Executor binary..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
EXECUTOR_FILE="executor-linux-${LATEST_VERSION}.tar.gz"
wget "https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/${EXECUTOR_FILE}"

# Extract the archive
echo "Extracting the Executor binary..."
tar -xzf "$EXECUTOR_FILE"

# Ensure everything runs inside $T3RN_DIR
cd "$T3RN_DIR" || exit

# Prompt user for private key
read -sp "Enter your private key: " PRIVATE_KEY_LOCAL
echo
export PRIVATE_KEY_LOCAL

# Prompt user for preferred maximum gas price
read -p "Enter your preferred maximum gas price in gwei (default is 100): " EXECUTOR_MAX_L3_GAS_PRICE
EXECUTOR_MAX_L3_GAS_PRICE=${EXECUTOR_MAX_L3_GAS_PRICE:-100}
export EXECUTOR_MAX_L3_GAS_PRICE

# Set environment variables
export ENVIRONMENT=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_PROCESS_ORDERS_ENABLED=true
export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'
export RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false

# Ensure we are still in t3rn directory
cd "$T3RN_DIR" || exit

# Install screen if not installed
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    sudo apt install -y screen
fi

# Start the executor inside a screen session
screen -dmS t3rn-executor bash -c './executor/executor/bin/executor; exec bash'

echo "t3rn Executor is running in the background. Use 'screen -r t3rn-executor' to view the session."
