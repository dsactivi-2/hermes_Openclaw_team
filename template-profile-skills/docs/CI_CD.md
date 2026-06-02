# CI/CD Pipeline

## Workflow-Übersicht

```
Push/PR → Preflight Check → Deploy → Postdeploy Check → Rollback (optional)
```

## Preflight-Check (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: Preflight Check
on: [push, pull_request]

jobs:
  preflight:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate YAML Syntax
        run: |
          for f in $(find . -name "*.yaml" -o -name "*.yml"); do
            python3 -c "import yaml; yaml.safe_load(open('$f'))" || exit 1
          done
      - name: Check SOUL.md exists per agent
        run: |
          for d in profiles/teams/*/agents/*/; do
            [ -f "$d/SOUL.md" ] || { echo "MISSING: $d/SOUL.md"; exit 1; }
          done
      - name: Validate team.yaml
        run: |
          for f in profiles/teams/*/team.yaml; do
            python3 -c "
      import yaml, sys
      t = yaml.safe_load(open('$f'))
      assert 'team_name' in t, 'Missing team_name in $f'
      assert 'runtime' in t, 'Missing runtime in $f'
      assert t['runtime'] in ['hermes','openclaw','both'], 'Invalid runtime in $f'
      assert 'policy_level' in t, 'Missing policy_level in $f'
      " || exit 1
          done
      - name: Shellcheck Scripts
        run: shellcheck scripts/*.sh
        continue-on-error: true
```

## Deployment-Gates

```
1. Preflight-Check ✅
      │
      ▼
2. Manuelles Approval (nur main-Branch)
      │
      ▼
3. Deploy-Script ausführen
      │
      ▼
4. Postdeploy-Check ✅
      │
      ▼
5. Healthcheck (curl Endpoints)
```

## Versionierung

- **SemVer** auf Team/Agent-Ebene
- CHANGELOG.md pro Major-Release
- Git-Tags: `v1.0.0`, `v1.1.0`
- Breaking Changes → Major-Release + Runbook-Update

## Rollback-Trigger

| Auslöser | Aktion |
|----------|--------|
| Postdeploy-Check fehlschlägt | Auto-Rollback zuletzt known-good |
| Healthcheck 5x failed | Auto-Rollback |
| Manuelles `git revert` | Manuelles Rollback |