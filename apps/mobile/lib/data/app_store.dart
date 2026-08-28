import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/models.dart';
import 'api_client.dart';

class AppStore extends ChangeNotifier {
  AppStore({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  final _uuid = const Uuid();

  bool ready = false;
  String? error;
  Profile? currentUser;
  CasamentoConfig config = CasamentoConfig(
    id: 'casamento-1',
    nomeNoivo: AppConstants.fallbackNomeNoivo,
    nomeNoiva: AppConstants.fallbackNomeNoiva,
    mensagemBoasVindas: 'Bem-vindos ao nosso casamento!',
  );

  final List<Gasto> gastos = [];
  final List<Tarefa> tarefas = [];
  final List<Compromisso> compromissos = [];
  final List<Convidado> convidados = [];
  final List<Padrinho> padrinhos = [];
  final List<Foto> fotos = [];
  final List<Presente> presentes = [];
  final List<CardapioItem> cardapio = [];
  final List<AtracaoItem> atracoes = [];
  final List<ConviteAcesso> convites = [];
  final List<DespedidaParticipante> despedidaParticipantes = [];
  final List<DespedidaEvento> despedidas = [];

  bool get isLoggedIn => currentUser != null;
  bool get isNoivo => currentUser?.isNoivo ?? false;
  bool get isCerimonialista => currentUser?.isCerimonialista ?? false;
  bool get isPadrinho => currentUser?.isPadrinho ?? false;
  bool get isConvidado => currentUser?.isConvidado ?? false;
  bool get isGestao => isNoivo || isCerimonialista;

  Convidado? get meuConvidado {
    final cid = currentUser?.convidadoId;
    if (cid != null && cid.isNotEmpty) {
      try {
        return convidados.firstWhere((c) => c.id == cid);
      } catch (_) {}
    }
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      return convidados.firstWhere((c) => c.userId == uid);
    } catch (_) {
      return null;
    }
  }

  Padrinho? get meuPadrinho {
    final c = meuConvidado;
    if (c == null) return null;
    try {
      return padrinhos.firstWhere((p) => p.convidadoId == c.id);
    } catch (_) {
      return null;
    }
  }

  Convidado? convidadoById(String? id) {
    if (id == null) return null;
    try {
      return convidados.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalPrevisto => gastos
      .where((g) => g.status != GastoStatus.cancelado)
      .fold(0.0, (a, g) => a + g.valorPrevisto);

  double get totalPago => gastos
      .where((g) => g.status == GastoStatus.pago)
      .fold(0.0, (a, g) => a + (g.valorReal ?? g.valorPrevisto));

  double get totalRestante =>
      (totalPrevisto - totalPago).clamp(0, double.infinity);

  int countRsvp(RsvpStatus s) => convidados.where((c) => c.rsvp == s).length;

  int get totalConvidadosPessoas =>
      convidados.fold(0, (a, c) => a + c.totalPessoas);

  int get totalAdultos => convidados.fold(0, (a, c) => a + c.totalAdultos);

  int get totalCriancas => convidados.fold(0, (a, c) => a + c.totalCriancas);

  int get totalConfirmadosPessoas =>
      convidados.fold(0, (a, c) => a + c.confirmadosPessoas);

  int get totalConfirmadosAdultos =>
      convidados.fold(0, (a, c) => a + c.confirmadosAdultos);

  int get totalConfirmadosCriancas =>
      convidados.fold(0, (a, c) => a + c.confirmadosCriancas);

  String gerarToken({String prefix = 'LD'}) {
    final raw = _uuid.v4().replaceAll('-', '').substring(0, 6).toUpperCase();
    return '$prefix-$raw';
  }

  String homeRouteForRole() {
    if (isNoivo) return '/noivo';
    if (isCerimonialista) return '/cerimonialista';
    if (isPadrinho) return '/padrinho';
    return '/convidado';
  }

  List<Foto> get fotosVisiveis => fotos.where((f) => f.publico).toList();

  List<Tarefa> get minhasTarefasPadrinho {
    final pid = meuPadrinho?.id;
    if (pid == null) return [];
    return tarefas
        .where(
          (t) => t.destino == DestinoTarefa.padrinho && t.padrinhoId == pid,
        )
        .toList();
  }

  DespedidaEvento? eventoDespedida(TipoDespedida tipo) {
    try {
      return despedidas.firstWhere((e) => e.tipo == tipo);
    } catch (_) {
      return null;
    }
  }

  List<DespedidaParticipante> participantesDespedida(TipoDespedida tipo) =>
      despedidaParticipantes.where((p) => p.tipo == tipo).toList();

  List<Compromisso> compromissosDoDia(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return compromissos.where((c) {
      final i = DateTime(c.inicio.year, c.inicio.month, c.inicio.day);
      return i == d;
    }).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  List<Compromisso> compromissosProximos({int dias = 14}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: dias));
    return compromissos.where((c) {
      return !c.inicio.isBefore(start) && c.inicio.isBefore(end);
    }).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  List<Acompanhante> _parseAcomps(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Acompanhante(
        id: m['id']?.toString() ?? _uuid.v4(),
        nome: m['nome']?.toString() ?? '',
        tipo: tipoAcompanhanteFromDb(m['tipo']?.toString() ?? 'amigo'),
        rsvp: rsvpFromDb(m['rsvp']?.toString() ?? 'pendente'),
      );
    }).toList();
  }

  void _applyBootstrap(Map<String, dynamic> data) {
    final u = data['user'] as Map<String, dynamic>?;
    if (u != null) {
      currentUser = Profile(
        id: u['id'].toString(),
        role: userRoleFromDb(u['role']?.toString() ?? 'convidado'),
        nome: u['nome']?.toString() ?? '',
        telefone: u['telefone']?.toString() ?? '',
        email: u['email']?.toString() ?? '',
        convidadoId: u['convidadoId']?.toString(),
        temSenha: u['temSenha'] == true,
      );
    }

    final c = data['config'] as Map<String, dynamic>?;
    if (c != null) {
      config = CasamentoConfig(
        id: c['id'].toString(),
        nomeNoivo: c['nomeNoivo']?.toString() ?? AppConstants.fallbackNomeNoivo,
        nomeNoiva: c['nomeNoiva']?.toString() ?? AppConstants.fallbackNomeNoiva,
        dataCerimonia: _parseDate(c['dataCerimonia']),
        local: c['local']?.toString(),
        localCerimonia: c['localCerimonia']?.toString(),
        enderecoCerimonia: c['enderecoCerimonia']?.toString(),
        localFesta: c['localFesta']?.toString(),
        enderecoFesta: c['enderecoFesta']?.toString(),
        capaUrl: c['capaUrl']?.toString(),
        whatsapp: c['whatsapp']?.toString(),
        mensagemBoasVindas: c['mensagemBoasVindas']?.toString(),
      );
    }

    gastos
      ..clear()
      ..addAll(((data['gastos'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Gasto(
          id: m['id'].toString(),
          descricao: m['descricao']?.toString() ?? '',
          categoria: m['categoria']?.toString() ?? '',
          valorPrevisto: (m['valorPrevisto'] as num?)?.toDouble() ?? 0,
          valorReal: (m['valorReal'] as num?)?.toDouble(),
          status: gastoStatusFromDb(m['status']?.toString() ?? 'pendente'),
          dataPrevista: _parseDate(m['dataPrevista']),
          dataPagamento: _parseDate(m['dataPagamento']),
          observacoes: m['observacoes']?.toString(),
        );
      }));

    tarefas
      ..clear()
      ..addAll(((data['tarefas'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Tarefa(
          id: m['id'].toString(),
          titulo: m['titulo']?.toString() ?? '',
          descricao: m['descricao']?.toString(),
          status: tarefaStatusFromDb(m['status']?.toString() ?? 'pendente'),
          prioridade: prioridadeFromDb(m['prioridade']?.toString() ?? 'media'),
          destino: destinoTarefaFromDb(m['destino']?.toString() ?? 'noivos'),
          prazo: _parseDate(m['prazo']),
          padrinhoId: m['padrinhoId']?.toString(),
          criadoPor: m['criadoPor']?.toString(),
        );
      }));

    compromissos
      ..clear()
      ..addAll(((data['compromissos'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Compromisso(
          id: m['id'].toString(),
          titulo: m['titulo']?.toString() ?? '',
          inicio: _parseDate(m['inicio']) ?? DateTime.now(),
          fim: _parseDate(m['fim']),
          descricao: m['descricao']?.toString(),
          local: m['local']?.toString(),
          criadoPor: m['criadoPor']?.toString(),
        );
      }));

    convidados
      ..clear()
      ..addAll(((data['convidados'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Convidado(
          id: m['id'].toString(),
          nome: m['nome']?.toString() ?? '',
          telefone: m['telefone']?.toString(),
          email: m['email']?.toString(),
          lado: ladoFromDb(m['lado']?.toString() ?? 'ambos'),
          mesa: m['mesa']?.toString(),
          ehCrianca: m['ehCrianca'] == true,
          acompanhantesLista: _parseAcomps(m['acompanhantesLista']),
          rsvp: rsvpFromDb(m['rsvp']?.toString() ?? 'pendente'),
          observacoes: m['observacoes']?.toString(),
          userId: m['userId']?.toString(),
          token: m['token']?.toString(),
        );
      }));

    padrinhos
      ..clear()
      ..addAll(((data['padrinhos'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Padrinho(
          id: m['id'].toString(),
          convidadoId: m['convidadoId'].toString(),
          tipo: tipoPadrinhoFromDb(m['tipo']?.toString() ?? 'padrinho'),
          papel: m['papel']?.toString(),
          ordem: (m['ordem'] as num?)?.toInt() ?? 0,
        );
      }));

    fotos
      ..clear()
      ..addAll(((data['fotos'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Foto(
          id: m['id'].toString(),
          tipo: fotoTipoFromDb(m['tipo']?.toString() ?? 'noivos'),
          url: m['url']?.toString() ?? '',
          legenda: m['legenda']?.toString(),
          publico: m['publico'] == true,
        );
      }));

    presentes
      ..clear()
      ..addAll(((data['presentes'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Presente(
          id: m['id'].toString(),
          nome: m['nome']?.toString() ?? '',
          descricao: m['descricao']?.toString(),
          link: m['link']?.toString(),
          valorEstimado: (m['valorEstimado'] as num?)?.toDouble(),
          imagemUrl: m['imagemUrl']?.toString(),
          ativo: m['ativo'] != false,
          reservadoPorConvidadoId: m['reservadoPorConvidadoId']?.toString(),
          reservadoEm: _parseDate(m['reservadoEm']),
        );
      }));

    cardapio
      ..clear()
      ..addAll(((data['cardapio'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return CardapioItem(
          id: m['id'].toString(),
          titulo: m['titulo']?.toString() ?? '',
          descricao: m['descricao']?.toString(),
          ordem: (m['ordem'] as num?)?.toInt() ?? 0,
        );
      }));

    atracoes
      ..clear()
      ..addAll(((data['atracoes'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return AtracaoItem(
          id: m['id'].toString(),
          titulo: m['titulo']?.toString() ?? '',
          descricao: m['descricao']?.toString(),
          horario: m['horario']?.toString(),
          ordem: (m['ordem'] as num?)?.toInt() ?? 0,
        );
      }));

    convites
      ..clear()
      ..addAll(((data['convites'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return ConviteAcesso(
          id: m['id'].toString(),
          token: m['token']?.toString() ?? '',
          role: userRoleFromDb(m['role']?.toString() ?? 'convidado'),
          nome: m['nome']?.toString() ?? '',
          convidadoId: m['convidadoId']?.toString(),
          ativo: m['ativo'] != false,
        );
      }));

    despedidas
      ..clear()
      ..addAll(((data['despedidas'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return DespedidaEvento(
          tipo: tipoDespedidaFromDb(m['tipo']?.toString() ?? 'solteiro'),
          data: _parseDate(m['data']),
          local: m['local']?.toString(),
          endereco: m['endereco']?.toString(),
          observacoes: m['observacoes']?.toString(),
        );
      }));

    despedidaParticipantes
      ..clear()
      ..addAll(((data['despedidaParticipantes'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return DespedidaParticipante(
          id: m['id'].toString(),
          nome: m['nome']?.toString() ?? '',
          tipo: tipoDespedidaFromDb(m['tipo']?.toString() ?? 'solteiro'),
          telefone: m['telefone']?.toString(),
          confirmado: m['confirmado'] == true,
          observacoes: m['observacoes']?.toString(),
          convidadoId: m['convidadoId']?.toString(),
        );
      }));
  }

  Future<void> init() async {
    try {
      await _api.loadToken();
      if (_api.hasToken) {
        await refreshAll();
      } else {
        try {
          final pub = await _api.get('/api/public/config', auth: false);
          if (pub['id'] != null) {
            config = CasamentoConfig(
              id: pub['id'].toString(),
              nomeNoivo:
                  pub['nomeNoivo']?.toString() ?? AppConstants.fallbackNomeNoivo,
              nomeNoiva:
                  pub['nomeNoiva']?.toString() ?? AppConstants.fallbackNomeNoiva,
              dataCerimonia: _parseDate(pub['dataCerimonia']),
              local: pub['local']?.toString(),
              localCerimonia: pub['localCerimonia']?.toString(),
              enderecoCerimonia: pub['enderecoCerimonia']?.toString(),
              localFesta: pub['localFesta']?.toString(),
              enderecoFesta: pub['enderecoFesta']?.toString(),
              capaUrl: pub['capaUrl']?.toString(),
              whatsapp: pub['whatsapp']?.toString(),
              mensagemBoasVindas: pub['mensagemBoasVindas']?.toString(),
            );
          }
        } catch (_) {}
      }
      ready = true;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      ready = true;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    final data = await _api.get('/api/bootstrap');
    _applyBootstrap(data);
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _api.post('/api/auth/login', {
        'email': email.trim(),
        'password': password,
      }, auth: false);
      await _api.setToken(res['accessToken']?.toString());
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Profile>> listNoivos() async {
    final raw = await _api.getList('/api/auth/noivos');
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Profile(
        id: m['id'].toString(),
        role: userRoleFromDb(m['role']?.toString() ?? 'noivo'),
        nome: m['nome']?.toString() ?? '',
        telefone: m['telefone']?.toString() ?? '',
        email: m['email']?.toString() ?? '',
      );
    }).toList();
  }

  Future<String?> inviteParceiro({
    required String nome,
    required String email,
    required String password,
    String? telefone,
  }) async {
    try {
      await _api.post('/api/auth/invite-parceiro', {
        'nome': nome.trim(),
        'email': email.trim(),
        'password': password,
        if (telefone != null && telefone.trim().isNotEmpty)
          'telefone': telefone.trim(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.put('/api/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> completarCadastroConvidado({
    required String email,
    required String password,
    String? nome,
  }) async {
    try {
      await _api.post('/api/auth/completar-cadastro', {
        'email': email.trim(),
        'password': password,
        if (nome != null && nome.trim().isNotEmpty) 'nome': nome.trim(),
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> loginWithToken(String tokenRaw) async {
    try {
      final res = await _api.post('/api/auth/token', {
        'token': tokenRaw.trim(),
      }, auth: false);
      await _api.setToken(res['accessToken']?.toString());
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _api.setToken(null);
    currentUser = null;
    gastos.clear();
    tarefas.clear();
    compromissos.clear();
    convidados.clear();
    padrinhos.clear();
    fotos.clear();
    presentes.clear();
    cardapio.clear();
    atracoes.clear();
    convites.clear();
    despedidaParticipantes.clear();
    despedidas.clear();
    notifyListeners();
  }

  Future<String?> criarConviteCerimonialista(String nome) async {
    try {
      await _api.post('/api/convites/cerimonialista', {'nome': nome});
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> regenerarTokenConvidado(String convidadoId) async {
    try {
      await _api.post('/api/convidados/$convidadoId/token', {});
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> salvarConfig(CasamentoConfig c) async {
    try {
      await _api.put('/api/config', {
        'nomeNoivo': c.nomeNoivo,
        'nomeNoiva': c.nomeNoiva,
        'dataCerimonia': c.dataCerimonia?.toIso8601String(),
        'local': c.local,
        'localCerimonia': c.localCerimonia,
        'enderecoCerimonia': c.enderecoCerimonia,
        'localFesta': c.localFesta,
        'enderecoFesta': c.enderecoFesta,
        'capaUrl': c.capaUrl,
        'whatsapp': c.whatsapp,
        'mensagemBoasVindas': c.mensagemBoasVindas,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> uploadCapa(Uint8List bytes, String ext) async {
    // Upload local: guarda data URL no config (MVP sem storage).
    final b64 = base64Encode(bytes);
    final mime = ext.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';
    final url = 'data:$mime;base64,$b64';
    return salvarConfig(config.copyWith(capaUrl: url));
  }

  Future<String?> upsertGasto(Gasto g) async {
    try {
      await _api.post('/api/gastos', {
        if (g.id.isNotEmpty && !g.id.startsWith('local-')) 'id': g.id,
        'descricao': g.descricao,
        'categoria': g.categoria,
        'valorPrevisto': g.valorPrevisto,
        'valorReal': g.valorReal,
        'status': g.status.dbValue,
        'dataPrevista': g.dataPrevista?.toIso8601String(),
        'dataPagamento': g.dataPagamento?.toIso8601String(),
        'observacoes': g.observacoes,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerGasto(String id) async {
    try {
      await _api.delete('/api/gastos/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertTarefa(Tarefa t) async {
    try {
      await _api.post('/api/tarefas', {
        if (t.id.isNotEmpty && !t.id.startsWith('local-')) 'id': t.id,
        'titulo': t.titulo,
        'descricao': t.descricao,
        'status': t.status.dbValue,
        'prioridade': t.prioridade.dbValue,
        'destino': t.destino.dbValue,
        'prazo': t.prazo?.toIso8601String(),
        'padrinhoId': t.padrinhoId,
        'criadoPor': t.criadoPor ?? currentUser?.id,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertCompromisso(Compromisso c) async {
    try {
      await _api.post('/api/compromissos', {
        if (c.id.isNotEmpty && !c.id.startsWith('local-')) 'id': c.id,
        'titulo': c.titulo,
        'descricao': c.descricao,
        'inicio': c.inicio.toIso8601String(),
        'fim': c.fim?.toIso8601String(),
        'local': c.local,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerCompromisso(String id) async {
    try {
      await _api.delete('/api/compromissos/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> marcarTarefaFeita(String id) async {
    try {
      await _api.post('/api/tarefas/$id/feito', {});
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertConvidado(Convidado c) async {
    try {
      await _api.post('/api/convidados', {
        if (c.id.isNotEmpty && !c.id.startsWith('local-')) 'id': c.id,
        'nome': c.nome,
        'telefone': c.telefone,
        'email': c.email,
        'lado': c.lado.dbValue,
        'mesa': c.mesa,
        'ehCrianca': c.ehCrianca,
        'acompanhantesLista': c.acompanhantesLista
            .map((a) => {
                  'id': a.id,
                  'nome': a.nome,
                  'tipo': a.tipo.dbValue,
                  'rsvp': a.rsvp.dbValue,
                })
            .toList(),
        'rsvp': c.rsvp.dbValue,
        'observacoes': c.observacoes,
        'token': c.token,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerConvidado(String id) async {
    try {
      await _api.delete('/api/convidados/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerTarefa(String id) async {
    try {
      await _api.delete('/api/tarefas/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerPresente(String id) async {
    try {
      await _api.delete('/api/presentes/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> atualizarRsvp(
    RsvpStatus status, {
    String? acompanhanteId,
  }) async {
    try {
      await _api.put('/api/rsvp', {
        'status': status.dbValue,
        if (acompanhanteId != null) 'acompanhanteId': acompanhanteId,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> vincularPadrinho({
    required String convidadoId,
    required TipoPadrinho tipo,
    String? papel,
    int ordem = 0,
  }) async {
    try {
      await _api.post('/api/padrinhos', {
        'convidadoId': convidadoId,
        'tipo': tipo.dbValue,
        'papel': papel,
        'ordem': ordem,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerPadrinho(String id) async {
    try {
      await _api.delete('/api/padrinhos/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertPresente(Presente p) async {
    try {
      await _api.post('/api/presentes', {
        if (p.id.isNotEmpty && !p.id.startsWith('local-')) 'id': p.id,
        'nome': p.nome,
        'descricao': p.descricao,
        'link': p.link,
        'valorEstimado': p.valorEstimado,
        'imagemUrl': p.imagemUrl,
        'ativo': p.ativo,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> reservarPresente(String presenteId) async {
    try {
      await _api.post('/api/presentes/$presenteId/reservar', {});
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> cancelarReservaPresente(String presenteId) async {
    try {
      await _api.post('/api/presentes/$presenteId/cancelar-reserva', {});
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> adicionarFotos({
    required List<({Uint8List bytes, String name})> arquivos,
    FotoTipo tipo = FotoTipo.evento,
    String? legenda,
    bool publico = false,
  }) async {
    if (arquivos.isEmpty) return 'Selecione ao menos uma foto';
    try {
      final files = <http.MultipartFile>[];
      for (final item in arquivos) {
        files.add(
          http.MultipartFile.fromBytes(
            'files',
            item.bytes,
            filename: item.name,
          ),
        );
      }
      await _api.postMultipart(
        '/api/fotos',
        fields: {
          'tipo': tipo.dbValue,
          if (legenda != null && legenda.isNotEmpty) 'legenda': legenda,
          'publico': publico ? 'true' : 'false',
        },
        files: files,
      );
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> atualizarFoto(Foto f) async {
    try {
      await _api.put('/api/fotos', {
        'id': f.id,
        'tipo': f.tipo.dbValue,
        'legenda': f.legenda,
        'publico': f.publico,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerFoto(String id) async {
    try {
      await _api.delete('/api/fotos/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  String novoId() => 'local-${_uuid.v4()}';

  Future<String?> upsertCardapio(CardapioItem item) async {
    try {
      await _api.post('/api/cardapio', {
        if (item.id.isNotEmpty && !item.id.startsWith('local-')) 'id': item.id,
        'titulo': item.titulo,
        'descricao': item.descricao,
        'ordem': item.ordem,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerCardapio(String id) async {
    try {
      await _api.delete('/api/cardapio/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertAtracao(AtracaoItem item) async {
    try {
      await _api.post('/api/atracoes', {
        if (item.id.isNotEmpty && !item.id.startsWith('local-')) 'id': item.id,
        'titulo': item.titulo,
        'descricao': item.descricao,
        'horario': item.horario,
        'ordem': item.ordem,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerAtracao(String id) async {
    try {
      await _api.delete('/api/atracoes/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> salvarDespedidaEvento(DespedidaEvento e) async {
    try {
      await _api.put('/api/despedida/evento', {
        'tipo': e.tipo.dbValue,
        'data': e.data?.toIso8601String(),
        'local': e.local,
        'endereco': e.endereco,
        'observacoes': e.observacoes,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> upsertDespedidaParticipante(DespedidaParticipante p) async {
    try {
      await _api.post('/api/despedida/participantes', {
        if (p.id.isNotEmpty && !p.id.startsWith('local-')) 'id': p.id,
        'nome': p.nome,
        'tipo': p.tipo.dbValue,
        'telefone': p.telefone,
        'confirmado': p.confirmado,
        'observacoes': p.observacoes,
        'convidadoId': p.convidadoId,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removerDespedidaParticipante(String id) async {
    try {
      await _api.delete('/api/despedida/participantes/$id');
      await refreshAll();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
