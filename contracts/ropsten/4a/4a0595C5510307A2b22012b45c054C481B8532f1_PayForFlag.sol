/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract PayForFlag {
    string flag;
    address payable public owner;
    constructor(string memory _flag) payable {
        owner = payable(msg.sender);
        flag = _flag;
    }

    function getFlag() public payable returns (string memory){
        require(msg.value == 0.000314159 ether);
        payable(msg.sender).transfer(0.000314159 ether);
        return flag;
    }
}