import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/homework_model.dart';
import '../repository/homework_repository.dart';

// --- Events ---
abstract class HomeworkEvent {
  const HomeworkEvent();
}

class LoadStudentHomeworkEvent extends HomeworkEvent {
  const LoadStudentHomeworkEvent();
}

class LoadTeacherHomeworkEvent extends HomeworkEvent {
  const LoadTeacherHomeworkEvent();
}

class LoadClassHomeworkEvent extends HomeworkEvent {
  final String classId;
  final String sectionId;
  const LoadClassHomeworkEvent(this.classId, this.sectionId);
}

class CreateHomeworkEvent extends HomeworkEvent {
  final String classId;
  final String sectionId;
  final String subjectId;
  final String title;
  final String description;
  final String? assignedDate;
  final String dueDate;
  final String? s3AttachmentKey;
  final String? attachmentName;

  const CreateHomeworkEvent({
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.title,
    required this.description,
    this.assignedDate,
    required this.dueDate,
    this.s3AttachmentKey,
    this.attachmentName,
  });
}

class UpdateHomeworkEvent extends HomeworkEvent {
  final String id;
  final String? title;
  final String? description;
  final String? dueDate;
  final String? s3AttachmentKey;
  final String? attachmentName;

  const UpdateHomeworkEvent({
    required this.id,
    this.title,
    this.description,
    this.dueDate,
    this.s3AttachmentKey,
    this.attachmentName,
  });
}

class ToggleHomeworkCompletionEvent extends HomeworkEvent {
  final String homeworkId;
  final String currentStatus;
  const ToggleHomeworkCompletionEvent(this.homeworkId, this.currentStatus);
}

class SubmitHomeworkEvent extends HomeworkEvent {
  final String homeworkId;
  final String? submissionText;
  final String? submissionAttachmentKey;
  final String? submissionAttachmentName;

  const SubmitHomeworkEvent({
    required this.homeworkId,
    this.submissionText,
    this.submissionAttachmentKey,
    this.submissionAttachmentName,
  });
}

class DownloadHomeworkAttachmentEvent extends HomeworkEvent {
  final String homeworkId;
  final bool isSubmission;
  const DownloadHomeworkAttachmentEvent(
    this.homeworkId, {
    this.isSubmission = false,
  });
}

// --- States ---
abstract class HomeworkState {
  const HomeworkState();
}

class HomeworkInitial extends HomeworkState {
  const HomeworkInitial();
}

class HomeworkLoading extends HomeworkState {
  const HomeworkLoading();
}

class StudentHomeworkLoaded extends HomeworkState {
  final List<HomeworkModel> homeworkList;
  const StudentHomeworkLoaded(this.homeworkList);
}

class TeacherHomeworkLoaded extends HomeworkState {
  final List<HomeworkModel> homeworkList;
  const TeacherHomeworkLoaded(this.homeworkList);
}

class HomeworkOperationSuccess extends HomeworkState {
  final String message;
  final String? downloadUrl;
  final String? attachmentName;
  const HomeworkOperationSuccess(this.message, {this.downloadUrl, this.attachmentName});
}

class HomeworkError extends HomeworkState {
  final String message;
  const HomeworkError(this.message);
}

// --- BLoC ---
class HomeworkBloc extends Bloc<HomeworkEvent, HomeworkState> {
  final HomeworkRepository _repository;
  List<HomeworkModel> _cachedStudentHomework = [];

  List<HomeworkModel> get cachedStudentHomework =>
      List.unmodifiable(_cachedStudentHomework);

  HomeworkBloc(this._repository) : super(const HomeworkInitial()) {
    on<LoadStudentHomeworkEvent>(_onLoadStudentHomework);
    on<LoadTeacherHomeworkEvent>(_onLoadTeacherHomework);
    on<LoadClassHomeworkEvent>(_onLoadClassHomework);
    on<CreateHomeworkEvent>(_onCreateHomework);
    on<UpdateHomeworkEvent>(_onUpdateHomework);
    on<ToggleHomeworkCompletionEvent>(_onToggleCompletion);
    on<SubmitHomeworkEvent>(_onSubmitHomework);
    on<DownloadHomeworkAttachmentEvent>(_onDownloadAttachment);
  }

  Future<void> _onLoadStudentHomework(
    LoadStudentHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      final list = await _repository.getStudentMyClassHomework();
      _cachedStudentHomework = list;
      emit(StudentHomeworkLoaded(list));
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> _onLoadTeacherHomework(
    LoadTeacherHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      final list = await _repository.getTeacherMyAssignedHomework();
      emit(TeacherHomeworkLoaded(list));
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> _onLoadClassHomework(
    LoadClassHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      final list = await _repository.getClassHomework(event.classId, event.sectionId);
      emit(TeacherHomeworkLoaded(list));
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> _onCreateHomework(
    CreateHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      await _repository.createHomework(
        classId: event.classId,
        sectionId: event.sectionId,
        subjectId: event.subjectId,
        title: event.title,
        description: event.description,
        assignedDate: event.assignedDate,
        dueDate: event.dueDate,
        s3AttachmentKey: event.s3AttachmentKey,
        attachmentName: event.attachmentName,
      );
      final list = await _repository.getTeacherMyAssignedHomework();
      emit(TeacherHomeworkLoaded(list));
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> _onUpdateHomework(
    UpdateHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      await _repository.updateHomework(
        id: event.id,
        title: event.title,
        description: event.description,
        dueDate: event.dueDate,
        s3AttachmentKey: event.s3AttachmentKey,
        attachmentName: event.attachmentName,
      );
      final list = await _repository.getTeacherMyAssignedHomework();
      emit(TeacherHomeworkLoaded(list));
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> _onToggleCompletion(
    ToggleHomeworkCompletionEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    final newStatus = event.currentStatus == 'COMPLETED' ? 'PENDING' : 'COMPLETED';
    try {
      await _repository.setCompletionStatus(event.homeworkId, newStatus);
      final updatedLocal = _cachedStudentHomework.map((hw) {
        if (hw.id != event.homeworkId) return hw;
        return hw.copyWith(
          studentStatus: newStatus,
          completedAt: newStatus == 'COMPLETED'
              ? DateTime.now().toIso8601String()
              : hw.completedAt,
        );
      }).toList();

      List<HomeworkModel> latestList;
      try {
        final serverList = await _repository.getStudentMyClassHomework();
        latestList = serverList.map((serverItem) {
          if (serverItem.id == event.homeworkId &&
              serverItem.studentStatus != newStatus) {
            return serverItem.copyWith(studentStatus: newStatus);
          }
          return serverItem;
        }).toList();
      } catch (_) {
        latestList = updatedLocal;
      }

      _cachedStudentHomework = latestList;
      emit(StudentHomeworkLoaded(latestList));
    } catch (e) {
      emit(HomeworkError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubmitHomework(
    SubmitHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    try {
      final res = await _repository.submitHomework(
        homeworkId: event.homeworkId,
        submissionText: event.submissionText,
        submissionAttachmentKey: event.submissionAttachmentKey,
        submissionAttachmentName: event.submissionAttachmentName,
      );

      final updatedLocal = _cachedStudentHomework.map((hw) {
        if (hw.id != event.homeworkId) return hw;
        return hw.copyWith(
          studentStatus: 'COMPLETED',
          completedAt: (res['completed_at'] as String?) ??
              DateTime.now().toIso8601String(),
          submissionText:
              (res['submission_text'] as String?) ?? event.submissionText,
          submissionAttachmentKey:
              (res['submission_attachment_key'] as String?) ??
                  event.submissionAttachmentKey,
          submissionAttachmentName:
              (res['submission_attachment_name'] as String?) ??
                  event.submissionAttachmentName,
          submittedAt: (res['submitted_at'] as String?) ??
              DateTime.now().toIso8601String(),
        );
      }).toList();

      List<HomeworkModel> latestList;
      try {
        latestList = await _repository.getStudentMyClassHomework();
      } catch (_) {
        latestList = updatedLocal;
      }

      _cachedStudentHomework = latestList;
      emit(const HomeworkOperationSuccess('Homework submitted successfully!'));
      emit(StudentHomeworkLoaded(latestList));
    } catch (e) {
      emit(HomeworkError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDownloadAttachment(
    DownloadHomeworkAttachmentEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    try {
      final res = await _repository.getAttachmentDownloadUrl(
        event.homeworkId,
        isSubmission: event.isSubmission,
      );
      emit(HomeworkOperationSuccess(
        'Download link generated',
        downloadUrl: res.downloadUrl,
        attachmentName: res.fileName,
      ));
    } catch (e) {
      emit(HomeworkError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
