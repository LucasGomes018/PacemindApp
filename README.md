# 🏃 PaceMind

<p align="center">
  <img src="assets/logo.png" width="140" alt="PaceMind Logo">
</p>

<h3 align="center">
  Seu desempenho. Seus dados. Sua evolução.
</h3>

<p align="center">
  Aplicativo mobile para acompanhamento, análise e evolução de treinamentos de corrida.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white">
  <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black">
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white">
  <img src="https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white">
</p>

---

## 📌 Sobre o PaceMind

O **PaceMind** é uma aplicação mobile desenvolvida para auxiliar corredores no acompanhamento e análise de seus treinamentos.

A plataforma centraliza informações importantes sobre os treinos e transforma esses dados em métricas e gráficos que facilitam o acompanhamento da evolução do atleta.

O sistema permite analisar **volume, intensidade, ritmo, frequência cardíaca, zonas de treinamento, carga e consistência**, oferecendo uma visão mais completa do desempenho ao longo do tempo.

---

# 🧠 Como funciona?

```text
                         ┌──────────────────────┐
                         │      🏃 USUÁRIO      │
                         │                      │
                         │  Realiza seus treinos│
                         └──────────┬───────────┘
                                    │
                                    ▼
                    ┌─────────────────────────────┐
                    │       📱 PACEMIND APP       │
                    │                             │
                    │       Flutter + Dart        │
                    │                             │
                    │  • Dashboard                │
                    │  • Treinos                  │
                    │  • Métricas                 │
                    │  • Gráficos                 │
                    │  • Histórico                │
                    └──────────────┬──────────────┘
                                   │
                              HTTP / REST
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │        ⚙️ BACKEND            │
                    │                             │
                    │       JavaScript            │
                    │        Node.js               │
                    │                             │
                    │  • Autenticação             │
                    │  • Regras de negócio        │
                    │  • Processamento de dados   │
                    │  • API REST                 │
                    └──────────────┬──────────────┘
                                   │
                              SQL / API
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │       🗄️ DATABASE            │
                    │                             │
                    │         Supabase            │
                    │        PostgreSQL            │
                    │                             │
                    │  • Usuários                 │
                    │  • Treinos                  │
                    │  • Métricas                 │
                    │  • Histórico                │
                    └─────────────────────────────┘