
import 'dart:math' ;
String generateCustomId() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  final random = Random();


  String letterPart = List.generate( 3, (_) => letters[random.nextInt(letters.length)], ).join();


  String numberPart = List.generate( 3, (_) => numbers[random.nextInt(numbers.length)], ).join();


  return '#$letterPart$numberPart';
}



