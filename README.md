# cdb-storage-engines

Builds and publishes the storage engine images used by ChronicleDB's tx-manager instances. Currently provides a Redis-based storage engine image, pre-seeded with the metadata this service expects on startup.

## What this builds

A Docker image (`redis:7-alpine` base) that:

1. Runs Redis with a minimal config (`redis.conf`) binding to all interfaces on the default port `6379`.
2. On startup, seeds the `metadata` hash with an initial `seq_num` of `0` — the sequence number the tx-manager's `StorageEngine.getSeqNum()` reads and that every `commitTransaction` call is validated against.

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the image: copies in `redis.conf` and `seed.sh`, and on container start launches `redis-server` in the background, waits for it to come up, runs the seed script, then keeps Redis running in the foreground. |
| `redis.conf` | Minimal Redis server config — binds `0.0.0.0:6379`. |
| `seed.sh` | Seeds the `metadata` hash's `seq_num` field to `0` via `redis-cli`. Runs once on container startup. |
| `deploy.sh` | Builds the image locally, authenticates with ECR, tags, and pushes it to `cdb-storage-engines` in the account's ECR registry. |

## Building and deploying

```bash
./deploy.sh
```

This will:
1. Build the image locally as `cdb-storage-engines:redis`.
2. Authenticate Docker with your account's ECR registry (via `aws sts get-caller-identity` + `aws configure get region`).
3. Tag and push the image to `<account-id>.dkr.ecr.<region>.amazonaws.com/cdb-storage-engines:redis`.

Requires AWS credentials configured locally with ECR push permissions, and Docker running.

## Running locally

```bash
docker build -t cdb-storage-engines:redis .
docker run -p 6379:6379 cdb-storage-engines:redis
```

Redis will be available on `localhost:6379`, pre-seeded with `metadata.seq_num = 0`.

## Notes

- **`ENGINE` is currently hardcoded to `redis`** in `deploy.sh` — the image tag (`cdb-storage-engines:$ENGINE`) suggests this repo is meant to support multiple storage engine backends in the future, with `redis` being the first.
- **Seeding is not idempotent-safe for existing data** — `seed.sh` unconditionally sets `seq_num` to `0` on every container start. This is fine for a fresh Redis instance but would reset `seq_num` on restart if the container doesn't have a persistent volume, or would silently overwrite a genuinely nonzero counter if one exists. Worth confirming whether Redis persistence (e.g. an AOF/RDB volume mount) is handled outside this repo, since `redis.conf` here doesn't configure any persistence directives.
- **No TLS/auth configured** on the Redis server itself (`redis.conf` has no `requirepass` or TLS settings) — matches the `usePlaintext()` TODO noted in the tx-manager service; both would need addressing for production.