# duplicacy

[![Docker Pulls][dockerhub-pulls]][dockerhub-link]
[![Docker Build][dockerhub-build]][dockerhub-link]
[![Docker Passing][dockerhub-passing]][dockerhub-link]
[![GitHub Last Commit][github-lastcommit]][github-link]

`azinchen/duplicacy` is a Docker image to easily perform automated backups. It uses [Duplicacy][duplicacy-home] under the hood, and therefore supports:

- Multiple storage backends: S3, Backblaze B2, Hubic, Dropbox, SFTP...
- Client-side encryption
- Deduplication
- Multi-versioning
- ... and more generally, all the features that duplicacy has.

## Supported Architectures

The image supports multiple architectures such as `amd64`, `arm` and `arm64`.

The new features are introduced to 'edge' version, but this version might contain issues. Avoid to use 'edge' image in production environment.

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64, armhf, aarch64 | latest |
| x86-64, armhf, aarch64 | edge |

## Starting an Duplicacy instance

You can run the following command to stand up a standalone instance of Duplicacy on Docker:

```
docker run \
  -v path_to_data:/data \
  -e BACKUP_CRON="0 1 * * *" \
  -e SNAPSHOT_ID="id" \
  -e STORAGE_URL="url" \
  azinchen/duplicacy
```

## Environment variables

Container images are configured using environment variables passed at runtime.

 * `BACKUP_CRON`
 * `PRUNE_CRON`
 * `CHUNK_SIZE`
 * `MAX_CHUNK_SIZE`
 * `MIN_CHUNK_SIZE`
 * `GLOBAL_OPTIONS`
 * `BACKUP_OPTIONS`
 * `PRUNE_OPTIONS`
 * `RUN_JOB_IMMEDIATELY`
 * `SNAPSHOT_ID`
 * `STORAGE_URL`
 * `JOB_RANDOM_DELAY`
 * `PRUNE_KEEP_POLICIES`
 * `FILTER_PATTERNS`
 * `DUPLICACY_PASSWORD`
 * `EMAIL_FROM`
 * `EMAIL_FROM_NAME`
 * `EMAIL_TO`
 * `EMAIL_USE_TLS`
 * `EMAIL_SMTP_SERVER`
 * `EMAIL_SMTP_SERVER_PORT`
 * `EMAIL_SMTP_LOGIN`
 * `EMAIL_SMTP_PASSWORD`
 * `EMAIL_LOG_LINES_IN_BODY`

## Disclaimer

This project uses [Duplicacy][duplicacy-home], which is free for personal use but requires [purchasing a licence][duplicacy-purchase] for non-trial commercial use. See the detailed terms [here]([duplicacy-license].

# Issues

If you have any problems with or questions about this image, please contact me through a [GitHub issue][github-issues] or [email][email-link].

[dockerhub-pulls]: https://img.shields.io/docker/pulls/azinchen/duplicacy
[dockerhub-build]: https://img.shields.io/docker/cloud/automated/azinchen/duplicacy
[dockerhub-passing]: https://img.shields.io/docker/cloud/build/azinchen/duplicacy
[dockerhub-link]: https://hub.docker.com/repository/docker/azinchen/duplicacy
[github-lastcommit]: https://img.shields.io/github/last-commit/azinchen/duplicacy
[github-link]: https://github.com/azinchen/duplicacy
[github-issues]: https://github.com/azinchen/duplicacy/issues
[duplicacy-home]: https://duplicacy.com
[duplicacy-license]: https://github.com/gilbertchen/duplicacy/blob/master/LICENSE.md)
[duplicacy-purchase]: https://duplicacy.com/buy.html
[duplicacy-forum]: https://forum.duplicacy.com
[duplicacy-storage]: https://forum.duplicacy.com/t/supported-storage-backends/1107
[duplicacy-global-options]: https://forum.duplicacy.com/t/global-options-details/1087
[duplicacy-init]: https://forum.duplicacy.com/t/init-command-details/1090
[duplicacy-backup]: https://forum.duplicacy.com/t/backup-command-details/1077
[duplicacy-prune]: https://forum.duplicacy.com/t/prune-command-details/1005
[duplicacy-filters]: https://forum.duplicacy.com/t/filters-include-exclude-patterns/1089
[duplicacy-variables]: https://forum.duplicacy.com/t/passwords-credentials-and-environment-variables/1094
[email-link]: mailto:alexander@zinchenko.com