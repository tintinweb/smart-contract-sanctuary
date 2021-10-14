//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library QuiltGenerator {
  struct QuiltStruct {
    uint256 quiltX;
    uint256 quiltY;
    uint256 quiltW;
    uint256 quiltH;
    uint256 xOff;
    uint256 yOff;
    uint256 themeIndex;
    uint256 backgroundIndex;
    uint256 patchXCount;
    uint256 patchYCount;
    bool hovers;
  }

  function getQuiltForSeed(string memory seed)
    external
    pure
    returns (QuiltStruct memory)
  {
    QuiltStruct memory quilt;

    uint256 xRand = random(seed, "X") % 100;
    uint256 yRand = random(seed, "Y") % 100;
    quilt.patchXCount = 3;
    quilt.patchYCount = 3;

    if (xRand < 5) {
      quilt.patchXCount = 2;
    } else if (xRand > 60) {
      quilt.patchXCount = 4;
    } else if (xRand > 80) {
      quilt.patchXCount = 5;
    }

    if (yRand < 5) {
      quilt.patchYCount = 2;
    } else if (yRand > 60) {
      quilt.patchYCount = 4;
    } else if (yRand > 80) {
      quilt.patchYCount = 5;
    }

    uint256 maxX = 64 * quilt.patchXCount + (quilt.patchXCount - 1) * 6;
    uint256 maxY = 64 * quilt.patchYCount + (quilt.patchYCount - 1) * 6;
    quilt.xOff = (500 - maxX) / 2;
    quilt.yOff = (500 - maxY) / 2;
    quilt.quiltW = maxX + 32;
    quilt.quiltH = maxY + 32;
    quilt.quiltX = quilt.xOff + 0 - 16;
    quilt.quiltY = quilt.yOff + 0 - 16;
    quilt.themeIndex = random(seed, "T") % 8;
    quilt.hovers = random(seed, "H") % 100 > 90;

    quilt.backgroundIndex = 0;
    uint256 bgRand = random(seed, "BG") % 100;
    if (bgRand > 70) {
      quilt.backgroundIndex = 1;
    } else if (bgRand > 90) {
      quilt.backgroundIndex = 2;
    }

    return quilt;
  }

  function getPatches(
    string[] storage patches,
    QuiltStruct memory quilt,
    string memory seed
  ) internal view returns (string[3] memory) {
    string[3] memory parts;
    for (uint256 col = 0; col < quilt.patchXCount; col++) {
      for (uint256 row = 0; row < quilt.patchYCount; row++) {
        uint256 x = quilt.xOff + 70 * col;
        uint256 y = quilt.yOff + 70 * row;
        uint256 patchIndex = random(seed, string(abi.encodePacked(col, row))) %
          14;
        parts[0] = string(
          abi.encodePacked(
            parts[0],
            '<mask id="s',
            Strings.toString(col + 1),
            Strings.toString(row + 1),
            '"><rect rx="8" x="',
            Strings.toString(x),
            '" y="',
            Strings.toString(y),
            '" width="64" height="64" fill="white"/></mask>'
          )
        );
        parts[1] = string(
          abi.encodePacked(
            parts[1],
            '<g mask="url(#s',
            Strings.toString(col + 1),
            Strings.toString(row + 1),
            ')"><g transform="translate(',
            Strings.toString(x),
            " ",
            Strings.toString(y),
            ')">',
            patches[patchIndex],
            "</g></g>"
          )
        );
        parts[2] = string(
          abi.encodePacked(
            parts[2],
            '<rect rx="8" stroke-width="2" stroke-linecap="round" stroke="url(#c1)" stroke-dasharray="4 4" x="',
            Strings.toString(x),
            '" y="',
            Strings.toString(y),
            '" width="64" height="64" fill="transparent"/>'
          )
        );
      }
    }

    return parts;
  }

  function getQuiltSVG(
    string memory seed,
    QuiltStruct memory quilt,
    string[] storage colors,
    string[] storage backgrounds,
    string[] storage patches
  ) external view returns (string memory) {
    string[3] memory patchParts = getPatches(patches, quilt, seed);
    string memory quiltBG = string(
      abi.encodePacked(
        '<rect x="',
        Strings.toString(quilt.quiltX),
        '" y="',
        Strings.toString(quilt.quiltY),
        '" width="',
        Strings.toString(quilt.quiltW),
        '" height="',
        Strings.toString(quilt.quiltH),
        '" rx="17" fill="url(#c2)" stroke="url(#c1)" stroke-width="2"/>'
      )
    );

    string memory quiltShadow = string(
      abi.encodePacked(
        '<rect transform="translate(',
        Strings.toString(quilt.quiltX + 8),
        " ",
        Strings.toString(quilt.quiltY + 8),
        ')" x="0" y="0" width="',
        Strings.toString(quilt.quiltW),
        '" height="',
        Strings.toString(quilt.quiltH),
        '" rx="16" fill="url(#c1)" />'
      )
    );

    string memory theme = string(
      abi.encodePacked(
        '<linearGradient id="c1"><stop stop-color="',
        colors[quilt.themeIndex * 4],
        '"/></linearGradient><linearGradient id="c2"><stop stop-color="',
        colors[(quilt.themeIndex * 4) + 1],
        '"/></linearGradient><linearGradient id="c3"><stop stop-color="',
        colors[(quilt.themeIndex * 4) + 2],
        '"/></linearGradient><linearGradient id="c4"><stop stop-color="',
        colors[(quilt.themeIndex * 4) + 3],
        '"/></linearGradient>'
      )
    );

    string memory background = string(
      abi.encodePacked(
        backgrounds[quilt.backgroundIndex * 2],
        seed,
        backgrounds[(quilt.backgroundIndex * 2) + 1]
      )
    );

    string memory output = string(
      abi.encodePacked(
        '<svg width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg"><defs>',
        patchParts[0],
        theme,
        '</defs><rect width="500" height="500" fill="url(#c3)" />',
        background,
        '<filter id="f" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence baseFrequency="0.003" seed="',
        seed,
        '"/><feDisplacementMap in="SourceGraphic" scale="10"/></filter><g><g filter="url(#f)">',
        quiltShadow
      )
    );

    output = string(
      abi.encodePacked(
        output,
        quilt.hovers
          ? '<animateTransform attributeName="transform" type="scale" additive="sum" dur="4s" values="1 1; 1.005 1.02; 1 1;" calcMode="spline" keySplines="0.45, 0, 0.55, 1; 0.45, 0, 0.55, 1;" repeatCount="indefinite"/>'
          : "",
        '</g><g filter="url(#f)">',
        quiltBG,
        patchParts[2],
        patchParts[1],
        quilt.hovers
          ? '<animateTransform attributeName="transform" type="translate" dur="4s" values="0,0; -4,-16; 0,0;" calcMode="spline" keySplines="0.45, 0, 0.55, 1; 0.45, 0, 0.55, 1;" repeatCount="indefinite"/>'
          : "",
        "</g></g></svg>"
      )
    );

    return output;
  }

  function random(string memory seed, string memory key)
    internal
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(key, seed)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}