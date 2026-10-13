import 'package:flutter_test/flutter_test.dart';
import 'package:triunfa_beca/utils/validadores.dart';

void main() {
  test('Validación de DNI', () {
    expect(Validadores.dni('76543210'), isNull);
    expect(Validadores.dni('123'), isNotNull);
    expect(Validadores.dni('abcdefgh'), isNotNull);
  });

  test('Validación de correo', () {
    expect(Validadores.correo('ana@email.com'), isNull);
    expect(Validadores.correo('ana@'), isNotNull);
  });

  test('Validación de contraseña', () {
    expect(Validadores.password('123456'), isNull);
    expect(Validadores.password('123'), isNotNull);
  });
}
