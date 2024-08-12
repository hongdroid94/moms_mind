import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final String apiKey = '62eb52d8c5d99a9bc5597964973b7233';
  final String apiUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<String> getCurrentWeather() async {
    try {
      print("위치 정보 가져오기 시작");
      Position position = await _determinePosition();
      print("위치: ${position.latitude}, ${position.longitude}");

      print("날씨 API 호출 시작");
      final response = await http.get(
          Uri.parse('$apiUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['main']['temp'];
        final description = data['weather'][0]['description'];
        print("날씨 정보 가져오기 성공");
        return '현재 기온은 $temp°C이고, 날씨는 $description입니다.';
      } else {
        print("날씨 API 응답 오류: ${response.statusCode}");
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('날씨 정보 가져오기 실패: $e');
      return '날씨 정보를 가져오는 데 실패했습니다.';
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}