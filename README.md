# Kubernetes Network Setup

Configuration and setup scripts for Kubernetes networking with Firewalla Gold.

## Structure
- `scripts/`: Network configuration and testing scripts
- `docs/`: Network architecture and configuration documentation

## Quick Start
1. Run network configuration check:
```bash
./scripts/network-config.sh
```

2. Follow the Firewal configuration guide in `docs/firewal-config.md` - removed given that many people may have different firewal types

## Requirements
- Some sort of Firewal
- Ubuntu machines for K8s nodes
- bash
- Basic network utilities (nc, ping, etc.)

## Security Notice
- This repository contains templates and scripts for network configuration
- Do NOT commit any actual configuration files or sensitive information
- Always use the templates and create local copies for your actual configuration
- The following information should NEVER be committed:
  - Actual IP addresses
  - MAC addresses
  - Network layout details
  - Security rules
  - Credentials
  - Certificate files
  - kubeconfig files

## License
MIT
