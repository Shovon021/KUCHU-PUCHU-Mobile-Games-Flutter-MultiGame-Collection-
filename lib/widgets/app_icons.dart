import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized app icons class for consistent SVG icon usage
class AppIcons {
  static Widget svg(String name, {double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color, BlendMode.srcIn) 
        : null,
    );
  }

  // Common navigation icons
  static Widget back({double size = 24, Color color = const Color(0xFF2D3436)}) => 
    svg('arrow-back', size: size, color: color);
  
  static Widget refresh({double size = 24, Color color = const Color(0xFF2D3436)}) => 
    svg('refresh', size: size, color: color);
  
  static Widget help({double size = 24, Color color = Colors.grey}) => 
    svg('help', size: size, color: color);

  // Game result icons
  static Widget trophy({double size = 60, Color color = Colors.amber}) => 
    svg('trophy', size: size, color: color);
  
  static Widget handshake({double size = 60, Color color = Colors.grey}) => 
    svg('handshake', size: size, color: color);

  // Player mode icons
  static Widget people({double size = 30, Color? color}) => 
    svg('people', size: size, color: color);
  
  static Widget groups({double size = 40, Color? color}) => 
    svg('groups', size: size, color: color);
  
  static Widget robot({double size = 30, Color? color}) => 
    svg('robot', size: size, color: color);

  // Game icons
  static Widget tag({double size = 60, Color color = Colors.white}) => 
    svg('tag', size: size, color: color);
  
  static Widget flash({double size = 60, Color color = Colors.white}) => 
    svg('flash', size: size, color: color);
    
  static Widget brain({double size = 60, Color color = Colors.white}) => 
    svg('brain', size: size, color: color);
}
