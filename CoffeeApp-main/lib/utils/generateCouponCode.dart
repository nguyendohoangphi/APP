
import 'dart:math';
String generateCouponCode() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  final rand = Random();


  List<String> letterPart = List.generate(5, (_) => letters[rand.nextInt(letters.length)], );


  List<String> numberPart = List.generate(5, (_) => numbers[rand.nextInt(numbers.length)], );


  List<String> all = [...letterPart, ...numberPart]..shuffle(rand);

  return all.join();
}


