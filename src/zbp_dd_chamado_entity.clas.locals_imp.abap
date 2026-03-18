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
      IMPORTING keys FOR zdd_chamado_entity~calcularVisibilidade.
    METHODS validarSolucao FOR VALIDATE ON SAVE
      IMPORTING keys FOR zdd_chamado_entity~validarSolucao.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zdd_chamado_entity RESULT result.
    METHODS setdefaultstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zdd_chamado_entity~setdefaultstatus.
    METHODS encerrarchamado FOR MODIFY
      IMPORTING keys FOR ACTION zdd_chamado_entity~encerrarchamado RESULT result.



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


  ENDMETHOD.

  METHOD SetDefaultSolicitante.

    " 1. Lê os chamados que acabaram de ser criados e ainda estão no buffer
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
      FIELDS ( Solicitanteid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    " 2. Filtra apenas aqueles que ainda não possuem um solicitante preenchido
    DELETE lt_chamados WHERE Solicitanteid IS NOT INITIAL.

    CHECK lt_chamados IS NOT INITIAL.

  " 3. Inicializa o gerador de números aleatórios (entre 1 e 3)
    DATA(lo_random) = cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                                  min  = 1
                                                  max  = 3 ).

    " 4. Atualiza os registros com o sorteio
    MODIFY ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
      UPDATE FIELDS ( Solicitanteid )
      WITH VALUE #( FOR ls_chamado IN lt_chamados
                     LET lv_sorteio = lo_random->get_next( ) IN (
                         %tky          = ls_chamado-%tky
                         Solicitanteid = COND #( WHEN lv_sorteio = 1 THEN 3894
                                                 WHEN lv_sorteio = 2 THEN 7612
                                                 ELSE 9768 )
                   ) )
      REPORTED DATA(lt_reported).

    reported = CORRESPONDING #( DEEP lt_reported ).

  ENDMETHOD.

  METHOD validarAssunto.

    " 1. Lê os dados dos chamados que estão sendo validados no buffer
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
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
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
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
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
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

    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    MODIFY ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
      UPDATE FIELDS ( SolucaoEscondida )
      WITH VALUE #( FOR ls_ch IN lt_chamados (
        %tky = ls_ch-%tky
        SolucaoEscondida = COND #( WHEN ls_ch-Status = 'C' THEN ' ' WHEN ls_ch-Status = '' THEN ' '  ELSE 'X' )
      ) ).


  ENDMETHOD.

  METHOD validarSolucao.

    " 1. Lê os dados dos chamados que estão sendo validados no buffer
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
      FIELDS ( Solucao ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).

    LOOP AT lt_chamados INTO DATA(ls_chamado).
      " 2. Verifica se o assunto está vazio
      IF ls_chamado-Solucao IS INITIAL AND ls_chamado-Status EQ 'C'.

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
    READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
      ENTITY zdd_chamado_entity
      FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chamados).


    "Busca o status do banco de dados, e verifica se ele esta concluindo o chamado no exato momento.
    " se sim, nao bloqueia os campos, e nao bloqueia a função de update ou delete.

    READ TABLE lt_chamados INTO DATA(w_chamado) INDEX 1.

    SELECT SINGLE
      FROM zchamado
      FIELDS status
      WHERE chamadoid = @w_chamado-chamadoid
      INTO @DATA(status_bco).

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


  METHOD setDefaultStatus.
" Ao criar um novo status o status deve ser A (Aberto).

" 1. Lê os chamados que estão sendo criados agora
  READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
    ENTITY zdd_chamado_entity
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_chamados).

  " 2. Filtra os que não têm status (os novos)
  DELETE lt_chamados WHERE Status IS NOT INITIAL.
  CHECK lt_chamados IS NOT INITIAL.

  " 3. Grava o status 'A' (Aberto) neles
  MODIFY ENTITIES OF zdd_chamado_entity IN LOCAL MODE
    ENTITY zdd_chamado_entity
    UPDATE FIELDS ( Status )
    WITH VALUE #( FOR ls_chamado IN lt_chamados (
                       %tky   = ls_chamado-%tky
                       Status = 'A'
                 ) )
    REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD encerrarChamado.

read table keys into data(w_key) index 1.

  " 1. Modifica o status para 'C' (Concluído) dos registros selecionados
  MODIFY ENTITIES OF zdd_chamado_entity IN LOCAL MODE
    ENTITY zdd_chamado_entity
    UPDATE FIELDS ( Status Solucao )
    WITH VALUE #( FOR key IN keys (
                       %tky   = key-%tky
                       Status = 'C'
                       Solucao = w_key-%param-Solucao "keys-%param-Solucao " Pega o que foi digitado no popup
                 ) )
    REPORTED DATA(lt_reported).

  " 2. Lê os dados atualizados para devolver o resultado para a tela
  READ ENTITIES OF zdd_chamado_entity IN LOCAL MODE
    ENTITY zdd_chamado_entity
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_chamados).

  result = VALUE #( FOR ls_chamado IN lt_chamados (
                         %tky   = ls_chamado-%tky
                         %param = ls_chamado
                   ) ).

  ENDMETHOD.

ENDCLASS.
