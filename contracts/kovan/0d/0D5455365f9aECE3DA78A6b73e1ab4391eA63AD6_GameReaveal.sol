/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.0;

contract GameReaveal {
    
    bytes32 public hash;
    address owner;
    
    constructor() {
    owner = msg.sender;
    }
   
    /* Manager sets the hash and send the reward*/
    function setHash(string memory _solution) payable external {
        require(owner == msg.sender);
        hash = keccak256(abi.encode(_solution));
    }
    //  function setHash(bytes32 __hash) payable external {
    //     require(owner == msg.sender);
    //     hash = _hash;
    // }
    
    // function getHash(string memory _solution) pure external returns (bytes32) {
    //     returns keccak256(abi.encode(_solution));
    // }
    /* PLayer tries to find the solution by putting a hash to get the reward */ 
    function play(string memory _solution) payable external {
        require(hash == keccak256(abi.encode(_solution)));
        
    address payable player = payable(msg.sender);
    
    // address(this).send(player);
    player.transfer(address(this).balance);
    }
    
    function computeHash(string memory _solution, string memory _salt) pure external returns (bytes32) {
        return keccak256(abi.encodePacked(_solution, _salt));
    }
    
    function getRewardAmount() external view returns (uint)  {
        return address(this).balance;
    }
}