@echo off
echo Instalando entorno...

python -m venv .venv
call .venv\Scripts\activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python manage.py migrate

echo Instalación lista.
pause