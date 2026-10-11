# Leantime Home Assistant Add-on Repository

[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-Add--on-blue.svg)](https://www.home-assistant.io/)
[![Leantime](https://img.shields.io/badge/Leantime-Project%20Management-brightgreen.svg)](https://leantime.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status: Experimental](https://img.shields.io/badge/Status-Experimental-orange.svg)](#disclaimer)
[![Architectures](https://img.shields.io/badge/Arch-amd64%20%7C%20aarch64-informational.svg)](#architecture)

This repository provides an experimental **Home Assistant Add-on** for [Leantime](https://leantime.io/) — an open-source, lean project management system tailored for innovators, startups, and creative teams.

> [!WARNING]
> ### Disclaimer: Experimental Software — No Support or Guarantee
> This add-on is an **experimental community project** provided strictly on an **"AS IS"** basis, **without any support, warranty, or guarantee** of any kind, whether express or implied.
> - **Use at your own risk:** Neither stability, data safety, nor long-term maintenance is guaranteed.
> - **Backup regularly:** Ensure you take frequent, independent Home Assistant backups before installing or upgrading.
> - **Non-Affiliation:** This project is independent and is neither affiliated with nor officially endorsed by Leantime or Nabu Casa / Home Assistant.

---

## Important: Add-on Store vs. HACS

Home Assistant has two distinct extension mechanisms:

| Extension Type | Platform | Purpose | Typical Contents |
|---|---|---|---|
| **Add-on** *(This Repository)* | **Home Assistant Add-on Store** | Runs containerized Docker applications and system services managed by the Supervisor. | Dockerfile, Linux services (MariaDB, Nginx, PHP-FPM), Leantime web server. |
| **Integration / Frontend** | **HACS (Home Assistant Community Store)** | Adds Python device/platform integrations and custom Lovelace dashboard cards/themes. | `custom_components/`, Lovelace JS cards. |

> **Note:** Because Leantime is a full-featured web application requiring PHP, Nginx, and a MariaDB database in an isolated Docker container, it is installed via the **Home Assistant Add-on Store** (as a custom repository), rather than HACS.

---

## Features

- **Ready to Go Out-of-the-Box:** Includes an embedded MariaDB server initialized automatically on startup.
- **External Database Support:** Seamlessly connect to Home Assistant's official MariaDB add-on (`core-mariadb`) or an external MySQL/MariaDB database if preferred.
- **Data Persistence:** Database data (`/data/mysql`) and user file uploads (`/data/leantime/userfiles`) are stored in Home Assistant's persistent storage, surviving container restarts, updates, and rebuilds.
- **Full Home Assistant Backup Support:** All project data, tasks, and files are included in Home Assistant's native backup snapshots.
- **Supervised Services:** Process supervision via Supervisord ensures MariaDB, PHP-FPM, Nginx, and the Leantime background scheduler run reliably with automatic restart upon failure.
- **Multi-Architecture:** Supports `amd64` (Intel/AMD x86_64) and `aarch64` (Raspberry Pi 4/5, Odroid, ARM64 boards).

---

## Installation

### Method 1: Add as a Custom Repository in Home Assistant (Recommended)

1. Push this repository to your GitHub account (or use your repository URL).
2. Open your Home Assistant instance.
3. Navigate to **Settings** &rarr; **Add-ons** &rarr; **Add-on Store**.
4. Click the **three vertical dots** in the upper-right corner and select **Repositories**.
5. Paste your repository URL:
   ```text
   https://github.com/<your-username>/<your-repo-name>
   ```
6. Click **Add**, then close the dialog.
7. Scroll down to find the **Leantime** add-on (or use the search bar).
8. Click **Install**.

---

### Method 2: Local Installation (Development / Direct Copy)

If you prefer to install locally without pushing to GitHub:

1. Connect to your Home Assistant instance using the **Samba share**, **SSH & Web Terminal**, or **VS Code add-on**.
2. Navigate to the `/addons` directory on your Home Assistant filesystem.
3. Copy the `leantime/` folder from this repository into `/addons/leantime/`:
   ```bash
   # Directory structure on Home Assistant:
   /addons/
   └── leantime/
       ├── config.yaml
       ├── Dockerfile
       ├── run.sh
       ├── DOCS.md
       ├── CHANGELOG.md
       ├── icon.png
       └── logo.png
   ```
4. In Home Assistant, go to **Settings** &rarr; **Add-ons** &rarr; **Add-on Store**.
5. Click the **three vertical dots** in the upper-right corner and select **Check for updates**.
6. The **Leantime** add-on will appear under the **Local add-ons** section ready to install.

---

## Configuration

Before starting the add-on, navigate to the **Configuration** tab in the add-on menu:

```yaml
db_password: "YourSecureDatabasePasswordHere!"
session_password: "YourVeryLongRandomSessionSecretKey32Chars!"
app_url: ""
db_host: "localhost"
db_port: 3306
db_user: "leantime"
db_name: "leantime"
site_name: "Leantime"
```

### Configuration Options

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `db_password` | password | Yes | `ChangeThisSecretPassword123!` | Password for the database user. |
| `session_password` | password | Yes | `GenerateA32CharRandomString123!` | 32+ character random secret used for session salting. |
| `app_url` | string | No | `""` | Public base URL (e.g. `https://leantime.mydomain.com`). Leave empty to auto-detect. |
| `db_host` | string | No | `localhost` | Set to `localhost` to use embedded MariaDB, or set to an external hostname (e.g. `core-mariadb`). |
| `db_port` | port | No | `3306` | Port of the database server. |
| `db_user` | string | No | `leantime` | Database username. |
| `db_name` | string | No | `leantime` | Database schema name. |
| `site_name` | string | No | `Leantime` | Title displayed on the Leantime application. |

---

## First Run & Setup

1. In the **Info** tab of the add-on, click **Start**.
2. Monitor the **Log** tab until you see:
   ```text
   [INFO] Starting Leantime services (PHP-FPM, Nginx, Scheduler, MariaDB)...
   ```
3. Click the **OPEN WEB UI** button in Home Assistant or browse to:
   ```text
   http://<home-assistant-ip>:8080
   ```
4. Complete the initial Leantime installation wizard to create your administrator account.

---

## Repository Layout

```text
.
├── repository.yaml          # Home Assistant Add-on repository manifest
├── README.md                # Repository documentation & installation guide
├── LICENSE                  # MIT License
├── .gitignore               # Ignored files
└── leantime/                # Add-on package directory
    ├── config.yaml          # Home Assistant add-on specification & schema
    ├── Dockerfile           # Alpine-based container build recipe
    ├── run.sh               # Orchestration & MariaDB provisioning script
    ├── DOCS.md              # In-app documentation for Home Assistant UI
    ├── CHANGELOG.md         # Release history
    ├── icon.png             # Add-on store icon (192x192)
    └── logo.png             # Add-on store banner (512x512)
```

---

## Troubleshooting

- **Web interface not loading:** Ensure that port `8080` is not used by another service. You can adjust the host port under the **Network** configuration section of the add-on.
- **Log inspection:** Check the **Log** tab in the add-on UI. It streams logs from MariaDB, Nginx, and PHP-FPM directly.
- **Resetting Database:** To wipe and re-initialize the internal database, stop the add-on and delete the `/data/mysql` directory (or uninstall and reinstall without restoring backup).

---

## License

This project is licensed under the [MIT License](LICENSE).  
Leantime is open-source software licensed by the Leantime team.
