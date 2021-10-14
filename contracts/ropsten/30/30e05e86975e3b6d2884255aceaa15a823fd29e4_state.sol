/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract state {
    struct HeroState {
        uint256 attack;
        uint256 health;
        string levelSeed;
        uint x;
        uint y;
    }
    mapping (address => HeroState) hero2stage;
    mapping (address => string) hero2state;

    function update(uint256 attack, uint256 health, string memory levelSeed, uint x, uint y) public {
        HeroState storage s = hero2stage[msg.sender];
        s.attack = attack;
        s.health = health;
        s.levelSeed = levelSeed;
        s.x = x;
        s.y = y;
    }

    function get() public view returns (HeroState memory) {
        return hero2stage[msg.sender];
    }


    function getState() public view returns (string memory) {
        return hero2state[msg.sender];
    }

    function saveState(string memory stateString) public {
        hero2state[msg.sender] = stateString;
    }
}