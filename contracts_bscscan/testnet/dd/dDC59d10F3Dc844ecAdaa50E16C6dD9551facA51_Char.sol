/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Char {

    struct Character {
        uint32 race;
        uint32 attack;
        uint32 speed;
        uint32 defence;
        uint32 intelligence;
        uint32 level;
    }

    Character defaultHuman = Character(1,2,2,1,1,1);
    Character defaultDwarf = Character(2,2,1,2,1,1);
    Character defaultElf = Character(3,1,2,1,2,1);
    Character defaultHalfling = Character(4,1,1,2,2,1);

    mapping(address => Character) public charInfo;

    function createChar(uint32 _race, uint32 _attack, uint32 _speed, uint32 _defence, uint32 _intelligence) public {
        require(_attack + _speed + _defence + _intelligence < 4, "too many points added");
        require(charInfo[msg.sender].race == 0, "character exists");
        Character memory baseChar;
        if (_race == 1) {
            baseChar = defaultHuman;
        } else if (_race == 2) {
            baseChar = defaultDwarf;
        } else if (_race == 3) {
            baseChar = defaultElf;
        } else if (_race == 4) {
            baseChar = defaultHalfling;
        }

        baseChar.attack += _attack;
        baseChar.speed += _speed;
        baseChar.defence += _defence;
        baseChar.intelligence += _intelligence;

        charInfo[msg.sender] = baseChar;
    }

    function levelUp (uint32 _attack, uint32 _speed, uint32 _defence, uint32 _intelligence) public {
        require(_attack + _speed + _defence + _intelligence < 4, "too many points added");
        require(charInfo[msg.sender].race != 0, "character does not exist");

        charInfo[msg.sender].attack += _attack;
        charInfo[msg.sender].speed += _speed;
        charInfo[msg.sender].defence += _defence;
        charInfo[msg.sender].intelligence += _intelligence;

    }

}