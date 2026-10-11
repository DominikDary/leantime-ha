# Home Assistant Add-on: Leantime

[Leantime](https://leantime.io/) is an open-source, lean project management system built for innovators, creators, and small teams. It combines strategy planning, task management, milestones, and idea boards into a single streamlined workspace.

> **Disclaimer:** This add-on is an **experimental community project** provided on an **"AS IS"** basis, **without any support, warranty, or guarantee**. Use at your own risk and always make regular Home Assistant backups.

---

## Getting Started

### 1. Installation

1. In Home Assistant, navigate to **Settings** -> **Add-ons** -> **Add-on Store**.
2. Click the three dots in the top-right corner, select **Repositories**, and add your repository URL.
3. Refresh the page and find **Leantime** in the store.
4. Click **Install** and wait for the image to build/download.

### 2. Initial Configuration

Before starting the add-on, navigate to the **Configuration** tab:
1. Provide a secure, random **`db_password`**.
2. Provide a 32+ character random string for **`session_password`**.
3. (Optional) Set your **`app_url`** if accessing via external domain (e.g., `https://leantime.example.com`).
4. Click **Save**.

### 3. Starting the Add-on

1. Navigate to the **Info** tab.
2. (Optional) Enable **Start on boot** and **Watchdog**.
3. Click **Start**.
4. Check the **Log** tab to ensure MariaDB and Leantime services have initialized cleanly.
5. Click **Open Web UI** (or navigate to `http://<your-ha-ip>:8080`).
6. Follow the on-screen initial setup wizard to create your primary administrator account.

---

## Configuration Options

| Option | Type | Default | Description |
|---|---|---|---|
| `db_password` | password | Required | Password for the MariaDB `leantime` user. |
| `session_password` | password | Required | 32+ character key used to salt Leantime user sessions. |
| `app_url` | string | `""` | Base URL used for email notifications and links. |
| `db_host` | string | `localhost` | Database host. Set to `localhost` to use the embedded MariaDB, or specify an external host. |
| `db_port` | port | `3306` | Port for the database connection. |
| `db_user` | string | `leantime` | Database username. |
| `db_name` | string | `leantime` | Database name. |
| `site_name` | string | `Leantime` | Name of your Leantime instance. |

---

## Using an External Database

By default (`db_host: localhost`), this add-on automatically initializes and supervises an embedded MariaDB server inside `/data/mysql`.

If you prefer using an external MariaDB instance (such as Home Assistant's official MariaDB add-on):
1. In Home Assistant MariaDB add-on, create a database named `leantime` and grant permissions to a user.
2. In the Leantime add-on Configuration tab, set:
   - `db_host`: `core-mariadb` (or the IP/hostname of your external DB)
   - `db_port`: `3306`
   - `db_user`: Your external DB user
   - `db_password`: Your external DB password
   - `db_name`: `leantime`
3. Restart the Leantime add-on. When an external host is specified, the internal MariaDB server is automatically bypassed.

---

## Data Persistence & Backups

All critical data is stored inside Home Assistant's persistent `/data` volume:
- **Database Data:** `/data/mysql`
- **User Uploads & Attachments:** `/data/leantime/userfiles`

Whenever you create a Home Assistant backup of this add-on, `/data` is automatically included, ensuring that your projects, tasks, comments, and files are safely preserved.

---

## Troubleshooting

- **Database Connection Errors:** Verify your `db_password` in the Configuration tab. Check the add-on logs under the **Log** tab.
- **Port Conflict (8080):** If port 8080 is already used by another add-on or integration, change the host port in the **Configuration -> Network** section of the add-on.
- **Email Notifications:** To send email invitations and notifications, configure SMTP settings inside Leantime's **Company Settings** UI once logged in as administrator.
