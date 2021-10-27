// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FundMe {
  address owner;
  uint256 funds;

  constructor() {
    owner = msg.sender;
  }

  function fund() public payable {
    funds += msg.value;
  }  

  function getFunds() public view returns(uint256) {
    return funds;
  }

  modifier isOwner {
    require(msg.sender == owner);
    _;
  }

  function withdraw() public isOwner payable {
    payable(owner).transfer(address(this).balance);
    funds = 0;
  }
}