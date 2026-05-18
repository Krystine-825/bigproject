
const OpenAI = require('openai');
const logger = require('firebase-functions/logger');

let openaiInstance = null;
function getOpenAIClient() {
  if (!openaiInstance) {
    openaiInstance = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  }
  return openaiInstance;
}

function _getCEFRDescription(level) {
  const cefrGuides = {
    'A1': 'A1 (Beginner): Everyday vocabulary, simple present/continuous, basic prepositions, pronouns.',
    'A2': 'A2 (Elementary): Past simple, future (will/going to), comparatives, basic modals (can, must), daily life vocabulary.',
    'B1': 'B1 (Intermediate): Present perfect, past continuous, conditionals (0, 1st, 2nd), relative clauses, gerunds/infinitives.',
    'B2': 'B2 (Upper-Intermediate): Past perfect, complex conditionals, reported speech, passive voice, phrasal verbs, idioms.',
    'C1': 'C1 (Advanced): Inversions, cleft sentences, subjunctive, nuanced vocabulary, collocations.',
    'C2': 'C2 (Proficient): Near-native nuance, obscure vocabulary, cultural idioms, complex layered sentences.'
  };
  return cefrGuides[level] || cefrGuides['B1'];
}

function _buildTypeInstructions(types) {
  const instructions = [];
  if (types.includes('multiple_choice')) {
    instructions.push(`MULTIPLE CHOICE rules:\n- Provide 4 options prefixed exactly with "A. ", "B. ", "C. ", "D. ".\n- Provide a COMPLETE, standalone sentence with a blank "___" to test grammar/vocabulary.\n- Example: "I ________ to the market when it started raining." (A. went, B. was going, C. go, D. am going)`);
  }
  if (types.includes('fill_in')) {
    instructions.push(`FILL IN THE BLANK rules:\n- Provide a COMPLETE, standalone sentence with a blank "___".\n- Example: "She is very good ___ playing the piano." (Answer: at)`);
  }
  if (types.includes('true_false')) {
    instructions.push(`TRUE/FALSE rules:\n- Test UNIVERSAL grammar rules, spelling, or vocabulary. DO NOT test facts.\n- Example: "The plural form of 'child' is 'childrens'." (Answer: False)\n- Example: "The word 'rapidly' is an adverb." (Answer: True)`);
  }
  if (types.includes('reading_comprehension')) {
    instructions.push(`READING COMPREHENSION rules:\n- You MUST provide a "passage" field containing a reading text appropriate for the CEFR level (extracted or summarized from the source text).\n- The "question" field should ask about main ideas, details, inference, or vocabulary in context.\n- Provide 4 options prefixed exactly with "A. ", "B. ", "C. ", "D. ".\n- The "answer" field must be exactly A, B, C, or D.`);
  }
  return instructions.join('\n\n');
}

function _buildSystemPrompt(typeInstructions, targetCEFR, types) {
  const cefrGuide = _getCEFRDescription(targetCEFR);
  const isRC = types.includes('reading_comprehension');

  let criticalRules = `CRITICAL RULES (FAILING THESE WILL RUIN THE APP):\n1. THE INPUT IS MAYBE AN OLD EXAMS: The text I provide is probably an old, messy exam, reading passage, or OCR text. It contains questions, reading passages, and question numbers.\n2. DO NOT COPY EXISTING QUESTIONS: You MUST NEVER copy existing questions from the text. Make new ones.`;

  if (isRC) {
    criticalRules += `\n3. READING COMPREHENSION IS ALLOWED: You MUST extract or create a reading passage from the input text and place it in the "passage" field.`;
  } else {
    criticalRules += `\n3. PURE GRAMMAR & VOCABULARY: Only test grammar rules, verb tenses, prepositions, or vocabulary meanings.\n4. BAN LIST: You are STRICTLY FORBIDDEN from using the following words in your questions or explanations: "passage", "text", "author", "paragraph", "Question", "line".`;
  }

  return `You are an expert English exam creator. Your task is to create a BRAND NEW, STANDALONE English quiz strictly at the **${targetCEFR}** CEFR level.\n\nCEFR LEVEL GUIDELINE:\n${cefrGuide}\n\n${criticalRules}\n\nOUTPUT FORMAT (Valid JSON Only):\n{\n  "questions": [\n    {\n      "type": "multiple_choice" | "fill_in" | "true_false" | "reading_comprehension",\n      ${isRC ? '"passage": "string (The reading passage content - ONLY include this if type is reading_comprehension)",' : ''}\n      "question": "string (The newly invented standalone sentence or reading question)",\n      "options": ["A. ...", "B. ...", "C. ...", "D. ..."], // For multiple_choice or reading_comprehension ONLY.\n      "answer": "string (The exact correct answer, e.g. 'A' or 'True' or word)", \n      "explanation": "string (Explain the rule or reason clearly)"\n    }\n  ]\n}\n\n${typeInstructions}`;
}

function _buildUserPrompt(text, questionCount, types, targetCEFR) {
  const isRC = types.includes('reading_comprehension');
  const typesLabel = types.join(', ');

  let mandatoryInstructions = `- Look at the text below to find vocabulary words, grammar topics, or reading passages.\n- IGNORE all question numbers from the old text.\n- INVENT ${questionCount} new questions.`;

  if (!isRC) {
    mandatoryInstructions = `- Look at the text below ONLY to find vocabulary words or grammar topics.\n- IGNORE all formatting, question numbers, reading passages, and stories in the text.\n- INVENT ${questionCount} completely new, unrelated standalone sentences to test the students.`;
  }

  return `Generate EXACTLY ${questionCount} questions at the ${targetCEFR} level.\n\nQuestion Types allowed: ${typesLabel}.\n\nMANDATORY INSTRUCTIONS:\n${mandatoryInstructions}\n\nSOURCE TEXT:\n"""\n${text}\n"""\n\nGenerate the JSON output now.`;
}

async function generateQuestionsFromAI(text, config) {
  const openai = getOpenAIClient();
  const { questionCount = 10, questionTypes = ['multiple_choice', 'fill_in', 'true_false'], targetCEFR = 'B1' } = config;

  const maxChars = 40000; 
  let inputText = text;

  if (text.length > maxChars) {
    const snippet = text.slice(0, maxChars);
    const safeCutIndex = Math.max(
      snippet.lastIndexOf('. '), snippet.lastIndexOf('? '),
      snippet.lastIndexOf('! '), snippet.lastIndexOf('\n')
    );
    const finalCut = safeCutIndex > (maxChars - 500) ? safeCutIndex + 1 : maxChars;
    inputText = text.slice(0, finalCut) + '\n\n[... phần còn lại của tài liệu đã được rút gọn để tối ưu AI ...]';
    logger.info(`[TỐI ƯU TEXT] File quá dài (${text.length} ký tự). Đã cắt an toàn tại ký tự thứ ${finalCut}.`);
  }

  const typeInstructions = _buildTypeInstructions(questionTypes);
  const systemPrompt = _buildSystemPrompt(typeInstructions, targetCEFR, questionTypes);
  const userPrompt   = _buildUserPrompt(inputText, questionCount, questionTypes, targetCEFR);

  logger.info(`[DEBUG INPUT] Tổng số ký tự nhận được từ Flutter: ${text.length}`);
  logger.info(`[DEBUG INPUT] Mốc CEFR được chọn: ${targetCEFR}`);
  
  const MAX_RETRIES = 3;
  
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      logger.info(`[OPENAI] Bắt đầu gọi API sinh đề (Lần thử: ${attempt}/${MAX_RETRIES})...`);
      
      const response = await openai.chat.completions.create({
        model: 'gpt-4o',
        temperature: 0.7,
        messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userPrompt }],
        response_format: { type: 'json_object' },
      });

      const raw = response.choices[0].message.content;
      const charCount = raw.length;
      logger.info(`[THỐNG KÊ AI] Số ký tự AI sinh ra: ${charCount} ký tự.`);

      if (response.usage) {
        const promptTokens = response.usage.prompt_tokens;      
        const completionTokens = response.usage.completion_tokens;
        const totalTokens = response.usage.total_tokens;        
        logger.info(`[THỐNG KÊ TOKEN] Đầu vào: ${promptTokens} | Đầu ra: ${completionTokens} | Tổng cộng: ${totalTokens}`);
      }

      const parsed = JSON.parse(raw);
      if (!parsed.questions || !Array.isArray(parsed.questions)) {
        throw new Error('OpenAI trả về dữ liệu không đúng định dạng (Thiếu mảng questions).');
      }

      return parsed.questions.map((q, i) => ({ ...q, id: i + 1 }));

    } catch (error) {
      logger.warn(`[OPENAI ERROR] Lỗi ở lần thử thứ ${attempt}: ${error.message}`);
      if (attempt === MAX_RETRIES) {
        throw new Error(`Quá trình sinh đề thất bại sau ${MAX_RETRIES} lần thử: ${error.message}`);
      }
      const delayMs = attempt * 2000; 
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
}

module.exports = { generateQuestionsFromAI };