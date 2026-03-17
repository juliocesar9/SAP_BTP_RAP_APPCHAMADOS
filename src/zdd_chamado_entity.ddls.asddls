@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'dados do chamado'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'Chamadoid' ]
@ObjectModel.usageType.sizeCategory: #S

define root view entity ZDD_CHAMADO_ENTITY
  as select from zchamado
  association [0..1] to ZDD_STATUS_SH   as _StatusText on $projection.Status = _StatusText.Status
  association [0..*] to ZDD_CHAMADO_ANA as _Grafico    on $projection.Anchor = _Grafico.Anchor // 1 = 1
{
  key chamadoid                   as Chamadoid,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZDD_STATUS_SH', element: 'Status' } }]
      @ObjectModel.text.element: ['StatusDesc'] -- Isso faz aparecer a descrição na tela de detalhes
      status                      as Status,

      -- Linha da Associação.
      _StatusText.StatusDesc      as StatusDesc,

      assunto                     as Assunto,
      descricao                   as Descricao,
      solicitanteid               as Solicitanteid,
      /* No select da View Principal */
      cast( 'X' as abap.char(1) ) as Anchor,

      last_changed_at             as Last_changed_at,


      /* Logica para decidir o status */
      case status
        when 'A' then 1 -- Azul (Neutro)
        when 'P' then 2 -- Amarelo (Pendente)
        when 'C' then 3 -- Verde (Concluído)
        when 'F' then 0 -- Vermelho   Interrupção. O processo foi cortado antes do fim.
        else  0
      end  as StatusCriticality, //Este elemento alimenta a tabela (List Report).

      _StatusText,

      @Semantics.systemDateTime.createdAt: true //Preenche a data e a hora de forma automatica.
      criado_em,

      solucao,

      //Esconder o campo Solução.
      case status
        when 'C' then cast( ' ' as abap_boolean ) -- FALSE (Não esconde)
        else cast( 'X' as abap_boolean )          -- TRUE (Esconde)
      end  as SolucaoEscondida,

      _Grafico

}
