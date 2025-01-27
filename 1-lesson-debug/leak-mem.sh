#!/bin/bash

# Создание большой строки для заполнения памяти
leak_memory() {
    local leak=""
    while true; do
        # Добавляем 100 МБ данных к строке
        leak+=$(head -c 104857600 /dev/zero | tr '\0' 'a')
        # Уменьшаем интервал до 0.1 секунды
        sleep 0.1
    done
}

# Запуск функции
leak_memory
