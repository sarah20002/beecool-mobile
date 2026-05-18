import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:another_flushbar/flushbar.dart';

class NotificationHelper {
  // Affiche un snackbar de succès avec awesome_snackbar_content
  static void showSuccess(BuildContext context, {required String title, required String message}) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  // Affiche un snackbar d'avertissement/info avec awesome_snackbar_content
  static void showWarning(BuildContext context, {required String title, required String message}) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.warning,
      ),
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  // Affiche un Flushbar d'erreur avec une action "Réessayer"
  static void showError(BuildContext context, {
    required String title, 
    required String message, 
    required VoidCallback onRetry
  }) {
    Flushbar(
      titleText: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      icon: const Icon(
        Icons.error_outline_rounded,
        size: 28.0,
        color: Colors.redAccent,
      ),
      mainButton: TextButton(
        onPressed: () {
          // Fermer le flushbar d'abord
          Navigator.of(context, rootNavigator: true).pop();
          onRetry();
        },
        child: const Text(
          'RÉESSAYER',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      duration: const Duration(seconds: 6),
      margin: const EdgeInsets.all(15),
      borderRadius: BorderRadius.circular(15),
      backgroundColor: Colors.black87,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0.0, 3.0),
          blurRadius: 3.0,
        )
      ],
    )..show(context);
  }
}
