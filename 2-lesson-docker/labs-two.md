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
3. Остановите контейнер:
   ```bash
   docker stop <container_id>
   ```
4. Удалите контейнер:
   ```bash
   docker rm <container_id>
   ```

#### Задание 5*: Исследование cgroups и namespaces
1. Запустите контейнер и войдите в его оболочку:
   ```bash
   docker run -it --rm ubuntu bash
   ```
2. В другом терминале найдите PID процесса контейнера:
   ```bash
   docker ps
   docker inspect <container_id> | grep Pid
   ```
3. Посмотрите, как cgroups и namespaces применяются к процессу контейнера:
   ```bash
   ls /proc/<pid>/ns
   cat /proc/<pid>/cgroup
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
