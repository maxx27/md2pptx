#!/bin/bash -e

# most probably you have to install:
# npm install -g @marp-team/marp-cli

scriptdir=$(readlink -f "$0")
scriptdir=$(dirname "$scriptdir")
cd "$scriptdir/.."

# TODO: use loop over all folders "dd. name"
# readarray -t files <<<"$(ls)"
# for file in "${files[@]}"; do echo "|$file|"; done

output=$(readlink -f "$scriptdir/../output")
[ "$output" == / ] && echo error && exit 1
# IFS= rm -rf "$output"/* 2>/dev/null || true

generate=
for d in "$scriptdir" . ../setup ../../setup ; do
    if [ -e "$d/generate.sh" ]; then
        generate=$(readlink -f "$d/generate.sh")
        break
    fi
done
[ -z $generate ] && echo generate.sh not found && exit 1

"$generate" -o "$output" -f docx -t none -i "00. Установка и настройка" -o "$output/00. Установка и настройка"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "01. Приступаем"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "02. Введение в Git"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "03. Репозиторий"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "04. Начало работы с Git"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "05. Просмотр истории"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "06. Ветвление"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "07. Применение изменений"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "08. Слияние"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "09. Git изнутри"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "10. Отмена изменений"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "11. Эффективная работа"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "12. Работа с сервером"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "13. Работа в команде"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "14. Метки"
"$generate" -o "$output" -f html -f pdf -t dark -t light -i "15. Завершаем"
