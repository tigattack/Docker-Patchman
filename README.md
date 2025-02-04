# Docker Patchman

This is a Dockerised version of [Patchman](https://github.com/furlongm/patchman).

It also has a modified host page to add a separate section for security updates.

## Getting Started

1. Download `docker-compose.yml` and `.env`
2. Add your configuration in `.env` (see [Environment Variables](#environment-variables) below)
3. Run `docker compose up -d` or `docker-compose up -d` (old version)
4. Run `docker compose exec -it server patchman-manage createsuperuser` and enter the same ADMIN details you configured in `.env`
5. Run `docker compose logs mariadb 2>&1 | grep GENERATED` to get your generated MariaDB root password. Store this somewhere safe.
6. Browse to `<IP/hostname>:8080` and start using Patchman!

For next steps, you'll need to configure your Patchman clients. You can find instructions in the [Patchman](https://github.com/furlongm/patchman) repository.

### Scheduled Maintenance

The supplied `docker-compose.yml` includes a `scheduler` service which executes Patchman maintenance operations on a predefined schedule.

If the scheduler encounters any errors when performing Patchman maintenance, it will save logs to `./scheduler-error-logs`. You can also configure Slack and SMTP notifications; see [here](https://github.com/mcuadros/ofelia#logging) for information.

See the [Environment Variables](#environment-variables) section below for the default schedule and how to change it to your preference.

Patchman maintenance (executed with `patchman -a`) includes the following operations:

- Refresh repositories
- Find host updates
- Process pending reports\*
- Clean reports (removes all but the last three reports from each host)
- Perform some sanity checks on the database and clean unused entries
- Perform reverse DNS checks if enabled per-host

_\* Reports should rarely, if ever, be pending for any significant duration since they are expected to be processed by the `worker` service in an asynchronous manner upon subsmission._

### MySQL/MariaDB

By default, the MariaDB database included in `docker-compose.yml` will use a randomly generated root password.

If you wish to set your own password, configure a `MYSQL_ROOT_PASSWORD` environment variable in `docker-compose.yml`.

## Environment variables

All environment variables without a default are **required**, unless noted otherwise in the variable's description.

The rest are optional and, if unspecified, will use the listed default.

| Name                            | Description                                                                                                                                                                                                                                   | Default   |
|---------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------|
| `ADMIN_EMAIL`                   | Administrator email address.                                                                                                                                                                                                                  |           |
| `ADMIN_USERNAME`                | Administrator username.                                                                                                                                                                                                                       |           |
| `SECRET_KEY`                    | Patchman's secret key. Create a unique string and don't share it with anybody.                                                                                                                                                                |           |
| `TIME_ZONE`                     | Time zone for this installation. All choices can be found [here](http://en.wikipedia.org/wiki/List_of_tz_zones_by_name).<br>At time of writing, Patchman does not properly support this. It will work, but you'll receive warnings to STDOUT. | `Etc/UTC` |
| `LANGUAGE_CODE`                 | Language for this installation. All choices can be found [here](http://www.i18nguy.com/unicode/language-identifiers.html).                                                                                                                    | `en-GB`   |
| `MAX_MIRRORS`                   | Maximum number of mirrors to add or refresh per repo.                                                                                                                                                                                         | `5`       |
| `DAYS_WITHOUT_REPORT`           | Number of days to wait before notifying users that a host has not reported.                                                                                                                                                                   | `14`      |
| `ALLOWED_HOSTS`                 | Hosts allowed to access Patchman.                                                                                                                                                                                                             | `*`       |
| `PATCHMAN_MAINTENANCE_ENABLED`  | Enable/disable the scheduled maintenance action.                                                                                                                                                                                              | `true`    |
| `PATCHMAN_MAINTENANCE_SCHEDULE` | The cron schedule for the maintenance action.<br>See [here](https://pkg.go.dev/github.com/robfig/cron) for the scheduling format (go-cron).                                                                                                   | `@daily`  |

### Database Configuration

By default, Patchman will use the database container included in `docker-compose.yml`.

However, you can use an external/different database if you wish. To do so, configure `.env` with the following settings:

| Name          | Description                                                             | Default                 |
|---------------|-------------------------------------------------------------------------|-------------------------|
| `DB_ENGINE`   | Supported database engines: `mysql`, `oracle`, and `postgresql`.        | `mysql`                 |
| `DB_HOST`     | Database server IP/name.                                                | `mariadb`               |
| `DB_PORT`     | Database port. If empty, will use the default port for selected engine. |                         |
| `DB_NAME`     | Database name.                                                          | `patchman`              |
| `DB_USER`     | Database username.                                                      | `patchman`              |
| `DB_PASSWORD` | Database password.                                                      | `MyPatchmanDBP@ssw0rd!` |


### Advanced Configuration & Debugging

| Name                | Description                                                                                        | Default     |
|---------------------|----------------------------------------------------------------------------------------------------|-------------|
| `DJANGO_DEBUG`      | Enable/disable Django debug.                                                                       | `False`     |
| `DJANGO_LOGLEVEL`   | Set Django's log level.                                                                            | `INFO`      |
| `GUNICORN_WORKERS`  | Numbers of Gunicorn (web server) workers.                                                          | `2`         |
| `CELERY_REDIS_HOST` | Redis server IP/name for Celery worker.<br>Only set this if you want to use your own redis server. | `redis`     |
| `CELERY_REDIS_PORT` | Redis server port for Celery worker.<br>Only set this if you want to use your own redis server.    | `6379`      |
| `CELERY_LOG_LEVEL`  | Set Celery's log level.                                                                            | `INFO`      |
| `MEMCACHED_HOST`    | memcached server IP/name.                                                                          | `memcached` |
| `MEMCACHED_PORT`    | memcached server port.                                                                             | `11211`     |

## Credits

- [Patchman](https://github.com/furlongm/patchman)
- [Original docker-patchman](https://github.com/uqlibrary/docker-patchman) (unmaintained)
