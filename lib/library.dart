// Flutter
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:songtube/internal/nativeMethods.dart';

// Internal
import 'package:songtube/internal/updateChecker.dart';
import 'package:songtube/internal/youtube/youtubeExtractor.dart';
import 'package:songtube/players/components/musicPlayer/playerPadding.dart';
import 'package:songtube/provider/configurationProvider.dart';
import 'package:songtube/provider/managerProvider.dart';
import 'package:songtube/provider/mediaProvider.dart';
import 'package:songtube/routes/playlist.dart';
import 'package:songtube/routes/video.dart';
import 'package:songtube/screens/downloads.dart';
import 'package:songtube/screens/home.dart';
import 'package:songtube/screens/media.dart';
import 'package:songtube/screens/more.dart';
import 'package:songtube/players/musicPlayer.dart';

// Packages
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:songtube/ui/animations/blurPageRoute.dart';
import 'package:songtube/ui/components/navigationBar.dart';
import 'package:songtube/ui/dialogs/appUpdateDialog.dart';
import 'package:songtube/ui/dialogs/loadingDialog.dart';
import 'package:songtube/ui/internal/disclaimerDialog.dart';
import 'package:songtube/ui/internal/downloadFixDialog.dart';
import 'package:songtube/ui/internal/lifecycleEvents.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MainLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Library(),
          SlidingPlayerPanel()
        ],
      )
    );
  }
}

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.renderView.automaticSystemUiAdjustment=false;
    KeyboardVisibility.onChange.listen((bool visible) {
        if (visible == false) FocusScope.of(context).unfocus();
      }
    );
    WidgetsBinding.instance.addObserver(
      new LifecycleEventHandler(resumeCallBack: () async {
        String intent = await NativeMethod.handleIntent();
        if (intent == null) return;
        if (VideoId.parseVideoId(intent) != null) {
          String id = VideoId.parseVideoId(intent);
          showDialog(
            context: context,
            builder: (_) => LoadingDialog()
          );
          YoutubeExplode yt = YoutubeExplode();
          Video video = await yt.videos.get(id);
          Provider.of<ManagerProvider>(context, listen: false)
            .updateMediaInfoSet(video);
          Navigator.pop(context);
          Navigator.push(context,
            BlurPageRoute(
              slideOffset: Offset(0.0, 10.0),
              builder: (_) => YoutubePlayerVideoPage(
                url: video.id.value,
                thumbnailUrl: video.thumbnails.highResUrl,
              )
          ));
        }
        if (PlaylistId.parsePlaylistId(intent) != null) {
          String id = PlaylistId.parsePlaylistId(intent);
          showDialog(
            context: context,
            builder: (_) => LoadingDialog()
          );
          YoutubeExplode yt = YoutubeExplode();
          Playlist playlist = await yt.playlists.get(id);
          Provider.of<ManagerProvider>(context, listen: false)
            .updateMediaInfoSet(playlist);
          Navigator.pop(context);
          Navigator.push(context,
            BlurPageRoute(
              slideOffset: Offset(0.0, 10.0),
              builder: (_) => YoutubePlayerPlaylistPage()
          ));
        }
        return;
      })
    );
    Provider.of<MediaProvider>(context, listen: false).loadSongList();
    Provider.of<MediaProvider>(context, listen: false).loadVideoList();
    // Disclaimer
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show Disclaimer
      if (!Provider.of<ConfigurationProvider>(context, listen: false).disclaimerAccepted) {
        await showDialog(
          context: context,
          builder: (context) => DisclaimerDialog()
        );
      }
      if (Provider.of<ConfigurationProvider>(context, listen: false).showDownloadFixDialog) {
        AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;
        int sdkNumber = deviceInfo.version.sdkInt;
        if (sdkNumber >= 30) {
          await showDialog(
            context: context,
            builder: (context) => DownloadFixDialog()
          );
        }
        Provider.of<ConfigurationProvider>(context, listen: false)
          .showDownloadFixDialog = false;
      }
      // Check for Updates
      PackageInfo.fromPlatform().then((android) {
        double appVersion = double
          .parse(android.version.replaceRange(3, 5, ""));
        getLatestRelease().then((details) {
          if (appVersion < details.version) {
            // Show the user an Update is available
            showDialog(
              context: context,
              builder: (context) => AppUpdateDialog(details)
            );
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //ManagerProvider manager = Provider.of<ManagerProvider>(context);
    MediaProvider mediaProvider = Provider.of<MediaProvider>(context);
    Brightness _systemBrightness = Theme.of(context).brightness;
    Brightness _statusBarBrightness = _systemBrightness == Brightness.light
      ? Brightness.dark
      : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: _statusBarBrightness,
        statusBarIconBrightness: _statusBarBrightness,
        systemNavigationBarColor: Theme.of(context).cardColor,
        systemNavigationBarIconBrightness: _statusBarBrightness,
      ),
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        body: Container(
          color: Theme.of(context).cardColor,
          child: SafeArea(
            child: WillPopScope(
              onWillPop: () {
                ManagerProvider manager =
                  Provider.of<ManagerProvider>(context, listen: false);
                if (mediaProvider.slidingPanelOpen) {
                  mediaProvider.slidingPanelOpen = false;
                  mediaProvider.panelController.close();
                  return Future.value(false);
                } else if (manager.showSearchBar) {
                  manager.showSearchBar = false;
                  return Future.value(false);
                } else {
                  return Future.value(true);
                }
              },
              child: Consumer<ManagerProvider>(
                builder: (context, manager, _) {
                  return Column(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 250),
                          child: _currentScreen(manager)
                        ),
                      ),
                      if (manager.screenIndex == 2)
                      MusicPlayerPadding(manager.showSearchBar)
                    ],
                  );
                }
              ),
            ),
          ),
        ),
        bottomNavigationBar: Consumer<ManagerProvider>(
          builder: (context, manager, _) {
            return AppBottomNavigationBar(
              onItemTap: (int index) => manager.screenIndex = index,
              currentIndex: manager.screenIndex
            );
          }
        ),
      ),
    );
  }

  Widget _currentScreen(manager) {
    if (manager.screenIndex == 0) {
      return HomeScreen();
    } else if (manager.screenIndex == 1) {
      return DownloadTab();
    } else if (manager.screenIndex == 2) {
      return MediaScreen();
    } else if (manager.screenIndex == 3) {
      return MoreScreen();
    } else {
      return Container();
    }
  }

  
}