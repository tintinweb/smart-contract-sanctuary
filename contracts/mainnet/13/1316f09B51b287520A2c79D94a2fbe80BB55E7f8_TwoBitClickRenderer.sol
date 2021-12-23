// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/two_bit.sol";
import "./libraries/base64.sol";

pragma solidity 0.8.10;
pragma abicoder v2;

contract TwoBitClickRenderer is Ownable {
  using Strings for uint16;
  using Strings for uint8;
  using Strings for uint256;

  string[10] public _traits = [
    "Bit One RGB",
    "Bit Two RGB",
    "Bit One Level",
    "Bit Two Level",
    "Bit One X Coordinate",
    "Bit Two X Coordinate",
    "Degrees",
    "Background Color",
    "Total Level",
    "Rebirth Count"
  ];

  // Levels as keys, RGBs as lists
  mapping(uint8 => mapping(uint8 => string)) public bitRGBs;

  function uploadRGBs(
    uint8 level,
    uint8[] calldata rgbIds,
    string[] calldata rgbs
  ) external onlyOwner {
    require(rgbIds.length == rgbs.length, "Mismatched inputs");
    for (uint i = 0; i < rgbIds.length; i++) {
      bitRGBs[level][rgbIds[i]] = rgbs[i];
    }
  }

  function tokenURI(uint256 tokenId, TwoBit memory tbh) external view returns (string memory) {
    string memory image = Base64.encode(bytes(generateSVGImage(tbh)));

    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              'Two Bit',
              ' #',
              tokenId.toString(),
              '", ',
              '"attributes": ',
              compileAttributes(tbh),
              ', "image": "',
              "data:image/svg+xml;base64,",
              image,
              '"}'
            )
          )
        )
      )
    );
  }

  function generateSVGImage(TwoBit memory params) internal view returns (string memory) {
    return string(
      abi.encodePacked(
        generateSVGHeader(),
        generateBackground(params.backgroundRandomLevel, params.background),
        generateRGB(params.degrees, params.bitOneRGB, params.bitOneLevel, 160, params.bitOneXCoordinate),
        generateRGB(params.degrees, params.bitTwoRGB, params.bitTwoLevel, 360, params.bitTwoXCoordinate),
        "</svg>"
      )
    );
  }

  function generateSVGHeader() private pure returns (string memory) {
    return
    string(
      abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
        ' viewBox="0 0 720 720" style="enable-background:new 0 0 720 720;" xml:space="preserve">'
      )
    );
  }

  function generateBackground(uint8 level, uint8 rgbInt) internal view returns (string memory) {
    bytes memory svgString = abi.encodePacked(
      '<rect x="0" y="0" fill="rgb(',
      bitRGBs[level][rgbInt],
      ')" width="720" height="720"></rect>'
    );

    return string(svgString);
  }

  function generateRGB(uint16 degrees, uint8 rgbInt, uint8 level, uint16 yCoord, uint16 xCoord) internal view returns (string memory) {
    bytes memory svgString = abi.encodePacked(
      '<rect x="', xCoord.toString(), '" y="', yCoord.toString(),'" width="200" height="200" fill="rgb(',
      bitRGBs[level][rgbInt],
      ')" transform="rotate(',
      degrees.toString(),
      ', 360, 360',
      ')">'
      '</rect>'
    );
    return string(svgString);
  }

  function compileAttributes(TwoBit memory tbh) public view returns (string memory) {
    string memory traits;
    traits = string(abi.encodePacked(
      attributeForTypeAndValue(_traits[0], bitRGBs[tbh.bitOneLevel][tbh.bitOneRGB]),',',
      attributeForTypeAndValue(_traits[1], bitRGBs[tbh.bitTwoLevel][tbh.bitTwoRGB]),',',
      attributeForTypeAndValue(_traits[2], (tbh.bitOneLevel + 1).toString()),',',
      attributeForTypeAndValue(_traits[3], (tbh.bitTwoLevel+ 1).toString()),',',
      attributeForTypeAndValue(_traits[4], tbh.bitOneXCoordinate.toString()),',',
      attributeForTypeAndValue(_traits[5], tbh.bitTwoXCoordinate.toString()),',',
      attributeForTypeAndValue(_traits[6], tbh.degrees.toString()),',',
      attributeForTypeAndValue(_traits[7], bitRGBs[tbh.backgroundRandomLevel][tbh.background]),',',
      attributeForTypeAndValue(_traits[8], (tbh.bitOneLevel + tbh.bitTwoLevel + 2).toString()),',',
      attributeForNumberAndValue(_traits[2], tbh.bitOneLevel + 1),',',
      attributeForNumberAndValue(_traits[3], tbh.bitTwoLevel + 1),',',
      attributeForNumberAndValue(_traits[9], tbh.rebirth)
    ));
    return string(abi.encodePacked(
      '[',
      traits,
      ']'
    ));
  }

  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  function attributeForNumberAndValue(string memory traitType, uint8 value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"display_type":"number","trait_type":"',
      traitType,
      '","value": ',
      value.toString(),
      '}'
    ));
  }
}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v2;

struct TwoBit {
  uint8 backgroundRandomLevel;
  uint8 background;
  uint8 bitOneRGB;
  uint8 bitTwoRGB;
  uint8 bitOneLevel;
  uint8 bitTwoLevel;
  uint16 bitOneXCoordinate;
  uint16 bitTwoXCoordinate;
  uint16 degrees;
  uint8 rebirth;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}