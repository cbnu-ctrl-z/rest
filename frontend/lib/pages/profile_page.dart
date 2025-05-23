import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:path/path.dart' as path_package;
import 'package:async/async.dart';

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

  String selectedLanguage = '한국어'; // 기본값
  final List<String> languages = ['한국어', 'English'];

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('프로필 정보를 가져오는데 실패했습니다.')));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      print("이미지 선택 시작: ${source == ImageSource.camera ? '카메라' : '갤러리'}");

      // 이미지 선택기 직접 실행 - 필요한 권한을 자동으로 요청합니다
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        print("이미지 선택 완료: ${pickedFile.path}");
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // 이미지 업로드
        _uploadImage();
      } else {
        print("이미지 선택 취소됨");
      }
    } catch (e) {
      print("이미지 선택 오류: $e");
      String errorMessage = '이미지를 선택할 수 없습니다';

      // 권한 관련 오류인지 확인
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        errorMessage = '이미지에 접근하려면 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('프로필 이미지가 업데이트되었습니다!')));
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드에 실패했습니다: $responseBody')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  // Flutter 코드에서 한국어/English를 -> Korean/English로 매핑해서 서버로 전송하도록 수정
  Future<void> _updateLanguagePreference(String userId, String language) async {
    // 매핑 딕셔너리
    final languageMap = {
      '한국어': 'Korean',
      'English': 'English',
    };

    final mappedLanguage = languageMap[language] ?? 'Korean'; // 기본값 Korean

    final baseUrl = dotenv.env['API_URL'];
    final response = await http.post(
      Uri.parse('$baseUrl/update_language'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': userId,
        'language': mappedLanguage, // 매핑된 언어 전송
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('언어 설정이 업데이트되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('언어 설정 실패: ${response.body}')),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('카메라로 촬영'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider
                              : AssetImage('assets/simpo_b.jpg'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _showImageSourceActionSheet,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  userName ?? '이름 없음',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  userEmail ?? '이메일 없음',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'ID: $userId',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                Divider(),
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('내 공강 시간'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/freetime',
                      arguments: {'id': userId},
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('설정'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/settings',
                      arguments: {'id': userId},
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('언어 설정'),
                  trailing: DropdownButton<String>(
                    value: selectedLanguage,
                    items: languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                        _updateLanguagePreference(userId!, selectedLanguage);
                      });
                    },
                  ),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    '로그아웃',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    // 로그아웃 로직: 필요 시 토큰 삭제 등 수행 가능
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',  // 로그인 화면 라우트 이름
                          (route) => false, // 모든 이전 화면 제거
                    );
                  },
                ),
              ],
            ),
          ),
        );
  }
}
