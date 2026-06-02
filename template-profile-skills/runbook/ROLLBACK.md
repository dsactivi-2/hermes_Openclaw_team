# ROLLBACK — Rollback-Prozeduren

## Rollback-Typen

| Typ | Methode | Datenverlust | Dauer |
|-----|---------|-------------|-------|
| Git | `git revert` | Kein | 1min |
| Config | Config revert | Kein | 2min |
| Docker | `docker compose down` + altes Image | Container-State | 5min |
| k3s | `kubectl rollout undo` | Kein | 2min |
| Borg | `borg extract` | Backup-Alter | 10-60min |

## Git Rollback

```bash
cd /root/project/template-profile-skills
git revert HEAD --no-edit
git push
```

## Config Rollback

```bash
# Vorher aktuelle Config sichern
cp ~/.hermes/profiles/<profil>/config.yaml{,.bak}

# Revert
cp ~/.hermes/profiles/<profil>/config.yaml.bak ~/.hermes/profiles/<profil>/config.yaml

# Gateway neustarten
hermes -p <profil> gateway restart
```

## Docker Rollback

```bash
cd /opt/<app>
docker compose down
# Alte Version starten
docker compose up -d
```

## k3s Rollback

```bash
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

## Borg Restore

```bash
# Letztes Backup finden
borg list /pfad/zum/repo

# Extrahieren
borg extract /pfad/zum/repo::<backup-name>

# Validieren
systemctl is-active <service>
```

## Wann NICHT rollbacken

- **Datenbank-Migration vorwärts** → forward fix, kein revert
- **API-Key-Rotation** → neuen Key setzen, nicht alten
- **DNS-Änderungen** → warten bis propagated