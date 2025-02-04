// link detail screen to view the web links inside app

import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart'; // Assuming this has the AppTheme class
import 'package:webview_flutter/webview_flutter.dart';

class LinkDetailScreen extends StatefulWidget {
  final String url;
  final String title;

  const LinkDetailScreen({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  _LinkDetailScreenState createState() => _LinkDetailScreenState();
}

class _LinkDetailScreenState extends State<LinkDetailScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true; // Track the loading state of the page

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading) // Show the progress bar if the page is loading
              LinearProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            Expanded(
              child: WebViewWidget(controller: _webViewController),
            ),
          ],
        ),
      ),
    );
  }
}
