/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IFoxGameNFTTraits.sol";
import "./IFoxGameNFT.sol";

contract FoxGameNFTTraits_v1 is IFoxGameNFTTraits, Ownable {
  using Strings for uint256; // add [uint256].toString()

  // Struct to store each trait's data for metadata and rendering
  struct Trait { string name; string png; }

  // Mapping of traits to metadata display names
  string[3] private _players = [ "Rabbit", "Fox", "Hunter" ];
  string[4] private _advantages = [ "5", "6", "7", "8"  ];

  // FoxGames NFT address reference
  IFoxGameNFT private foxNFTGen0;
  IFoxGameNFT private foxNFTGen1;

  // Storage of each traits name and base64 PNG data [TRAIT][TRAIT VALUE]
  mapping(uint8 => mapping(uint8 => Trait)) public traitData;

  constructor() {}

  /**
   * Update the NFT contract address outside constructor as it would
   * create a cyclic dependency.
   */
  function setNFTContracts(address _foxNFTGen0, address _foxNFTGen1) external onlyOwner {
    foxNFTGen0 = IFoxGameNFT(_foxNFTGen0);
    foxNFTGen1 = IFoxGameNFT(_foxNFTGen1);
  }

  /**
   * Return the appropriate contract interface for token.
   */
  function getTokenContract(uint16 tokenId) private view returns (IFoxGameNFT) {
    return tokenId <= 10000 ? foxNFTGen0 : foxNFTGen1;
  }

  /**
   * Upload trait art to blockchain!
   * @param traitTypeId trait name id (0 corresponds to "fur")
   * @param traitValueIds trait value id (3 corresponds to "black")
   * @param traits array of trait [name, png] (e.g,. [bandana, {bytes}])
   */
  function uploadTraits(uint8 traitTypeId, uint8[] calldata traitValueIds, string[][] calldata traits) external onlyOwner {
    require(traitValueIds.length == traits.length, "Mismatched inputs");
    for (uint8 i = 0; i < traits.length; i++) {
      traitData[traitTypeId][traitValueIds[i]] = Trait(
        traits[i][0],
        traits[i][1]
      );
    }
  }

  /**
   * generates an <image> element using base64 encoded PNGs
   * @param trait the trait storing the PNG data
   * @return the <image> element
   */
  function _drawTrait(Trait memory trait) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
      trait.png,
      '"/>'
    ));
  }

  /**
   * Generates an entire SVG by composing multiple <image> elements of PNGs
   * @param t token trait struct
   * @return layered SVG
   */
  function _drawSVG(IFoxGameNFT.Traits memory t) internal view returns (string memory) {
    string memory svg;
    if (t.kind == IFoxGameNFT.Kind.RABBIT) {
      svg = string(abi.encodePacked(
        _drawTrait(traitData[0][t.traits[0]]), // Fur
        _drawTrait(traitData[1][t.traits[1]]), // Paws
        _drawTrait(traitData[2][t.traits[2]]), // Mouth
        _drawTrait(traitData[3][t.traits[3]]), // Nose
        _drawTrait(traitData[4][t.traits[4]]), // Eyes
        _drawTrait(traitData[5][t.traits[5]]), // Ears
        _drawTrait(traitData[6][t.traits[6]])  // Head
      ));
    } else if (t.kind == IFoxGameNFT.Kind.FOX) {
      svg = string(abi.encodePacked(
        _drawTrait(traitData[7][t.traits[0]]), // Tail
        _drawTrait(traitData[8][t.traits[1]]), // Fur
        _drawTrait(traitData[9][t.traits[2]]), // Feet
        _drawTrait(traitData[10][t.traits[3]]), // Neck
        _drawTrait(traitData[11][t.traits[4]]), // Mouth
        _drawTrait(traitData[12][t.traits[5]])  // Eyes
      ));
    } else { // HUNTER
      svg = string(abi.encodePacked(
        _drawTrait(traitData[14][t.traits[0]]), // Clothes
        _drawTrait(traitData[15][t.traits[1]]), // Marksman
        _drawTrait(traitData[16][t.traits[2]]), // Neck
        _drawTrait(traitData[17][t.traits[3]]), // Mouth
        _drawTrait(traitData[18][t.traits[4]]), // Eyes
        _drawTrait(traitData[19][t.traits[5]])  // Hat
      ));
    }

    return string(abi.encodePacked(
      '<svg width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svg,
      "</svg>"
    ));
  }

  /**
   * Generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function _attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"', traitType,
      '","value":"', value,
      '"}'
    ));
  }

  /**
   * Generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return traits JSON array of all of the attributes for given token ID
   */
  function _compileAttributes(uint16 tokenId, IFoxGameNFT.Traits memory t) internal view returns (string memory traits) {
    if (t.kind == IFoxGameNFT.Kind.RABBIT) {
      traits = string(abi.encodePacked(
        _attributeForTypeAndValue("Fur",   traitData[0][t.traits[0]].name), ",", 
        _attributeForTypeAndValue("Paws",  traitData[1][t.traits[1]].name), ",",
        _attributeForTypeAndValue("Mouth", traitData[2][t.traits[2]].name), ",",
        _attributeForTypeAndValue("Nose",  traitData[3][t.traits[3]].name), ",",
        _attributeForTypeAndValue("Eyes",  traitData[4][t.traits[4]].name), ",",
        _attributeForTypeAndValue("Ears",  traitData[5][t.traits[5]].name), ",",
        _attributeForTypeAndValue("Head",  traitData[6][t.traits[6]].name), ","
      ));
    } else if (t.kind == IFoxGameNFT.Kind.FOX) {
      traits = string(abi.encodePacked(
        _attributeForTypeAndValue("Tail",  traitData[7][t.traits[0]].name), ",",
        _attributeForTypeAndValue("Fur",   traitData[8][t.traits[1]].name), ",",
        _attributeForTypeAndValue("Feet",  traitData[9][t.traits[2]].name), ",",
        _attributeForTypeAndValue("Neck",  traitData[10][t.traits[3]].name), ",",
        _attributeForTypeAndValue("Mouth", traitData[11][t.traits[4]].name), ",",
        _attributeForTypeAndValue("Eyes",  traitData[12][t.traits[5]].name), ",",
        _attributeForTypeAndValue("Cunning Score", _advantages[t.advantage]), ","
      ));
    } else { // HUNTER
      traits = string(abi.encodePacked(
        _attributeForTypeAndValue("Clothes",  traitData[14][t.traits[0]].name), ",",
        _attributeForTypeAndValue("Marksman", traitData[15][t.traits[1]].name), ",",
        _attributeForTypeAndValue("Neck",     traitData[16][t.traits[2]].name), ",",
        _attributeForTypeAndValue("Mouth",    traitData[17][t.traits[3]].name), ",",
        _attributeForTypeAndValue("Eyes",     traitData[18][t.traits[4]].name), ",",
        _attributeForTypeAndValue("Hat",      traitData[19][t.traits[5]].name), ",",
        _attributeForTypeAndValue("Marksman Score", _advantages[t.advantage]), ","
      ));
    }
    return string(abi.encodePacked(
      '[',
        traits,
        '{"trait_type":"Generation","value":', tokenId <= getTokenContract(tokenId).getMaxGEN0Players() ? '"GEN 0"' : '"GEN 1"',
        '},{"trait_type":"Type","value":"', _players[uint8(t.kind)],
      '"}]'
    ));
  }

  /**
   * ERC720 token URI interface. Generates a base64 encoded metadata response
   * without referencing off-chain content.
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint16 tokenId) external view override returns (string memory) {
    IFoxGameNFT.Traits memory traits = getTokenContract(tokenId).getTraits(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "', _players[uint8(traits.kind)], " #", uint256(tokenId).toString(),
      '", "description": "The metaverse mainland is full of creatures. Around the Farm, an abundance of Rabbits scurry to harvest CARROT. Alongside Farmers, they expand the farm and multiply their earnings. There',
      "'", 's only one small problem -- the farm has grown too big and a new threat of nature has entered the game.", "image": "data:image/svg+xml;base64,',
      _base64(bytes(_drawSVG(traits))),
      '", "attributes":',
      _compileAttributes(tokenId, traits),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      _base64(bytes(metadata))
    ));
  }

  /** BASE 64 - Written by Brech Devos */
  string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function _base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFoxGameNFTTraits {
  function tokenURI(uint16 tokenId) external view returns (string memory);
}

/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFoxGameNFT {
  enum Kind { RABBIT, FOX, HUNTER }
  struct Traits { Kind kind; uint8 advantage; uint8[7] traits; }
  function getMaxGEN0Players() external pure returns (uint16);
  function getTraits(uint16) external view returns (Traits memory);
  function ownerOf(uint256) external view returns (address owner);
  function transferFrom(address, address, uint256) external;
  function safeTransferFrom(address, address, uint256, bytes memory) external;
}

// SPDX-License-Identifier: MIT

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