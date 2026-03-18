CLASS zcl_patch_chamados DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_patch_chamados IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

  " Este comando vai mudar o status de TODOS os seus chamados para 'A' (Aberto)
    UPDATE zchamado SET status = 'A'.

    IF sy-subrc = 0.
      out->write( 'Sucesso! Todos os chamados foram resetados para Aberto (A).' ).
    ELSE.
      out->write( 'Erro ao atualizar ou tabela vazia.' ).
    ENDIF.



  ENDMETHOD.
ENDCLASS.
