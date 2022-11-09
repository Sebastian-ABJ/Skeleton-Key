cls
@pushd %~dp0
@echo	--------------------------------------------------------------------------
@echo	--------------------------------------------------------------------------
@echo	---        			 Password Reset			       ---
@echo	---          			  (Ver. 0.9)           	       	       ---
@echo	---    			   Made by Sebastian Jones     		       ---
@echo	--------------------------------------------------------------------------
@echo	--------------------------------------------------------------------------
@echo.
@echo.
@echo off

fsutil dirty query %systemdrive% >nul
if %errorlevel% == 0 goto :NextStep
@echo	You must run this tool as Administrator. Press any key to exit...
pause > nul
exit

:NextStep
@echo.
@echo As a standard disclaimer, this tool modifies registry entries and as such,
@echo should be used only as a last resort. If possible, it is recommended to
@echo back up the registry before continuing or proceed at your own risk.
@echo.
@echo Which operation do you want to perform?
@echo 1. Opening the backdoor
@echo 2. Resetting a user password (backdoor already opened)
set /p choice=Enter a selection: 

if NOT %choice% == 1 ( 
	if NOT %choice% == 2 goto :NextStep
)

if %choice% == 1 goto :Opening
if %choice% == 2 goto :ResetPassword

:Opening
@echo.
set /p online=Is the target Windows OS already mounted? (Y/N):
if %online% == N (goto OfflineBackdoor)
if NOT %online% == N (
	if %online% == n goto OfflineBackdoor
)
if %online% == Y (goto OnlineBackdoor)
if NOT %online% == Y (
	if %online% == y goto OnlineBackdoor
)

:OnlineBackdoor
@echo.
@echo Modifying registry...
timeout /nobreak 1 > NUL

@echo.
@echo Injecting cmd.exe to CmdLine entry...
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v CmdLine /t REG_SZ /f /d cmd.exe
timeout /nobreak 1 > NUL

@echo.
@echo Enabling CmdLine entry to be run before login service...
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v SetupType /t REG_DWORD /f /d 2
timeout /nobreak 1 > NUL


@echo.
@echo Completed! After performing password changes, make sure to rerun this
@echo tool to close the backdoor.
@echo System will restart after hitting a key.
pause > nul
shutdown /r -t 0
goto eof

:OfflineBackdoor
set /p targetVol=Specify the target Windows drive letter: 

set /p confirm=Confirm target Windows install is located on letter %targetVol%: (Y/N) 
@echo.
if NOT %confirm% == Y (
	if NOT %confirm% == y goto OfflineBackdoor
)
timeout /nobreak 1 > NUL

@echo Navigating to Windows volume...
%targetVol%:
@echo.
timeout /nobreak 1 > NUL

@echo Finding System registry hive...
cd Windows\System32\config
@echo.
timeout /nobreak 1 > NUL

@echo Mounting hive...
REG LOAD HKEY_LOCAL_MACHINE\temp system
@echo.
timeout /nobreak 1 > NUL

@echo Modifying registry...
timeout /nobreak 1 > NUL

@echo.
@echo Injecting cmd.exe to CmdLine entry...
REG ADD HKEY_LOCAL_MACHINE\temp\Setup /v CmdLine /t REG_SZ /f /d cmd.exe
timeout /nobreak 1 > NUL

@echo.
@echo Enabling CmdLine entry to be run before login service...
REG ADD HKEY_LOCAL_MACHINE\temp\Setup /v SetupType /t REG_DWORD /f /d 2
timeout /nobreak 1 > NUL

@echo.
@echo Completed! Command Prompt will now launch before the login service has loaded.
@echo Rerun this tool after rebooting to assist in resetting any offline user's password.
set /p reboot=Press Enter to reboot the system.
shutdown /r -t 0
goto eof

:ResetPassword
@echo.
@echo Listing users...
net users

@echo.
set /p targetUser=Which user do you want to reset the password for?
@echo Attempting to reset user's password to [ password ]

@echo.
timeout /nobreak 1 > NUL
net users %targetUser% password

:Continue
@echo.
timeout /nobreak 1 > NUL
set /p continue=Do you wish to reset another password? (Y/N)

if NOT %continue% == N (
	if NOT %continue% == n goto ResetPassword
)

@echo.
@echo Restoring registry...
timeout /nobreak 1 > NUL

@echo.
@echo Removing cmd.exe from CmdLine entry...
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v CmdLine /t REG_SZ /f /d /ve
timeout /nobreak 1 > NUL

@echo.
@echo Disabling CmdLine entry to be run before login service...
REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup /v SetupType /t REG_DWORD /f /d 0
timeout /nobreak 1 > NUL

@echo.
@echo Completed! Login will resume after hitting a key.
pause > nul
exit