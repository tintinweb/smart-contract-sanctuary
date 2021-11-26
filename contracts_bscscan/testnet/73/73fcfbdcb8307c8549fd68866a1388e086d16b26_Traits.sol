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
  traitData[0][0] = Trait("15","15");
  traitData[0][1] = Trait("50","50");
  traitData[0][2] = Trait("200","200");
  traitData[0][3] = Trait("250","250");
  traitData[0][4] = Trait("255","255");
  traitData[1][0] = Trait("190","190");
  traitData[1][1] = Trait("215","215");
  traitData[1][2] = Trait("240","240");
  traitData[1][3] = Trait("100","100");
  traitData[1][4] = Trait("110","110");
  traitData[1][5] = Trait("135","135");
  traitData[1][6] = Trait("160","160");
  traitData[1][7] = Trait("185","185");
  traitData[1][8] = Trait("80","80");
  traitData[1][9] = Trait("210","210");
  traitData[1][10] = Trait("235","235");
  traitData[1][11] = Trait("240","240");
  traitData[1][12] = Trait("80","80");
  traitData[1][13] = Trait("80","80");
  traitData[1][14] = Trait("100","100");
  traitData[1][15] = Trait("100","100");
  traitData[1][16] = Trait("100","100");
  traitData[1][17] = Trait("245","245");
  traitData[1][18] = Trait("250","250");
  traitData[1][19] = Trait("255","255");
  traitData[2][0] = Trait("255","255");
  traitData[2][1] = Trait("30","30");
  traitData[2][2] = Trait("60","60");
  traitData[2][3] = Trait("60","60");
  traitData[2][4] = Trait("150","150");
  traitData[2][5] = Trait("156","156");
  traitData[3][0] = Trait("221","221");
  traitData[3][1] = Trait("100","100");
  traitData[3][2] = Trait("181","181");
  traitData[3][3] = Trait("140","140");
  traitData[3][4] = Trait("224","224");
  traitData[3][5] = Trait("147","147");
  traitData[3][6] = Trait("84","84");
  traitData[3][7] = Trait("228","228");
  traitData[3][8] = Trait("140","140");
  traitData[3][9] = Trait("224","224");
  traitData[3][10] = Trait("250","250");
  traitData[3][11] = Trait("160","160");
  traitData[3][12] = Trait("241","241");
  traitData[3][13] = Trait("207","207");
  traitData[3][14] = Trait("173","173");
  traitData[3][15] = Trait("84","84");
  traitData[3][16] = Trait("254","254");
  traitData[3][17] = Trait("220","220");
  traitData[3][18] = Trait("196","196");
  traitData[3][19] = Trait("140","140");
  traitData[3][20] = Trait("168","168");
  traitData[3][21] = Trait("252","252");
  traitData[3][22] = Trait("140","140");
  traitData[3][23] = Trait("183","183");
  traitData[3][24] = Trait("236","236");
  traitData[3][25] = Trait("252","252");
  traitData[3][26] = Trait("224","224");
  traitData[3][26] = Trait("255","255");
  traitData[4][0] = Trait("175","175");
  traitData[4][1] = Trait("100","100");
  traitData[4][2] = Trait("40","40");
  traitData[4][3] = Trait("250","250");
  traitData[4][4] = Trait("115","115");
  traitData[4][5] = Trait("100","100");
  traitData[4][6] = Trait("185","185");
  traitData[4][7] = Trait("175","175");
  traitData[4][8] = Trait("180","180");
  traitData[4][9] = Trait("255","255");

  traitData[5][0] = Trait("80","80");
  traitData[5][1] = Trait("255","255");
  traitData[5][2] = Trait("227","227");
  traitData[5][3] = Trait("228","228");
  traitData[5][4] = Trait("112","112");
  traitData[5][5] = Trait("240","240");
  traitData[5][6] = Trait("64","64");
  traitData[5][7] = Trait("160","160");
  traitData[5][8] = Trait("167","167");
  traitData[5][9] = Trait("217","217");
  traitData[5][10] = Trait("171","171");
  traitData[5][11] = Trait("64","64");
  traitData[5][12] = Trait("240","240");
  traitData[5][13] = Trait("126","126");
  traitData[5][14] = Trait("80","80");
  traitData[5][15] = Trait("255","255");
  traitData[6][0] = Trait("255","255");

  traitData[7][0] = Trait("243","243");
  traitData[7][1] = Trait("189","189");
  traitData[7][2] = Trait("133","133");
  traitData[7][3] = Trait("133","133");
  traitData[7][4] = Trait("57","57");
  traitData[7][5] = Trait("95","95");
  traitData[7][6] = Trait("152","152");
  traitData[7][7] = Trait("135","135");
  traitData[7][8] = Trait("133","133");
  traitData[7][9] = Trait("57","57");
  traitData[7][10] = Trait("222","222");
  traitData[7][11] = Trait("168","168");
  traitData[7][12] = Trait("57","57");
  traitData[7][13] = Trait("57","57");
  traitData[7][14] = Trait("38","38");
  traitData[7][15] = Trait("11","84");
  traitData[7][16] = Trait("114","114");
  traitData[7][17] = Trait("144","114");
  traitData[7][18] = Trait("255","255");
  //Goat
    traitData[9][0] = Trait("210","210");
    traitData[9][1] = Trait("90","90");
    traitData[9][2] = Trait("9","9");
    traitData[9][3] = Trait("9","9");
    traitData[9][4] = Trait("9","9");
    traitData[9][5] = Trait("150","150");
    traitData[9][6] = Trait("9","9");
    traitData[9][7] = Trait("255","255");
    traitData[9][8] = Trait("9","9");

    traitData[10][0]  = Trait("255","255");
    
    traitData[11][0] = Trait("255","255");

    traitData[12][0] = Trait("135","135");
    traitData[12][1] = Trait("177","177");
    traitData[12][2] = Trait("219","219");
    traitData[12][3] = Trait("141","141");
    traitData[12][4] = Trait("183","183");
    traitData[12][5] = Trait("225","225");
    traitData[12][6] = Trait("147","147");
    traitData[12][7] = Trait("189","189");
    traitData[12][8] = Trait("231","231");
    traitData[12][9]= Trait("135","135");
    traitData[12][10]= Trait("135","135");
    traitData[12][11]= Trait("135","135");
    traitData[12][12]= Trait("135","135");
    traitData[12][13]= Trait("246","246");
    traitData[12][14]= Trait("150","150");
    traitData[12][15]= Trait("150","150");
    traitData[12][16]= Trait("156","156");
    traitData[12][17]= Trait("165","165");
    traitData[12][18]= Trait("171","171");
    traitData[12][19]= Trait("180","180");
    traitData[12][20]= Trait("186","1886");
    traitData[12][21]= Trait("195","195");
    traitData[12][22]= Trait("201","201");
    traitData[12][23]= Trait("210","210");
    traitData[12][24]= Trait("243","243");
    traitData[12][25]= Trait("252","252");
    traitData[12][26]= Trait("255","255");


    traitData[13][0]= Trait("255","255");

    traitData[14][0]= Trait("239","239");
    traitData[14][1]= Trait("244","244");
    traitData[14][2]= Trait("249","249");
    traitData[14][3]= Trait("234","234");
    traitData[14][4]= Trait("234","234");
    traitData[14][5]= Trait("234","234");
    traitData[14][6]= Trait("234","234");
    traitData[14][7]= Trait("234","234");
    traitData[14][8]= Trait("234","234");
    traitData[14][9]= Trait("234","234");
    traitData[14][10]= Trait("130","130");
    traitData[14][11]= Trait("255","255");
    traitData[14][12]= Trait("247","247");

    traitData[15][0]= Trait("75","75");
    traitData[15][1]= Trait("180","180");
    traitData[15][2]= Trait("165","165");
    traitData[15][3]= Trait("120","120");
    traitData[15][4]= Trait("60","60");
    traitData[15][5]= Trait("150","150");
    traitData[15][6]= Trait("105","105");
    traitData[15][7]= Trait("195","195");
    traitData[15][8]= Trait("45","45");
    traitData[15][9]= Trait("225","225");
    traitData[15][10]= Trait("75","75");
    traitData[15][11]= Trait("45","45");
    traitData[15][12]= Trait("195","195");
    traitData[15][13]= Trait("120","120");
    traitData[15][14]= Trait("255","255");

    

    traitData[16][0]= Trait("255","255");
    traitData[17][0]= Trait("8","8");
    traitData[17][1]= Trait("160","160");
    traitData[17][2]= Trait("73","73");
    traitData[17][3]= Trait("255","255");
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
      '", "external_url":"https://external_url/',tokenId.toString(),
      '", "description": "Thousands of Tortoises and Goats compete on a isle in the metaverse. A tempting prize of $EGGS awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "attributes":',
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
}