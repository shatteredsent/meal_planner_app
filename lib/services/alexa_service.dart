import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/shopping_list_provider.dart';

class AlexaService with ChangeNotifier {
  final ShoppingListProvider shoppingListProvider;
  final stt.SpeechToText speechToText = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  AlexaService({required this.shoppingListProvider});

  Future<void> initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
  }

  Future<void> initStt() async {
    await speechToText.initialize(
      onStatus: (val) => print('STT status: $val'),
      onError: (val) => print('STT error: $val'),
    );
  }

  void startListening() {
    if (speechToText.isAvailable) {
      speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            processCommand(result.recognizedWords);
            stopListening();
          }
        },
      );
    }
  }

  void stopListening() {
    if (speechToText.isListening) {
      speechToText.stop();
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> processCommand(String command) async {
    final lowerCaseCommand = command.toLowerCase();

    if (lowerCaseCommand.contains('add') && lowerCaseCommand.contains('to shopping list')) {
      final item = lowerCaseCommand.replaceAll('add', '').replaceAll('to shopping list', '').trim();
      if (item.isNotEmpty) {
  await shoppingListProvider.addShoppingItem(item, 'Other');
  await speak('Added $item to your shopping list.');
      }
    } else if (lowerCaseCommand.contains('read') && lowerCaseCommand.contains('shopping list')) {
      await speak('Your shopping list contains:');
      for (var item in shoppingListProvider.items) {
        await speak(item.name);
      }
    } else if (lowerCaseCommand.contains('check off')) {
      final item = lowerCaseCommand.replaceAll('check off', '').trim();
      await shoppingListProvider.toggleCompletionByName(item);
      await speak('Checked off $item.');
    } else if (lowerCaseCommand.contains('clear completed items')) {
      await shoppingListProvider.clearCompletedItems();
      await speak('Cleared completed items from your shopping list.');
    } else {
      await speak('Sorry, I didn\'t understand that command.');
    }
  }
}