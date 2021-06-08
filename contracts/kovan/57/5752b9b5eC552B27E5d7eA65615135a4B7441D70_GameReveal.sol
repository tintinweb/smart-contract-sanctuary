/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.8.0;

contract GameReveal {
    bytes32 public hash;
    //bytes32 hash;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    /* Manager sets the hash, and the reward amount (payable) */
    function setHash(bytes32 _hash) payable external {
        require(owner == msg.sender);
        
        hash = _hash;
        //hash = keccak256(abi.encode(_solution));
    }
    
    function getHash(string memory _solution) pure external returns(bytes32) {
        return keccak256(abi.encode(_solution));
    }
    
    function play(string memory _solution) payable external {
       // require: throws exception if condition not met (refund)
       require(hash == keccak256(abi.encode(_solution)));
       
       // send reward
       address payable player= payable(msg.sender);
       
       player.transfer(address(this).balance);
       //address(this).send(player);
   }
   
   function getRewardAmount() external view returns(uint) {
       return address(this).balance;
   }
}