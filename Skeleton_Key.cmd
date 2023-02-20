echo off
cls
@pushd %~dp0
@echo	--------------------------------------------------------------------------
@echo	--------------------------------------------------------------------------
@echo	---        		      	Skeleton Key			       ---
@echo	---          		        (Ver. 1.4.3)           	       	       ---
@echo	--------------------------------------------------------------------------
@echo	--------------------------------------------------------------------------
@echo.

if "%~1"=="" (goto CheckAdmin) else goto ResetPassword

:CheckAdmin
@echo %appPath%
fsutil dirty query %systemdrive% >nul
if %errorlevel% == 0 goto :NextStep
@echo	You must run this tool as Administrator. Press any key to exit...
pause > nul
exit

:NextStep
set appPath=%~dp0%Skeleton_Key.cmd
@echo.
@echo As a standard disclaimer, this tool modifies registry entries and as such,
@echo should be used only as a last resort. If possible, it is recommended to
@echo back up the registry before continuing or proceed at your own risk.
pause
@echo.

:Backdoor
set /p targetVol=Specify the target Windows drive letter: 
CALL :UpCase targetVol
set /p confirm=Confirm target Windows install is located on letter %targetVol%: (Y/N) 

@echo.
if NOT %confirm% == Y (
	if NOT %confirm% == y goto Backdoor
)

@echo Copying password reset script to OS root directory...
copy Skeleton_key.cmd %targetVol%:\Skeleton_Key.cmd
@echo.

@echo Finding SAM registry hive...
%targetVol%:
cd Windows\System32\config

@echo Mounting SAM hive...
REG LOAD HKEY_LOCAL_MACHINE\temp SAM
@echo.

set microsoftAccounts= 0

@echo Searching for Microsoft Accounts...
for /f "tokens=*" %%k in ('reg query HKEY_LOCAL_MACHINE\temp\SAM\Domains\Account\Users') do (
	REG QUERY %%k /V InternetUID >nul
	if errorlevel 1 (
		@echo Account not connected to Microsoft Account
		@echo.
	) else (
		set /a microsoftAccounts = microsoftAccounts + 1
		@echo Microsoft Account detected! Severing link...
		REG DELETE %%k\ /v InternetProviderAttributes /f
		REG DELETE %%k\ /v InternetProviderGUID /f
		REG DELETE %%k\ /v InternetProviderName /f
		REG DELETE %%k\ /v InternetSID /f
		REG DELETE %%k\ /v InternetUID /f
		REG DELETE %%k\ /v InternetUserName /f
		@echo Microsoft Account link broken!
		@echo.
	)
)
@echo	--------------------------------------------------------------------------
@echo Microsoft Account removal process completed.
@echo.

@echo Unloading SAM hive...
REG UNLOAD HKEY_LOCAL_MACHINE\temp
@echo.

@echo Mounting System hive...
REG LOAD HKEY_LOCAL_MACHINE\temp system
@echo.

@echo Enabling CMD to be run before login service...
REG ADD HKEY_LOCAL_MACHINE\temp\Setup /v SetupType /t REG_DWORD /f /d 2


@echo Injecting script to CMD entry...
REG ADD HKEY_LOCAL_MACHINE\temp\Setup /v CmdLine /t REG_SZ /f /d "cmd.exe /c C:\Skeleton_Key.cmd 1"
@echo.

@echo Unloading System hive...
REG UNLOAD HKEY_LOCAL_MACHINE\temp
@echo	--------------------------------------------------------------------------
@echo Microsoft Accounts found: %microsoftAccounts%
@echo Be sure to disable their link inside Windows after removing passwords.
@echo.
@echo Completed. It is your responsibility to verify all actions have been completed successfully.
@echo.
@echo Restart the computer into the operating system to continue. A command prompt window should open
@echo allowing you to reset user passwords before login.
@echo.

pause
exit

:ResetPassword
@echo.
@echo Listing users...
net users

@echo.
set /p targetUser=Enter username to reset password or leave blank to continue: 
echo.

@echo Attempting to remove selected user's password...

@echo.
timeout /nobreak 1 > NUL
net users "%targetUser%" ""
@echo If this was a Microsoft Account, be sure to go into the Account Info settings
@echo and disable the Microsoft Account.
@echo.

:Continue
timeout /nobreak 1 > NUL
set /p continue=Do you wish to reset another password? (Y/N) 

if NOT %continue% == N (
	if NOT %continue% == n goto ResetPassword
)


@echo Restoring registry...
timeout /nobreak 1 > NUL
@echo.

@echo Removing CMD from startup...
timeout /nobreak 1 > NUL
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v SetupType /t REG_DWORD /f /d 0
@echo.

@echo Removing script from CMD...
timeout /nobreak 1 > NUL
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v CmdLine /t REG_SZ /f

:End
@echo	--------------------------------------------------------------------------
@echo.
@echo Completed! This script will self destruct in 5 seconds...
timeout /nobreak 5 > nul
DEL "%~f0"
exit

:: For standardizing drive letter format
:UpCase
if not defined %~1 exit /b
for %%a in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "ä=Ä" "ö=Ö" "ü=Ü") do (
call set %~1=%%%~1:%%~a%%
)
goto :eof