import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- NOVO IMPORT PARA ABRIR O GOOGLE MAPS

void main() {
  runApp(const MyApp());
}

// ============================================================================
// CHAVES E CONFIGURAÇÕES GERAIS (TUDO CONFIGURADO PARA VOCÊ!)
// ============================================================================
class AppConfig {
  // A chave do Mapbox 
  static const String mapboxToken = "COLE_SUA_CHAVE_AQUI";
  
  // LINK DO NGROK (COM O /api/comandas NO FINAL)
  static const String baseUrl = "https://photomechanically-unfair-jennifer.ngrok-free.dev/api/comandas";
}

class ConfigVeiculo {
  static double consumoKmL = 35.0;       
  static double precoCombustivel = 5.80; 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoEntrega IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark), useMaterial3: true),
      home: const TelaPrincipal(), 
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});
  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0; 
  final List<Widget> _telas = [const TelaCaptura(), const TelaVeiculo(), const TelaFinanceiro(), const TelaMapa()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceAtual, children: _telas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        type: BottomNavigationBarType.fixed, backgroundColor: Colors.grey[900], selectedItemColor: Colors.amber, unselectedItemColor: Colors.grey, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.two_wheeler), label: 'Veículo'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Financeiro'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rotas'),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. TELA CAPTURA E LISTAGEM
// ============================================================================
class TelaCaptura extends StatefulWidget {
  const TelaCaptura({super.key});
  @override
  State<TelaCaptura> createState() => _TelaCapturaState();
}

class _TelaCapturaState extends State<TelaCaptura> {
  List<XFile> _imagensSelecionadas = [];
  final ImagePicker _picker = ImagePicker();
  bool _carregando = false;
  String _mensagemErro = '';
  List<dynamic> _listaComandas = []; 

  Future<void> _pegarImagens() async {
    final List<XFile> fotos = await _picker.pickMultiImage();
    if (fotos.isNotEmpty) {
      setState(() { _imagensSelecionadas = fotos; _listaComandas = []; _mensagemErro = ''; });
    }
  }

  Future<void> _enviarParaIA() async {
    if (_imagensSelecionadas.isEmpty) return;
    setState(() { _carregando = true; _listaComandas = []; _mensagemErro = ''; });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}/ler-fotos'));
      for (var img in _imagensSelecionadas) {
        var bytes = await img.readAsBytes();
        var arquivo = http.MultipartFile.fromBytes('fotos', bytes, filename: img.name);
        request.files.add(arquivo);
      }
      var resposta = await request.send();
      var textoResposta = await resposta.stream.bytesToString();

      setState(() {
        if (resposta.statusCode == 200) {
          _listaComandas = jsonDecode(textoResposta);
        } else {
          _mensagemErro = '❌ Erro no Servidor: ${resposta.statusCode}\n$textoResposta';
        }
      });
    } catch (e) {
      setState(() => _mensagemErro = '❌ Erro de conexão com o Java.\n$e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de Comandas 📷', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.amber, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              if (_imagensSelecionadas.isNotEmpty)
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _imagensSelecionadas.map((img) {
                    return Container(
                      height: 80, width: 80, decoration: BoxDecoration(border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: kIsWeb ? Image.network(img.path, fit: BoxFit.cover) : Image.file(File(img.path), fit: BoxFit.cover)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pegarImagens, 
                      icon: const Icon(Icons.library_add, color: Colors.black, size: 18), 
                      label: const Text('Selecionar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis), 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 12))
                    ),
                  ),
                  if (_imagensSelecionadas.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _carregando ? null : _enviarParaIA, 
                        icon: const Icon(Icons.route, color: Colors.white, size: 18), 
                        label: Text('Gerar Rota (${_imagensSelecionadas.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis), 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12))
                      ),
                    ),
                  ]
                ],
              ),

              const SizedBox(height: 30),
              if (_carregando) const CircularProgressIndicator(color: Colors.amber)
              else if (_mensagemErro.isNotEmpty) Text(_mensagemErro, style: const TextStyle(color: Colors.redAccent))
              else if (_listaComandas.isNotEmpty)
                ..._listaComandas.map((dados) {
                  var comanda = dados is String ? jsonDecode(dados) : dados;
                  return CardEntrega(comanda: comanda); 
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. O CARTÃO ANIMADO (INTELIGENTE)
// ============================================================================

class CardEntrega extends StatefulWidget {
  final Map<String, dynamic> comanda;
  final bool modoFinanceiro; 
  final bool isPendente;
  final VoidCallback? aoClicarPagar;

  const CardEntrega({
    super.key, 
    required this.comanda, 
    this.modoFinanceiro = false, 
    this.isPendente = true, 
    this.aoClicarPagar
  });

  @override
  State<CardEntrega> createState() => _CardEntregaState();
}

class _CardEntregaState extends State<CardEntrega> with SingleTickerProviderStateMixin {
  late AnimationController _animacaoController;
  late Animation<Color?> _corPiscante;
  late Map<String, dynamic> _comandaAtual; 
  bool _salvandoEdicao = false;

  @override
  void initState() {
    super.initState();
    _comandaAtual = Map.from(widget.comanda); 
    _animacaoController = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true); 
    _corPiscante = ColorTween(begin: Colors.red[900], end: Colors.red[400]).animate(_animacaoController);
  }

  @override
  void dispose() {
    _animacaoController.dispose(); 
    super.dispose();
  }

  void _mostrarDialogoEdicao() {
    TextEditingController ruaController = TextEditingController(text: _comandaAtual['logradouro']);
    TextEditingController numeroController = TextEditingController(text: _comandaAtual['numero']);
    TextEditingController bairroController = TextEditingController(text: _comandaAtual['bairro']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Editar Endereço ✏️', style: TextStyle(color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ruaController, decoration: const InputDecoration(labelText: 'Rua / Avenida', labelStyle: TextStyle(color: Colors.grey))),
              TextField(controller: numeroController, decoration: const InputDecoration(labelText: 'Número', labelStyle: TextStyle(color: Colors.grey))),
              TextField(controller: bairroController, decoration: const InputDecoration(labelText: 'Bairro', labelStyle: TextStyle(color: Colors.grey))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(context); 
                setState(() => _salvandoEdicao = true);

                try {
                  var res = await http.put(
                    Uri.parse('${AppConfig.baseUrl}/${_comandaAtual['id']}/endereco'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'logradouro': ruaController.text, 'numero': numeroController.text, 'bairro': bairroController.text,
                    }),
                  );

                  if (res.statusCode == 200) {
                    setState(() { _comandaAtual = jsonDecode(res.body); });
                    if (!mounted) return; 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Endereço corrigido!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Erro ao salvar'), backgroundColor: Colors.red));
                } finally {
                  setState(() => _salvandoEdicao = false);
                }
              },
              child: const Text('Recalcular GPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_salvandoEdicao) return const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Colors.amber))));

    bool isUrgente = _comandaAtual['urgente'] == true; 
    double dist = _comandaAtual['distanciaEmKm'] != null ? double.parse(_comandaAtual['distanciaEmKm'].toString()) : 0.0;
    double taxa = _comandaAtual['taxaEntrega'] != null ? double.parse(_comandaAtual['taxaEntrega'].toString()) : 0.0;
    
    double custoGasolina = 0.0;
    if (dist > 0 && dist < 999.0) custoGasolina = (dist / ConfigVeiculo.consumoKmL) * ConfigVeiculo.precoCombustivel;
    double lucroReal = taxa - custoGasolina;
    String textoDistancia = (dist <= 0 || dist >= 999.0) ? "GPS Falhou" : "${dist.toStringAsFixed(1)} km";

    if (isUrgente) {
      return AnimatedBuilder(
        animation: _corPiscante,
        builder: (context, child) {
          return _construirCorpoDoCard(corBorda: _corPiscante.value!, corFundo: _corPiscante.value!.withOpacity(0.2), icone: Icons.warning_amber_rounded, textoCabecalho: '🚨 URGENTE: #${_comandaAtual['controle'] ?? 'S/N'}', corTextoCabecalho: Colors.white, distancia: textoDistancia, taxa: taxa, custoGasolina: custoGasolina, lucroReal: lucroReal);
        },
      );
    } 
    return _construirCorpoDoCard(corBorda: Colors.amber, corFundo: Colors.grey[900]!, icone: Icons.inventory_2, textoCabecalho: '📦 Pedido #${_comandaAtual['controle'] ?? 'S/N'}', corTextoCabecalho: Colors.amber, distancia: textoDistancia, taxa: taxa, custoGasolina: custoGasolina, lucroReal: lucroReal);
  }

  Widget _construirCorpoDoCard({required Color corBorda, required Color corFundo, required IconData icone, required String textoCabecalho, required Color corTextoCabecalho, required String distancia, required double taxa, required double custoGasolina, required double lucroReal}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15), color: corFundo, elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: corBorda, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Row(children: [Icon(icone, color: corTextoCabecalho, size: 20), const SizedBox(width: 8), Text(textoCabecalho, style: TextStyle(color: corTextoCabecalho, fontWeight: FontWeight.bold, fontSize: 16))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.two_wheeler, color: Colors.blueAccent, size: 16), const SizedBox(width: 5), Text(distancia, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]))]),
            const Divider(color: Colors.grey, height: 25),
            Text('👤 ${_comandaAtual['nomeCliente']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Expanded(child: Text('📍 ${_comandaAtual['logradouro']}, ${_comandaAtual['numero']} - ${_comandaAtual['bairro']}', style: const TextStyle(color: Colors.grey, fontSize: 14))), 
                if (!widget.modoFinanceiro) 
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20), onPressed: _mostrarDialogoEdicao, tooltip: 'Corrigir Endereço no GPS')
              ]
            ),
            
            const SizedBox(height: 15),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Taxa Bruta da Rota:', style: TextStyle(color: Colors.grey)), Text('R\$ ${taxa.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]), const SizedBox(height: 5), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('⛽ Combustível (Ida):', style: TextStyle(color: Colors.redAccent)), Text('- R\$ ${custoGasolina.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]), const Divider(color: Colors.grey), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('LUCRO LÍQUIDO:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)), Text('R\$ ${lucroReal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18))])])),

            if (widget.modoFinanceiro) ...[
              const SizedBox(height: 15),
              if (widget.isPendente)
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: widget.aoClicarPagar,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('MARCAR COMO PAGO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Text('PAGO E FINALIZADO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))
                    ],
                  ),
                )
            ]
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TELA DE VEÍCULO (CONFIGURAÇÕES)
// ============================================================================

class TelaVeiculo extends StatefulWidget {
  const TelaVeiculo({super.key});
  @override
  State<TelaVeiculo> createState() => _TelaVeiculoState();
}

class _TelaVeiculoState extends State<TelaVeiculo> {
  final TextEditingController _consumoController = TextEditingController(text: ConfigVeiculo.consumoKmL.toString());
  final TextEditingController _precoController = TextEditingController(text: ConfigVeiculo.precoCombustivel.toString());
  
  void _salvarConfiguracoes() {
    setState(() { ConfigVeiculo.consumoKmL = double.tryParse(_consumoController.text.replaceAll(',', '.')) ?? 35.0; ConfigVeiculo.precoCombustivel = double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 5.80; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Dados da moto atualizados com sucesso!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados do Veículo 🏍️', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.amber, foregroundColor: Colors.black, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajuste os valores para o cálculo preciso:', style: TextStyle(color: Colors.grey, fontSize: 16)), const SizedBox(height: 30),
            TextField(controller: _consumoController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Consumo da Moto (km/L)', labelStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.speed, color: Colors.amber), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.amber, width: 2)))), const SizedBox(height: 20),
            TextField(controller: _precoController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Preço do Combustível (R\$ por Litro)', labelStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.local_gas_station, color: Colors.greenAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.greenAccent, width: 2)))), const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: _salvarConfiguracoes, icon: const Icon(Icons.save, color: Colors.black), label: const Text('Salvar Configurações', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))))
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. TELA FINANCEIRO (PRESTAÇÃO DE CONTAS)
// ============================================================================

class TelaFinanceiro extends StatefulWidget {
  const TelaFinanceiro({super.key});
  @override
  State<TelaFinanceiro> createState() => _TelaFinanceiroState();
}

class _TelaFinanceiroState extends State<TelaFinanceiro> {
  List<dynamic> _listaPendentes = [];
  List<dynamic> _listaHistorico = [];
  bool _carregando = true;

  @override
  void initState() { super.initState(); _carregarDadosFinanceiros(); }

  Future<void> _carregarDadosFinanceiros() async {
    setState(() => _carregando = true);
    try {
      var resPendentes = await http.get(Uri.parse('${AppConfig.baseUrl}/pendentes'));
      var resHistorico = await http.get(Uri.parse('${AppConfig.baseUrl}/historico'));
      if (resPendentes.statusCode == 200 && resHistorico.statusCode == 200) {
        setState(() { _listaPendentes = jsonDecode(resPendentes.body); _listaHistorico = jsonDecode(resHistorico.body); _carregando = false; });
      }
    } catch (e) { setState(() => _carregando = false); }
  }

  Future<void> _registrarAcerto(int idComanda) async {
    try {
      var resposta = await http.post(Uri.parse('${AppConfig.baseUrl}/$idComanda/pagar-motoboy'));
      if (resposta.statusCode == 200) { 
        _carregarDadosFinanceiros(); 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pagamento registrado com sucesso!'), backgroundColor: Colors.green)); 
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    double totalAReceber = _listaPendentes.fold(0, (soma, item) => soma + (item['taxaEntrega'] ?? 0.0));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Prestação de Contas 💰', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.amber, foregroundColor: Colors.black, bottom: const TabBar(labelColor: Colors.black, unselectedLabelColor: Colors.black54, indicatorColor: Colors.black, indicatorWeight: 4, tabs: [Tab(icon: Icon(Icons.pending_actions), text: 'Pendentes'), Tab(icon: Icon(Icons.history), text: 'Histórico Pago')])),
        body: _carregando ? const Center(child: CircularProgressIndicator(color: Colors.amber)) : TabBarView(children: [_construirAbaLista(_listaPendentes, totalAReceber, true), _construirAbaLista(_listaHistorico, 0, false)]),
      ),
    );
  }

  Widget _construirAbaLista(List<dynamic> lista, double totalLista, bool isPendente) {
    if (lista.isEmpty) return const Center(child: Text('Nenhuma comanda encontrada aqui! 🍃', style: TextStyle(color: Colors.grey, fontSize: 16)));
    return Column(
      children: [
        if (isPendente) Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.green[900], borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total a Receber:', style: TextStyle(color: Colors.white, fontSize: 18)), Text('R\$ ${totalLista.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold))])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), itemCount: lista.length, itemBuilder: (context, index) { 
          var comanda = lista[index]; 
          return CardEntrega(
            comanda: comanda,
            modoFinanceiro: true,
            isPendente: isPendente,
            aoClicarPagar: isPendente ? () => _registrarAcerto(comanda['id']) : null,
          ); 
        })),
      ],
    );
  }
}

// ============================================================================
// 5. TELA MAPA: CIRCUITO OTIMIZADO COM NAVEGAÇÃO E BAIXA
// ============================================================================

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});
  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  List<dynamic> _listaPendentes = [];
  List<Polyline> _rotasDesenhadas = []; 
  bool _carregandoMapa = true;

  final double latLanchonete = -1.4300;
  final double lonLanchonete = -48.4700;

  @override
  void initState() { 
    super.initState(); 
    _carregarPontosERotasNoMapa(); 
  }

  Future<void> _carregarPontosERotasNoMapa() async {
    setState(() => _carregandoMapa = true);
    
    try {
      var resposta = await http.get(Uri.parse('${AppConfig.baseUrl}/pendentes'));
      if (resposta.statusCode == 200) {
        List<dynamic> comandas = jsonDecode(resposta.body);
        List<Polyline> novasLinhas = [];
        List<dynamic> clientesValidos = comandas.where((c) => c['latitude'] != null && c['longitude'] != null).toList();

        if (clientesValidos.isNotEmpty) {
          String coordenadas = '$lonLanchonete,$latLanchonete';
          int limiteDeEntregas = clientesValidos.length > 11 ? 11 : clientesValidos.length;
          
          for (int i = 0; i < limiteDeEntregas; i++) {
            coordenadas += ';${clientesValidos[i]['longitude']},${clientesValidos[i]['latitude']}';
          }

          final urlOtimizada = 'https://api.mapbox.com/optimized-trips/v1/mapbox/driving/$coordenadas?geometries=geojson&roundtrip=true&source=first&access_token=${AppConfig.mapboxToken}';
          final resMapbox = await http.get(Uri.parse(urlOtimizada));
          
          if (resMapbox.statusCode == 200) {
            final data = jsonDecode(resMapbox.body);
            final trips = data['trips'] as List;
            
            if (trips.isNotEmpty) {
              final coordinatesGeoJson = trips[0]['geometry']['coordinates'] as List;
              List<LatLng> pontosDoCircuito = coordinatesGeoJson.map((coord) => LatLng(coord[1], coord[0])).toList();
              novasLinhas.add(Polyline(points: pontosDoCircuito, strokeWidth: 5.0, color: Colors.blueAccent.withOpacity(0.8)));
            }
          }
        }

        setState(() { 
          _listaPendentes = comandas; 
          _rotasDesenhadas = novasLinhas; 
          _carregandoMapa = false; 
        });
      }
    } catch (e) {
      setState(() => _carregandoMapa = false);
    }
  }

  // --- NOVA FUNÇÃO: Abrir o Google Maps ---
  Future<void> _abrirNavegador(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d"); // Tenta abrir o App do Maps
    final Uri webUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng"); // Plano B (Abre no navegador)

    try {
      bool appAberto = await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      if (!appAberto) await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  // --- NOVA FUNÇÃO: Dar baixa na entrega direto pelo mapa ---
  Future<void> _finalizarEntrega(int idComanda) async {
    Navigator.pop(context); // Fecha o painel flutuante
    setState(() => _carregandoMapa = true);

    try {
      // Reutilizando a rota de pagamento para retirar a comanda das "Pendentes"
      var resposta = await http.post(Uri.parse('${AppConfig.baseUrl}/$idComanda/pagar-motoboy'));
      if (resposta.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Entrega finalizada! Recalculando rota...'), backgroundColor: Colors.green));
        await _carregarPontosERotasNoMapa(); // Recarrega o mapa sem o ponto que foi entregue!
      }
    } catch (e) {
      setState(() => _carregandoMapa = false);
    }
  }

  // --- NOVA FUNÇÃO: Painel flutuante ao clicar no pino ---
  void _mostrarDetalhesDoPino(Map<String, dynamic> comanda) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👤 Cliente: ${comanda['nomeCliente']}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('📍 Endereço: ${comanda['logradouro']}, ${comanda['numero']} - ${comanda['bairro']}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 25),
              
              // Botão de Navegar (Abre Google Maps)
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirNavegador(comanda['latitude'], comanda['longitude']),
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text('Navegar (Google Maps)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 15),

              // Botão de Finalizar Entrega
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _finalizarEntrega(comanda['id']),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Marcar como Entregue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> marcadores = [
      Marker(point: LatLng(latLanchonete, lonLanchonete), width: 60, height: 60, child: const Icon(Icons.storefront, color: Colors.amber, size: 45))
    ];
    
    // Agora os pinos dos clientes são botões!
    for (var comanda in _listaPendentes) {
      if (comanda['latitude'] != null && comanda['longitude'] != null) {
        marcadores.add(
          Marker(
            point: LatLng(comanda['latitude'], comanda['longitude']), 
            width: 50, height: 50, 
            child: GestureDetector(
              onTap: () => _mostrarDetalhesDoPino(comanda), // O clique que abre o painel
              child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
            )
          )
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Circuito de Entregas 🗺️', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.amber, foregroundColor: Colors.black, centerTitle: true),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: LatLng(latLanchonete, lonLanchonete), initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxToken}',
                userAgentPackageName: 'br.com.motoentrega',
              ),
              PolylineLayer(polylines: _rotasDesenhadas),
              MarkerLayer(markers: marcadores),
            ],
          ),
          if (_carregandoMapa) const Center(child: CircularProgressIndicator(color: Colors.amber))
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _carregarPontosERotasNoMapa, backgroundColor: Colors.amber, child: const Icon(Icons.refresh, color: Colors.black)),
    );
  }
}