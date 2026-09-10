# Configuração do JSONBin.io

O CRUD utiliza `ProductRepository`, com `JSONBIN_INDEX_BIN_ID` e
`JSONBIN_ACCESS_KEY`. O catálogo é lido com GET e gravado com PUT;
a exclusão de um produto atualiza a lista no mesmo bin.

Consulte [CATALOGO_JSONBIN.md](CATALOGO_JSONBIN.md) para o formato do catálogo,
a migração de dados antigos e a execução pelo VS Code.

Para executar pelo terminal:

```powershell
flutter run --dart-define-from-file=jsonbin.local.json
```

Crie o arquivo local a partir de `jsonbin.example.json` e preencha os valores.
O arquivo local é ignorado pelo Git e não deve ser compartilhado.
