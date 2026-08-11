# hl-component-s3-deployer

Component to deploy files from a zip file to an S3 bucket with optional file filtering and per-file metadata/headers.

## Deployment metadata

`deployment_metadata` is a list of rules matched with `fnmatch` against zip entry names. Matching rules merge in order; later rules override earlier keys. The built-in `deployment` user-metadata key (source zip key) is always set last.

```yaml
deployment_metadata:
  - file: index.html
    headers:
      CacheControl: "no-cache"
  - file: assets/*
    headers:
      CacheControl: "public, max-age=31536000, immutable"
  - file: "*"
    metadata:
      env: prod
```

- `file`: fnmatch pattern against the zip entry name
- `metadata`: optional dict → S3 user metadata (`x-amz-meta-*`)
- `headers`: optional dict → top-level upload `ExtraArgs` (`CacheControl`, `ContentDisposition`, `ContentEncoding`, `ContentLanguage`, `Expires`, `WebsiteRedirectLocation`, `ContentType`, etc.)

Legacy flat-dict configs are still supported and treated as a single `*` rule with that dict as `metadata`.

## Deployment filter

```yaml
deployment_filter:
  - file: index.html
    placeholder: PLACEHOLDER
    value: https://${APIEndpoint}.example.com
```
