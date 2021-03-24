/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Selector {
    
    constructor() {} 
    function calculateSelector() public pure returns (bytes4) {
        
        return  bytes4(keccak256('battlePoints(uint16)')) ^ bytes4(keccak256('_increaseWins(uint16)')) ^ bytes4(keccak256('_increaseLosses(uint16)')) ^ bytes4(keccak256('isBanned(uint16)')) ^ bytes4(keccak256('getStamina(uint16)')) ^ bytes4(keccak256('getBirthday(uint16)'));
    
    }
}