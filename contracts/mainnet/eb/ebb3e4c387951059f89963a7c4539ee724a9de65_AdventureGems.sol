// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * @title AdventureGems contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract AdventureGems is ERC721, ReentrancyGuard, Ownable {
    
    uint256 public s_publicPrice = 20000000000000000; //0.02 ETH
    bool public s_isPrivateSale = true;

    mapping(uint256=>uint256) private s_randomSeeds;
    //Loot Interface
    LootInterface lootContract;
        
    struct gemDataStruct {
        string condition;
        string stone;
        string size;
        string suffix;
        string cut;
        string jewelryType;
        string power;
        string protection;
        string effect;
        string colourHSL;
        string blessing;
    }

    constructor(address p_loot) ERC721("Adventure Gems for Loot", "ADVGEM") {
        lootContract = LootInterface(p_loot);
    }
    
    function setLootContract (address p_lootContract) onlyOwner external {
        lootContract = LootInterface(p_lootContract);
    }
    
    /* GET FUNCTIONS */
    
    function getGemStone(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");           
        uint256 gemId = findGemId(p_tokenId, "GEMSTONE");
        string[8] memory gemStoneNames = [
            "Blue Diamond",
            "Pink Diamond",
            "Diamond",
            "Ruby",
            "Emerald",
            "Sapphire",            
            "Jade",
            "Opal"
        ];
        return gemStoneNames[gemId];
    }
        
    function getGemCondition(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");         
        uint256 conditionId = findGemId(p_tokenId, "CONDITION");
        string[8] memory gemConditionNames = [
            "Divine",
            "Sacred",
            "Legendary",
            "Sterling",
            "Brilliant",
            "Radiant",
            "Shiny",
            "Worn"
        ];
        return gemConditionNames[conditionId];
    }
    
    function getGemSize(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");           
        uint256 gemSizeId = findGemId(p_tokenId, "GEMSIZE");
        string[8] memory gemSizes = [
            "Huge",
            "Large",
            "Larger than average",
            "Average",
            "Average",
            "Smaller than average",       
            "Small",
            "Tiny"
        ];
        return gemSizes[gemSizeId];
    }
    
    function getGemColourHSL(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");          
        uint256 conditionId = findGemId(p_tokenId, "CONDITION");
        uint256 gemId = findGemId(p_tokenId, "GEMSTONE");
        uint8[8] memory gemSaturations = [
            100, // Divine
            80, // Blessed
            70, // Sacred
            60, // Exalted
            50, // Brilliant
            40, // Radiant
            30, // Shiny
            20 // Worn
        ];
        uint16[8] memory gemHues = [
            220, // Blue diamond
            300, // Pink diamond
            0, // Diamond
            0, // Ruby
            120, // Emerald
            40, // Sapphire
            180, // Jade
            20 // Opal
        ];
        uint8[8] memory gemLightnesses = [
            50, // Blue diamond
            50, // Pink diamond
            100, // Diamond
            50, // Ruby
            50, // Emerald
            50, // Sapphire
            50, // Jade
            80 // Opal
        ];

        string memory output = string(abi.encodePacked(toString(uint256(gemHues[gemId])),
            ',',
            toString(uint256(gemSaturations[conditionId])),
            '%,',
            toString(uint256(gemLightnesses[gemId])),
            '%'));
        return output;
    }
    
    function getGemPowerSuffix(uint256 p_tokenId) public view returns (string memory) {
       require(_exists(p_tokenId),"Not minted");       
        uint256 powerId = findGemPowerId(p_tokenId, "POWER");
        string[13] memory gemPowerNames = [
            "the Gods",
            "Eternal Youth",
            "Healing Light",
            "the Warrior",
            "Dexterity",
            "Thieves",
            "Fortune",
            "Ancient Wisdom",
            "Immolation",
            "Thunder",
            "the Seas",
            "the Skies",
            "the Earth"
        ];
        return gemPowerNames[powerId];
    }
    
    function getGemPower(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");        
        uint256 powerId = findGemPowerId(p_tokenId, "POWER");
        string[13] memory gemBoost = [
            "Wisdom",
            "Charisma",
            "Constitution",
            "Strength",
            "Dexterity",
            "Stealth",
            "Critical Strikes",
            "Intelligence",
            "Fire dmg",
            "Lightning dmg",
            "Water dmg",
            "Wind dmg",
            "Earth dmg"];
        return gemBoost[powerId];
    }
    
    function getGemProtection(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");        
        uint256 powerId = findGemPowerId(p_tokenId, "PROTECT");
        string[13] memory gemProtection = [
            "Magic",
            "Encounters",
            "Critical Strikes",
            "Poison",
            "Blunt Weapons",
            "Ranged Weapons",
            "Confusion",
            "Fire",
            "Lightning",
            "Water",
            "Wind",
            "Earth",
            "Stealing"
            ];
        return gemProtection[powerId];
    }
    
    function getGemEffect(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string[17] memory gemEffect = [
            "looks indestructible",
            "hypnotizes",
            "entrances",
            "whispers eerily",
            "glows under the moon",
            "looks a bit scary",
            "glows in the dark",
            "feels hot",
            "feels cold",
            "glows under a full moon",
            "looks durable",
            "feels heavy",
            "feels light",
            "vibrates",
            "resists water",
            "looks otherworldy",
            "smells strange"];
        uint256 rand = random(abi.encodePacked("EFFECT", s_randomSeeds[p_tokenId]));
        uint256 effectId = (rand % gemEffect.length);
        return gemEffect[effectId];
    }
    
    function getGemCut(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string[10] memory gemCuts = [
            "Heart",
            "Teardrop",
            "Oval",
            "Round",
            "Rectangular",
            "Triangle",
            "Hexagon",
            "Trillion",
            "Octagon",
            "Marquise"
            ];
        uint256 rand = random(abi.encodePacked("CUT", s_randomSeeds[p_tokenId]));
        uint256 cutId = (rand % gemCuts.length);
        return gemCuts[cutId];
    }
    
    function getGemBlessing(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string memory output="No blessing";
        uint256 conditionId = findGemId(p_tokenId, "CONDITION");
        // Only for divine gems
        if (conditionId==0) {
            string[10] memory rarities = [
            "Scares away monsters",
            "Doubles stamina",
            "Doubles damage output",
            "Attracts monsters",
            "Doubles move speed",
            "Grants fire immunity",
            "Dodges critical strikes",
            "Regenerates health",
            "Doubles earned experience",
            "Doubles gold drops"
            ];
            uint256 rand = random(abi.encodePacked("BLESSING", s_randomSeeds[p_tokenId]));
            uint256 rarityId = (rand % rarities.length);
            output = rarities[rarityId];
        }
        return output;
    }
    
    
    function getJewelryType(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string[7] memory jewelryTypes = [
            "Amulet",
            "Ring",
            "Necklace",
            "Pendant",
            "Bracelet",
            "Earring",
            "Locket"];
        uint256 rand = random(abi.encodePacked("JEWEL", s_randomSeeds[p_tokenId]));
        uint256 r_attrId = (rand % jewelryTypes.length);
        return jewelryTypes[r_attrId];
    }  

    // FINDER functions
    // Find Gem Id can find anything from an array with 8 elements (note: weighting table in place)
    function findGemId(uint256 p_tokenId, string memory p_seedString) internal view returns (uint256) {
        uint8[8] memory weightings = [
            1,
            2,
            4,
            8,
            16,
            32,
            56,
            78
        ];
        uint256 rand = random(abi.encodePacked(p_seedString, s_randomSeeds[p_tokenId]));
        uint256 weighting = (rand % 100)+1;
        uint256 r_attrId = weightings.length-1;
        for (uint i=0; i<weightings.length-1; i++) {
            if (weighting>=weightings[i] && weighting<weightings[i+1]) {
                r_attrId = i;
            }
        }
        return r_attrId;
    }
    
    // Find Gem Power can find anything from an array with 13 elements (note: weighting table in place)
    function findGemPowerId(uint256 p_tokenId, string memory p_seedPhrase) internal view returns (uint256) {
         uint8[13] memory weightings = [
            1,
            4,
            7,
            10,
            15,
            20,
            25,
            30,
            45,
            55,
            65,
            75,
            85
        ];
        uint256 rand = random(abi.encodePacked(p_seedPhrase, s_randomSeeds[p_tokenId]));
        uint256 weighting = (rand % 100)+1;
        uint256 r_attrId = weightings.length-1;
        for (uint i=0; i<weightings.length-1; i++) {
            if (weighting>=weightings[i] && weighting<weightings[i+1]) {
                r_attrId = i;
            }
        }
        return r_attrId;
    }
    
    
    /* Token URI encoder */

    function tokenURI(uint256 p_tokenId) override public view returns (string memory) {
        gemDataStruct memory gemData;

        gemData.condition = getGemCondition(p_tokenId);
        gemData.stone = getGemStone(p_tokenId);
        gemData.size = getGemSize(p_tokenId);
        gemData.suffix = getGemPowerSuffix(p_tokenId);
        gemData.cut = getGemCut(p_tokenId);
        gemData.jewelryType = getJewelryType(p_tokenId);
        gemData.power = getGemPower(p_tokenId);
        gemData.protection = getGemProtection(p_tokenId);
        gemData.effect = getGemEffect(p_tokenId);
        gemData.colourHSL = getGemColourHSL(p_tokenId);
        gemData.blessing = getGemBlessing(p_tokenId);
        
        string memory output;

        // Need to do this to prevent stack depth errors
        output = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }.colored { fill:hsl(',
            gemData.colourHSL,
            ')}</style><rect width="100%" height="100%" fill="black" stroke="hsl(',
            gemData.colourHSL,
            ')" stroke-width="5px" /><text x="10" y="20" class="base colored" font-weight="bold">',
            string(abi.encodePacked(gemData.condition," ",gemData.stone," ",gemData.jewelryType," of ", gemData.suffix)),
            '</text><text x="10" y="60" class="base colored">',
            gemData.stone,
            '</text><text x="10" y="80" class="base">'
        ));

        output = string(abi.encodePacked(
            output,
            gemData.condition,
            '</text><text x="10" y="100" class="base">',
            gemData.size,
            '</text><text x="10" y="120" class="base">',
            gemData.cut,
            '</text><text x="10" y="140" class="base">',
            gemData.jewelryType,
            '</text><text x="10" y="180" class="base">Boosts ',
            gemData.power,
            '</text><text x="10" y="200" class="base">Protects against '));

        output = string(abi.encodePacked(
            output,
            gemData.protection,
            '</text><text x="10" y="220" class="base">It ',
            gemData.effect,
            '</text><text x="10" y="260" class="base colored">',
            gemData.blessing,            
            '</text><text text-anchor="end" x="95%" y="95%" class="base">#',
            toString(p_tokenId),
            '</text></svg>'));

        string memory attributes = string(abi.encodePacked(
            '{"trait_type":"gem","value":"',gemData.stone,
            '"},{"trait_type":"condition","value":"',gemData.condition,
            '"},{"trait_type":"cut","value":"',gemData.cut,
            '"},{"trait_type":"jewelry","value":"',gemData.jewelryType,
            '"},{"trait_type":"namesuffix","value":"',gemData.suffix,
            '"},{"trait_type":"power","value":"',gemData.power,
            '"},{"trait_type":"protection","value":"',gemData.protection
        ));
        
        attributes = string(abi.encodePacked(
            attributes,
            '"},{"trait_type":"effect","value":"',gemData.effect,
            '"},{"trait_type":"size","value":"',gemData.size,
            '"},{"trait_type":"blessing","value":"',gemData.blessing,'"}'
        ));
            
    
        string memory json = Base64.encode(bytes(
            string(abi.encodePacked(
                '{"name": "Jewelry #', 
                toString(p_tokenId),
                '","description": "Loot Jewels for Adventurers are generated and stored on chain. Stats, images, and other functionality are omitted for others to interpret. Use however you want.",', 
                '"image": "data:image/svg+xml;base64,', 
                Base64.encode(bytes(output)),
                '","attributes": [', attributes, ']}'
            ))
        ));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    
    // Loot minting (free)
    function mintWithLoot(uint p_lootId) public payable nonReentrant {
        require(lootContract.ownerOf(p_lootId) == msg.sender, "Not loot owner");
        _safeMint(msg.sender, p_lootId);
        s_randomSeeds[p_lootId] = uint256(blockhash(block.number - 2))
            ^ block.timestamp
            ^ block.difficulty 
            ^ p_lootId
            ^ block.basefee
            ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
    }
    
    function multiMintWithLoot(uint[] memory p_lootIds) public payable nonReentrant {
        for (uint i=0; i<p_lootIds.length; i++) {
            require(lootContract.ownerOf(p_lootIds[i]) == msg.sender, "Not loot owner");
            _safeMint(msg.sender, p_lootIds[i]);
            s_randomSeeds[p_lootIds[i]] = uint256(blockhash(block.number - 2))
                ^ block.timestamp 
                ^ block.difficulty 
                ^ p_lootIds[i] 
                ^ block.basefee
                ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
        }
    }
    
    // Public minting
    function mint(uint p_tokenId) public payable nonReentrant {
        require(s_publicPrice <= msg.value, "Insufficient Ether");
        if (s_isPrivateSale){
            require(p_tokenId > 8000 && p_tokenId <= 12000, "Token ID invalid");
        } else {
            require(p_tokenId > 0 && p_tokenId <= 12000, "Token ID invalid");
        }
        _safeMint(msg.sender, p_tokenId);
        s_randomSeeds[p_tokenId] = uint256(blockhash(block.number - 2))
            ^ block.timestamp
            ^ block.difficulty
            ^ p_tokenId
            ^ block.basefee
            ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
    }
    
    function multiMint(uint[] memory p_tokenIds) public payable nonReentrant {
        require((s_publicPrice * p_tokenIds.length) <= msg.value, "Insufficient Ether");
        
        for (uint i=0; i<p_tokenIds.length; i++) {
            if (s_isPrivateSale){
                require(p_tokenIds[i] > 8000 && p_tokenIds[i] <= 12000, "Token ID invalid");
            } else {
                require(p_tokenIds[i] > 0 && p_tokenIds[i] <= 12000, "Token ID invalid");
            }
            _safeMint(msg.sender, p_tokenIds[i]);
            s_randomSeeds[p_tokenIds[i]] = uint256(blockhash(block.number - 2))
                ^ block.timestamp
                ^ block.difficulty
                ^ p_tokenIds[i]
                ^ block.basefee
                ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
        }
    }    
    
    // Owner reserved minting (100 items)
     function ownerMint(uint p_tokenId) public payable nonReentrant onlyOwner {
         require(p_tokenId > 12000 && p_tokenId <= 12100, "Token ID invalid");
        _safeMint(msg.sender, p_tokenId);         
        s_randomSeeds[p_tokenId] =  uint256(blockhash(block.number - 2))
            ^ block.timestamp
            ^ block.difficulty
            ^ p_tokenId
            ^ block.basefee
            ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
        
     }
    
    /* UTILITY FUNCTIONS */
    
    function flipPrivateSale() external onlyOwner {
        s_isPrivateSale = !s_isPrivateSale;
    }
    
    function setPrice(uint256 p_newPrice) external onlyOwner {
        s_publicPrice = p_newPrice;
    }
    
    function random(bytes memory p_input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(p_input)));
    }
    
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function deposit() public payable onlyOwner {}


    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

