#!/bin/sh

# This script creates/updates a Java keystore
# containing the specified openssl certificate.
#
# It expects a directory containing the fullchain.pem
# and privkey.pem file, creates a keystore named 'keystore.jks'
# in the same directory (protected by a random password), and
# saves the keyring and key password into the "keystorePWD"
# and "keystoreKeyPWD" files.
#
# Both the password files are created with mode 0440, owner
# root:ssl-cert. This is set before writing the passwords, so
# there should be no moment the passwords are visible from the
# outside.
# *DISCLAIMER*: I'm no security expert *AT ALL*!
#


updateKeyring()  {
	if [ "$#" -ne 1 ]
	then
		echo "Usage: $0 <path_to_keystore>" 1>&2
		return 1
	fi

	dstPath="$1"
	if [ ! -d "$dstPath" ]
	then
		echo "$dstPath is not a directory, aborting." 1>&2
		return 1
	fi
	krName=`basename $dstPath`
	echo "Generating Java keyring for $krName into $dstPath"

	cd "$dstPath"

	# Generates a temporary PKCS12 keystore
	tmpPKCSFile=`tempfile -s '.p12' -d .`

	echo "Generating temporary keyring in $tmpPKCSFile"
	pkcsPWD=`makepasswd --minChars 150 --maxChars 250`

	openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out "$tmpPKCSFile" -name "$krName"  -passout "pass:$pkcsPWD"

	# Generate random java keystore and key password
	# Java sucks, so keystore and key password must be the same
	javaKSPWD=`makepasswd --minChars 150 --maxChars 250`

	rm -f keystore.jks
	keytool -importkeystore -deststorepass "$javaKSPWD" -destkeystore keystore.jks -srckeystore "$tmpPKCSFile" -srcstoretype PKCS12 -srcstorepass "$pkcsPWD" -destkeypass "$javaKSPWD" 

	# Cleanup
	rm $tmpPKCSFile
	pkcsPWD=

	# Save key and keystore passwd
	rm -f keystorePWD
	touch keystorePWD
	chmod 440 keystorePWD
	chown root:ssl-cert keystorePWD
	echo "$javaKSPWD" >> keystorePWD
	javaKSPWD=
}

for dir in `find /etc/letsencrypt/live/* -maxdepth 1 -type d`
do
	updateKeyring "$dir"
done
