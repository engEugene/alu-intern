import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../widgets/opportunity_create_form.dart';

final class OpportunityCreateScreen extends StatelessWidget {
  const OpportunityCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Opportunity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: OpportunityCreateForm(
            onCreated: () {
              if (context.mounted) context.pop();
            },
          ),
        ),
      ),
    );
  }
}
