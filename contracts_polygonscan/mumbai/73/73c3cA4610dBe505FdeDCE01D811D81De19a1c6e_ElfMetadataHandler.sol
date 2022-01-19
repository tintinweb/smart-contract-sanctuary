// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

//import "hardhat/console.sol";
/// @notice BASED ON ETHERORCS INVENTORY MANAGER.

import "./DataStructures.sol";

contract ElfMetadataHandler {
    using DataStructures for DataStructures.Token;

    address impl_;
    address public manager;

    enum Part {
        race,
        hair,
        primaryWeapon,
        accessories
    }

    mapping(uint8 => address) public race;
    mapping(uint8 => address) public hair;
    mapping(uint8 => address) public primaryWeapon;
    mapping(uint8 => address) public accessories;

    struct Attributes {
        uint8 hair; //MAX 3
        uint8 race; //MAX 6 Body
        uint8 accessories; //MAX 7
        uint8 sentinelClass; //MAX 3
        uint8 weaponTier; //MAX 6
        uint8 inventory; //MAX 7
    }

    string public constant header =
        '<svg id="elf" width="100%" height="100%" version="1.1" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer =
        "<style>#elf{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

    function getSVG(
        uint8 race_,
        uint8 hair_,
        uint8 primaryWeapon_,
        uint8 accessories_
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    header,
                    get(Part.race, race_),
                    get(Part.hair, hair_),
                    primaryWeapon_ > 0
                        ? get(Part.primaryWeapon, primaryWeapon_)
                        : "",
                    //  get(Part.accessories, accessories_),
                    footer
                )
            );
    }

    constructor() {
        manager = msg.sender;
    }

    function getTokenURI(uint16 id_, uint256 sentinel)
        external
        view
        returns (string memory)
    {
        DataStructures.Token memory token = DataStructures.getToken(sentinel);

        //Attributes memory attributes = unPackAttributes(traits_, class_);
        

        string memory svg = Base64.encode(
            bytes(
                getSVG(
                    token.race,
                    token.hair,
                    token.primaryWeapon,
                    token.accessories
                )
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Elf #',
                                toString(id_),
                                '", "description":"EthernalElves is a collection of 6666. With no IPFS or API, these Elves a 100% on-chain. Play EthernalElves to upgrade your abilities and grow your army. !onward", "image": "',
                                "data:image/svg+xml;base64,",
                                svg,
                                '",',
                                getAttributes(
                                    token.race,
                                    token.hair,
                                    token.primaryWeapon,
                                    token.accessories,
                                    token.level,
                                    token.healthPoints,
                                    token.attackPoints,
                                    token.sentinelClass
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                    INVENTORY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setRace(uint8[] calldata ids, address source) external {
        require(msg.sender == manager);

        for (uint256 index = 0; index < ids.length; index++) {
            race[ids[index]] = source;
        }
    }

    function setHair(uint8[] calldata ids, address source) external {
        require(msg.sender == manager);

        for (uint256 index = 0; index < ids.length; index++) {
            hair[ids[index]] = source;
        }
    }

    function setWeapons(uint8[] calldata ids, address source) external {
        require(msg.sender == manager);

        for (uint256 index = 0; index < ids.length; index++) {
            primaryWeapon[ids[index]] = source;
        }
    }

    function setAccessories(uint8[] calldata ids, address source) external {
        require(msg.sender == manager);

        for (uint256 index = 0; index < ids.length; index++) {
            accessories[ids[index]] = source;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function call(address source, bytes memory sig)
        internal
        view
        returns (string memory svg)
    {
        (bool succ, bytes memory ret) = source.staticcall(sig);
        require(succ, "failed to get data");

        svg = abi.decode(ret, (string));
    }

    function get(Part part, uint8 id)
        internal
        view
        returns (string memory data_)
    {
        address source = part == Part.race ? race[id] : part == Part.hair
            ? hair[id]
            : part == Part.primaryWeapon
            ? primaryWeapon[id]
            : accessories[id];

        data_ = wrapTag(call(source, getData(part, id)));

        return data_;
    }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="1" y="1" width="128" height="128" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    uri,
                    '"/>'
                )
            );
    }

    function getData(Part part, uint8 id)
        internal
        pure
        returns (bytes memory data)
    {
        string memory s = string(
            abi.encodePacked(
                part == Part.race ? "race" : part == Part.hair
                    ? "hair"
                    : part == Part.primaryWeapon
                    ? "weapon"
                    : "accessory",
                toString(id),
                "()"
            )
        );

        return abi.encodeWithSignature(s, "");
    }

    function unPackAttributes(uint256 _trait, uint256 _class)
        internal
        pure
        returns (Attributes memory _attributes)
    {
        _attributes.hair = uint8((_trait / 100) % 10);
        _attributes.race = uint8((_trait / 10) % 10);
        _attributes.accessories = uint8((_trait) % 10);
        _attributes.sentinelClass = uint8((_class / 100) % 10);
        _attributes.weaponTier = uint8((_class / 10) % 10);
        _attributes.inventory = uint8((_class) % 10);

        ///Convert from key/value to class based index
        _attributes.hair =
            (_attributes.sentinelClass * 3) +
            (_attributes.hair + 1);
        _attributes.race =
            (_attributes.sentinelClass * 4) +
            (_attributes.race + 1);
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

    function getAttributes(
        uint8 race_,
        uint8 hair_,
        uint8 primaryWeapon_,
        uint8 accessories_,
        uint8 level_,
        uint8 healthPoints_,
        uint8 attackPoints_,
        uint8 sentinelClass_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"attributes": [',
                    getClassAttributes(sentinelClass_),
                    ",",
                    getRaceAttributes(race_),
                    ",",
                    getHairAttributes(hair_),
                    ",",
                    getPrimaryWeaponAttributes(primaryWeapon_),
                    ",",
                    getOffhandAttributes(accessories_),
                    ',{"trait_type": "Level", "value":',
                    toString(level_),
                    '},{"display_type": "boost_number","trait_type": "Attack Points", "value":',
                    toString(attackPoints_),
                    '},{"display_type": "boost_number","trait_type": "Health Points", "value":',
                    toString(healthPoints_),
                    "}]"
                )
            );
    }

    function getClassAttributes(uint8 sentinelClass_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Class","value":"',
                    getClassName(sentinelClass_),
                    '"}'
                )
            );
    }

    function getRaceAttributes(uint8 race_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Race","value":"',
                    getRaceName(race_),
                    '"}'
                )
            );
    }

    function getHairAttributes(uint8 hair_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Hair","value":"',
                    getHairName(hair_),
                    '"}'
                )
            );
    }

    function getPrimaryWeaponAttributes(uint8 primaryWeapon_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Weapon","value":"',
                    getPrimaryWeapon(primaryWeapon_),
                    '"},{"display_type":"number","trait_type":"Weapon Tier","value":',
                    toString(getWeaponTier(primaryWeapon_)),
                    "}"
                )
            );
    }

    function getOffhandAttributes(uint8 accessory_)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Accessory","value":"',
                    getOffhandName(accessory_),
                    '"}'
                )
            );
    }

    function getTier(uint16 id) internal pure returns (uint16) {
        if (id > 40) return 100;
        if (id == 0) return 0;
        return ((id - 1) / 4);
    }

    function getWeaponTier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        id = id - 1;
        id = id / 3;
        id = id + 1;

        return (id);
    }

    // Here, we do sort of a Binary Search to find the correct name. Not the pritiest code I've wrote, but hey, it works!
    function getClassName(uint8 id)
        public
        pure
        returns (string memory className)
    {
        className = id == 0 ? "Druid" : id == 1 ? "Assassin" : "Range";
    }

    function getRaceName(uint8 id)
        public
        pure
        returns (string memory raceName)
    {
        raceName = id == 0 ? "Darkborne" : id == 1 ? "Lightborne" : id == 2
            ? "Primeborne"
            : "Woodborne";
    }

    function getHairName(uint8 id)
        public
        pure
        returns (string memory raceName)
    {
        raceName = id == 0 ? "Brown" : id == 1 ? "White" : "Dark";
    }

    function getPrimaryWeapon(uint8 id) public pure returns (string memory) {
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Pickaxe" : "Nothing";
                    }
                    return id == 3 ? "Club" : "Pleb Staff";
                }
                if (id < 7) return id == 5 ? "Short Sword +1" : "Dagger +1";
                return
                    id == 7 ? "Simple Axe +1" : id == 8
                        ? "Fiery Poker +1"
                        : "Large Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Iron Hammer +2" : id == 11
                            ? "Iron Mace +2"
                            : "Jagged Axe +2";
                }
                return
                    id == 13 ? "Enchanted Poker +3" : id == 14
                        ? "Curved Sword +3"
                        : "Ultra Mallet +3";
            }
            if (id < 18)
                return id == 16 ? "Disciple Staff +3" : "Assassin Blade +4";
            return id == 18 ? "Swamp Staff +4" : "Simple Wand +4";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Royal Blade +4" : id == 21
                            ? "Skull Shield +5"
                            : "Skull Crusher Axe +5";
                }
                return id == 23 ? "Flaming Staff +5" : "Flaming Royal Blade +5";
            }

            if (id < 27)
                return id == 25 ? "Berserker Sword +6" : "Necromancer Staff +6";
            return
                id == 27 ? "Flaming Skull Shield +6" : id == 28
                    ? "Frozen Scythe +6"
                    : "Blood Sword +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return
                    id == 30 ? "Dark Lord Staff +7" : id == 31
                        ? "Bow of Artemis +7"
                        : "Ice Sword +7";
            }
            return
                id == 33 ? "Cryptic Staff +8" : id == 34
                    ? "Nether Lance +8"
                    : "Demonic Axe +8";
        }

        if (id <= 40) {
            if (id < 39) {
                return
                    id == 36 ? "Royal Blade +4" : id == 37
                        ? "Skull Shield +5"
                        : "Skull Crusher Axe +5";
            }
            return id == 39 ? "Flaming Staff +5" : "Flaming Royal Blade +5";
        }
        if (id <= 45) {
            if (id < 44) {
                return
                    id == 41 ? "Royal Blade +4" : id == 42
                        ? "Skull Shield +5"
                        : "Skull Crusher Axe +43";
            }
            return id == 44 ? "Flaming Staff +5" : "Flaming Royal Blade +45";
        }
    }

    function getOffhandName(uint8 id) public pure returns (string memory) {
        if (id < 20) {
            if (id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7)
                    return
                        id == 5 ? "Wooden Shield +1" : "Paper Hands Shield +1";
                return
                    id == 7 ? "Dagger +1" : id == 8
                        ? "Pirate Hook +1"
                        : "Offhand Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return
                        id == 10 ? "Offhand Slasher +2" : id == 11
                            ? "Large Shield +2"
                            : "Bomb +2";
                }
                return
                    id == 13 ? "Offhand Poker +3" : id == 14
                        ? "Reinforced Shield +3"
                        : "War Banner +3";
            }
            if (id < 18)
                return id == 16 ? "Hand Cannon +3" : "Metal Kite Shield +4";
            return id == 18 ? "Crossbow +4" : "Cursed Skull +4";
        }

        if (id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return
                        id == 20 ? "Spiked Shield +4" : id == 21
                            ? "Cursed Totem +5"
                            : "Grimoire +5";
                }
                return id == 23 ? "Offhand Glaive +5" : "Frost Side Sword +5";
            }

            if (id < 27)
                return id == 25 ? "Magic Shield +6" : "Enchanted Glaive +6";
            return
                id == 27 ? "Burning Wand +6" : id == 28
                    ? "Burning Shield +6"
                    : "Burning Blade +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return
                    id == 30 ? "Holy Scepter +7" : id == 31
                        ? "Possessed Skull +7"
                        : "Demonic Grimoire +7";
            }
            return
                id == 33 ? "Scepter of Frost +8" : id == 34
                    ? "Demonic Scythe +8"
                    : "Lightning Armband of Power +8";
        }
        if (id < 38) return id == 36 ? "Ice Staff +8" : "Nether Shield +9";
        return
            id == 38 ? "Molten Scimitar +9" : id == 39
                ? "Staff of the Dark Lord +9"
                : "Helix Scepter +9";
    }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERNAL ELVES TEAM.
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


library DataStructures {

using SafeMath for uint256;
/////////////DATA STRUCTURES///////////////////////////////
    struct Elf {
            address owner;  
            uint256 timestamp; 
            uint256 action; 
            uint256 healthPoints;
            uint256 attackPoints; 
            uint256 primaryWeapon; 
            uint256 level;
            uint256 hair;
            uint256 race; 
            uint256 accessories; 
            uint256 sentinelClass; 
            uint256 weaponTier; 
            uint256 inventory; 
    }

    struct Token {
            address owner;  
            uint256 timestamp; 
            uint8 action; 
            uint8 healthPoints;
            uint8 attackPoints; 
            uint8 primaryWeapon; 
            uint8 level;
            uint8 hair;
            uint8 race; 
            uint8 accessories; 
            uint8 sentinelClass; 
            uint8 weaponTier; 
            uint8 inventory; 
    }

    struct ActionVariables {

            uint256 reward;
            uint256 timeDiff;
            uint256 traits; 
            uint256 class;  
    }

    struct Camps {
            uint32 baseRewards; 
            uint32 creatureCount; 
            uint32 creatureHealth; 
            uint32 expPoints; 
            uint32 minLevel;
            uint32 itemDrop;
            uint32 weaponDrop;
            uint32 spare;
    }

    /*Dont Delete, just keep it for reference

    struct Attributes { 
            uint256 hair; //MAX 3 3 hair traits
            uint256 race;  //MAX 6 Body 4 for body
            uint256 accessories; //MAX 7 4 
            uint256 sentinelClass; //MAX 3 3 in class
            uint256 weaponTier; //MAX 6 5 tiers
            uint256 inventory; //MAX 7 6 items
    }

    */

/////////////////////////////////////////////////////
function getElf(uint256 character) internal pure returns(Elf memory _elf) {
   
    _elf.owner =          address(uint160(uint256(character)));
    _elf.timestamp =      uint256(uint40(character>>160));
    _elf.action =         uint256(uint8(character>>200));
    _elf.healthPoints =       uint256(uint8(character>>208));
    _elf.attackPoints =   uint256(uint8(character>>216));
    _elf.primaryWeapon =  uint256(uint8(character>>224));
    _elf.level    =       uint256(uint8(character>>232));
    _elf.hair           = (uint256(uint8(character>>240)) / 100) % 10;
    _elf.race           = (uint256(uint8(character>>240)) / 10) % 10;
    _elf.accessories    = (uint256(uint8(character>>240))) % 10;
    _elf.sentinelClass  = (uint256(uint8(character>>248)) / 100) % 10;
    _elf.weaponTier     = (uint256(uint8(character>>248)) / 10) % 10;
    _elf.inventory      = (uint256(uint8(character>>248))) % 10; 

} 

function getToken(uint256 character) internal pure returns(Token memory token) {
   
    token.owner          = address(uint160(uint256(character)));
    token.timestamp      = uint256(uint40(character>>160));
    token.action         = (uint8(character>>200));
    token.healthPoints       = (uint8(character>>208));
    token.attackPoints   = (uint8(character>>216));
    token.primaryWeapon  = (uint8(character>>224));
    token.level          = (uint8(character>>232));
    token.hair           = ((uint8(character>>240)) / 100) % 10;
    token.race           = ((uint8(character>>240)) / 10) % 10;
    token.accessories    = ((uint8(character>>240))) % 10;
    token.sentinelClass  = ((uint8(character>>248)) / 100) % 10;
    token.weaponTier     = ((uint8(character>>248)) / 10) % 10;
    token.inventory      = ((uint8(character>>248))) % 10; 

    token.hair = (token.sentinelClass * 3) + (token.hair + 1);
    token.race = (token.sentinelClass * 4) + (token.race + 1);

}

function _setElf(
                address owner, uint256 timestamp, uint256 action, uint256 healthPoints, 
                uint256 attackPoints, uint256 primaryWeapon, 
                uint256 level, uint256 traits, uint256 class )

    internal pure returns (uint256 sentinel) {

    uint256 character = uint256(uint160(address(owner)));
    
    character |= timestamp<<160;
    character |= action<<200;
    character |= healthPoints<<208;
    character |= attackPoints<<216;
    character |= primaryWeapon<<224;
    character |= level<<232;
    character |= traits<<240;
    character |= class<<248;
    
    return character;
}

//////////////////////////////HELPERS/////////////////

function packAttributes(uint hundreds, uint tens, uint ones) internal pure returns (uint256 packedAttributes) {
    packedAttributes = uint256(hundreds*100 + tens*10 + ones);
    return packedAttributes;
}

function calcAttackPoints(uint256 sentinelClass, uint256 weaponTier) internal pure returns (uint256 attackPoints) {

        attackPoints = (sentinelClass.add(1).mul(2)).add(weaponTier.mul(2));
        
        return attackPoints;
}

function calcHealthPoints(uint256 sentinelClass, uint256 level) internal pure returns (uint256 healthPoints) {

        healthPoints = level.div(3).add(2) + (20 - sentinelClass.mul(4));
        
        return healthPoints;
}

function calcCreatureHealth(uint256 sector, uint256 baseCreatureHealth) internal pure returns (uint256 creatureHealth) {

        creatureHealth = sector.sub(1).mul(8).add(baseCreatureHealth); 
        
        return creatureHealth;
}

function roll(uint256 level_, uint256 sectorIndex_, uint256 rand, uint256 rollOption_, uint256 weaponTier_, uint256 primaryWeapon_, uint256 inventory_) 
internal pure 
returns (uint256 newWeaponTier, uint256 newWeapon, uint256 newInventory) {

   uint256 levelTier = uint256(level_.div(20).add(1));

   newWeaponTier = weaponTier_;
   newWeapon     = primaryWeapon_;
   newInventory  = inventory_;


   if(rollOption_ == 1 || rollOption_ == 3){
       //Weapons
        uint256 weaponTier = sectorIndex_ > levelTier ? sectorIndex_ : levelTier;
        uint16  chance = uint16(_randomize(rand, "Weapon", levelTier)) % 100;
        
        if(levelTier >= sectorIndex_){

                        if(chance < 85){
                              newWeaponTier = weaponTier;
                        }else{
                              newWeaponTier = weaponTier + 1 > 5 ? 5 : weaponTier + 1;
                        }
        }else{
                        if(chance < 50){
                              newWeaponTier = levelTier;
                        }else{
                              newWeaponTier = levelTier - 1;
                        }

        }

        newWeapon = newWeaponTier == 0 ? 0 : ((newWeaponTier - 1) * 3) + (rand % 3 + 1);  

   }else if(rollOption_ == 2 || rollOption_ == 3){
       //Inventory
    
        uint16 morerand = uint16(_randomize(rand, "Inventory", level_));
        uint16 diceRoll = uint16(_randomize(rand, "Dice", level_));
        
        diceRoll = (diceRoll % 6) + 1;
        
        if(diceRoll % 2 == 1){

            newInventory = levelTier > 3 ? morerand % 3 + 3: morerand % 6 + 1;
            
        } 

   }
                      
              
}


function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}

/*
function getAttributes(uint256 _trait, uint256 _class) internal pure returns (DataStructures.Attributes memory _attributes) {

    _attributes.hair              =       (_trait / 100) % 10;
    _attributes.race              =       (_trait / 10) % 10;
    _attributes.accessories       =       (_trait) % 10;   
    _attributes.sentinelClass     =       (_class / 100) % 10;
    _attributes.weaponTier        =       (_class / 10) % 10;
    _attributes.inventory         =       (_class) % 10; 

}
*/

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}