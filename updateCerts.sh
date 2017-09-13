#!/bin/sh

#
# This script creates key+certificate PEM files
# for each LetsEncrypt certificate that you have.
#
# This can be useful for servers that can only
# serve from a single PEM file, e.g. lighttpd
#
for dir in `find /etc/letsencrypt/live/* -maxdepth 1 -type d`
do
	echo "Merging certificates in $dir"
	cat $dir/privkey.pem $dir/fullchain.pem > $dir/keypluschain.pem
	chmod o-r $dir/keypluschain.pem
        chgrp ssl-cert $dir/keypluschain.pem
done
