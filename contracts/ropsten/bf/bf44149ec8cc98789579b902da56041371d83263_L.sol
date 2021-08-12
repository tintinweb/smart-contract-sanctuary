pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "./ownable.sol";

contract L is Ownable {
    mapping (string => uint) public NameToLs;
    
    event addedLToName(string _name, uint Lstaken);
    
    function addLToName(string memory _name, uint _Lstoadd) public {
        NameToLs[_name] += _Lstoadd;
        emit addedLToName(_name, NameToLs[_name]);
    }
    
    function sendAll() external payable { }
    
    function sendAllWd() public onlyOwner {
        require(address(this).balance > 0, "No hab ma'am.");
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}