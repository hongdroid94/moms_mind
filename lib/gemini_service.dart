import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() => _instance;

  GeminiService._internal();

  final String apiKey = 'AIzaSyDw_3KkcTHieQH8rAyZjFUEGYsa6HJPPUM';
  final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> generateMessage(String weatherInfo) async {
    try {
      print("Gemini API 호출 시작");
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "날씨 정보: $weatherInfo\n\n이 날씨 정보를 바탕으로, 엄마가 자식에게 하는 말투로 걱정 스러운 말투로 외출하려는 자녀에게 조언을 해주세요. 대기 상태에 따른 피드백을 종합적으로 짧고 굵게 피드백 해줘야하고, 예를들어 비가오는 날이면 우산을 챙기라는 느낌의 걱정어린 말투를 해야 합니다. 특수문자는 절대 넣지마시고, 자녀를 부를 때에는 '홍철' 이라고 해주세요"
            }
            ]
          }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['candidates'][0]['content']['parts'][0]['text'];
        print("Gemini API 응답 성공");
        return message;
      } else {
        print("Gemini API 응답 오류: ${response.statusCode}");
        throw Exception('Failed to generate message');
      }
    } catch (e) {
      print("Gemini API 호출 실패: $e");
      return "메시지 생성에 실패했습니다. 엄마의 사랑은 변함없어요.";
    }
  }
}