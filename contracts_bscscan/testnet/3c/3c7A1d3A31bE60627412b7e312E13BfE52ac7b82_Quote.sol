/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract Quote {
  address public owner;
  string private message;  
  mapping (address => bool) public whiteList;

  constructor() {
      owner = msg.sender;
      whiteList[msg.sender] = true;
  }
  
  modifier onlyOwner {
      require(msg.sender == owner,"Only owner");
      _;
  }

  modifier onlyWhitelist {
      require(whiteList[msg.sender] == true, "Only whitelist");
      _;
  }

  function setQuote(string memory _message) public onlyWhitelist {
      message = _message;
  }

  function getQuote() public view returns (string memory) {
      return message;
  }

  function addMember (address _member) public onlyOwner {
      whiteList[_member] = true;
  }
  
  function delMember (address _member) public onlyOwner {
      whiteList[_member] = false;
  }   
}