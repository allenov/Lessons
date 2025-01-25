### Презентация: Основы Kubernetes

#### Введение
Kubernetes — это платформа для оркестрации контейнеров, которая автоматизирует развёртывание, масштабирование и управление контейнеризованными приложениями. Основная идея Kubernetes — управление вашими приложениями в виде микросервисов, разделённых на компоненты и изолированных друг от друга.

#### "Пять бинарей Kubernetes"
1. **kube-apiserver** — центральный компонент управления, через который взаимодействуют все остальные элементы. Это основной API для работы с кластером.
2. **kube-scheduler** — отвечает за планирование Pod’ов (единиц работы в Kubernetes) на узлах.
3. **kube-controller-manager** — управляет различными контроллерами, которые следят за состоянием кластера (например, ReplicationController, NodeController).
4. **kubelet** — агент, который работает на каждом узле (Node) и управляет жизненным циклом Pod’ов.
5. **etcd** — распределённое хранилище всех данных о состоянии кластера.


6. **kube-proxy** — реализует сетевую логику для сервисов, обеспечивая доступ к Pod'ам.



  ![Выбираем os](/lessons-three-kubernetes/images/image1.png)


#### Основные компоненты и их взаимодействие
- **Master Node**
  - Содержит компоненты управления (API server, Scheduler, Controller Manager и др.).
- **Worker Node**
  - Содержит kubelet и kube-proxy.
  - Запускает Pod'ы.
- **Etcd**
  - Хранилище всех данных о состоянии кластера.

### Взаимодействие:
1. Пользователь отправляет запрос через `kubectl` или UI.
2. Запрос идет к `kube-apiserver`, который взаимодействует с `etcd` для сохранения состояния.
3. `kube-scheduler` назначает под на узел.
4. `kubelet` запускает контейнеры и следит за их состоянием.


![Диаграмма взаимодействия компонентов Kubernetes](https://kubernetes.io/docs/images/components-of-kubernetes.svg)

#### Подробно о Pod, Service, Ingress, ConfigMap и Secrets

1. **Pod**
   - Минимальная единица развертывания в Kubernetes.
   - Может содержать один или несколько контейнеров, которые работают совместно (обычно один контейнер), разделяя сеть и дисковую подсистему.

Пример Pod:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: nginx-container
    image: nginx:1.21
    ports:
    - containerPort: 80
```

2. **Service**
   - Позволяет организовать доступ к Pod'ам.
   - Типы сервисов:
     - **ClusterIP** — доступ внутри кластера.
     - **NodePort** — доступ извне через определённый порт.
     - **LoadBalancer** — интеграция с балансировщиками облачных провайдеров.

Пример Service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
spec:
  selector:
    app: example-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

3. **Ingress**
   - Управляет HTTP/HTTPS-трафиком.
   - Позволяет настраивать маршрутизацию запросов к различным сервисам.

Пример Ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

4. **ConfigMap**
   - Используется для хранения конфигурационных данных в виде пар ключ-значение.
   - Позволяет передавать данные в контейнеры без необходимости изменения образа.

Пример ConfigMap:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-configmap
  namespace: default
data:
  APP_ENV: production
  APP_DEBUG: "false"
```

Использование ConfigMap в Pod:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-configmap
spec:
  containers:
  - name: example-container
    image: nginx
    env:
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: example-configmap
          key: APP_ENV
```

Использование ConfigMap в Deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-configmap
spec:
  replicas: 2
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
      - name: config-container
        image: nginx
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: example-configmap
              key: APP_ENV
```

5. **Secrets**
   - Используется для безопасного хранения конфиденциальных данных, таких как пароли, токены и ключи шифрования.
   - Данные шифруются при хранении в etcd.

Пример Secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: example-secret
type: Opaque
data:
  username: YWRtaW4=
  password: cGFzc3dvcmQ=
```

Использование Secret в Pod:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-secret
spec:
  containers:
  - name: example-container
    image: nginx
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: example-secret
          key: username
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: example-secret
          key: password
```

Использование Secret в Deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-secret
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secret-app
  template:
    metadata:
      labels:
        app: secret-app
    spec:
      containers:
      - name: secret-container
        image: nginx
        env:
        - name: USERNAME
          valueFrom:
            secretKeyRef:
              name: example-secret
              key: username
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: example-secret
              key: password
```


[Больше о секретах тут](https://kubernetes.io/docs/concepts/configuration/secret/)


---

#### Возможности использования переменных среды (Env)

Переменные среды (Environment Variables, env) используются для передачи данных внутрь контейнеров. Они позволяют:

- Передавать конфигурационные параметры.
- Управлять поведением приложений.
- Безопасно хранить и использовать секреты через Kubernetes Secrets.
- Легко изменять настройки без перекомпиляции образов.

Пример задания статической переменной среды в Pod:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-env
spec:
  containers:
  - name: example-container
    image: nginx
    env:
    - name: STATIC_ENV
      value: "static-value"
```

Возможности переменных среды:
1. **Static Values**: Прямое указание значения в поле `value`.
2. **ConfigMap Key Reference**: Использование значений из ConfigMap через `valueFrom.configMapKeyRef`.
3. **Secret Key Reference**: Использование значений из Secret через `valueFrom.secretKeyRef`.
4. **Подстановка системных переменных Kubernetes**: Использование `envFrom` для массового импорта всех пар ключ-значение из ConfigMap или Secret.

Пример использования `envFrom` в Deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-envfrom
spec:
  replicas: 2
  selector:
    matchLabels:
      app: envfrom-app
  template:
    metadata:
      labels:
        app: envfrom-app
    spec:
      containers:
      - name: envfrom-container
        image: nginx
        envFrom:
        - configMapRef:
            name: example-configmap
        - secretRef:
            name: example-secret
```

![Диаграмма работы Pod, Service и Ingress](https://kubernetes.io/docs/images/ingress.svg)

---

#### ReplicaSet: работа с Pod
**ReplicaSet** — это контроллер, который поддерживает заданное количество Pod, обеспечивая их доступность.

Пример:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: example-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app-container
        image: nginx
        ports:
        - containerPort: 80
```

---

### Namespace в Kubernetes

Namespace — это механизм изоляции ресурсов в Kubernetes. Он используется для разделения сред, таких как разработка, тестирование и продакшн, или для управления ресурсами различных команд в одном кластере.

#### Ключевые особенности Namespace:
1. **Изоляция ресурсов**: ресурсы (Pods, Services, Secrets и др.) внутри одного Namespace не конфликтуют с аналогичными именами в другом.
2. **Управление доступом**: с помощью RBAC можно ограничивать доступ пользователей и сервисов к определённым Namespace.
3. **Организация среды**: позволяет структурировать ресурсы в кластере для упрощения управления.

#### Основные команды:
1. **Список Namespace:**
   ```bash
   kubectl get namespaces
   ```
2. **Создание Namespace:**
   ```bash
   kubectl create namespace <имя-namespace>
   ```
3. **Применение манифеста в определённом Namespace:**
   Укажите `namespace` в манифесте или используйте флаг `-n`:
   ```bash
   kubectl apply -f <file>.yaml -n <имя-namespace>
   ```
4. **Удаление Namespace:**
   ```bash
   kubectl delete namespace <имя-namespace>
   ```

#### Пример манифеста Namespace:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: example-namespace
```

Использование Namespace помогает организовать ресурсы и улучшить масштабируемость работы в Kubernetes.

---

#### Stateful и Stateless приложения
- **Stateless (бессостоянные):**
  - Не сохраняют состояние между запросами.
  - Примеры: веб-сервисы, REST API.

- **Stateful (состояния):**
  - Сохраняют состояние приложения (например, базы данных, очереди сообщений).

#### Различия StatefulSets, Deployments и DaemonSets
1. **StatefulSets**
   - Используются для управления Stateful-приложениями.
   - Поддерживает фиксированные имена Pod’ов и стабильные сетевые идентификаторы: pod-0, pod-1, pod-2.
   - Пример: базы данных, такие как Cassandra или MongoDB.

2. **Deployments**
   - Используются для управления Stateless-приложениями.
   - Поддерживает обновление и откат Pod’ов.
   - Пример: фронтенд-приложения, API-сервисы.
   - Все поды одинаковые, без строгого порядка.
   - Используется для stateless приложений.

3. **DaemonSets**
   - Гарантирует, что Pod’ы запущены на каждом узле в кластере.
   - Пример: логгеры, мониторинг.

---

### Примеры Deployment с параметрами

#### Пример 1: Базовый Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: basic-deployment
  labels:
      app: labeled-app
      tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: labeled-app
      tier: backend
  template:
    metadata:
      labels:
        app: labeled-app
        tier: backend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

- **replicas:** задаёт количество Pod, которые нужно запустить.
- **Labels:** используются для классификации объектов.
- **selector:** указывает, какие Pod управляются этим Deployment.

---

#### Пример 2: Добавление ресурсов (Limits и Requests)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-limits
spec:
  replicas: 3
  selector:
    matchLabels:
      app: labeled-app
      tier: backend
  template:
    metadata:
      labels:
        app: labeled-app
        tier: backend
    spec:
      containers:
      - name: app-container
        image: nginx
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

- **requests:** минимальное количество ресурсов, которое запрашивает Pod.
- **limits:** максимальное количество ресурсов, которое Pod может использовать.


[Прочитать про Pod Quality of Service Classes на свое усмотрение](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)


---

#### Пример 3: Affinity и Anti-Affinity
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-affinity
spec:
  replicas: 2
  selector:
    matchLabels:
      app: affinity-app
  template:
    metadata:
      labels:
        app: affinity-app
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: backend
              topologyKey: "kubernetes.io/hostname"
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: frontend
              topologyKey: "kubernetes.io/hostname"
      containers:
      - name: app-container
        image: nginx
        ports:
        - containerPort: 80
```

- **podAffinity:** назначает Pod на узлы, где уже есть Pod с определёнными метками.
- **podAntiAffinity:** предотвращает размещение Pod на узлах, где уже есть Pod с указанными метками.

---

#### Пример 4: Работа с Image и Pull Policy
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-with-image
spec:
  replicas: 1
  selector:
    matchLabels:
      app: image-app
  template:
    metadata:
      labels:
        app: image-app
    spec:
      containers:
      - name: custom-app
        image: myregistry.com/myapp:v1.2.3
        imagePullPolicy: Always
```

- **image:** задаёт образ контейнера, который будет запускаться.
- **imagePullPolicy:** определяет, как Kubernetes загружает образы:
  - **Always:** всегда загружает новый образ.
  - **IfNotPresent:** использует локальный образ, если он есть.
  - **Never:** никогда не загружает образ из реестра.

---


### Пример использования Ingress

#### Установка ingress-nginx
Перед использованием манифеста для Ingress необходимо установить контроллер ingress-nginx. Это можно сделать с помощью команды:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

#### Пример манифеста Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
      - path: /frontend(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  tls:
  - hosts:
    - example.com
    secretName: example-tls
```

#### Основные параметры Ingress
1. **rules**: Определяет маршруты для доступа к сервисам через HTTP(S).
2. **path**: Указывает путь, который должен соответствовать запросу.
3. **pathType**: Тип маршрутизации:
   - **Prefix**: Запрос совпадает с указанным префиксом.
   - **Exact**: Полное совпадение с указанным путём.
4. **annotations**:
   - **nginx.ingress.kubernetes.io/rewrite-target**: Перенаправление запросов к определённому пути.
   - **nginx.ingress.kubernetes.io/use-regex**: Позволяет использовать регулярные выражения в путях.
5. **tls**: Настройки для HTTPS. Содержит список хостов и имя секрета для сертификата.

---

#### Пример создания TLS-секрета
```bash
kubectl create secret tls example-tls \
  --cert=/path/to/cert.pem \
  --key=/path/to/key.pem
```

- **cert.pem**: сертификат для домена.
- **key.pem**: приватный ключ для сертификата.

---


#### Заключение
Kubernetes — мощный инструмент для управления контейнерными приложениями. Его возможности позволяют автоматизировать многие аспекты управления, обеспечивая масштабируемость и надёжность. Понимание компонентов Kubernetes и их взаимодействия — первый шаг к эффективной работе с платформой.

- **Limits и Requests** помогают оптимизировать использование ресурсов.
- **Affinity/Anti-Affinity** управляет размещением Pod в кластере.
- **Labels** позволяют организовать и упрощают управление ресурсами.

Что почитать для себя (оффтоп):

```
https://habr.com/ru/articles/777728/
https://habr.com/ru/articles/699074/
https://kubernetes.io/ru/docs/concepts/overview/components/
```
