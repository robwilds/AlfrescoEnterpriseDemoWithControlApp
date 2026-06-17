# AGENTS.md

## What this is

Portable Docker Compose demo of **Alfresco Content Services 25.3 (Governance Edition)** + **Process Services 25.3** + custom apps, maintained by Rob Wilds.

## First run

```bash
chmod +x *.sh tools/*.sh   # make scripts executable
./run.sh                    # menu: option 1 (Start)
```

`run.sh` is the primary entrypoint. It opens Docker Desktop, extracts data zips if needed, runs `docker compose up -d`, waits for Alfresco on port 8080, and opens the browser.

## Key entrypoints

| What | File | How |
|------|------|-----|
| Demo launcher | `run.sh` | Menu-driven (options 1-9) |
| Control plane UI | `start.sh` | Starts Python server on port 9700; full web UI for container mgmt, AMP/JAR install, logs |
| Docker Compose | `DockerCompose/AlfrescoEnterprise/docker-compose.yaml` | The actual deployment definition |
| Compose includes | `DockerCompose/AlfrescoEnterprise/commons/base.yaml` | Traefik reverse proxy config |
| Tool scripts | `tools/{start,stop,down,restart,clearFolders,install_amps_and_jars,stop_and_backup,zipBackupData,pullAll}.sh` | Individual operations |

## Architecture

- **Traefik** reverse proxy routes everything on **port 8080** (path-based routing)
- **OpenLDAP** provides authentication (user: `demo`, password: `demo`)
- **Postgres** on 5432 (databases: `alfresco`, `activitiapp`, `activitiadmin`)
- **Elasticsearch** on 9200 for search indexing
- **ActiveMQ** on 61616 for async messaging
- **Apache James** on 25/143/993 for email (demo user: `demo@example.com` / `demo`)
- **Dozzle** on port 9999 for container log viewing

## Service profiles

Some services are gated by Docker Compose profiles and don't start by default:
- `disabled`: kibana, ldapadmin, webmail, chimera, fileplanuploadadw5, queryalfapi, processadmin, mcpo
- `donotstart`: control-center, transform-excel

Start them with: `docker compose --profile disabled up -d <service>`

## AMP / JAR installation workflow

1. Drop AMP/JAR files into `installs/content/` or `installs/share/`
2. Use the Control Plane UI (`start.sh` → port 9700) to install, OR
3. Run `tools/install_amps_and_jars.sh` manually

**AMP removal:** Installed AMPs that were installed via the Control Plane show a **Remove** button (determined by the presence of a `.applied` file in the container's amps dir). Clicking it runs `alfresco-mmt uninstall` to remove the module from the WAR and reverts the `.applied` file back to `.amp` so it reappears as pending.

Pre-installed extensions live in `DockerCompose/AlfrescoEnterprise/data/services/content/amps/` and `DockerCompose/AlfrescoEnterprise/data/services/share/amps/`.

## Data persistence

- Alfresco content: `DockerCompose/AlfrescoEnterprise/data/services/content/alf_data/`
- Postgres data: `DockerCompose/AlfrescoEnterprise/data/services/postgres/data/`
- `tools/clearFolders.sh` deletes both and restores from zip (resets to clean state)
- `tools/stop_and_backup.sh` stops services and zips data dirs
- Backup zips: `alf_data_backup.zip` and `postgres_backup.zip` in corresponding directories

## MCP / AI stack

- **wildsalfmcp** (port 8000): FastMCP-based Alfresco MCP server
- **mcpo** (port 8001, profile `disabled`): MCP→OpenAI protocol gateway for Open WebUI
- **Open WebUI** (port 3000): Chat interface
- **queryalfapi** (port 9600, profile `disabled`): AI query microservice
- Client config at `.openmcp/connection.json` (streamable HTTP → localhost:8000/mcp)

## Custom apps (all profile `disabled`)

| App | Port | Image |
|-----|------|-------|
| Weapons Detection (Chimera) | 4200 | `wildsdocker/chimera:v1` |
| File Plan Upload (ADW5) | 4201 | `wildsdocker/fileplanuploadadw5:v1` |
| AI Query API | 9600 | `wildsdocker/queryalfapi:v3` |
| MCP Server | 8000 | `wildsdocker/wildsalfmcp:v2` |

## Control Plane (mgr/)

- Python3 HTTP server at `mgr/server.py` (no dependencies beyond stdlib)
- Served on port 9700 via `start.sh`
- No build step required — pure Python + vanilla HTML/JS SPA

### UI features

| Feature | Details |
|---------|---------|
| Start / Stop / Restart All | POSTs to `/api/start\|stop\|restart` with an empty `containers` array. Triggers 1-second polling until all *appropriate* containers (no `donotstart`/`disabled` profile) reach the target state, then reverts to normal 5-second polling |
| Per-service Start / Stop / Restart | POSTs the service name to the same endpoints. Triggers a single refresh after 3 seconds |
| "waiting for Alfresco" banner | Yellow banner below the header visible during start/restart and after clicking "Restart Now" following an AMP/JAR install on Alfresco. Contains an inline Alfresco flower SVG. Disappears right before the "Alfresco is ready" overlay |
| "Alfresco is ready" overlay | Detects when Alfresco transitions from stopped → running, then after 5s calls `/api/status`. If healthy, shows a modal with "Open Alfresco" (→ `http://localhost:8080`) and "Not now" buttons |
| Container logs | Inline expandable log viewer per running service (last 20 lines via `/api/logs/<service>`). Logs auto-refresh every poll cycle while the accordion is open, and auto-scroll to the bottom on each update. Dozzle link opens container logs on port 9999 |
| AMP / JAR installation | Upload files to the `installs/` directory, then install AMPs into running containers via MMT, or copy JARs into WEB-INF/lib. Shows "Restart Required" prompt after install. Clicking "Restart Now" for Alfresco triggers the "waiting for Alfresco" banner |
| Safe JAR removal | Only manually installed JARs show the Remove button — built-in Alfresco/Share JARs are protected. Tracked in `mgr/data/installed_jars.json` on the host |
| Safe AMP removal | Only AMPs installed via the Control Plane (those with a `.applied` file in the container's amps dir) show a Remove button. Clicking it runs `alfresco-mmt uninstall` to purge the module from the WAR, then reverts `.applied` → `.amp` so it reappears as pending |
| AMP install / remove detection | Installed AMPs listed via `alfresco-mmt list`. The `removable` flag is determined dynamically by scanning the container's amps dir for `.applied` files, extracting each one's `module.id` via `module.properties`, and cross-referencing with MMT's module list |
| Quay.io login | Credential overlay shown only when `docker compose config --images` reveals quay.io images that are not locally cached. Uses `docker login quay.io` to authenticate, then starts containers |
| Refresh interval | Normal polling is 5 seconds (`setInterval` in `restoreNormalRefresh`). Fast polling (1s) during start/stop/restart operations |

### Smart refresh behavior

The `startFastRefreshUntil(action)` function (JS in `index.html`) replaces the old fixed-timeout fast refresh. It polls `/api/services` every 1 second and checks `checkPendingAction(data)`:
- For `start`/`restart`: waits until all *appropriate* services (`.isAppropriate()` — filters out `donotstart`/`disabled` profile services) are `running`
- For `stop`: waits until all appropriate services are `stopped`
- Once done, clears `pendingAction` and calls `restoreNormalRefresh()` (reverts to 5s)

The `waitingForAlfresco` flag gates the banner. It is set to `true` in `startAll`/`restartAll`, cleared in `stopAll`, cleared in `checkAlfrescoHealth` when healthy, and also set to `true` when clicking "Restart Now" after an AMP/JAR install on Alfresco. `alfrescoPromptShown` and `prevAlfrescoRunning` are reset on each start/restart so the cycle can repeat.

### Backend endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/status` | Health of alfresco/share containers |
| GET | `/api/services` | All compose services with running state, profile, container_id, Dozzle URL |
| GET | `/api/amps` | Installed and pending AMPs |
| GET | `/api/jars` | JARs in WEB-INF/lib |
| GET | `/api/local-files` | Files in `installs/content` and `installs/share` |
| GET | `/api/docker-status` | Docker installed/running |
| GET | `/api/docker/quay-status` | Checks which quay.io images are cached using `docker compose config --images` |
| GET | `/api/logs/<service>` | Last 20 lines of container logs |
| POST | `/api/start` | `docker compose up -d --pull missing` (no profiles → only non-profile-gated services) |
| POST | `/api/stop` | `docker compose stop` (stops all) |
| POST | `/api/restart` | `docker compose restart` (restarts all) |
| POST | `/api/upload` | Upload file to installs directory |
| POST | `/api/install/jar` | Copy JAR into container |
| POST | `/api/install/amp` | Install AMP via MMT |
| POST | `/api/remove/jar` | Remove JAR from container |
| POST | `/api/uninstall/amp` | Uninstall AMP from WAR via MMT (module_id + container) |
| POST | `/api/delete-file` | Delete file from installs directory |
| POST | `/api/docker/login` | `docker login quay.io` |
| POST | `/api/launch-docker` | Open Docker Desktop |

### Key service list behaviour

`list_services()` in `server.py` merges service names from YAML parsing + `docker compose config --services`, then cross-references with `docker compose ps --format json` for running state and container IDs. Profiles are parsed from the compose YAML and attached as `profile_name` on each service entry. Appropriate service filtering (`.isAppropriate()` in JS) excludes services with profile `donotstart` or `disabled`.

### Key files

| File | Role |
|------|------|
| `mgr/server.py` | Python stdlib HTTP server, all backend logic |
| `mgr/static/index.html` | Single-page app — all HTML, CSS, JS inline |
| `mgr/data/installed_jars.json` | Persistent tracking of user-installed JARs (only these show Remove buttons) |
| `mgr/static/hyland-icon.svg` | Hyland favicon |
| `mgr/static/alfresco-icon.svg` | Alfresco flower icon (graphic only, no text) — saved locally for reference |
| `start.sh` | Launches Python server, polls until ready, opens browser |

## No build / test / lint / CI

This repo has no package.json, no Makefile, no test framework, no lint config, no CI/CD. It is purely Docker Compose orchestration + bash scripts + a Python stdlib server.

## LDAP users (configured in init.ldif)

- `demo` / `demo` (primary demo user)
- `admin` / `admin` (Alfresco admin)

## Gotchas

- Always run `chmod +x *.sh tools/*.sh` after clone
- First start extracts data from zips (alf_data + postgres) — this takes time on initial boot
- Alfresco takes several minutes to be ready after containers start
- The license is an external `.bin` file referenced by name in `licenseid`
- `clearFolders.sh` destroys all data — use `stop_and_backup.sh` first if you need to preserve state
- All services run behind Traefik on port 8080 — individual container ports are internal
