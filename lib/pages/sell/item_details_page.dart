import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vbay/components/teal_button.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/pages/sell/preview_page.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/globals.dart';

class ItemDetailsPage extends StatefulWidget {
  final String? imagePath;
  final Product? item;

  const ItemDetailsPage({super.key, this.imagePath, this.item});

  @override
  _ItemDetailsPageState createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? selectedCategory;
  String? selectedCondition;

  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();

    // Prefill data if editing an item
    if (widget.item != null) {
      _nameController.text = widget.item!.itemName;
      _priceController.text = widget.item!.price.toString();
      if (widget.item?.quantity != null) {
        _qtyController.text = widget.item!.quantity.toString();
      }
      _descController.text = widget.item!.itemDescription;
      selectedCategory = widget.item!.category;
      selectedCondition = widget.item!.condition;
    } else {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await UserDataService().fetchUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<File> _copyToPermanentStorage(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime
        .now()
        .millisecondsSinceEpoch}.jpg';
    final newFile = File('${directory.path}/$fileName');
    final sourceFile = File(sourcePath);

    if (await sourceFile.exists()) {
      return await sourceFile.copy(newFile.path);
    } else {
      throw Exception("Source file does not exist.");
    }
  }

  Future<void> _createOrUpdateItem() async {
    if (_nameController.text.isEmpty ||
        selectedCategory == null ||
        selectedCondition == null ||
        _priceController.text.isEmpty ||
        _descController.text.isEmpty) {
      Utils.showSnackBar(context, 'Please fill in all required fields.');
      return;
    }
    if (int.parse(_priceController.text) > 25000) {
      Utils.showSnackBar(context, 'Price exceeds the allowed limit.');
      return;
    }

    try {
      Utils.showLoading(context);

      String? imagePath;
      if (widget.imagePath != null) {
        final permanentFile = await _copyToPermanentStorage(widget.imagePath!);
        imagePath = permanentFile.path;
      }

      final itemData = {
        'itemName': _nameController.text,
        'category': selectedCategory,
        'condition': selectedCondition,
        'price': int.tryParse(_priceController.text),
        'quantity': int.tryParse(_qtyController.text),
        'itemDescription': _descController.text,
        'imagePath': imagePath ?? widget.item?.imagePath,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': "Pending",
      };

      if (widget.item != null) {
        final changes = [
          if (selectedCategory != widget.item?.category) 'category',
          if (selectedCondition != widget.item?.condition) 'condition',
          if (int.tryParse(_priceController.text) != widget.item?.price) 'price',
          if (int.tryParse(_qtyController.text) != widget.item?.quantity) 'quantity',
          if (_nameController.text != widget.item?.itemName) 'name',
          if (_descController.text != widget.item?.itemDescription) 'description',
        ];

        if (changes.isEmpty) {
          Utils.showSnackBar(context, 'No changes were made.');
          Navigator.of(context).pop();

          return;
        }

        final requiresApproval =
        changes.any((field) => !['price', 'quantity', 'category', 'condition'].contains(field));

        if (!requiresApproval && widget.item!.reasons == null && widget.item!.reasons != null) {
          itemData['status'] = 'Active';
          await UserDataService().updateAdDirectly(context, widget.item!.itemID!, itemData);
        } else {
          if (widget.item!.reasons != null) itemData['reasons'] = widget.item!.reasons;
          await UserDataService().updateAd(context, widget.item!.itemID!, itemData);
        }

        _showSnackBar('Item updated successfully!');
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } else {
        await UserDataService().createAd(context, itemData);
        _showSnackBar('Ad Sent For Review!');
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        BottomNavbarKey.instance.key.currentState?.changeTab(4);
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    Utils.showSnackBar(navigatorKey.currentContext!, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .secondary,
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .secondary,
        title: const Text('Item Details', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(CupertinoIcons.arrow_left, size: 30), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
                icon: Icon(CupertinoIcons.eye, size: 30, color: Color(0xFF00C1A2)),
                onPressed: () {
                  var item = Product(
                    itemName: _nameController.text.isNotEmpty ? _nameController.text : 'Title',
                    price: int.tryParse(_priceController.text) ?? 0,
                    quantity: int.tryParse(_qtyController.text),
                    itemDescription: _descController.text.isNotEmpty ? _descController.text : 'Description',
                    imagePath: widget.imagePath ?? widget.item!.imagePath,
                    condition: selectedCondition ?? 'Condition',
                    category: selectedCategory ?? 'Category',
                    sellerName: userProfile?['name'],
                    sellerHostel: userProfile?['hostel'],
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PreviewPage(item: item)));
                }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: widget.imagePath != null
                  ? Image.file(
                File(widget.imagePath!),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Image.network(
                widget.item!.imagePath,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image from network: ${error.toString()}');
                  return Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/default.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  );
                },
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField('Item Name', _nameController),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildDropdownField('Category', selectedCategory, categoryList, (newValue) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField('Condition', selectedCondition, conditionList, (newValue) {
                    setState(() {
                      selectedCondition = newValue;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Quantity (Optional)',
                    _qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('Price', _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      prefix: Text('₹ ',
                          style: TextStyle(fontSize: 16, color: Theme
                              .of(context)
                              .colorScheme
                              .inversePrimary))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Tell others about your product', _descController, maxLines: 4, maxLength: 50),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.item != null) Utils.buildEmptyIcon(),
                TealButton(text: widget.item != null ? 'Update Item' : 'Publish Ad', onTap: _createOrUpdateItem),
                if (widget.item != null)
                  Row(
                    children: [
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                            onPressed: () =>
                                Utils.showDialogBox(
                                    context: context,
                                    message: 'Are you sure you want to delete this Ad?\nThis action cannot be undone.',
                                    onConfirm: () async {
                                      await UserDataService().deleteAdOrSeek(context, widget.item);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    }),
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red[400],
                              size: 30,
                            )),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        int? maxLength,
        Widget? prefix,
        List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme
          .of(context)
          .colorScheme
          .inversePrimary),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters ??
          (keyboardType == TextInputType.number
              ? [
            FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ]
              : (maxLength != null ? [LengthLimitingTextInputFormatter(maxLength)] : null)),
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme
            .of(context)
            .colorScheme
            .onInverseSurface),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme
              .of(context)
              .colorScheme
              .onSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme
              .of(context)
              .colorScheme
              .onInverseSurface),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        prefix: prefix,
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme
            .of(context)
            .colorScheme
            .onInverseSurface),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme
              .of(context)
              .colorScheme
              .onSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme
              .of(context)
              .colorScheme
              .onInverseSurface),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            textAlign: TextAlign.center,
            item,
            style: label == "Category"
                ? TextStyle(color: Theme
                .of(context)
                .colorScheme
                .onInverseSurface)
                : TextStyle(
              color: item == "Fresh" ? Colors.lightGreen : Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: Theme
          .of(context)
          .colorScheme
          .secondary,
    );
  }
}
