/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Randomizer {
    
    address public owner;
    address[] public addresses;
    uint public seedBlock;
    uint public seed;

    uint public winnerId;
    address public winnerAddress;
    
    constructor() public {
        owner = msg.sender;  
    }
    
    function addAddresses(address[] calldata _addresses) public {
        require(msg.sender == owner, "only owner");
        
        for(uint i = 0; i < _addresses.length; i++) {
            addresses.push(_addresses[i]);
        }
    }
    
    function setReady() public {
        require(msg.sender == owner, "only owner");
        seedBlock = block.number + 10;
    }
    
    function generateWinners() public {
        require(blockhash(seedBlock) != bytes32(0), "too early or expired");
        require(seed == 0, "already generated");
        
        seed = uint(keccak256(abi.encodePacked(blockhash(seedBlock), tx.gasprice, block.timestamp)));
        
        winnerId = random(addresses.length);
        winnerAddress = addresses[winnerId];
    }
    
    function random(uint totalAddresses) public view returns (uint) {
        return uint(keccak256(abi.encode(seed))) % totalAddresses;
    }
    
    function airdrop(address[] calldata addrs, uint256 tokenId) public {
        
    }
}