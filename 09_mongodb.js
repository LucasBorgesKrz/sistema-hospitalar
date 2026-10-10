// Sistema Hospitalar - Introdução ao MongoDB
const h = db.getSiblingDB('hospital_mongo');
h.dropDatabase();

// ---------- MEDICOS (especialidade EMBUTIDA) ----------
const m = h.medicos.insertMany([
  { nome: "Dra. Ana Souza",    crm: "CRM-SP 12345", especialidade: { nome: "Cardiologia",  area: "Clínica" }, plantao: ["seg", "qua"] },
  { nome: "Dr. Bruno Lima",    crm: "CRM-SP 23456", especialidade: { nome: "Pediatria" }, convenios_aceitos: ["Unimed", "Bradesco Saúde"] },
  { nome: "Dra. Carla Mendes", crm: "CRM-SP 34567", especialidade: { nome: "Ortopedia" }, telemedicina: true },
  { nome: "Dr. Diego Rocha",   crm: "CRM-SP 45678", especialidade: { nome: "Dermatologia" } }
]).insertedIds;

// ---------- PACIENTES (convênio e contatos EMBUTIDOS) ----------
const p = h.pacientes.insertMany([
  { nome: "Maria Silva",     cpf: "111.111.111-11", nascimento: new Date("1985-04-12"),
    convenio: { nome: "Unimed", plano: "Premium", carteirinha: "U-001" },
    contatos: [{ tipo: "celular", valor: "(11) 90000-0001" }, { tipo: "email", valor: "maria@email.com" }],
    alergias: ["dipirona"] },
  { nome: "João Pereira",    cpf: "222.222.222-22", nascimento: new Date("1979-09-30"),
    convenio: { nome: "Bradesco Saúde", plano: "Standard", carteirinha: "B-777" },
    contatos: [{ tipo: "celular", valor: "(11) 90000-0002" }] },
  { nome: "Paula Costa",     cpf: "333.333.333-33", nascimento: new Date("1992-01-05"),
    contatos: [{ tipo: "email", valor: "paula@email.com" }] },                       // particular: sem convênio
  { nome: "Carlos Nunes",    cpf: "444.444.444-44", nascimento: new Date("2015-07-21"),
    convenio: { nome: "Unimed", plano: "Básico", carteirinha: "U-002" },
    acompanhante: { nome: "Lúcia Nunes", parentesco: "mãe" } },                      // campo só de alguns
  { nome: "Fernanda Alves",  cpf: "555.555.555-55", nascimento: new Date("1968-11-18"),
    convenio: { nome: "SulAmérica", plano: "Plus", carteirinha: "S-123" },
    alergias: ["penicilina", "látex"] },
  { nome: "Ricardo Gomes",   cpf: "666.666.666-66", nascimento: new Date("1950-02-02"),
    observacoes: "Paciente idoso, mobilidade reduzida" }
]).insertedIds;

// ---------- CONSULTAS (REFERENCIA paciente_id e medico_id; receitas EMBUTIDAS) ----------
h.consultas.insertMany([
  { paciente_id: p[0], medico_id: m[0], data_hora: new Date("2026-03-10T09:00:00Z"), tipo: "retorno",  status: "realizada", valor: 250, diagnostico: "hipertensão arterial controlada",
    receitas: [{ medicamento: "Losartana", dose: "50mg 1x ao dia" }] },
  { paciente_id: p[0], medico_id: m[0], data_hora: new Date("2026-05-12T10:30:00Z"), tipo: "rotina",   status: "agendada",  valor: 250 },
  { paciente_id: p[1], medico_id: m[2], data_hora: new Date("2026-03-15T14:00:00Z"), tipo: "primeira", status: "realizada", valor: 300, diagnostico: "tendinite no ombro direito",
    receitas: [{ medicamento: "Ibuprofeno", dose: "400mg 8/8h por 5 dias" }] },
  { paciente_id: p[2], medico_id: m[3], data_hora: new Date("2026-04-02T11:00:00Z"), tipo: "primeira", status: "realizada", valor: 350, diagnostico: "dermatite de contato" },
  { paciente_id: p[3], medico_id: m[1], data_hora: new Date("2026-04-08T08:30:00Z"), tipo: "rotina",   status: "realizada", valor: 200, diagnostico: "avaliação de crescimento normal" },
  { paciente_id: p[4], medico_id: m[0], data_hora: new Date("2026-04-20T16:00:00Z"), tipo: "primeira", status: "cancelada", valor: 250 },
  { paciente_id: p[4], medico_id: m[2], data_hora: new Date("2026-05-03T09:30:00Z"), tipo: "retorno",  status: "agendada",  valor: 300 },
  { paciente_id: p[5], medico_id: m[0], data_hora: new Date("2026-05-07T15:00:00Z"), tipo: "rotina",   status: "realizada", valor: 250, diagnostico: "insuficiência cardíaca leve",
    receitas: [{ medicamento: "Furosemida", dose: "40mg pela manhã" }, { medicamento: "Enalapril", dose: "10mg 2x ao dia" }] }
]);

print("\n== Totais ==");
printjson({ medicos: h.medicos.countDocuments(), pacientes: h.pacientes.countDocuments(), consultas: h.consultas.countDocuments() });

// ---------- CONSULTAS: find + sort + projeção ----------
print("\n== 1) Pacientes da Unimed, ordenados por nome (projeção) ==");
h.pacientes.find({ "convenio.nome": "Unimed" }, { _id: 0, nome: 1, "convenio.plano": 1 }).sort({ nome: 1 }).forEach(printjson);

print("\n== 2) Consultas realizadas com valor >= 250, da mais cara para a mais barata ==");
h.consultas.find({ status: "realizada", valor: { $gte: 250 } }, { _id: 0, tipo: 1, valor: 1, diagnostico: 1 }).sort({ valor: -1 }).forEach(printjson);

print("\n== 3) Pacientes particulares (sem campo convenio) ==");
h.pacientes.find({ convenio: { $exists: false } }, { _id: 0, nome: 1 }).forEach(printjson);

print("\n== 4) Pacientes com alguma alergia ==");
h.pacientes.find({ alergias: { $exists: true } }, { _id: 0, nome: 1, alergias: 1 }).forEach(printjson);

print("\n== 5) Junção com $lookup: consultas realizadas com nome do paciente e do médico ==");
h.consultas.aggregate([
  { $match: { status: "realizada" } },
  { $lookup: { from: "pacientes", localField: "paciente_id", foreignField: "_id", as: "paciente" } },
  { $lookup: { from: "medicos",   localField: "medico_id",   foreignField: "_id", as: "medico" } },
  { $project: { _id: 0, data_hora: 1, paciente: { $first: "$paciente.nome" }, medico: { $first: "$medico.nome" }, valor: 1 } },
  { $sort: { data_hora: 1 } }
]).forEach(printjson);

// ---------- ÍNDICES + explain() ----------
const plano = (e) => {
  const w = JSON.stringify(e.queryPlanner.winningPlan);
  return { estagio: w.includes("IXSCAN") ? "IXSCAN (usa índice)" : "COLLSCAN (varre tudo)",
           docsExaminados: e.executionStats.totalDocsExamined, retornados: e.executionStats.nReturned };
};
const consulta = () => h.consultas.find({ paciente_id: p[0] }).sort({ data_hora: -1 });

print("\n== explain ANTES do índice composto ==");
printjson(plano(consulta().explain("executionStats")));

print("\n== Criando índices ==");
print(h.pacientes.createIndex({ cpf: 1 }, { unique: true }));                 // simples (único)
print(h.consultas.createIndex({ paciente_id: 1, data_hora: -1 }));            // composto
print(h.consultas.createIndex({ diagnostico: "text" }));                      // texto

print("\n== explain DEPOIS do índice composto ==");
printjson(plano(consulta().explain("executionStats")));

print("\n== Busca por texto: 'cardíaca' ==");
h.consultas.find({ $text: { $search: "cardíaca" } }, { _id: 0, diagnostico: 1 }).forEach(printjson);

print("\n== Índices da collection consultas ==");
h.consultas.getIndexes().forEach(i => print(i.name));
