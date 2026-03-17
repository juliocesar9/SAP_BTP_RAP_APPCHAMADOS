
//@Metadata.ignorePropagatedAnnotations: true
//@Metadata.allowExtensions: true  // <--- ADICIONE ESTA LINHA
//@Analytics.dataCategory: #CUBE

//define view entity ZDD_CHAMADO_ANA 
//  as select from zchamado as _Cham
//  association [0..1] to ZDD_STATUS_TEXT as _TEXT on $projection.Status = _TEXT.Status
//{
//    @ObjectModel.text.association: '_TEXT'
//    key _Cham.status as Status, // ÚNICA CHAVE
//    
//    @Aggregation.default: #SUM
//    cast( 1 as abap.int4 ) as TotalChamados, 
//    
//    @Aggregation.default: #MIN
//    @UI.hidden: true 
//    case _Cham.status
//        when 'A' then 1
//        when 'P' then 2
//        when 'C' then 3
//        else 0
//    end as StatusCriticality,
//    
//    cast( 'X' as abap.char(1) ) as Anchor,
//
//    _TEXT
//}
//union all
//select from zchamado_d as _Draft
//  association [0..1] to ZDD_STATUS_TEXT as _TEXT on $projection.Status = _TEXT.Status
//{
//    key _Draft.status as Status,
//    cast( 1 as abap.int4 ) as TotalChamados, 
//    case _Draft.status
//        when 'A' then 1
//        when 'P' then 2
//        when 'C' then 3
//        else 0
//    end as StatusCriticality,
//    
//    cast( 'X' as abap.char(1) ) as Anchor,
//    _TEXT







//define view entity ZDD_CHAMADO_ANA 
//  as select from zchamado as _Cham
//  association [0..1] to ZDD_STATUS_TEXT as _TEXT on $projection.Status = _TEXT.Status
//{
//    @ObjectModel.text.association: '_TEXT'
//    key _Cham.status as Status,
//    
//    @Aggregation.default: #SUM
//    @EndUserText.label: 'Qtd'
//   // @UI.hidden: true
//    // Forçamos o tipo Inteiro 4 aqui
//    cast( 1 as abap.int4 ) as TotalChamados, 
//    
//    @Aggregation.default: #MIN
//
//    case _Cham.status
//        when 'A' then 1
//        when 'P' then 2
//        when 'C' then 3
//        else 0
//    end as StatusCriticality,
//    
//    cast( 'X' as abap.char(1) ) as Anchor,
//
//    _TEXT
//}
//
//union all
//
//select from zchamado_d as _Draft
//  association [0..1] to ZDD_STATUS_TEXT as _TEXT on $projection.Status = _TEXT.Status
//{
//
//// NOVO: Sem anotações aqui. 
//    key _Draft.status as Status,
//    cast( 1 as abap.int4 ) as TotalChamados, 
//    case _Draft.status
//        when 'A' then 1
//        when 'P' then 2
//        when 'C' then 3
//        else 0
//    end as StatusCriticality,
//    cast( 'X' as abap.char(1) ) as Anchor,
//    _TEXT


// // @ObjectModel.text.association:'_TEXT'
//    key _Draft.status as Status,
//    
//   // @Aggregation.default: #SUM
//   // @EndUserText.label: 'Qtd'
//    // O tipo aqui DEVE ser exatamente igual ao de cima
//   cast( 1 as abap.int4 ) as TotalChamados, 
//    
//    //@Aggregation.default: #MIN
//    //@UI.hidden: true 
//    case _Draft.status
//        when 'A' then 1
//        when 'P' then 2
//        when 'C' then 3
//        else 0
//    end as StatusCriticality,
//    
//    cast( 'X' as abap.char(1) ) as Anchor,
//
//    _TEXT
//    
//    
    


//group by status




@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'view analitica para contagem de chamados'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true  // <--- ADICIONE ESTA LINHA


/* ESSAS SÃO AS ANOTAÇÕES ANALÍTICAS PRINCIPAIS */


@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

@Analytics.dataCategory: #CUBE //Anotação que tranforma a view em analitica.

define view entity ZDD_CHAMADO_ANA as select from zchamado as _Cham
association [0..1] to ZDD_STATUS_TEXT as _TEXT on $projection.Status = _TEXT.Status
//{
//   
 //  @Analytics.dimension: true        // Define o Status como uma dimensão (Eixo do gráfico)
 //   key status as Status,
//    
//    @Aggregation.default: #SUM        // Define a métrica (O valor que será somado)
//    @Semantics.quantity.unitOfMeasure: 'TotalChamados'
//    cast( 1 as abap.int4 ) as TotalChamados
//}

{  



    @ObjectModel.text.association: '_Text' // troca a legenda do grafico de pizza de "A" para "Aberto".
   key _Cham.status as Status,
   
    // Lógica para o gráfico: Se houver rascunho, usa o status do rascunho, 
    // senão usa o da tabela principal.
    
    @Aggregation.default: #SUM
    @EndUserText.label: 'Qtd'
  count( * ) as TotalChamados,
  
    
  
/* Adicione este campo na lista de campos da sua View Analítica */
//@Analytics.dimension: true

cast( 'X' as abap.char(1) ) as Anchor,

// Define a cor do Grafico analitico conforme o dicionario de cores do Fiori.

//Valor,Estado Semântico,Cor no Gráfico/Tabela,Exemplo no seu Projeto
//1,Negative,Vermelho,Status 'A' (Aberto)
//2,Critical,Amarelo/Laranja,Status 'P' (Pendente)
//3,Positive,Verde,Status 'C' (Concluído)
//0 / Inicial,Neutral,Cinza/Azul,Outros status>

//teste aqui 10.03.2026 09:39

@Aggregation.default: #SUM
@UI.hidden: true
cast(1 as abap.int4) as SemanticMeasure,


@Aggregation.default: #MIN
@UI.hidden: true // Oculta da tabela mas mantém no gráfico
  case _Cham.status
    when 'A' then 1
    when 'P' then 2
    when 'C' then 3
    else 0
  end as StatusCriticality,


_TEXT


}

group by _Cham.status
