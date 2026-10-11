import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ui/localized.dart';
import 'common.dart';

class ImageCropPage extends StatefulWidget {
  final Uint8List bytes;
  const ImageCropPage({super.key, required this.bytes});
  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  ui.Image? image;
  String? error;
  double left = 0, top = 0, right = 1, bottom = 1;
  @override
  void initState() {
    super.initState();
    decode();
  }

  Future<void> decode() async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(widget.bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > 25000000) {
        descriptor.dispose();
        buffer.dispose();
        throw Exception('Choose an image up to 25 megapixels.');
      }
      final codec = await descriptor.instantiateCodec();
      descriptor.dispose();
      buffer.dispose();
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (mounted) {
        setState(() => image = frame.image);
      } else {
        frame.image.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = 'This image could not be opened. Choose another image.',
        );
      }
    }
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  Future<void> crop() async {
    final source = image!;
    final rect = Rect.fromLTRB(
      left * source.width,
      top * source.height,
      right * source.width,
      bottom * source.height,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      rect,
      Rect.fromLTWH(0, 0, rect.width, rect.height),
      Paint(),
    );
    final picture = recorder.endRecording();
    final output = await picture.toImage(rect.width.ceil(), rect.height.ceil());
    picture.dispose();
    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    output.dispose();
    if (data == null || data.lengthInBytes > 5000000) {
      throw Exception(
        'The cropped image exceeds 5 MB. Use the original or choose a smaller image.',
      );
    }
    if (mounted) {
      Navigator.pop(
        context,
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Review and crop document')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const UiText(
            'Keep every required detail readable. Crop only empty edges; never hide or change identity or vehicle information.',
          ),
          if (error != null) Text(error!),
          if (image == null && error == null) const LinearProgressIndicator(),
          if (image != null) ...[
            SizedBox(
              height: 300,
              child: CustomPaint(
                painter: _CropPreview(
                  image!,
                  Rect.fromLTRB(left, top, right, bottom),
                ),
              ),
            ),
            for (final side in [
              'Left edge',
              'Top edge',
              'Right edge',
              'Bottom edge',
            ]) ...[
              UiText(side),
              Slider(
                value: switch (side) {
                  'Left edge' => left,
                  'Top edge' => top,
                  'Right edge' => right,
                  _ => bottom,
                },
                min: switch (side) {
                  'Right edge' => left + .1,
                  'Bottom edge' => top + .1,
                  _ => 0,
                },
                max: switch (side) {
                  'Left edge' => right - .1,
                  'Top edge' => bottom - .1,
                  _ => 1,
                },
                label: side,
                onChanged: (v) => setState(() {
                  switch (side) {
                    case 'Left edge':
                      left = v;
                    case 'Top edge':
                      top = v;
                    case 'Right edge':
                      right = v;
                    default:
                      bottom = v;
                  }
                }),
              ),
            ],
            FilledButton(
              onPressed: () => perform(context, crop),
              child: const UiText('Use cropped image'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, widget.bytes),
              child: const UiText('Use original image'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _CropPreview extends CustomPainter {
  final ui.Image image;
  final Rect crop;
  _CropPreview(this.image, this.crop);
  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final fitted = applyBoxFit(BoxFit.contain, source.size, size);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(image, source, destination, Paint());
    final selected = Rect.fromLTRB(
      destination.left + crop.left * destination.width,
      destination.top + crop.top * destination.height,
      destination.left + crop.right * destination.width,
      destination.top + crop.bottom * destination.height,
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(destination),
        Path()..addRect(selected),
      ),
      Paint()..color = Colors.black54,
    );
    canvas.drawRect(
      selected,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xff79dcc7),
    );
  }

  @override
  bool shouldRepaint(_CropPreview old) =>
      image != old.image || crop != old.crop;
}
