@echo off

SETLOCAL
SET IP=%1
SET PORT=%2

REM ****************************************************************************************************

:: 0/ --------- Set some local variables
SET Environment.ExecutingFolder="C:\Deployment\%IP%_%PORT%"
SET Environment.7zip="C:\Program Files\7-Zip\7z.exe"
SET Environment.SQL.COMMAND="C:\PROGRA~1\MICROS~1\100\Tools\Binn\SqlCMD.exe"
SET Environment.InstallUtil="C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
SET Environment.appcmd=CALL %WINDIR%\system32\inetsrv\appcmd

rem SET TeamCity.Artifact=Release_2.6.0.240_CONCENTRATOR.zip
SET TeamCity.Artifact=Release_2.6.0.289_CONCENTRATOR.zip
SET FTP.SERVERNAME=concentrator.basgroup.nl
SET FTP.USERNAME=ConcentratorTest
SET FTP.PASSWORD=cheGefr2
SET FTP.REMOTE.DIRECTORY=%IP%_%PORT%

SET SQL.DATABASE.HOST=10.172.26.5
SET SQL.DATABASE.USERNAME=Concentrator_Usr
SET SQL.DATABASE.PASSWORD=c0nc3ntT12
SET SQL.DATABASE.NAME=Concentrator_staging_master

SET SPIDER.PACKAGE=Host.zip

SET Host.BackupFolderPath=d:\Concentrator\Backups
SET Host.TargetFolderName=Host
SET Host.TargetFolderPath=d:\Concentrator\Host
SET Host.ServiceName=""
SET Host.ImageName=Concentrator.Host.exe


SET MANAGEMENT.WEB.NAME="Default Web Site"



REM ****************************************************************************************************


For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b)

if not exist %Environment.ExecutingFolder% mkdir %Environment.ExecutingFolder%\Artifacts

CD /D %Environment.ExecutingFolder%

Echo.>>log.txt
Echo ******************************* Header ******************************* >>log.txt
echo %cd%>>log.txt
echo DATE: %mydate%_%mytime% >> log.txt
Echo IP: %IP% >>log.txt
Echo PORT: %PORT% >>log.txt
Echo.>>log.txt

rem Echo 0/ --------- Cleanup old files>>log.txt
rem del %SPIDER.PACKAGE%
rem del %TeamCity.Artifact%

Echo.>>log.txt
Echo ****************** Get latest artifact from FTP ********************** >>log.txt
@echo off
echo open %FTP.SERVERNAME%>>ftpcmd.dat
echo user %FTP.USERNAME%>>ftpcmd.dat
echo %FTP.PASSWORD%>>ftpcmd.dat
echo hash>>ftpcmd.dat
echo asc>>ftpcmd.dat
echo cd %FTP.REMOTE.DIRECTORY%>>ftpcmd.dat
echo get %TeamCity.Artifact%>>ftpcmd.dat
echo bye>>ftpcmd.dat

echo Launch FTP and pass it to the script>>log.txt
ftp -n -s:ftpcmd.dat >>log.txt

echo Clean up FTP inlog script>>log.txt
del ftpcmd.dat

ECHO Found following artifact>>log.txt
DIR /B *zip>>log.txt

Echo.>>log.txt
Echo ************ Extract the artifact to folder __Temp ******************* >>log.txt
ren %TeamCity.Artifact% %SPIDER.PACKAGE%>>log.txt
%Environment.7zip% x -r -y -o__Temp_concentrator %SPIDER.PACKAGE%>>log.txt

Echo.>>log.txt
Echo ************************ Store the artifactTemp ********************** >>log.txt
MOVE /Y %SPIDER.PACKAGE% Artifacts\>>log.txt

Echo.>>log.txt
Echo ************ Backup current service folder *************************** >>log.txt
for %%a in (%Host.TargetFolderPath%) do set Temp.LastDate=%%~ta
SET Temp.LastDate=%Temp.LastDate:~6,4%-%Temp.LastDate:~0,2%-%Temp.LastDate:~3,2% %Temp.LastDate:~11,2%%Temp.LastDate:~14,2%%Temp.LastDate:~17,2%
xcopy /f /y /s /e /k /i %Host.TargetFolderPath% "%Host.BackupFolderPath%\Concentrator.%mydate%_%mytime%">>log.txt
timeout /t 5

EXIT

Echo ******* Determine if host service is installed *********************** >>log.txt
SC QUERY %Host.ServiceName%> NUL
IF ERRORLEVEL 1060 GOTO MISSING
ECHO %Host.ServiceName% is installed.

rem Stop service
rem copy dll's
rem start service
Echo.>>log.txt
Echo ************ Stop %Host.ServiceName% service ************************* >>log.txt
rem DD --stop=%Host.ServiceName% --wait=50
net stop %Host.ServiceName%
ECHO Wait 30 more seconds
ping 1.1.1.1 -n 1 -w 30000 > NUL
rem pause

Echo.>>log.txt
Echo ************ Deploy new files and copy over old configs ************** >>log.txt
ECHO ... Deploy latest assemblies
XCOPY /E /H /R /Y __Temp_concentrator\Concentrator %Host.TargetFolderPath%


del %Host.TargetFolderPath%\Plugins\Concentrator.Plugins.Magento-OLD-VERSION-RENAME_IF_NEEDED.dll
rem pause
 
:: Concentrator - don't redeploy old configs - should be there after copy
:: ECHO ... Deploy old configs 
:: COPY /Y "%Host.TargetFolderName%.%Temp.LastDate%\*.config" %Host.TargetFolderPath%

:: Concentrator don't delete log files for now
:: ECHO ... Delete log files 
:: DEL /F /Q %Host.TargetFolderPath%\Logs\log.txt* > NUL
rem pause

GOTO START

:MISSING
ECHO %Host.ServiceName% is missing.

ECHO Installing the service %Host.ServiceName%
%Environment.InstallUtil% /i %Environment.ExecutingFolder%\PathToHost >>log.txt

rem install Host service with the new release.zip
rem start service

:START

Echo.>>log.txt
Echo ************ Start %Host.ServiceName% service ************************ >>log.txt
net start %Host.ServiceName% 
rem pause








Echo.>>log.txt
Echo ************ Determine if Management website is installed ************* >>log.txt
%Environment.appcmd% list site /name:%MANAGEMENT.WEB.NAME%
IF "%ERRORLEVEL%" EQU "0" (

	ECHO %MANAGEMENT.WEB.NAME% EXISTS
	ECHO STOPPING %MANAGEMENT.WEB.NAME%...
	
	%Environment.appcmd% stop site /site.name:%MANAGEMENT.WEB.NAME%
    REM Add your bindings here
) ELSE (
    ECHO %MANAGEMENT.WEB.NAME% NOT EXISTS
	
	ECHO CREATING %MANAGEMENT.WEB.NAME%...
	
	
)











Echo.>>log.txt
Echo ************ Update database with all sql scripts ******************** >>log.txt
for %%f in (__Temp_concentrator\SqlScripts\*.sql) do %Environment.SQL.COMMAND% -S %SQL.DATABASE.HOST% -U %SQL.DATABASE.USERNAME% -P %SQL.DATABASE.PASSWORD% -d %SQL.DATABASE.NAME% -i "%%f"

Echo.>>log.txt
Echo ************ Cleanup ************************************************* >>log.txt
::DEL /F /Q /S *jsessionid*
RD /S /Q __Temp_concentrator
ENDLOCAL
rem pause







