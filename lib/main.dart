import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TranslatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String _englishText = '';
  final _formKey = GlobalKey<FormState>();

  Future<String> translateText(String textValue) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener la API key desde el archivo .env
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found. Please add it to your .env file.');
      }

      // Crear una instancia del modelo de Gemini
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      // Preparar el prompt para la traducción
      final prompt =
          'Traduce el siguiente texto del español al inglés. Devuelve '
          'solamente el texto traducido sin incluir explicaciones:'
          '\n\n$textValue';

      // Realizar la consulta a la API
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text?.trim() ?? 'No se pudo obtener una traducción.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleTranslate() async {
    if (_formKey.currentState!.validate()) {
      String result = await translateText(_textController.text);
      setState(() {
        _englishText = result;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traductor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Entrada de texto en español
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Texto en Español',
                  border: OutlineInputBorder(),
                  hintText: 'Escribe o pega el texto a traducir',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa texto para traducir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Botón de traducción
              ElevatedButton(
                onPressed: _isLoading ? null : _handleTranslate,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Traducir'),
              ),
              const SizedBox(height: 24.0),

              // Sección de texto traducido
              const Text(
                'Traducción:',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _englishText.isEmpty
                          ? 'La traducción aparecerá aquí'
                          : _englishText,
                      style: TextStyle(
                        color:
                            _englishText.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
