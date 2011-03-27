#!/bin/sh

MIRRORDIR=/home/peter/data/pdb                 # your top level rsync directory
LOGFILE=/home/peter/data/pdb.log               # file for storing logs
RSYNC=/usr/bin/rsync                             # location of local rsync

SERVER=rsync.wwpdb.org::ftp                                   # RCSB PDB server name
PORT=33444                                                    # port RCSB PDB server is using

${RSYNC} -rlpt -v -z --delete --port=$PORT ${SERVER}/data/structures/divided/pdb/ $MIRRORDIR
