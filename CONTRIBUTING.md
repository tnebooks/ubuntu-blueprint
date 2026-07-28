# Contributing to Ubuntu Blueprint

Thank you for your interest in contributing to **Ubuntu Blueprint**! We welcome contributions from the community to help maintain and extend this modular Ubuntu provisioning framework.

## How to Contribute

1. **Fork the Repository**: Click the "Fork" button at the top right of this repository to create your own copy.
2. **Clone your Fork**:
   ```bash
   git clone https://github.com/<your-username>/ubuntu-blueprint.git
   cd ubuntu-blueprint
   ```
3. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your Changes**: Ensure your bash scripts and blueprint modules are modular, clean, and well-tested.
5. **Commit your Changes**: Use meaningful commit messages:
   ```bash
   git commit -m "feat: add blueprint module for X"
   ```
6. **Push to your Fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**: Go to the original repository on GitHub and click "New Pull Request" comparing your feature branch against the `main` branch.

## Code & Script Guidelines

- Write clean, POSIX-compliant or standard bash code with error handling (`set -euo pipefail` where applicable).
- Keep profile blueprints modular and isolated.
- Avoid hardcoding system-specific paths or user credentials.

## Reporting Issues

If you find a bug or have a suggestion, please open an issue in the main repository with a clear description and environment specifications.

Thank you for contributing!
