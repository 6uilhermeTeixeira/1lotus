# Arquitetura

```text
5lotus -- promoção revisada --> 4lotus -- bundle imutável --> 3lotus
                                                            |
                                                            v
                                                     2lotus (eventos)
                                                            |
                                                            v
                                                     6lotus (agregados)
```

O 3lotus decide localmente a partir de um bundle validado. Falhas de rede não
transferem a decisão para outro serviço. Eventos operacionais usam uma outbox
SQLite e chegam ao 2lotus de forma idempotente.

## Fronteiras

- 1lotus não é dependência de runtime.
- 3lotus contém somente execução, controles locais e coleta necessária à decisão.
- 2lotus não produz decisão de trading.
- 4lotus não recebe chamadas da VPS no caminho crítico.
- 5lotus não possui autorização operacional.
- 6lotus não acessa bancos ou APIs internas.
