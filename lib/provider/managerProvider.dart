// Dart
import 'dart:async';

// Flutter
import 'package:flutter/material.dart';
import 'package:newpipeextractor_dart/extractors/playlist.dart';
import 'package:newpipeextractor_dart/extractors/search.dart';
import 'package:newpipeextractor_dart/extractors/trending.dart';
import 'package:newpipeextractor_dart/models/infoItems/video.dart';
import 'package:newpipeextractor_dart/models/search.dart';

enum HomeScreenTab { Trending, Music, Favorites, WatchLater }

class ManagerProvider extends ChangeNotifier {

  // ----------------
  // Initialize Class
  // ----------------
  //
  ManagerProvider() {
    // Variables
    searchBarFocusNode = FocusNode();
    searchController = new TextEditingController();
    // HomeScreen
    homeScrollController = ScrollController();
    // Home Screen
    currentHomeTab = HomeScreenTab.Trending;
    homeTrendingVideoList = [];
    homeMusicVideoList = [];
    searchRunning = false;
    TrendingExtractor.getTrendingVideos().then((value) {
      homeTrendingVideoList = value;
      notifyListeners();
    });
    PlaylistExtractor.getPlaylistStreams(
      'https://www.youtube.com/playlist?list=PLFgquLnL59akA2PflFpeQG9L01VFg90wS'
    ).then((value) {
      homeMusicVideoList = value;
      notifyListeners();
    });
  }

  // -------------
  // App Variables
  // -------------
  //
  // Library
  GlobalKey _internalScaffoldKey;
  GlobalKey _scaffoldStateKey;
  // Home Screen
  ScrollController homeScrollController;
  // Navitate Screen
  String youtubeSearchQuery;
  // SearchBar
  FocusNode searchBarFocusNode;

  // Current search filters
  List<String> searchFilters = [];

  // -----------
  // Home Screen
  // -----------
  bool searchRunning;
  YoutubeSearch youtubeSearch;
  Future<void> searchYoutube({String query, bool forceReload = false}) async {
    searchRunning = true;      
    notifyListeners();
    if (query == null) return null;
    if (youtubeSearch == null) {
      youtubeSearch = await SearchExtractor.searchYoutube(query, searchFilters);
      notifyListeners();
    } else if (youtubeSearch != null && forceReload) {
      youtubeSearch = null;
      notifyListeners();
      youtubeSearch = await SearchExtractor.searchYoutube(query, searchFilters);
      notifyListeners();
    } else if (youtubeSearch != null) {
      await youtubeSearch.getNextPage();
      notifyListeners();
    }
    searchRunning = false;
    notifyListeners();
  }

  HomeScreenTab _currentHomeTab;
  HomeScreenTab get currentHomeTab => _currentHomeTab;
  set currentHomeTab(HomeScreenTab tab) {
    _currentHomeTab = tab;
    notifyListeners();
  }
  // Trending Video List
  List<StreamInfoItem> homeTrendingVideoList;
  // Music Video List
  List<StreamInfoItem> homeMusicVideoList;

  // ---------------
  // SearchBar TextController
  //
  TextEditingController searchController;
  // ----------------------------------

  void setState() {
    notifyListeners();
  }

  // -------------------
  // Getters and Setters
  // -------------------
  //
  // Library
  GlobalKey get internalScaffoldKey => _internalScaffoldKey;
  set internalScaffoldKey(GlobalKey key) {
    _internalScaffoldKey = key;
    notifyListeners();
  }
  // Library
  GlobalKey get scaffoldStateKey => _scaffoldStateKey;
  set scaffoldStateKey(GlobalKey key) {
    _scaffoldStateKey = key;
    notifyListeners();
  }
  bool get showSearchBar {
    if (youtubeSearch != null) {
      return true;
    } else if (searchBarFocusNode.hasFocus) {
      return true;
    } else if (searchRunning) {
      return true;
    } else {
      return false;
    }
  }
}