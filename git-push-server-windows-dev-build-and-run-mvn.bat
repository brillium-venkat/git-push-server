:: ===================================================================================================================================
:: apb-server-build-n-run-mvn.bat
:: AppBrahma back-end server build and run script
:: Created by Venkateswar Reddy Melachervu on 15-03-2022.
:: Updates:
::  16-03-2022 - Updated for mysql docker terminal spawning and running
::  20-06-2022 - Update for AppBrahma generator sync and https support optimization
::  03-07-2022 - Updated for MacOS terminal spwans and colored font
::  05-07-2022 - Updated for colored text and unification with linux and macos scripts
::  10-07-2022 - Unified across all OSes
:: (C) Brillium Technologies 2019-2022. All rights reserved.
:: ===================================================================================================================================

@echo off
Setlocal EnableDelayedExpansion
set "NT=[0m"
set "BOLD=[1m"
set "UL=[4m"
set "NRED=[31m"
set "NGREEN=[32m"
set "NYELLOW=[33m"
set "NWHITE=[37m"
set "SRED=[91m"
set "SGREEN=[92m"
set "SYELLOW=[93m"
set "SBLUE=[94m"
set "SMAGENTA=[95m"
set "SCYAN=[96m"
set "SWHITE=[97m"

set "ERROR=%SRED%"
set "WARNING=%SYELLOW%"
set "ATTENTION=%SWHITE%"
set "SUCCESS=%SGREEN%"
set "INFO=%WHITE%"
set "ACCENT=%SCYAN%"


:: min version consts
set "NODE_MAJOR_VERSION=16"
set "NPM_MAJOR_VERSION=6"
set "JAVA_MIN_VERSION=11"
set "JAVA_MIN_MAJOR_VERSION=11"
set "JAVA_MIN_MINOR_VERSION=0"

set "GENERATOR_NAME=AppBrahma"
set "GENERATOR_LINE_PREFIX=[%GENERATOR_NAME%]"
set "EXIT_WRONG_PARAMS_ERROR_CODE=100"
set "EXIT_PRE_REQ_CHECK_FAILURE_CODE=101"
set "EXIT_WINDOWS_VERSION_CHECK_COMMAND_ERROR_CODE=102"
set "EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=103"
set "EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=104"
set "EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=105"
set "EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=106"
set "EXIT_DOCKER_VERSION_CHECK_COMMAND_ERROR_CODE=107"
set "EXIT_DOCKER_COMPOSE_VERSION_CHECK_COMMAND_ERROR_CODE=108"
set "EXIT_NPM_INSTALL_COMMAND_ERROR_CODE=109"
set "EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE=110"
set "EXIT_GNOME_TERMINAL_NOT_INSTALLED_ERROR_CODE=111"
set "EXIT_NPM_INSTALL_ERROR_CODE=112"
set "EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE=113"
set "EXIT_MVNW_CHMOD_ERROR_CODE=114"
set "EXIT_DELETE_TARGET_FOLDER_ERROR_CODE=115"
set "EXIT_MVNW_CLEAN_ERROR_CODE=116"
set "EXIT_WEB_FRONT_END_BUILD_ERROR_CODE=117"
set "EXIT_JAVA_WEB_SERVER_BUILD_ERROR_CODE=118"
set "EXIT_DIR_DELETE_ERROR_CODE=119"
set "EXIT_MVN_CLEAN_ERROR_CODE=120"
set "EXIT_PROJ_REBUILD_ERROR_CODE=121"
set "EXIT_SPAWN_TERM_DOCKER_RUN_ERROR_CODE=122"
set "EXIT_SPAWN_TERM_JAVA_SPRING_BOOT_SERVER_ERROR_CODE=123"
set "EXIT_SPAWN_TERM_HMR_SERVER_ERROR_CODE=124"

set "DOCKER_DB_TERMINAL_NAME=Docker Backend DB Server Terminal"
set "HMR_WEBPACK_TERMINAL_NAME=Webpack HMR Terminal"
set "BACKEND_SERVER_TERMINAL_NAME=Backend Java Spring Boot Server Terminal"

set "output_tmp_file=.appbrahma-server-build-n-run.tmp"
set "child1_output_tmp_file=.appbrahma-server-build-n-run-child-1.tmp"

:: constant strings
set "BUILD=build"
set "REBUILD=rebuild"
set "HTTP=http"
set "HTTPS=https"
set "HMR=hmr"
set "NOHMR=no-hmr"
set "CONFIGURE_NEW_KEYSTORE=configure-new-ks"
set "USE_CONFIGURED_KEYSTORE=use-configured-ks"
set "LOCALHOST=localhost"
set "apb_server_tmp_output_file=.apb-server-build-n-run.tmp"

cls
echo ==========================================================================================================================================
echo 				Welcome to %SGREEN%%GENERATOR_NAME% maven build and run script%NT% for development and testing - non-production
echo Sit back, relax, and sip a cup of coffee while the dependencies are downloaded, project is built, and run. 
echo Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution.
echo ==========================================================================================================================================
echo %SYELLOW%%GENERATOR_LINE_PREFIX% : You typed - "%~nx0 %*%NT%"
echo.

:: arguments
:: %1 - build/rebuild - rebuild cleans the target directory, node_modules etc. forcibly
:: %2 - http/https - back-end server protocol support - http or https
:: %3 - hmr or nohmr - live hot-reload of front-end code changes or no hot module reload

:: args and count
set "build_rebuild=%1"
set "server_rest_api_mode=%2"
set "webpack=%3"

set /A "arg_count=0"
for %%g in (%*) do (
	set /A arg_count+=1
)

:: remove any residual temp logs
if exist !apb_server_tmp_output_file! (
	for /F "tokens=*" %%G in ('del /F !apb_server_tmp_output_file!' ) do (									
		set "del_result=%%G"
	)		
) 

if !arg_count! LSS 3 ( 
	echo %SRED%%GENERATOR_LINE_PREFIX% : In-sufficient parameters supplied - needed 3 but !arg_count! supplied^^!%NT%	    
	echo %BOLD%Usage:%NT%
    echo    %SUCCESS%windows-scripts-server-windows-dev-build-and-run-mvn.sh %BOLD%build-action server-protocol front-end-hot-reload-action%NT%
    echo %BOLD%Arguments:%NT%
    echo    %SGREEN%build-action%NT%: 
    echo        - Build or rebuild. Rebuild cleans the target forcibly. Mandatory argument. Allowed values - %SGREEN%build%NT% or %SGREEN%rebuild%NT%.
    echo    %SGREEN%server-protocol%NT%: 
    echo        - Backend server protocol. HTTP is NOT auto-redirected to HTTPS. HTTPS requires keystore infomation in next arguments. 
    echo        - Mandatory argument. Allowed values - %SGREEN%http%NT% or %SGREEN%https%NT%.
    echo    %SGREEN%front-end-hot-module-reload-action%NT%: 
    echo        - Hot live reloading of front-end code changes.
    echo        - Mandatory argument. Allowed values are: %SGREEN%hmr%NT% or %SGREEN%no-hmr%NT%.
    echo        - %SGREEN%hmr%NT% spawns a new terminal to run webpack for live hot reload of front-end code changes.
    echo        - %SGREEN%nohmr%NT% does not spawn a terminal and server does not reflect any front-end code changes while running - requires re-run of the server.
    echo. 	
	exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%		
)

:: args validation
if not !build_rebuild!==!BUILD! (
	if not !build_rebuild!==!REBUILD! (
		echo %SRED%%GENERATOR_LINE_PREFIX% : Invalid value - "!build_rebuild!" - supplied for the first argument^^!%NT%	        
		echo %BOLD%Usage:%NT%
        echo    %SUCCESS%windows-scripts-server-windows-dev-build-and-run-mvn.sh %BOLD%build-action server-protocol front-end-hot-reload-action%NT%
        echo %BOLD%Arguments:%NT%
        echo    %SGREEN%build-action%NT%: 
        echo        - Build or rebuild. Rebuild cleans the target forcibly. Mandatory argument. Allowed values - %SGREEN%build%NT% or %SGREEN%rebuild%NT%.
        echo    %SGREEN%server-protocol%NT%: 
        echo        - Backend server protocol. HTTP is NOT auto-redirected to HTTPS. HTTPS requires keystore infomation in next arguments. 
        echo        - Mandatory argument. Allowed values - %SGREEN%http%NT% or %SGREEN%https%NT%.
        echo    %SGREEN%front-end-hot-module-reload-action%NT%: 
        echo        - Hot live reloading of front-end code changes.
        echo        - Mandatory argument. Allowed values are: %SGREEN%hmr%NT% or %SGREEN%no-hmr%NT%.
        echo        - %SGREEN%hmr%NT% spawns a new terminal to run webpack for live hot reload of front-end code changes.
        echo        - %SGREEN%nohmr%NT% does not spawn a terminal and server does not reflect any front-end code changes while running - requires re-run of the server.
        echo. 	
        exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%		
	) 
)

if not !server_rest_api_mode!==!HTTP! (
	if not !server_rest_api_mode!==!HTTPS! (
		echo %SRED%%GENERATOR_LINE_PREFIX% : Invalid value - "!server_rest_api_mode!" - supplied for the second argument^^!%NT%	        
		echo %BOLD%Usage:%NT%
        echo    %SUCCESS%windows-scripts-server-windows-dev-build-and-run-mvn.sh %BOLD%build-action server-protocol front-end-hot-reload-action%NT%
        echo %BOLD%Arguments:%NT%
        echo    %SGREEN%build-action%NT%: 
        echo        - Build or rebuild. Rebuild cleans the target forcibly. Mandatory argument. Allowed values - %SGREEN%build%NT% or %SGREEN%rebuild%NT%.
        echo    %SGREEN%server-protocol%NT%: 
        echo        - Backend server protocol. HTTP is NOT auto-redirected to HTTPS. HTTPS requires keystore infomation in next arguments. 
        echo        - Mandatory argument. Allowed values - %SGREEN%http%NT% or %SGREEN%https%NT%.
        echo    %SGREEN%front-end-hot-module-reload-action%NT%: 
        echo        - Hot live reloading of front-end code changes.
        echo        - Mandatory argument. Allowed values are: %SGREEN%hmr%NT% or %SGREEN%no-hmr%NT%.
        echo        - %SGREEN%hmr%NT% spawns a new terminal to run webpack for live hot reload of front-end code changes.
        echo        - %SGREEN%nohmr%NT% does not spawn a terminal and server does not reflect any front-end code changes while running - requires re-run of the server.
        echo. 	
        exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%		
	) 
)

if not !webpack!==!HMR! (
	if not !webpack!==!NOHMR! (
		echo %SRED%%GENERATOR_LINE_PREFIX% : Invalid value - "!webpack!" - supplied for the third argument^^!%NT%	        
		echo %BOLD%Usage:%NT%
        echo    %SUCCESS%windows-scripts-server-windows-dev-build-and-run-mvn.sh %BOLD%build-action server-protocol front-end-hot-reload-action%NT%
        echo %BOLD%Arguments:%NT%
        echo    %SGREEN%build-action%NT%: 
        echo        - Build or rebuild. Rebuild cleans the target forcibly. Mandatory argument. Allowed values - %SGREEN%build%NT% or %SGREEN%rebuild%NT%.
        echo    %SGREEN%server-protocol%NT%: 
        echo        - Backend server protocol. HTTP is NOT auto-redirected to HTTPS. HTTPS requires keystore infomation in next arguments. 
        echo        - Mandatory argument. Allowed values - %SGREEN%http%NT% or %SGREEN%https%NT%.
        echo    %SGREEN%front-end-hot-module-reload-action%NT%: 
        echo        - Hot live reloading of front-end code changes.
        echo        - Mandatory argument. Allowed values are: %SGREEN%hmr%NT% or %SGREEN%no-hmr%NT%.
        echo        - %SGREEN%hmr%NT% spawns a new terminal to run webpack for live hot reload of front-end code changes.
        echo        - %SGREEN%nohmr%NT% does not spawn a terminal and server does not reflect any front-end code changes while running - requires re-run of the server.
        echo. 	
        exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%		
	) 
)
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Values of arguments are valid. Moving ahead with other checks...%NT%

echo %GENERATOR_LINE_PREFIX% : Performing pre-requisites checks...
call :appbrahma_pre_reqs_check
if !ERRORLEVEL! NEQ 0 (  	
	echo %SRED%%GENERATOR_LINE_PREFIX% : Pre-requisites validation failed^^!%NT% 
	echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the execution.%NT%
	echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running this script after fixing the above reported errors.%NT%
	exit /b %EXIT_PRE_REQ_CHECK_FAILURE_CODE%
)

:: https pre-reqs
if !server_rest_api_mode!==!HTTPS! (
    echo.
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : You have chosen %BOLD%%HTTPS%%BOLD% for back-end server protocol. A PKCS12 keystore with signed server certificate needs to be configured on the back-end server for enabling %BOLD%%HTTPS%.%NT%
    echo.
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : AppBrahma has already generated Brillium CA ^(non-public^) signed certificate, PKCS12 keystore, and configured backend server spring boot tls profile for automatic deployment of keystore for the first time server use/run.%NT%
    echo.
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Alternatively, you can configure a new certificate keystore now.%NT%        
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Would you like to use already configured keystore? ^(This would be either AppBrahma configured or last configured by you, if this is not the first run of the script^)%NT%
    set "YES=Yes"
    set "NO=No"
    set "ONE=1"
    set "TWO=2"
    echo    %SYELLOW%1^) !YES!
    echo    2^) !NO!%NT%
    :prompt_back
    set /p choice="%SYELLOW%%GENERATOR_LINE_PREFIX% : Please type a number shown above for selecting your option: %NT%"	
    if !choice!==!ONE! (
        echo %SGREEN%%GENERATOR_LINE_PREFIX% : You have chosen "1^) !YES!" as the option.%NT%
    ) else (
        if !choice!==!TWO! (
            echo %SGREEN%%GENERATOR_LINE_PREFIX% : You have chosen "2^) !NO!" as the option.%NT%
        ) else (
            echo %SRED%%GENERATOR_LINE_PREFIX% : You have typed an illegal value - "!choice!" - as the option.%NT%
            goto :prompt_back
        )    
    )
    :: echo.
    if !choice!==!ONE! (
        :: already configured ks
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Please be aware that AppBrahma generated server certificate/keystore is issued by non-public Brillium CA which may require special certificate store/trust configurations on iOS and Android devices for enabling HTTPS access to this server from Apps running on these devices - especially Unimobile app you might have generated for this server by AppBrahma MVP generator.%NT%
        echo.
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue...%NT%
        :: wait for the user confirmation
        pause > Nul    
    ) else (
        :: user is generating and configuring the ks
        echo %GENERATOR_LINE_PREFIX% : For configuring a new certificate keystore, you will now need to complete the below steps.    
        echo 1.Obtain a digital certificate signed by a publicly known CA for the back-end server.
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
        :: wait for the user confirmation
        pause > Nul     
        echo 2.Generate PKCS12 type keystore from the signed certificate, server private key files and server alias etc. Ensure the files are placed in the same directory as you execute the command in to generate.
        echo Command with openSSL is - %BOLD%openssl pkcs12 -export -out appbrahma-server-ks.p12 -name ^<server_alias_used_in_cert_or_CSR^> -passin pass:^<server_private_key_password_used^> -password pass:^<password_for_generated_keystore^> -inkey ^<server_private_key_file_name^> -in ^<CA_signed_server_cert_file_name^>%NT%    
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
        :: wait for the user confirmation
        pause > Nul     
        echo 3.Ensure keystore file is named as %BOLD%appbrahma-server-ks.p12%NT% and place it in %BOLD%^<backend_server_root^>/src/main/resources/config/tls%NT%. ^If a file with the same name exists, ^replace it.    
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
        :: wait for the user confirmation
        pause > Nul     
        echo 4.Update this keystore related information in the spring tls profile file %BOLD%^<backend_server_root^>/src/main/resources/config/application-tls.yml%NT% as below and save it:
        echo    - "server.ssl.key-store-password" key value with the password you have used to create the keystore in the previous steps
        echo    - "server.ssl.key-alias" key value with the server alias you have used to create the keystore in the previous steps
        echo %GENERATOR_LINE_PREFIX% : Please ensure you have NOT modified any other information in this file before saving - knowingly or un-knowingly, for such inadvertent changes would result in server start-up failures.
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
        :: wait for the user confirmation
        pause > Nul     
    )
)
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Pre-requisites check completed successfully.%NT%

:: build or rebuild
if !build_rebuild!==!REBUILD! (
    echo %GENERATOR_LINE_PREFIX% : Rebuild is requested. Cleaning the project for the rebuild...
    if exist node_modules\ (
		call rmdir /S /Q node_modules > "!apb_server_tmp_output_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			set "error_code=!ERRORLEVEL!"
            echo %SRED%%GENERATOR_LINE_PREFIX% : Error removing node_modules directory for rebuilding^^!%NT%	
			echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
            for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
			echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								
			exit /b %EXIT_DIR_DELETE_ERROR_CODE%
		)
	)
    if exist target\ (
		call rmdir /S /Q target > "!apb_server_tmp_output_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			set "error_code=!ERRORLEVEL!"
            echo %SRED%%GENERATOR_LINE_PREFIX% : Error removing target directory for rebuilding^^!%NT%	
			echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
            for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
			echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								
			exit /b %EXIT_DIR_DELETE_ERROR_CODE%
		)
	)
    call .\mvnw clean > "!apb_server_tmp_output_file!" 2>&1			
    if !ERRORLEVEL! NEQ 0  (
        set "error_code=!ERRORLEVEL!"
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error cleaning the project for rebuilding^^!%NT%	
        echo %GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
        echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								
        exit /b %EXIT_MVN_CLEAN_ERROR_CODE%
    )
    echo %SGREEN%%GENERATOR_LINE_PREFIX% : Project cleaned successfully.%NT%
    echo %GENERATOR_LINE_PREFIX% : Starting the re-build process...%NT%
) else (
    echo %GENERATOR_LINE_PREFIX% : Starting the build process...%NT%
)

:: install node deps
echo %GENERATOR_LINE_PREFIX% : Installing nodejs dependencies...
call npm install --force > "!apb_server_tmp_output_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
    set "error_code=!ERRORLEVEL!"
    echo %SRED%%GENERATOR_LINE_PREFIX% : Error installing node dependencies^^!%NT%
    echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%	
    for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
    echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported error.%NT%
	exit /b %EXIT_NPM_INSTALL_ERROR_CODE%
)
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Installed nodejs dependencies.%NT%

:: build angular front-end webapp
echo %GENERATOR_LINE_PREFIX% : Building server front-end...
call npm run webapp:build > "!apb_server_tmp_output_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
	set "error_code=!ERRORLEVEL!"
    echo %SRED%%GENERATOR_LINE_PREFIX% : Error building server front-end^^!%NT%
    echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%	
    for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
    echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported error.%NT%
	exit %EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE%
)
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Built server front-end.%NT%

:: spawn docker terminal for mysql and run it, if not already running
call docker container inspect -f '{{.State.Status}}' windows-scripts-server > "!apb_server_tmp_output_file!" 2>&1
for /F "tokens=* usebackq" %%I in ("!apb_server_tmp_output_file!") do (
    set "docker_container_run_check=%%~I"
    set "docker_container_run_check=!docker_container_run_check:'=!"
)
set "RUNNING=running"
if !docker_container_run_check!==!RUNNING! (
	echo %SGREEN%%GENERATOR_LINE_PREFIX% : Found docker container already running configured database server. Will connect to this DB server. Proceeding ahead.%NT%
) else (    
    :: daemon run check - it appears we need the below steps before calling docker-compose run from the command line
    call docker stats --no-stream > "!apb_server_tmp_output_file!" 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : It appears docker daemon is NOT running^^!%NT%
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Please run the docker daemon/engine now%NT%
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, after docker engine/daemon is up and running...%NT%
        :: wait for the user confirmation
        pause > Nul    
    )       
    call;    
    echo %GENERATOR_LINE_PREFIX% : Spawning a command terminal for running configured database server in docker container...    
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key when ready to continue...%NT%
    :: wait for the user confirmation
    pause > Nul
    start "!DOCKER_DB_TERMINAL_NAME!" /D "!cd!" /i echo %SGREEN%%GENERATOR_LINE_PREFIX% : Welcome to!DOCKER_DB_TERMINAL_NAME! for Windows Scripts Server%NT% ^& docker-compose -f src/main/docker/mysql.yml up --remove-orphans    
    if !ERRORLEVEL! NEQ 0 (
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error spawning command terminal or running configured db server^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed above. Aborting the execution.%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								        
        exit %EXIT_SPAWN_TERM_DOCKER_RUN_ERROR_CODE%
    )
    echo %SGREEN%%GENERATOR_LINE_PREFIX% : Spawned a command terminal for running configured database server in docker container.%NT%
)

:: build and run backend java server
if !server_rest_api_mode!==!HTTPS! (
    :: https support
    echo %GENERATOR_LINE_PREFIX% : Now back-end server with "!HTTPS!" support will be built and run in a spawned terminal...    
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key when ready to continue...%NT%
    :: wait for the user confirmation
    pause > Nul 
    echo %GENERATOR_LINE_PREFIX% : Spawning a command terminal for building and running backend java spring boot server project...    
    start "!BACKEND_SERVER_TERMINAL_NAME!" /D "!cd!" /i echo %SGREEN%%GENERATOR_LINE_PREFIX% : Welcome to Java Spring Boot Back-end Server.%NT% ^& mvnw -Pdev,-webapp,tls    
    if !ERRORLEVEL! NEQ 0 (
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error spawning command terminal or building and running back-end java spring server^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed above. Aborting the execution.%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								        
        exit %EXIT_SPAWN_TERM_JAVA_SPRING_BOOT_SERVER_ERROR_CODE%
    )
    echo %SGREEN%%GENERATOR_LINE_PREFIX% : Spawned command terminal for building and running backend java spring boot server project with !HTTPS! support.%NT%
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Please wait for the back-end java spring boot server to be up and running in the spawned terminal.%NT%
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
    :: wait for the user confirmation
    pause > Nul

    if !webpack!==!HMR! (
        echo %GENERATOR_LINE_PREFIX% : Spawning a command terminal to run webpack hot module reload for reflecting live front-end code changes with "!HTTPS!" support...
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key when ready to continue...%NT%
        :: wait for the user confirmation
        pause > Nul 
        start "!HMR_WEBPACK_TERMINAL_NAME!" /D "!cd!" /i echo %SGREEN%%GENERATOR_LINE_PREFIX% : Welcome to Webpack Hot Module Reload Terminal.%NT% ^& npm run start-tls --host=localhost
        if !ERRORLEVEL! NEQ 0 (
            echo %SRED%%GENERATOR_LINE_PREFIX% : Error spawning command terminal or running webpack live hot module reload server for front-end code changes^^!%NT%        
            echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed above. Aborting the execution.%NT%        
            echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								        
            exit %EXIT_SPAWN_TERM_HMR_SERVER_ERROR_CODE%
        )
        echo %SGREEN%%GENERATOR_LINE_PREFIX% : Spawned command terminal to run webpack hot module reload for reflecting live front-end code changes with "!HTTPS!" support.%NT%
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Please wait for webpack HMR server starts up fully and opens a browser with the back-end server home page link.%NT%
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
        :: wait for the user confirmation
        pause > Nul
    )    
) else (
    :: http support
    echo %GENERATOR_LINE_PREFIX% : Now back-end server with "!HTTP!" support will be built and run in a spawned terminal...    
    echo %GENERATOR_LINE_PREFIX% : Spawning a command terminal for building and running backend java spring boot server project...    
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key when ready to continue...%NT%
    :: wait for the user confirmation
    pause > Nul
    start "!BACKEND_SERVER_TERMINAL_NAME!" /D "!cd!" /i echo %SGREEN%%GENERATOR_LINE_PREFIX% : Welcome to Java Spring Boot Back-end Server.%NT% ^& mvnw -Pdev,-webapp    
    if !ERRORLEVEL! NEQ 0 (
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error spawning command terminal or building and running back-end java spring server^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed above. Aborting the execution.%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								        
        exit %EXIT_SPAWN_TERM_JAVA_SPRING_BOOT_SERVER_ERROR_CODE%
    )
    echo %SGREEN%%GENERATOR_LINE_PREFIX% : Spawned command terminal for building and running backend java spring boot server project with !HTTP! support.%NT%
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Please wait for the back-end java spring boot server to be up and running in the spawned terminal.%NT%
    echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
    :: wait for the user confirmation
    pause > Nul

    if !webpack!==!HMR! (
        echo %GENERATOR_LINE_PREFIX% : Spawning a command terminal to run webpack hot module reload for reflecting live front-end code changes with "!HTTP!" support...
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key when ready to continue...%NT%
        :: wait for the user confirmation
        pause > Nul            
        start "!HMR_WEBPACK_TERMINAL_NAME!" /D "!cd!" /i echo %SGREEN%%GENERATOR_LINE_PREFIX% : Welcome to Webpack Hot Module Reload Terminal.%NT% ^& npm run start --host=localhost        
        if !ERRORLEVEL! NEQ 0 (
            echo %SRED%%GENERATOR_LINE_PREFIX% : Error spawning command terminal or running webpack live hot module reload server for front-end code changes^^!%NT%        
            echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed above. Aborting the execution.%NT%        
            echo %SRED%%GENERATOR_LINE_PREFIX% : Please retry running the script after fixing the above reported errors.%NT%			 								        
            exit %EXIT_SPAWN_TERM_HMR_SERVER_ERROR_CODE%
        )
        echo %SGREEN%%GENERATOR_LINE_PREFIX% : Spawned command terminal to run webpack hot module reload for reflecting live front-end code changes with "!HTTP!" support.%NT%
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Please wait for webpack HMR server starts up fully and opens a browser with the back-end server home page link.%NT%
        echo %SYELLOW%%GENERATOR_LINE_PREFIX% : Press any key to continue, when the above is done...%NT%
        :: wait for the user confirmation
        pause > Nul
    )    
)

:: display credentials for server log in
:: echo.
if !webpack!==!HMR! (
    echo %GENERATOR_LINE_PREFIX% : For the login into the back-end server:
    echo    - Use the access URL displayed on the spawned webpack hot module reload server terminal for reflecting front-end code changes live
    echo            ^(or^)
    echo    - Use the URL displayed on the spawned back-end server terminal - any changes in the front-end code will NOT be live reflected on the server
    echo %GENERATOR_LINE_PREFIX% : Please use the below credentials for the back-end server login.         
) else (
    echo %GENERATOR_LINE_PREFIX% : For the login into the back-end server, use the URL displayed on the spawned back-end server terminal.
    echo %GENERATOR_LINE_PREFIX% : Please use the below credentials for the back-end server login.     
)
echo    %SYELLOW%%BOLD%Admin user - Username: brahma, Password: brahma@appbrahma%NT%
echo    %SYELLOW%%BOLD%End user - Username: manasputhra, Password: manasputhra@appbrahma%NT%
echo.

:: acknowledgement and best wishes
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Wishing you best for faster quality development sprint cycles and go-live.%NT%
echo.
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Powered and brought to you by the passion, perseverance, and pursuit of perfection and efficiency by Brillium Technologies to transform the world through technology.%NT%
echo.
echo %SGREEN%%GENERATOR_LINE_PREFIX% : Thank you for giving us the opportunity to serve you in going live quickly with your MVP by cutting down your development time and effort of the first runnable version of your full-stack product from months of team work to a few individual clicks.%NT%
echo %SGREEN%-Team AppBrahma%NT%
echo.
exit /b 0

:: function reset errorlevel to zero
:reset_error_level    
    exit /b 0

:: function pre-reqs check
:appbrahma_pre_reqs_check
    set "for_exec_result="
    :: windows os name and version
	set "for_exec_result="
	echo %GENERATOR_LINE_PREFIX% : Your Windows version details are :
	for /F "tokens=*" %%G in ('systeminfo ^| findstr /B /C:"OS Name" /C:"OS Version"') do (			
		set ver_token=%%G
		set ver_token=!ver_token: =!
		for /F "tokens=1,2 delims=:" %%J in ("!ver_token!") do (
			echo 	%%J : %%K
		)				
	)

    :: nodejs install check	
    call node --version > "!apb_server_tmp_output_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (                 
		set "error_code=!ERRORLEVEL!"        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Nodejs is not installed or NOT in PATH^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
		echo %SRED%%GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of nodejs major release !NODE_MAJOR_VERSION! or fix the PATH and retry running this script.%NT%
		exit /b !EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE! 
	)    
    
    :: nodejs version check	
    for /F "tokens=*" %%G in ('node --version') do (									
		set "for_exec_result=%%G"
	)
    for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (	
		set "raw_major_ver=%%G"	
		for /f "tokens=1 delims=v" %%J in ("!raw_major_ver!") do (
			set "major_verion=%%J"
		)			
		if !major_verion! LSS %NODE_MAJOR_VERSION% (
			echo %SRED%%GENERATOR_LINE_PREFIX% : You are running non-supported nodejs version "%%G.%%H.%%I"^^!%NT%
			echo %SRED%%GENERATOR_LINE_PREFIX% : Supporeted major version is %NODE_MAJOR_VERSION%.%NT% 
			echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS NodeJS version of major release %NODE_MAJOR_VERSION% and retry running the script.%NT%
			exit /b %EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE%
		) else (
			echo %GENERATOR_LINE_PREFIX% : Minimum Nodejs version requirement met - you are running !for_exec_result!. Moving ahead with other checks...%NT%
		)
	)     

    :: npm install check	
    call npm --version > "!apb_server_tmp_output_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (                 
		set "error_code=!ERRORLEVEL!"
        echo %SRED%%GENERATOR_LINE_PREFIX% : npm ^(Node Package Manager^) is NOT installed or NOT in PATH^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
		echo %SRED%%GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of npm major release !NPM_MAJOR_VERSION! or fix the PATH and retry running this script.%NT%
		exit /b !EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE! 
	) 

    :: npm version check
	for /F "tokens=*" %%G in ('npm --version') do (									
		set "for_exec_result=%%G"
	)
    for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (					
		if %%G LSS %NPM_MAJOR_VERSION% (
            set "error_code=!ERRORLEVEL!"
			echo %SRED%%GENERATOR_LINE_PREFIX% : You are running non-supported npm major version %%G.%%H.%%I^^!%NT%
			echo %SRED%%GENERATOR_LINE_PREFIX% : Supported major version is %NPM_MAJOR_VERSION%.%NT%
			echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS npm version of major release !NPM_MAJOR_VERSION! and retry running this script.%NT%
			exit /b %EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE%
		) else (
			echo %GENERATOR_LINE_PREFIX% : Minimum npm version requirement met - you are running !for_exec_result!. Moving ahead with other checks...%NT%
		)
	)

    :: Java run time install check	
    call java -version > "!apb_server_tmp_output_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (                 
		set "error_code=!ERRORLEVEL!"
        echo %SRED%%GENERATOR_LINE_PREFIX% : Java run time is NOT installed or NOT in PATH^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
		echo %SRED%%GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of JRE/JDK major release !JAVA_MIN_MAJOR_VERSION! or fix the PATH and retry running this script.%NT%
		exit /b !EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE! 
	)

    :: Java runtime version check
	set "first_line_string="
	set "first_line=1"
	for /F "tokens=*" %%G in ('java -version  2^>^&1 1^> nul') do (	
		if !first_line! EQU 1 (
			set "first_line_string=%%G"
			set /a first_line=!first_line!+1
		)	
	)	    
	set "third_token="
	::  percent~I on commandline or percent percent~I in batch file expands percent I removing any surrounding quotes	
	for /F "tokens=1,2,3,4,5 delims= " %%G in ("!first_line_string!") do (			
		set "third_token=%%~I"		
	)    
	set "java_major_version="
	set "java_minor_version="
	set "java_patch_version="
	for /F "tokens=1,2,3 delims=." %%G in ("!third_token!") do (
		set java_major_version=%%G
		set java_minor_version=%%H
		set java_patch_version=%%I
	)
	set first_part_mis_match=0
	set second_part_mis_match=0
	if !java_major_version! LSS %JAVA_MIN_MAJOR_VERSION% (
		set first_part_mis_match=1
	)
	if !java_minor_version! LSS %JAVA_MIN_MINOR_VERSION% (
		set second_part_mis_match=1
	)
    if !first_part_mis_match! == 1 (
		echo %SRED%%GENERATOR_LINE_PREFIX% : You are running non-supported Java runtime version !third_token!^^!%NT% 
		echo %SRED%%GENERATOR_LINE_PREFIX% : Supported major version is %JAVA_MIN_MAJOR_VERSION%%NT%
		echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS java release of major version %JAVA_MIN_MAJOR_VERSION% and retry running this script.%NT%
		exit /b %EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE%
	) 
	if !second_part_mis_match! == 1 (
		echo %SRED%%GENERATOR_LINE_PREFIX% : You are running non-supported Java runtime version !third_token!^^!%NT% 
		echo %SRED%%GENERATOR_LINE_PREFIX% : Supported major version is %JAVA_MIN_MAJOR_VERSION%%NT%
		echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS java release of major version %JAVA_MIN_MAJOR_VERSION% and retry running this script.%NT%
		exit /b %EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE%
	) else (		
        echo %GENERATOR_LINE_PREFIX% : Minimum Java run time version requirement met - you are running !third_token!. Moving ahead with other checks...%NT%
	)

    :: jdk install check
    call javac -version > "!apb_server_tmp_output_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (                 
		set "error_code=!ERRORLEVEL!"
        echo %SRED%%GENERATOR_LINE_PREFIX% : Java JDK is NOT installed or NOT in PATH^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
		echo %SRED%%GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of JDK major release !JAVA_MIN_MAJOR_VERSION! or fix the PATH and retry running this script.%NT%
		exit /b !EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE! 
	)
    :: jdk version check
    for /F "tokens=1,2 delims= " %%G in ('javac -version') do (			
		set "jdk_version=%%~H"	       
	)    
    for /F "tokens=1,2,3 delims=." %%G in ("!jdk_version!") do (
		set java_major_version=%%G
		set java_minor_version=%%H
		set java_patch_version=%%I
	)

    if !java_major_version! LSS %JAVA_MIN_MAJOR_VERSION% (
		set first_part_mis_match=1
	)
	if !java_minor_version! LSS %JAVA_MIN_MINOR_VERSION% (
		set second_part_mis_match=1
	)

    if !first_part_mis_match! == 1 (
		echo %SRED%%GENERATOR_LINE_PREFIX% : You are running non-supported JDK version !jdk_version!^^!%NT% 
		echo %SRED%%GENERATOR_LINE_PREFIX% : Supported major version is %JAVA_MIN_MAJOR_VERSION%%NT%
		echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS java release of major version %JAVA_MIN_MAJOR_VERSION% and retry running this script.%NT%
		exit /b %EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE%
	) 
	if !second_part_mis_match! == 1 (
		echo %SRED%%GENERATOR_LINE_PREFIX% : You are running non-supported JDK version !jdk_version!^^!%NT% 
		echo %SRED%%GENERATOR_LINE_PREFIX% : Supported minor version is %JAVA_MIN_MINOR_VERSION%%NT%
		echo %SRED%%GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS java release of major version %JAVA_MIN_MAJOR_VERSION% and retry running this script.%NT%
		exit /b %EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE%
	) else (		
        echo %GENERATOR_LINE_PREFIX% : Minimum JDK run time version requirement met - you are running !jdk_version!. Moving ahead with other checks...%NT%
	)

    :: docker install check
    call docker -v > "!apb_server_tmp_output_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (                 
		set "error_code=!ERRORLEVEL!"
        echo %SRED%%GENERATOR_LINE_PREFIX% : Docker engine is NOT installed or NOT in the path^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
		echo %SRED%%GENERATOR_LINE_PREFIX% : Please install a stable and latest LTS version of docker release or fix the PATH and retry running this script.%NT%
		exit /b !EXIT_DOCKER_VERSION_CHECK_COMMAND_ERROR_CODE! 
	) else (		
        for /F "tokens=1,2,3,4,5 delims= " %%G in ('docker -v') do (			
            for /F "tokens=1,* delims=," %%L in ("!%%I") do (
                set "docker_version=%%~L"
            )		    
            set "docker_build=%%~K"
	    )    
        echo %GENERATOR_LINE_PREFIX% : Docker engine requirement met - you are running docker version !docker_version! and build !docker_build!. Moving ahead with other checks...%NT%
	)

    :: docker-compose install check
    call docker-compose -v > "!apb_server_tmp_output_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (                 
		set "error_code=!ERRORLEVEL!"
        echo %SRED%%GENERATOR_LINE_PREFIX% : Docker compose is NOT installed or NOT in the path^^!%NT%        
        echo %SRED%%GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.%NT%
        for /F "usebackq delims=" %%I in ("!apb_server_tmp_output_file!") do echo %%I
		echo %SRED%%GENERATOR_LINE_PREFIX% : Please install a stable and latest LTS version of docker compose or fix the PATH and retry running this script.%NT%
		exit /b !EXIT_DOCKER_COMPOSE_VERSION_CHECK_COMMAND_ERROR_CODE! 
	) else (		
        for /F "tokens=1,2,3,4,5 delims= " %%G in ('docker-compose -v') do (			
            for /F "tokens=1,* delims=," %%L in ("!%%I") do (
                set "docker_compose_version=%%~L"
            )		    
            set "docker_compose_build=%%~K"
	    )    
        echo %GENERATOR_LINE_PREFIX% : Docker compose requirement met - you are running docker compose version !docker_compose_version! and build !docker_compose_build!. Moving ahead with other checks...%NT%
	)
    exit /b 0
