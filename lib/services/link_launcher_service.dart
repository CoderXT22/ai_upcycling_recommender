import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkLauncherService {
  const LinkLauncherService();

  Future<bool> openUrl(BuildContext context, String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      _showMessage(context, 'No related link available.');
      return false;
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasScheme) {
      _showMessage(context, 'This link is not valid.');
      return false;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showMessage(context, 'Unable to open this link.');
    }
    return opened;
  }

  Future<bool> openMapNavigation({
    required BuildContext context,
    required String name,
    required String address,
    double? latitude,
    double? longitude,
  }) {
    final destination = _mapDestination(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination';
    return openUrl(context, url);
  }

  String _mapDestination({
    required String name,
    required String address,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return Uri.encodeComponent('$latitude,$longitude');
    }

    return Uri.encodeComponent('$name $address');
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
