#!/bin/bash
#
# PostgreSQL Backup Script
# This script is based on the "Automated Backup on Linux"-wiki page from postgresql (https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux).
#
# With the script, it is possible to do daily backups and to define which daily, weekly, backups should be kept in a folder.
# One monthly backup is also kept.
# 
# Add the following line as cron job (asuming to use the definded BACKUP_DIR as folder).
# 0 1 * * * /srv/backups/postgres/backupDatabase.sh >> /srv/backups/postgres/backupDatabase.log 2>&1
#
##
#
##############################
#### SETTINGS FOR BACKUPS ####
##############################

# Database name
DATABASE=yourDatabaseName

# Username to connect to database as.
USERNAME=yourUserName

# This dir will be created if it doesn't exist.  This must be writable by the user the script is running as.
BACKUP_DIR=/srv/backups/postgres/

# Number of parallel dumping jobs. pg_dump will dump tables simultaneously
N_JOBS=10

# Number of days to keep daily backups
DAYS_TO_KEEP=7

# Which day to take the weekly backup from (1-7 = Monday-Sunday)
DAY_OF_WEEK_TO_KEEP=5

# How many weeks to keep weekly backups
WEEKS_TO_KEEP=3

#########################
#### BACKUP FUNCTION ####
#########################

function perform_backups()
{
        # create final backup dir
        # has current date as name + suffix (=parameter)

        SUFFIX=$1
        FINAL_BACKUP_DIR=$BACKUP_DIR$DATABASE"`date +\%Y-\%m-\%d`$SUFFIX"

        # not needed because pg_dump will create the folder by itself
        #if ! mkdir -p $FINAL_BACKUP_DIR; then
        #       echo "Cannot create backup directory in $FINAL_BACKUP_DIR."
        #       exit 1;
        #fi;

        # run pg_dump
        echo "Making backup for $DATABASE in $FINAL_BACKUP_DIR."
        echo "Start at: $(date)"
        if ! pg_dump -j "$N_JOBS" -Fd -U "$USERNAME" -f $FINAL_BACKUP_DIR".in_progress" "$DATABASE"; then
                echo "[!!ERROR!!] Failed to produce backup database $DATABASE in $FINAL_BACKUP_DIR."
        else
                mv $FINAL_BACKUP_DIR".in_progress" $FINAL_BACKUP_DIR
                echo "Backup done for $DATABASE."
                echo "End at: $(date)"
        fi
        echo -e "\nDatabase backup complete!"
}

###########################
#### START THE BACKUPS ####
###########################

# MONTHLY BACKUPS

DAY_OF_MONTH=`date +%d`

if [ $DAY_OF_MONTH -eq 1 ];
then
        # Delete all expired monthly directories
        find $BACKUP_DIR -maxdepth 1 -name "*-monthly" -exec rm -rf '{}' ';'
        echo -e "\nStart monthly backup."
        perform_backups "-monthly"

        exit 0;
fi

# WEEKLY BACKUPS

DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
EXPIRED_DAYS=`expr $((($WEEKS_TO_KEEP * 7) + 1))`

if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ];
then
        # Delete all expired weekly directories
        find $BACKUP_DIR -maxdepth 1 -mtime +$EXPIRED_DAYS -name "*-weekly" -exec rm -rf '{}' ';'
        echo -e "\nStart weekly backup."
        perform_backups "-weekly"

        exit 0;
fi

# DAILY BACKUPS

# Delete daily backups xx days old or more
find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*-daily" -exec rm -rf '{}' ';'
echo -e "\nStart daily backup."
perform_backups "-daily"

# eof