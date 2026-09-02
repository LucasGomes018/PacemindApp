# 🏃 PaceMind

> Aplicativo de treinamento e acompanhamento de corrida desenvolvido para auxiliar corredores no monitoramento, análise e evolução de seus treinos.

## 📱 Sobre o projeto

O **PaceMind** é uma aplicação mobile desenvolvida em **Flutter e Dart**, criada com o objetivo de facilitar o acompanhamento e a análise dos treinos de corrida.

A aplicação permite registrar e visualizar informações importantes sobre os treinamentos, como distância percorrida, tempo, ritmo, frequência cardíaca, intensidade e carga de treino.

Além disso, o sistema apresenta os dados de forma visual através de gráficos e indicadores, permitindo acompanhar a evolução do desempenho ao longo do tempo.

## 🎯 Objetivos

- 📊 Monitorar o desempenho durante os treinos
- 🏃 Registrar e acompanhar treinos de corrida
- 📈 Visualizar a evolução do desempenho
- ❤️ Acompanhar frequência cardíaca e zonas de intensidade
- ⏱️ Analisar ritmo e tempo de treino
- 📅 Comparar períodos de treinamento
- 💡 Fornecer informações para auxiliar na tomada de decisões durante os treinamentos

## ✨ Funcionalidades

### 🏃 Treinos

- Registro de treinos de corrida
- Distância percorrida
- Tempo total
- Ritmo médio
- Frequência cardíaca
- Carga de treino
- Treino longo
- Histórico de atividades

### 📊 Dashboard

O aplicativo possui um painel para visualizar rapidamente os principais indicadores do treinamento.

Entre os dados apresentados estão:

- **KM por semana**
- **Tempo total de treino**
- **Carga de treinamento**
- **Quantidade de treinos**
- **Evolução da quilometragem**
- **Evolução do ritmo**
- **Evolução da frequência cardíaca**

### ❤️ Zonas de intensidade

Os treinos podem ser analisados de acordo com as zonas de intensidade:

- Zona 1
- Zona 2
- Zona 3
- Zona 4
- Zona 5

Também é possível visualizar quanto tempo foi passado em cada zona durante os treinamentos.

### 📈 Análise de desempenho

O PaceMind permite analisar a evolução do corredor através de diferentes métricas:

- Evolução da quilometragem
- Evolução do ritmo
- Evolução da frequência cardíaca
- Volume semanal e mensal
- Tempo total treinado
- Distribuição das zonas de intensidade
- Carga de treinamento
- Consistência dos treinos

### 🔄 Comparações

Os dados podem ser utilizados para comparar diferentes períodos de treinamento, como:

- Semana atual × semana anterior
- Mês atual × mês anterior
- Evolução do ritmo
- Evolução do volume
- Distribuição das zonas de intensidade
- Carga de treinamento
- Dias de descanso
- Consistência

---

## 🛠️ Tecnologias utilizadas

### 📱 Aplicativo

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)

### ⚙️ Backend

- JavaScript
- Node.js
- API REST

### 🗄️ Banco de dados

- [Supabase](https://supabase.com/)
- PostgreSQL
- SQL

### 📊 Visualização de dados

- Gráficos e indicadores para análise dos treinamentos

---

## 🏗️ Arquitetura

O projeto utiliza uma arquitetura dividida em três principais componentes:

```text
┌─────────────────────┐
│                     │
│   📱 Flutter App    │
│      (Dart)         │
│                     │
└──────────┬──────────┘
           │
           │ HTTP / REST API
           ▼
┌─────────────────────┐
│                     │
│   ⚙️ Backend        │
│   JavaScript        │
│                     │
└──────────┬──────────┘
           │
           │ SQL
           ▼
┌─────────────────────┐
│                     │
│   🗄️ Supabase       │
│   PostgreSQL        │
│                     │
└─────────────────────┘