# 🛵 MotoEntrega IA (Circuito Otimizado)

Um sistema completo de logística e gestão para entregadores, projetado para transformar a câmera do celular em um leitor(Scanner) inteligente de comandas, organizar pedidos por ordem de urgência ou distância, traçar rotas mais rápidas e econômicas para múltiplas entregas.

## 💡 Sobre o Projeto
O MotoEntrega IA resolve um dos maiores problemas do delivery moderno: a perda de tempo organizando rotas manualmente. O aplicativo permite que o entregador tire fotos das comandas físicas. O backend (Java) processa as imagens, extrai os endereços e utiliza algoritmos de otimização (Problema do Caixeiro Viajante) para criar o circuito de entrega perfeito, reduzindo o consumo de combustível e maximizando o lucro diário.

## 🚀 Principais Funcionalidades

- **📸 Scanner de Comandas:** Captura de múltiplas fotos de recibos diretamente da câmera.
- **🧠 Leitura OCR (IA):** Integração com backend para extração automática de dados do cliente e endereço.
- **🗺️ Roteirização Inteligente (Caixeiro Viajante):** Cálculo do trajeto mais eficiente entre múltiplos pontos, garantindo economia de tempo e gasolina.
- **🧭 Navegação Nativa:** Botões integrados que abrem o Google Maps automaticamente com a rota curva-a-curva traçada até a porta do cliente.
- **💰 Gestão Financeira:** Cálculo automático de lucro líquido por entrega, abatendo o custo do combustível (baseado no consumo da moto configurado no app) e gestão de repasses pendentes/pagos.
- **📍 Baixa em Tempo Real:** Recálculo dinâmico do circuito de entregas no mapa assim que um pedido é marcado como "Entregue".

## 🛠️ Tecnologias Utilizadas

**Frontend (Mobile App)**
- [Flutter](https://flutter.dev/) & Dart
- `flutter_map` & `latlong2` (Renderização de mapas nativos)
- `image_picker` (Acesso à câmera/galeria)
- `url_launcher` (Deep linking com Google Maps)

**Backend & Infraestrutura**
- Java + Spring Boot (Processamento OCR e regras de negócio)
- [Mapbox Optimization API](https://docs.mapbox.com/api/navigation/optimization/) (Motor matemático para rotas)
- [Ngrok](https://ngrok.com/) (Túnel de rede para comunicação remota via 4G)

## 📱 Telas do Aplicativo
*(Dica: Tire prints da tela do seu celular rodando o app, salve na pasta do projeto e adicione as imagens aqui depois!)*
- Tela 1: Captura e Leitura
- Tela 2: Mapa com o Circuito Otimizado
- Tela 3: Prestação de Contas (Lucro Líquido)

## ⚙️ Como executar este projeto
1. Clone este repositório: `git clone https://github.com/SEU_USUARIO/motoentrega-ia.git`
2. Instale as dependências do Flutter: `flutter pub get`
3. Configure o seu IP ou link do Ngrok no arquivo `main.dart` (classe `AppConfig`).
4. Execute o app no seu emulador ou dispositivo físico: `flutter run`

---
*Desenvolvido com dedicação para revolucionar a logística de entregas locais.*
