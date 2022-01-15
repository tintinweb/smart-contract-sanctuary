/**
 *Submitted for verification at polygonscan.com on 2022-01-15
*/

// File: contracts/IStructs.sol



pragma solidity ^0.8.0;

interface IStructs {
    struct Sentry {
        uint16 id; 
        uint8 generation;
        // 0=Human, 1=cyborg, 2=alien
        uint8 species;
        uint8 attack;
        uint8 defense; 
        uint8 luck;
        bool infected;
        Traits traits;
    }
    struct Traits{
        uint8 body;
        uint8 clothes; 
        uint8 suit;
        uint8 accessory; 
        uint8 backpack; 
        uint8 eyewear; 
        uint8 weapon;
    }

    struct GameplayStats {
      uint16 sentryId;
      bool isDeployed;
      uint8 riskCode;
      uint cooldownTimestamp;
      uint16 daysSurvived;
      uint16 longestStreak;
      uint deploymentTimestamp;
      uint16 successfulAttacks;
      uint16 successfulDefends;
    }


    struct DeploymentParty {
        uint id;
        uint16[] listOfIds;
        uint8 activeMembers;
        address leaderAddress;
        bool isDeployed;
    }
}
// File: contracts/ISentryFactory.sol



pragma solidity ^0.8.0;


interface ISentryFactory is IStructs  {
    // Interface used by gameplay contract
    // Need to get traits for gameplay RNG
    // Need owner to return $BITS upond evac
    
    // get owner address of a sentry
    function getSentryOwner(uint16) external view returns (address);

    // retrieve sentry traits for gameplay
    function getSentryTraits(uint16) external view returns (Sentry memory);
    // get number of sentries byy owner
    // ensures an address actually owns a token
    function getOwnerSentryCount(address) external view returns (uint);


    // Infect sentry
    // Called by gameplay
    function infectSentry(uint16 ) external;
}
// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: contracts/Traits.sol


pragma solidity ^0.8.0;





contract SentryTraits is Ownable, IStructs {
    using Strings for uint256;

    uint nonce;

    // First map = layer type, ie:background, species, etc
    // Second map = rarity inducer 
    // A
    struct Layer {string name; string png;}
    mapping(uint8 => mapping(uint8 => mapping(uint8 => Layer))) public layers;
    mapping(uint8 => mapping(uint8 => uint8)) public layerCount;
    // MAPPING ORDER GOES: SPECIES => LAYER CATEGORY => Layer
    // example: 0(human)=>1(body)=>2(black male)

    // mapping(uint8 => mapping(uint8 => uint8)) public rarities;
    // // rarities will be shared across species (each species will have high med low rarity items with same rng roll)
    // // rarity initial mapping matches to the initial mapping of layers
    //     //So rarities for each category can easily be accessed

    // layers will be hard coded with certain indeces pertaining only to certain species
    // 0 = background
        // 0 = forrest
        // 1 = city
        // 2 = caves
    // 1 = body (spans of indeces due to variable bodies)
        // 0 - 4 = human
        // 5 - 9 = cyborg
        // 10 - 14 = alien
    // 2 - clothing tops
        // 0 - 4 = human
        // 5 - 9 = cyborg
        // 10 - 14 = alien ALL ALIEN SUITS CONSIDERED TOPS
    // 3 = accesory
        // 20 cap (all inclusive)
    // 4 - Energy suit
        // 0 = no 1 = yes
    // 5 - backpack
    // 6 - eyewear
    // 7 = weapon
        // 0 - 9 = human
        // 10 - 19 = cyborg
        // 20 - 29 = alien

    ISentryFactory public factory;
    mapping(address => bool) private controllers;

    modifier onlyController() {
        require(controllers[msg.sender], "You cannot do this!");
        _;
    }
    function toggleController(address _address) external onlyOwner {
        controllers[_address] = !controllers[_address];
    }

    constructor() {
        nonce = 0;
    }

    function indexOffset(uint species, uint offset) public pure returns (uint) {
        uint mult;
        if(species == 1) {
            mult = 1;
        } else if (species == 2) {
            mult = 2;
        } 
        return offset*mult;
    }

    function generateStat(uint min) public returns (uint8) {
        uint randomInt = random(100);
        uint8 base;
        if(randomInt <= 1) {
            base = 90;
        } else if(randomInt <=4){
            base = 80;
        } else if(randomInt <=9){
            base = 70;
        } else if(randomInt <=16){
            base = 60;
        } else if(randomInt <=25){
            base = 50;
        } else if(randomInt <=36){
            base = 40;
        } else if(randomInt <=49){
            base = 30;
        } else if(randomInt <=64){
            base = 20;
        } else if(randomInt <=81){
            base = 10;
        } else {
            base = 0;
        }
        uint8 stat = base + uint8(random(10));
        if(stat < min) {
            return uint8(min);
        }
        return stat;
    }
// TypeError: Member "length" not found or not visible after argument-dependent lookup in mapping(uint8 => struct Traits.Layer storage ref).
    function rerollSentry(Sentry memory sentry) external onlyController returns(Sentry memory) {
        sentry.attack =generateStat(0);
        sentry.defense =generateStat(0);
        sentry.luck =generateStat(0);
        return sentry;
    }


    function assembleTraits(uint8 species, uint8 gen, bool infected) external onlyController returns (Traits memory) {
        Traits memory newTraits = Traits(
            generateRarity(layerCount[species][1]),
            generateRarity(layerCount[species][2]),
            gen == 0 ? 0 : 1,
            generateRarity(layerCount[species][3]),
            generateRarity(layerCount[species][4]),
            generateRarity(layerCount[species][5]),
            generateRarity(layerCount[species][6])
        );
        return newTraits;
    }

    function generateRarity(uint max) private returns (uint8) {
        if(max == 0) {return 0;}
        uint cap = max*max;
        uint randomInt = random(cap);
        for(uint8 i = 0; i <= max; i++) {
            if(randomInt <= (i*i)) {
                return i;
            }
        }
        return uint8(max);
    }

    function _drawLayer(Layer memory layer) internal pure returns (string memory) {
        return string(abi.encodePacked(
        '<image x="4" y="4" width="32" height="32" preserveAspectRatio="xMidYMid" xlink:href="',
        layer.png,
        '"/>'
        ));
    }


    // URI/Attribute Render
    // Build SVG image from tokenID and DNA
    // Manipulate for infected/non states
    function buildImage(uint16 _tokenId) public view returns(string memory) {
        // uint currentWord = _tokenId;
        Sentry memory sentry = factory.getSentryTraits(_tokenId);
        string memory svg;
        svg = string(abi.encodePacked(
            _drawLayer(layers[sentry.species][0][0]),
            _drawLayer(layers[sentry.species][1][sentry.traits.body]),
            _drawLayer(layers[sentry.species][2][sentry.traits.clothes]),
            _drawLayer(layers[sentry.species][3][sentry.traits.suit]),
            _drawLayer(layers[sentry.species][4][sentry.traits.accessory]),
            _drawLayer(layers[sentry.species][5][sentry.traits.backpack]),
            _drawLayer(layers[sentry.species][6][sentry.traits.eyewear]),
            _drawLayer(layers[sentry.species][7][sentry.traits.weapon])

        ));
        return string(abi.encodePacked(
            '<svg width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            svg,
            "</svg>"
        ));
    }


    function _sintleAttributeCompilation(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
        '{"trait_type":"', traitType,
        '","value":"', value,
        '"}'
        ));
    }
    function _singleStatBuild(string memory stat, uint8 value) internal pure returns (string memory) {
        return string(abi.encodePacked(
        '{"trait_type":"', stat,
        '","value":"', uint256(value).toString(),
        '"}'
        ));
    }

    function _compileAttributes(uint16 tokenId) public view returns (string memory) {
        Sentry memory sentry = factory.getSentryTraits(tokenId);
        Traits memory sentryTraits = sentry.traits;
        // Traits memory sentryTraits = Traits(0,0,0,0,0,0,0,0);
        uint8 species = 0;
        string memory traits = string(abi.encodePacked(
            _sintleAttributeCompilation("Background",   layers[sentry.species][0][0].name), ",", 
            _sintleAttributeCompilation("Body",  layers[sentry.species][1][sentryTraits.body].name), ",",
            _sintleAttributeCompilation("Clothing", layers[sentry.species][2][sentryTraits.clothes].name), ",",
            _sintleAttributeCompilation("Suit",  layers[sentry.species][3][sentryTraits.suit].name), ",",
            _sintleAttributeCompilation("Accessory",  layers[sentry.species][4][sentryTraits.accessory].name), ",",
            _sintleAttributeCompilation("Backpack",  layers[sentry.species][5][sentryTraits.backpack].name), ",",
            _sintleAttributeCompilation("Eyewear",  layers[sentry.species][6][sentryTraits.eyewear].name), ",",
            _sintleAttributeCompilation("Weapon",  layers[sentry.species][7][sentryTraits.weapon].name), ",",
            _singleStatBuild("Attack", sentry.attack), ",",
            _singleStatBuild("Defense", sentry.defense), ",",
            _singleStatBuild("Luck", sentry.luck), ","
        ));
        return string(abi.encodePacked(
        '[',
            traits,
            '{"trait_type":"Species","value":', species == 0 ? '"Human"' :  species == 1 ? '"Cyborg"' :'"Alien"',
            '},{"trait_type":"Type","value":"', 'da',
        '"}]'
        ));
    }


    // Relay metadata as json
    // SVG and attributes are passed in from functions
    function buildMetadata(uint16 _tokenId) public view returns(string memory) {
        // uint currentWord = 1;
        return string(abi.encodePacked(
                'data:application/json;base64,', _base64(bytes(abi.encodePacked(
                            '{"name":"', 
                            'Sentry #', uint256(_tokenId).toString(), 
                            '", "description":"', 
                            'The last stand against the MATIC virus. Sentries are augmented soldiers designed to defend Polygonia by any means necessary.',
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            _base64(bytes(buildImage(_tokenId))),
                            '", "attributes":"',
                            _compileAttributes(_tokenId),
                            '"}'
        )))));
    }

    function uploadTraits(uint8 species,uint8 layerCategory, uint8[] calldata layerIds, string[][] calldata newLayers) external onlyOwner {
        require(layerIds.length == newLayers.length, "Mismatched inputs");
        for (uint8 i = 0; i < newLayers.length; i++) {
            layers[species][layerCategory][layerIds[i]] = Layer(
                newLayers[i][0],
                newLayers[i][1]
            );
        }
        layerCount[species][layerCategory] = uint8(layerIds.length + layerCount[species][layerCategory]);
    }

    function clearLayersOfType(uint8 species, uint8 layerCategory, uint8 maxIndex) external onlyOwner {
        for(uint8 i = 0; i < maxIndex; i++) {
            layers[species][layerCategory][i] = Layer("","");
        }
        layerCount[species][layerCategory] = 0;
    }

    function random(uint max) internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % max;
        nonce++;
        return randomnumber;
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

//   only owner
    function setFactory(address _address) external onlyOwner {
        factory = ISentryFactory(_address);
    }
}