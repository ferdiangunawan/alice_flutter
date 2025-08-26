import 'package:alice_lightweight/core/alice_core.dart';
import 'package:alice_lightweight/helper/alice_save_helper.dart';
import 'package:alice_lightweight/model/alice_http_call.dart';
import 'package:alice_lightweight/ui/widget/alice_call_error_widget.dart';
import 'package:alice_lightweight/ui/widget/alice_call_overview_widget.dart';
import 'package:alice_lightweight/ui/widget/alice_call_request_widget.dart';
import 'package:alice_lightweight/ui/widget/alice_call_response_widget.dart';
import 'package:alice_lightweight/utils/alice_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AliceCallDetailsScreen extends StatefulWidget {
  final AliceHttpCall call;
  final AliceCore core;

  AliceCallDetailsScreen(this.call, this.core);

  @override
  _AliceCallDetailsScreenState createState() => _AliceCallDetailsScreenState();
}

class _AliceCallDetailsScreenState extends State<AliceCallDetailsScreen>
    with SingleTickerProviderStateMixin {
  AliceHttpCall get call => widget.call;

  bool isFloatingActionShown = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget.core.brightness,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AliceConstants.lightRed,
          surface: Colors.white,
        ),
      ),
      child: StreamBuilder<List<AliceHttpCall>>(
        stream: widget.core.callsSubject,
        initialData: [widget.call],
        builder: (context, callsSnapshot) {
          if (callsSnapshot.hasData) {
            AliceHttpCall? call = callsSnapshot.data?.firstWhere(
                (snapshotCall) => snapshotCall.id == widget.call.id,
                orElse: null);
            if (call != null) {
              return _buildMainWidget();
            } else {
              return _buildErrorWidget();
            }
          } else {
            return _buildErrorWidget();
          }
        },
      ),
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isFloatingActionShown) ...[
              FloatingActionButton(
                heroTag: 'copy_curl',
                backgroundColor: AliceConstants.red,
                onPressed: _copyCurl,
                child: _FloatingContent(
                  title: 'cURL',
                ),
              ),
              SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'copy_payload',
                backgroundColor: AliceConstants.blue,
                onPressed: _copyPayloadOnly,
                child: _FloatingContent(
                  title: 'Payload',
                ),
              ),
              SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'copy_response',
                backgroundColor: AliceConstants.green,
                onPressed: _copyResponseOnly,
                child: _FloatingContent(
                  title: 'Response',
                ),
              ),
              SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'copy_all',
                backgroundColor: AliceConstants.orange,
                onPressed: _copyAllAliceLogMap,
                child: _FloatingContent(
                  title: 'All',
                ),
              ),
              SizedBox(height: 12),
            ],

            // Info: Disable share button
            // FloatingActionButton(
            //   heroTag: 'share_key',
            //   backgroundColor: AliceConstants.lightRed,
            //   onPressed: () async {
            //     Share.share(await _getSharableResponseString(),
            //         subject: 'Request Details');
            //   },
            //   child: Icon(Icons.share),
            // ),

            // Visibility Toggle
            FloatingActionButton(
              heroTag: 'toggle_visibility',
              backgroundColor: isFloatingActionShown
                  ? AliceConstants.lightRed
                  : AliceConstants.grey,
              onPressed: () {
                setState(() {
                  isFloatingActionShown = !isFloatingActionShown;
                });
              },
              child: Icon(
                isFloatingActionShown ? Icons.visibility_off : Icons.visibility,
                color: isFloatingActionShown ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        appBar: AppBar(
          bottom: TabBar(
            indicatorColor: AliceConstants.lightRed,
            tabs: _getTabBars(),
          ),
          title: Text('Alice - HTTP Call Details'),
        ),
        body: TabBarView(
          children: _getTabBarViewList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(child: Text("Failed to load data"));
  }

  // Info: Disable share button
  // Future<String> _getSharableResponseString() async {
  //   return AliceSaveHelper.buildCallLog(widget.call);
  // }

  Future<void> _copyAllAliceLogMap() async {
    late final SnackBar snackBar;

    try {
      final response = await AliceSaveHelper.buildLogMap(widget.call);

      print(response);

      await Clipboard.setData(ClipboardData(text: response));
      snackBar = SnackBar(
        content: Text('Successfully copied to clipboard'),
        backgroundColor: Colors.green,
      );
    } catch (exception) {
      snackBar = SnackBar(
        content: Text('Failed to copy to clipboard'),
        backgroundColor: Colors.red,
      );
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _copyCurl() async {
    late final SnackBar snackBar;

    try {
      final curlCommand = call.getCurlCommand();

      if (curlCommand.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: curlCommand));
        snackBar = SnackBar(
          content: Text('cURL command copied to clipboard'),
          backgroundColor: Colors.green,
        );
      } else {
        snackBar = SnackBar(
          content: Text('No cURL command available'),
          backgroundColor: Colors.orange,
        );
      }
    } catch (exception) {
      snackBar = SnackBar(
        content: Text('Failed to copy cURL command'),
        backgroundColor: Colors.red,
      );
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _copyResponseOnly() async {
    final responseBody = await AliceSaveHelper.getResponseBody(call);
    late final SnackBar snackBar;
    if (responseBody != null) {
      await Clipboard.setData(ClipboardData(text: responseBody));

      snackBar = SnackBar(
        content: Text('Response copied to clipboard'),
        backgroundColor: Colors.green,
      );
    } else {
      snackBar = SnackBar(
        content: Text('Failed to copy response'),
        backgroundColor: Colors.red,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _copyPayloadOnly() async {
    final payload = await AliceSaveHelper.getPayload(call);
    late final SnackBar snackBar;
    if (payload != null) {
      await Clipboard.setData(ClipboardData(text: payload));

      snackBar = SnackBar(
        content: Text('Response copied to clipboard'),
        backgroundColor: Colors.green,
      );
    } else {
      snackBar = SnackBar(
        content: Text('Failed to copy response'),
        backgroundColor: Colors.red,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  List<Widget> _getTabBars() {
    List<Widget> widgets = [];
    widgets.add(Tab(icon: Icon(Icons.info_outline), text: "Overview"));
    widgets.add(Tab(icon: Icon(Icons.arrow_upward), text: "Request"));
    widgets.add(Tab(icon: Icon(Icons.arrow_downward), text: "Response"));
    widgets.add(
      Tab(
        icon: Icon(Icons.warning),
        text: "Error",
      ),
    );
    return widgets;
  }

  List<Widget> _getTabBarViewList() {
    List<Widget> widgets = [];
    widgets.add(AliceCallOverviewWidget(widget.call));
    widgets.add(AliceCallRequestWidget(widget.call));
    widgets.add(AliceCallResponseWidget(widget.call));
    widgets.add(AliceCallErrorWidget(widget.call));
    return widgets;
  }
}

class _FloatingContent extends StatelessWidget {
  const _FloatingContent({this.title});
  final title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.copy, size: 14),
        SizedBox(height: 1),
        Text(
          title,
          style: TextStyle(fontSize: 8),
        ),
      ],
    );
  }
}
