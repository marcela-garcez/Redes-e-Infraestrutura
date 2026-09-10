# Redes e Infraestrutura

Aplicativo Flutter de catálogo de equipamentos de rede. Mantém autenticação e
perfil no Firebase e oferece um CRUD REST de produtos no menu **CRUD API**.

## Executar

```powershell
flutter pub get
flutter run --dart-define=JSONBIN_INDEX_BIN_ID=SEU_BIN_DE_INDICE --dart-define=JSONBIN_ACCESS_KEY=SUA_ACCESS_KEY
```

Consulte [JSONBIN_SETUP.md](JSONBIN_SETUP.md) para configurar o JSONBin.io sem
incluir credenciais no repositório.

## Verificações

```powershell
flutter analyze
flutter test
```
