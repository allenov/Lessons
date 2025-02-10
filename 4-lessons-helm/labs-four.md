### Урок по развертыванию k3s, GitLab и Vault с использованием локального домена volgit.local

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
# metallb.yaml
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
      - 192.168.1.140 # Укажите диапазон IP из вашей сети
```
3. Примените конфигурацию:
```bash
kubectl apply -f metallb.yaml
```

#### Шаг 3. Установка helm и ingress-nginx
1. https://helm.sh/ru/docs/intro/install/ устанавливаем helm согласно инструкции. \
```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

```
2. Установите ingress-nginx:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

Добавим в coredns наши dns записи.
```bash
kubectl -n kube-system edit configmap coredns
```
Не забудьте поменять IP на ваш.
```plaintext
192.168.1.240 volgit.local gitlab.volgit.local vault.volgit.local
```
![coredns](/4-lessons-helm/images/image1.png)

#### Шаг 4. Установка Cert-Manager
1. Установите Cert-Manager:
```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.6.1
```
2. Настройте локальный ClusterIssuer для сертификатов:
```yaml
# local-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: local-issuer
spec:
  selfSigned: {}
```
3. Примените конфигурацию:
```bash
kubectl apply -f local-issuer.yaml
```

#### Шаг 5. Развертывание GitLab
1. Подготовьте файл `gitlab-values.yaml`:
```yaml
# gitlab-values.yaml
certmanager:
  install: false

global:
  edition: ce
  hosts:
    domain: volgit.local

  ingress:
    ingressClassName: nginx
    configureCertmanager: false
    annotations:
      kubernetes.io/tls-acme: "false"
      cert-manager.io/cluster-issuer: "local-issuer"

gitlab:
  webservice:
    ingress:
      tls:
        secretName: gitlab-tls
gitlab-runner:
  install: true
  rbac:
    create: true
  volumes:
    - secret:
        secretName: gitlab-tls
      name: gitlab-tls
  volumeMounts:
    - name: gitlab-tls
      mountPath: /usr/local/share/ca-certificates/
  runners:
    locked: false
    secret: "nonempty"
    config: |
      [[runners]]
        name = "my-runner2"
        url = "https://gitlab.volgit.local"
        tls-ca-file = "/usr/local/share/ca-certificates/ca.crt"
        [runners.kubernetes]
          image = "ubuntu:22.04"

  podAnnotations:
    gitlab.com/prometheus_scrape: "true"
    gitlab.com/prometheus_port: 9252
  podSecurityContext:
    seccompProfile:
      type: "RuntimeDefault"
```
2. Установите GitLab:
```bash
helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install gitlab gitlab/gitlab --namespace gitlab --create-namespace --values gitlab-values.yaml
```
3. Получите пароль администратора:
```bash
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode ; echo
```

![Login](/4-lessons-helm/images/image2.png)

### Создадим репу.

![Create-repo](/4-lessons-helm/images/image3.png)

![Create-repo2](/4-lessons-helm/images/image4.png)


#### Примечание
Убедитесь, что в вашей системе настроен DNS или файл `/etc/hosts` для доменов `volgit.local` и их IP-адресов. Например:
```plaintext
192.168.1.240 volgit.local gitlab.volgit.local vault.volgit.local
```

#### Шаг 6. Развертывание Vault
1. Подготовьте файл `vault-values.yaml`:
```yaml
# vault-values.yaml
server:
  ingress:
    enabled: true
    hosts:
      - host: vault.volgit.local
        paths:
          - /
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: local-issuer
    tls:
      - secretName: vault-tls
        hosts:
          - vault.volgit.local
```
2. Установите Vault:
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --namespace vault --create-namespace --values vault-values.yaml
```
3. Инициализируйте Vault:
```bash
kubectl exec -it vault-0 -n vault -- /bin/sh
vault operator init
```

Тут появляются шамир ключи и токен для логина под root. Пример:
```bash
/ $ vault operator init
Unseal Key 1: 2cW+35ul4vgGQmHaYpz5DeSQzTFNrSlR/gmTKgrst9Ad
Unseal Key 2: r62jiJYNqk9vx24A1TbA9eNZue0cjNtyyB72MeYzmauN
Unseal Key 3: ZreV1bQWXiOdPiyPJl+Myp7o5fBq2bIAXgg22AxuV9aF
Unseal Key 4: TwQRS5ZaYltsk5rLz3AWrTY6Uwyr5KkwsTlHxDI4GLpS
Unseal Key 5: zEpKVY8DKHzZlW87lZ1oO9SyLQgYFOjcqkAeaW9q2nEW

Initial Root Token: Ваш токен

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

3 раза делаем команду vault operator unseal и вставляем туда ключи 3 любых разных:
```bash
/ $ vault operator unseal
Unseal Key (will be hidden):
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       fcb94845-7979-8188-a31e-d51411a9d195
Version            1.18.1
Build Date         2024-10-29T14:21:31Z
Storage Type       file
HA Enabled         false
/ $ vault operator unseal
Unseal Key (will be hidden):
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       fcb94845-7979-8188-a31e-d51411a9d195
Version            1.18.1
Build Date         2024-10-29T14:21:31Z
Storage Type       file
HA Enabled         false
/ $ vault operator unseal
Unseal Key (will be hidden):
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.18.1
Build Date      2024-10-29T14:21:31Z
Storage Type    file
Cluster Name    vault-cluster-b2298b31
Cluster ID      4893f269-b5dc-53a0-9d68-25e5b3d53148
HA Enabled      false
```

#### Примечание
Убедитесь, что в вашей системе настроен DNS или файл `/etc/hosts` для доменов `volgit.local` и их IP-адресов. Например:
```plaintext
192.168.1.240 volgit.local gitlab.volgit.local vault.volgit.local
```

### Добавление KV хранилища и секрета в Vault, создание пайплайна для GitLab CI

В этом шаге мы создадим KV хранилище для Vault, добавим секреты в **KV2** и настроим пайплайн для извлечения этих секретов с использованием root token в GitLab CI.

#### Шаг 7. Создание KV хранилища и секрета в Vault
### Можно создать из консоли или через Web-версию.
1. **Логин в Vault в cli**:

   Подключитесь к Vault:
   ```bash
   export VAULT_ADDR=https://vault.volgit.local
   export VAULT_SKIP_VERIFY=true
   vault login <root_token>
   ```

2. **Создайте секрет и хранилище KV2**:
   Создадим секрет с именем `test-vault` в пути `secret/data/test-vault`. Для этого добавим два ключа: `name=allenov` и `pass=bestpasswordinworld`. Используйте свою фамилию.

   ```bash
   vault secrets enable -path=secret kv-v2
   vault kv put secret/test-vault name=allenov pass=bestpasswordinworld
   ```
![Login-vault](/4-lessons-helm/images/image5.png)

![Create-secret-kv](/4-lessons-helm/images/image6.png)

![Create-secret-kv-2](/4-lessons-helm/images/image7.png)

![Create-secret-kv-3](/4-lessons-helm/images/image8.png)

![Create-secret-kv-3](/4-lessons-helm/images/image9.png)

![Create-secret-kv-3](/4-lessons-helm/images/image10.png)

![Create-secret-kv-3](/4-lessons-helm/images/image11.png)


#### Шаг 8. Настройка пайплайна GitLab CI

Теперь создадим пайплайн в **GitLab CI**, который будет использовать root token для извлечения секрета из Vault.

1. В репозитории GitLab создайте файл `.gitlab-ci.yml`.

![Create-pipeline](/4-lessons-helm/images/image12.png)

2. Внесите следующие шаги в `.gitlab-ci.yml`:

```yaml
stages:
  - fetch-secrets

variables:
  VAULT_ADDR: "https://vault.volgit.local"
  VAULT_TOKEN: "Ваш токен"
  VAULT_SKIP_VERIFY: "true"
fetch-secrets:
  stage: fetch-secrets
  image: hashicorp/vault:latest
  script:
    - |
      # Авторизация с использованием токена
      vault login -method=token "$VAULT_TOKEN"

      # Извлечение секретов из Vault
      echo "------------------------------------------------"
      SECRET_NAME=$(vault kv get -field=name secret/test-vault)
      SECRET_PASS=$(vault kv get -field=pass secret/test-vault)

      echo "Name: $SECRET_NAME"
      echo "Password: $SECRET_PASS"
```

![Create-pipeline-2](/4-lessons-helm/images/image13.png)
![Create-pipeline-3](/4-lessons-helm/images/image14.png)

### Пояснение:
- **VAULT_ADDR** — это адрес вашего Vault сервера.
- **VAULT_TOKEN** - токен который получили в Vault.

### Шаг 9. Запуск пайплайна

Теперь, когда пайплайн настроен, запустится автоматически в GitLab CI при вашем коммите. При каждом запуске пайплайн будет подключаться к Vault, используя **Token**, и извлекать секреты из пути `secret/data/test-vault`.

![Create-pipeline-4](/4-lessons-helm/images/image15.png)

---

Теперь у вас есть полноценная настройка для работы с Vault через **Token** и CI/CD пайплайн для автоматического извлечения секретов в GitLab.