@AbapCatalog.sqlViewName: 'ZV_HELP_APP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Status de texto para a CDS ZDD_CHAMADO_ENTITY'
@Metadata.ignorePropagatedAnnotations: true
define view ZDD_STATUS_SH 
as select from I_Language
{
      @ObjectModel.text.element: ['StatusDesc']
  key cast( 'A' as abap.char(1) ) as Status,
      cast( 'Aberto' as abap.char(20) ) as StatusDesc
}
where
  Language = 'P' -- Filtra apenas uma linha para evitar duplicidade

union all select distinct from I_Language
//union select from zsearchelpapp
{
  key cast( 'P' as abap.char(1) ) as Status,
      cast( 'Pendente' as abap.char(20) ) as StatusDesc
}

union all select distinct  from I_Language
//union select from zsearchelpapp
{
  key cast( 'C' as abap.char(1) ) as Status,
      cast( 'Concluído' as abap.char(20) ) as StatusDesc
}

union all select distinct  from I_Language
{
  key cast( 'F' as abap.char(1) ) as Status,
      cast( 'Cancelado' as abap.char(20) ) as StatusDesc
}
