
@echo off

:: Run all commands using this script's directory as the working directory
cd %~dp0

:: copy over the first line from environment.yaml, e.g. name: copilot, and take the second word after splitting by ":" delimiter
for /F "tokens=2 delims=: " %%i in (environment.yaml) DO (
  set v_conda_env_name=%%i
  goto EOL
)
:EOL
echo Environment name is set as %v_conda_env_name% as per environment.yaml

:: Put the path to conda directory in a file called "custom-conda-path.txt" if it's installed at non-standard path
IF EXIST custom-conda-path.txt (
  FOR /F %%i IN (custom-conda-path.txt) DO set v_custom_path=%%i
)

set v_paths=%ProgramData%\miniconda3
set v_paths=%v_paths%;%USERPROFILE%\miniconda3
set v_paths=%v_paths%;%ProgramData%\anaconda3
set v_paths=%v_paths%;%USERPROFILE%\anaconda3


for %%a in (%v_paths%) do (
  IF NOT "%v_custom_path%"=="" (
    set v_paths=%v_custom_path%;%v_paths%
  )
)

for %%a in (%v_paths%) do (
  if EXIST "%%a\Scripts\activate.bat" (
    SET v_conda_path=%%a
    echo anaconda3/miniconda3 detected in %%a
    goto :CONDA_FOUND
  )
)

IF "%v_conda_path%"=="" (
  echo anaconda3/miniconda3 not found. Install from here https://docs.conda.io/en/latest/miniconda.html
  pause
  exit /b 1
)

:CONDA_FOUND
call "%v_conda_path%\Scripts\activate.bat"

:: Check the hash of the environment.yaml file and compare it with the hash stored in the file "environment.yaml.hash".
:: The sha256 hash is extracted from certutil output by using the second line only.
:: Store the last and the current hash in variables v_last_hash and v_cur_hash respectively.

set v_last_hash=
set v_cur_hash=

IF EXIST environment.yaml.hash (
  for /F "skip=1 tokens=1 delims=:" %%i in (environment.yaml.hash) DO (
    set v_last_hash=%%i
    goto EOL_LAST_HASH
  )
)
:EOL_LAST_HASH

certutil -hashfile environment.yaml sha256 > environment.yaml.hash
for /F "skip=1 tokens=1 delims=:" %%i in (environment.yaml.hash) DO (
  set v_cur_hash=%%i
  goto EOL_CUR_HASH
)
:EOL_CUR_HASH

echo Current  environment.yaml hash: %v_cur_hash%
echo Previous environment.yaml hash: %v_last_hash%

:: If the hashes are different, then recreate the environment
if "%v_last_hash%" == "%v_cur_hash%" (
  echo environment.yaml unchanged. dependencies should be up to date.
  echo if you still have unresolved dependencies, delete "environment.yaml.hash" 
  echo and run this script again.
) else (
  echo environment.yaml changed. updating dependencies
  call conda env create --name "%v_conda_env_name%" -f environment.yaml
  call conda env update --name "%v_conda_env_name%" -f environment.yaml
)

call "%v_conda_path%\Scripts\activate.bat" "%v_conda_env_name%"

cmd

