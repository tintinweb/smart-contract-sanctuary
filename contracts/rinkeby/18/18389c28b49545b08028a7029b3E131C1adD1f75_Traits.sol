pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./IDogewood.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  string[] traitTypes = ['head', 'breed', 'color', 'class', 'armor', 'offhand', 'mainhand', 'lvlArmor', 'lvlOffhand', 'lvlMainhand', 'level'];

  // storage of each traits name
  // trait1 => [name1, name2, ...]
  mapping(uint8 => mapping(uint8 => string)) public traitNames;

  // trait1 => id1 => trait2 => id2 => address
  // ex:
  //   breed => 0 => head => 0 => breedHeas
  //   class => {armor | offhand | mainhand} => value => address
  mapping(uint8 => mapping(uint8 => mapping(uint8 => mapping(uint8 => address)))) public traitSvgs;

  IDogewood public dogewood;

  constructor() {
    // head
    string[9] memory heads = ["Determined", "High", "Happy", "Determined Tongue", "High Tongue", "Happy Tongue", "Determined Open", "High Open", "Happy Open"];
    for (uint8 i = 0; i < heads.length; i++) {
      traitNames[0][i] = heads[i];  
    }
    // bread
    string[8] memory breads = ["Shiba", "Pug", "Corgi", "Labrador", "Dachshund", "Poodle", "Pitbull", "Bulldog"];
    for (uint8 i = 0; i < breads.length; i++) {
      traitNames[1][i] = breads[i];  
    }
    // color
    string[6] memory colors = ["Palette 1", "Palette 2", "Palette 3", "Palette 4", "Palette 5", "Palette 6"];
    for (uint8 i = 0; i < colors.length; i++) {
      traitNames[2][i] = colors[i];  
    }
    // class
    string[8] memory classes = ["Warrior", "Rogue", "Mage", "Hunter", "Cleric", "Bard", "Merchant", "Forager"];
    for (uint8 i = 0; i < classes.length; i++) {
      traitNames[3][i] = classes[i];  
    }
  }

  /** ADMIN */

  function setDogewood(address _dogewood) external onlyOwner {
    dogewood = IDogewood(_dogewood);
  }

  /**
   * administrative to upload the names associated with each trait
   */
  function uploadTraitNames(uint8 trait, uint8[] calldata traitIds, string[] calldata names) external onlyOwner {
    require(traitIds.length == names.length, "Mismatched inputs");
    for (uint256 index = 0; index < traitIds.length; index++) {
      traitNames[trait][traitIds[index]] = names[index];
    }
  }

  function uploadTraitSvgs(uint8 trait1, uint8 id1, uint8 trait2, uint8[] calldata trait2Ids, address source) external onlyOwner {
    for (uint256 index = 0; index < trait2Ids.length; index++) {
        traitSvgs[trait1][id1][trait2][trait2Ids[index]] = source; 
    }
  }

  /*///////////////////////////////////////////////////////////////
                  INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function call(address source, bytes memory sig) internal view returns (string memory svg) {
      (bool succ, bytes memory ret)  = source.staticcall(sig);
      require(succ, "failed to get data");
      svg = abi.decode(ret, (string));
  }

  function getSvg(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2) internal view returns (string memory data_) {
      address source = traitSvgs[trait1][id1][trait2][id2];
      data_ = call(source, getData(trait1, id1, trait2, id2));
  }

  function getData(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2) internal view returns (bytes memory data) {
    string memory s = string(abi.encodePacked(
          traitTypes[trait1],toString(id1),
          traitTypes[trait2],toString(id2),
          "()"
      ));
    return abi.encodeWithSignature(s, "");
  }

  /**
   * generates an entire SVG by composing multiple <image> elements of PNGs
   * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Sheep / Wolf
   */
  function drawSVG(uint256 tokenId) public view returns (string memory) {
    IDogewood.Doge memory s = dogewood.getTokenTraits(tokenId);

    return string(abi.encodePacked(
      string(abi.encodePacked(
        '<svg id="doge" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 64 64" shape-rendering="geometricPrecision" text-rendering="geometricPrecision"><style>',
        getSvg(1, s.breed, 2, s.color) // breed -> color
      )),
      '.to {fill: #E2B0D0;};<![CDATA[#llu_to {animation: llu_to__to 1970ms linear infinite normal forwards}@keyframes llu_to__to {0% {transform: translate(38.445px, 50.11px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(38.445px, 49.11px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(38.445px, 50.08px)}}#llu_tr {animation: llu_tr__tr 1970ms linear infinite normal forwards}@keyframes llu_tr__tr {0% {transform: rotate(0deg);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: rotate(9.852042deg);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: rotate(0.295561deg)}}#lll_tr {animation: lll_tr__tr 1970ms linear infinite normal forwards}@keyframes lll_tr__tr {0% {transform: translate(40.570847px, 59.34803px) rotate(0deg);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(40.570847px, 59.34803px) rotate(-6.706667deg);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(40.570847px, 59.34803px) rotate(0deg)}}#lau_to {animation: lau_to__to 1970ms linear infinite normal forwards}@keyframes lau_to__to {0% {transform: translate(40.09px, 36.61px)}10.152284% {transform: translate(40.09px, 36.61px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(40.09px, 35.724449px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(40.09px, 36.583433px)}}#lal_to {animation: lal_to__to 1970ms linear infinite normal forwards}@keyframes lal_to__to {0% {transform: translate(44.64px, 42.14px)}10.152284% {transform: translate(44.64px, 42.14px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(44.64px, 41.30px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(44.64px, 42.12px)}}#lhg_to {animation: lhg_to__to 1970ms linear infinite normal forwards}@keyframes lhg_to__to {0% {transform: translate(51.932867px, 41.61px)}10.152284% {transform: translate(51.932867px, 41.61px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(51.932867px, 40.61px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(51.932867px, 41.58px)}}#rlu_to {animation: rlu_to__to 1970ms linear infinite normal forwards}@keyframes rlu_to__to {0% {transform: translate(29.8px, 49px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(29.727549px, 47.98px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(29.797826px, 48.97px)}}#rll_tr {animation: rll_tr__tr 1970ms linear infinite normal forwards}@keyframes rll_tr__tr {0% {transform: translate(21.539296px, 59.4px) rotate(7.41deg);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(21.539296px, 59.397946px) rotate(0.899323deg);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(21.539296px, 59.397946px) rotate(7.824398deg)}}#b_to {animation: b_to__to 1970ms linear infinite normal forwards}@keyframes b_to__to {0% {transform: translate(32.42684px, 42.24346px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(32.42684px, 41.24346px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(32.42684px, 42.21346px)}}#h_to {animation: h_to__to 1970ms linear infinite normal forwards}@keyframes h_to__to {0% {transform: translate(34.27015px, 25.573563px)}5.076142% {transform: translate(34.27015px, 25.573563px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(34.27015px, 24.573563px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(34.27015px, 25.543563px)}}#rau_to {animation: rau_to__to 1970ms linear infinite normal forwards}@keyframes rau_to__to {0% {transform: translate(25.071545px, 35.88px)}10.152284% {transform: translate(25.071545px, 35.88px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(25.071545px, 34.88px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(25.071545px, 35.85px)}}#ral_to {animation: ral_to__to 1970ms linear infinite normal forwards}@keyframes ral_to__to {0% {transform: translate(21.75px, 39.476864px)}10.152284% {transform: translate(21.75px, 39.476864px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}50.761421% {transform: translate(21.75px, 38.476864px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(21.75px, 39.446864px)}}#rhg_to {animation: rhg_to__to 1970ms linear infinite normal forwards}@keyframes rhg_to__to {0% {transform: translate(16.48px, 26.210001px)}20.304569% {transform: translate(16.48px, 26.210001px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}60.913706% {transform: translate(16.48px, 25.210001px);animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1)}100% {transform: translate(16.48px, 26.172501px)}}]]></style><g id="llu_to" transform="translate(38.445,50.11)"><g id="llu_tr" transform="rotate(0)"><path id="llu" class="p st" d="M39,54.08C48.21,59.71,47.38,49.2,38.85,47.08C35.57,46.22,32.87,50.33,39,54.08Z" transform="translate(-38.444998,-50.11)"/></g></g><g id="lll_tr" transform="translate(40.570847,59.34803) rotate(0)"><path id="lll" d="M40.67,54.6C40.67,54.6,38.22,55.6,38.76,56.02C39.019118,56.1171,39.293294,56.167874,39.57,56.17C39.846706,56.172126,37.48,57.85,39.5,57.85C38.5,59.75,39.33,60.29,40.5,60.14C42.88,59.85,47.35,54.94,45.34,53.35" transform="translate(-40.570846,-59.34803)" class= "p st" /></g><g id="lau_to" transform="translate(40.09,36.61)"><path id="lau" d="M39.58,34.55C41,32.99,43.94,34.55,44.05,37.89C54,50.78,31.36,41.73,39.58,34.55Z" transform="translate(-40.089999,-36.692566)" class="p st" /></g><g id="lal_to" transform="translate(44.64,42.141064)"><path id="lal" d="M44.45,40.41C48.84,37.86,55.52,44.57,45.22,44.5C45.22,44.5,45.03,45.5,44.49,44.74C44.22,44.98,43.29,46.3,43.49,43.81" transform="translate(-44.64,-42.141054)" class= "p st" /></g><g id="lhg_to" transform="translate(51.932867,41.613806)"><g id="lhg" transform="translate(-51.932867,-41.613805)"><g id="lh"><path class="p st" d="M53.72,40.94C53.72,40.94,54.19,42.8,53.06,42.82C53.74,44.82,48.95,43.66,50.46,42.27C50.310545,41.770875,50.383427,41.231554,50.66,40.79C48.89,38.05,55,38.77,53.72,40.94Z" fill="rgb(250,146,35)"/><path class="p st" d="M50.38,43.33C50.38,43.33,50.15,43.56,49.03,43.1M50.18,41.72C50.5,41.62,50.42,40.56,50.42,40.56C52.19,42.44,51.55,38.78,50.42,39.07C49.957689,39.069969,49.514599,39.254979,49.18958,39.583756C48.864561,39.912532,48.684655,40.35772,48.69,40.82" fill="rgb(250,146,35)" /></g><g id="oh">',
      string(abi.encodePacked(
        getSvg(3, s.class, 5, s.offhand), // class -> offhand
        string(abi.encodePacked(
          '</g></g></g><g id="rlu_to" transform="translate(29.8,49)"><path id="rlu" d="M26.16,47.51C17.88,57,27,58.28,32.3,51.18" transform="rotate(-16.630564) translate(-29.8,-49.07425)" class= "p st" /></g><g id="rll_tr" transform="translate(21.539296,59.397946) rotate(7.415168)"><path id="rll" d="M23,53.26C23,53.26,20,54,21.35,55C20.07,55.79,20.19,56.46,21.24,56.32C18.09,63.32,24.24,59.17,26.69,56.56C28.03,55.13,28.07,54.78,28.07,54.78" transform="translate(-21.059999,-59.397931)" class= "p st" /></g><g id="b_to" transform="translate(32.42684,42.24346)"><g id="b" transform="translate(-32.42684,-42.243459)"><path id="t" d="M23.47,36.09C22.57,40.9,25.15,39.94,26.03,47.91C26.63,53.36,41,56.43,40.5,43C40.36,39.33,42.2,35.12,39.8,33.36C36.57,31,24.94,28.27,23.47,36.09Z" class= "p st" /></g></g> <g id="rau_to" transform="translate(25.071545,35.88)"><path id="rau" d="M26,33.76C26,33.76,21.84,31.92,20.7,36.82C20.7,36.82,17.2,41.48,21.7,41.49C26.05,41.49,26.03,40.15,27.32,40.25" transform="translate(-25.07154,-35.756237)" class= "p st" /></g><g id="b_to" transform="translate(32.42684,42.24346)"><g id="b" transform="translate(-32.42684,-42.243459)">',
          getSvg(3, s.class, 4, s.armor))), // class -> armor
        string(abi.encodePacked(
          '</g></g><g id="h_to" transform="translate(34.27015,25.573563)"><g id="h" transform="translate(-34.27015,-25.573563)">',
          getSvg(1, s.breed, 0, s.head), // breed -> head
          '</g></g><g id="ral_to" transform="translate(21.75,39.476864)"><path id="ral" d="M22.54,37.73C21.91,36.65,19.54,35.95,17.48,38.42C13.89,42.8,23,43,23.3,40.67" transform="translate(-21.749999,-39.476864)" class= "p st" /></g><g id="rhg_to" transform="translate(16.48,26.210001)"><g id="rhg" transform="translate(-16.48,-26.210001)"><g id="mh">')),
        string(abi.encodePacked(
          getSvg(3, s.class, 6, s.mainhand), // class -> mainhand
          '</g><g id="rh"><path id="25" d="M18.08,37.23C22.13,35.44,21.08,41.16,19.59,41.16C18.1,41.16,17.51,37.49,18.08,37.23Z" class= "p st" /><path id="13" d="M18.67,38.69C20.56,39.14,19.04,40.86,19.04,40.86C21.63,43.17,13.04,44.51,14.3,41.67C12.24,41.67,13.08,38.92,13.08,38.92C11.52,35.33,21.48,36,18.67,38.69ZM15.67,41.35C16.55443,41.435012,17.446858,41.370784,18.31,41.16M17.62,38.74C16.866986,38.594273,16.093014,38.594273,15.34,38.74" class= "p st" /></g></g></g><path id="rf" d="M22.920306,59.141614Q24.375075,57.999107,24.899612,59.141614Q26.13429,57.617253,26.488256,60.345399Q23.097414,60.768964,21.257409,60.174476" transform="matrix(1 0 0 1 -0.10429 -0.116147)" class= "p st" /><path id="lf" d="M23.380676,59.141614Q25.065606,57.999107,25.590143,59.141614Q26.824821,57.617253,26.488256,60.345399Q23.097414,60.768964,21.257409,60.174476" transform="matrix(1 0 0 1 18.164491 -0.116147)" class= "p st" /></svg>'
        ))
      ))
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
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IDogewood.Doge memory s = dogewood.getTokenTraits(tokenId);

    string memory traits1 = string(abi.encodePacked(
      attributeForTypeAndValue(traitTypes[0], traitNames[0][s.head]),',',
      attributeForTypeAndValue(traitTypes[1], traitNames[1][s.breed]),',',
      attributeForTypeAndValue(traitTypes[2], traitNames[2][s.color]),',',
      attributeForTypeAndValue(traitTypes[3], traitNames[3][s.class]),','
    ));
    string memory traits2 = string(abi.encodePacked(
      attributeForTypeAndValue(traitTypes[4], toString(s.armor)),',',
      attributeForTypeAndValue(traitTypes[5], toString(s.offhand)),',',
      attributeForTypeAndValue(traitTypes[6], toString(s.mainhand)),',',
      attributeForTypeAndValue(traitTypes[7], toString(s.lvlArmor)),',',
      attributeForTypeAndValue(traitTypes[8], toString(s.lvlOffhand)),',',
      attributeForTypeAndValue(traitTypes[9], toString(s.lvlMainhand)),',',
      attributeForTypeAndValue(traitTypes[10], toString(s.level)),','
    ));
    return string(abi.encodePacked(
      '[',
      traits1, traits2,
      '{"trait_type":"Generation","value":',
      tokenId <= dogewood.getGenesisSupply() ? '"Gen 0"' : '"Gen 1"',
      '}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "Dogewood #',
      tokenId.toString(),
      '", "description": "100% on-chain", "image": "data:image/svg+xml;base64,',
      base64(bytes(drawSVG(tokenId))),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  /** BASE 64 - Written by Brech Devos */
  
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

pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IDogewood {

  // struct to store each token's traits
  
  struct Doge {
      uint8 head;
      uint8 breed;
      uint8 color;
      uint8 class;
      uint8 armor;
      uint8 offhand;
      uint8 mainhand;
      uint8 lvlArmor;
      uint8 lvlOffhand;
      uint8 lvlMainhand;
      uint16 level;
  }

  function getTokenTraits(uint256 tokenId) external view returns (Doge memory);
  function getGenesisSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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