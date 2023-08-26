import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future sendMail2(
    {required String reciever_address,
    required String mail_subject,
    required String mail_content}) async {
  await dotenv.load();
  String username = dotenv.env['MAILUSERNAME']!;
  String password = dotenv.env['MAILPASSWORD']!;

  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Team Confessions')
    ..recipients.add(reciever_address)
    ..subject = mail_subject
    ..text = mail_content;

  try {
    final sendReport = await send(message, smtpServer);
    return 'Email sent successfully.';
  } on MailerException catch (e) {
    return e.toString();
  }
}
