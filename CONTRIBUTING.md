# Contributing to Wispr

We welcome contributions to Wispr! Before you get started, please take a moment to review these guidelines.

## Getting Started

### Prerequisites

*   macOS 13+ (Monterey or later)
*   Xcode Command Line Tools (`swiftc`, `swift run`)
*   `uv` for dependency management (install with `pip install uv`)

### Setting Up Your Development Environment

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yash-jain-560/wispr.git
    cd wispr
    ```
2.  **Install dependencies:**
    ```bash
    uv sync --frozen
    source .venv/bin/activate
    ```
3.  **Download required models:** Refer to the [Required Models section in `README.md`](README.md#required-models) for details on downloading LTX-2, upscalers, and LoRA models.
4.  **Configure environment variables:** Create a `.env` file based on `.env.example` and set your `GEMINI_API_KEY` (if using `cloud` AI mode) and any other necessary configurations.

## Reporting Issues

If you encounter any bugs or issues, please report them on the [GitHub Issues page](https://github.com/yash-jain-560/wispr/issues). When reporting, please include:

*   A clear and concise description of the bug.
*   Steps to reproduce the behavior.
*   Expected behavior.
*   Screenshots or videos (if applicable).
*   Your environment details (macOS version, OpenClaw version, etc.).

## Submitting Pull Requests

1.  **Fork the repository** and create your branch from `main`.
2.  **Make your changes.** Ensure your code adheres to the project's coding style (SwiftLint, if configured, or general Swift best practices).
3.  **Test your changes.** Run existing tests and add new ones for new features or bug fixes. (`./run test`)
4.  **Update documentation** as needed.
5.  **Commit your changes** with clear and descriptive commit messages.
6.  **Push your branch** to your fork.
7.  **Open a pull request** to the `main` branch of the `yash-jain-560/wispr` repository. Describe your changes clearly and link to any relevant issues.

## Code Style

Follow standard Swift coding conventions and practices. We aim for clean, readable, and maintainable code.

## Licensing

By contributing to Wispr, you agree that your contributions will be licensed under the [MIT License](LICENSE.md).