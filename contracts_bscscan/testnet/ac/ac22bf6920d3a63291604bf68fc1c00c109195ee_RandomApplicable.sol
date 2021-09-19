/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomApplicable {
    // ############
    // Views
    // ############
    /**
    Get a random number from 0 to max - 1
    */
    function random(uint256 max, uint256 bonusNonce) public view returns(uint256) {
        uint256 newRandomNonce = block.number + bonusNonce;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newRandomNonce))) % max;
        return randomNumber;
    }

    /**
    Get a random number from min to max - 1
    */
    function randomBetween(uint256 min, uint256 max, uint256 bonusNonce) public view returns(uint256) {
        require(max>min, "Max must larger than min");
        uint256 newRandomNonce = block.number + bonusNonce;
        uint256 delta = max - min;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newRandomNonce)))%delta;
        return min + randomNumber;
    }
}