#!/usr/bin/env bash
set -euo pipefail

# โหลดตัวแปรจาก .env (ข้ามบรรทัดที่เป็นคอมเมนต์)
export $(grep -v '^#' .env | xargs) || true

DB_HOST=${PMA_HOST:-mariadb}
DB_PORT=${PMA_DB_PORT:-3306}
ROOT_PASS=${MARIADB_ROOT_PASSWORD:-adminpass}
CTRL_USER=${PMA_CONTROLUSER:-phpmyadmin}
CTRL_PASS=${PMA_CONTROLPASS:-phpmyadmin}

echo "[1/2] Create DB/user/grants..."
docker exec -i mariadb mariadb -uroot -p"$ROOT_PASS" <<SQL
CREATE DATABASE IF NOT EXISTS \`phpmyadmin\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${CTRL_USER}'@'%' IDENTIFIED BY '${CTRL_PASS}';
GRANT SELECT, INSERT, UPDATE, DELETE,
      CREATE, ALTER, INDEX, DROP,
      CREATE VIEW, SHOW VIEW, TRIGGER, EVENT
  ON \`phpmyadmin\`.* TO '${CTRL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
echo "    ✓ DB/user/grants ensured"

echo "[2/2] Verify control user can connect..."
docker exec -i mariadb mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$CTRL_USER" -p"$CTRL_PASS" -e "SELECT 1;" phpmyadmin >/dev/null
echo "    ✓ Control user OK"

echo "Done."
