import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/document_picker_bottom_sheet.dart';
import '../models/homework_model.dart';
import '../repository/homework_repository.dart';

Future<void> viewHomeworkAttachment(BuildContext context, HomeworkModel homework) async {
  var url = homework.s3AttachmentKey;
  if (url != null && !url.startsWith('https://')) {
    try {
      final response = await context.read<HomeworkRepository>().getAttachmentDownloadUrl(homework.id);
      url = response.downloadUrl;
    } catch (_) {
      url = null;
    }
  }
  if (context.mounted) await viewAttachment(context, url);
}
