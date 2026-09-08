import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drinkopedia/shared/widgets/image/asset.dart';
import 'package:drinkopedia/app/theme/app_color_palette.dart';
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

  const AssetWidget({
    super.key,
    required this.asset,
    this.width,
    this.file,
    this.firstName,
    this.isCircular = false,
    this.lastName,
    this.height,
    this.color,
    this.boxFit,
  });

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
          color: color,
        );
      case AssetType.svg:
        return SvgPicture.asset(
          asset.path,
          width: width,
          height: height,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color!, BlendMode.srcIn),
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
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) {
            return isCircular!
                ? AvtarNameIcon(
                    firstName: firstName ?? "",
                    lastName: lastName ?? "",
                    height: height,
                    width: width,
                    textColor: lightColorPalette.secondarySwatch.shade400,
                    backgroundColor: lightColorPalette.secondarySwatch.shade100,
                    isCircular: isCircular,
                  )
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
    super.key,
    required this.firstName,
    required this.lastName,
    this.backgroundColor = Colors.white,
    this.height = 30,
    this.width = 30,
    this.isCircular,
    required this.textColor,
  });

  String get firstLetter =>
      firstName != "" ? firstName.substring(0, 1).toUpperCase() : "G";

  String get lastLetter =>
      lastName != "" ? lastName.substring(0, 1).toUpperCase() : "C";

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: height,
      width: width,
      decoration: BoxDecoration(
        shape: isCircular! ? BoxShape.circle : BoxShape.rectangle,
        color: backgroundColor,
        border: Border.all(
          color: !isCircular! ? backgroundColor : textColor,
          width: isCircular! ? 0 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            firstLetter,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: !isCircular! || height! < 62 ? 24 : 34,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          Text(
            lastLetter,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: !isCircular! || height! < 62 ? 24 : 34,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
