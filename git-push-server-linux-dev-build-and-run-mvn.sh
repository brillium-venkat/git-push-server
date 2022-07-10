#!/bin/bash
# ====================================================================================================================================
# git-push-server-linux-dev-build-and-run-mvn.sh
# AppBrahma back-end server build and run script
# Created by Venkateswar Reddy Melachervu on 15-03-2022.
# Updates:
#   16-03-2022 - Updated for mysql docker terminal spawning and running
#   20-06-2022 - Update for AppBrahma generator sync and https support optimization
#   03-07-2022 - Updated for MacOS terminal spwans and colored font
#   09-07-2022 - Updated for unified colors and pre-req checks across OSes
#
# (C) Brillium Technologies 2011-2022. All rights reserved.
# ====================================================================================================================================

export RED=$(tput setaf 9)
export GREEN=$(tput setaf 10)
export YELLOW=$(tput setaf 11)
export LIME_YELLOW=$(tput setaf 190)
export ORANGE=$(tput setaf 172)
export POWDER_BLUE=$(tput setaf 153)
export MAGENTA=$(tput setaf 5)
export PURPLE=$(tput setaf 141)
export CYAN=$(tput setaf 6)
export BOLD=$(tput bold)
export NT=$(tput sgr0)

# color aliases
export ERROR=$RED
export WARNING=$YELLOW
export ATTENTION=$WHITE
export SUCCESS=$GREEN
export INFO=$WHITE
export ACCENT=$CYAN

# Required version values
NODE_MAJOR_VERSION=16
NPM_MAJOR_VERSION=6
JAVA_MIN_MAJOR_VERSION=11
JAVA_MIN_MINOR_VERSION=0

# error and exit codes
EXIT_WRONG_PARAMS_ERROR_CODE=100
EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE=101
EXIT_GNOME_TERMINAL_NOT_INSTALLED_ERROR_CODE=102
EXIT_NPM_INSTALL_ERROR_CODE=103
EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE=104
EXIT_MVNW_CHMOD_ERROR_CODE=105
EXIT_DELETE_TARGET_FOLDER_ERROR_CODE=106
EXIT_MVNW_CLEAN_ERROR_CODE=107
EXIT_SERVER_KEYSTORE_GEN_ERROR_CODE=108
EXIT_SERVER_KEYSTORE_COPY_ERROR_CODE=109
EXIT_GNOME_TERM_WEBPACK_RUN_ERROR_CODE=110
EXIT_MVNW_RUN_JAVA_SERVER_ERROR_CODE=111
EXIT_GNOME_TERM_DOCKER_RUN_ERROR_CODE=112
EXIT_PRE_REQ_CHECK_FAILURE_CODE=113
EXIT_LINUX_VERSION_CHECK_COMMAND_ERROR_CODE=114
EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=115
EXIT_DOCKER_COMPOSE_NOT_INSTALLED_ERROR_CODE=116
EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=117
EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=118
EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=119
EXIT_SPAWN_TERM_JAVA_SPRING_BOOT_SERVER_ERROR_CODE=120

# arguments
# $1 - build/rebuild - rebuild cleans the target forcibly
# $2 - http/https
# $3 - webpack for hot module reload

# args
build_rebuild=$1
server_rest_api_mode=$2
webpack=$3
expected_arg_count=3


#constant strings
export DOCKER_DB_TERMINAL_NAME="AppBrahma Docker DB Terminal - git-push-server"
export HMR_WEBPACK_TERMINAL_NAME="AppBrahma Webpack Live HMR Terminal - git-push-server"
export SERVER_APP_NAME="Git Push Server"
export GENERATOR_NAME="AppBrahma"
export GENERATOR_LINE_PREFIX=\[$GENERATOR_NAME]
BUILD="build"
REBUILD="rebuild"
HTTP="http"
HTTPS="https"
HMR="hmr"
NOHMR="no-hmr"
CONFIGURE_NEW_KEYSTORE="configure-new-ks"
USE_CONFIGURED_KEYSTORE="use-configured-ks"
LOCALHOST="localhost"

# function for pre-reqs check
appbrahma_pre_reqs_check() {
    # OS version validation
	LINUX_VERSION_CMD=$(lsb_release -a 2>&1)
	if [ $? -gt 0 ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : Error in getting linux version. The error is:${NT}"
		echo "$LINUX_VERSION_CMD"
		echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running this script after fixing above errors.${NT}"
		return_code=$EXIT_LINUX_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	fi
	echo "$GENERATOR_LINE_PREFIX : Your linux distribution name and version are:"
	echo "$LINUX_VERSION_CMD"

    # Node install check
	node_command=$(node --version 2>&1)
	if [ $? -gt 0 ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : Nodejs is not installed or NOT in PATH!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS version of nodejs major release $NODE_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
		return_code=$EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	fi

    # Node version check
	node_version=$(node --version | awk -F. '{ print $1 }' 2>&1)
	# remove the first character
	node_command=${node_version#?}
	if [ $node_command -lt $NODE_MAJOR_VERSION ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : You are running non-supported nodejs major version $(node --version | awk -F. '{ print $1 }')!${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Supported major version is $NODE_MAJOR_VERSION${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS NodeJS version of major release $NODE_MAJOR_VERSION and retry running this script.${NT}"
		return_code=$EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum Nodejs version requirement met - you are running $(node --version). Moving ahead with other checks..."
	fi

    # npm install check
	npm_command=$(npm --version 2>&1)
	if [ $? -gt 0 ]; then
		    echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : npm (Node Package Manager) is not installed or NOT in PATH!${NT}"
            echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
		    echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Please install a stable and LTS version of npm major release $NPM_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
		    return_code=$EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
		    return
	fi

	# NPM version check
	npm_version=$(npm --version | awk -F. '{ print $1 }' 2>&1)
	if [ $npm_version -lt $NPM_MAJOR_VERSION ]; then
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : You are running unsupported npm major version $(npm --version | awk -F. '{ print $1 }')!${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Supported major version is $NPM_MAJOR_VERSION${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Aborting the build process."
        echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Please install a stable and LTS npm version of major release $NPM_MAJOR_VERSION and retry running this script.${NT}"
		return_code=$EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum npm version requirement met - you are running $(npm --version). Moving ahead with other checks..."
	fi

    # java install check
	java_command=$(java -version 2>&1)
	if [ $? -gt 0 ]; then
	    echo "${RED}$GENERATOR_LINE_PREFIX : Java runtime is not installed or NOT in PATH!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
	    echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS Java JDK version of major release $JAVA_MIN_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
	    return_code=$EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	fi

	# java runtime version check
	java_version_first_part=$(java -version 2>&1 | awk 'NR==1 {print $3}'| awk -F. '{print $1}')
	java_version_first_part=$(echo $java_version_first_part | sed "s/\"//g")
	java_version_second_part=$(java -version 2>&1 | awk 'NR==1 {print $3}'| awk -F. '{print $2}')
	if [ $java_version_first_part -lt $JAVA_MIN_MAJOR_VERSION -a $java_version_second_part -lt $JAVA_MIN_MAJOR_VERSION ]; then
	    echo "${RED}$GENERATOR_LINE_PREFIX : You are running unsupported Java runtime version $java_version_second_part!${NT}"
	    echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the build process."
        echo "${RED}$GENERATOR_LINE_PREFIX : Supported major version is $JAVA_MIN_MAJOR_VERSION${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS version of Java/JDK major release $JAVA_MIN_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
	    return_code=$EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum Java runtime version requirement met - you are running $(java -version 2>&1 | awk 'NR==1 {print $3}'). Moving ahead with other checks..."
	fi

	# jdk install check
	jdk_command=$(javac -help 2>&1)
	if [ $? -gt 0 ]; then
	    echo "${RED}$GENERATOR_LINE_PREFIX : Java JDK is not installed or NOT in PATH!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the build process."
	    echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS Java JDK version of major release $JAVA_MIN_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
	    return_code=$EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	else
		echo "$GENERATOR_LINE_PREFIX : Java JDK found in the path. Moving ahead with other checks..."
	fi

    # jdk version check
	jdk_version=$(javac --version | awk -F. '{ print $1 }' | awk '{print $2}' 2>&1)
    if [ $jdk_version -lt $JAVA_MIN_MAJOR_VERSION ]; then
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : You are running unsupported JDK major version $(javac --version | awk -F. '{ print $1 }')!${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Supported major version is $JAVA_MIN_MAJOR_VERSION${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Aborting the build process."
        echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Please install a stable and LTS npm version of major release $NPM_MAJOR_VERSION and retry running this script.${NT}"
		return_code=$EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum JDK version requirement met - you are running $(javac --version | awk '{ print $2 }'). Moving ahead with other checks..."
	fi

    # docker installation check - conditional for non-h2 dbs
    docker_install_check=$(docker -v 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Docker engine/desktop is NOT installed or NOT in the path! This is needed for running database in the container.${NT}
        echo "${RED}$GENERATOR_LINE_PREFIX : Please install docker compose and retry running this script.${NT}"
        exit $EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE
    else
        echo "$GENERATOR_LINE_PREFIX : Docker engine/desktop needed for running database container is installed. Moving ahead with other checks..."
    fi

    # docker-compose install check - conditional for non-h2 dbs
    docker_install_check=$(docker-compose version 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Docker-compose is not installed. This is needed for running database in the container.
        echo "Please install docker compose and retry running this script.${NT}"
        exit $EXIT_DOCKER_COMPOSE_NOT_INSTALLED_ERROR_CODE
    else
        echo "$GENERATOR_LINE_PREFIX : Docker-compose needed for running database container is installed. Moving ahead with other checks..."
    fi
}

clear
echo "=========================================================================================================================================="
echo "                  Welcome to ${GREEN}${BOLD}$SERVER_APP_NAME build and run script generated by ${GREEN}$GENERATOR_NAME - the baap of apps${NT}"
echo "Sit back, relax, and sip a cuppa coffee while the dependencies are download, project is built, and server is run."
echo "${YELLOW}Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution$NT"
echo "-Team AppBrahma"
echo "=========================================================================================================================================="
echo "${BOLD}${YELLOW}$GENERATOR_LINE_PREFIX : You typed - \"$0 $*${NT}\""

# arguments
# $1 - build/rebuild - rebuild cleans the target directory, node_modules etc. forcibly
# $2 - http/https - back-end server protocol support - http or https
# $3 - hmr or nohmr - live hot-reload of front-end code changes or no hot module reload

# args check
if [ "$#" -ne $expected_arg_count ]; then
	echo "${BOLD}${ERROR}$GENERATOR_LINE_PREFIX : In-sufficient or invalid arguments supplied - needed $expected_arg_count but "$#" were supplied!${NT}"
	echo "${BOLD}Usage:${NT}"
	echo "  ${BOLD}${GREEN}$0 <build-action> <server-protocol> <front-end-hot-reload-action>${NT}"
	echo "${BOLD}Arguments:${NT}"
	echo "  ${BOLD}${GREEN}build-action${NT}:"
	echo "      - Build or rebuild. Rebuild cleans the target forcibly."
	echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}build${NT} or ${BOLD}${GREEN}rebuild${NT}."
	echo "  ${BOLD}${GREEN}server-protocol${NT}:"
	echo "      - Backend server protocol. HTTP is NOT auto-redirected to HTTPS."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}http${NT} or ${BOLD}${GREEN}https${NT}."
    echo "      - HTTP is NOT auto-redirected to HTTPS."
    echo "  ${BOLD}${GREEN}front-end-hot-reload-action${NT}:"
	echo "      - For hot live reloading of front-end code changes using webpack."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}hmr${NT} or ${BOLD}${GREEN}no-hmr${NT}."
    echo "      - ${BOLD}${GREEN}hmr${NT} spawns a new terminal to run webpack server."
    echo "      - ${BOLD}${GREEN}no-hmr${NT} does not spawn a terminal and server does not reflect any live front-end code changes while running - requires restart of the server."
	exit $EXIT_WRONG_PARAMS_ERROR_CODE
fi

# args validation
echo "$GENERATOR_LINE_PREFIX : Validating the values of arguments..."
if [[ $build_rebuild != $BUILD && $build_rebuild != $REBUILD ]]; then
    echo "${BOLD}${ERROR}Invalid value - \"$build_rebuild\" - supplied to the first argument!${NT}"
	echo "${BOLD}Usage:${NT}"
	echo "  ${BOLD}${GREEN}$0 <build-action> <server-protocol> <front-end-hot-reload-action>${NT}"
	echo "${BOLD}Arguments:${NT}"
	echo "  ${BOLD}${GREEN}build-action${NT}:"
	echo "      - Build or rebuild. Rebuild cleans the target forcibly."
	echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}build${NT} or ${BOLD}${GREEN}rebuild${NT}."
	echo "  ${BOLD}${GREEN}server-protocol${NT}:"
	echo "      - Backend server protocol. HTTP is NOT auto-redirected to HTTPS."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}http${NT} or ${BOLD}${GREEN}https${NT}."
    echo "      - HTTP is NOT auto-redirected to HTTPS."
    echo "  ${BOLD}${GREEN}front-end-hot-reload-action${NT}:"
	echo "      - For hot live reloading of front-end code changes using webpack."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}hmr${NT} or ${BOLD}${GREEN}no-hmr${NT}."
    echo "      - ${BOLD}${GREEN}hmr${NT} spawns a new terminal to run webpack server."
    echo "      - ${BOLD}${GREEN}no-hmr${NT} does not spawn a terminal and server does not reflect any live front-end code changes while running - requires restart of the server."
	exit $EXIT_WRONG_PARAMS_ERROR_CODE
fi

if [[ $server_rest_api_mode != $HTTP && $server_rest_api_mode != $HTTPS ]]; then
    echo "${BOLD}${RED}Invalid value - \"$server_rest_api_mode\" - supplied to the second argument!${NT}"
	echo "${BOLD}Usage:${NT}"
	echo "  ${BOLD}${GREEN}$0 <build-action> <server-protocol> <front-end-hot-reload-action>${NT}"
	echo "${BOLD}Arguments:${NT}"
	echo "  ${BOLD}${GREEN}build-action${NT}:"
	echo "      - Build or rebuild. Rebuild cleans the target forcibly."
	echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}build${NT} or ${BOLD}${GREEN}rebuild${NT}."
	echo "  ${BOLD}${GREEN}server-protocol${NT}:"
	echo "      - Backend server protocol. HTTP is NOT auto-redirected to HTTPS."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}http${NT} or ${BOLD}${GREEN}https${NT}."
    echo "      - HTTP is NOT auto-redirected to HTTPS."
    echo "  ${BOLD}${GREEN}front-end-hot-reload-action${NT}:"
	echo "      - For hot live reloading of front-end code changes using webpack."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}hmr${NT} or ${BOLD}${GREEN}no-hmr${NT}."
    echo "      - ${BOLD}${GREEN}hmr${NT} spawns a new terminal to run webpack server."
    echo "      - ${BOLD}${GREEN}no-hmr${NT} does not spawn a terminal and server does not reflect any live front-end code changes while running - requires restart of the server."
	exit $EXIT_WRONG_PARAMS_ERROR_CODE
fi

if [[ $webpack != $HMR && $webpack != $NOHMR ]]; then
    echo "${BOLD}${RED}Invalid value - \"$webpack\" - supplied to the third argument!${NT}"
	echo "${BOLD}Usage:${NT}"
	echo "  ${BOLD}${GREEN}$0 <build-action> <server-protocol> <front-end-hot-reload-action>${NT}"
	echo "${BOLD}Arguments:${NT}"
	echo "  ${BOLD}${GREEN}build-action${NT}:"
	echo "      - Build or rebuild. Rebuild cleans the target forcibly."
	echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}build${NT} or ${BOLD}${GREEN}rebuild${NT}."
	echo "  ${BOLD}${GREEN}server-protocol${NT}:"
	echo "      - Backend server protocol. HTTP is NOT auto-redirected to HTTPS."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}http${NT} or ${BOLD}${GREEN}https${NT}."
    echo "      - HTTP is NOT auto-redirected to HTTPS."
    echo "  ${BOLD}${GREEN}front-end-hot-reload-action${NT}:"
	echo "      - For hot live reloading of front-end code changes using webpack."
    echo "      - Mandatory argument. Allowed values - ${BOLD}${GREEN}hmr${NT} or ${BOLD}${GREEN}no-hmr${NT}."
    echo "      - ${BOLD}${GREEN}hmr${NT} spawns a new terminal to run webpack server."
    echo "      - ${BOLD}${GREEN}no-hmr${NT} does not spawn a terminal and server does not reflect any live front-end code changes while running - requires restart of the server."
	exit $EXIT_WRONG_PARAMS_ERROR_CODE
fi
echo "${GREEN}$GENERATOR_LINE_PREFIX : Values of arguments are valid. Moving ahead with other checks...${NT}"

echo "$GENERATOR_LINE_PREFIX : Performing pre-requisites checks..."
return_code=0
appbrahma_pre_reqs_check
if [[ $return_code -ne 0 ]]; then
	echo "${RED}$GENERATOR_LINE_PREFIX : Pre-requisites validation failed!${NT}"
	echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
	echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running this script after fixing the above reported errors.${NT}"
	exit $EXIT_PRE_REQ_CHECK_FAILURE_CODE
fi

#https pre-reqs
if [ "$server_rest_api_mode" == "$HTTPS" ]; then
    echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : You have chosen \"$HTTPS\" for back-end server protocol. A PKCS12 keystore with signed server certificate needs to be configured on the back-end server for enabling \"$HTTPS\".${NT}"
    echo ""
    echo "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : AppBrahma has already generated Brillium CA (non-public) signed certificate, PKCS12 keystore, and configured backend server spring boot tls profile for automatic deployment of keystore for the first time server use/run.${NT}"
    echo ""
    echo "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Alternatively, you can configure a new certificate keystore now.${NT}"

    # prompt user for using configured appbrahma self-signed ks or to create a new keystore
    ks_option="Yes No"
    echo "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Would you like to use already configured keystore? (This would be either AppBrahma configured or last configured by you, if this is not the first run of the script)${NT}"
    PS3='Please type the number shown above for selecting your option: '
    select ks_selection in $ks_option;
    do
        # echo ""
        echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : You have chosen \"$REPLY) $ks_selection\" as the option.${NT}"
        if [[ "$ks_selection" != "" ]]; then
            break
        fi
    done
    if [ "$ks_selection" == "Yes" ]; then
        echo "${YELLOW}$GENERATOR_LINE_PREFIX : Please be aware that AppBrahma generated server certificate/keystore is issued by non-public Brillium CA which may require special certificate store/trust configurations on iOS and Android devices for enabling HTTPS access to this server from Apps running on these devices - especially Unimobile app you might have generated for this server by AppBrahma MVP generator.${NT}"
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue...${NT}"
    else
        echo "$GENERATOR_LINE_PREFIX : For configuring a new certificate keystore, you will now need to complete the below steps."
        echo "1.Obtain a digital certificate signed by a publicly known CA for the back-end server."
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue, when the above is done...${NT}"
        echo "2.Generate PKCS12 type keystore from the signed certificate, server private key files and server alias etc. Ensure the files are placed in the same directory as you execute the command in to generate."
        echo "Command with openSSL is - ${YELLOW}openssl pkcs12 -export -out appbrahma-server-ks.p12 -name <server_alias_used_in_cert_or_CSR> -passin pass:<server_private_key_password_used> -password pass:<password_for_generated_keystore -inkey <server_private_key_file_name> -in <CA_signed_server_cert_file_name>${NT}"
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue, when done...${NT}"
        echo "3.Ensure keystore file is named as ${BOLD}appbrahma-server-ks.p12${NT} and place it in ${BOLD}<backend_server_root>/src/main/resources/config/tls${NT}. If a file with the same name exists, replace it."
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue, when done...${NT}"
        echo "4.Update this keystore related information in the spring tls profile file ${BOLD}<backend_server_root>/src/main/resources/config/application-tls.yml${NT} as below and save it:"
        echo "  - \"server.ssl.key-store-password\" key value with the password you have used to create the keystore in the previous steps"
        echo "  - \"server.ssl.key-alias\" key value with the server alias you have used to create the keystore in the previous steps"
        echo "$GENERATOR_LINE_PREFIX : Please ensure you have NOT modified any other information in this file before saving - knowingly or un-knowingly, for such inadvertent changes would result in server start-up failures."
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue, when done...${NT}"
    fi
fi
echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Pre-requisites check completed successfully.${NT}"

# as a pre-caution set the execute access permission to the mvnw script file
chmod_mvnw=$(chmod u+x ./mvnw 2>&1)
if [ $? -gt 0 ]; then
	ECHO "${RED}$GENERATOR_LINE_PREFIX : Error setting execute access permissions to mvnw.sh file. Error details are displayed below. Please do it manually using the command and re-run this script.${NT}"
	echo "$chmod_mvnw"
	exit $EXIT_MVNW_CHMOD_ERROR_CODE
fi

# build or rebuild
if [ "$build_rebuild" == "$REBUILD" ]; then
	echo "$GENERATOR_LINE_PREFIX : Re-building backend web server project..."
	delete_target=$(rm -rf target node_modules 2>&1)
	if [ $? -gt 0 ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : Error deleting the target and node_modules folders for rebuilding!${NT}"
        echo "${RED}Error details are displayed below. Please delete these folders manually and re-run this script.${NT}"
		echo "$delete_target"
		exit $EXIT_DELETE_TARGET_FOLDER_ERROR_CODE
	fi
	clean_mvnw=$(./mvnw clean)
	if [ $? -gt 0 ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : Error cleaning build assets for re-building!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
		echo "$clean_mvnw"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
		exit $EXIT_MVNW_CLEAN_ERROR_CODE
	fi
else
    echo "$GENERATOR_LINE_PREFIX : Building backend web server project..."
fi
echo "$GENERATOR_LINE_PREFIX : Installing nodejs dependencies..."
apb_npm_install=$(npm install --force 2>&1)
if [ $? -gt 0 ]; then
	echo "${RED}$GENERATOR_LINE_PREFIX : Error installing node dependencies!${NT}"
    echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
	echo "$apb_npm_install"
    echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
	exit $EXIT_NPM_INSTALL_ERROR_CODE
fi
echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Installed nodejs dependencies.${NT}"

echo "$GENERATOR_LINE_PREFIX : Building server front-end..."
apb_build_webpack=$(npm run webapp:build 2>&1)
if [ $? -gt 0 ]; then
	echo "${RED}$GENERATOR_LINE_PREFIX : Error building server front-end!${NT}"
	echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
	echo "$apb_build_webpack"
    echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
	exit $EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE
fi
echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Built server front-end.${NT}"

# spawn docker terminal for mysql and run it, if not already running
docker_container_run_check=$(docker container inspect -f '{{.State.Status}}' git-push-server 2>&1)
if [[ ! "$docker_container_run_check" == "running" ]]; then
    # docker daemon run check - it appears we need the below step before calling docker-compose run from the shell.
    docker_run_check=$(docker stats --no-stream 2>&1)
    if [ $? -gt 0 ]; then
        echo "${YELLOW}$GENERATOR_LINE_PREFIX : It appears docker daemon is not running!${NT}"
        echo "${YELLOW}$GENERATOR_LINE_PREFIX : Please run the docker daemon/engine now${NT}"
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue, after docker engine/daemon is up and running...${NT}"
    fi

    echo "${GREEN}$GENERATOR_LINE_PREFIX : Spawning a command terminal for running configured database server in docker container...${NT}"
    spawn_gnome_term_for_db=$(gnome-terminal --tab --title="$DOCKER_DB_TERMINAL_NAME" -- bash -c 'echo "${GREEN}$GENERATOR_LINE_PREFIX : Welcome to Docker DB Server for $SERVER_APP_NAME ${NT}" && docker-compose -f src/main/docker/mysql.yml up --remove-orphans; exec bash' 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Error spawning command terminal or running configured db server!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
        echo "$spawn_gnome_term_for_db"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
        exit $EXIT_GNOME_TERM_DOCKER_RUN_ERROR_CODE
    fi
    echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Spawned a command terminal for running configured database server in docker container.${NT}"
else
    echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Found git-push-server docker container already running configured database server. Will connect to this DB server. Proceeding ahead.${NT}"
fi

# build and run java server
if [ "$server_rest_api_mode" == "$HTTPS" ]; then
    # https
    echo "$GENERATOR_LINE_PREFIX : Now back-end server with \"$HTTPS\" support will be built and run in a spawned terminal..."
    read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue...${NT}"
    spawn_gnome_term_for_back_end_web_server=$(gnome-terminal --tab --title="$SERVER_APP_NAME" -- bash -c 'echo "${GREEN}$GENERATOR_LINE_PREFIX : Welcome to $SERVER_APP_NAME Build and Run${NT}" && ./mvnw -Pdev,-webapp,tls; exec bash' 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Error spawning command terminal for running back-end server!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
        echo "$spawn_gnome_term_for_back_end_web_server"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
        exit $EXIT_SPAWN_TERM_JAVA_SPRING_BOOT_SERVER_ERROR_CODE
    fi
    echo "$GENERATOR_LINE_PREFIX : Spawned command terminal for building and running back-end server with \"$HTTPS\" support."
    echo "${YELLOW}$GENERATOR_LINE_PREFIX : Please wait for the back-end server to be up and running in the spawned terminal.${NT}"
    read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key when the above is done...${NT}"

    # spawn webpack terminal for front-end hot module run
    if [ "$webpack" == "$HMR" ]; then
        echo "$GENERATOR_LINE_PREFIX : Spawning a command terminal to run webpack hot module reload for reflecting live front-end code changes with \"$HTTPS\" support..."
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue...${NT}"
        spawn_gnome_term_for_hmr=$(gnome-terminal --tab --title="$HMR_WEBPACK_TERMINAL_NAME" -- bash -c 'echo "${GREEN}$GENERATOR_LINE_PREFIX : Welcome to AppBrahma Webpack Live HMR for <$SERVER_APP_NAME.${NT}" && npm run start-tls --host=localhost --disable-host-check ; exec bash' 2>&1)
        if [ $? -gt 0 ]; then
            echo "${RED}$GENERATOR_LINE_PREFIX : Error spawning command terminal or running webpack live hot module reload of front-end code changes!${NT}"
            echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
            echo "$spawn_gnome_term_for_hmr"
            echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
            exit $EXIT_GNOME_TERM_WEBPACK_RUN_ERROR_CODE
        fi
        echo "$GENERATOR_LINE_PREFIX : Spawned command terminal for running webpack."
        echo "${YELLOW}$GENERATOR_LINE_PREFIX : Please wait until webpack starts up fully and opens a browser with the server home page link.${NT}"
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key when the above is done...${NT}"
    fi
else
    # http
    echo "$GENERATOR_LINE_PREFIX : Now back-end server with \"$HTTP\" support will be built and run in a spawned terminal..."
    read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue...${NT}"
    spawn_gnome_term_for_back_end_web_server=$(gnome-terminal --tab --title="$SERVER_APP_NAME" -- bash -c 'echo "${GREEN}$GENERATOR_LINE_PREFIX : Welcome to $SERVER_APP_NAME Build and Run${NT}" && ./mvnw -Pdev,-webapp; exec bash' 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Error spawning command terminal for running back-end server!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
        echo "$spawn_gnome_term_for_back_end_web_server"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
        exit $EXIT_MVNW_RUN_JAVA_SERVER_ERROR_CODE
    fi
    echo "$GENERATOR_LINE_PREFIX : Spawned command terminal for building and running back-end server with \"$HTTP\" support."
    echo "${YELLOW}$GENERATOR_LINE_PREFIX : Please wait for the back-end server to be up and running in the spawned terminal.${NT}"
    read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key when the above is done...${NT}"

    # spawn webpack terminal for front-end hot module build or run
    if [ "$webpack" == "$HMR" ]; then
        echo "$GENERATOR_LINE_PREFIX : Spawning a command terminal to run webpack hot module reload for reflecting live front-end code changes with \"$HTTP\" support..."
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue...${NT}"
        spawn_gnome_term_for_hmr=$(gnome-terminal --tab --title="$HMR_WEBPACK_TERMINAL_NAME" -- bash -c 'echo "${GREEN}$GENERATOR_LINE_PREFIX : Welcome to Webpack Live HMR Server for $SERVER_APP_NAME.${NT}" && npm run start; exec bash' 2>&1)
        if [ $? -gt 0 ]; then
            echo "${RED}$GENERATOR_LINE_PREFIX : Error spawning command terminal or running webpack live hot module reload of front-end code changes!${NT}"
            echo "${RED}$GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution.${NT}"
            echo "$spawn_gnome_term_for_hmr"
            echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running the script after fixing above reported errors.${NT}"
            exit $EXIT_GNOME_TERM_WEBPACK_RUN_ERROR_CODE
        fi
        echo "$GENERATOR_LINE_PREFIX : Spawned command terminal for webpack run."
        echo "${YELLOW}$GENERATOR_LINE_PREFIX : Please wait until webpack for live hot module reload of front-end code changes starts up and opens a browser with the server home page link.${NT}"
        read -p "${YELLOW}${BOLD}$GENERATOR_LINE_PREFIX : Press any key to continue, after the above is done...${NT}"
    fi
fi

# display credentials for server log in
if [ "$webpack" == "$HMR" ]; then
    echo "$GENERATOR_LINE_PREFIX : For the login into the back-end server:"
    echo "   - Use the access URL displayed on the spawned webpack hot module reload server terminal for reflecting front-end code changes live"
    echo "     (or)"
    echo "   - Use the URL displayed on the spawned back-end server terminal - any changes in the front-end code will NOT be live reflected on the server"
    echo "$GENERATOR_LINE_PREFIX : Please use the below credentials for the back-end server login."
else
    echo "$GENERATOR_LINE_PREFIX : Please use the below credentials for the back-end server login."
fi
echo "  ${YELLOW}Admin user - Username: brahma, Password: brahma@appbrahma${NT}"
echo "  ${YELLOW}End user - Username: manasputhra, Password: manasputhra@appbrahma${NT}"
echo ""

# acknowledgement and best wishes
echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Wishing you best for faster quality development sprint cycles and go-live.${NT}"
echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Powered and brought to you by the passion, perseverance, perfection, and pursuit of efficiency by Brillium Technologies to transform the world through technology.${NT}"
echo "${GREEN}${BOLD}$GENERATOR_LINE_PREFIX : Thank you for giving us the opportunity to serve you in going live quickly with your MVP by cutting down your development time and effort of the first runnable version of your full-stack product from months of team work to a few individual clicks.${NT}"
echo "${GREEN}${BOLD}-Team AppBrahma${NT}"
echo ""

# end of main script

# function for pre-reqs check
appbrahma_pre_reqs_check() {
    # OS version validation
	LINUX_VERSION_CMD=$(lsb_release -a 2>&1)
	if [ $? -gt 0 ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : Error in getting linux version. The error is:${NT}"
		echo "$LINUX_VERSION_CMD"
		echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Please retry running this script after fixing above errors.${NT}"
		return_code=$EXIT_LINUX_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	fi
	echo "$GENERATOR_LINE_PREFIX : Your linux distribution name and version are:"
	echo "$LINUX_VERSION_CMD"

    # Node install check
	node_command=$(node --version 2>&1)
	if [ $? -gt 0 ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : Nodejs is not installed or NOT in PATH!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS version of nodejs major release $NODE_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
		return_code=$EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	fi

    # Node version check
	node_version=$(node --version | awk -F. '{ print $1 }' 2>&1)
	# remove the first character
	node_command=${node_version#?}
	if [ $node_command -lt $NODE_MAJOR_VERSION ]; then
		echo "${RED}$GENERATOR_LINE_PREFIX : You are running non-supported nodejs major version $(node --version | awk -F. '{ print $1 }')!${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Supported major version is $NODE_MAJOR_VERSION${NT}"
		echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS NodeJS version of major release $NODE_MAJOR_VERSION and retry running this script.${NT}"
		return_code=$EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum Nodejs version requirement met - you are running $(node --version). Moving ahead with other checks..."
	fi

    # npm install check
	npm_command=$(npm --version 2>&1)
	if [ $? -gt 0 ]; then
		    echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : npm (Node Package Manager) is not installed or NOT in PATH!${NT}"
            echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
		    echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Please install a stable and LTS version of npm major release $NPM_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
		    return_code=$EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
		    return
	fi

	# NPM version check
	npm_version=$(npm --version | awk -F. '{ print $1 }' 2>&1)
	if [ $npm_version -lt $NPM_MAJOR_VERSION ]; then
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : You are running unsupported npm major version $(npm --version | awk -F. '{ print $1 }')!${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Supported major version is $NPM_MAJOR_VERSION${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Aborting the build process."
        echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Please install a stable and LTS npm version of major release $NPM_MAJOR_VERSION and retry running this script.${NT}"
		return_code=$EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum npm version requirement met - you are running $(npm --version). Moving ahead with other checks..."
	fi

    # java install check
	java_command=$(java -version 2>&1)
	if [ $? -gt 0 ]; then
	    echo "${RED}$GENERATOR_LINE_PREFIX : Java runtime is not installed or NOT in PATH!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the execution.${NT}"
	    echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS Java JDK version of major release $JAVA_MIN_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
	    return_code=$EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	fi

	# java runtime version check
	java_version_first_part=$(java -version 2>&1 | awk 'NR==1 {print $3}'| awk -F. '{print $1}')
	java_version_first_part=$(echo $java_version_first_part | sed "s/\"//g")
	java_version_second_part=$(java -version 2>&1 | awk 'NR==1 {print $3}'| awk -F. '{print $2}')
	if [ $java_version_first_part -lt $JAVA_MIN_MAJOR_VERSION -a $java_version_second_part -lt $JAVA_MIN_MAJOR_VERSION ]; then
	    echo "${RED}$GENERATOR_LINE_PREFIX : You are running unsupported Java runtime version $java_version_second_part!${NT}"
	    echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the build process."
        echo "${RED}$GENERATOR_LINE_PREFIX : Supported major version is $JAVA_MIN_MAJOR_VERSION${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS version of Java/JDK major release $JAVA_MIN_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
	    return_code=$EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum Java runtime version requirement met - you are running $(java -version 2>&1 | awk 'NR==1 {print $3}'). Moving ahead with other checks..."
	fi

	# jdk install check
	jdk_command=$(javac -help 2>&1)
	if [ $? -gt 0 ]; then
	    echo "${RED}$GENERATOR_LINE_PREFIX : Java JDK is not installed or NOT in PATH!${NT}"
        echo "${RED}$GENERATOR_LINE_PREFIX : Aborting the build process."
	    echo "${RED}$GENERATOR_LINE_PREFIX : Please install a stable and LTS Java JDK version of major release $JAVA_MIN_MAJOR_VERSION or fix the PATH and retry running this script.${NT}"
	    return_code=$EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	else
		echo "$GENERATOR_LINE_PREFIX : Java JDK found in the path. Moving ahead with other checks..."
	fi

    # jdk version check
	jdk_version=$(javac --version | awk -F. '{ print $1 }' 2>&1)
	if [ $jdk_version -lt $JAVA_MIN_MAJOR_VERSION ]; then
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : You are running unsupported JDK major version $(java --version | awk -F. '{ print $1 }')!${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Supported major version is $JAVA_MIN_MAJOR_VERSION${NT}"
		echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Aborting the build process."
        echo "${RED}${BOLD}$GENERATOR_LINE_PREFIX : Please install a stable and LTS npm version of major release $NPM_MAJOR_VERSION and retry running this script.${NT}"
		return_code=$EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
        echo "$GENERATOR_LINE_PREFIX : Minimum npm version requirement met - you are running $(npm --version). Moving ahead with other checks..."
	fi

    # docker installation check - conditional for non-h2 dbs
    docker_install_check=$(docker -v 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Docker engine/desktop is NOT installed or NOT in the path! This is needed for running database in the container.${NT}
        echo "${RED}$GENERATOR_LINE_PREFIX : Please install docker compose and retry running this script.${NT}"
        exit $EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE
    else
        echo "$GENERATOR_LINE_PREFIX : Docker engine/desktop needed for running database container is installed. Moving ahead with other checks..."
    fi

    # docker-compose install check - conditional for non-h2 dbs
    docker_install_check=$(docker-compose version 2>&1)
    if [ $? -gt 0 ]; then
        echo "${RED}$GENERATOR_LINE_PREFIX : Docker-compose is not installed. This is needed for running database in the container.
        echo "Please install docker compose and retry running this script.${NT}"
        exit $EXIT_DOCKER_COMPOSE_NOT_INSTALLED_ERROR_CODE
    else
        echo "$GENERATOR_LINE_PREFIX : Docker-compose needed for running database container is installed. Moving ahead with other checks..."
    fi
}
