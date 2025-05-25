import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:path/path.dart' as path_package;
import 'package:async/async.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePageDetailed extends StatefulWidget {
  @override
  _ProfilePageDetailedState createState() => _ProfilePageDetailedState();
}

class _ProfilePageDetailedState extends State<ProfilePageDetailed> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? userId;
  String? userName;
  String? userEmail;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    userId = args['id'] as String? ?? 'unknown_user';
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = dotenv.env['API_URL'];
      final response = await http.get(
        Uri.parse('$baseUrl/user_profile?id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userName = data['name'];
          userEmail = data['email'];
          profileImageUrl = data['profile_image'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 정보를 가져오는데 실패했습니다.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _uploadImage();
      }
    } catch (e) {
      String errorMessage = '이미지를 선택할 수 없습니다';
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        errorMessage = '이미지에 접근하려면 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = dotenv.env['API_URL'];
      var uri = Uri.parse('$baseUrl/update_profile_image');

      var stream = http.ByteStream(
        DelegatingStream.typed(_imageFile!.openRead()),
      );
      var length = await _imageFile!.length();

      var request = http.MultipartRequest('POST', uri);
      request.fields['id'] = userId!;

      var multipartFile = http.MultipartFile(
        'profile_image',
        stream,
        length,
        filename: path_package.basename(_imageFile!.path),
      );

      request.files.add(multipartFile);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final respData = jsonDecode(responseBody);
        setState(() {
          profileImageUrl = respData['profile_image_url'];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 이미지가 업데이트되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드에 실패했습니다: $responseBody'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: Color(0xFF36eff4)),
                  title: Text('갤러리에서 선택', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Color(0xFF36eff4)),
                  title: Text('카메라로 촬영', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF36eff4)))
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : AssetImage('assets/basic.png'),
                      ),
                      GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Color(0xFF36eff4),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    userName ?? '이름 없음',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userEmail ?? '이메일 없음',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ID: $userId',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildMenuCard(
                    icon: Icons.assignment_turned_in,
                    color: Color(0xFF36eff4),
                    title: '완료한 프로젝트',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/done_projects',
                        arguments: {'id': userId},
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildMenuCard(
                    icon: Icons.star,
                    color: Colors.orange,
                    title: '내 평가',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/my_reviews',
                        arguments: {'id': userId},
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildMenuCard(
                    icon: Icons.logout,
                    color: Colors.redAccent,
                    title: '로그아웃',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: title == '로그아웃'
                ? Colors.redAccent
                : Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}