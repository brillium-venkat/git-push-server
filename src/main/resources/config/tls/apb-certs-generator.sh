#!/bin/sh
# =======================================================================================================================
# Generate root CA cert, server-side cer, and sign server-side cert with root CA cert
# Created by Venkateswar Reddy Melachervu on 13-03-2022.
# Updates:
#      13-03-2022 - Created for root ca, server cert and signing by root ca
#      14-03-2022 - Added pkcs12 keystore creation for signed server cert and private key
#      17-03-2022 - Fixed jhipster integration issues
#
# OpenSSL commands reference - https://www.openssl.org/docs/man3.0/man1/
# =======================================================================================================================

# Required version values
MOBILE_GENERATOR_NAME=AppBrahma
MOBILE_GENERATOR_LINE_PREFIX=\[$MOBILE_GENERATOR_NAME]
GEN_PATH=$2
CNF_PATH=$3
SERVER_KEY="$GEN_PATH/appbrahma-server.key"
SERVER_KEY_PWD="serverkey@appbrahma"
SERVER_CSR="$GEN_PATH/appbrahma-server.csr"
SERVER_CRT="$GEN_PATH/appbrahma-server.crt"
ROOT_CA_SIGNED_SERVER_CRT="$GEN_PATH/appbrahma-root-ca-signed-server.crt"
SERVER_KEYSTORE_NAME="$GEN_PATH/$4"
SERVER_KEYSTORE_PWD="$5"
SERVER_KEYSTORE_TYPE="$6"
SERVER_KEYSTORE_ALIAS=$7
CA_KEY="$GEN_PATH/appbrahma-root-ca.key"
CA_CRT="$GEN_PATH/appbrahma-root-ca-cert.pem"
CA_CNF="$CNF_PATH/appbrahma-root-ca-cert-config.cnf"
CA_KEY_PWD="rootcakey@appbrahma"
SERVER_CNF="$CNF_PATH/appbrahma-server-cert-config.cnf"
SERVER_EXT_CNF="$CNF_PATH/appbrahma-server-san-config.cnf"
OPENSSL_CMD="openssl"
EXIT_INVALD_ARGS_ERROR_CODE=110
EXIT_ROOT_CA_PVT_KEY_GEN_COMMAND_ERROR_CODE=111
EXIT_ROOT_CA_CERT_GEN_COMMAND_ERROR_CODE=112
EXIT_SERVER_PVT_KEY_GEN_COMMAND_ERROR_CODE=113
EXIT_SERVER_CSR_GEN_COMMAND_ERROR_CODE=114
EXIT_SERVER_CERT_GEN_COMMAND_ERROR_CODE=115
EXIT_SERVER_SIGNED_CERT_GEN_COMMAND_ERROR_CODE=116
EXIT_SERVER_CERT_READ_COMMAND_ERROR_CODE=117
EXIT_SERVER_CERT_VERIFY_COMMAND_ERROR_CODE=118
EXIT_SERVER_KEYSTORE_GEN_COMMAND_ERROR_CODE=119

# function to generate key and cert for root ca
generate_root_ca_cert_and_key() {
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Generating self-signed Root CA certificate and private key..."
	#echo "OpenSSL command is..."
	#echo "\t$OPENSSL_CMD req -x509 -sha256 -days 3650 -config $CA_CNF -newkey rsa:4096 -passout pass:$CA_KEY_PWD -keyout $CA_KEY -out $CA_CRT"
	gen_root_ca_cert_private_key=$($OPENSSL_CMD req -x509 -sha256 -days 3650 -newkey rsa:4096 -keyout $CA_KEY -out $CA_CRT -config $CA_CNF -passout pass:$CA_KEY_PWD 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error generating self-signed Root CA certificate and private key!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details:"
		echo "$gen_root_ca_cert_private_key"
		exit $EXIT_ROOT_CA_PVT_KEY_GEN_COMMAND_ERROR_CODE
	else
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Successfully generated self-signed Root CA certificate and private key - $CA_KEY and $CA_CRT"
	fi
	# echo "$MOBILE_GENERATOR_LINE_PREFIX : Verify Root CA certificate..."
	# $OPENSSL_CMD  x509 -noout -text -in $CA_CRT
}

# function to generate key, cert and sign the server certificate
generate_server_certificate_and_sign() {
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Generating certificate signing request for server..."
	#echo "OpenSSL command is..."
	#echo "\t$OPENSSL_CMD req -new -newkey rsa:4096 -keyout $SERVER_KEY -passout pass:$SERVER_KEY_PWD -out $SERVER_CSR -config $SERVER_CNF"
	gen_server_csr=$($OPENSSL_CMD req -new -newkey rsa:4096 -keyout $SERVER_KEY -passout pass:$SERVER_KEY_PWD -out $SERVER_CSR -config $SERVER_CNF 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error generating server signing request!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details:"
		echo "$gen_server_csr"
		exit $EXIT_SERVER_CSR_GEN_COMMAND_ERROR_CODE
	else
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Successfully generated server signing request - $SERVER_CSR."
	fi

	echo "$MOBILE_GENERATOR_LINE_PREFIX : Signing the server CSR with self-signed root CA certificate..."
	#echo "OpenSSL command is..."
	#echo "\t$OPENSSL_CMD x509 -req -CA $CA_CRT -CAkey $CA_KEY -in $SERVER_CSR -out $ROOT_CA_SIGNED_SERVER_CRT -days 365 -CAcreateserial -extfile $SERVER_EXT_CNF"
	gen_root_ca_signed_server_cert=$($OPENSSL_CMD x509 -req -CA $CA_CRT -CAkey $CA_KEY -passin pass:$CA_KEY_PWD -in $SERVER_CSR -out $ROOT_CA_SIGNED_SERVER_CRT -days 365 -CAcreateserial -extfile $SERVER_EXT_CNF 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error generating root CA signed server certificate!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details:"
		echo "$gen_root_ca_signed_server_cert"
		exit $EXIT_SERVER_SIGNED_CERT_GEN_COMMAND_ERROR_CODE
	else
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Successfully signed server CSR with self-signed root CA certificate and generated signed server certificate - $ROOT_CA_SIGNED_SERVER_CRT."
	fi

	echo "$MOBILE_GENERATOR_LINE_PREFIX : Verify signed server certificate against Root CA..."
	#echo "OpenSSL command is..."
	#echo "\t$OPENSSL_CMD verify -CAfile $CA_CRT $ROOT_CA_SIGNED_SERVER_CRT"
	verify_server_cert_against_root_ca=$($OPENSSL_CMD verify -CAfile $CA_CRT $ROOT_CA_SIGNED_SERVER_CRT 2>&1)

	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error verifying server certificate against Root CA!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details:"
		echo "$verify_server_cert_against_root_ca"
		exit $EXIT_SERVER_CERT_VERIFY_COMMAND_ERROR_CODE
	else
		echo "$MOBILE_GENERATOR_LINE_PREFIX : $verify_server_cert_against_root_ca"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Successfully verified server certificate against Root CA - $ROOT_CA_SIGNED_SERVER_CRT."
	fi
}

# function to create pkcs12 keystore package archive of server cert and key - ready for appbrahma web server
create_server_pkcs12_package_keystore() {
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Creating server PKCS12 keystore..."
	#echo "OpenSSL command is..."
	#echo "\t$OPENSSL_CMD $SERVER_KEYSTORE_TYPE -export -out $SERVER_KEYSTORE_NAME -name $SERVER_KEYSTORE_ALIAS -passin pass:$SERVER_KEY_PWD -passout pass:$SERVER_KEYSTORE_PWD -inkey $SERVER_KEY -in $ROOT_CA_SIGNED_SERVER_CRT"
	# name is server alias
	gen_server_pkcs12_keystore=$($OPENSSL_CMD $SERVER_KEYSTORE_TYPE -export -out $SERVER_KEYSTORE_NAME -name $SERVER_KEYSTORE_ALIAS -passin pass:$SERVER_KEY_PWD -password pass:$SERVER_KEYSTORE_PWD -inkey $SERVER_KEY -in $ROOT_CA_SIGNED_SERVER_CRT 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error creating server PKCS12 keystore!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details:"
		echo "$gen_server_pkcs12_keystore"
		exit $EXIT_SERVER_KEYSTORE_GEN_COMMAND_ERROR_CODE
	else
		cp $SERVER_KEYSTORE_NAME .
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Successfully created server PKCS12 keystore - $SERVER_KEYSTORE_NAME"
	fi
}

# main script
#  $1  - working dir of the script
#  $2  - name of the directory for the generated certs
#  $3  - name of the cnf directory under apbCertsRootPath where the openssl cnf files are stored
#  $4  - Server keystore name with extension
#  $5  - Server keystore password
#  $6  - Keystore type to be created
#  $7  - Server alias for keystore - should be same as the (DNS.1) alt_name used in appbrahma-server-san-config.cnf
#      - Also should match/same as the spring boot server network address bound
#echo "$MOBILE_GENERATOR_LINE_PREFIX : Received arguments are..."
#echo "\tScript working directory: $1"
#echo "\tName of the directory for generated certs: $2"
#echo "\tName of the directory where openSSL cnf files are available: $3"
#echo "\tServer keystore name: $4"
#echo "\tServer keystore password: $5"
#echo "\tKeystore type to be created: $6"
#echo "\tServer keystore alias: $7"

ARGS_COUNT=7;
if [ $# -ne $ARGS_COUNT ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Invalid number of arguments!"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Expected 7 arguments but received $#. Please retry with valid number of arguments."
    exit $EXIT_INVALD_ARGS_ERROR_CODE
fi
cd "$1"
mkdir -p $2
generate_root_ca_cert_and_key
generate_server_certificate_and_sign
create_server_pkcs12_package_keystore
