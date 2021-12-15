/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManagerAllies {

    address impl_;
    address public manager;

    enum Part { body, featA, featB, helm, mainhand, offhand }

    mapping(uint8 => address) public bodies;
    mapping(uint8 => address) public featA;
    mapping(uint8 => address) public featB;
    mapping(uint8 => address) public helms;
    mapping(uint8 => address) public mainhands;
    mapping(uint8 => address) public offhands;
    mapping(uint8 => address) public uniques;


    string public constant header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    function getSVG(uint8 body_, uint8 featA_, uint8 featB_, uint8 helm_, uint8 mainhand_, uint8 offhand_) public view returns(string memory) {

        return string(abi.encodePacked(
            header,
            get(Part.body, body_), 
            get(Part.featB, featB_),
            get(Part.featA, featA_),
            get(Part.helm, helm_),
            get(Part.offhand, offhand_),
            get(Part.mainhand, mainhand_),
            footer ));
    }


    constructor() { manager = msg.sender;}

    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory) {
        if (class_ == 1) {
            // It's a shaman
            (uint8 body_, uint8 featA_, uint8 featB_, uint8 helm_, uint8 mainhand_, uint8 offhand_) = _shaman(details_);
            return _buildShamanURI(_getUpper(id_), getSVG(body_,featA_, featB_, helm_,mainhand_,offhand_), getAttributes(details_, level_, modF_, skillCredits_));
        }
    }

    function _buildShamanURI(bytes memory upper, string memory svg, string memory attributes) internal pure returns (string memory) {
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
        return abi.encodePacked('{"name":"Shaman #',toString(id_),'", "description":"EtherOrcs Allies is a collection of 12,000 100% on-chain warriors that aid Genesis Orcs in their conquest of Valkala. Four classes of Allies (Shamans, Tanks, Mages, and Rogues) each produce their own unique consumables as their entry point to the broader EtherOrcs game economy. Each Ally can participate in all aspects of gameplay within the ecosystem and will strengthen the Horde and solidify its place as champions in the on-chain metaverse.", "image": "',
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

    function setFeatA(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            featA[ids[index]] = source; 
        }
    }

    function setFeatB(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            featB[ids[index]] = source; 
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
            uniques[ids[index]] = source; 
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _shaman(bytes22 details) internal pure returns(uint8 body_, uint8 featA_, uint8 featB_, uint8 helm_, uint8 mainhand_, uint8 offhand_) {
        body_     = uint8(bytes1(details));
        featA_    = uint8(bytes1(details << 8));
        featB_    = uint8(bytes1(details << 16));
        helm_     = uint8(bytes1(details << 24));
        mainhand_ = uint8(bytes1(details << 32));
        offhand_  = uint8(bytes1(details << 40));
    }
    
    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function get(Part part, uint8 id) internal view returns (string memory data_) {
        address source = 
            part == Part.body     ? bodies[id]    :
            part == Part.featA    ? featA[id]     :
            part == Part.featB    ? featB[id]     :
            part == Part.helm     ? helms[id]     :
            part == Part.mainhand ? mainhands[id] : offhands[id];

        data_ = wrapTag(call(source, getData(part, id)));
    }
    
    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    function getData(Part part, uint8 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            part == Part.body     ? "body"     :
            part == Part.featA    ? "featA"    :
            part == Part.featB    ? "featB"    :
            part == Part.helm     ? "helm"     :
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
        (uint256 body_, uint256 featA_, uint256 featB_, uint256 helm_, uint256 mainhand_, uint256 offhand_) = _shaman(details_);
       return string(abi.encodePacked(
           '"attributes": [',
            getBodyAttributes(body_),         ',',
            getFeatAAttributes(featA_),         ',',
            getFeatBAttributes(featB_),         ',',
            getHelmAttributes(helm_),         ',',
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

    function getFeatAAttributes(uint256 featA_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Hair","value":"',getHairName(featA_),'"}'));
    }

    function getFeatBAttributes(uint256 featB_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Facial Hair","value":"',getFacialHairName(featB_),'"}'));
    }

    function getHelmAttributes(uint256 helm_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Helm","value":"',getHelmName(helm_),'"},{"display_type":"number","trait_type":"HelmTier","value":',toString(getTier(uint8(helm_))),'}'));
    }

    function getMainhandAttributes(uint256 mainhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Mainhand","value":"',getMainhandName(mainhand_),'"},{"display_type":"number","trait_type":"MainhandTier","value":',toString(getTier(uint8(mainhand_))),'}'));
    }

    function getOffhandAttributes(uint256 offhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Offhand","value":"',getOffhandName(offhand_),'"},{"display_type":"number","trait_type":"OffhandTier","value":',toString(getTier(uint8(offhand_))),'}'));
    }

    function getTier(uint8 item) internal pure returns (uint8 tier) {
        if (item <= 7) return 0;
        if (item <= 12) return 1;
        if (item <= 18) return 2;
        if (item <= 25) return 3;
        if (item <= 32) return 4;
        if (item <= 38) return 5;
        if (item <= 44) return 6;
        return 7;
    } 

    function getHelmName(uint256 id) public pure returns (string memory) {
        if (id <= 7) return "None";
        if (id <= 25) {
            if (id <= 15) {
                if (id == 8)  return "Hero Bandana +1";
                if (id == 9)  return "Bone Shard Crest +1";
                if (id == 10) return "Bone Mask +1";
                if (id == 11) return "Horned Helm +1";
                if (id == 12) return "Iron Helm +1";
                if (id == 13) return "Horns +2";
                if (id == 14) return "Skull Mask +2";
                if (id == 15) return "Centurion Cap +2";
            } else {
                if (id == 16) return "Toad +2";
                if (id == 17) return "Knights Helm +2";
                if (id == 18) return "Viking Helm +2";
                if (id == 19) return "Furtive Skull +3";
                if (id == 20) return "Sacred Mask +3";
                if (id == 21) return "Wisdom Horns +3";
                if (id == 22) return "Steel Cover +3";
                if (id == 23) return "Wolf Helm +3";
                if (id == 24) return "Royal Knights Helm +3";
                if (id == 25) return "Elk Antlers +3";
            }
        } else {
            if (id <= 37) {
                if (id == 26)  return "Tiger Helm +4";
                if (id == 27)  return "Bone Witch Mask +4";
                if (id == 28) return "Bear Helm +4";
                if (id == 29) return "Tribal Skull +4";
                if (id == 30) return "Bone Hawk Mask +4";
                if (id == 31) return "Tiger Pelt +4";
                if (id == 32) return "Fishman Helm +4";
                if (id == 33) return "Buck Antlers +5";
                if (id == 34) return "Wolf Pelt +5";
                if (id == 35) return "Grand Headdress +5";
                if (id == 36) return "Tribal Champion Skull +5";
                if (id == 37) return "Ancient Mask +5";
            } else {
                if (id == 38) return "Lion Pelt +5";
                if (id == 39) return "Witch Doctor Mask +6";
                if (id == 40) return "Ancestral Mask +6";
                if (id == 41) return "Primal Horns +6";
                if (id == 42) return "Cursed Fishman Helm +6";
                if (id == 43) return "Possessed Mask +6";
                if (id == 44) return "Wolf Soul +7";
                if (id == 45) return "Orb the Elk +7";
                if (id == 46) return "Bear Soul +7";
                if (id == 47) return "Antlers of Power +7";
                if (id == 48) return "Alchemist Mask +7";
                if (id == 49) return "Chieftan Mask +7";
                if (id == 50) return "Witch Doctor Regalia +7";
            }
        }
    }


function getMainhandName(uint256 id) public pure returns (string memory) {
        if (id <= 7) {
                if (id == 1)  return "Simple Staff";
                if (id == 2)  return "Bone Staff";
                if (id == 3)  return "Steel Cane";
                if (id == 4)  return "Iron Rod";
                if (id == 5)  return "Steel Pole";
                if (id == 6)  return "Monk Staff";
                if (id == 7)  return "Gnarled Spear";
}
        if (id <= 25) {
            if (id <= 15) {
                if (id == 8)  return "Twisted Staff +1";
                if (id == 9)  return "Martial Club +1";
                if (id == 10)  return "Living Branch +1";
                if (id == 11)  return "Wiseman Blade +1";
                if (id == 12)  return "Monk Spade +1";
                if (id == 13)  return "Trident +2";
                if (id == 14)  return "Alchemist Branch +2";
                if (id == 15)  return "Monk Steel +2";
            } else {
                if (id == 16)  return "Alchemist Crook +2";
                if (id == 17)  return "Ankh Wand +2";
                if (id == 18)  return "Voodoo Staff +2";
                if (id == 19)  return "Transmutation Rod +3";
                if (id == 20)  return "Spined Crook +3";
                if (id == 21)  return "Enchanted Staff +3";
                if (id == 22)  return "Alchemist Spark +3";
                if (id == 23)  return "Crescent Spear +3";
                if (id == 24)  return "Raven Talon +3";
                if (id == 25)  return "Healing Roots +3";
            }
        } else {
            if (id <= 37) {
                if (id == 26)  return "Powered Rod +4";
                if (id == 27)  return "Fiery Trident +4";
                if (id == 28)  return "Witch Doctor Staff +4";
                if (id == 29)  return "Ancient Wand +4";
                if (id == 30)  return "Demon Crescent +4";
                if (id == 31)  return "Ancestral Torch +4";
                if (id == 32)  return "Spirit Staff +4";
                if (id == 33)  return "Alchemist Rock +5";
                if (id == 34)  return "Serpent Staff +5";
                if (id == 35)  return "Elder Staff +5";
                if (id == 36)  return "Flaming Staff +5";
                if (id == 37)  return "Poisonous Staff +5";
            } else {
                if (id == 38)  return "Wisened Staff +5";
                if (id == 39)  return "Sage Staff +6";
                if (id == 40)  return "Ceremonial Staff +6";
                if (id == 41)  return "Ancestral Torch +6";
                if (id == 42)  return "Voodoo Spirit +6";
                if (id == 43)  return "Venomous Serpent +6";
                if (id == 44)  return "Healing Serpent +6";
                if (id == 45)  return "Philosopher Stone +7";
                if (id == 46)  return "Shard of the Ancestors +7";
                if (id == 47)  return "Ancestral Gift +7";
                if (id == 48)  return "Grand Healer Staff +7";
                if (id == 49)  return "Memory of Gulzog +7";
                if (id == 50)  return "Power of the Sage +7";
            }
        }
    }






function getOffhandName(uint256 id) public pure returns (string memory) {
        if (id <= 7) {
                if (id == 1)  return "Hammer";
                if (id == 2)  return "Rough Axe";
                if (id == 3)  return "Bone";
                if (id == 4)  return "Gnarled Club";
                if (id == 5)  return "Standard Mace";
                if (id == 6)  return "Branch Wand";
                if (id == 7)  return "Rock Flail";
        }
        if (id <= 25) {
            if (id <= 15) {
                if (id == 8)  return "Large Hatchet +1";
                if (id == 9)  return "Ceremonial Knife +1";
                if (id == 10)  return "Mallet +1";
                if (id == 11)  return "Large Hammer +1";
                if (id == 12)  return "Steel Axe +1";
                if (id == 13)  return "Skull Crusher +2";
                if (id == 14)  return "Strange Sword +2";
                if (id == 15)  return "Bone Axe +2";
            } else {
                if (id == 16)  return "Battle Axe +2";
                if (id == 17)  return "Witch Doctor Hammer +2";
                if (id == 18)  return "Poisoned Dagger +2";
                if (id == 19)  return "Delicious Potion +3";
                if (id == 20)  return "Cutlass +3";
                if (id == 21)  return "Steel Flanged Mace +3";
                if (id == 22)  return "Double Sided Hammer +3";
                if (id == 23)  return "Large Flanged Mace +3";
                if (id == 24)  return "Spear of the Warrior +3";
                if (id == 25)  return "Stolen Staff +3";
            }
        } else {
            if (id <= 37) {
                if (id == 26)  return "Bear Claw +4";
                if (id == 27)  return "Barbed Club +4";
                if (id == 28)  return "Venom Axe +4";
                if (id == 29)  return "Time Hammer +4";
                if (id == 30)  return "The Smasher +4";
                if (id == 31)  return "Ancient Censer +4";
                if (id == 32)  return "Lion Claw +4";
                if (id == 33)  return "Crescent Blade +5";
                if (id == 34)  return "Iron Flail +5";
                if (id == 35)  return "Crusher Axe +5";
                if (id == 36)  return "Shriveled Totem +5";
                if (id == 37)  return "Large Flanged Mace +5";
            } else {
                if (id == 38)  return "War Axe +5";
                if (id == 39)  return "Frog +6";
                if (id == 40)  return "Eagle +6";
                if (id == 41)  return "Might of the Wizard +6";
                if (id == 42)  return "Horned Club of Urtgok +6";
                if (id == 43)  return "Enchanted Serpent +6";
                if (id == 44)  return "Aspect of Lightning +6";
                if (id == 45)  return "Elemental Dragon +7";
                if (id == 46)  return "Elemental Wolf +7";
                if (id == 47)  return "Eagle Soul +7";
                if (id == 48)  return "Frog of the Ancestors +7";
                if (id == 49)  return "Wand of Gulzog +7";
                if (id == 50)  return "Might of the Sage +7";
            }
        }
    }

    function getBodyName(uint256 id) public pure returns (string memory) {
        if (id == 1) return "Red";
        if (id == 2) return "Light Green";
        if (id == 3) return "Dark Green";
        if (id == 4) return "Dark Red";
        if (id == 5) return "Light Red";
        if (id == 6) return "Blue";
        if (id == 7) return "Clay";
        if (id == 8) return "Red Clay";
        if (id == 9) return "Dark Blue";
        if (id == 10) return "Light Blue";
        if (id == 11) return "Albino";

    }

    function getFacialHairName(uint256 id) public pure returns (string memory) {
        if (id == 1) return "Facial Hair 1";
        if (id == 2) return "Facial Hair 2";
        if (id == 3) return "Facial Hair 3";
        if (id == 4) return "Facial Hair 4";
        if (id == 5) return "Facial Hair 5";
        if (id == 6) return "None";
        if (id == 7) return "Facial Hair 7";
        if (id == 8) return "Facial Hair 8";
        if (id == 9) return "None";
        if (id == 10) return "Facial Hair 10";
        if (id == 11) return "Facial Hair 11";
        if (id == 12) return "Facial Hair 12";
        if (id == 13) return "Facial Hair 13";
        if (id == 14) return "None";
        if (id == 15) return "Facial Hair 15";
        if (id == 16) return "Facial Hair 16";
        if (id == 17) return "Facial Hair 17";
        if (id == 18) return "None";
        if (id == 19) return "Facial Hair 19";
        if (id == 20) return "Facial Hair 20";
    }

    function getHairName(uint256 id) public pure returns (string memory) {
        if (id == 1) return "Bald";
        if (id == 2) return "Hair 1";
        if (id == 3) return "Hair 2";
        if (id == 4) return "Hair 3";
        if (id == 5) return "Hair 4";
        if (id == 6) return "Hair 5";
        if (id == 7) return "Hair 6";
        if (id == 8) return "Hair 7";
        if (id == 9) return "Hair 8";
        if (id == 10) return "Hair 9";
        if (id == 11) return "Hair 10";
        if (id == 12) return "Hair 11";
        if (id == 13) return "Hair 12";
        if (id == 14) return "Hair 13";
        if (id == 15) return "Hair 14";
        if (id == 16) return "Hair 15";
        if (id == 17) return "Hair 16";
        if (id == 18) return "Hair 17";
        if (id == 19) return "Hair 18";
        if (id == 20) return "Hair 19";
        if (id == 21) return "Hair 20";
        if (id == 22) return "Hair 21";
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