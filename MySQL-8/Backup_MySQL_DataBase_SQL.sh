 # docker exec -it MySQL /bin/bash

# mysqldump -h127.0.0.1 -P3306 -uroot -pP@88W0rd --default-character-set=utf8mb4 --hex-blob --master-data=2 --single-transaction --opt --set-gtid-purged=OFF --skip-tz-utc --events --triggers --routines lit_inf_sys_db  > /var/lib/mysql/$(date +%Y%m%d%H%M%S)_lit_inf_sys_db.sql
