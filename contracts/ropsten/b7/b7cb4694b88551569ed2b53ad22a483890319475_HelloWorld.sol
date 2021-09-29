/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract HelloWorld {

    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function hello() public view returns (string memory) {
        return message;
    }

    function setMessage(string memory _message) public payable {
        require(msg.value > 1 ether);
        message = _message;
    }
}