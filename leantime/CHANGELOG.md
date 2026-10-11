# Changelog

## 1.0.0

- Initial release of the Leantime Home Assistant Add-on.
- Built on official `leantime/leantime:latest` multi-arch image (supporting `amd64` and `aarch64`).
- Self-contained embedded MariaDB instance with persistent data storage in `/data/mysql`.
- Flexible support for external database engines (e.g. Home Assistant core MariaDB add-on).
- Automatic persistence for uploaded user files and attachments in `/data/leantime/userfiles`.
- Full process supervision with automated recovery (MariaDB, PHP-FPM, Nginx, Leantime Scheduler).
- Configurable port exposure with direct Web UI launcher integration (`webui: http://[HOST]:[PORT:8080]`).
