:: =================================================================================
:: apb-server-build-n-run-mvn.bat
:: AppBrahma server building and running
:: Created by Venkateswar Reddy Melachervu on 17-12-2021.
:: Updates:
::      17-12-2021 - Added gracious error handling and recovery mechansim for already added android platform
:: ================================================================================= 

@echo off
setlocal
set "GENERATOR_NAME=AppBrahma"
set "GENERATOR_LINE_PREFIX=\[$GENERATOR_NAME]"
set "EXIT_WRONG_PARAMS_ERROR_CODE=100"
set "EXIT_DOCKER_NOT_INSTALLED_ERROR_CODE=101"
set "EXIT_GNOME_TERMINAL_NOT_INSTALLED_ERROR_CODE=102"
set "EXIT_NPM_INSTALL_ERROR_CODE=103"
set "EXIT_WEBPACK_BUILD_INSTALL_ERROR_CODE=104"
set "EXIT_MVNW_CHMOD_ERROR_CODE=105"
set "EXIT_DELETE_TARGET_FOLDER_ERROR_CODE=106"
set "EXIT_MVNW_CLEAN_ERROR_CODE=107"
set "EXIT_WEB_FRONT_END_BUILD_ERROR_CODE=108"
set "EXIT_JAVA_WEB_SERVER_BUILD_ERROR_CODE=109"

set "output_tmp_file=.appbrahma-server-build-n-run.tmp"
set "child1_output_tmp_file=.appbrahma-server-build-n-run-child-1.tmp"

:: arguments
:: usage <script_name> build/rebuild http/https
set "build_rebuild=%1"
set "server_rest_api_mode=%2"
set /A "arg_count=0"

:: args count
for %%g in (%*) do (
	set /A arg_count+=1
)
if !arg_count! LSS 2 ( 
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Invalid arguments supplied to the script^^!	
	echo.
	echo Usage:			
	echo 	apb-windows-server-build-n-run-mvn.bat ^<build_task_type^> ^<server_protocol^>
	echo 	Example 1 : "apb-windows-server-build-n-run-mvn.bat build http"
	echo 	Example 2 : "apb-windows-server-build-n-run-mvn.bat build https"
	echo 	Example 3 : "apb-windows-server-build-n-run-mvn.bat rebuild http"
	echo 	Example 4 : "apb-windows-server-build-n-run-mvn.bat rebuild https"
	exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%		
)

:: clear the screen for better visibility
cls
if exist !output_tmp_file! (
	for /F "tokens=*" %%G in ('del /F !output_tmp_file!' ) do (									
		set "del_result=%%G"
	)		
) 
if exist !child1_output_tmp_file! (
	for /F "tokens=*" %%G in ('del /F !child1_output_tmp_file!' ) do (									
		set "del_result=%%G"
	)		
) 

echo ==========================================================================================================================================
echo 				Welcome to %MOBILE_GENERATOR_NAME% Unimobile app build and run script for development and testing - non-production
echo Sit back, relax, and sip a cup of coffee while the dependencies are downloaded, project is built, and run. 
echo Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-^)
echo ==========================================================================================================================================
echo.


if "!build_rebuild!" == "rebuild" (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Rebuild is requested. Cleaning the project for the rebuild...
	if exist node_modules\ (
		call rmdir /S /Q "node_modules"  > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing node_modules directory for rebuilding^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
			exit /b %EXIT_PROJ_REBUILD_ERROR_CODE%
		)
	)
	if exist target\ (
		call rmdir /S /Q "target"  > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing target directory for rebuilding^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
			exit /b %EXIT_PROJ_REBUILD_ERROR_CODE%
		)
	)	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Project successfully cleaned.
)

echo %MOBILE_GENERATOR_LINE_PREFIX% : Installing nodejs dependencies...			
call npm install > "!output_tmp_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error installing nodejs dependencies^!
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Fixing the errors...
	call rmdir /S /Q "node_modules" > "!output_tmp_file!" 2>&1			
	if !ERRORLEVEL! NEQ 0  (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing node_modules for fixing dependencies install errors^^!	
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
		exit /b %EXIT_NPM_INSTALL_ERROR_CODE%
	) else (				
		:: echo %MOBILE_GENERATOR_LINE_PREFIX% : Fixing nodejs dependencies installation errors...
		call :npm_reinstall
		if !ERRORLEVEL! NEQ 0 (
			set "exit_code=!ERRORLEVEL!"
			exit /b !exit_code!
		) 
	)			
) 

echo %MOBILE_GENERATOR_LINE_PREFIX% : Building web front-end...
call npm run webapp:build > "!output_tmp_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error building the web front-end^^!
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details below. Please re-run this script after fixixng the reported errors.
	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
	exit /b %EXIT_WEB_FRONT_END_BUILD_ERROR_CODE%			
) 

echo %MOBILE_GENERATOR_LINE_PREFIX% : Building java web server...
call ./mvnw > "!output_tmp_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error building the java web server^^!
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details below. Please re-run this script after fixixng the reported errors.
	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
	exit /b %EXIT_JAVA_WEB_SERVER_BUILD_ERROR_CODE%			
) 


exit /b 0

:npm_reinstall	
	setlocal EnableDelayedExpansion	
	call npm install  > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Re-attempt to install nodejs dependencies resulted in error^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting Unimobile build and run process.
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing these issues.		
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 		
		exit /b %EXIT_NPM_INSTALL_ERROR_CODE%		
	) else ( 		
		exit /b 0
	)
	exit /b !ERRORLEVEL!	
endlocal
