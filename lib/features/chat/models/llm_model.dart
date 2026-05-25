/// Represents a selectable LLM model.
class LlmModel {
  const LlmModel({required this.id, required this.label, required this.provider});

  final String id;
  final String label;
  final String provider;

  static const List<LlmModel> all = [
    LlmModel(
      id: 'gemini/gemini-2.5-flash',
      label: 'Gemini 2.5 Flash',
      provider: 'Google',
    ),
    LlmModel(
      id: 'gemini/gemini-2.5-pro',
      label: 'Gemini 2.5 Pro',
      provider: 'Google',
    ),
    LlmModel(
      id: 'openai/gpt-4o',
      label: 'GPT-4o',
      provider: 'OpenAI',
    ),
    LlmModel(
      id: 'openai/gpt-4.1',
      label: 'GPT-4.1',
      provider: 'OpenAI',
    ),
    LlmModel(
      id: 'anthropic/claude-3-5-sonnet-20241022',
      label: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
    ),
  ];

  /// Default model used when the app first opens.
  static const LlmModel defaultModel = LlmModel(
    id: 'gemini/gemini-2.5-flash',
    label: 'Gemini 2.5 Flash',
    provider: 'Google',
  );
}
