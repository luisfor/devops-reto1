#!/bin/bash
echo "=== INICIANDO APIS MOCK Y FLASK ==="
java -jar ../wiremock-standalone-3.12.0.jar --port 9090 --root-dir ../ > /dev/null 2>&1 &
WPID=$!

export FLASK_APP=app/api.py
python3 -m flask run -p 5001 > /dev/null 2>&1 &
FPID=$!

sleep 3 # Dar tiempo a que arranquen

echo "=== INICIANDO PRUEBAS ==="
python3 -m pytest test/ > test_output.txt 2>&1
echo "=== PRUEBAS FINALIZADAS ==="

kill $WPID
kill $FPID
