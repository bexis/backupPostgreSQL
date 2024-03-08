PostgreSQL Backup Script
# This script is based on the "Automated Backup on Linux"-wiki page from postgresql (https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux).
#
#
#
# With the script, it is possible to do daily backups and to define which daily, weekly, backups should be kept in a folder.
# One monthly backup is also kept.
# 
# Add the following line as cron job (asuming to use the definded BACKUP_DIR as folder).
# 0 1 * * * /srv/backups/postgres/backupDatabase.sh >> /srv/backups/postgres/backupDatabase.log 2>&1
#
