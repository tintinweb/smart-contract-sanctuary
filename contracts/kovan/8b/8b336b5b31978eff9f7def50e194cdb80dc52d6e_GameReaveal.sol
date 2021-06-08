/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.0;

contract GameReaveal {
    bytes32 public hash;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    /* Manager sets the hash and send the reward */
    function setHash(string memory _solution) payable external {
        require(owner == msg.sender);

        hash = keccak256(abi.encode(_solution));
    }
    
    /* Player tries to find the solution by putting a hash to get the reward. */
    function play(string memory _solution) payable external {
        require(hash == keccak256(abi.encode(_solution)));
        
        address payable player = payable(msg.sender);
        
        player.transfer(address(this).balance);
    }
    
    function getRewardAmount() external view returns (uint)  {
        return address(this).balance;
    }
}