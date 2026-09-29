# Runbook de migração

## Compatibilidade

- Serviços antigos: 1111 e 1112.
- Serviços novos: 7771 a 7776.
- O período paralelo não duplica ordens; apenas telemetria pode ser espelhada.

## Corte

1. Confirmar `/health` e `/ready` dos novos serviços.
2. Confirmar hash e versão do bundle instalado no runner.
3. Drenar a outbox e suspender execução.
4. Atualizar o WebRequest do MT5 para `127.0.0.1:7772`.
5. Executar smoke test em demo e comparar a decisão shadow.
6. Manter os serviços antigos disponíveis para rollback por cinco sessões.

## Rollback

Restaurar URL do EA e processos antigos diante de perda de eventos, divergência de
decisão, readiness negativo ou falha de proteção. Bancos nunca são revertidos de
forma destrutiva; a reconciliação usa chaves idempotentes.

