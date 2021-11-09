/**
 *Submitted for verification at polygonscan.com on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Randomizer {
    
    address public owner;
    
    uint public seedBlock;
    uint public seed;
    
    uint public totalAddressesId2 = 7444;
    uint public totalAddressesId3 = 665;
    
    uint nonce = 1;
    
    address[] public addressesForId2;
    address[] public addressesForId3;
    
    address[] public winnersId2;
    address public winnerId3;
    
    constructor() public {
        owner = msg.sender;  
    }
    
    function addAddressesForId2(address[] calldata _addresses) public {
        require(msg.sender == owner, "only owner");
        
        for(uint i = 0; i < _addresses.length; i++) {
            addressesForId2.push(_addresses[i]);
        }
    }
    
    function addAddressesForId3(address[] calldata _addresses) public {
        require(msg.sender == owner, "only owner");
        
        for(uint i = 0; i < _addresses.length; i++) {
            addressesForId3.push(_addresses[i]);
        }
    }
    
    function setReady() public {
        require(msg.sender == owner, "only owner");
        seedBlock = block.number + 10;
        
        // require(totalAddressesId2 == addressesForId2.length, "something wrong with id2 addresses");
        require(totalAddressesId3 == addressesForId3.length, "something wrong with id3 addresses");
    }
    
    function generateWinners() public {
        require(blockhash(seedBlock) != bytes32(0), "too early or expired");
        require(seed == 0, "already generated");
        
        uint winner;
        
        seed = uint(keccak256(abi.encodePacked(blockhash(seedBlock), tx.gasprice, block.timestamp)));
        
        //ID 2
        // for(uint i = 0; i < 30; i++) {
        //     winner = random(totalAddressesId2);
        //     winnersId2.push(addressesForId2[winner]);
        //     nonce++;
        // }
        
        //ID 3
        winner = random(totalAddressesId3);
        winnerId3 = addressesForId3[winner];
    }
    
    function random(uint totalAddresses) public view returns (uint) {
        return uint(keccak256(abi.encode(seed, nonce))) % totalAddresses;
    }
}