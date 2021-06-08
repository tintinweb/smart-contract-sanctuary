/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// File: @openzeppelin/contracts/utils/Strings.sol

// spd-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: contracts/SVGGenerator2.sol

// spd-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.8;


contract SVGGenerator2 {

  using Strings for uint256;

  function createSVG(uint256 id, uint256 gasPrice) external pure returns (string memory) {
    gasPrice = gasPrice/(10**9);
    string memory color = getColor(gasPrice);
    string memory animationDuration = getSpeed(gasPrice);
    string memory svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><rect width="280" height="280" x="10" y="10" fill="#eee" ry="10" rx="10"/> <path d="M70 32c-13 0-24 11-24 24v102l-19 4v30h149v-30l-19-4V87h10v37h15V90l2-1 8-8c2-1 2-4 1-5l-4-4-1-1 15-14-2-2-16 15-2 1-8 8c-2 2-2 4-1 6l4 3v31h-6V82h-15V56c0-13-10-24-24-24z" fill="',
    color,
    '"/><rect width="67" height="34" x="68" y="49" ry="10" rx="10" fill="#fff"/><circle r="5" cx="205" cy="60"><animate attributeName="cy" values="60;100" dur="',
    animationDuration,
    's" repeatCount="indefinite" fill="freeze"/></circle><circle r="5" cx="205" cy="100"><animate attributeName="cy" values="100;140" dur="',
    animationDuration,
    's" repeatCount="indefinite" fill="freeze"/></circle><circle r="5" cx="205" cy="140"><animate attributeName="cy" values="140;180" dur="',
    animationDuration,
    's" repeatCount="indefinite" fill="freeze"/></circle><rect width="20" height="10" x="195" y="180" rx="5"><animate attributeName="width" values="20;30;20" dur="',
    animationDuration,
    's" repeatCount="indefinite" fill="freeze" begin="',
    animationDuration,
    's"/><animate attributeName="x" values="195;190;195" dur="',
    animationDuration,
    's" repeatCount="indefinite" fill="freeze" begin="',
    animationDuration,
    's"/></rect><text x="50" y="230" font-size="24" font-weight="bold">NFGas #',
    id.toString(),
    '</text><text x="70" y="130" font-size="34" font-weight="bold" fill="#fff">',
    gasPrice.toString(),
    '</text></svg>'));
    return svg;
  }

  function getSpeed(uint256 gasPrice) internal pure returns(string memory) {
    if (gasPrice > 400) {
      return "0.2";
    }
    if (gasPrice > 300) {
      return "0.3";
    }
    if (gasPrice > 200) {
      return "0.4";
    }
    if (gasPrice > 100) {
      return "0.8";
    }
    if (gasPrice > 50) {
      return "1";
    }
    else {
      return (51/(gasPrice+1)).toString();
    }
  }

  function getColor(uint256 gasPrice) internal pure returns(string memory) {
    if (gasPrice <= 2) {
      return "rgb(220, 20, 60)";
    }
    if (gasPrice <= 4) {
      return "rgb(230, 215, 140)";
    }
    if (gasPrice <= 8) {
      return "rgb(120, 240, 20)";
    }
    if (gasPrice <= 16) {
      return "rgb(20, 200, 209)";
    }
    if (gasPrice <= 32) {
      return "rgb(30, 150, 220)";
    }
    if (gasPrice <= 64) {
      return "rgb(120, 100, 220)";
    }
    if (gasPrice <= 128) {
      return "rgb(220, 160, 220)";
    }
    if (gasPrice <= 256) {
      return "rgb(250, 200, 200)";
    }
    if (gasPrice <= 512) {
      return "rgb(120, 120, 120)";
    }
    if (gasPrice <= 1000) {
      return "rgb(20, 40, 20)";
    }
  }
}