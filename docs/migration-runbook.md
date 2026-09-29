# Runbook de migração

## Compatibilidade

- Serviços antigos: 1111 e 1112.
- Serviços novos: 7771 a 7776.
- O período paralelo não duplica ordens; apenas telemetria pode ser espelhada.

## Estado preparado em 2026-09-29

- Os seis serviços paralelos estão instalados como `lotus-next-1.service` até
  `lotus-next-6.service` e respondem nas portas 7771–7776.
- O 2lotus carrega os bundles `zigzag-scalper-v2` e `zigzag-v7` com execução
  desabilitada.
- A outbox persistente do 2lotus entrega eventos autenticados ao SQLite do
  3lotus; duplicatas são tratadas por `event_id`.
- O terminal MT5 isolado antigo está inativo e o preset existente mantém
  um contrato incompatível com o runner novo. Em 2026-09-29 foi encontrado em
  loop de reinício, com `EnableOrderExecution=true`; a unit foi interrompida e
  desabilitada, e o preset instalado foi preservado no backup. Nenhum EA legado
  foi apontado automaticamente para o runner novo.
- O novo `LotusRunnerBridge.ex5` foi compilado em 2026-09-29 sem erros ou
  warnings e carregado uma vez na conta demo em modo shadow. O build recusa
  inicializar se `EnableOrderExecution=true`, portanto não há caminho de ordem
  neste artefato de migração.
- A whitelist WebRequest do MT5 ainda contém somente `127.0.0.1:1112`.
  Acrescentar `http://127.0.0.1:7772` em **Tools → Options → Expert Advisors**
  é pré-requisito para a primeira decisão originada pelo terminal.
  Uma sessão de prova confirmou que o EA carrega na conta demo, mas o runner
  não recebe ticks enquanto essa URL não estiver autorizada.
- Execute `scripts/check-staging.sh` antes e depois de toda mudança.

## Corte

1. Confirmar `/health` e `/ready` dos novos serviços.
2. Confirmar hash e versão do bundle instalado no runner.
3. Drenar a outbox e suspender execução.
4. Atualizar o WebRequest do MT5 para `127.0.0.1:7772`.
5. Compilar e anexar `LotusRunnerBridge.mq5`, carregando exclusivamente
   `LotusRunnerBridge-shadow.set`; não reutilizar o preset do EA legado.
6. Executar smoke test em demo e comparar a decisão shadow.
7. Manter os serviços antigos disponíveis para rollback por cinco sessões.

O corte de diretórios só deve acontecer após as cinco sessões. Até lá,
`/home/codexops/projects-next` é o ambiente candidato e
`/home/codexops/projects` continua sendo o ambiente anterior.

## Evidência mínima por sessão

Para cada uma das cinco sessões, registrar data, commit do 2lotus, hash do
bundle, quantidade de decisões, quantidade de eventos entregues, tamanho final
da outbox e qualquer divergência. Uma sessão só conta quando termina com outbox
zero, serviços ready e nenhuma divergência não explicada.

## Troca final de nomes

1. Parar apenas os serviços antigos que usam `/home/codexops/projects`.
2. Confirmar novamente o backup `lotus-reorg-20260929/SHA256SUMS`.
3. Preservar o diretório antigo com nome datado, sem apagá-lo.
4. Promover `projects-next` para `projects` e ajustar os caminhos das units.
5. Recarregar systemd, iniciar 1lotus–6lotus e repetir o check completo.
6. Alterar o EA apenas em conta demo/shadow; execução continua desabilitada.
7. Manter o diretório antigo e as units de rollback durante cinco sessões.

## Rollback

Restaurar URL do EA e processos antigos diante de perda de eventos, divergência de
decisão, readiness negativo ou falha de proteção. Bancos nunca são revertidos de
forma destrutiva; a reconciliação usa chaves idempotentes.
