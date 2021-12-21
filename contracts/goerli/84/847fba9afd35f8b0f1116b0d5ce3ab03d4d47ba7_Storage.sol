/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint roll;

    function rollTheDice(uint guess) public returns (string memory) {
        roll = random(6);
        if ( roll == guess ){
            return "Winner";
            // send some eth to the players account
        }else{
            return "Looser";
            // steal some eth from the players account :)
        }
    }

    function random(uint max) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % max +1;
    }

    function vieRoll() public view returns (uint){
        return roll;
    }
}