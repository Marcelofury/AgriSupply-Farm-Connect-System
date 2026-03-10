// Quick test script for Groq API
require('dotenv').config();
const OpenAI = require('openai');

async function testGroq() {
  console.log('Testing Groq API...\n');
  console.log('API Key:', process.env.GROQ_API_KEY ? '✓ Found' : '✗ Missing');
  
  if (!process.env.GROQ_API_KEY) {
    console.log('\nError: GROQ_API_KEY not found in backend/.env');
    process.exit(1);
  }

  const groq = new OpenAI({
    apiKey: process.env.GROQ_API_KEY,
    baseURL: 'https://api.groq.com/openai/v1',
  });

  try {
    console.log('\nSending test message to Groq...');
    
    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',  // Updated model
      messages: [
        {
          role: 'system',
          content: 'You are a helpful farming assistant for Ugandan farmers.'
        },
        {
          role: 'user',
          content: 'What is the best time to plant maize in Uganda?'
        }
      ],
      temperature: 0.7,
      max_tokens: 200,
    });

    console.log('\n✓ SUCCESS! Groq API is working!\n');
    console.log('Model:', completion.model);
    console.log('Response:', completion.choices[0].message.content);
    console.log('\nTokens used:', completion.usage.total_tokens);
    
  } catch (error) {
    console.log('\n✗ FAILED! Groq API error:\n');
    console.log('Error:', error.message);
    if (error.status) console.log('Status:', error.status);
    if (error.type) console.log('Type:', error.type);
  }
}

testGroq();
