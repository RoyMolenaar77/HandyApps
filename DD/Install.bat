ECHO OFF
CLS

REM ========================================
REM Installs the windows Service
REM at post-build or de-installs this
REM at pre-build.
REM ========================================
ECHO.
ECHO Start
ECHO.

SET lvEXE="C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
SET lvASM=".\DistributedDeployment\bin\Release\DD.exe
SET lvSRV=""

IF "%1"=="/U" GOTO uninstallbatch
IF "%1"=="/I" GOTO installbatch
IF "%1"=="/R" GOTO restartbatch
GOTO helptext

:uninstallbatch
ECHO Uninstalling the service %lvSRV%
rem NET STOP %lvSRV% 
%lvEXE% /u %lvASM%
GOTO endofbatch

:installbatch
ECHO Installing the service %lvSRV%
%lvEXE% /listen=5555 /token=YourS3cur!tyTok3n /i %lvASM% 
ECHO.
rem ECHO The service is succesfully installed. Attempting to start the service.
rem NET START %lvSRV% 
GOTO endofbatch

:restartbatch
ECHO Restarting the service %lvSRV%
NET STOP %lvSRV%
ECHO.
ECHO The service is succesfully stopped. Attempting to start the service.
ECHO.
NET START %lvSRV% 
ECHO.
ECHO The service is succesfully started.
GOTO endofbatch

:helptext
ECHO To install %lvASM% run this file with parameter /I.
ECHO To un-install the service, run this file with parameter /U.
ECHO To restart the service, run this file with parameter /R.
ECHO Otherwise this text is shown.
GOTO endofbatch

:endofbatch
SET lvEXE=
SET lvASM=
SET lvSRV=

ECHO.
ECHO Finished.
ECHO.

ECHO ON
