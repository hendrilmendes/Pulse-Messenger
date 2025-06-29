import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social/screens/profile/create/create.dart';
import 'package:social/services/auth/auth.dart';
import 'package:social/widgets/bottom_navigation.dart';
import 'package:social/utils/country_data.dart';
import 'package:social/utils/language_data.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({required this.authService, super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String selectedCountry = 'BR';
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    CountryData.fetchCountriesFromApi()
        .then((_) {
          if (!mounted) return;
          setState(() {
            if (CountryData.countries.containsKey('BR')) {
              selectedCountry = 'BR';
            } else if (CountryData.countries.isNotEmpty) {
              selectedCountry = CountryData.countries.keys.first;
            }
          });
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar países: $e')),
          );
        });
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha o idioma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...languageOptions.map(
                (lang) => ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(lang.name),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showCountryPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (CountryData.countries[selectedCountry]?['flag'] !=
                              null &&
                          CountryData.countries[selectedCountry]!['flag']
                              .toString()
                              .isNotEmpty)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl:
                                  CountryData
                                      .countries[selectedCountry]?['flag'] ??
                                  '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.flag, size: 20),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(
                        CountryData.countries[selectedCountry]?['ddi'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Divisor vertical
              Container(width: 1, height: 24, color: Colors.grey[300]),
              const SizedBox(width: 12),
              // Campo de telefone
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Número de telefone",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                ),
              ),
              if (_phoneController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _phoneController.clear(),
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        List<MapEntry<String, dynamic>> filteredCountries = CountryData
            .countries
            .entries
            .toList();

        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCountries(String query) {
              setModalState(() {
                filteredCountries = CountryData.countries.entries.where((
                  entry,
                ) {
                  final name = (entry.value['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final ddi = (entry.value['ddi'] ?? '').toString();
                  final q = query.toLowerCase();
                  return name.contains(q) || ddi.contains(q);
                }).toList();
              });
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Selecione seu país',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por nome ou DDI',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: filterCountries,
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                Expanded(
                  child: ListView.separated(
                    controller: PrimaryScrollController.of(context),
                    itemCount: filteredCountries.length,
                    separatorBuilder: (_, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final entry = filteredCountries[index];
                      final country = entry.value;
                      final isSelected = entry.key == selectedCountry;
                      return ListTile(
                        leading: SizedBox(
                          width: 36,
                          child: Center(
                            child: country['flag'] != null
                                ? Image.network(
                                    country['flag'] ?? '',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        title: Text(
                          country['name'] ?? '',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        subtitle: Text('DDI: ${country['ddi'] ?? ''}'),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            selectedCountry = entry.key;
                          });
                          Navigator.pop(context);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handlePhoneLogin() async {
    if (_phoneController.text.isEmpty) return;

    final country = CountryData.countries[selectedCountry];
    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um país válido.')),
      );
      return;
    }

    final phoneNumber = '+${country['ddi']}${_phoneController.text}';

    try {
      await widget.authService.verifyPhoneNumber(
        phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {});
          _showSmsCodeDialog(context);
        },
        onVerificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Falha na verificação para ${country['name']} (${country['ddi']}): ${e.message}',
              ),
            ),
          );
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await widget.authService.signInWithCredential(
            credential,
          );
          if (userCredential.user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNav()),
            );
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro no login para ${country['name']} (${country['ddi']}): ${e.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmSMSCode(String smsCode) async {
    try {
      final user = await widget.authService.confirmSMSCode(smsCode);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código inválido: ${e.toString()}')),
      );
    }
  }

  Future<void> _showSmsCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código de Verificação'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Digite o código SMS'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmSMSCode(codeController.text);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: () => _showLanguagePicker(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Português",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[100]
                              : Colors.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Image.asset('assets/img/logo.png', height: 60),
                    // Título
                    const SizedBox(height: 40),
                    Text(
                      "Que bom te ver por aqui :)",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[100]
                            : Colors.grey[900],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Campo de telefone
                    _buildPhoneInput(),

                    const SizedBox(height: 24),
                    // Botão continuar
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _phoneController.text.isEmpty
                            ? null
                            : _handlePhoneLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "CONTINUAR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divisor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "ou",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão Google
                    FilledButton(
                      onPressed: _isGoogleLoading
                          ? null
                          : () async {
                              setState(() => _isGoogleLoading = true);
                              try {
                                final userCredential = await widget.authService
                                    .signInWithGoogle();
                                if (userCredential != null) {
                                  if (userCredential
                                          .additionalUserInfo
                                          ?.isNewUser ??
                                      false) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompleteProfileScreen(
                                              authService: widget.authService,
                                              user: userCredential.user!,
                                            ),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const BottomNav(),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Falha no login: ${e.toString()}',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[100]
                            : Colors.grey[900],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/google_logo.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text("Entrar com Google"),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Rodapé
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Ao continuar, você concorda com os ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    TextSpan(
                      text: "Termos de Uso",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[100]
                            : Colors.grey[900],
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    TextSpan(
                      text: " e ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    TextSpan(
                      text: "Política de Privacidade",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[100]
                            : Colors.grey[900],
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
