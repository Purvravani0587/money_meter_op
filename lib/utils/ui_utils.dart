import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UIUtils {
  static void showTopMessage(BuildContext? context, String message, {bool isError = false}) {
    final ctx = context ?? Get.context ?? Get.overlayContext;
    if (ctx == null) {
      Get.snackbar(
        isError ? 'Attention' : 'Success',
        message,
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        colorText: Colors.white,
      );
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) {
      Get.snackbar(
        isError ? 'Attention' : 'Success',
        message,
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        colorText: Colors.white,
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isError ? 'Attention' : 'Success',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),
    );
  }
}

