/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract L {
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    mapping (string => uint) public NameToLs;
    event addedLtoName(string _name, uint Lstaken);
    function addLtoName(string memory _name) public {
        NameToLs[_name]++;
        emit addedLtoName(_name, NameToLs[_name]);
    }
    function sendAll() external payable { }
    function sendAllWd() public {
        require(address(this).balance > 0, "No sends :(");
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}