// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import './Strings.sol';
import './base64.sol';
import './ITheme.sol';
import './SpellsUtils.sol';
import './ThemeBase.sol';

contract FlippedTheme is ITheme, ThemeBase {
  using Strings for uint256;
  string[] private REVERSED_UNICODE = [
    unicode"A", unicode"ᗺ", unicode"Ɔ", unicode"ᗡ", unicode"Ǝ", unicode"ꟻ", unicode"Ә", unicode"H",
    unicode"I", unicode"ᒑ", unicode"ꓘ", unicode"⅃", unicode"M", unicode"И", unicode"O", unicode"ᑫ",
    unicode"Ϙ", unicode"Я", unicode"Ƨ", unicode"T", unicode"U", unicode"V", unicode"W", unicode"X",
    unicode"Y", unicode"Z", unicode"؟"
  ];
  uint256 constant private LETTER_MASK      = 0x0000000000000000FF0000000000000000000000000000000000000000000000;

  function canUseTheme(uint256, TokenDetails calldata, TokenDetails calldata) external pure override returns (bool) {
    return true;
  }

  function characterSet() external view override returns (string[] memory) {
    return UNICODE_BLOCKS;
  }

  function extendedAttributes(
    uint256 _tokenId,
    TokenDetails calldata,
    AuxiliaryDetails calldata _auxDetails
  ) public view override returns (string memory) {
    uint256 colors = SpellsUtils.getColorway(_tokenId, _auxDetails.length);
    return string(
      abi.encodePacked(
        '{'
          '"trait_type": "Colorway",'
          '"value": "', _renderColorDescription(colors), '"'
        '},'
        '{'
          '"display_type": "number",'
          '"trait_type": "Number of Colors",'
          '"value": ', SpellsUtils.popCount(colors).toString(), ','
          '"max_value": 8'
        '},'
        '{'
          '"value": "', unicode"ƧƎY", '",'
          '"trait_type": "Flipped?"'
        '},'
      )
    );
  }

  function extendedProperties(
    uint256,
    TokenDetails calldata _tokenDetails,
    AuxiliaryDetails calldata _auxDetails
  ) public view override returns (string memory) {
    return string(
      abi.encodePacked(
        '"description":"**', SpellsUtils.renderText(_reverseWord(_tokenDetails.word, _auxDetails.length), REVERSED_UNICODE),
        '**\\n\\n```\\n',
        _renderUnicode(_auxDetails.shape, _auxDetails.letterBlocks, _auxDetails.length), '\\n```",',
        '"image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(_renderSvg(_auxDetails.shape, _auxDetails.letterBlocks, _auxDetails.length))), '",'
    ));
  }

  function renderSvg(
    uint256,
    TokenDetails calldata,
    AuxiliaryDetails calldata _auxDetails
  ) external view override returns (string memory svg_){
    return _renderSvg(_auxDetails.shape, _auxDetails.letterBlocks, _auxDetails.length);
  }

  function _renderSvg(uint256 _shape, uint256 _letterBlocks, uint256 _length) internal override view returns (string memory svg_) {
    bytes memory letters;

    uint256 j;
    uint256 x;
    uint256 y;
    uint256 width;

    for (uint256 i;i<64;i++) {
      if (_shape & (1 << (63 - i)) != 0) {
        if (x > width) {
          width = x;
        }
        letters = abi.encodePacked(letters, _renderLetterBlock(x, y, _getLetterBlock(_letterBlocks, j)));
        if (j == _length - 1) {
          break;
        }
        j++;
      }
      x++;
      if (x == 8) {
        x = 0;
        y++;
      }
    }

    uint256 pxWidth = ((width + 1) * 60);
    return string(
      abi.encodePacked(
        '<svg '
          'xmlns="http://www.w3.org/2000/svg" '
          'viewBox="0 0 ', pxWidth.toString(), ' ', ((y + 1) * 60).toString(),'"'
        '>',
        '<g transform="scale(-1 1) translate(-', pxWidth.toString(), ' 0)">',
          letters,
        '</g>'
        '</svg>'
      )
    );
  }

  function _renderUnicode(uint256 _shape, uint256 _letterBlocks, uint256) internal override view returns (string memory unicode_) {
    bytes memory letters;
    bytes memory line;
    uint256 j;

    for (uint256 i;i<64;i++) {
      if (_shape & (1 << (63 - i)) != 0) {
        line = abi.encodePacked(
          _getUnicodeBlock(
            uint8(
              _getLetterBlock(_letterBlocks, uint8(j))
            ) >> 3
          ),
          line
        );
        j++;
      } else {
        line = abi.encodePacked(whitespace_character, line);
      }
      
      if (i != 0 && i % 8 == 7) {
        letters = abi.encodePacked(letters, line, linebreak_character);
        line = '';
      }
    }

    return string(letters);
  }

  function _reverseWord(uint256 _word, uint256 _length) internal pure returns (uint256) {
    uint256[24] memory copy = [uint256(0xFF), 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
    for (uint256 i; i < _length; i++) copy[_length - 1 - i] = (_word & (LETTER_MASK >> i * 8)) >> (23 - i) * 8;
    uint256 union;
    for (uint256 i; i < 24; i++) union |= copy[i] << (23 - i) * 8;
    return union;
  }
}