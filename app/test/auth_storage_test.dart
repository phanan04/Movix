import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movix/core/cache/user_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorage().init();
  });

  test('loginAsGuest sets active guest user', () async {
    final user = await UserStorage().loginAsGuest();
    expect(user.authProvider, 'guest');
    expect(user.name, 'Khách VIP');
    expect(UserStorage().currentUserNotifier.value?.name, 'Khách VIP');
  });

  test('registerAccount creates and stores account', () async {
    final user = await UserStorage().registerAccount(
      name: 'Nguyen Van A',
      email: 'vana@gmail.com',
      password: 'password123',
    );

    expect(user.email, 'vana@gmail.com');
    expect(user.name, 'Nguyen Van A');
    expect(UserStorage().currentUserNotifier.value?.email, 'vana@gmail.com');
  });

  test('registerAccount with same email and same password auto logs in', () async {
    await UserStorage().registerAccount(
      name: 'Nguyen Van A',
      email: 'vana@gmail.com',
      password: 'password123',
    );

    // Registering again with exact credentials shouldn't throw error
    final user = await UserStorage().registerAccount(
      name: 'Nguyen Van A',
      email: 'vana@gmail.com',
      password: 'password123',
    );
    expect(user.email, 'vana@gmail.com');
  });

  test('loginAccount succeeds with correct credentials and fails with wrong password', () async {
    await UserStorage().registerAccount(
      name: 'Nguyen Van B',
      email: 'vanb@gmail.com',
      password: 'secretPassword',
    );

    await UserStorage().signOut();
    expect(UserStorage().currentUserNotifier.value, isNull);

    // Wrong password throws
    expect(
      () => UserStorage().loginAccount(email: 'vanb@gmail.com', password: 'wrongPassword'),
      throwsA(isA<String>()),
    );

    // Correct password succeeds
    final user = await UserStorage().loginAccount(email: 'vanb@gmail.com', password: 'secretPassword');
    expect(user.email, 'vanb@gmail.com');
    expect(UserStorage().currentUserNotifier.value?.email, 'vanb@gmail.com');
  });
}
