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



![Диаграмма взаимодействия компонентов Kubernetes](/lessons-three-kubernetes/images/image1.png)


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
5. В фоновом режиме kube-controller-manager следит за состоянием кластера и корректирует его, если что-то отклоняется от целевого состояния (например, добавляет недостающие реплики подов).


#### Подробно о Pod, Service, Ingress, ConfigMap и Secrets

![Диаграмма работы Service и Ingress](/lessons-three-kubernetes/images/image2.png)

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

Поле kind — это одно из полей в метаданных манифеста ресурса, которое определяет, к какому типу относится описываемый объект./n
Поле spec в манифестах ресурсов является ключевым элементом для описания конфигурации и состояния объекта. Оно определяет, как должен выглядеть и функционировать объект, который вы хотите создать или управлять в кластере.
Поле spec представляет собой специфическую настройку для каждого типа объекта (например, пода, развертывания, сервиса и т. д.) и содержит параметры, которые определяют, как этот объект будет работать. Структура и содержимое поля spec зависит от типа объекта, поскольку для разных типов ресурсов Kubernetes требуются разные параметры.

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

<details>
<summary>Labels</summary>

В Kubernetes метки (labels) играют ключевую роль в организации и управлении ресурсами, такими как Pods, Deployments, Services и другими объектами. Labels позволяют эффективно управлять группами объектов и применять различные действия к этим группам. Давайте рассмотрим, как метки (labels) используются в различных контекстах, таких как Pods, Selectors, MatchLabels и Template.

![Labels](/lessons-three-kubernetes/images/image3.png)

### 1. **Mетки в Pod**
   Метки в **Pod** являются важными для их идентификации и фильтрации в пределах кластера. Они определяют атрибуты Pod, которые могут быть использованы для различных целей, таких как:

   - **Группировка**: Метки помогают объединять Pods по каким-то характеристикам, например, версии приложения, окружению (prod, dev) или типу трафика.
   - **Выборка**: Позволяют другим объектам, например, ReplicaSet или Deployment, выбирать Pods, которые соответствуют определённым меткам.
   - **Роутинг**: Для Services метки Pods используются для маршрутизации трафика к нужным экземплярам.

   Пример меток в Pod:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: my-pod
     labels:
       app: my-app
       env: production
   ```

### 2. **Selectors и MatchLabels**
   **Selector** — это способ выбора группы объектов, основанный на их метках. Они важны для объектов, таких как ReplicaSets, Deployments, Services и других, которые используют метки для того, чтобы связать объекты.

   **MatchLabels** — это подтип селектора, который использует строгие соответствия меток для выбора объектов.

   #### Применение селекторов:
   - **ReplicaSet**: Когда вы создаете ReplicaSet, метки используются в `selector`, чтобы указать, какие Pods должны управляться этим ReplicaSet.
   - **Deployment**: Deployment использует метки в `selector`, чтобы управлять Pods, поддерживая их количество на нужном уровне.
   - **Service**: Для того чтобы Service находил правильные Pods, он использует метки в `selector`.

   Пример использования `selector` и `matchLabels` в ReplicaSet:
   ```yaml
   apiVersion: apps/v1
   kind: ReplicaSet
   metadata:
     name: my-replicaset
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: my-app
     template:
       metadata:
         labels:
           app: my-app
   ```

   В этом примере, ReplicaSet с `matchLabels` выбирает Pods, у которых есть метка `app: my-app`. В шаблоне (`template`) Pods также задается эта метка, чтобы убедиться, что созданные Pods будут соответствовать условиям селектора.

### 3. **Template и метки**
   В **template** (например, в Deployment или ReplicaSet) метки важны для того, чтобы Pods, которые будут созданы, имели нужные метки. Эти метки должны соответствовать селектору, чтобы Pods были правильно управляемыми и маршрутизировались соответствующим образом.

   - В Deployment и ReplicaSet важно, чтобы метки в `template` совпадали с теми метками, которые указаны в селекторе. Это гарантирует, что система управления будет корректно отслеживать и обновлять Pods.

   Пример шаблона в Deployment с метками:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: my-deployment
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: my-app
     template:
       metadata:
         labels:
           app: my-app
           version: v1
       spec:
         containers:
           - name: my-container
             image: my-image:v1
   ```

   Здесь `matchLabels` в селекторе в Deployment выбирает Pods с меткой `app: my-app`. В шаблоне `template` также указываются эти метки для новых Pods. Это важно для того, чтобы Kubernetes знал, какие Pods управлять и обновлять.

### 4. **Зачем важны метки?**
   - **Отделение логики и управления**: Метки позволяют отделить управление инфраструктурой от бизнес-логики, позволяя организовать Pods по логическим группам (например, по версии приложения или по окружению).
   - **Маршрутизация трафика**: Services используют метки для маршрутизации запросов к подходящим Pods.
   - **Автоматизация и масштабирование**: Метки в ReplicaSet и Deployment позволяют автоматизировать масштабирование и обновления приложений.
   - **Мониторинг и управление**: Метки могут использоваться в системах мониторинга и логирования для группировки данных по приложениям, версиям или другим характеристикам.

### Важность правильного использования:
- **Точное соответствие селекторов и меток**: Если метки в селекторе не соответствуют меткам в Pod или шаблоне, Kubernetes не сможет корректно управлять Pods.
- **Обновления и развертывания**: Важно, чтобы метки в шаблонах (например, для Deployment) были актуальными для правильной работы стратегий обновления и обеспечения непрерывной работы.

Таким образом, метки в Kubernetes являются мощным инструментом для организации, управления, фильтрации и маршрутизации данных между объектами в кластере.
</details>

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

#### Пример 5: Метки (Labels) и Селекторы (Selectors)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: labeled-deployment
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
      - name: backend-container
        image: nginx
```

- **Labels:** используются для классификации объектов.
- **Selectors:** определяют, какие Pod управляются этим Deployment.

---

### Заключение
- **Limits и Requests** помогают оптимизировать использование ресурсов.
- **Affinity/Anti-Affinity** управляет размещением Pod в кластере.
- **Labels** позволяют организовать и упрощают управление ресурсами.

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


<details>
<summary>Labels</summary>

Аннотации в Kubernetes — это метаданные, которые можно прикрепить к объектам (например, подам, репликасетам, сервисам и т. д.) в кластере Kubernetes. В отличие от меток (labels), которые обычно используются для организации и выбора объектов, аннотации предоставляют более гибкую возможность хранить дополнительные данные, не используемые для фильтрации объектов.

В Kubernetes есть множество инструментов и плагинов, которые могут использовать аннотации для своей работы. Например, как выше появляется новый функционал.
</details>
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



Что почитать для себя:
[Больше о k8s тут 1](https://habr.com/ru/articles/777728/)
[Больше о k8s тут 2](https://habr.com/ru/articles/699074/)
[Больше о k8s тут 3](https://kubernetes.io/ru/docs/concepts/overview/components/)
