import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🔥 added
import 'package:just_audio/just_audio.dart'; // 🔥 added — for reading duration locally
import '../../model/podcast.dart';
import '../../service/podcast_service.dart';
// 🔥 removed: import '../../service/cloudinary_service.dart';

class CreatePodcastScreen extends StatefulWidget {
  const CreatePodcastScreen({super.key});

  @override
  State<CreatePodcastScreen> createState() => _CreatePodcastScreenState();
}

class _CreatePodcastScreenState extends State<CreatePodcastScreen> {
  static const Color _brandGreen = Color(0xFF4A6741);

  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');

  String _category = 'Mental Health';
  bool _isPremium = false;
  File? _mediaFile;
  String _mediaFileName = '';

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  static const List<String> _categories = [
    'Mental Health', 'Anxiety', 'Stress',
    'Mindfulness', 'Motivation', 'Sleep', 'Other',
  ];

  // 🔥 video extensions — anything else is treated as audio
  static const List<String> _videoExtensions = ['mp4', 'mov', 'avi', 'mkv'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'mp4', 'm4a', 'wav', 'aac'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _mediaFile = File(result.files.single.path!);
      _mediaFileName = result.files.single.name;
      _error = null;
    });
  }

  // 🔥 NEW — reads duration from the local file before uploading.
  // Falls back to 0 if the format can't be parsed (won't block upload).
  Future<int> _getDurationSeconds(File file) async {
    final tempPlayer = AudioPlayer();
    try {
      final duration = await tempPlayer.setFilePath(file.path);
      return duration?.inSeconds ?? 0;
    } catch (e) {
      debugPrint('Could not read media duration: $e');
      return 0;
    } finally {
      await tempPlayer.dispose();
    }
  }

  // 🔥 NEW — uploads to Firebase Storage under podcasts/, reports progress,
  // returns the public download URL.
  Future<String> _uploadToFirebaseStorage(
    File file,
    void Function(double progress) onProgress,
  ) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'podcast_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('podcasts').child(fileName);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: _contentTypeFor(ext)),
    );

    final subscription = uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    try {
      final completedSnapshot = await uploadTask;
      return await completedSnapshot.ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();

    if (title.isEmpty || author.isEmpty) {
      setState(() => _error = 'Title and author are required.');
      return;
    }
    if (_mediaFile == null) {
      setState(() => _error = 'Please select an audio or video file.');
      return;
    }
    if (_isPremium) {
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      if (price <= 0) {
        setState(() => _error = 'Enter a valid price for premium content.');
        return;
      }
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _error = null;
    });

    try {
      final ext = _mediaFile!.path.split('.').last.toLowerCase();
      final isVideo = _videoExtensions.contains(ext);

      final durationSeconds = await _getDurationSeconds(_mediaFile!);
      final durationStr = _formatDuration(durationSeconds);

      // 🔥 Firebase Storage upload replaces the old Cloudinary call
      final downloadUrl = await _uploadToFirebaseStorage(
        _mediaFile!,
        (progress) => setState(() => _uploadProgress = progress),
      );

      final price = _isPremium ? (double.tryParse(_priceCtrl.text) ?? 0) : 0.0;

      final podcast = Podcast(
        title: title,
        author: author,
        category: _category,
        duration: durationStr,
        audioUrl: isVideo ? '' : downloadUrl,
        videoUrl: isVideo ? downloadUrl : '',
        description: _descCtrl.text.trim(),
        isNew: true,
        isPremium: _isPremium,
        price: price,
        createdAt: DateTime.now(),
      );

      await PodcastService.instance.addPodcast(podcast);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Upload failed: ${e.toString()}';
      });
    }
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Podcast'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isUploading ? _buildProgress() : _buildForm(),
    );
  }

  Widget _buildProgress() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _brandGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_rounded,
                  color: _brandGreen, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Uploading…',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${(_uploadProgress * 100).toStringAsFixed(0)}% complete',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_brandGreen),
              ),
            ),
            const SizedBox(height: 12),
            Text('Please wait, this may take a moment…',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Title *'),
          _field(_titleCtrl, 'e.g. The Anxiety Solution'),
          const SizedBox(height: 16),

          _label('Author *'),
          _field(_authorCtrl, 'e.g. Dr. Priya Mehta'),
          const SizedBox(height: 16),

          _label('Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: _deco('Select category'),
            items: _categories
                .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),

          _label('Description'),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: _deco('Brief description of this episode'),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    color: Color(0xFFFFB300), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium Content',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Charge listeners to access this episode',
                          style: TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _isPremium,
                  onChanged: (v) => setState(() => _isPremium = v),
                  activeColor: _brandGreen,
                ),
              ],
            ),
          ),

          if (_isPremium) ...[
            const SizedBox(height: 14),
            _label('Price (₹) *'),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: _deco('e.g. 99'),
            ),
          ],

          const SizedBox(height: 20),

          _label('Audio / Video File *'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mediaFile != null
                    ? _brandGreen.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _mediaFile != null
                      ? _brandGreen
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _mediaFile != null
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color: _mediaFile != null
                        ? _brandGreen
                        : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _mediaFile != null
                          ? _mediaFileName
                          : 'Tap to pick mp3, mp4, m4a, wav, aac…',
                      style: TextStyle(
                        fontSize: 13,
                        color: _mediaFile != null
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.cloud_upload_rounded,
                  color: Colors.white),
              label: const Text('Upload & Publish',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      );

  Widget _field(TextEditingController ctrl, String hint) =>
      TextField(controller: ctrl, decoration: _deco(hint));

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _brandGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      );
}