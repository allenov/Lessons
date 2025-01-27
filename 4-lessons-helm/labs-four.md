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
      - 192.168.1.240-192.168.1.250 # Укажите диапазон IP из вашей сети
```
3. Примените конфигурацию:
```bash
kubectl apply -f metallb.yaml
```

#### Шаг 3. Установка ingress-nginx
1. Установите ingress-nginx:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

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
# letsencrypt-prod.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: local-issuer
spec:
  selfSigned: {}
```
3. Примените конфигурацию:
```bash
kubectl apply -f letsencrypt-prod.yaml
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
vault operator unseal
```

#### Примечание
Убедитесь, что в вашей системе настроен DNS или файл `/etc/hosts` для доменов `volgit.local` и их IP-адресов. Например:
```plaintext
192.168.1.240 volgit.local gitlab.volgit.local vault.volgit.local
```

### Добавление AppRole и секрета в Vault, создание пайплайна для GitLab CI

В этом шаге мы создадим **AppRole** для Vault, добавим секреты в **KV2** и настроим пайплайн для извлечения этих секретов с использованием **AppRole** в GitLab CI.

#### Шаг 7. Создание AppRole и секрета в Vault

1. **Создайте роль AppRole в Vault**:
   В Vault используем **AppRole**, чтобы предоставлять приложениям безопасный доступ к секретам. Включим разрешения для доступа к секретам из Vault.

   Подключитесь к Vault:
   ```bash
   export VAULT_ADDR=https://vault.volgit.local
   vault login <root_token>
   ```

2. **Создайте секрет в KV2**:
   Создадим секрет с именем `test-vault` в пути `secret/data/test-vault`. Для этого добавим два ключа: `name=allenov` и `pass=bestpasswordinworld`.

   ```bash
   vault kv put secret/test-vault name=allenov pass=bestpasswordinworld
   ```

3. **Создайте AppRole**:
   Создадим роль **AppRole**, которая будет использоваться для доступа к секретам из Vault. Мы назначим роль на путь `secret/data/test-vault`.

   ```bash
   vault auth enable approle
   vault policy write app-role-policy - <<EOF
   path "secret/data/test-vault" {
     capabilities = ["read"]
   }
   EOF

   vault write auth/approle/role/test-role policies="app-role-policy" secret_id_ttl=60m token_ttl=60m token_max_ttl=120m
   ```

4. **Получите `role_id` и `secret_id`** для AppRole:
   ```bash
   vault read auth/approle/role/test-role/role-id
   vault write -f auth/approle/role/test-role/secret-id
   ```

   Сохраните `role_id` и `secret_id` для дальнейшего использования.

#### Шаг 8. Настройка пайплайна GitLab CI

Теперь создадим пайплайн в **GitLab CI**, который будет использовать **AppRole** для извлечения секрета из Vault.

1. В репозитории GitLab создайте файл `.gitlab-ci.yml`.

2. Внесите следующие шаги в `.gitlab-ci.yml`:

```yaml
stages:
  - fetch-secrets

variables:
  VAULT_ADDR: "https://vault.volgit.local"
  VAULT_ROLE_ID: "<your_role_id>"
  VAULT_SECRET_ID: "<your_secret_id>"
  VAULT_TOKEN: ""

fetch-secrets:
  stage: fetch-secrets
  script:
    - |
      # Получаем токен с помощью AppRole
      export VAULT_TOKEN=$(curl -s --request POST --data '{"role_id": "'$VAULT_ROLE_ID'", "secret_id": "'$VAULT_SECRET_ID'"}' $VAULT_ADDR/v1/auth/approle/login | jq -r .auth.client_token)

      # Извлекаем секреты
      export SECRET_NAME=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/data/test-vault | jq -r .data.data.name)
      export SECRET_PASS=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/secret/data/test-vault | jq -r .data.data.pass)

      echo "Name: $SECRET_NAME"
      echo "Password: $SECRET_PASS"
```

### Пояснение:
- **VAULT_ADDR** — это адрес вашего Vault сервера.
- **VAULT_ROLE_ID** и **VAULT_SECRET_ID** — это значения, которые вы получили при создании AppRole в Vault.
- Мы используем `curl` для получения токена с помощью **AppRole** и затем извлекаем секреты из Vault.

### Шаг 9. Запуск пайплайна

Теперь, когда пайплайн настроен, просто запустите его в GitLab CI. При каждом запуске пайплайн будет подключаться к Vault, используя **AppRole**, и извлекать секреты из пути `secret/data/test-vault`.

---

Теперь у вас есть полноценная настройка для работы с Vault через **AppRole** и CI/CD пайплайн для автоматического извлечения секретов в GitLab.