import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/staff_profile_model.dart';
import '../models/student_profile_model.dart';
import '../repository/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;
  StudentProfileModel? _lastStudentProfile;
  StaffProfileModel? _lastStaffProfile;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadStudentProfileEvent>(_onLoadStudentProfile);
    on<UpdateStudentProfileEvent>(_onUpdateStudentProfile);
    on<UploadStudentPhotoEvent>(_onUploadStudentPhoto);
    on<LoadStaffProfileEvent>(_onLoadStaffProfile);
    on<UpdateStaffProfileEvent>(_onUpdateStaffProfile);
  }

  Future<void> _onLoadStudentProfile(
    LoadStudentProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await repository.getStudentProfile();
      _lastStudentProfile = profile;
      emit(StudentProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateStudentProfile(
    UpdateStudentProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());
    try {
      final updated = await repository.updateStudentProfile(
        emergencyPhone: event.emergencyPhone,
        bloodGroup: event.bloodGroup,
        medicalNotes: event.medicalNotes,
        documentUrl: event.documentUrl,
      );
      _lastStudentProfile = updated;
      emit(ProfileUpdateSuccess('Profile updated successfully', updated));
      emit(StudentProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
      if (_lastStudentProfile != null) {
        emit(StudentProfileLoaded(_lastStudentProfile!));
      }
    }
  }

  Future<void> _onUploadStudentPhoto(
    UploadStudentPhotoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());
    try {
      final updated =
          await repository.uploadStudentPhoto(event.bytes, event.fileName);
      _lastStudentProfile = updated;
      emit(ProfileUpdateSuccess('Profile photo uploaded successfully', updated));
      emit(StudentProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
      if (_lastStudentProfile != null) {
        emit(StudentProfileLoaded(_lastStudentProfile!));
      }
    }
  }

  Future<void> _onLoadStaffProfile(
    LoadStaffProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await repository.getStaffProfile();
      _lastStaffProfile = profile;
      emit(StaffProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateStaffProfile(
    UpdateStaffProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());
    try {
      final updated = await repository.updateStaffProfile(
        phone: event.phone,
        emergencyPhone: event.emergencyPhone,
        qualification: event.qualification,
        bloodGroup: event.bloodGroup,
      );
      _lastStaffProfile = updated;
      emit(ProfileUpdateSuccess('Profile updated successfully', updated));
      emit(StaffProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
      if (_lastStaffProfile != null) {
        emit(StaffProfileLoaded(_lastStaffProfile!));
      }
    }
  }
}
