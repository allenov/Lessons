#!/bin/bash

# Определяем количество процессов для создания нагрузки
target_load=100

# Создаем временную директорию для записи файлов
temp_dir=$(mktemp -d /tmp/diskload.XXXXXX)

# Функция для создания нагрузки на диск
disk_load() {
    while true; do
        # Создаем файл размером 100MB
        dd if=/dev/zero of="$temp_dir/testfile_$1" bs=1M count=100 oflag=direct status=none
        # Удаляем файл, чтобы освободить место
        rm -f "$temp_dir/testfile_$1"
    done
}

# Запускаем процессы в фоне для создания нагрузки
for i in $(seq 1 $target_load); do
    disk_load $i &
done

wait
