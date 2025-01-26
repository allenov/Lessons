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

