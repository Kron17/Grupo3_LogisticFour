@echo off
echo Activando entorno y ejecutando servidor...
call .venv\Scripts\activate
python manage.py runserver
pause