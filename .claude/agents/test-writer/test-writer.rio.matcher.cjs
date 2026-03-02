/**
 * Universal UserPromptSubmit Matcher Template (v2.0)
 *
 * This template is used by the `setup` command to auto-generate
 * matchers for skills and agents. Claude Haiku fills in the keywords array
 * based on the skill/agent description.
 *
 * IMPORTANT: All return fields are MANDATORY and must not be undefined/null.
 *
 * @param {Object} context - Matcher context
 * @param {string} context.prompt - User's prompt text
 * @param {string} context.cwd - Current working directory
 * @param {string} context.transcriptPath - Path to conversation transcript
 * @param {string} context.permissionMode - "ask" | "allow"
 * @param {string} context.sessionId - Session ID
 * @param {Object} context.meta - Meta information
 * @param {Object} context.transcript - Transcript utilities (for async usage)
 * @returns {Object} Matcher result with all required fields
 */
module.exports = function (context) {
  const prompt = context.prompt.toLowerCase();

  const keywords = [
    'test', 'tests', 'teste', 'testes',
    'write test', 'escrever teste', 'criar teste',
    'unit test', 'teste unitário', 'teste unitario',
    'pytest', 'coverage', 'cobertura',
    'failing test', 'teste falhando', 'teste quebrado',
    'fix test', 'corrigir teste', 'arrumar teste',
    'run test', 'rodar teste', 'executar teste',
    'add test', 'adicionar teste',
    'missing test', 'sem teste', 'falta teste',
  ];

  const matchCount = keywords.filter((keyword) => prompt.includes(keyword)).length;

  // IMPORTANT: All fields are MANDATORY and must not be undefined/null
  return {
    version: '2.0',
    matchCount: matchCount,
    type: 'agent',
  };
};
