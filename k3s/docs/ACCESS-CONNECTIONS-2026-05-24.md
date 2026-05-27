# Access and Connection Map - 2026-05-24

Diese Datei dokumentiert nur nicht-geheime Zugangs- und Verbindungswege. Sie
enthaelt keine Passwoerter, Tokens, Kubeconfigs oder privaten SSH-Key-Inhalte.

Review 2026-05-24: Datei enthaelt nach Sichtpruefung nur nicht-geheime
Zugangs-/Verbindungsmetadaten; keine Passwoerter, Tokens, Kubeconfig-Inhalte
oder privaten SSH-Key-Inhalte.

## SSH Aliases

| Ziel | Zweck | Hostname/IP | Benutzer | Alias | Hinweis |
| --- | --- | --- | --- | --- | --- |
| Server 1 | Kubernetes-/kubectl-Hauptzugang | `88.99.215.210` | `root` | `k3-1` | nutzt lokal den bekannten `mujo`-Key laut SSH-Config |
| Server 2 | OS-Restic-/Node-Pruefung | `178.63.12.52` | `root` | `kube3-2` | vom User am 2026-05-24 getestet und als funktionierend gemeldet |
| Server 3 | OS-Restic-/Node-Pruefung | `167.235.6.160` | `root` | kein verbindlicher Alias dokumentiert | bekannter lokaler Key: `/Users/activi/.ssh/k3-3` |

## Kubernetes Private Network

| Node | Hostname | Private IP | Interface | Rolle |
| --- | --- | --- | --- | --- |
| Server 1 | `activi-k3-1.0` | `10.0.1.10` | `enp41s0.4000` | control-plane/etcd/master |
| Server 2 | `activi-k3-2` | `10.0.1.20` | `enp41s0.4000` | control-plane/etcd/master |
| Server 3 | `activi-k3-3` | `10.0.1.30` | `enp7s0.4000` | control-plane/etcd/master |

## Public Service Access

| Dienst | URL | Route |
| --- | --- | --- |
| Portainer Business | `https://portainer.activi.io` | Cloudflare DNS `portainer.activi.io -> 88.99.215.210`, ingress-nginx, cert-manager TLS |
| Kubernetes API intern | `https://10.43.0.1:443` | Kubernetes Service verteilt auf die API-Server `10.0.1.10:6443`, `10.0.1.20:6443`, `10.0.1.30:6443` |

## Verification Defaults

Die lokalen Pruefscripte verwenden ab 2026-05-24:

```text
Server 1: k3-1
Server 2: kube3-2
Server 3: root@167.235.6.160, mit /Users/activi/.ssh/k3-3 falls lesbar
```

Wenn `kube3-2` nicht funktioniert, nicht auf andere Keys raten. Dann stoppen
und die lokale SSH-Config/Key-Lage nur als Metadaten melden.
