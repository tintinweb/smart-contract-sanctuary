/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string[] public greeting;
    address owner;

    constructor(string memory _greeting) payable {
        greeting.push(_greeting);
        owner = msg.sender;
    }

    function greet(uint index) public view returns (string memory) {
        return greeting[index];
    }

    function addGreeting(string memory _greeting) public {
        greeting.push(_greeting);
    }

    function iNeedEther(uint _amount) public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(_amount);
    }
}