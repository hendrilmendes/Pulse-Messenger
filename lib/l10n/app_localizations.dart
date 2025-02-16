import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'Pulse'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In pt, this message translates to:
  /// **'Feed'**
  String get home;

  /// No description provided for @search.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @chat.
  ///
  /// In pt, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @activity.
  ///
  /// In pt, this message translates to:
  /// **'Atividades'**
  String get activity;

  /// No description provided for @profile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @shared.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get shared;

  /// No description provided for @comments.
  ///
  /// In pt, this message translates to:
  /// **'Comentários'**
  String get comments;

  /// No description provided for @noPost.
  ///
  /// In pt, this message translates to:
  /// **'Sem novas publicações.'**
  String get noPost;

  /// No description provided for @postImage.
  ///
  /// In pt, this message translates to:
  /// **'Postar Imagem'**
  String get postImage;

  /// No description provided for @postVideo.
  ///
  /// In pt, this message translates to:
  /// **'Postar Vídeo'**
  String get postVideo;

  /// No description provided for @createPost.
  ///
  /// In pt, this message translates to:
  /// **'Criar Publicação'**
  String get createPost;

  /// No description provided for @content.
  ///
  /// In pt, this message translates to:
  /// **'Legenda'**
  String get content;

  /// No description provided for @insertContent.
  ///
  /// In pt, this message translates to:
  /// **'Por favor insira a legenda'**
  String get insertContent;

  /// No description provided for @post.
  ///
  /// In pt, this message translates to:
  /// **'Postar'**
  String get post;

  /// No description provided for @postMomment.
  ///
  /// In pt, this message translates to:
  /// **'Criar Momentos'**
  String get postMomment;

  /// No description provided for @noMomment.
  ///
  /// In pt, this message translates to:
  /// **'Não há momentos disponíveis.'**
  String get noMomment;

  /// No description provided for @deleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Exclusão'**
  String get deleteConfirm;

  /// No description provided for @deleteMomment.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja excluir esta história?'**
  String get deleteMomment;

  /// No description provided for @account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get editProfile;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @desconnect.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get desconnect;

  /// No description provided for @ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noComment.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum comentário disponível'**
  String get noComment;

  /// No description provided for @hintText.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua mensagem...'**
  String get hintText;

  /// No description provided for @hintTextMomment.
  ///
  /// In pt, this message translates to:
  /// **'Em que você esta pensando...'**
  String get hintTextMomment;

  /// No description provided for @existentUser.
  ///
  /// In pt, this message translates to:
  /// **'Este nome de usuário já está em uso.'**
  String get existentUser;

  /// No description provided for @imageProfile.
  ///
  /// In pt, this message translates to:
  /// **'Imagem de Perfil'**
  String get imageProfile;

  /// No description provided for @updateImageProfile.
  ///
  /// In pt, this message translates to:
  /// **'Imagem de perfil atualizada com sucesso!'**
  String get updateImageProfile;

  /// No description provided for @errorImageProfile.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar a imagem.'**
  String get errorImageProfile;

  /// No description provided for @profileInformation.
  ///
  /// In pt, this message translates to:
  /// **'Informações do Perfil'**
  String get profileInformation;

  /// No description provided for @userName.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Usuário'**
  String get userName;

  /// No description provided for @insertUserName.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu nome de usuário'**
  String get insertUserName;

  /// No description provided for @bio.
  ///
  /// In pt, this message translates to:
  /// **'Biografia'**
  String get bio;

  /// No description provided for @insertBio.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua bio'**
  String get insertBio;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get delete;

  /// No description provided for @noConnection.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a Terra'**
  String get noConnection;

  /// No description provided for @noConnectionSub.
  ///
  /// In pt, this message translates to:
  /// **'Verifique se você realmente e um humano'**
  String get noConnectionSub;

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar'**
  String get refresh;

  /// No description provided for @noResult.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado'**
  String get noResult;

  /// No description provided for @sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando...'**
  String get sending;

  /// No description provided for @selectFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolha sua melhor foto ou vídeo'**
  String get selectFile;

  /// No description provided for @about.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get about;

  /// No description provided for @copyright.
  ///
  /// In pt, this message translates to:
  /// **'Todos os direitos reservados'**
  String get copyright;

  /// No description provided for @version.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// No description provided for @privacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get privacy;

  /// No description provided for @privacyPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Politica de Privacidade'**
  String get privacyPolicy;

  /// No description provided for @sourceCode.
  ///
  /// In pt, this message translates to:
  /// **'Código Fonte'**
  String get sourceCode;

  /// No description provided for @openSource.
  ///
  /// In pt, this message translates to:
  /// **'Licenças de Código Aberto'**
  String get openSource;

  /// No description provided for @notification.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notification;

  /// No description provided for @interface.
  ///
  /// In pt, this message translates to:
  /// **'Interface'**
  String get interface;

  /// No description provided for @outhers.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get outhers;

  /// No description provided for @theme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSelect.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o Tema'**
  String get themeSelect;

  /// No description provided for @darkMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Escuro'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Claro'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In pt, this message translates to:
  /// **'Padrão do Sistema'**
  String get systemMode;

  /// No description provided for @update.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações'**
  String get update;

  /// No description provided for @updateSub.
  ///
  /// In pt, this message translates to:
  /// **'Toque para buscar por novas versões do app'**
  String get updateSub;

  /// No description provided for @support.
  ///
  /// In pt, this message translates to:
  /// **'Suporte'**
  String get support;

  /// No description provided for @supportSub.
  ///
  /// In pt, this message translates to:
  /// **'Encontrou um bug ou deseja sugerir algo?'**
  String get supportSub;

  /// No description provided for @review.
  ///
  /// In pt, this message translates to:
  /// **'Avalie o App'**
  String get review;

  /// No description provided for @reviewSub.
  ///
  /// In pt, this message translates to:
  /// **'Faça uma avaliação na loja de apps'**
  String get reviewSub;

  /// No description provided for @aboutSub.
  ///
  /// In pt, this message translates to:
  /// **'Um pouco mais sobre o app'**
  String get aboutSub;

  /// No description provided for @searchFor.
  ///
  /// In pt, this message translates to:
  /// **'Procurar por...'**
  String get searchFor;

  /// No description provided for @homeLogin.
  ///
  /// In pt, this message translates to:
  /// **'Bem vindo ao nosso app, aproveite 😁'**
  String get homeLogin;

  /// No description provided for @googleLogin.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com Google'**
  String get googleLogin;

  /// No description provided for @desconect.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get desconect;

  /// No description provided for @alreadyReviewed.
  ///
  /// In pt, this message translates to:
  /// **'Você já avaliou o app'**
  String get alreadyReviewed;

  /// No description provided for @errorCommentsDelete.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao apagar comentário'**
  String get errorCommentsDelete;

  /// No description provided for @errorCommentsDeleteSub.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível apagar os comentários de outros usuários.'**
  String get errorCommentsDeleteSub;

  /// No description provided for @confirmDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar Comentário'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteSub.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente apagar esse comentário?'**
  String get confirmDeleteSub;

  /// No description provided for @savedPosts.
  ///
  /// In pt, this message translates to:
  /// **'Postagens Salvas'**
  String get savedPosts;

  /// No description provided for @noSavedPosts.
  ///
  /// In pt, this message translates to:
  /// **'Não há postagens salvas'**
  String get noSavedPosts;

  /// No description provided for @noUser.
  ///
  /// In pt, this message translates to:
  /// **'Não foi encontrado esse usuário'**
  String get noUser;

  /// No description provided for @noMedia.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum post com mídia encontrado'**
  String get noMedia;

  /// No description provided for @changeLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma alterado para'**
  String get changeLanguage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
