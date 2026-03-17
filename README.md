# SAP_BTP_RAP_APPCHAMADOS
📝 Projeto: Sistema de Gestão de Chamados (SAP RAP)
Sistema de Gestão de Chamados desenvolvido em ABAP Cloud utilizando o framework SAP RAP (RESTful ABAP Programming Model). Inclui Draft Handling, Side Effects, Instance Feature Control e OData Service V4


📋 Descrição
Este repositório contém o desenvolvimento de uma aplicação de Gestão de Chamados ponta a ponta, construída no ambiente SAP BTP (ABAP Cloud) utilizando o RESTful ABAP Programming Model (RAP).

O projeto foca em governança de dados e experiência do usuário (UX), implementando regras de negócio complexas e uma interface reativa com Fiori Elements.

🚀 Funcionalidades Principais
CRUD Completo: Criação, leitura, atualização e exclusão de chamados.

Draft Handling: Persistência temporária de dados para evitar perda de informações durante a edição.

Instance Feature Control: Bloqueio dinâmico das operações de Update e Delete quando um chamado atinge o status Concluído.

Side Effects: Reatividade da UI para ocultar/exibir campos de solução em tempo real conforme a mudança de status.

Analytics Header: Visualização gerencial através de gráficos integrados no cabeçalho da aplicação.

Value Helps (F4): Seleção inteligente de clientes e produtos.

🛠️ Tecnologias e Ferramentas
ABAP Cloud & SAP BTP: Ambiente de execução.

Core Data Services (CDS): Modelagem de dados e definições de UI (Annotations).

Behavior Definition (BDEF): Orquestração do comportamento transacional (Managed).

ABAP Git: Versionamento e deploy dos artefatos.

Fiori Elements (LRP): Template de interface padronizado.

🏗️ Arquitetura do Projeto
O projeto segue a estrutura de camadas do RAP:

Data Modeling: Tabelas de banco de dados e CDS Views.

Business Object Projection: Projeções focadas na interface do usuário.

Business Services: Service Definition e Service Binding (OData V4).

🧠 Desafios Técnicos Superados
Durante o desenvolvimento, foram aplicadas soluções para:

Governança de Status: Implementação do método get_instance_features para controle de estado (State Machine).

Consistência de Dados: Uso de READ ENTITIES IN LOCAL MODE para validações performáticas no buffer.

CI/CD: Configuração do fluxo de versionamento via abapGit integrando o Eclipse ADT ao GitHub.

📞 Contato
Julio Cesar  IN [juliocesardev]

