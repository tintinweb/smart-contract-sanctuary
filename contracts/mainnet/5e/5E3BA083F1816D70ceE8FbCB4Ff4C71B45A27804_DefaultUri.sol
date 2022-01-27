// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import './Strings.sol';
import './base64.sol';

contract DefaultUri {
  using Strings for uint256;

  function uri(uint256 _tokenId) external pure returns (string memory) {
    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(abi.encodePacked(
        '{'
          '"name":"\\"UA\\" #', _tokenId.toString(), '",'
          '"image": "https://www.unauthedauth.com/default.png",'
          '"external_url": "https://www.unauthedauth.com/', _tokenId.toString(), '"'
        '}'
      ))
    ));
  }
}