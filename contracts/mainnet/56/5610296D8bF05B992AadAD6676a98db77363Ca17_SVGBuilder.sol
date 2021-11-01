// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import './ToColor.sol';

struct colorSet {
  bytes3 color1;
  bytes3 color2;
  bytes3 color3;
  bytes3 color4;
  bytes3 color5;
}

struct FileListing {
  string textElements;
  string[10] boringSoftwares;
  string[10] specialSoftwares;
}

library SVGBuilder {
  using ToColor for bytes3;

  function generateSVGofToken(colorSet memory tokenColors, FileListing memory files, uint8 wackyPattern) public pure returns (string memory) {
    string memory diskFill = tokenColors.color1.toColor();
    string memory svg = string(abi.encodePacked(
      "<svg viewBox='0 0 322.2 332.55' xmlns='http://www.w3.org/2000/svg'><style>.t { white-space: pre; fill: rgb(51, 51, 51); font: 11px monospace; }</style><defs><linearGradient id='a' x1='80.802' x2='254.2' y1='-28.879' y2='-28.879' gradientTransform='matrix(-.99682 0 0 -2.5057 319.72 205.97)' gradientUnits='userSpaceOnUse'><stop stop-color='#878787' offset='0'/><stop stop-color='#fff' offset='.5'/><stop stop-color='#878787' offset='1'/></linearGradient>"
    ));

    if (wackyPattern > 0) {
      diskFill = "url(#b)";
      if (wackyPattern == 1) {
        svg = string(abi.encodePacked(
          svg,
          string(abi.encodePacked(
            "<pattern id='b' patternUnits='userSpaceOnUse' width='20' height='20' patternTransform='scale(2) rotate(0)'><rect x='0' y='0' width='100%' height='100%' fill='",
            tokenColors.color1.toColor(),
            "'/><path d='M3.25 10h13.5M10 3.25v13.5'  stroke-linecap='square' stroke-width='1' stroke='",
            tokenColors.color3.toColor(),
            "' fill='none'/></pattern>"
          ))
        ));
      }

      if (wackyPattern == 3) {
        svg = string(abi.encodePacked(
          svg,
          string(abi.encodePacked(
            "<pattern id='b' patternUnits='userSpaceOnUse' width='40' height='40' patternTransform='scale(2) rotate(0)'><rect x='0' y='0' width='100%' height='100%' fill='",
            tokenColors.color1.toColor(),
            "'/><path d='M40 45a5 5 0 110-10 5 5 0 010 10zM0 45a5 5 0 110-10 5 5 0 010 10zM0 5A5 5 0 110-5 5 5 0 010 5zm40 0a5 5 0 110-10 5 5 0 010 10z'  stroke-width='2' stroke='",
            tokenColors.color4.toColor(),
            "' fill='none'/><path d='M20 25a5 5 0 110-10 5 5 0 010 10z'  stroke-width='2' stroke='",
            tokenColors.color5.toColor(),
            "' fill='none'/></pattern>"
          ))
        ));
      }

      if (wackyPattern == 2) {
        svg = string(abi.encodePacked(
          svg,
          string(abi.encodePacked(
            "<linearGradient id='b' x1='80.802' x2='254.2' y1='-28.879' y2='-28.879' gradientTransform='matrix(-1.667037, 1.746009, -1.812309, -1.730337, 383.987524, -171.581138)' gradientUnits='userSpaceOnUse'><stop stop-color='",
            tokenColors.color1.toColor(),
            "' offset='0'/><stop stop-color='",
            tokenColors.color4.toColor(),
            "' offset='.223'/><stop stop-color='",
            tokenColors.color5.toColor(),
            "' offset='.451'/><stop stop-color='",
            tokenColors.color2.toColor(),
            "' offset='.771'/><stop stop-color='",
            tokenColors.color3.toColor(),
            "' offset='1'/></linearGradient>"
          ))
        ));
      }
    }

    svg = string(abi.encodePacked(
      svg,
      "</defs><ellipse cx='160.95' cy='164.38' rx='158.43' ry='161.93' fill='#797474'/><ellipse cx='162.67' cy='163.34' rx='58.216' ry='59.966' fill='#897b7b' stroke='#070707' stroke-width='11.339'/><path d='m311.54 292.2h-4.2v-13.65h-8.7v13.65h-4.2l8.55 24.75z' stroke='#808080' stroke-linecap='round' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='.9'/><path d='m311.39 23.4h-18.15v11.85h18.15z' stroke='#808080' stroke-linecap='round' stroke-miterlimit='8' stroke-width='.9'/><path d='m319.19 331.64 1.9375-1.7812 0.625-2.2501-0.3125-324.15-0.75-1.66-1.6562-1.06-315.43-0.28-2.1 1.18-1.06 1.97 0.44 289.19h2.25v13.188l-1.78-0.438v4.5l24.28 21.312 4.81 0.28175 1.5-1.3438h25.81l2.25-2.25 5.25-0.1562h173.38l-2e-3 1.5 42.624 0.3124-0.156 1.6563 38.094 0.28125zm-288.91-296.25h-18.15v-11.84h18.15z' fill='",
      diskFill
    ));

    svg = string(abi.encodePacked(
      svg,
      "' fill-rule='evenodd' opacity='.75' stroke='#020000'/><g transform='rotate(180 295.08 220.36)'><path d='m550.9 440.27-0.01874-184.65-1.8-2.1-240 0.3-2.1 1.5v184.95z' fill='#eaeaea' fill-rule='evenodd' stroke='#9b9b9b' stroke-width='.8'/><path d='m307.58 285.32h242.7' fill='none' stroke='",
      tokenColors.color2.toColor(),
      "' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='1.2'/><path d='m307.58 308.42h242.7' fill='none' stroke='",
      tokenColors.color2.toColor(),
      "' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='1.2'/><path d='m307.58 331.67h242.7' fill='none' stroke='",
      tokenColors.color2.toColor(),
        "' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='1.2'/><path id='b' d='m307.58 355.07h242.7' fill='none' stroke='",
      tokenColors.color2.toColor()
    ));
    svg = string(abi.encodePacked(
      svg,
      "' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='1.2'/><path d='m307.58 378.32h242.7' fill='none' stroke='",
      tokenColors.color2.toColor(),
      "' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='1.2'/><path d='m307.58 401.57h242.7' fill='none' stroke='",
      tokenColors.color2.toColor(),
      "' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='1.2'/><path d='m307.36 439.87h243.14v-15h-243.14z' fill='",
      tokenColors.color2.toColor(),
      "' stroke-width='1.0009'/></g><path d='m280.79 330.3v-106.35l-0.75-1.35-1.05-0.45h-46.5' fill='none' stroke='#808080' stroke-linecap='round' stroke-linejoin='round' stroke-miterlimit='10' stroke-width='.6'/><path d='m238.53 332.02v-107.97l-3.125-2.4062h-165.97l-2.75 3.0312v107.34h171.84zm-99.031-17.781h-46.375v-87h46.375z' color='#000000' fill='url(#a)' stroke-width='.3'/>"
    ));
    svg = string(abi.encodePacked(
      svg,
      files.textElements,
      "</svg>"
    ));
    return svg;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library ToColor {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) internal pure returns (string memory) {
      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(abi.encodePacked("#", string(buffer)));
    }
}