# Catálogo em um único bin

Use um bin privado com o formato abaixo. O identificador do bin continua sendo
informado em `JSONBIN_INDEX_BIN_ID` para manter a configuração existente.

```json
{
  "products": []
}
```

O aplicativo cria IDs curtos para novos produtos. Ele também lê o formato
antigo `productIds`: na próxima inclusão, alteração ou exclusão, copia os
produtos referenciados para `products` no bin do catálogo. Os bins antigos não
são apagados. Faça um backup do índice e dos produtos antes dessa migração e
confirme que todos estão acessíveis; não substitua manualmente o índice antigo
por um catálogo vazio.

O aplicativo lê o bin com GET e grava a lista completa com PUT. As operações
simultâneas de vários usuários podem sobrescrever alterações umas das outras;
esta solução não oferece transações ou controle de concorrência entre clientes.
Não coloque chaves no código nem na documentação.

## Executar pelo VS Code sem digitar a chave no terminal

1. Copie `jsonbin.example.json` para um arquivo chamado `jsonbin.local.json`
   na raiz do projeto.
2. No arquivo local, substitua os exemplos pelo ID do bin e pela Access Key.
   Salve o arquivo. Ele está no `.gitignore` e não deve ser compartilhado.
3. No VS Code, abra **Executar e Depurar**, escolha **Flutter com JSONBin
   (Chrome)** e pressione **F5**. Após alterar os valores, encerre e reinicie
   a execução; hot reload não altera as definições.

`dart-define` não é um cofre: a chave pode ser extraída de um app cliente
compilado. Use uma Access Key restrita e, para produção, um backend seguro.
Revogue qualquer chave que tenha sido compartilhada ou gravada em arquivos.
