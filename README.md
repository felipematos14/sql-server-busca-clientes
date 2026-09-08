# 🔍 Busca Dinâmica de Clientes com SQL Server

Esse é um projeto que fiz para praticar e mostrar na prática como funciona uma busca dinâmica dentro de um banco de dados — parecida com aquele filtro que a gente usa em sites de compras, onde você escolhe só os campos que quer buscar (nome, cidade, faixa de preço, etc).

Usei o banco de exemplo da Microsoft, o **AdventureWorksDW2019**, focando na tabela de clientes (`DimCustomer`).

## 💡 O que esse projeto faz

Criei uma **stored procedure** (uma espécie de "função salva" dentro do banco) chamada `BuscarClientes`, que permite buscar clientes combinando vários filtros, todos opcionais:

- Nome e sobrenome
- Gênero
- Estado civil
- Faixa de renda anual
- Paginação (pra não trazer milhares de resultados de uma vez só)

Ou seja: dá pra buscar só por gênero, só por renda, por vários filtros juntos, ou nenhum filtro (nesse caso, traz todo mundo).

## 🧠 Por que fiz esse projeto assim

Meu objetivo não era só "fazer uma busca funcionar" — eu queria realmente entender o que acontece por trás dos panos quando o SQL Server busca informação, e usar isso a meu favor. Por isso o projeto tem duas partes: a busca em si, e depois uma investigação de performance, onde eu testei, medi e melhorei a velocidade da busca usando um índice.

## ⚙️ Como rodar o projeto

1. Restaure o banco `AdventureWorksDW2019` no seu SQL Server (arquivo `.bak` disponível oficialmente pela Microsoft)
2. Execute os scripts nessa ordem:
   1. `01_procedure.sql` — cria a stored procedure de busca
   2. `02_indice.sql` — cria o índice de otimização
   3. `testes.sql` — roda exemplos de busca e mede a performance

## 📝 Entendendo a stored procedure

A ideia central da procedure é bem simples: cada filtro só é aplicado **se** a pessoa realmente informar um valor pra ele. Isso é feito com esse padrão, repetido pra cada campo:

```sql
WHERE (Coluna = @Parametro OR @Parametro IS NULL)
```

Traduzindo em português: "ou a coluna é igual ao que a pessoa buscou, ou a pessoa nem informou esse filtro (então ignora essa condição)".

A paginação funciona parecido com passar página numa busca do Google — você escolhe qual página quer ver e quantos resultados por página:

```sql
ORDER BY CustomerKey
OFFSET (@PageNumber - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;
```

**Alguns exemplos de como usar:**

```sql
-- Busca só mulheres casadas
EXEC BuscarClientes @Gender = 'F', @MaritalStatus = 'M';

-- Busca por sobrenome, trazendo a página 1 com 5 resultados
EXEC BuscarClientes @LastName = 'Zhu', @PageNumber = 1, @PageSize = 5;

-- Sem nenhum filtro, traz todos os clientes
EXEC BuscarClientes;
```

## ⚡ A parte de performance (e o que eu aprendi de mais interessante)

Antes de qualquer otimização, testei uma busca por sobrenome e medi quanto "esforço" o banco de dados fazia pra encontrar o resultado. O SQL Server tem uma métrica chamada **leituras lógicas**, que basicamente mostra quantas "páginas" de dados ele precisou ler pra responder a busca.

**Resultado sem índice:** 282 leituras lógicas. Ou seja, o banco praticamente "folheou" a tabela inteira, cliente por cliente, procurando quem batia com o sobrenome buscado.

Criei então um índice na coluna de busca:

```sql
CREATE INDEX IX_DimCustomer_LastName
ON DimCustomer (LastName);
```

Pensa num índice como o índice remissivo no final de um livro: ao invés de ler o livro do início ao fim procurando um assunto, você vai direto na página certa. Depois de criar esse índice, o SQL Server passou a usar uma estratégia bem mais rápida (chamada de **Index Seek**) pra encontrar os registros.

### A descoberta que não esperava

Enquanto eu analisava o "plano de execução" (uma ferramenta visual que mostra o caminho que o SQL Server escolheu pra buscar os dados), percebi algo interessante: mesmo usando o índice, ainda tinha uma etapa extra consumindo **98% do custo total** da consulta, chamada de **Key Lookup**.

O motivo é simples depois que se entende: meu índice só guarda a coluna `LastName`. Só que minha busca também pede outras colunas (nome, gênero, renda, etc.), que não estão no índice. Então o SQL Server precisa fazer uma segunda parada: usar o índice pra achar o cliente, e depois voltar na tabela original pra buscar o resto dos dados desse cliente. Essa "volta" é o que se chama Key Lookup, e dependendo de quantos registros são encontrados, ela pode ficar cara.

Isso me ensinou uma lição importante: **criar um índice não resolve tudo sozinho** — é preciso analisar como o banco realmente está usando ele. A solução mais indicada pra esse caso seria criar um índice que já inclui as outras colunas usadas na busca (chamado de *covering index*), evitando essa segunda parada:

```sql
CREATE INDEX IX_DimCustomer_LastName_Covering
ON DimCustomer (LastName)
INCLUDE (FirstName, Gender, MaritalStatus, YearlyIncome);
```

## 🛠️ Tecnologias usadas

- SQL Server (T-SQL)
- SQL Server Management Studio (SSMS)
- Banco de dados de exemplo AdventureWorksDW2019 (Microsoft)

## 🚀 Próximos passos (se eu continuar evoluindo o projeto)

- Aplicar o *covering index* e comparar a diferença de performance
- Expandir a busca usando `JOIN`, trazendo dados de cidade/estado a partir da tabela `DimGeography`
- Testar Full-Text Search pra buscas mais avançadas de texto
