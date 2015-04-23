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

SET TeamCity.Artifact=""
SET FTP.SERVERNAME=concentrator.basgroup.nl
SET FTP.USERNAME=ConcentratorTest
SET FTP.PASSWORD=cheGefr2
SET FTP.REMOTE.DIRECTORY=%IP%_%PORT%
SET SQL.DATABASE.HOST=10.172.26.5
SET SQL.DATABASE.USERNAME=Concentrator_Usr
SET SQL.DATABASE.PASSWORD=c0nc3ntT12
SET SQL.DATABASE.NAME=Concentrator_staging_master
SET SPIDER.PACKAGE=spider.zip

SET Host.BackupEnvironment=c:\Concentrator
SET Host.BackupFolderPath=c:\Concentrator\Backups
SET Host.TargetFolderName=Host
SET Host.TargetFolderPath=c:\Concentrator\Host6666
SET Host.ServiceName="DeployAgent 172.crq343rqv43v4316.34.197:5555"
SET Host.ImageName=Concentrator.Host.exe
SET MANAGEMENT.WEB.NAME="Default Web Site"

REM ****************************************************************************************************


For /f "tokens=1-2 delims=/ " %%a in ('date /t') do (set mydate=%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b)

if not exist %Environment.ExecutingFolder% mkdir %Environment.ExecutingFolder%\Artifacts

CD /D %Environment.ExecutingFolder%

Echo ******************************* Header ******************************* >>log.txt
echo %cd%>>log.txt
echo DATE: %mydate%_%mytime% >> log.txt
Echo IP: %IP% >>log.txt
Echo PORT: %PORT% >>log.txt

:FTP

Echo ****************** Get latest artifact from FTP ********************** >>log.txt
@echo off
echo open %FTP.SERVERNAME%>>ftpcmd.dat
echo user %FTP.USERNAME%>>ftpcmd.dat
echo %FTP.PASSWORD%>>ftpcmd.dat
echo hash>>ftpcmd.dat
echo cd %FTP.REMOTE.DIRECTORY%>>ftpcmd.dat
echo mget *.zip>>ftpcmd.dat
echo mdelete *.zip>>ftpcmd.dat
echo cd ..>>ftpcmd.dat
echo rmdir %FTP.REMOTE.DIRECTORY%>>ftpcmd.dat
echo bye>>ftpcmd.dat
echo Launch FTP and pass it to the script>>log.txt
ftp -n -i -s:ftpcmd.dat >>log.txt

echo Clean up FTP inlog script>>log.txt
del ftpcmd.dat

ECHO Found following artifact>>log.txt
DIR /B *zip>>log.txt
for /F %%a in ('dir /b *.zip') do set TeamCity.Artifact=%%~nxa

:EXTRACT

Echo ************ Extract the artifact to folder __Temp ******************* >>log.txt
ren %TeamCity.Artifact% %SPIDER.PACKAGE%>>log.txt
%Environment.7zip% x -r -y -o__Temp_concentrator %SPIDER.PACKAGE%>>log.txt

:MOVE

Echo ************************ Store the artifactTemp ********************** >>log.txt
MOVE /Y %SPIDER.PACKAGE% Artifacts\>>log.txt

:BACKUP

Echo ************ Backup current service folder *************************** >>log.txt

for %%a in (%Host.TargetFolderPath%) do set Temp.LastDate=%%~ta
SET Temp.LastDate=%Temp.LastDate:~6,4%-%Temp.LastDate:~0,2%-%Temp.LastDate:~3,2% %Temp.LastDate:~11,2%%Temp.LastDate:~14,2%%Temp.LastDate:~17,2%
robocopy %Host.TargetFolderPath% "%Host.BackupFolderPath%\Concentrator.%mydate%_%mytime%" /e /mir /np /b /tee /log:backup.txt

:CHECK

Echo ******* Determine if host service is installed *********************** >>log.txt
SC QUERY %Host.ServiceName%> NUL
IF ERRORLEVEL 1060 GOTO DEPLOY
ECHO %Host.ServiceName% is installed.>>log.txt

:STOP

Echo ************ Stop %Host.ServiceName% service ************************* >>log.txt
rem DD --stop=%Host.ServiceName% --wait=50
rem net stop %Host.ServiceName%
rem ECHO Wait 30 more seconds
rem ping 1.1.1.1 -n 1 -w 30000 > NUL
rem pause

:DEPLOY

ECHO %Host.ServiceName% is missing.>>log.txt
ECHO Copying the Host package to the Host Target directory.. >>log.txt
ECHO ************ Deploy new files and copy over old configs ************** >>log.txt
robocopy __Temp_concentrator\TeamCity\buildAgent\work\915df5694b81467f %Host.TargetFolderPath% /e /mir /np /b /tee /log:Deploy.txt

:INSTALL

ECHO Installing the service %Host.ServiceName%>>log.txt
rem %Environment.InstallUtil% /i %Environment.ExecutingFolder%\PathToHost >>log.txt

:START

Echo ************ Start %Host.ServiceName% service ************************ >>log.txt
rem net start %Host.ServiceName% 

:WEB

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

GOTO EXIT

:SQL

Echo ************ Update database with all sql scripts ******************** >>log.txt
for %%f in (__Temp_concentrator\SqlScripts\*.sql) do %Environment.SQL.COMMAND% -S %SQL.DATABASE.HOST% -U %SQL.DATABASE.USERNAME% -P %SQL.DATABASE.PASSWORD% -d %SQL.DATABASE.NAME% -i "%%f"

Echo ************ Cleanup ************************************************* >>log.txt
::DEL /F /Q /S *jsessionid*
RD /S /Q __Temp_concentrator
ENDLOCAL
rem pause

:EXIT

Echo End of process.. >>log.txt




