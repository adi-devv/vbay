import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vbay/services/auth/auth_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/globals.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final List<String> batches = ['2021', '2022', '2023', '2024'];

  String? selectedCollege;
  String? selectedBatch;
  String? selectedHostel;

  late Future<Map<String, dynamic>?> _userDataFuture;
  bool _isInitialized = false;
  bool status = false;

  @override
  void initState() {
    super.initState();
    _getStatus();
    _userDataFuture = UserDataService().fetchUserProfile();
  }

  Future<bool> _getStatus() async {
    status = await AuthService().getStatus();
    return status;
  }

  void _initializeUserData(Map<String, dynamic> userData) {
    if (!_isInitialized) {
      _nameController.text = userData['name'];
      selectedCollege = userData['college'];
      selectedBatch = userData['batch'];
      selectedHostel = userData['hostel'];
      _phoneController.text = userData['phone'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _isInitialized = true;
    }
  }

  Future<void> saveDetails(BuildContext context) async {
    if (_nameController.text.isEmpty || selectedCollege == null || selectedBatch == null) {
      Utils.showSnackBar(context, 'Please fill in all required fields.');
      return;
    }

    final userData = {
      'name': _nameController.text,
      'college': selectedCollege,
      'batch': selectedBatch,
      'hostel': selectedHostel,
      'phone': _phoneController.text,
      'bio': _bioController.text,
    };

    try {
      if (mapEquals(userData, await UserDataService().fetchUserProfile())) {
        Utils.showSnackBar(context, 'No Changes Made!');
      } else {
        await UserDataService().saveUserProfile(context, userData);
        Utils.showSnackBar(context, 'Details saved successfully!');
      }
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving details: $e');
      Utils.showSnackBar(context, "Profile update failed. Please try again later.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.check, size: 35, color: Colors.blue),
              onPressed: () {
                saveDetails(context);
              }),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No user data found.'));
          }

          _initializeUserData(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 72,
                    child: ClipOval(
                        child: snapshot.data!['avatarUrl'] != null
                            ? CachedNetworkImage(
                                imageUrl: snapshot.data!['avatarUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Transform.translate(
                                  offset: Offset(0, 16),
                                  child: Icon(
                                    CupertinoIcons.person_alt,
                                    color: Colors.grey,
                                    size: 150,
                                  ),
                                ),
                              )
                            : Transform.translate(
                                offset: Offset(0, 16),
                                child: Icon(
                                  CupertinoIcons.person_alt,
                                  color: Colors.grey,
                                  size: 150,
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 60),
                _buildTextField('Name', _nameController, readOnly: true),
                const SizedBox(height: 16),
                _buildDropdownField(
                  'College',
                  selectedCollege,
                  hostelData.keys.toList(),
                  (value) => setState(
                    () {
                      selectedHostel = null;
                      selectedCollege = value;
                    },
                  ),
                  status: status,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Contact (Optional)',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBatchAndHostelRow(),
                const SizedBox(height: 16),
                _buildTextField(
                  'Bio (Optional)',
                  _bioController,
                  maxLength: 50,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      int? maxLength,
      int maxLines = 1,
      bool readOnly = false,
      List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(label),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged,
      {bool status = true}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
              value: item, child: Center(child: Text(item, style: TextStyle(fontWeight: FontWeight.normal)))))
          .toList(),
      onChanged: status ? onChanged : null,
      decoration: _inputDecoration(label),
      dropdownColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildBatchAndHostelRow() {
    return Row(
      children: [
        Expanded(
            child: _buildDropdownField('Hostel', selectedHostel, hostelData[selectedCollege] ?? [],
                (value) => setState(() => selectedHostel = value))),
        const SizedBox(width: 16),
        Expanded(
            child:
                _buildDropdownField('Batch', selectedBatch, batches, (value) => setState(() => selectedBatch = value))),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      enabledBorder: _borderStyle(Theme.of(context).colorScheme.onSecondary),
      focusedBorder: _borderStyle(Theme.of(context).colorScheme.onInverseSurface),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  OutlineInputBorder _borderStyle(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
