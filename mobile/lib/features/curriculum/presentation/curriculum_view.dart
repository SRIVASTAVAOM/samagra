import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/curriculum_bloc.dart';
import '../models/curriculum_model.dart';

class CurriculumView extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String? className;
  final String? subjectName;

  const CurriculumView({
    super.key,
    required this.classId,
    required this.subjectId,
    this.className,
    this.subjectName,
  });

  @override
  State<CurriculumView> createState() => _CurriculumViewState();
}

class _CurriculumViewState extends State<CurriculumView> {
  @override
  void initState() {
    super.initState();
    if (widget.classId.isNotEmpty && widget.subjectId.isNotEmpty) {
      context.read<CurriculumBloc>().add(
            LoadCurriculumUnitsEvent(widget.classId, widget.subjectId),
          );
    }
  }

  @override
  void didUpdateWidget(CurriculumView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.classId != widget.classId || oldWidget.subjectId != widget.subjectId) &&
        widget.classId.isNotEmpty &&
        widget.subjectId.isNotEmpty) {
      context.read<CurriculumBloc>().add(
            LoadCurriculumUnitsEvent(widget.classId, widget.subjectId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName ?? "Subject"} Syllabus & Curriculum'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
            onPressed: () {
              if (widget.classId.isNotEmpty && widget.subjectId.isNotEmpty) {
                context.read<CurriculumBloc>().add(
                      LoadCurriculumUnitsEvent(widget.classId, widget.subjectId),
                    );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: (widget.classId.isEmpty || widget.subjectId.isEmpty)
          ? const Center(
              child: Text(
                'Please select a class and subject to view curriculum.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            )
          : BlocConsumer<CurriculumBloc, CurriculumState>(
        listener: (context, state) {
          if (state is CurriculumError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is CurriculumLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state is CurriculumLoaded) {
            final units = state.units;
            if (units.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, size: 48, color: AppColors.tertiaryText),
                    const SizedBox(height: 12),
                    const Text(
                      'No curriculum units defined yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: units.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildUnitCard(units[index]);
              },
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<CurriculumBloc>().add(
                      LoadCurriculumUnitsEvent(widget.classId, widget.subjectId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Load Curriculum'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitCard(CurriculumUnitModel unit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.indigo50,
              radius: 18,
              child: Text(
                '${unit.unitNumber}',
                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          title: Text(
            unit.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText),
          ),
          subtitle: unit.description != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    unit.description!,
                    style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                  ),
                )
              : null,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.borderLight, height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    'Topics & Learning Objectives',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 8),
                  if (unit.topics.isEmpty)
                    const Text(
                      'No sub-topics added to this unit yet.',
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.tertiaryText),
                    )
                  else
                    ...unit.topics.map((t) => _buildTopicTile(t)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildTopicTile(CurriculumTopicModel topic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${topic.topicNumber}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                ),
                if (topic.learningObjectives != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Objective: ${topic.learningObjectives!}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
