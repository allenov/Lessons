### Лабораторная работа по Kubernetes

#### Тема: Развертывание приложений в Kubernetes: Nginx, PostgreSQL и PgAdmin с использованием Ingress и StatefulSet

---

### Цель работы:

1. Освоить базовые объекты Kubernetes.
2. Научиться развертывать сервисы и управлять их доступностью через Ingress.
3. Настроить базу данных PostgreSQL и подключение к ней через PgAdmin.
4. Использовать ConfigMap и Secret для управления конфигурацией.

---

### Подготовка:

#### Шаг 1. Установка k3s

1. Установите k3s с отключением Traefik:
   ```bash
   curl -sfL https://get.k3s.io | sh -s - --disable traefik
   ```
2. Настройте переменную окружения для kubectl:
   ```bash
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   ```

#### Шаг 2. Настройка MetalLB

1. Установите MetalLB:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml
   ```
2. Создайте ConfigMap для MetalLB:
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     namespace: metallb-system
     name: config
   data:
     config: |
       address-pools:
       - name: default
         protocol: layer2
         addresses:
         - 192.168.1.240-192.168.1.250
   ```
3. Примените конфигурацию:
   ```bash
   kubectl apply -f metallb-config.yaml
   ```

#### Шаг 3. Установка Ingress-Nginx

1. Установите Ingress-Nginx без Helm:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```
2. Убедитесь, что контроллер установлен:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

---

### Задание 1: Запуск Nginx с Ingress

#### Шаг 1. Создайте Namespace для Nginx

```bash
kubectl create namespace nginx-test
```

#### Шаг 2. Создайте Deployment и Service для Nginx

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: nginx-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: nginx-test
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

#### Шаг 3. Создайте Ingress

```yaml
# nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: nginx-test
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: nginx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

#### Шаг 4. Примените манифесты и проверьте:

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-ingress.yaml
```

Настройте локальный DNS, чтобы проверить доступность по адресу `http://nginx.local`.
Добавьте в файл `/etc/hosts` для доменов `nginx.local` и их IP-адресов. Например:
```plaintext
192.168.1.240 nginx.local
```
---

### Задание 2: StatefulSet с PostgreSQL

#### Шаг 1. Создайте Namespace для PostgreSQL

```bash
kubectl create namespace postgresql
```

#### Шаг 2. Создайте Secrets и ConfigMap для PostgreSQL

Создайте два файла для Secret и ConfigMap:

```yaml
# pg-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: pg-secret
  namespace: postgresql
type: Opaque
data:
  POSTGRES_USER: YWRtaW4= # admin (base64)
  POSTGRES_PASSWORD: cGFzc3dvcmQ= # password (base64)
---
# pg-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pg-config
  namespace: postgresql
data:
  POSTGRES_DB: mydb
```

Примените манифесты:

```bash
kubectl apply -f pg-secret.yaml
kubectl apply -f pg-config.yaml
```

#### Шаг 3. Создайте StatefulSet для PostgreSQL

```yaml
# postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: postgresql
spec:
  serviceName: "postgres"
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: pg-secret
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg-secret
              key: POSTGRES_PASSWORD
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: pg-config
              key: POSTGRES_DB
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: postgresql
spec:
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
  selector:
    app: postgres
```

#### Шаг 4. Примените манифесты:

```bash
kubectl apply -f postgres-statefulset.yaml
```

---

### Задание 3: Подключение PgAdmin к PostgreSQL

#### Шаг 1. Создайте Secret для учетных данных PgAdmin

```yaml
# pgadmin-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: pgadmin-secret
  namespace: postgresql
type: Opaque
data:
  PGADMIN_DEFAULT_EMAIL: YWRtaW5AZXhhbXBsZS5jb20= # admin@example.com (base64)
  PGADMIN_DEFAULT_PASSWORD: YWRtaW4= # admin (base64)
```

Примените Secret:

```bash
kubectl apply -f pgadmin-secret.yaml
```

#### Шаг 2. Создайте Deployment и Service для PgAdmin

```yaml
# pgadmin-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgadmin
  namespace: postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pgadmin
  template:
    metadata:
      labels:
        app: pgadmin
    spec:
      containers:
      - name: pgadmin
        image: dpage/pgadmin4
        ports:
        - containerPort: 80
        env:
        - name: PGADMIN_DEFAULT_EMAIL
          valueFrom:
            secretKeyRef:
              name: pgadmin-secret
              key: PGADMIN_DEFAULT_EMAIL
        - name: PGADMIN_DEFAULT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pgadmin-secret
              key: PGADMIN_DEFAULT_PASSWORD
---
apiVersion: v1
kind: Service
metadata:
  name: pgadmin-service
  namespace: postgresql
spec:
  selector:
    app: pgadmin
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

#### Шаг 3. Создайте Ingress для PgAdmin

```yaml
# pgadmin-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pgadmin-ingress
  namespace: postgresql
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: pgadmin.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pgadmin-service
            port:
              number: 80
```

#### Шаг 4. Примените манифесты:

```bash
kubectl apply -f pgadmin-deployment.yaml
kubectl apply -f pgadmin-ingress.yaml
```

Настройте локальный DNS, чтобы проверить доступность по адресу `http://pgadmin.local`.
Добавьте в файл `/etc/hosts` для доменов `pgadmin.local` и их IP-адресов. Например:
```plaintext
192.168.1.240 pgadmin.local
```

#### Шаг 5. Настройте подключение PgAdmin к PostgreSQL

1. Откройте PgAdmin по адресу `http://pgadmin.local`.
2. Войдите с учетными данными из Secret (`admin@example.com` / `admin`).
3. Создайте новый сервер:
   - **Host**: `postgres.postgresql.svc.cluster.local`
   - **Port**: `5432`
   - **Maintenance Database**: `mydb`
   - **Username**: `admin`
   - **Password**: `password`

Теперь вы можете управлять базой данных PostgreSQL через PgAdmin.
