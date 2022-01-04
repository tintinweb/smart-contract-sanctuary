// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import './Strings.sol';
import './base64.sol';
import './ITheme.sol';
import './SpellsUtils.sol';
import './ThemeBase.sol';

contract OriginalTheme is ITheme, ThemeBase {
  using Strings for uint256;

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
        '"description":"**', SpellsUtils.renderText(_tokenDetails.word, PLAIN_TEXT), '**\\n\\n```\\n',
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
}