echo off
cls
@pushd %~dp0
@echo	--------------------------------------------------------------------------
@echo	--------------------------------------------------------------------------
@echo	---        		      	Skeleton Key			       ---
@echo	---          		        (Ver. 1.7.5)           	       	       ---
@echo	--------------------------------------------------------------------------
@echo	--------------------------------------------------------------------------
@echo	---   This software is licensed under the Mozilla Public License 2.0   ---
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
@echo back up the registry before continuing and proceed at your own risk.
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

@echo	--------------------------------------------------------------------------

copy Skeleton_key.cmd %targetVol%:\Skeleton_Key.cmd > NUL
if errorlevel 1 (
	@echo Error copying script to target directory, exiting.
	goto Error
) else (
	@echo Script copied to OS root directory.
)
@echo.

%targetVol%:
cd \Windows\System32\config
if errorlevel 1 (
	@echo Could not find registry hives, exiting.
	goto Error
) else (
	@echo Registry hives found.
)
@echo.

REG LOAD HKEY_LOCAL_MACHINE\temp SAM > NUL
if errorlevel 1 (
	@echo Error mounting SAM hive. Cleaning up and exiting.
	del /q %targetVol%:\Skeleton_Key.cmd
	goto Error
)

set microsoftAccounts= 0

for /f "tokens=*" %%k in ('reg query HKEY_LOCAL_MACHINE\temp\SAM\Domains\Account\Users 2^>NUL') do (
	REG QUERY %%k /V InternetUID 2> NUL
	if errorlevel 1 (
		@echo Microsoft Account not found.
	) else (
		set /a microsoftAccounts = microsoftAccounts + 1
		@echo Microsoft Account detected! Severing link...
		REG DELETE %%k\ /v InternetProviderAttributes /f > nul
		REG DELETE %%k\ /v InternetProviderGUID /f > nul
		REG DELETE %%k\ /v InternetProviderName /f > nul
		REG DELETE %%k\ /v InternetSID /f > nul
		REG DELETE %%k\ /v InternetUID /f > nul
		REG DELETE %%k\ /v InternetUserName /f > nul
		@echo Microsoft Account link broken.
		@echo.
	)
) >NUL 2>&1
@echo Microsoft Account connections removed.
@echo.

REG UNLOAD HKEY_LOCAL_MACHINE\temp > nul

REG LOAD HKEY_LOCAL_MACHINE\temp system > nul
if errorlevel 1 (
	@echo Error mounting SYSTEM hive. Cleaning up and exiting.
	del /q %targetVol%:\Skeleton_Key.cmd
	goto Error
)

set sMode= 0
REG QUERY HKEY_LOCAL_MACHINE\temp\ControlSet001\Control\CI\Policy /V SkuPolicyRequired > NUL
if errorlevel 1 (
	@echo Unable to find Registry Key for S-Mode
) else (
	REG QUERY HKEY_LOCAL_MACHINE\temp\ControlSet001\Control\CI\Policy /V SkuPolicyRequired | Find "0x0" > NUL
	if errorlevel 1 (
		@echo S-Mode enabled. Disabling...
		set /a sMode = 1
		REG ADD HKEY_LOCAL_MACHINE\temp\ControlSet001\Control\CI\Policy /v SkuPolicyRequired /t REG_DWORD /f /d 0 > NUL
	) else (
		@echo S-Mode not enabled.
	)
)
@echo.

REG ADD HKEY_LOCAL_MACHINE\temp\Setup /v SetupType /t REG_DWORD /f /d 2 > nul
if errorlevel 1 (
	@echo Error modifying registry. Cleaning up and exiting.
	del /q %targetVol%:\Skeleton_Key.cmd
	goto Error
) else (
	@echo Enabled CMD to run at startup.
)
@echo.


REG ADD HKEY_LOCAL_MACHINE\temp\Setup /v CmdLine /t REG_SZ /f /d "cmd.exe /c C:\Skeleton_Key.cmd 1" > nul
if errorlevel 1 (
	@echo Error modifying registry. Cleaning up and exiting.
	REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v SetupType /t REG_DWORD /f /d 0
	del /q %targetVol%:\Skeleton_Key.cmd
	goto Error
) else (
	@echo Injected script into startup.
)

REG UNLOAD HKEY_LOCAL_MACHINE\temp > nul
@echo	--------------------------------------------------------------------------
@echo Completed. Next steps:
@echo.
@echo Microsoft Accounts found: %microsoftAccounts%
if NOT %microsoftAccounts% == 0 (
	@echo Remember to switch all affected accounts to local accounts.
@echo.
if %sMode% == 1 (
	@echo S-Mode was found and disabled - Turn off Secure Boot in BIOS to prevent boot looping.
	@echo.
)
@echo Restart the computer into Windows to continue.
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
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v SetupType /t REG_DWORD /f /d 0 > NUL
@echo Done.
@echo.

@echo Removing script from CMD...
timeout /nobreak 1 > NUL
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v CmdLine /t REG_SZ /f > NUL
@echo Done.

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

:Error
@echo -------------------------------------------------------------------------------
REG UNLOAD HKEY_LOCAL_MACHINE\temp > nul
del %targetVol%:\Skeleton_Key.cmd
pause