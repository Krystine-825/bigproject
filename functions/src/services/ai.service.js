
const OpenAI = require('openai');
const logger = require('firebase-functions/logger');
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

function _getCEFRDescription(level) {
  const cefrGuides = {
    'A1': 'A1 (Beginner): Everyday vocabulary, simple present/continuous, basic prepositions, pronouns.',
    'A2': 'A2 (Elementary): Past simple, future (will/going to), comparatives, basic modals.',
    'B1': 'B1 (Intermediate): Present perfect, past continuous, conditionals, relative clauses.',
    'B2': 'B2 (Upper-Intermediate): Past perfect, complex conditionals, passive voice, phrasal verbs.',
    'C1': 'C1 (Advanced): Inversions, cleft sentences, subjunctive, nuanced vocabulary.',
    'C2': 'C2 (Proficient): Near-native nuance, obscure vocabulary, cultural idioms.'
  };
  return cefrGuides[level] || cefrGuides['B1'];
}

function _buildTypeInstructions(types) {
  const instructions = [];
  if (types.includes('multiple_choice')) instructions.push(`MULTIPLE CHOICE rules:\n- Provide 4 options prefixed exactly with "A. ", "B. ", "C. ", "D. ".\n- Provide a COMPLETE sentence with a blank "___".`);
  if (types.includes('fill_in')) instructions.push(`FILL IN THE BLANK rules:\n- Provide a COMPLETE sentence with a blank "___".`);
  if (types.includes('true_false')) instructions.push(`TRUE/FALSE rules:\n- Test UNIVERSAL grammar rules or vocabulary. DO NOT test facts.`);
  if (types.includes('reading_comprehension')) instructions.push(`READING COMPREHENSION rules:\n- MUST provide a "passage" field.\n- "options" must have 4 choices.`);
  return instructions.join('\n\n');
}

function _buildSystemPrompt(typeInstructions, targetCEFR, types) {
  const isRC = types.includes('reading_comprehension');
  let criticalRules = `CRITICAL RULES:\n1. THE INPUT IS MAYBE AN OLD EXAM. DO NOT COPY EXISTING QUESTIONS.\n2. INVENT BRAND NEW QUESTIONS.`;
  if (isRC) {
    criticalRules += `\n3. You MUST extract or create a reading passage and place it in the "passage" field.`;
  } else {
    criticalRules += `\n3. BAN LIST: NEVER use words like "passage", "text", "paragraph", "Question".`;
  }

  return `You are an expert English exam creator. Create a BRAND NEW quiz at the **${targetCEFR}** CEFR level.\n\nCEFR GUIDELINE:\n${_getCEFRDescription(targetCEFR)}\n\n${criticalRules}\n\nOUTPUT FORMAT (JSON Only):\n{\n  "questions": [\n    {\n      "type": "...",\n      ${isRC ? '"passage": "...",' : ''}\n      "question": "...",\n      "options": ["A. ...", "B. ..."],\n      "answer": "...",\n      "explanation": "..."\n    }\n  ]\n}\n\n${typeInstructions}`;
}

async function generateQuestionsFromAI(text, config) {
  const { questionCount = 10, questionTypes = ['multiple_choice'], targetCEFR = 'B1' } = config;
  
  let inputText = text;
  if (text.length > 40000) {
    inputText = text.slice(0, 40000) + '\n\n[... truncated ...]';
  }

  const systemPrompt = _buildSystemPrompt(_buildTypeInstructions(questionTypes), targetCEFR, questionTypes);
  const userPrompt = `Generate EXACTLY ${questionCount} questions.\n\nSOURCE TEXT:\n"""\n${inputText}\n"""`;

  logger.info(`[OPENAI] Calling API for ${questionCount} questions (CEFR: ${targetCEFR})`);
  
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const response = await openai.chat.completions.create({
        model: 'gpt-4o',
        temperature: 0.7,
        messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userPrompt }],
        response_format: { type: 'json_object' },
      });
      const parsed = JSON.parse(response.choices[0].message.content);
      if (!parsed.questions) throw new Error('Missing questions array.');
      return parsed.questions.map((q, i) => ({ ...q, id: i + 1 }));
    } catch (error) {
      logger.warn(`[OPENAI ERROR] Attempt ${attempt}: ${error.message}`);
      if (attempt === 3) throw new Error(`AI failed after 3 attempts: ${error.message}`);
      await new Promise(r => setTimeout(r, attempt * 2000));
    }
  }
}

module.exports = { generateQuestionsFromAI };