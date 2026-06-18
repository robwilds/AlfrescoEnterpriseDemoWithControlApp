# AlfrescoDemoContainer

Portable Docker Compose demo of **Alfresco Content Services 26.1 (Governance Edition)** + **Process Services 25.3** + custom apps, maintained by Rob Wilds.

Includes: FastMCP server and an Open WebUI chat interface.

## Prerequisites

Before using the Control Plane UI, ensure the following are installed on your system:

- **Python** (any recent 3.x version)
- **Docker** (Docker Desktop or equivalent)
- **A web browser** of your choice
- **Quay.io credentails**

## Getting Started using Control Plane UI

The **Control Plane** (`start.sh`) is a Python stdlib web server on **port 9700** providing a full management interface:
** make sure to run chmod +x start.sh to make that script executable **

### Service Management

- **Start / Stop / Restart All** — 1-second auto-refresh polling until services reach target state; smart filtering excludes profile-gated services
- **Per-service controls** — start, stop, restart individual containers with status indicators
- **Services dashboard** — real-time status of all containers (running/stopped) with profile badges and colour-coded summary
- **"Start all services?" prompt** — shown when Docker is ready but no services are running; one-click start
- **Docker overlay** — if Docker isn't running, prompts to launch Docker Desktop or retry; waits for it to become ready

### Logs & Monitoring

- **Inline log viewer** — expandable per-service accordion showing last 20 lines with live auto-refresh and auto-scroll while open
- **Error highlighting** — lines containing `ERROR`, `FATAL`, `Exception`, `Traceback`, etc. rendered in red
- **Dozzle link** — per-service link to open full real-time logs in Dozzle (port 9999)

### Extensions Management (AMPs & JARs)

- **Upload** — upload AMP/JAR files to `installs/content/` or `installs/share/`
- **Install AMP** — installs into running container via MMT (`alfresco-mmt install -directory -nobackup -force`); renames to `.applied` on success
- **Install JAR** — copies into container's `WEB-INF/lib`; tracks in `installed_jars.json` for later removal
- **Install All** — batch-installs all uninstalled AMPs and JARs for a service with progress counter
- **Install status detection** — uses MMT's module list for accurate AMP install status (module ID extracted from AMP's `module.properties`), falling back to `.applied` file check if the AMP was deleted locally
- **Safe AMP removal (3-layer mechanism)** — AMPs installed via the Control Plane show a Remove button; pre-installed AMPs (shipped with the WAR) do not. The detection works as follows:
  1. **MMT list** — `alfresco-mmt list` runs inside each container (Alfresco and Share) to enumerate all modules currently installed in the WAR
  2. **`.applied` file scan** — the container's `amps/` (or `amps_share/`) directory is scanned for `*.applied` files. When the Control Plane installs an AMP via MMT, it renames the `.amp` → `.applied` to mark it as Control Plane-managed. Each `.applied` file is copied out and opened as a ZIP; its `module.properties` is read to extract `module.id`
  3. **Cross-reference** — a module only gets `removable: true` if its ID appears in **both** the MMT list and the `.applied` scan. Pre-installed AMPs have no `.applied` file on disk, so they never match. See `server.py:_get_applied_amp_ids()` and `server.py:api_list_amps()`
- **Uninstall flow** — clicking Remove runs `alfresco-mmt uninstall <module_id>` to purge it from the WAR, then locates the matching `.applied` file and renames it back to `.amp` so it reappears as pending (see `server.py:do_uninstall_amp()`)
- **Safe JAR removal** — only manually installed JARs show a Remove button; built-in Alfresco/Share JARs are protected. Tracked in `mgr/data/installed_jars.json` on the host (see `server.py:api_list_jars()`)
- **Pending vs installed** — AMP files in the container's `amps/` directory shown as pending; already-installed AMPs shown with install status
- **Delete file** — remove uploaded files from the `installs/` directory

### Overlays & Notifications

- **"Alfresco is ready"** — detects when Alfresco becomes healthy after a start/restart; prompts to open
- **"Waiting for Alfresco"** — animated yellow banner with Alfresco flower icon during startup and after AMP/JAR restarts
- **"Restart Required"** — appears after AMP/JAR installation; triggers banner cycle on restart
- **Quay.io login** — credential overlay shown only when quay.io images are not locally cached; auto-starts containers after login
- **Toast notifications** — success toasts auto-dismiss after 3s; error toasts persist with dismiss button
- **Refresh toast** — manual refresh shows success confirmation

### File Browser

- **Content / Share tabs** — browse files in both `installs/content/` and `installs/share/`
- **Install button per file** — shows "Install AMP" or "Install JAR" (or "(done)" if already installed)
- **Upload button** — upload new files to either directory
- **Post-upload install prompt** — asks to install immediately after upload

### Smart Refresh

- **Normal polling** — 5-second interval for service status, AMPs, JARs, and files
- **Fast polling** — 1-second interval during start/stop/restart operations
- **Target state detection** — waits until all appropriate services reach the expected state (running or stopped) before reverting to normal poll
- **Appropriate service filtering** — services with `donotstart` or `disabled` profiles excluded from state checks

### Guided Tour

6-step interactive walkthrough of the UI (auto-shows on first visit, persisted in `localStorage`; accessible via "?" button):

1. Service Controls — header action buttons
2. Services Table — container list
3. Logs & Monitoring — per-service log/dozzle buttons
4. File Management — Available Files card
5. Installed Modules (AMPs) — AMPs card
6. Library JARs — JARs card

## Login Credentials

| Service                | URL                                  | Username                     | Password | Notes                                            |
| ---------------------- | ------------------------------------ | ---------------------------- | -------- | ------------------------------------------------ |
| Share                  | http://localhost:8080/share          | `demo`                       | `demo`   | LDAP user                                        |
| Alfresco               | http://localhost:8080/alfresco       | `admin`                      | `admin`  | -                                                |
| phpLDAPadmin           | http://localhost:8400                | `cn=admin,dc=example,dc=com` | `admin`  | LDAP browser UI                                  |
| Process Services       | http://localhost:8080/activiti-app   | `admin`                      | `admin`  | Requires license to be applied first             |
| Process Services       | http://localhost:8080/activiti-app   | `demo@example.com`           | `demo`   | this login works after applying the license      |
| Process Services Admin | http://localhost:8080/activiti-admin | `admin`                      | `admin`  | Requires license to be applied first             |
| Rainloop Webmail       | http://localhost:8800                | `demo@example.com`           | `demo`   | Webmail client                                   |
| Open WebUI             | http://localhost:3000                | `demo@example.com`           | `demo`   | Pre-configured to talk to wildsalfmcp MCP server |

### Backend API Endpoints

| Method | Path                      | Purpose                                                                    |
| ------ | ------------------------- | -------------------------------------------------------------------------- |
| GET    | `/api/status`             | Health of alfresco/share containers                                        |
| GET    | `/api/services`           | All compose services with running state, profile, container_id, Dozzle URL |
| GET    | `/api/amps`               | Installed and pending AMPs (MMT-based)                                     |
| GET    | `/api/jars`               | JARs in WEB-INF/lib with removable flag                                    |
| GET    | `/api/local-files`        | Files in `installs/content` and `installs/share`                           |
| GET    | `/api/docker-status`      | Docker installed/running                                                   |
| GET    | `/api/docker/quay-status` | Checks which quay.io images are cached                                     |
| GET    | `/api/logs/<service>`     | Last 20 lines of container logs                                            |
| POST   | `/api/start`              | `docker compose up -d --pull missing`                                      |
| POST   | `/api/stop`               | `docker compose stop`                                                      |
| POST   | `/api/restart`            | `docker compose restart`                                                   |
| POST   | `/api/upload`             | Upload file to installs directory (base64)                                 |
| POST   | `/api/install/jar`        | Copy JAR into container WEB-INF/lib                                        |
| POST   | `/api/install/amp`        | Install AMP via MMT                                                        |
| POST   | `/api/remove/jar`         | Remove JAR from container (tracked only)                                   |
| POST   | `/api/uninstall/amp`      | Uninstall AMP from WAR via MMT (module_id + container)                     |
| POST   | `/api/delete-file`        | Delete file from installs directory                                        |
| POST   | `/api/docker/login`       | `docker login quay.io`                                                     |
| POST   | `/api/launch-docker`      | Open Docker Desktop (macOS)                                                |

### Key files

| File                           | Role                                               |
| ------------------------------ | -------------------------------------------------- |
| `mgr/server.py`                | Python stdlib HTTP server, all backend logic       |
| `mgr/static/index.html`        | Single-page app — all HTML, CSS, JS inline         |
| `mgr/data/installed_jars.json` | Persistent tracking of user-installed JARs         |
| `start.sh`                     | Launches Python server on port 9700, opens browser |

## Architecture

All services run behind a **Traefik** reverse proxy on **port 8080** (path-based routing). The full list of services defined in `docker-compose.yaml`:

### Default services (start automatically)

| Service                | Description                         | Port(s)                  |
| ---------------------- | ----------------------------------- | ------------------------ |
| **alfresco**           | Alfresco Governance Repository 26.1 | 8080 (via Traefik)       |
| **share**              | Alfresco Governance Share 26.1      | 8080 (via Traefik)       |
| **postgres**           | PostgreSQL 17.9                     | 5432                     |
| **elasticsearch**      | Elasticsearch 8.17                  | 9200, 9300               |
| **activemq**           | ActiveMQ message broker             | 8161, 5672, 61616, 61613 |
| **transform-router**   | Transform Router 4.4                | 8095                     |
| **transform-core-aio** | Transform Core AIO 5.4              | 8090                     |
| **shared-file-store**  | Shared File Store 4.4               | 8099                     |
| **search**             | Elasticsearch Live Indexing 5.5     | —                        |
| **search-reindexing**  | Elasticsearch Reindexing 5.5        | —                        |
| **audit-storage**      | Audit Storage 1.3                   | —                        |
| **digital-workspace**  | Alfresco Digital Workspace 7.4      | 8080 (via Traefik)       |
| **proxy**              | Traefik reverse proxy               | 8080                     |
| **sync-service**       | Sync Service 5.3                    | 9090                     |
| **ldap**               | OpenLDAP (Bitnami)                  | 389, 636                 |
| **email**              | Apache James email server           | 25, 143, 465, 993, 8500  |
| **dozzle**             | Container log viewer                | 9999                     |

### Profiled services (`donotstart` profile — start with `--profile donotstart`)

| Service            | Description                   | Port(s)                  |
| ------------------ | ----------------------------- | ------------------------ |
| **process**        | Process Services 25.3         | 8094, 8080 (via Traefik) |
| **processadmin**   | Process Services Admin 25.3   | 8096, 8080 (via Traefik) |
| **control-center** | Alfresco Control Center 10.4  | 8080 (via Traefik)       |
| **open-webui**     | Open WebUI chat interface     | 3000                     |
| **wildsalfmcp**    | Alfresco MCP Server (FastMCP) | 8000                     |

### Profiles quick reference

| Profile      | Services                                                                                   | How to start                                          |
| ------------ | ------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| _(none)_     | All default services                                                                       | `docker compose up -d`                                |
| `donotstart` | kibana, ldapadmin, webmail, process, processadmin, control-center, open-webui, wildsalfmcp | `docker compose --profile donotstart up -d <service>` |
