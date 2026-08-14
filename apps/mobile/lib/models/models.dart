enum UserRole { noivo, cerimonialista, padrinho, convidado }

UserRole userRoleFromDb(String v) => switch (v) {
      'noivo' => UserRole.noivo,
      'cerimonialista' => UserRole.cerimonialista,
      'padrinho' => UserRole.padrinho,
      _ => UserRole.convidado,
    };

extension UserRoleX on UserRole {
  String get dbValue => switch (this) {
        UserRole.noivo => 'noivo',
        UserRole.cerimonialista => 'cerimonialista',
        UserRole.padrinho => 'padrinho',
        UserRole.convidado => 'convidado',
      };

  String get label => switch (this) {
        UserRole.noivo => 'Noivo',
        UserRole.cerimonialista => 'Cerimonialista',
        UserRole.padrinho => 'Padrinho',
        UserRole.convidado => 'Convidado',
      };
}

enum DestinoTarefa { noivos, padrinho }

DestinoTarefa destinoTarefaFromDb(String v) =>
    v == 'padrinho' ? DestinoTarefa.padrinho : DestinoTarefa.noivos;

extension DestinoTarefaX on DestinoTarefa {
  String get dbValue => name;
  String get label =>
      this == DestinoTarefa.padrinho ? 'Padrinho' : 'Noivos';
}

enum GastoStatus { pendente, pago, cancelado }

GastoStatus gastoStatusFromDb(String v) => switch (v) {
      'pago' => GastoStatus.pago,
      'cancelado' => GastoStatus.cancelado,
      _ => GastoStatus.pendente,
    };

extension GastoStatusX on GastoStatus {
  String get dbValue => name;
  String get label => switch (this) {
        GastoStatus.pendente => 'Pendente',
        GastoStatus.pago => 'Pago',
        GastoStatus.cancelado => 'Cancelado',
      };
}

enum TarefaStatus { pendente, aprovado, feito, rejeitado, cancelado }

TarefaStatus tarefaStatusFromDb(String v) => switch (v) {
      'aprovado' => TarefaStatus.aprovado,
      'feito' => TarefaStatus.feito,
      'rejeitado' => TarefaStatus.rejeitado,
      'cancelado' => TarefaStatus.cancelado,
      _ => TarefaStatus.pendente,
    };

extension TarefaStatusX on TarefaStatus {
  String get dbValue => name;
  String get label => switch (this) {
        TarefaStatus.pendente => 'Pendente',
        TarefaStatus.aprovado => 'Aprovado',
        TarefaStatus.feito => 'Feito',
        TarefaStatus.rejeitado => 'Rejeitado',
        TarefaStatus.cancelado => 'Cancelado',
      };
}

enum Prioridade { baixa, media, alta }

Prioridade prioridadeFromDb(String v) => switch (v) {
      'baixa' => Prioridade.baixa,
      'alta' => Prioridade.alta,
      _ => Prioridade.media,
    };

extension PrioridadeX on Prioridade {
  String get dbValue => name;
  String get label => switch (this) {
        Prioridade.baixa => 'Baixa',
        Prioridade.media => 'Média',
        Prioridade.alta => 'Alta',
      };
}

enum LadoConvidado { noivo, noiva, ambos }

LadoConvidado ladoFromDb(String v) => switch (v) {
      'noivo' => LadoConvidado.noivo,
      'noiva' => LadoConvidado.noiva,
      _ => LadoConvidado.ambos,
    };

extension LadoConvidadoX on LadoConvidado {
  String get dbValue => name;
  String get label => switch (this) {
        LadoConvidado.noivo => 'Noivo',
        LadoConvidado.noiva => 'Noiva',
        LadoConvidado.ambos => 'Ambos',
      };
}

enum RsvpStatus { pendente, sim, nao, talvez }

RsvpStatus rsvpFromDb(String v) => switch (v) {
      'sim' => RsvpStatus.sim,
      'nao' => RsvpStatus.nao,
      'talvez' => RsvpStatus.talvez,
      _ => RsvpStatus.pendente,
    };

extension RsvpStatusX on RsvpStatus {
  String get dbValue => name;
  String get label => switch (this) {
        RsvpStatus.pendente => 'Pendente',
        RsvpStatus.sim => 'Sim',
        RsvpStatus.nao => 'Não',
        RsvpStatus.talvez => 'Talvez',
      };
}

enum TipoPadrinho { padrinho, madrinha }

TipoPadrinho tipoPadrinhoFromDb(String v) =>
    v == 'madrinha' ? TipoPadrinho.madrinha : TipoPadrinho.padrinho;

extension TipoPadrinhoX on TipoPadrinho {
  String get dbValue => name;
  String get label => this == TipoPadrinho.madrinha ? 'Madrinha' : 'Padrinho';
}

enum FotoTipo { noivos, evento, outro }

FotoTipo fotoTipoFromDb(String v) => switch (v) {
      'evento' => FotoTipo.evento,
      'outro' => FotoTipo.outro,
      _ => FotoTipo.noivos,
    };

extension FotoTipoX on FotoTipo {
  String get dbValue => name;
  String get label => switch (this) {
        FotoTipo.noivos => 'Noivos',
        FotoTipo.evento => 'Evento',
        FotoTipo.outro => 'Outro',
      };
}

class Profile {
  Profile({
    required this.id,
    required this.role,
    required this.nome,
    this.telefone = '',
    this.email = '',
    this.convidadoId,
    this.temSenha = false,
  });

  final String id;
  final UserRole role;
  final String nome;
  final String telefone;
  final String email;
  final String? convidadoId;
  final bool temSenha;

  bool get isNoivo => role == UserRole.noivo;
  bool get isCerimonialista => role == UserRole.cerimonialista;
  bool get isPadrinho => role == UserRole.padrinho;
  bool get isConvidado => role == UserRole.convidado;
}

class CasamentoConfig {
  CasamentoConfig({
    required this.id,
    required this.nomeNoivo,
    required this.nomeNoiva,
    this.dataCerimonia,
    this.local,
    this.localCerimonia,
    this.enderecoCerimonia,
    this.localFesta,
    this.enderecoFesta,
    this.capaUrl,
    this.whatsapp,
    this.mensagemBoasVindas,
  });

  final String id;
  String nomeNoivo;
  String nomeNoiva;
  DateTime? dataCerimonia;
  /// Legado / resumo do local da cerimônia.
  String? local;
  String? localCerimonia;
  String? enderecoCerimonia;
  String? localFesta;
  String? enderecoFesta;
  String? capaUrl;
  String? whatsapp;
  String? mensagemBoasVindas;

  String get nomesHero => '$nomeNoiva & $nomeNoivo';

  String get cerimoniaTitulo =>
      (localCerimonia?.isNotEmpty == true) ? localCerimonia! : (local ?? '');

  String get cerimoniaEnderecoMaps {
    if (enderecoCerimonia?.isNotEmpty == true) return enderecoCerimonia!;
    return cerimoniaTitulo;
  }

  String get festaTitulo => localFesta ?? '';

  String get festaEnderecoMaps {
    if (enderecoFesta?.isNotEmpty == true) return enderecoFesta!;
    return festaTitulo;
  }

  CasamentoConfig copyWith({
    String? nomeNoivo,
    String? nomeNoiva,
    DateTime? dataCerimonia,
    String? local,
    String? localCerimonia,
    String? enderecoCerimonia,
    String? localFesta,
    String? enderecoFesta,
    String? capaUrl,
    String? whatsapp,
    String? mensagemBoasVindas,
    bool clearCapa = false,
    bool clearData = false,
  }) {
    return CasamentoConfig(
      id: id,
      nomeNoivo: nomeNoivo ?? this.nomeNoivo,
      nomeNoiva: nomeNoiva ?? this.nomeNoiva,
      dataCerimonia: clearData ? null : (dataCerimonia ?? this.dataCerimonia),
      local: local ?? this.local,
      localCerimonia: localCerimonia ?? this.localCerimonia,
      enderecoCerimonia: enderecoCerimonia ?? this.enderecoCerimonia,
      localFesta: localFesta ?? this.localFesta,
      enderecoFesta: enderecoFesta ?? this.enderecoFesta,
      capaUrl: clearCapa ? null : (capaUrl ?? this.capaUrl),
      whatsapp: whatsapp ?? this.whatsapp,
      mensagemBoasVindas: mensagemBoasVindas ?? this.mensagemBoasVindas,
    );
  }
}

class CardapioItem {
  CardapioItem({
    required this.id,
    required this.titulo,
    this.descricao,
    this.ordem = 0,
  });

  final String id;
  String titulo;
  String? descricao;
  int ordem;
}

class AtracaoItem {
  AtracaoItem({
    required this.id,
    required this.titulo,
    this.descricao,
    this.horario,
    this.ordem = 0,
  });

  final String id;
  String titulo;
  String? descricao;
  String? horario;
  int ordem;
}

class Gasto {
  Gasto({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.valorPrevisto,
    this.valorReal,
    this.status = GastoStatus.pendente,
    this.dataPrevista,
    this.dataPagamento,
    this.observacoes,
  });

  final String id;
  String descricao;
  String categoria;
  double valorPrevisto;
  double? valorReal;
  GastoStatus status;
  DateTime? dataPrevista;
  DateTime? dataPagamento;
  String? observacoes;
}

class Tarefa {
  Tarefa({
    required this.id,
    required this.titulo,
    this.descricao,
    this.status = TarefaStatus.pendente,
    this.prioridade = Prioridade.media,
    this.prazo,
    this.destino = DestinoTarefa.noivos,
    this.padrinhoId,
    this.criadoPor,
  });

  final String id;
  String titulo;
  String? descricao;
  TarefaStatus status;
  Prioridade prioridade;
  DateTime? prazo;
  DestinoTarefa destino;
  String? padrinhoId;
  String? criadoPor;
}

class Compromisso {
  Compromisso({
    required this.id,
    required this.titulo,
    required this.inicio,
    this.fim,
    this.descricao,
    this.local,
    this.criadoPor,
  });

  final String id;
  String titulo;
  DateTime inicio;
  DateTime? fim;
  String? descricao;
  String? local;
  String? criadoPor;
}

enum TipoAcompanhante { esposa, amigo, filho }

TipoAcompanhante tipoAcompanhanteFromDb(String v) => switch (v) {
      'esposa' => TipoAcompanhante.esposa,
      'filho' => TipoAcompanhante.filho,
      _ => TipoAcompanhante.amigo,
    };

extension TipoAcompanhanteX on TipoAcompanhante {
  String get dbValue => name;
  String get label => switch (this) {
        TipoAcompanhante.esposa => 'Esposa/esposo',
        TipoAcompanhante.amigo => 'Amigo(a)',
        TipoAcompanhante.filho => 'Filho(a)',
      };

  bool get isCrianca => this == TipoAcompanhante.filho;
}

class Acompanhante {
  Acompanhante({
    required this.id,
    required this.nome,
    required this.tipo,
    this.rsvp = RsvpStatus.pendente,
  });

  final String id;
  String nome;
  TipoAcompanhante tipo;
  RsvpStatus rsvp;
}

class Convidado {
  Convidado({
    required this.id,
    required this.nome,
    this.telefone,
    this.email,
    this.lado = LadoConvidado.ambos,
    this.mesa,
    this.ehCrianca = false,
    List<Acompanhante>? acompanhantesLista,
    this.rsvp = RsvpStatus.pendente,
    this.observacoes,
    this.userId,
    this.token,
  }) : acompanhantesLista = acompanhantesLista ?? [];

  final String id;
  String nome;
  String? telefone;
  String? email;
  LadoConvidado lado;
  String? mesa;
  bool ehCrianca;
  List<Acompanhante> acompanhantesLista;
  RsvpStatus rsvp;
  String? observacoes;
  String? userId;
  String? token;

  int get acompanhantes => acompanhantesLista.length;

  int get totalPessoas => 1 + acompanhantes;

  int get totalAdultos =>
      (ehCrianca ? 0 : 1) +
      acompanhantesLista.where((a) => !a.tipo.isCrianca).length;

  int get totalCriancas =>
      (ehCrianca ? 1 : 0) +
      acompanhantesLista.where((a) => a.tipo.isCrianca).length;

  int get confirmadosPessoas =>
      (rsvp == RsvpStatus.sim ? 1 : 0) +
      acompanhantesLista.where((a) => a.rsvp == RsvpStatus.sim).length;

  int get confirmadosAdultos =>
      (rsvp == RsvpStatus.sim && !ehCrianca ? 1 : 0) +
      acompanhantesLista
          .where((a) => a.rsvp == RsvpStatus.sim && !a.tipo.isCrianca)
          .length;

  int get confirmadosCriancas =>
      (rsvp == RsvpStatus.sim && ehCrianca ? 1 : 0) +
      acompanhantesLista
          .where((a) => a.rsvp == RsvpStatus.sim && a.tipo.isCrianca)
          .length;
}

/// Convite por token (cerimonialista, ou convidado/padrinho sem e-mail).
class ConviteAcesso {
  ConviteAcesso({
    required this.id,
    required this.token,
    required this.role,
    required this.nome,
    this.convidadoId,
    this.ativo = true,
  });

  final String id;
  String token;
  UserRole role;
  String nome;
  String? convidadoId;
  bool ativo;
}

enum TipoDespedida { solteiro, solteira }

TipoDespedida tipoDespedidaFromDb(String v) =>
    v == 'solteira' ? TipoDespedida.solteira : TipoDespedida.solteiro;

extension TipoDespedidaX on TipoDespedida {
  String get dbValue => name;
  String get label =>
      this == TipoDespedida.solteira ? 'Despedida da noiva' : 'Despedida do noivo';
  String get labelCurto =>
      this == TipoDespedida.solteira ? 'Noiva' : 'Noivo';
}

class DespedidaEvento {
  DespedidaEvento({
    required this.tipo,
    this.data,
    this.local,
    this.endereco,
    this.observacoes,
  });

  TipoDespedida tipo;
  DateTime? data;
  String? local;
  String? endereco;
  String? observacoes;
}

class DespedidaParticipante {
  DespedidaParticipante({
    required this.id,
    required this.nome,
    required this.tipo,
    this.telefone,
    this.confirmado = false,
    this.observacoes,
    this.convidadoId,
  });

  final String id;
  String nome;
  TipoDespedida tipo;
  String? telefone;
  bool confirmado;
  String? observacoes;
  String? convidadoId;
}

class Padrinho {
  Padrinho({
    required this.id,
    required this.convidadoId,
    required this.tipo,
    this.papel,
    this.ordem = 0,
  });

  final String id;
  final String convidadoId;
  TipoPadrinho tipo;
  String? papel;
  int ordem;
}

class Foto {
  Foto({
    required this.id,
    required this.tipo,
    required this.url,
    this.legenda,
    this.publico = false,
  });

  final String id;
  FotoTipo tipo;
  String url;
  String? legenda;
  bool publico;
}

class Presente {
  Presente({
    required this.id,
    required this.nome,
    this.descricao,
    this.link,
    this.valorEstimado,
    this.imagemUrl,
    this.ativo = true,
    this.reservadoPorConvidadoId,
    this.reservadoEm,
  });

  final String id;
  String nome;
  String? descricao;
  String? link;
  double? valorEstimado;
  String? imagemUrl;
  bool ativo;
  String? reservadoPorConvidadoId;
  DateTime? reservadoEm;

  bool get reservado => reservadoPorConvidadoId != null;
}
