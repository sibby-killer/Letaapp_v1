import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/vendor_provider.dart';

class EditStoreScreen extends StatefulWidget {
  const EditStoreScreen({super.key});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  File? _selectedLogo;
  File? _selectedBanner;
  String? _currentLogoUrl;
  String? _currentBannerUrl;
  bool _isLoading = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  void _loadStoreData() {
    final store = context.read<VendorProvider>().store;
    if (store != null) {
      _nameController.text = store.name;
      _descriptionController.text = store.description ?? '';
      _addressController.text = store.address ?? '';
      _phoneController.text = store.phone ?? '+254';
      _currentLogoUrl = store.logoUrl;
      _currentBannerUrl = store.bannerUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isLogo) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: isLogo ? 512 : 1920,
        maxHeight: isLogo ? 512 : 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isLogo) {
            _selectedLogo = File(pickedFile.path);
          } else {
            _selectedBanner = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showImagePicker(bool isLogo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isLogo ? 'Change Store Logo' : 'Change Store Banner',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isLogo
                    ? 'Square image recommended (1:1)'
                    : 'Wide image recommended (16:9)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isLogo);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isLogo);
                },
              ),
              if ((isLogo && (_currentLogoUrl != null || _selectedLogo != null)) ||
                  (!isLogo && (_currentBannerUrl != null || _selectedBanner != null)))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: AppTheme.errorRed),
                  ),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      if (isLogo) {
                        _selectedLogo = null;
                        _currentLogoUrl = null;
                      } else {
                        _selectedBanner = null;
                        _currentBannerUrl = null;
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File image, String type, String storeId) async {
    try {
      final fileName = '${type}_$storeId\_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await image.readAsBytes();
      
      await Supabase.instance.client.storage
          .from('store-images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ));

      return Supabase.instance.client.storage
          .from('store-images')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload $type: $e');
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vendorProvider = context.read<VendorProvider>();
      final store = vendorProvider.store;
      if (store == null) return;

      String? logoUrl = _currentLogoUrl;
      String? bannerUrl = _currentBannerUrl;

      // Upload new logo if selected
      if (_selectedLogo != null) {
        setState(() => _isUploadingLogo = true);
        logoUrl = await _uploadImage(_selectedLogo!, 'logo', store.id);
        setState(() => _isUploadingLogo = false);
      }

      // Upload new banner if selected
      if (_selectedBanner != null) {
        setState(() => _isUploadingBanner = true);
        bannerUrl = await _uploadImage(_selectedBanner!, 'banner', store.id);
        setState(() => _isUploadingBanner = false);
      }

      // Update store
      final success = await vendorProvider.updateStore(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vendorProvider.errorMessage ?? 'Failed to update store'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploadingLogo = false;
        _isUploadingBanner = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // YouTube-style header with banner
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image
                  GestureDetector(
                    onTap: () => _showImagePicker(false),
                    child: _selectedBanner != null
                        ? Image.file(_selectedBanner!, fit: BoxFit.cover)
                        : _currentBannerUrl != null
                            ? Image.network(_currentBannerUrl!, fit: BoxFit.cover)
                            : Container(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 48, color: Colors.white70),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add banner',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Edit banner button
                  Positioned(
                    bottom: 60,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => _showImagePicker(false),
                      icon: _isUploadingBanner
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Edit Banner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  // Logo positioned at bottom
                  Positioned(
                    bottom: 0,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => _showImagePicker(true),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: AppTheme.primaryGreen,
                              backgroundImage: _selectedLogo != null
                                  ? FileImage(_selectedLogo!)
                                  : (_currentLogoUrl != null
                                      ? NetworkImage(_currentLogoUrl!)
                                      : null) as ImageProvider?,
                              child: (_selectedLogo == null && _currentLogoUrl == null)
                                  ? const Icon(Icons.store, size: 40, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _isUploadingLogo
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveStore,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          // Form content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Store Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Name',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter store name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: Icon(Icons.description_outlined),
                        ),
                        hintText: 'Tell customers about your store...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+254 7XX XXX XXX',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-]')),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Tips for a great store',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTip('Use a clear, high-quality logo'),
                          _buildTip('Add an attractive banner image'),
                          _buildTip('Write a compelling description'),
                          _buildTip('Keep your contact info updated'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
