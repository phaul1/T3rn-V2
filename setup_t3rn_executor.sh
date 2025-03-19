#!/bin/bash

# Set your preferred Node Environment
export ENVIRONMENT=testnet

# Set your log settings
export LOG_LEVEL=debug
export LOG_PRETTY=false

# Process bids, orders, and claims
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_PROCESS_ORDERS_ENABLED=true
export EXECUTOR_PROCESS_CLAIMS_ENABLED=true

# Specify limit on gas usage (default is 1000 gwei, adjust as needed)
export EXECUTOR_MAX_L3_GAS_PRICE=100

# Prompt user for private key
read -sp "Enter your private key: " PRIVATE_KEY_LOCAL
export PRIVATE_KEY_LOCAL

# Enable networks to operate on
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'

# Configure RPC endpoints
export RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'

# Enable order processing via API for higher reliability
export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true

# Install screen if not installed
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    sudo apt-get update && sudo apt-get install -y screen
fi

# Start the executor inside a screen session
screen -dmS t3rn-executor bash -c './executor; exec bash'

echo "t3rn Executor is running in the background. Use 'screen -r t3rn-executor' to view the session."
