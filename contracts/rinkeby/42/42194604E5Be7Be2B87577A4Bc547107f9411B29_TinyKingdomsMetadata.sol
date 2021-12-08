// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TinyKingdoms
 * @dev Generates beautiful Tiny kingdoms metadata
 */


contract TinyKingdomsMetadata is Ownable {

    string public description;
    string public TinyKingdomsContract;
    
    address payable internal deployer;
    
    
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    constructor() Ownable()  {
        description = "Tiny Kingdoms Metadata";
        TinyKingdomsContract= "0x788defd1ae1e2299d54cf9ac3658285ab1da0900";
    }
    
    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }
    
    string[] private nouns = [ 
        "Eagle","Meditation","Folklore","Star","Light","Play","Palace","Wildflower","Rescue","Fish","Painting",
        "Shadow","Revolution","Planet","Storm","Land","Surrounding","Spirit","Ocean","Night","Snow","River",
        "Sheep","Poison","State","Flame","River","Cloud","Pattern","Water","Forest","Tactic","Fire","Strategy",
        "Space","Time","Art","Stream","Spectrum","Fleet","Ship","Spring","Shore","Plant","Meadow","System","Past",
        "Parrot","Throne","Ken","Buffalo","Perspective","Tear","Moon","Moon","Wing","Summer","Broad","Owls",
        "Serpent","Desert","Fools","Spirit","Crystal","Persona","Dove","Rice","Crow","Ruin","Voice","Destiny",
        "Seashell","Structure","Toad","Shadow","Sparrow","Sun","Sky","Mist","Wind","Smoke","Division","Oasis",
        "Tundra","Blossom","Dune","Tree","Petal","Peach","Birch","Space","Flower","Valley","Cattail","Bulrush",
        "Wilderness","Ginger","Sunset","Riverbed","Fog","Leaf","Fruit","Country","Pillar","Bird","Reptile","Melody","Universe",
        "Majesty","Mirage","Lakes","Harvest","Warmth","Fever","Stirred","Orchid","Rock","Pine","Hill","Stone","Scent","Ocean",
        "Tide","Dream","Bog","Moss","Canyon","Grave","Dance","Hill","Valley","Cave","Meadow","Blackthorn","Mushroom","Bluebell",
        "Water","Dew","Mud","Family","Garden","Stork","Butterfly","Seed","Birdsong","Lullaby","Cupcake","Wish",
        "Laughter","Ghost","Gardenia","Lavender","Sage","Strawberry","Peaches","Pear","Rose","Thistle","Tulip",
        "Wheat","Thorn","Violet","Chrysanthemum","Amaranth","Corn","Sunflower","Sparrow","Sky","Daisy","Apple",
        "Oak","Bear","Pine","Poppy","Nightingale","Mockingbird","Ice","Daybreak","Coral","Daffodil","Butterfly",
        "Plum","Fern","Sidewalk","Lilac","Egg","Hummingbird","Heart","Creek","Bridge","Falling Leaf","Lupine","Creek",
        "Iris Amethyst","Ruby","Diamond","Saphire","Quartz","Clay","Coal","Briar","Dusk","Sand","Scale","Wave","Rapid",
        "Pearl","Opal","Dust","Sanctuary","Phoenix","Moonstone","Agate","Opal","Malachite","Jade","Peridot","Topaz",
        "Turquoise","Aquamarine","Amethyst","Garnet","Diamond","Emerald","Ruby","Sapphire","Typha","Sedge","Wood"
    ];
    
    string[] private adjectives = [
        "Central","Free","United","Socialist","Ancient Republic of","Third Republic of",
        "Eastern","Cyber","Northern","Northwestern","Galactic Empire of","Southern","Solar",
        "Islands of","Kingdom of","State of","Federation of","Confederation of",
        "Alliance of","Assembly of","Region of","Ruins of","Caliphate of","Republic of",
        "Province of","Grand","Duchy of","Capital Federation of","Autonomous Province of",
        "Free Democracy of","Federal Republic of","Unitary Republic of","Autonomous Regime of","New","Old Empire of"
    ];
    
    
    string[] private suffixes = [
        "Beach", "Center","City", "Coast","Creek", "Estates", "Falls", "Grove",
        "Heights","Hill","Hills","Island","Lake","Lakes","Park","Point","Ridge",
        "River","Springs","Valley","Village","Woods", "Waters", "Rivers", "Points", 
        "Mountains", "Volcanic Ridges", "Dunes", "Cliffs", "Summit"
    ];

      
    string[4][21] private colors = [            
        ["#006D77", "#83C5BE", "#FFDDD2", "#faf2e5"],
        ["#351F39", "#726A95", "#719FB0", "#f6f4ed"],
        ["#472E2A", "#E78A46", "#FAC459", "#fcefdf"],
        ["#0D1B2A", "#2F4865", "#7B88A7", "#fff8e7"],
        ["#E95145", "#F8B917", "#FFB2A2", "#f0f0e8"],
        ["#C54E84", "#F0BF36", "#3A67C2", "#F6F1EC"],
        ["#E66357", "#497FE3", "#8EA5FF", "#F1F0F0"],
        ["#ED7E62", "#F4B674", "#4D598B", "#F3EDED"],
        ["#D3EE9E", "#006838", "#96CF24", "#FBFBF8"],
        ["#FFE8F5", "#8756D1", "#D8709C", "#faf2e5"],
        ["#533549", "#F6B042", "#F9ED4E", "#f6f4ed"],
        ["#8175A3", "#A3759E", "#443C5B", "#fcefdf"],
        ["#788EA5", "#3D4C5C", "#7B5179", "#fff8e7"],
        ["#553C60", "#FFB0A0", "#FF6749", "#f0f0e8"],
        ["#99C1B2", "#49C293", "#467462", "#F6F1EC"],
        ["#ECBFAF", "#017724", "#0E2733", "#F1F0F0"],
        ["#D2DEB1", "#567BAE", "#60BF3C", "#F3EDED"],
        ["#FDE500", "#58BDBC", "#EFF0DD", "#FBFBF8"],
        ["#2f2043", "#f76975", "#E7E8CB", "#faf2e5"],
        ["#5EC227", "#302F35", "#63BDB3", "#f6f4ed"],
        ["#75974a", "#c83e3c", "#f39140", "#fcefdf"]
    ];

    string [] private flags = [
        "Rising Sun", 
        "Vertical Triband", 
        "Chevron", 
        "Nordic Cross", 
        "Spanish Fess", 
        "Five Stripes", 
        "Hinomaru", 
        "Vertical Bicolor", 
        "Saltire", 
        "Horizontal Bicolor", 
        "Vertical Misplaced Bicolor", 
        "Bordure", 
        "Inverted Pall", 
        "Twenty-four squared", 
        "Diagonal Bicolor", 
        "Horizontal Triband", 
        "Diagonal Bicolor Inverse", 
        "Quadrisection", 
        "Diagonal Tricolor Inverse", 
        "Rising Split Sun", 
        "Lonely Star",  
        "Diagonal Bicolor Right", 
        "Horizontal Bicolor with a star", 
        "Bonnie Star",
        "Jolly Roger"
    ];


    uint256[3][6] private orders = [
        [1, 2, 3],
        [1, 3, 2],
        [2, 1, 3],
        [2, 3, 1],
        [3, 1, 2],
        [3, 2, 1]
    ];
    

    struct TinyFlag {
        string placeName;
        string flagName;
        
        uint256 themeIndex;
        uint256 orderIndex;
        uint256 flagIndex;

    }

    function getOrderIndex (uint256 tokenId) internal pure returns (uint256){
        uint256 rand = random(tokenId,"ORDER") % 1000;
        uint256  orderIndex= rand / 166;
        return orderIndex;
    
    }

    function getThemeIndex (uint256 tokenId) internal pure returns (uint256){
        uint256 rand = random(tokenId,"THEME") % 1050;
        uint256 themeIndex;

        if (rand<1000){themeIndex=rand/50;}
        else {themeIndex = 20;}
       
        return themeIndex;
    
    }
    
    function getFlagIndex(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(tokenId,"FLAG") % 1000;
        uint256 flagIndex =0;

        if (rand>980){flagIndex=24;}
        else {flagIndex = rand/40;}
        
        return flagIndex;
    }


    function getflagName(uint256 flagIndex) internal view returns (string memory) {       
        string memory f1 = flags[flagIndex];
        return string(abi.encodePacked(f1));
    }

     function getKingdom (uint256 tokenId, uint256 flagIndex) internal view returns (string memory) {
        uint256 rand = random(tokenId, "PLACE");
        
        
        string memory a1 = adjectives[(rand / 7) % adjectives.length];
        string memory n1 = nouns[(rand / 200) % nouns.length];
        string memory s1;

        if (flagIndex == 24) {
            s1 = "Pirate Ship";
        } else {
            s1 = suffixes[(rand /11) % suffixes.length];
        }
        
        string memory output= string(abi.encodePacked(a1,' ',n1,' ',s1));

    return output;

    }


    function randomFlag(uint256 tokenId) internal view returns (TinyFlag memory) {
        TinyFlag memory flag;
        
        flag.themeIndex= getThemeIndex(tokenId);
        flag.orderIndex = getOrderIndex(tokenId);
        flag.flagIndex = getFlagIndex(tokenId);
        
        flag.flagName = getflagName(flag.flagIndex);
        flag.placeName= getKingdom(tokenId, flag.flagIndex);

        return flag;
    }


    function kingdomName(uint256 tokenId) internal view returns (string memory) {
        uint256 flagIndex = getFlagIndex(tokenId);
        uint256 rand = random(tokenId, "PLACE");
        
        
        string memory a1 = adjectives[(rand / 7) % adjectives.length];
        string memory n1 = nouns[(rand / 200) % nouns.length];
        string memory s1;

        if (flagIndex == 24) {
            s1 = "Pirate Ship";
        } else {
            s1 = suffixes[(rand /11) % suffixes.length];
        }
        
        string memory output= string(abi.encodePacked(a1,' ',n1,' ',s1));
        return output;
    }
   
    function random(uint256 tokenId, string memory seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
    }
    

    function getFlagName(uint256 tokenId) public view returns (string memory){
        TinyFlag memory flag = randomFlag(tokenId);
        return flag.flagName;
    }

    function getKingdomName(uint256 tokenId) public view returns (string memory){
        return kingdomName(tokenId);
    }

    function getPalette(uint256 tokenId) public view returns (string [3] memory) {
        TinyFlag memory flag = randomFlag(tokenId);
        
        string[3] memory palette;
        
        palette[0] =colors[flag.themeIndex][orders[flag.orderIndex][0]-1];
        palette[1] =colors[flag.themeIndex][orders[flag.orderIndex][1]-1];
        palette[2] =colors[flag.themeIndex][orders[flag.orderIndex][2]-1];
        
        return palette;
    }
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