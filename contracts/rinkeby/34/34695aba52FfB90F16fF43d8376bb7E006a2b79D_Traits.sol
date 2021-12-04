// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./Itest.sol";
import "./EntTest.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
  }
  
  string private blank = "";

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
  
  // storage of each trait's name
  mapping(uint8 => mapping(uint8 => Trait)) public traitData;
  // mapping from alphaIndex to its score
  string[4] _alphas = [
    "8",
    "7",
    "6",
    "5"
  ];

  string private _baseArtURI;
  
  Itest public test;

  constructor(
      string memory baseArtURI
      ) {
      _baseArtURI = baseArtURI;
  }

  /** ADMIN */
  
  function setArtURI(string memory _artURI) public onlyOwner {
    _baseArtURI = _artURI;    
  }

  function artURI() public view returns (string memory) {
    return _baseArtURI;
  }

  function setTest(address _test) external onlyOwner {
    test = Itest(_test);
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
  function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint i = 0; i < traits.length; i++) {
      traitData[traitType][traitIds[i]] = Trait(
        traits[i].name
      );
    }
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
    Itest.SheepWolf memory s = test.getTokenTraits(tokenId);
    string memory traits;
    if (s.isSheep) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[0][s.fur].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[1][s.head].name),',',
        attributeForTypeAndValue(_traitTypes[2], traitData[2][s.ears].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[3][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[4][s.nose].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[5][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[7], traitData[7][s.feet].name),','
      ));
    } else {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[9][s.fur].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[10][s.alphaIndex].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[12][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[14][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[6], traitData[15][s.neck].name),',',
        attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]),','
      ));
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Type","value":',
      s.isSheep ? '"Sheep"' : '"Wolf"',
      '}]'
    ));
  }
  
  function getImage(uint256 tokenId) public view returns (string memory) {
    Itest.SheepWolf memory s = test._getTokenTraits(tokenId);
    string memory traits;
    if (s.isSheep) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[0][s.fur].name),'+',
        attributeForTypeAndValue(_traitTypes[1], traitData[1][s.head].name),'+',
        attributeForTypeAndValue(_traitTypes[2], traitData[2][s.ears].name),'+',
        attributeForTypeAndValue(_traitTypes[3], traitData[3][s.eyes].name),'+',
        attributeForTypeAndValue(_traitTypes[4], traitData[4][s.nose].name),'+',
        attributeForTypeAndValue(_traitTypes[5], traitData[5][s.mouth].name),'+',
        attributeForTypeAndValue(_traitTypes[7], traitData[7][s.feet].name),'+'
      ));
    } else {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[9][s.fur].name),'+',
        attributeForTypeAndValue(_traitTypes[1], traitData[10][s.alphaIndex].name),'+',
        attributeForTypeAndValue(_traitTypes[3], traitData[12][s.eyes].name),'+',
        attributeForTypeAndValue(_traitTypes[5], traitData[14][s.mouth].name),'+',
        attributeForTypeAndValue(_traitTypes[6], traitData[15][s.neck].name),'+',
        attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]),'+'
      ));
    }
    return string(abi.encodePacked(
      '[',
      artURI(),
      traits,
      '.png]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    Itest.SheepWolf memory s = test.getTokenTraits(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      s.isSheep ? 'Sheep #' : 'Wolf #',
      tokenId.toString(),
      '", "description": "This is a test.", "image": "',
      getImage(tokenId),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }


  
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
}