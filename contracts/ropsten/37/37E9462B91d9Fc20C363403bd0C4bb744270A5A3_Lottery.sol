/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Lottery {
    address public banker;
    address[] public victims;
    
    constructor() {
        banker = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= 0.1 ether, 'please send more than 0.1 ether');
        victims.push(msg.sender);
    }
    
    function draw() public returns(uint) {
        require(msg.sender == banker, 'you are not allowed');
        uint index = random() % victims.length;
        payable(victims[index]).transfer(address(this).balance);
        victims = new address[](0);
        return index;
    }
    
    function random() private view returns (uint){
        return uint(keccak256(abi.encode(block.timestamp)));
    }
}