/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface titanhero {
	function gene(uint) external view returns (uint);
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
}

contract hero_attributes {
    
    uint32 constant POINT_BASE_Genius = 5;
	uint32 constant POINT_BASE_Normal = 1;
	
	uint constant POINT_LEVEL_Genius = 3;
	uint constant POINT_LEVEL_Normal = 2;
	
    titanhero constant titan = titanhero(0x27ca58203EF9Cb2142246225b5d13af988A275fd);
    
    struct ability_score {
        uint32 strength;
        uint32 dexterity;
        uint32 constitution;
        uint32 intelligence;
        uint32 wisdom;
        uint32 charisma;
    }
    
    mapping(uint => ability_score) public ability_scores;
    mapping(uint => uint) public level_points_spent;
    mapping(uint => bool) public character_created;
    
    event Created(address indexed creator, uint hero, uint32 strength, uint32 dexterity, uint32 constitution, uint32 intelligence, uint32 wisdom, uint32 charisma);
    event Leveled(address indexed leveler, uint hero, uint32 strength, uint32 dexterity, uint32 constitution, uint32 intelligence, uint32 wisdom, uint32 charisma);
    
    function _isApprovedOrOwner(uint _hero) internal view returns (bool) {
        return titan.getApproved(_hero) == msg.sender || titan.ownerOf(_hero) == msg.sender;
    }
    
    function hero_activate(uint _hero) external {
        require(_isApprovedOrOwner(_hero));
        require(!character_created[_hero]);
		
        character_created[_hero] = true;
        
		if( titan.gene(_hero) == 0){
			ability_scores[_hero] = ability_score(POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius);
			emit Created(msg.sender, _hero, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius, POINT_BASE_Genius);
		}
		else{
			ability_scores[_hero] = ability_score(POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal);
			emit Created(msg.sender, _hero, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal, POINT_BASE_Normal);
		}
		
    }
    
    function calculate_point_buy(uint _str, uint _dex, uint _const, uint _int, uint _wis, uint _cha) public pure returns (uint) {
        return calc(_str)+calc(_dex)+calc(_const)+calc(_int)+calc(_wis)+calc(_cha);
    }
    
    function calc(uint score) public pure returns (uint) {
        if (score <= 14) {
            return score - 8;
        } else {
            return ((score - 8)**2)/6;
        }
    }
    
    function _increase_base(uint _hero) internal {
        require(_isApprovedOrOwner(_hero));
        require(character_created[_hero]);
        uint _points_spent = level_points_spent[_hero];
		
		if(titan.gene(_hero) == 0 ){
			require(titan.level(_hero)*POINT_LEVEL_Genius - _points_spent > 0);
		}
		else{
			require(titan.level(_hero)*POINT_LEVEL_Normal - _points_spent > 0);
		}
        level_points_spent[_hero] = _points_spent+1;
    }
    
    function increase_strength(uint _hero) external {
        _increase_base(_hero);
        ability_score storage _attr = ability_scores[_hero];
        _attr.strength = _attr.strength+1;
        emit Leveled(msg.sender, _hero, _attr.strength, _attr.dexterity, _attr.constitution, _attr.intelligence, _attr.wisdom, _attr.charisma);
    }
    
    function increase_dexterity(uint _hero) external {
        _increase_base(_hero);
        ability_score storage _attr = ability_scores[_hero];
        _attr.dexterity = _attr.dexterity+1;
        emit Leveled(msg.sender, _hero, _attr.strength, _attr.dexterity, _attr.constitution, _attr.intelligence, _attr.wisdom, _attr.charisma);
    }
    
    function increase_constitution(uint _hero) external {
        _increase_base(_hero);
        ability_score storage _attr = ability_scores[_hero];
        _attr.constitution = _attr.constitution+1;
        emit Leveled(msg.sender, _hero, _attr.strength, _attr.dexterity, _attr.constitution, _attr.intelligence, _attr.wisdom, _attr.charisma);
    }
    
    function increase_intelligence(uint _hero) external {
        _increase_base(_hero);
        ability_score storage _attr = ability_scores[_hero];
        _attr.intelligence = _attr.intelligence+1;
        emit Leveled(msg.sender, _hero, _attr.strength, _attr.dexterity, _attr.constitution, _attr.intelligence, _attr.wisdom, _attr.charisma);
    }
    
    function increase_wisdom(uint _hero) external {
        _increase_base(_hero);
        ability_score storage _attr = ability_scores[_hero];
        _attr.wisdom = _attr.wisdom+1;
        emit Leveled(msg.sender, _hero, _attr.strength, _attr.dexterity, _attr.constitution, _attr.intelligence, _attr.wisdom, _attr.charisma);
    }
    
    function increase_charisma(uint _hero) external {
        _increase_base(_hero);
        ability_score storage _attr = ability_scores[_hero];
        _attr.charisma = _attr.charisma+1;
        emit Leveled(msg.sender, _hero, _attr.strength, _attr.dexterity, _attr.constitution, _attr.intelligence, _attr.wisdom, _attr.charisma);
    }
    
    
    function abilities_by_level(uint current_level) public pure returns (uint) {
        return current_level / 4;
    }
    
    
    function tokenURI(uint256 _hero) public view returns (string memory) {
        string memory output;
        {
        string[7] memory parts;
        ability_score memory _attr = ability_scores[_hero];
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("strength", " ", toString(_attr.strength), '</text><text x="10" y="40" class="base">'));

        parts[2] = string(abi.encodePacked("dexterity", " ", toString(_attr.dexterity), '</text><text x="10" y="60" class="base">'));

        parts[3] = string(abi.encodePacked("constitution", " ", toString(_attr.constitution), '</text><text x="10" y="60" class="base">'));

        parts[4] = string(abi.encodePacked("intelligence", " ", toString(_attr.intelligence),  '</text><text x="10" y="60" class="base">'));

        parts[5] = string(abi.encodePacked("wisdom", " ", toString(_attr.wisdom), '</text><text x="10" y="60" class="base">'));

        parts[6] = string(abi.encodePacked("charisma", " ", toString(_attr.charisma), '</text></svg>'));
        
        output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        }
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "hero #', toString(_hero), '", "description": "Rarity is achieved via an active economy, heros must level, gain feats, learn spells, to be able to craft gear. This allows for market driven rarity while allowing an ever growing economy. Feats, spells, and hero gear is ommitted as part of further expansions.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
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