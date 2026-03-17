@AbapCatalog.sqlViewName: 'ZV_TEXTOS'
@EndUserText.label: 'Textos de Status'
@ObjectModel.dataCategory: #TEXT // Categoria de apenas textos descritivos. que vai ser chamado no
// text association na view analitica ZDD_CHAMADO_ANA.


//Textos descritivos para a CDS_VIEW ZDD_CHAMADO_ANA

define view ZDD_STATUS_TEXT as select from zchamado  //ZDD_CHAMADO_ENTITY
{
  @ObjectModel.text.element: [ 'StatusName' ]
   key status as Status,
   @Semantics.text: true //Descrição real, nome do Status.
   case status
   
   when 'A' then 'Aberto'
   when 'P' then 'Pendente'
   when 'C' then 'Concluído'
   when 'F' then 'Cancelado'
   else 'Desconhecido'
   
   end as StatusName
}
