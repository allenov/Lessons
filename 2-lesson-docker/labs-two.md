### Практическая часть

#### Задание 1: Установка Docker
1. Установите Docker на вашу систему, следуя официальной документации для вашей операционной системы.
2. Проверьте установку, запустив команду:
   ```bash
   docker --version
   ```

#### Задание 2: Первый контейнер
1. Запустите контейнер с Ubuntu:
   ```bash
   docker run -it ubuntu bash
   ```
2. Внутри контейнера выполните несколько команд для проверки:
   ```bash
   ls
   pwd
   exit
   ```

#### Задание 3: Работа с образами
1. Загрузите образ nginx:
   ```bash
   docker pull nginx
   ```
2. Посмотрите список локальных образов:
   ```bash
   docker images
   ```

#### Задание 4: Создание и управление контейнерами
1. Запустите контейнер с nginx:
   ```bash
   docker run -d -p 8080:80 nginx
   ```
2. Проверьте работу nginx, открыв в браузере `http://localhost:8080`.
3. Посмотрите логи контейнера, чтобы убедиться, что все работает корректно:
   ```bash
   docker logs <container_id>
   ```
4. Остановите контейнер:
   ```bash
   docker stop <container_id>
   ```
5. Удалите контейнер:
   ```bash
   docker rm <container_id>
   ```

### Запуск веб-приложения с Nginx в Docker

#### Цель:
Научиться создавать Dockerfile для развертывания простого веб-приложения с использованием Nginx.

#### Шаги:

1. **Создание структуры проекта**

   Создайте структуру директорий для вашего проекта:
   ```
   my-nginx-app/
   ├── Dockerfile
   └── index.html
   ```

2. **Создание файла index.html**

   Создайте простой HTML-файл `index.html`:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>My Nginx App</title>
   </head>
   <body>
       <h1>Hello, Docker!</h1>
   </body>
   </html>
   ```

3. **Написание Dockerfile**

   Создайте `Dockerfile` в директории `my-nginx-app`:
   ```dockerfile
   # Используем официальный образ Nginx
   FROM nginx:latest

   # Копируем index.html в папку, обслуживаемую Nginx
   COPY index.html /usr/share/nginx/html/

   # Указываем порт
   EXPOSE 80
   ```

4. **Сборка Docker-образа**

   Перейдите в директорию `my-nginx-app` и выполните команду для сборки образа:
   ```bash
   docker build -t my-nginx-app .
   ```

5. **Запуск контейнера**

   Запустите контейнер на основе созданного образа:
   ```bash
   docker run -d -p 8080:80 my-nginx-app
   ```

6. **Проверка работы**

   Откройте браузер и перейдите по адресу `http://localhost:8080`. Вы должны увидеть страницу с сообщением "Hello, Docker!".

7. **Остановка контейнера**

   Чтобы остановить контейнер, выполните:
   ```bash
   docker ps  # Найдите ID контейнера
   docker stop <container_id>
   ```

### Развертывание приложения на Golang

#### Цель:
Научиться контейнеризировать и запускать простое приложение на Go.

#### Шаги:

1. **Создание структуры проекта**

   Создайте структуру директорий для вашего Go проекта:
   ```
   my-go-app/
   ├── Dockerfile
   └── main.go
   ```

2. **Создание main.go**

   Напишите простое приложение на Go, которое будет обрабатывать HTTP запросы:
   ```go
   // main.go
   package main

   import (
     "fmt"
     "net/http"
   )

   func handler(w http.ResponseWriter, r *http.Request) {
     fmt.Fprintf(w, "Hello from Go server!")
   }

   func main() {
     http.HandleFunc("/", handler)
     fmt.Println("Server is running on http://localhost:8080")
     http.ListenAndServe(":8080", nil)
   }
   ```

3. **Создание Dockerfile**

   Создайте `Dockerfile` для Go приложения:
   ```dockerfile
   # Используем официальный образ Golang
   FROM golang:1.17

   # Создаем рабочую директорию
   WORKDIR /app

   # Копируем код приложения
   COPY . .

   # Компилируем приложение
   RUN go build -o my-go-app

   # Указываем порт
   EXPOSE 8080

   # Запускаем приложение
   CMD ["./my-go-app"]
   ```

4. **Сборка и запуск контейнера**

   Перейдите в директорию `my-go-app` и выполните команды для сборки и запуска контейнера:

   ```bash
   docker build -t my-go-app .
   docker run -d -p 8080:8080 my-go-app
   ```

5. **Проверка работы**

   Откройте браузер и перейдите по адресу `http://localhost:8080`. Вы должны увидеть сообщение "Hello from Go server!".