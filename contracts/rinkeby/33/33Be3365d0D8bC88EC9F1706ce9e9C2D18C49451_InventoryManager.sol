// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManager {

    enum Part { body, helm, mainhand, offhand, unique }

    mapping(uint8 => address) public bodies;
    mapping(uint8 => address) public helms;
    mapping(uint8 => address) public mainhands;
    mapping(uint8 => address) public offhands;
    mapping(uint8 => address) public uniques;

    address public manager;

    string public constant header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    function getSVG(uint8 body_, uint8 helm_, uint8 mainhand_, uint8 offhand_) public view returns(string memory) {

        // it's a unique!
        if (helm_ > 40) return string(abi.encodePacked(header, get(Part.unique, body_), footer));

        return string(abi.encodePacked(
            header,
            get(Part.body, body_), 
            helm_     > 4 ? get(Part.helm, helm_)         : "",
            mainhand_ > 0 ? get(Part.mainhand, mainhand_) : "",
            offhand_  > 4 ? get(Part.offhand, offhand_)   : "",
            footer ));
    }


    constructor() { manager = msg.sender;}


    function getTokenURI(uint16 id_, uint8 body_, uint8 helm_, uint8 mainhand_, uint8 offhand_, uint16 level_, uint16 zugModifier_) public view returns (string memory) {

        string memory svg = Base64.encode(bytes(getSVG(body_,helm_,mainhand_,offhand_)));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Orc #',toString(id_),'", "description":"EtherOrcs is a collection of 5050 Orcs ready to pillage the blockchain. With no IPFS, these Orcs are the very first role-playing game that takes place 100% on-chain.  Spawn new Orcs, battle your Orc to level up, and pillage different loot pools to get new weapons and gear which upgrades your Orct metadata. This Horde of Orcs will stand the test of time and live on the blockchain for eternity.", "image": "',
                                'data:image/svg+xml;base64,',
                                svg,
                                '",',
                                getAttributes(body_, helm_, mainhand_, offhand_, level_, zugModifier_),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    /*///////////////////////////////////////////////////////////////
                    INVENTORY MANAGEMENT
    //////////////////////////////////////////////////////////////*/


    function setBodies(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            bodies[ids[index]] = source; 
        }
    }

     function setHelms(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            helms[ids[index]] = source; 
        }
    }

    function setMainhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            mainhands[ids[index]] = source; 
        }
    }

    function setOffhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            offhands[ids[index]] = source; 
        }
    }

    function setUniques(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            offhands[ids[index]] = source; 
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

    function get(Part part, uint8 id) internal view returns (string memory data_) {
        address source = 
            part == Part.body     ? bodies[id]    :
            part == Part.helm     ? helms[id]     :
            part == Part.mainhand ? mainhands[id] :
            part == Part.offhand  ? offhands[id]  : uniques[id];

        data_ = wrapTag(call(source, getData(part, id)));
    }
    
    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="1" y="1" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    function getData(Part part, uint8 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            part == Part.body     ? "body"     :
            part == Part.helm     ? "helm"     :
            part == Part.mainhand ? "mainhand" :
            part == Part.offhand  ? "offhand"  : "unique",
            toString(id),
            "()"
        ));
        
        return abi.encodeWithSignature(s, "");
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

    function getAttributes(uint8 body_, uint8 helm_, uint8 mainhand_, uint8 offhand_, uint16 level_, uint16 zugModifier_) internal pure returns (string memory) {
       return string(abi.encodePacked(
           '"attributes": [',
            getBodyAttributes(body_),         ',',
            getHelmAttributes(helm_),         ',',
            getMainhandAttributes(mainhand_), ',',
            getOffhandAttributes(offhand_), 
            ',{"trait_type": "level", "value":', toString(level_),
            '},{"display_type": "boost_number","trait_type": "zug booster", "value":', 
            toString(zugModifier_),'}]'));
    }

    function getBodyAttributes(uint8 body_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type:":"Body","value":"',getBodyName(body_),'"}'));
    }

    function getHelmAttributes(uint8 helm_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type:":"Helm","value":"',getHelmName(helm_),'"},{"trait_type:":"helmTier","value":',toString(getTier(helm_)),'}'));
    }

    function getMainhandAttributes(uint8 mainhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type:":"Mainhand","value":"',getMainhandName(mainhand_),'"},{"trait_type:":"mainhandTier","value":',toString(getTier(mainhand_)),'}'));
    }

    function getOffhandAttributes(uint8 offhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type:":"Offhand","value":"',getOffhandName(offhand_),'"},{"trait_type:":"offhandTier","value":',toString(getTier(offhand_)),'}'));
    }

    function getTier(uint16 id) internal pure returns (uint16) {
        if (id > 40) return 100;
        if (id == 0) return 0;
        return ((id - 1) / 4 );
    }

    // Here, we do sort of a Binary Search to find the correct name. Not the pritiest code I've wrote, but hey, it works!

    function getBodyName(uint8 id) public pure returns (string memory) {
        if (id > 40) return "Orc God";
        if ( id < 10) {
            if (id < 5) {
                if (id < 3) {
                    return id == 1 ? "Light Green Orc 1" : "Light Green Orc 2";
                }
                return id == 3 ? "Light Green Orc 3" : "Blue Orc 1";
            }

            if (id < 7) return id == 5 ? "Blue Orc 2" : "Blue Orc 3"; 
            return id == 7 ? "Dark Green Orc 1" : id == 8 ? "Dark Green Orc 2" : "Dark Green Orc 3";
        }
        if (id <= 15) {
            if (id < 13) {
                return id == 10 ? "Blood Red Orc 1" : id == 11 ? "Blood Red Orc 2" : "Blood Red Orc 3";
            }
            return id == 13 ? "Red Clay Orc 1" : id == 14 ? "Red Clay Orc 2" : "Red Clay Orc 3";
        }
        if (id < 18) return id == 16 ? "Orange Orc 1" : "Orange Orc 2";
        return id == 18 ? "Dark Orc 1" :  "Dark Orc 2";
    }

    function getHelmName(uint8 id) public pure returns (string memory) {
        if (id > 40) return "Orc God";
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7) return id == 5 ? "Bell Head +1" : "Orcish Helm +1"; 
                return id == 7 ? "Iron Helm +1" : id == 8 ? "Pirate Bandana +1" : "Leather Cap +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Steel Cap +2" : id == 11 ? "Orcish Helm Again +2" : "Chainmail Cap +2";
                }
                return id == 13 ? "Parasite +3" : id == 14 ? "Bronze Helm +3" : "Treasure Chest +3";
            }
            if (id < 18) return id == 16 ? "Boar Head +3" : "Thorned Helm +4";
            return id == 18 ? "Full Plate Helm +4" :  "Knights Helm +4";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Red Bandana +4" : id == 21 ? "Purple Hood +5" : "Placeholder +5";
                }
                return id == 23 ? "Halo +5" : "Placeholder +5";
            }

            if (id < 27) return id == 25 ? "Sage Blindfold +6" : "Kings Eyes Green +6"; 
            return id == 27 ? "Kings Eyes Red +6" : id == 28 ? "Purple Hood with Horns +6" : "Beholder's Head +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return id == 30 ? "Purple Hood with Magic +7" : id == 31 ? "Demons Horned Skull +7" : "Placeholder +7";
            }
            return id == 33 ? "Purple Hood with Magic and Horns +8" : id == 34 ? "Molten Crown +8" : "Demons Horned Skull +8";
        }
        if (id < 38) return id == 36 ? "Enchanted Necklace +8" : "Blazing Horns +9";
        return id == 38 ? "Cursed Skull +9" : id == 39 ? "Lightning Circlet +9" : "Ice Crown +9";
    }

    function getMainhandName(uint8 id) public pure returns (string memory) {
        if (id > 40) return "Orc God";
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "Pickaxe" : "Torch";
                    }
                return id == 3 ? "Dagger" : "Short Sword";
            }
                if (id < 7) return id == 5 ? "Simple Axe +1" : "Simple Pike +1"; 
                return id == 7 ? "Poisoned Dagger +1" : id == 8 ? "Broadsword +1" : "Large Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Iron Hammer +2" : id == 11 ? "Iron Mace +2" : "Pleb Staff +2";
                }
                return id == 13 ? "Bloody Axe +3" : id == 14 ? "Curved Sword +3" : "Ultra Mallet +3";
            }
            if (id < 18) return id == 16 ? "Disciple Staff +3" : "Placeholder +4";
            return id == 18 ? "Swamp Staff +4" :  "Simple Wand +4";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Placeholder +4" : id == 21 ? "Placeholder +5" : "Placeholder +5";
                }
                return id == 23 ? "Placeholder +5" : "Placeholder +5";
            }

            if (id < 27) return id == 25 ? "Ancient Sword +6" : "Flaming Staff +6"; 
            return id == 27 ? "Assassins Blade +6" : id == 28 ? "Frozen Scythe +6" : "Placeholder +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return id == 30 ? "Necromancer Staff +7" : id == 31 ? "Frozen Sword +7" : "Crystalline Blade +7";
            }
            return id == 33 ? "Cryptic Staff +8" : id == 34 ? "Crystal Smasher +8" : "Orc Skull Axe +8";
        }
        if (id < 38) return id == 36 ? "Thunder Blade +8" : "Old Moon Sword +9";
        return id == 38 ? "Molten Hammer +9" : id == 39 ? "Cursed Great Staff +9" : "Lance of Longin +9";
    }

    function getOffhandName(uint8 id) public pure returns (string memory) {
        if (id > 40) return "Orc God";
        if (id < 20) {
            if ( id < 10) {
                if (id < 5) {
                    if (id < 3) {
                        return id == 1 ? "None" : "None";
                    }
                    return id == 3 ? "None" : "None";
                }
                if (id < 7) return id == 5 ? "Simple Buckler +1" : "Green Shield +1"; 
                return id == 7 ? "Dagger +1" : id == 8 ? "Pirate Hook +1" : "Offhand Axe +2";
            }
            if (id <= 15) {
                if (id < 13) {
                    return id == 10 ? "Offhand Krol +2" : id == 11 ? "Large Shield +2" : "Bomb +2";
                }
                return id == 13 ? "Polearm +3" : id == 14 ? "Reinforced Shield +3" : "War Banner +3";
            }
            if (id < 18) return id == 16 ? "Hand Cannon +3" : "Spiked Shield +4";
            return id == 18 ? "Crossbow +4" :  "Mithril Blade +4";
        }

        if ( id < 30) {
            if (id < 25) {
                if (id < 23) {
                    return id == 20 ? "Metal Kite Shield +4" : id == 21 ? "Cursed Totem +5" : "Grimoire +5";
                }
                return id == 23 ? "Offhand Glaive +5" : "Frost Side Sword +5";
            }

            if (id < 27) return id == 25 ? "Magic Shield +6" : "Enchanted Glaive +6"; 
            return id == 27 ? "Dragonhead Shield +6" : id == 28 ? "Placeholder +6" : "Burning Shield +7";
        }
        if (id <= 35) {
            if (id < 33) {
                return id == 30 ? "Placeholder +7" : id == 31 ? "Placeholder +7" : "Placeholder +7";
            }
            return id == 33 ? "Demonic Grimoire +8" : id == 34 ? "Nether Shield +8" : "Placeholder +8";
        }
        if (id < 38) return id == 36 ? "Placeholder +8" : "Flaming Scimitar +9";
        return id == 38 ? "Frozen Lance +9" : id == 39 ? "Lightning Bracelet +9" : "Cursed Skull +9";
    }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
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