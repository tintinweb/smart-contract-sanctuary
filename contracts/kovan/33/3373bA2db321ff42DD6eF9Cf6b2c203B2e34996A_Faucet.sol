/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {

    address public owner;
    mapping (address => bool) knownList;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(uint _amount) public {
        require(_amount <= 100000000000000000);
        require(knownList[msg.sender] == false);
        payable(msg.sender).transfer(_amount);
        knownList[msg.sender] = true;
    }

    // fallback function
    receive() external payable {}
}