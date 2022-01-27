// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManagerOgres {

    address impl_;
    address public manager;

    enum Part { body, mouth, nose, eyes, armor, mainhand, offhand }

    mapping(uint8 => address) public bodies;
    mapping(uint8 => address) public mouths;
    mapping(uint8 => address) public noses;
    mapping(uint8 => address) public eyes;
    mapping(uint8 => address) public armors;
    mapping(uint8 => address) public mainhands;
    mapping(uint8 => address) public offhands;

    string public constant header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    function getSVG(bytes22 details_) public view returns(string memory) {
        (uint8 body_, uint8 mouth_, uint8 nose_, uint8 eyes_, uint8 armor_, uint8 mainhand_, uint8 offhand_) = _ogre(details_);

        return string(abi.encodePacked(
            header,
            get(Part.body, body_), 
            get(Part.mouth, mouth_),
            get(Part.nose, nose_),
            get(Part.eyes, eyes_),
            get(Part.armor, armor_),
            get(Part.offhand, offhand_),
            get(Part.mainhand, mainhand_),
            footer ));
    }

    function getSVGDetailed(uint8 body_, uint8 mouth_, uint8 nose_, uint8 eyes_, uint8 armor_, uint8 mainhand_, uint8 offhand_) public view returns(string memory) {
        return string(abi.encodePacked(
            header,
            get(Part.body, body_), 
            get(Part.mouth, mouth_),
            get(Part.nose, nose_),
            get(Part.eyes, eyes_),
            get(Part.armor, armor_),
            get(Part.offhand, offhand_),
            get(Part.mainhand, mainhand_),
            footer ));
    }

    function getTokenURI(uint256 id_, uint256 , uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory) {
        return _buildOgreURI(_getUpper(id_), getSVG(details_), getAttributes(details_, level_, modF_, skillCredits_));
    }

    function _buildOgreURI(bytes memory upper, string memory svg, string memory attributes) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    BBase64.encode(
                        bytes(
                            abi.encodePacked(
                                upper,
                                BBase64.encode(bytes(svg)),
                                '",',
                                attributes,
                                '}'
                            )
                        )
                    )
                )
            );
    }


    function _getUpper(uint256 id_) internal pure returns (bytes memory) {
        return abi.encodePacked('{"name":"Ogre #',toString(id_),'", "description":"EtherOrcs Allies is a collection of 12,000 100% on-chain warriors that aid Genesis Orcs in their conquest of Valkala. Four classes of Allies (Shamans, Tanks, Mages, and Rogues) each produce their own unique consumables as their entry point to the broader EtherOrcs game economy. Each Ally can participate in all aspects of gameplay within the ecosystem and will strengthen the Horde and solidify its place as champions in the on-chain metaverse.", "image": "',
                                'data:image/svg+xml;base64,');
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

    function setMouths(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            mouths[ids[index]] = source; 
        }
    }

    function setNoses(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            noses[ids[index]] = source; 
        }
    }

    function setArmors(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            armors[ids[index]] = source; 
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

    function setEyes(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            eyes[ids[index]] = source; 
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _ogre(bytes22 details) internal pure returns(uint8 body_, uint8 mouth_, uint8 nose_, uint8 eyes_, uint8 armor_, uint8 mainhand_, uint8 offhand_) {
        body_     = uint8(bytes1(details));
        mouth_    = uint8(bytes1(details << 8));
        nose_     = uint8(bytes1(details << 16));
        eyes_     = uint8(bytes1(details << 24));
        armor_    = uint8(bytes1(details << 32));
        mainhand_ = uint8(bytes1(details << 40));
        offhand_  = uint8(bytes1(details << 48));
    }
    
    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function get(Part part, uint8 id) internal view returns (string memory data_) {
        address source = 
            part == Part.body     ? bodies[id]    :
            part == Part.mouth    ? mouths[id]    :
            part == Part.nose     ? noses[id]     :
            part == Part.eyes     ? eyes[id]      :
            part == Part.armor    ? armors[id]    :
            part == Part.mainhand ? mainhands[id] : offhands[id];

        data_ = wrapTag(call(source, getData(part, id)));
    }
    
    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    function getData(Part part, uint8 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            part == Part.body     ? "body"     :
            part == Part.mouth    ? "mouth"    :
            part == Part.nose     ? "nose"     :
            part == Part.eyes     ? "eye"     :
            part == Part.armor    ? "armor"    :
            part == Part.mainhand ? "mainhand" : "offhand",
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

    function getAttributes(bytes22 details_, uint256 level_, uint256 modF_, uint256 sc_) internal pure returns (string memory) {
       return string(abi.encodePacked(_getTopAtt(details_), _getBottomAtt(level_, sc_, modF_)));
    }

    function _getTopAtt(bytes22 details_) internal pure returns (string memory) {
        (uint256 body_, uint256 mouth_, uint256 nose_, uint256 eyes_, uint256 armor_, uint256 mainhand_, uint256 offhand_) = _ogre(details_);
       return string(abi.encodePacked(
           '"attributes": [',
            getBodyAttributes(body_),         ',',
            getArmorAttributes(armor_),        ',',
            getMainhandAttributes(mainhand_), ',',
            getOffhandAttributes(offhand_)));
    }

    function _getBottomAtt(uint256 level_, uint256 sc_, uint256 modF_) internal pure returns (string memory) {
        return string(abi.encodePacked(',{"trait_type": "level", "value":', toString(level_),
            '},{"trait_type": "skillCredits", "value":', toString(sc_),'},{"display_type": "boost_number","trait_type": "Herbalism", "value":', 
            toString(modF_),'}]'));
    }

    function getBodyAttributes(uint256 body_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Body","value":"',getBodyName(body_),'"}'));
    }

    function getArmorAttributes(uint256 armor_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Armor","value":"',getArmorName(armor_),'"},{"display_type":"number","trait_type":"ArmorTier","value":',toString(getTier(uint8(armor_))),'}'));
    }

    function getMainhandAttributes(uint256 mainhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Mainhand","value":"',getMainhandName(mainhand_),'"},{"display_type":"number","trait_type":"MainhandTier","value":',toString(getTier(uint8(mainhand_))),'}'));
    }

    function getOffhandAttributes(uint256 offhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Offhand","value":"',getOffhandName(offhand_),'"},{"display_type":"number","trait_type":"OffhandTier","value":',toString(getTier(uint8(offhand_))),'}'));
    }

    function getTier(uint8 item) internal pure returns (uint8 tier) {
        if (item <= 6) return 0;
        if (item <= 9) return 1;
        if (item <= 14) return 2;
        if (item <= 20) return 3;
        if (item <= 26) return 4;
        if (item <= 31) return 5;
        if (item <= 35) return 6;
        return 7;
    } 

    function getArmorName(uint256 id) public pure returns (string memory) {

        if (id <= 6) return "None";
        if (id <= 25) {
            if (id <= 15) {
                if (id == 7)  return "Iron Cap +1";
                if (id == 8)  return "Horned Crown +1";
                if (id == 9)  return "Protective Visor +1";
                if (id == 10)  return "Spiked Cap +2";
                if (id == 11)  return "Footsoldier Helm +2";
                if (id == 12)  return "Steel Pad +2";
                if (id == 13)  return "Leather Strap +2";
                if (id == 14)  return "Leather Pad +2";
                if (id == 15)  return "Centurion Cap +3";
            } else {
                if (id == 16)  return "Knight Helm +3";
                if (id == 17)  return "Strange Mask +3";
                if (id == 18)  return "Gladiator Visor +3";
                if (id == 19)  return "Conqueror Helm +3";
                if (id == 20)  return "Bone Mask +3";
                if (id == 21)  return "Champion Helm +4";
                if (id == 22)  return "Skull Crown +4";
                if (id == 23)  return "Gladiator Helm +4";
                if (id == 24)  return "Mercenary Steel +4";
                if (id == 25)  return "Stolen Artifact +4";
            }
        } else {
            if (id <= 35) {
                if (id == 26)  return "Tribelord Mask +4";
                if (id == 27)  return "Deathstalker Cowl +5";
                if (id == 28)  return "Helm of the Victor +5";
                if (id == 29)  return "Bonemaster Skull +5";
                if (id == 30)  return "Demon Visage +5";
                if (id == 31)  return "Resolve of the Champion +5";
                if (id == 32)  return "Wargod Crown +6";
                if (id == 33)  return "Cthulus Wrath +6";
                if (id == 34)  return "Iron Maiden +6";
                if (id == 35)  return "Mantle of Destruction +6";
            }
        }
    }


    function getMainhandName(uint256 id) public pure returns (string memory) {

        if (id <= 6) {
                if (id == 1)  return "Simple Club";
                if (id == 2)  return "Bone Knife";
                if (id == 3)  return "Hatchet";
                if (id == 4)  return "Crude Club";
                if (id == 5)  return "Witch Finger";
                if (id == 6)  return "Machete";
        }
        if (id <= 25) {
            if (id <= 15) {
                if (id == 7)  return "Ceramic Hammer +1";
                if (id == 8)  return "Battle Axe +1";
                if (id == 9)  return "Stone Smasher +1";
                if (id == 10)  return "Brute Club +2";
                if (id == 11)  return "Wiseman Blade +2";
                if (id == 12)  return "Iron fist +2";
                if (id == 13)  return "Strange Hammer +2";
                if (id == 14)  return "Venom Sickle +2";
                if (id == 15)  return "Monk Steel +3";
            } else {
                if (id == 16)  return "Blackiron Axe +3";
                if (id == 17)  return "Serpent Crook +3";
                if (id == 18)  return "Steel Bound Smasher +3";
                if (id == 19)  return "Blazing Torch +3";
                if (id == 20)  return "War Cleaver +3";
                if (id == 21)  return "Tainted Club +4";
                if (id == 22)  return "Spiked Club +4";
                if (id == 23)  return "Razor Edge +4";
                if (id == 24)  return "Raven Talon +4";
                if (id == 25)  return "Axe of Rorn +4";
            }
        } else {
            if (id <= 35) {
                if (id == 26)  return "Wyvern Hammer +4";
                if (id == 27)  return "Pulverizer +5";
                if (id == 28)  return "Demon Kanabo +5";
                if (id == 29)  return "Silken Shredder +5";
                if (id == 30)  return "Demon Crescent +5";
                if (id == 31)  return "Saber of the Unknown +5";
                if (id == 32)  return "Dragon Blade of Norok +6";
                if (id == 33)  return "Great Sword of Dakmak +6";
                if (id == 34)  return "Might of Bakk +6";
                if (id == 35)  return "Soul Blade of Bronk +6";
            }
        }
    }

    function getOffhandName(uint256 id) public pure returns (string memory) {

        if (id <= 6) {
                if (id == 1)  return "Pickaxe";
                if (id == 2)  return "Steel Cudgel";
                if (id == 3)  return "Two Sided Cleaver";
                if (id == 4)  return "Knife";
                if (id == 5)  return "Broken Bottle";
                if (id == 6)  return "Truncheon";
        }
        if (id <= 25) {
            if (id <= 15) {
                if (id == 7)  return "Spiked Mace +1";
                if (id == 8)  return "Cleaver +1";
                if (id == 9)  return "Barrel Shield +1";
                if (id == 10)  return "Flanged Mace +2";
                if (id == 11)  return "Large Knife +2";
                if (id == 12)  return "Large Cleaver +2";
                if (id == 13)  return "Skull Crusher +2";
                if (id == 14)  return "Duelist Buckler +2";
                if (id == 15)  return "Giant Cleaver +3";
            } else {
                if (id == 16)  return "Two Pronged Spear +3";
                if (id == 17)  return "Spear +3";
                if (id == 18)  return "Reinforced Shield +3";
                if (id == 19)  return "Kanabo +3";
                if (id == 20)  return "Tower Shield +3";
                if (id == 21)  return "Obsidian Macuahuitl +4";
                if (id == 22)  return "Wolf Hand +4";
                if (id == 23)  return "Large Flanged Mace +4";
                if (id == 24)  return "Chain Sword +4";
                if (id == 25)  return "Artifact Shield +4";
            }
        } else {
            if (id <= 35) {
                if (id == 26)  return "Seaman Shield +4";
                if (id == 27)  return "Spiked Shield +5";
                if (id == 28)  return "Venom Sword +5";
                if (id == 29)  return "Spiked Flail +5";
                if (id == 30)  return "Large Spiked Kanabo +5";
                if (id == 31)  return "Centurion Shield +5";
                if (id == 32)  return "Might of Trok +6";
                if (id == 33)  return "Rage of Zarag +6";
                if (id == 34)  return "Barricade of Erok +6";
                if (id == 35)  return "Bulwark of Kugrok +6";
            }
        }
    }

    function getBodyName(uint256 id) public pure returns (string memory) {
        if (id == 1) return "Dark Red";
        if (id == 2) return "Bright Red";
        if (id == 3) return "Dark Blue";
        if (id == 4) return "Blue";
        if (id == 5) return "Green";
        if (id == 6) return "Tan";
        if (id == 7) return "Clay";
        if (id == 8) return "Dark Green";
    }
}

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library BBase64 {
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