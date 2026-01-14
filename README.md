# Hytale Private Server - Docker Image

This repository provides a production-ready Docker image for running a Hytale Private Server. It is built on a lightweight Alpine Linux base with Eclipse Temurin Java 25, ensuring a secure and efficient environment for your server.

## Features

- **Alpine Linux Base**: Minimal footprint and enhanced security.
- **Java 25 Ready**: Pre-configured with Eclipse Temurin JDK 25.
- **Automated Setup**: Handles the downloading and extraction of `HytaleServer.jar` and `Assets.zip` automatically.
- **Secure Defaults**: Runs as a non-root user (`hytale`) with proper permission management.
- **Customizable**: extensive configuration via environment variables.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Quick Start with Docker Compose

1. **Create a `docker-compose.yml` file:**

   ```yaml
   services:
     hytale:
       image: lucasformiga/hytale-server-docker:latest
       container_name: hytale-server
       restart: unless-stopped
       ports:
         - "5520:5520/udp"
       volumes:
         - ./hytale-data:/hytale/data
       environment:
         - HYTALE_OPTS=-Xmx4G -Xms2G
         - DISABLE_SENTRY=true
       stdin_open: true
       tty: true
   ```

2. **Start the Server:**

   Run the following command in your terminal:

   ```bash
   docker compose up
   ```

   *Note: We recommend running without `-d` (detached mode) for the first run to easily see the authentication prompts.*

### First-Time Setup & Authentication

**Important:** The first time you start the server, you will need to authenticate it with your Hytale account.

1.  **Monitor the Console:** Watch the terminal output after starting the container.
2.  **Authenticate:** When the server startup initializes, it will prompt you for authentication. You will see a message asking you to log in.
3.  **Execute Login Command:**
    Type the following command directly into the server console (or your terminal if attached):
    
    ```
    /auth login device
    ```

4.  **Complete Authentication:** The server will provide a URL or a code. Copy this link/code and open it in your web browser to authorize the server.
5.  **Success:** Once authenticated, the server will finish loading and be ready for connections.

If you are running the server in detached mode (`-d`), you can access the console using:
```bash
docker attach hytale-server
```
*(Press `Ctrl+P`, `Ctrl+Q` to detach without stopping the container)*

## Configuration

You can configure the server behavior using environment variables in your `docker-compose.yml` or `docker run` command.

| Variable | Default | Description |
| :--- | :--- | :--- |
| `BIND_ADDRESS` | `0.0.0.0` | IP address the server listens on. |
| `HYTALE_OPTS` | *(empty)* | Java Virtual Machine (JVM) arguments (e.g., `-Xmx8G`). |
| `SERVER_ARGS` | *(empty)* | Additional arguments passed to the Hytale server executable. |
| `DISABLE_SENTRY` | `true` | Set to `false` to enable Sentry telemetry and error reporting. |
| `DISABLE_AOT` | `false` | Set to `true` to disable the AOT (Ahead-of-Time) cache. |
| `FORCE_UPDATE` | `false` | Set to `true` to force the downloader to run again on startup. |

## Data Persistence

All server data is stored in the `/hytale/data` directory inside the container. This includes:
-   `config.json`
-   `permissions.json`
-   `HytaleServer.jar`
-   World data and saves

By mounting a volume (as shown in the example), your data persists across container restarts and updates.

## Troubleshooting

-   **Permissions:** The container automatically handles permissions for the `/hytale/data` directory. If you manually edit files on the host, ensure they remain readable by the container user (UID 1000).
-   **Authentication Loop:** If the server keeps asking for authentication, ensure you have successfully completed the `/auth login device` flow and that the server has internet access.

## Pull Requests
All pull requests are welcome! Please ensure that your changes are well-documented and tested.

## License

This project is licensed under the [MIT License](LICENSE).
Hytale is a trademark of Hypixel Studios. This is an unofficial community-maintained image.
