import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drinkopedia/core/common_ui/image_assets/asset.dart';
import 'package:drinkopedia/core/theme/color_style/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class AssetWidget extends StatelessWidget {
  final Asset asset;
  final double? width;
  final File? file;
  final double? height;
  final Color? color;
  final BoxFit? boxFit;
  final String? firstName;
  final String? lastName;
  final bool? isCircular;

  const AssetWidget(
      {Key? key,
      required this.asset,
      this.width,
      this.file,
      this.firstName,
      this.isCircular = false,
      this.lastName,
      this.height,
      this.color,
      this.boxFit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (asset.type) {
      case AssetType.bytes:
        return Image.memory(
          base64Decode(asset.path),
          width: width,
          height: height,
          fit: boxFit ?? BoxFit.contain,
        );

      case AssetType.png:
        return Image(
            image: AssetImage(asset.path),
            width: width,
            height: height,
            color: color);
      case AssetType.svg:
        return SvgPicture.asset(
          asset.path,
          width: width,
          height: height,
          color: color,
          fit: boxFit ?? BoxFit.contain,
        );
      case AssetType.file:
        return Image.file(
          asset.file!,
          width: width,
          height: height,
          color: color,
          fit: boxFit ?? BoxFit.contain,
        );
      case AssetType.file:
        return Image.file(
          asset.file!,
          width: width,
          height: height,
          color: color,
          fit: boxFit ?? BoxFit.contain,
        );
      case AssetType.network:
        return CachedNetworkImage(
          imageUrl: asset.path,
          placeholder: (context, url) => SizedBox(
              height: height ?? 100 - 40.0,
              width: width ?? 100 - 40.0,
              child: Center(child: CircularProgressIndicator())),
          errorWidget: (context, url, error) {
            return isCircular!
                ? AvtarNameIcon(
                    firstName: firstName ?? "",
                    lastName: lastName ?? "",
                    height: height,
                    width: width,
                    textColor: lightColorPalette.secondarySwatch.shade400,
                    backgroundColor: lightColorPalette.secondarySwatch.shade100,
                    isCircular: isCircular)
                : Container();
          },
          height: height,
          width: width,
          fit: boxFit,
        );
    }
  }
}

class AvtarNameIcon extends StatelessWidget {
  final String firstName;
  final String lastName;
  final Color backgroundColor;
  final Color textColor;
  final double? height;
  final double? width;
  final bool? isCircular;

  const AvtarNameIcon({
    Key? key,
    required this.firstName,
    required this.lastName,
    this.backgroundColor = Colors.white,
    this.height = 30,
    this.width = 30,
    this.isCircular,
    required this.textColor,
  }) : super(key: key);

  String get firstLetter =>
      this.firstName != "" ? this.firstName.substring(0, 1).toUpperCase() : "G";

  String get lastLetter =>
      this.lastName != "" ? this.lastName.substring(0, 1).toUpperCase() : "C";

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: height,
      width: width,
      decoration: BoxDecoration(
        shape: isCircular! ? BoxShape.circle : BoxShape.rectangle,
        color: this.backgroundColor,
        border: Border.all(
            color: !isCircular! ? backgroundColor : textColor,
            width: isCircular! ? 0 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            this.firstLetter,
            style: Theme.of(context).textTheme.headline1?.copyWith(
                fontSize: !isCircular! || height! < 62 ? 24 : 34,
                fontWeight: FontWeight.w500,
                color: textColor),
          ),
          Text(
            this.lastLetter,
            style: Theme.of(context).textTheme.headline1?.copyWith(
                fontSize: !isCircular! || height! < 62 ? 24 : 34,
                fontWeight: FontWeight.w500,
                color: textColor),
          )
        ],
      ),
    );
  }
}
