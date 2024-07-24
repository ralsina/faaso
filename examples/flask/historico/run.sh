#!/bin/sh
uwsgi  --plugins http,python -H venv --http 0.0.0.0:3000 --master -p 1 -w funko:app
