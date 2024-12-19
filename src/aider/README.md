# Aider Dev Container Feature

This Dev Container Feature installs [Aider](https://github.com/Aider-AI/aider) into your development container, enabling AI-assisted pair programming directly from your terminal.

Aider leverages powerful language models (LLMs) to assist you in editing code within your local Git repository. With Aider, you can streamline the coding process, get instant suggestions, and rapidly iterate on new ideas—all without leaving your terminal.

## Example Usage

Add the Aider feature to your `.devcontainer/devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:latest",
  "features": {
    "github.com/ivy/aider-devcontainer-feature": {
      "version": "1.0.0"
    }
  }
}
```

If your base image doesn't include Python, the installation script will handle installing Python for you.

Alternatively, if you're using the `python` Dev Container Feature, the `installsAfter` directive will ensure that Python is installed first:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:latest",
  "features": {
    "ghcr.io/devcontainers/features/python": {
      "version": "latest"
    },
    "github.com/your-org/aider-devcontainer-feature": {
      "version": "1.0.0"
    }
  }
}
```

## Getting Started

1. **Open your repository in VS Code and run "Remote-Containers: Open Folder in Container" (or "Dev Containers: Rebuild and Reopen in Container").**

2. **Access Aider:**  
   Once the container finishes building, open a terminal in VS Code and run:
   ```bash
   aider --help
   ```
   You should see Aider's help menu, confirming that it’s installed correctly.

3. **Use Aider for AI pair programming:**  
   Aider can assist you in editing code files tracked by Git. For usage instructions, refer to the [Aider documentation](https://github.com/Aider-AI/aider) and its `--help` command output.

## Why Aider?

- **Seamless Integration:** Aider works directly with your local files and Git repository.
- **AI-driven Suggestions:** Get high-quality code suggestions and refactoring ideas as you type.
- **Boost Productivity:** Reduce context-switching by getting assistance without leaving the terminal.
- **Flexibility:** Works well alongside other dev tools and VS Code extensions in your containerized dev environment.

## Troubleshooting

- **Aider not found?**  
  Make sure the feature is correctly referenced in your `.devcontainer/devcontainer.json` and that you've rebuilt your dev container.
  
- **Missing Python?**  
  If you’re starting from a minimal base image, the installation script will install Python and `pip`. Ensure the container has internet access and that `apt-get` is available.

- **Network Issues?**  
  Aider uses LLMs for suggestions, so ensure you can reach the necessary endpoints. If you’re behind a firewall or using a proxy, configure your environment accordingly.

## Contributing

Contributions to this feature are welcome! Feel free to open issues or PRs in the repository. If you encounter problems, file a detailed issue so we can help resolve it quickly.

## License

This project is licensed under the MIT license. Please see the [LICENSE](../LICENSE) file for details.