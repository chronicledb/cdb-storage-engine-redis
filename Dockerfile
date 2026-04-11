FROM redis:7-alpine

COPY redis.conf /usr/local/etc/redis/redis.conf
COPY seed.sh /seed.sh
RUN chmod +x /seed.sh

# Startup: launch Redis in background, run seed, then keep Redis in foreground
CMD sh -c "redis-server /usr/local/etc/redis/redis.conf &sleep 2 && /seed.sh && wait"