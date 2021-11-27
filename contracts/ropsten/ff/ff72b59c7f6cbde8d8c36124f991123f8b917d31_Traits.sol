// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./IGoat.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    string png;
  }

  // mapping from trait type (index) to its name
  string[9] _traitTypes = [
    "Fur",
    "Head",
    "Ears",
    "Eyes",
    "Nose",
    "Mouth",
    "Neck",
    "Feet",
    "Alpha"
  ];
  // storage of each traits name and base64 PNG data
  mapping(uint8 => mapping(uint8 => Trait)) public traitData;
  // mapping from alphaIndex to its score
  string[4] _alphas = [
    "8",
    "7",
    "6",
    "5"
  ];

  IGoat public goat;

  constructor() {
  
  }

  /** ADMIN */

  function setGoat(address _goat) external onlyOwner {
    goat = IGoat(_goat);
  }

  

  /** RENDER */

  /**
   * generates an <image> element using base64 encoded PNGs
   * @param trait the trait storing the PNG data
   * @return the <image> element
   */
  function drawTrait(Trait memory trait) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
      trait.png,
      '"/>'
    ));
  }

  

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IGoat.TortoiseGoat memory s = goat.getTokenTraits(tokenId);
    string memory traits;
    
    if (s.isTortoise) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], uint2str(s.fur)),',',
        attributeForTypeAndValue(_traitTypes[1], uint2str(s.head)),',',
        attributeForTypeAndValue(_traitTypes[2], uint2str(s.ears)),',',
        attributeForTypeAndValue(_traitTypes[3], uint2str(s.eyes)),',',
        attributeForTypeAndValue(_traitTypes[4], uint2str(s.nose)),',',
        attributeForTypeAndValue(_traitTypes[5], uint2str(s.mouth)),',',
        attributeForTypeAndValue(_traitTypes[7], uint2str(s.neck)),',',
        attributeForTypeAndValue(_traitTypes[7], uint2str(s.feet)),','
      ));
    } else {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], uint2str(s.fur)),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[10][s.alphaIndex].name),',',
        attributeForTypeAndValue(_traitTypes[3], uint2str(s.eyes)),',',
        attributeForTypeAndValue(_traitTypes[5], uint2str(s.mouth)),',',
        attributeForTypeAndValue(_traitTypes[6], uint2str(s.neck)),',',
        attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]),','
      ));
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Generation","value":',
      tokenId <= goat.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
      '},{"trait_type":"Type","value":',
      s.isTortoise ? '"Tortoise"' : '"Goat"',
      '}]'
    ));
  }
  /**
   * generates an entire SVG by composing multiple <image> elements of PNGs
   * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Tortise / Goat
   */
  function drawSVG(uint256 tokenId) public view returns (string memory) {
    IGoat.TortoiseGoat memory s = goat.getTokenTraits(tokenId);
    uint8 shift = s.isTortoise ? 0 : 9;

    string memory svgString = string(abi.encodePacked(
      drawTrait(traitData[0 + shift][s.fur]),
      s.isTortoise ? drawTrait(traitData[1 + shift][s.head]) : drawTrait(traitData[1 + shift][s.alphaIndex]),
      s.isTortoise ? drawTrait(traitData[2 + shift][s.ears]) : '',
      drawTrait(traitData[3 + shift][s.eyes]),
      s.isTortoise ? drawTrait(traitData[4 + shift][s.nose]) : '',
      drawTrait(traitData[5 + shift][s.mouth]),
      s.isTortoise ? '' : drawTrait(traitData[6 + shift][s.neck]),
      s.isTortoise ? drawTrait(traitData[7 + shift][s.feet]) : ''
    ));

    return string(abi.encodePacked(
      '<svg id="Goat" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }
  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view  override returns (string memory) {  
    IGoat.TortoiseGoat memory s = goat.getTokenTraits(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      s.isTortoise ? 'Tortoise #' : 'Goat #',
      tokenId.toString(),
      '", "external_url":"https://ecclub.games/nft/images/',tokenId.toString(),
      '.png", "tokenid": "',tokenId.toString(),
      '", "description": "Thousands of Tortoises and Goats compete on a isle in the metaverse. A tempting prize of $EGGS awaits, with deadly high stakes.", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));
    return string(abi.encodePacked(
      "data:application/json,",
      bytes(metadata)
    ));
    
  }

  // BASE 64 - Written by Brech Devos
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

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


  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}