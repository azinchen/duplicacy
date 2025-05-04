# Duplicacy

[![Docker pulls][dockerhub-pulls]][dockerhub-link]  
[![Docker image size][dockerhub-size]][dockerhub-link]  
[![GitHub release date][github-releasedate]][github-link]  
[![GitHub build][github-build]][github-link]  
[![GitHub last commit][github-lastcommit]][github-link]

The Docker image `azinchen/duplicacy` is designed for automated backups by leveraging [Duplicacy][duplicacy-home]. As such, it supports:

- A wide range of storage backends (S3, Backblaze B2, Hubic, Dropbox, SFTP, and more)
- Client-side encryption
- Deduplication
- Multi-versioning
- And all the other features available in Duplicacy

This image uses the [Duplicacy Command Line version][duplicacy-github] `3.2.5`.

## Supported Architectures

The image is compatible with several architectures including `amd64`, `x86`, `arm/v6`, `arm/v7`, and `arm64`.

## Running a Duplicacy Container

To start a standalone Duplicacy instance in Docker, you can run:

```bash
docker run \
  -v path_to_data:/data \
  -e BACKUP_CRON="0 1 * * *" \
  -e SNAPSHOT_ID="id" \
  -e STORAGE_URL="url" \
  azinchen/duplicacy
```

## Configuring Environment Variables

The container is configured at runtime using environment variables. Below are the available settings:

### Backup Settings

- **`BACKUP_CRON`**: Specifies the schedule (in crontab format) for running the `duplicacy backup` command. Without this variable, the backup command will not execute.
- **`BACKUP_OPTIONS`**: Defines additional options for the `duplicacy backup` command. For details, see the [duplicacy backup documentation][duplicacy-backup]. Defaults are not applied.
- **`BACKUP_END_CRON`**: Sets a schedule (in crontab format) for forcefully terminating the duplicacy backup process. If not set, no force kill is performed.

### Prune Settings

- **`PRUNE_CRON`**: Specifies the schedule (in crontab format) for executing the `duplicacy prune` command. This command runs only if the variable is set.
- **`PRUNE_OPTIONS`**: Provides extra options for the `duplicacy prune` command. Refer to the [duplicacy prune documentation][duplicacy-prune] for more details. Defaults are not applied.
- **`PRUNE_KEEP_POLICIES`**: Sets the retention policies for pruning. Multiple policies can be specified by separating them with semicolons. For more details, see [duplicacy prune documentation][duplicacy-prune].

### General Settings

- **`GLOBAL_OPTIONS`**: Specifies global options for any `duplicacy` command. Check out the [global options details][duplicacy-global-options] for more information. No defaults are set.
- **`RUN_JOB_IMMEDIATELY`**: When set to `yes`, the container will execute the `duplicacy backup` and/or `duplicacy prune` commands immediately upon startup. By default, jobs do not run immediately.
- **`SNAPSHOT_ID`**: Provides the snapshot identifier as described in the `duplicacy init` command documentation [here][duplicacy-init].
- **`STORAGE_URL`**: Indicates the storage location URL, as required by the `duplicacy init` command [documentation][duplicacy-init]. Duplicacy supports various storage providers; see the [supported storage backends][duplicacy-storage] for details. Login credentials for the storage should be set via environment variables as outlined in the [credentials documentation][duplicacy-variables].
- **`JOB_RANDOM_DELAY`**: Sets a maximum delay (in seconds) before starting a job. By default, jobs start without delay.
- **`FILTER_PATTERNS`**: Defines include/exclude patterns for filtering. Multiple patterns can be separated by semicolons. For more details, refer to the [filter documentation][duplicacy-filters].
- **`DUPLICACY_PASSWORD`**: When provided, enables encryption for storage by setting the encryption password. See the `duplicacy init` command details [here][duplicacy-init]. Encryption is off by default.

### Email Settings

- **`EMAIL_HOSTNAME_ALIAS`**: Overrides the container's hostname in email reports.
- **`EMAIL_FROM`**: Sets the sender's email address.
- **`EMAIL_FROM_NAME`**: Sets the sender's name.
- **`EMAIL_TO`**: Specifies the recipient's email address.
- **`EMAIL_USE_TLS`**: Enables TLS encryption for the SMTP session.
- **`EMAIL_SMTP_SERVER`**: Specifies the SMTP server address.
- **`EMAIL_SMTP_SERVER_PORT`**: Defines the port for the SMTP server.
- **`EMAIL_SMTP_LOGIN`**: Provides the SMTP server login.
- **`EMAIL_SMTP_PASSWORD`**: Provides the SMTP server password.
- **`EMAIL_LOG_LINES_IN_BODY`**: Determines the number of lines from the start and end of the log to include in the email report. The default is `10`.
- **`SEND_REPORT_LEVEL`**: Sets the minimum level of logs to trigger email reports. Options are `all` or `error` (default is `all`).

### Time Zone Settings

- **`TZ`**: Sets the container's time zone. Acceptable values can be found [here][tz-database]. The default is `UTC`.

## Disclaimer

This project utilizes the [Duplicacy Command Line version][duplicacy-github], which is free for personal use. Commercial use requires a [license purchase][duplicacy-purchase]. For complete licensing terms, see [here][duplicacy-license].

## Reporting Issues

If you encounter any problems or have questions about this image, please open a [GitHub issue][github-issues] or contact via [email][email-link].

---

[dockerhub-pulls]: https://img.shields.io/docker/pulls/azinchen/duplicacy  
[dockerhub-link]: https://hub.docker.com/repository/docker/azinchen/duplicacy  
[dockerhub-size]: https://img.shields.io/docker/image-size/azinchen/duplicacy/latest  
[github-lastcommit]: https://img.shields.io/github/last-commit/azinchen/duplicacy  
[github-link]: https://github.com/azinchen/duplicacy  
[github-issues]: https://github.com/azinchen/duplicacy/issues  
[github-build]: https://img.shields.io/github/actions/workflow/status/azinchen/nordvpn/deploy.yml?branch=master  
[github-releasedate]: https://img.shields.io/github/release-date/azinchen/nordvpn  
[duplicacy-home]: https://duplicacy.com  
[duplicacy-github]: https://github.com/gilbertchen/duplicacy  
[duplicacy-license]: https://github.com/gilbertchen/duplicacy/blob/master/LICENSE.md  
[duplicacy-purchase]: https://duplicacy.com/buy.html  
[duplicacy-storage]: https://forum.duplicacy.com/t/supported-storage-backends/1107  
[duplicacy-global-options]: https://forum.duplicacy.com/t/global-options-details/1087  
[duplicacy-init]: https://forum.duplicacy.com/t/init-command-details/1090  
[duplicacy-backup]: https://forum.duplicacy.com/t/backup-command-details/1077  
[duplicacy-prune]: https://forum.duplicacy.com/t/prune-command-details/1005  
[duplicacy-filters]: https://forum.duplicacy.com/t/filters-include-exclude-patterns/1089  
[duplicacy-variables]: https://forum.duplicacy.com/t/passwords-credentials-and-environment-variables/1094  
[tz-database]: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones  
[email-link]: mailto:alexander@zinchenko.com