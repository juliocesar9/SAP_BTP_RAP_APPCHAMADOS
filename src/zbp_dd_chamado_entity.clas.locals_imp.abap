CLASS lhc_ZDD_CHAMADO_ENTITY DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zdd_chamado_entity RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE zdd_chamado_entity.

    METHODS copiarChamado FOR MODIFY
      IMPORTING keys FOR ACTION zdd_chamado_entity~copiarChamado.

    METHODS SetDefaultSolicitante FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zdd_chamado_entity~SetDefaultSolicitante.

    METHODS validarAssunto FOR VALIDATE ON SAVE
      IMPORTING keys FOR zdd_chamado_entity~validarAssunto.

    METHODS validarDescricao FOR VALIDATE ON SAVE
      IMPORTING keys FOR zdd_chamado_entity~validarDescricao.

    METHODS validarStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR zdd_chamado_entity~validarStatus.
    METHODS calcularVisibilidade FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZDD_CHAMADO_ENTITY~calcularVisibilidade.
    METHODS validarSolucao FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZDD_CHAMADO_ENTITY~validarSolucao.

    METHODS get_instance_features FOR INSTANCE FEATURES
  IMPORTING keys REQUEST requested_features FOR ZDD_CHAMADO_ENTITY RESULT result.



ENDCLASS.

CLASS lhc_ZDD_CHAMADO_ENTITY IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

  DATA: lv_max_id TYPE zchamado-chamadoid.

    " 1. Busca o último ID utilizado na tabela física (zchamado)
    SELECT MAX( chamadoid ) FROM zchamado INTO @lv_max_id.

    " 2. Itera sobre as novas entidades que estão sendo criadas no Fiori
    LOOP AT entities INTO DATA(ls_entity).
      lv_max_id += 1.

      " 3. Atribui o novo ID incremental para a entidade
      APPEND VALUE #( %cid      = ls_entity-%cid
                       %is_draft = ls_entity-%is_draft " <--- CRÍTICO: Repasse se é rascunho ou não
                      chamadoid = lv_max_id ) TO mapped-zdd_chamado_entity.
    ENDLOOP.

  ENDMETHOD.

  METHOD copiarChamado.

" 1. Lemos os dados originais
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_originais).

    DATA lt_novos TYPE TABLE FOR CREATE zdd_chamado_entity.

    " 2. Criamos o novo registro alterando o Status fixo
    lt_novos = VALUE #( FOR ls_orig IN lt_originais (
        %cid      = keys[ KEY entity %tky = ls_orig-%tky ]-%cid
        Assunto   = |Cópia: { ls_orig-Assunto }|
        Descricao = ls_orig-Descricao
        Status    = 'A' " <-- Aqui você força o valor inicial, independente do original
    ) ).

*    " 3. Disparamos a criação
*    MODIFY ENTITIES OF zdd_chamado_entity IN LOCAL MODE
*      ENTITY zdd_chamado_entity
*        CREATE FIELDS ( Assunto Descricao Status ) WITH lt_novos
*        %is_draft = if_abap_behv=>mk-on
*      FAILED   failed
*      REPORTED reported.


MODIFY ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
        CREATE FIELDS ( Assunto Descricao Status )
        WITH VALUE #( FOR ls_n IN lt_novos (
            %cid      = ls_n-%cid
            Assunto   = ls_n-Assunto
            Descricao = ls_n-Descricao
            Status    = ls_n-Status
            %is_draft = if_abap_behv=>mk-on " Abre a tela editável
        ) )
      MAPPED   DATA(lt_mapped_modify)
      FAILED   failed
      REPORTED reported.

" 4. Repassa o mapeamento para o Fiori navegar
mapped-zdd_chamado_entity = lt_mapped_modify-zdd_chamado_entity.

**  " 1. Lê os dados dos chamados selecionados na tela do Fiori
**    READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
**      ENTITY ZDD_CHAMADO_ENTITY
**      ALL FIELDS WITH CORRESPONDING #( keys )
**      RESULT DATA(lt_chamados_origem).
**
**    DATA: lt_chamados_novos TYPE TABLE FOR CREATE ZDD_CHAMADO_ENTITY.
**
**    " 2. Prepara os dados para a criação do novo registro
**    LOOP AT lt_chamados_origem INTO DATA(ls_origem).
**
**    data(lv_temp_cid) = |CID_{ sy-tabix }|.
**
**      APPEND VALUE #( %cid      = lv_temp_cid  " <--- A correção principal está aqui "keys[ sy-tabix ]-%cid_ref
**                      assunto   = |Cópia: { ls_origem-Assunto }|
**                      descricao = ls_origem-Descricao
**                      status    = 'A' " Novo chamado sempre começa como Aberto
**                      solicitanteid = ls_origem-Solicitanteid
**                    ) TO lt_chamados_novos.
**    ENDLOOP.
**
**    " 3. Executa a criação (o Early Numbering cuidará do novo ID)
**    MODIFY ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
**      ENTITY ZDD_CHAMADO_ENTITY
**      CREATE FIELDS ( assunto descricao status solicitanteid )
**      WITH lt_chamados_novos
**      MAPPED  DATA(lt_mapped_modify) " Pegamos o mapeamento aqui
**      FAILED failed
**      REPORTED reported.
**
**" 4. CRITICAL: Repassa o mapeamento para o framework exibir o registro na tela
**" No OData V2, tente passar o conteúdo linha a linha se o '=' falhar
**LOOP AT lt_mapped_modify-zdd_chamado_entity ASSIGNING FIELD-SYMBOL(<fs_mapped>).
**      APPEND VALUE #( %cid = <fs_mapped>-%cid
**                      chamadoid = <fs_mapped>-chamadoid ) TO mapped-zdd_chamado_entity.
**    ENDLOOP.
**
**
***    mapped-zdd_chamado_entity = lt_mapped_modify-zdd_chamado_entity.



  ENDMETHOD.

  METHOD SetDefaultSolicitante.

  " 1. Lê os chamados que acabaram de ser criados e ainda estão no buffer
    READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
      ENTITY ZDD_CHAMADO_ENTITY
      FIELDS ( Solicitanteid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    " 2. Filtra apenas aqueles que ainda não possuem um solicitante preenchido
    DELETE lt_chamados WHERE Solicitanteid IS NOT INITIAL.

    CHECK lt_chamados IS NOT INITIAL.

    " 3. Atualiza os registros com um ID padrão (ex: seu ID de desenvolvedor)
    MODIFY ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
      ENTITY ZDD_CHAMADO_ENTITY
      UPDATE FIELDS ( Solicitanteid )
      WITH VALUE #( FOR ls_chamado IN lt_chamados (
                         %tky          = ls_chamado-%tky
                         Solicitanteid = 1001 " <--- Substitua pelo seu ID padrão
                   ) )
      REPORTED DATA(lt_reported).

    " Passa eventuais mensagens para o framework
    reported = CORRESPONDING #( DEEP lt_reported ).



  ENDMETHOD.

  METHOD validarAssunto.

  " 1. Lê os dados dos chamados que estão sendo validados no buffer
    READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
      ENTITY ZDD_CHAMADO_ENTITY
      FIELDS ( Assunto ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    LOOP AT lt_chamados INTO DATA(ls_chamado).
      " 2. Verifica se o assunto está vazio
      IF ls_chamado-Assunto IS INITIAL.

        " 3. Se estiver vazio, marca o registro como falho (impede o save)
        APPEND VALUE #( %tky = ls_chamado-%tky ) TO failed-zdd_chamado_entity.

        " 4. Envia a mensagem de erro detalhada para a UI do Fiori
        APPEND VALUE #( %tky = ls_chamado-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'O campo Assunto é obrigatório!' )
                        %element-assunto = if_abap_behv=>mk-on " Destaca o campo em vermelho
                      ) TO reported-zdd_chamado_entity.
      ENDIF.
    ENDLOOP.



  ENDMETHOD.

  METHOD validarDescricao.

  " 1. Lê a descrição dos chamados que estão sendo validados
    READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
      ENTITY ZDD_CHAMADO_ENTITY
      FIELDS ( Descricao ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    LOOP AT lt_chamados INTO DATA(ls_chamado).
      " 2. Validação: Verifica se está vazio ou se é muito curta (ex: menos de 10 caracteres)
      IF ls_chamado-Descricao IS INITIAL OR strlen( condense( ls_chamado-Descricao ) ) < 10.

        " 3. Bloqueia a persistência do registro
        APPEND VALUE #( %tky = ls_chamado-%tky ) TO failed-zdd_chamado_entity.

        " 4. Retorna a mensagem de erro para o Fiori
        APPEND VALUE #( %tky = ls_chamado-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'A descrição deve conter pelo menos 10 caracteres!' )
                        %element-descricao = if_abap_behv=>mk-on " Realça o campo Descrição
                      ) TO reported-zdd_chamado_entity.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD validarStatus.

" 1. Lê o status dos chamados que estão sendo validados no buffer
    READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
      ENTITY ZDD_CHAMADO_ENTITY
      FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    " 2. Busca todos os status válidos cadastrados na sua CDS de Help
    SELECT FROM zdd_status_sh
      FIELDS status
      INTO TABLE @DATA(lt_status_validos).

    LOOP AT lt_chamados INTO DATA(ls_chamado).
      " 3. Validação: Verifica se o status informado existe na tabela de busca
      IF ls_chamado-Status IS NOT INITIAL AND
         NOT line_exists( lt_status_validos[ status = ls_chamado-Status ] ).

        " 4. Bloqueia a persistência se o status for inválido
        APPEND VALUE #( %tky = ls_chamado-%tky ) TO failed-zdd_chamado_entity.

        " 5. Retorna a mensagem de erro dinâmica
        APPEND VALUE #( %tky = ls_chamado-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Status '{ ls_chamado-Status }' inválido. Consulte a lista de opções.| )
                        %element-status = if_abap_behv=>mk-on
                      ) TO reported-zdd_chamado_entity.



      ENDIF.
    ENDLOOP.





  ENDMETHOD.


  METHOD calcularVisibilidade.

  READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
    ENTITY ZDD_CHAMADO_ENTITY FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_chamados).

  MODIFY ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
    ENTITY ZDD_CHAMADO_ENTITY
    UPDATE FIELDS ( SolucaoEscondida )
    WITH VALUE #( FOR ls_ch IN lt_chamados (
      %tky = ls_ch-%tky
      SolucaoEscondida = COND #( WHEN ls_ch-Status = 'C' THEN ' ' ELSE 'X' )
    ) ).


  ENDMETHOD.

  METHOD validarSolucao.

   " 1. Lê os dados dos chamados que estão sendo validados no buffer
    READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
      ENTITY ZDD_CHAMADO_ENTITY
      FIELDS ( Solucao ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    LOOP AT lt_chamados INTO DATA(ls_chamado).
      " 2. Verifica se o assunto está vazio
      IF ls_chamado-Solucao IS INITIAL and ls_chamado-Status EQ 'C'.

        " 3. Se estiver vazio, marca o registro como falho (impede o save)
        APPEND VALUE #( %tky = ls_chamado-%tky ) TO failed-zdd_chamado_entity.

        " 4. Envia a mensagem de erro detalhada para a UI do Fiori
        APPEND VALUE #( %tky = ls_chamado-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'O campo Solução é obrigatório!' )
                        %element-assunto = if_abap_behv=>mk-on " Destaca o campo em vermelho
                      ) TO reported-zdd_chamado_entity.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

METHOD get_instance_features.


  " 1. Ler o status dos chamados solicitados
  READ ENTITIES OF ZDD_CHAMADO_ENTITY IN LOCAL MODE
    ENTITY ZDD_CHAMADO_ENTITY
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_chamados).





"Busca o status do banco de dados, e verifica se ele esta concluindo o chamado no exato momento.
  " se sim, nao bloqueia os campos, e nao bloqueia a função de update ou delete.

read table lt_chamados into data(w_chamado) index 1.

select single
  from zchamado
  FIELDS status
  where chamadoid = @w_chamado-chamadoid
  into @data(status_bco).

 IF status_bco NE w_chamado-Status.
     RETURN.
 ENDIF.


  " 2. Definir as permissões baseadas no status
  result = VALUE #( FOR ls_ch IN lt_chamados (
             %tky = ls_ch-%tky





             " Se for 'C', Update e Delete ficam 'Disabled' (bloqueados)
             %update = COND #( WHEN ls_ch-Status = 'C'
                               THEN if_abap_behv=>fc-o-disabled
                               ELSE if_abap_behv=>fc-o-enabled )

             %delete = COND #( WHEN ls_ch-Status = 'C'
                               THEN if_abap_behv=>fc-o-disabled
                               ELSE if_abap_behv=>fc-o-enabled )
           ) ).
ENDMETHOD.


ENDCLASS.
