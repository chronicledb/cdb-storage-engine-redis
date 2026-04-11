#!/bin/sh
set -e

echo "Seeding Redis..."

redis-cli HSET metadata seq_num 0

echo "Seeding complete."