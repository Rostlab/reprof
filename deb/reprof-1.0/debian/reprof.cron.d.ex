#
# Regular cron jobs for the reprof package
#
0 4	* * *	root	[ -x /usr/bin/reprof_maintenance ] && /usr/bin/reprof_maintenance
