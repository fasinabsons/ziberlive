import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Import Uuid for generating IDs
import '../providers/app_state_provider.dart';
import '../models/schedule_models.dart'; // For ScheduleType
// Assuming CustomScheduleTemplate, CustomLaundryTemplate, RotationRule are defined in app_state_provider.dart for now

class ScheduleCustomizationScreen extends StatefulWidget {
  const ScheduleCustomizationScreen({super.key});

  @override
  State<ScheduleCustomizationScreen> createState() => _ScheduleCustomizationScreenState();
}

class _ScheduleCustomizationScreenState extends State<ScheduleCustomizationScreen> {
  // Example: Dialog to add/edit a task template
  void _showTaskTemplateDialog({CustomScheduleTemplate? template}) {
    // TODO: Implement dialog for task template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task template dialog placeholder: ${template?.name ?? 'New'}')),
    );
  }

  // Example: Dialog to add/edit a meal template
  void _showMealTemplateDialog({CustomScheduleTemplate? template}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = template?.name ?? '';
    String description = template?.description ?? ''; // For menu details

    showDialog(
      context: context,
      builder: (dialogContext) { // Renamed context
        return AlertDialog(
          title: Text(template == null ? 'New Meal Template' : 'Edit Meal Template'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Template Name', border: OutlineInputBorder()),
                  validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a name' : null,
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Default Menu/Description', border: OutlineInputBorder()),
                  onChanged: (value) => description = value,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (template == null) { // New
                    final newTemplate = CustomScheduleTemplate(
                      id: const Uuid().v4(),
                      name: name,
                      type: ScheduleType.communityMeal, // Crucial
                      description: description,
                    );
                    await appState.saveCustomMealTemplate(newTemplate);
                  } else { // Editing
                    final updatedTemplate = CustomScheduleTemplate(
                      id: template.id,
                      name: name,
                      type: template.type, // Should remain ScheduleType.communityMeal
                      description: description,
                    );
                    await appState.updateCustomMealTemplate(updatedTemplate);
                  }
                  if (mounted) Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  // Example: Dialog to add/edit a laundry template
  void _showLaundryTemplateDialog({CustomLaundryTemplate? template}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = template?.name ?? '';
    // String defaultDurationMinutes = template?.defaultDurationMinutes?.toString() ?? ''; // If using duration in model

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(template == null ? 'New Laundry Template' : 'Edit Laundry Template'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Template Name', border: OutlineInputBorder()),
                  validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a name' : null,
                  onChanged: (value) => name = value,
                ),
                // Optional: TextFormField for defaultDurationMinutes
                // TextFormField(
                //   initialValue: defaultDurationMinutes,
                //   decoration: const InputDecoration(labelText: 'Default Duration (minutes)', border: OutlineInputBorder()),
                //   keyboardType: TextInputType.number,
                //   onChanged: (value) => defaultDurationMinutes = value,
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // final int? duration = int.tryParse(defaultDurationMinutes); // If using duration
                  if (template == null) { // New
                    final newTemplate = CustomLaundryTemplate(
                      id: const Uuid().v4(),
                      name: name,
                      duration: template?.duration ?? Duration(minutes: 60) // Example default, adjust if model has it
                      // defaultDurationMinutes: duration, // If using duration
                    );
                    await appState.saveCustomLaundryTemplate(newTemplate);
                  } else { // Editing
                    final updatedTemplate = CustomLaundryTemplate(
                      id: template.id,
                      name: name,
                      duration: template.duration // Preserve existing duration or allow edit
                      // defaultDurationMinutes: duration, // If using duration
                    );
                    await appState.updateCustomLaundryTemplate(updatedTemplate);
                  }
                  if (mounted) Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Example: Dialog to add/edit a rotation rule
  void _showRotationRuleDialog({RotationRule? rule}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String description = rule?.description ?? '';
    ScheduleType type = rule?.type ?? ScheduleType.task; // Default to task

    final applicableTypes = ScheduleType.values.where((st) => st == ScheduleType.task || st == ScheduleType.communityMeal).toList();
    if (rule == null && !applicableTypes.contains(type)) {
      type = applicableTypes.isNotEmpty ? applicableTypes.first : ScheduleType.task;
    } else if (rule != null && !applicableTypes.contains(rule.type)) {
      type = applicableTypes.isNotEmpty ? applicableTypes.first : ScheduleType.task;
    }

    // Need to use a StatefulWidget or StatefulBuilder for the Dropdown's state if its selection needs to be reactive within the dialog
    // For simplicity, current 'type' variable will be updated directly, and DropdownButtonFormField might not visually update until dialog rebuilds or on save.
    // A more robust solution would use a local state variable within a StatefulBuilder for the Dropdown.

    showDialog(
      context: context,
      builder: (dialogContext) { // Renamed context
        // Local state for dropdown - this is one way to handle dropdown state inside stateless AlertDialog
        ScheduleType selectedType = type; 
        return StatefulBuilder( // Use StatefulBuilder to manage local state of the dialog's content
          builder: (stfContext, setDialogState) {
            return AlertDialog(
              title: Text(rule == null ? 'New Rotation Rule' : 'Edit Rotation Rule'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: description,
                      decoration: const InputDecoration(labelText: 'Rule Description', border: OutlineInputBorder()),
                      validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a description' : null,
                      onChanged: (value) => description = value,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ScheduleType>(
                      value: selectedType, // Use local state variable
                      decoration: const InputDecoration(labelText: 'Applies to Schedule Type', border: OutlineInputBorder()),
                      items: applicableTypes.map((ScheduleType value) {
                        return DropdownMenuItem<ScheduleType>(
                          value: value,
                          child: Text(value.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (ScheduleType? newValue) {
                        if (newValue != null) {
                          setDialogState(() { // Update local state for dropdown
                            selectedType = newValue;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Please select a type' : null,
                    ),
                    // TODO: Add fields for rule parameters if model supports it
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (rule == null) { // New
                        final newRule = RotationRule(
                          id: const Uuid().v4(),
                          description: description,
                          type: selectedType, // Use selectedType from dialog state
                        );
                        await appState.saveRotationRule(newRule);
                      } else { // Editing
                        final updatedRule = RotationRule(
                          id: rule.id,
                          description: description,
                          type: selectedType, // Use selectedType from dialog state
                        );
                        await appState.updateRotationRule(updatedRule);
                      }
                      if (mounted) Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void _showEditLaundryDurationDialog(AppStateProvider appState) {
    final TextEditingController durationController = TextEditingController(
        text: appState.laundrySlotDuration.inMinutes.toString());
    showDialog(
        context: context,
        builder: (context) {
            return AlertDialog(
                title: Text("Set Laundry Slot Duration"),
                content: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Duration in minutes"),
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                    TextButton(
                        onPressed: () async {
                            final minutes = int.tryParse(durationController.text);
                            if (minutes != null && minutes > 0) {
                                await appState.setLaundrySlotDuration(Duration(minutes: minutes));
                                if (mounted) Navigator.pop(context);
                            } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Invalid duration."))
                                  );
                                }
                            }
                        },
                        child: Text("Save")),
                ],
            );
        });
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Customization'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Task Templates
          _buildSectionHeader(context, 'Task Templates', () => _showTaskTemplateDialog()),
          if (appState.customTaskTemplates.isEmpty)
            const ListTile(title: Text('No task templates yet.')),
          ...appState.customTaskTemplates.map((template) => ListTile(
            title: Text(template.name),
            trailing: IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _showTaskTemplateDialog(template: template)),
            // TODO: Add delete action
          )),
          const Divider(),

          // Section: Meal Templates
          _buildSectionHeader(context, 'Meal Templates', () => _showMealTemplateDialog()),
          if (appState.customMealTemplates.isEmpty)
            const ListTile(title: Text('No meal templates yet.')),
          ...appState.customMealTemplates.map((template) {
            if (template.type != ScheduleType.communityMeal) return const SizedBox.shrink(); // Filter for meal templates
            return ListTile(
              title: Text(template.name),
              subtitle: Text(template.description.isNotEmpty ? template.description : 'No description/menu'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_rounded, color: theme.colorScheme.secondary), onPressed: () => _showMealTemplateDialog(template: template)),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (confirmContext) => AlertDialog(
                          title: const Text("Delete Meal Template?"),
                          content: Text("Are you sure you want to delete '${template.name}'? This cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () async {
                                await appState.deleteCustomMealTemplate(template.id);
                                if (mounted) Navigator.pop(confirmContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("'${template.name}' deleted." ))
                                );
                              },
                              child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          const Divider(),

          // Section: Laundry Settings
           Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Laundry Settings", style: theme.textTheme.titleLarge),
                ),
                ListTile(
                  title: Text("Default Slot Duration"),
                  subtitle: Text("${appState.laundrySlotDuration.inMinutes} minutes"),
                  trailing: IconButton(
                    icon: Icon(Icons.edit_rounded),
                    onPressed: () => _showEditLaundryDurationDialog(appState),
                  ),
                ),
                 Padding(
                  padding: const EdgeInsets.only(left:16.0, top: 8.0, bottom: 0), // Align with ListTile title
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Laundry Templates", style: theme.textTheme.titleMedium), // Smaller header for sub-section
                      IconButton(icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary), onPressed: () => _showLaundryTemplateDialog()),
                    ],
                  ),
                ),
                if (appState.customLaundryTemplates.isEmpty)
                  const ListTile(title: Text('No laundry templates yet.'), dense: true, contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0)),
                ...appState.customLaundryTemplates.map((template) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                    title: Text(template.name),
                    subtitle: Text("Duration: ${template.duration.inMinutes} min"), // Assumes CustomLaundryTemplate has duration
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit_rounded, color: theme.colorScheme.secondary), onPressed: () => _showLaundryTemplateDialog(template: template)),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (confirmContext) => AlertDialog(
                                title: const Text("Delete Laundry Template?"),
                                content: Text("Are you sure you want to delete '${template.name}'? This cannot be undone."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text("Cancel")),
                                  TextButton(
                                    onPressed: () async {
                                      await appState.deleteCustomLaundryTemplate(template.id);
                                      if (mounted) Navigator.pop(confirmContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("'${template.name}' deleted." ))
                                      );
                                    },
                                    child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            )
          ),
          const Divider(),

          // Section: Rotation Rules
          _buildSectionHeader(context, 'Rotation Rules', () => _showRotationRuleDialog()),
          if (appState.rotationRules.isEmpty)
            const ListTile(title: Text('No rotation rules defined yet.')),
          ...appState.rotationRules.map((rule) {
            return ListTile(
              title: Text(rule.description),
              subtitle: Text("Applies to: ${rule.type.toString().split('.').last}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_rounded, color: theme.colorScheme.secondary), onPressed: () => _showRotationRuleDialog(rule: rule)),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (confirmContext) => AlertDialog(
                          title: const Text("Delete Rotation Rule?"),
                          content: Text("Are you sure you want to delete the rule: '${rule.description}'? This cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () async {
                                await appState.deleteRotationRule(rule.id);
                                if (mounted) Navigator.pop(confirmContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Rule '${rule.description}' deleted." ))
                                );
                              },
                              child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onAdd) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAdd,
            tooltip: 'Add New $title',
          ),
        ],
      ),
    );
  }
}
