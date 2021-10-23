/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract CrappyBirdPlus {
    mapping (address => uint) highScore;
    mapping (string => address) player;

    function getHighScore() public view returns (uint) {
        return highScore[msg.sender];
    }
    
    function setHighScore(string memory id,uint score) public {
        player[id] = msg.sender;
        highScore[msg.sender] = score;
    }

    function register(string memory id) public {
        player[id] = msg.sender;
    }

    function getHighScoreById(string calldata id) public view returns (uint) {
        return highScore[player[id]];
    }

    function getHighScoreByAddress(address addr) public view returns (uint) {
        return highScore[addr];
    }
    
}