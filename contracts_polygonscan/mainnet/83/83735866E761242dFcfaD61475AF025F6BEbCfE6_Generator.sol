/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// File: contracts/base64.sol



pragma solidity ^0.8.0;

/** BASE 64 - Written by Brech Devos */
contract base64mod
{
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function showRole(uint8 _role) public pure returns(string memory)
  {
    if(_role == 0) return "Peasant";
    else if(_role == 1) return "Thief";
    else return "Militia";
  }
  
  function base64(bytes memory data) public pure returns (string memory) {
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
// File: contracts/Stringss.sol



pragma solidity ^0.8.0;

/*
 * @dev String operations.
 */
library Stringss {
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
// File: contracts/ICharacter.sol



pragma solidity ^0.8.0;

interface ICharacter {

  // struct to store each token's components
  // Fore Roles 0 => Peasant, 1 => Thief, 2 => Militia
  struct Character {
    uint8 role;
    uint8 base;
    uint8 eyes;
    uint8 hair;
    uint8 cloth;
    uint8 boots;
    uint8 hat;
    uint8 beard;
    uint8 shield;
    uint8 weapon;
    uint256 charisma;
  }


  function getPaidTokens() external view returns (uint256);
  function getTokenComponents(uint256 tokenId) external view returns (Character memory);
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Generator.sol



pragma solidity ^0.8.0;




// This is an on-chain image generator. A SVG image will be constructed with png components.
// All comboponents will be stored as base64 on-chain.
// For randomization, VRF will be used.

contract Generator is Ownable {
  //For converting uint to strings.
  using Stringss for uint256;

  event Response(bool success, bytes data);

  base64mod public b;
    // struct to store each component's data. 
    struct Component {

        // Name of component such as body, eyes, hat, boots etc.
        string name;

        // base64 form of component's png.
        string png;

        // Total character charisma will be derrived from components distinc scores.
        uint8 score;

        // Which classes are allowed to have this component?
        // 0 => Peasant
        // 1 => Thief
        // 2 => Police
        // 3 => Peasant&Thief
        // 4 => Peasant&Police
        // 5 => Thief&Police
        // 6 => All
        uint8 allowed;
    }

    // Since storing strings costs more, I will basicly store only componentids and than fetch them with this array.
    // Index to componentstypes.
    string[9] public componentsTypes = 
    [
        "Base",
        "Eyes",
        "Hair",
        "Cloth",
        "Boots",
        "Hat",
        "Beard",
        "Shield",
        "Weapon"
    ];

    // For every component, count of elements shall be saved for autoincrement.
    uint8[9] public componentElementIDs =
    [
        0, 0, 0, 0, 0, 0, 0, 0, 0
    ];
    
    /*                                                  Storage Structure
    *   Stored index is actually componentTypes. Lets say if you want to store a "Base" image, index will be 0, or a "Hat", index will be 5
    *   After that every component indexed by an unique id to be able to modify or add new data.
    */

    mapping(uint8 => mapping(uint8 => Component)) public componentData;

    // Get componentElementIds for external calls
    function getComponentElemendIds(uint8 _id) public view returns(uint8)
    {
        return componentElementIDs[_id];
    }

    // Get component score for calculating character charisma
    function getcomponentScore(uint8 _type, uint8 _id) public view returns(uint8){
        return componentData[_type][_id].score;
    }

    // // Get componentElementIds for external calls
    function checkAllowedComponent(uint8 _type, uint8 _id, uint8 _charclass) public  view returns(bool)
    {
        if(componentData[_type][_id].allowed == _charclass || componentData[_type][_id].allowed == 6)
        {
            return true;
        }
        else if(_charclass == 0 && (componentData[_type][_id].allowed == 3 || componentData[_type][_id].allowed == 4))
        {
            return true;
        }
        else if(_charclass == 1 && (componentData[_type][_id].allowed == 3 || componentData[_type][_id].allowed == 5))
        {
            return true;
        }
        else if(_charclass == 2 && (componentData[_type][_id].allowed == 4 || componentData[_type][_id].allowed == 5))
        {
            return true;
        }
        
          return false;
    }

    // Once contract is deployed, only Owner is able to upload components.

    function uploadComponent(uint8  _componentType, string calldata _name, string calldata _base64encodedPNG, uint8 _score, uint8 _allowed) external onlyOwner 
    {
        componentData[_componentType][componentElementIDs[_componentType]] = Component(_name, _base64encodedPNG, _score, _allowed);

        // Component count is updating...
        componentElementIDs[_componentType]++;
    }

    // Incase any error during uploading, owner able to delete content and re-upload.
    function deleteLastComponent(uint8 _componentType) external onlyOwner
    {
       // Component count is updating...
        componentElementIDs[_componentType]--;

    }

    /*                                                  Rendering Structure
    *   Once all related data are stored, it is now time to render. Rendering algorithm will be like this;
    *   1-Call stored base64 encoded PNG
    *   2-Generate an <image> embedded base64 encoded PNG
    *   3-Generate s SVG image with collection of <image>s.
    */

    function drawPNG(Component memory _component) public pure returns (string memory) 
    {
        return string(abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', _component.png,'"/>'
                ));
    }

    /**
   * generates an entire SVG by composing multiple <image> elements of PNGs
   * @return a valid SVG of the Peasant, Thief of Police.
   */
  function drawSVG(ICharacter.Character memory s) public view returns (string memory) 
  {
    string memory svgString = string(abi.encodePacked(
      drawPNG(componentData[0][s.base]),    //  Base character layer
      drawPNG(componentData[1][s.eyes]),    //  Eye layer
      drawPNG(componentData[2][s.hair]),    //  Hair layer
      drawPNG(componentData[3][s.cloth]),   //  Cloth/armor layer
      drawPNG(componentData[4][s.boots]),   //  Boots/Shoes layer
      drawPNG(componentData[5][s.hat]),     //  Hat layer
      drawPNG(componentData[6][s.beard]),   //  Beard layer
      drawPNG(componentData[7][s.shield]),  //  Shield/off hand layer
      drawPNG(componentData[8][s.weapon])   //  Weapon/Main hand layer
    ));

    return string(abi.encodePacked(
      '<svg id="Citizen" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param _componentType the component type to reference as the metadata key
   * @param _value the token's component associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory _componentType, string memory _value) public pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"'
      ,_componentType,
      '","_value":"',
      _value,
      '"}'
    ));
  }

  function compileAttributes(uint256 _tokenId, ICharacter.Character memory s, uint256 _getpaindTokens) public view returns (string memory) {
    string memory components;

      components = string(abi.encodePacked(
        attributeForTypeAndValue(componentsTypes[0], componentData[0][s.base].name),',',
        attributeForTypeAndValue(componentsTypes[1], componentData[1][s.eyes].name),',',
        attributeForTypeAndValue(componentsTypes[2], componentData[2][s.hair].name),',',
        attributeForTypeAndValue(componentsTypes[3], componentData[3][s.cloth].name),',',
        attributeForTypeAndValue(componentsTypes[4], componentData[4][s.boots].name),',',
        attributeForTypeAndValue(componentsTypes[5], componentData[5][s.hat].name),',',
        attributeForTypeAndValue(componentsTypes[6], componentData[6][s.beard].name),',',
        attributeForTypeAndValue(componentsTypes[7], componentData[7][s.shield].name),',',
        attributeForTypeAndValue(componentsTypes[8], componentData[8][s.weapon].name),',',
        attributeForTypeAndValue("charisma", s.charisma.toString()),','
      ));

    return string(abi.encodePacked(
      '[',
      components,
      '{"trait_type":"Generation","value":',
      _tokenId <= _getpaindTokens ? '"Gen 0"' : '"Gen 1"',
      '},{"trait_type":"Role","value":',
      b.showRole(s.role),
      '}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param _tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 _tokenId, ICharacter.Character memory s, uint256 _getpaindTokens) public view  returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      'Citizen #',
      _tokenId.toString(),
      '", "description": "Thousands of people in feudal age compete on a city in the metaverse. A tempting prize of $WHEAT awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Polygon blockchain.", "image": "data:image/svg+xml;base64,',
      b.base64(bytes(drawSVG(s))),
      '", "attributes":',
      compileAttributes(_tokenId,  s,  _getpaindTokens),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      b.base64(bytes(metadata))
    ));
  }
  function selectTrait(uint16 seed, uint8 traitType, uint8 _class) public view returns (uint8 traitId) 
    {
      traitId =  uint8(seed) % getComponentElemendIds(traitType);
     if(checkAllowedComponent(traitType, traitId, _class))
     {
       return traitId;
     }
     else
     {
       seed >>= 16;
       selectTrait(seed, traitType, _class);
     }
    }

    /**
   * selects the species and all of its traits based on the seed value
   * @return t -  a struct of randomly selected traits
   */
  function selectTraits(uint256 seed) public view returns (ICharacter.Character memory t) {  
    if(seed % 100 < 90) // %90 Peasant
    {
      t.role = 0;
    }
    else if(seed %100 < 99) // %9 Thief
    {
      t.role = 1;
    }
    else  // %1 Militia
    {
      t.role = 2;
    }

     seed >>= 16;
     t.base = selectTrait(uint16(seed & 0xFFFF), 0, t.role);
     t.charisma += uint256(getcomponentScore(0, t.base));
     seed >>= 16;
     t.eyes = selectTrait(uint16(seed & 0xFFFF), 1, t.role);
     t.charisma += uint256(getcomponentScore(1, t.eyes));
     seed >>= 16;
     t.hair = selectTrait(uint16(seed & 0xFFFF), 2, t.role);
     t.charisma += uint256(getcomponentScore(2, t.hair));
     seed >>= 16;
     t.cloth = selectTrait(uint16(seed & 0xFFFF), 3, t.role);
     t.charisma += uint256(getcomponentScore(3, t.cloth));
     seed >>= 16;
     t.boots = selectTrait(uint16(seed & 0xFFFF), 4, t.role);
     t.charisma += uint256(getcomponentScore(4, t.boots));
     seed >>= 16;
     t.hat = selectTrait(uint16(seed & 0xFFFF), 5, t.role);
     t.charisma += uint256(getcomponentScore(5, t.hat));
     seed >>= 16;
     t.beard = selectTrait(uint16(seed & 0xFFFF), 6, t.role);
     t.charisma += uint256(getcomponentScore(6, t.beard));
     seed >>= 16;
     t.shield = selectTrait(uint16(seed & 0xFFFF), 7, t.role);
     t.charisma += uint256(getcomponentScore(7, t.shield));
     seed >>= 16;
     t.weapon = selectTrait(uint16(seed & 0xFFFF), 8, t.role);
     t.charisma += uint256(getcomponentScore(8, t.weapon));
  }

  // Sending balance to another address, onlyOwner
    function SendTokens(address payable _to, uint256 _amount) public payable  onlyOwner{
        (bool sent, bytes memory data) = _to.call{value: _amount}("");
        emit Response(sent, data);
        require(sent, "Failed to send Ether");
    }
    
  // Default receive function
    receive() external payable {}
}