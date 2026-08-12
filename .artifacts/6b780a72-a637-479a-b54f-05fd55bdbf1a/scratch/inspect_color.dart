import 'dart:ui';

void main() {
  const color = Color(0xFF000000);
  // Try to access 'a' or 'alpha'
  try {
    print('Color alpha: ${color.alpha}');
  } catch (e) {
    print('alpha not available');
  }
  
  // Reflection or just checking if it compiles would be better.
  // But I can just try to print them.
}
