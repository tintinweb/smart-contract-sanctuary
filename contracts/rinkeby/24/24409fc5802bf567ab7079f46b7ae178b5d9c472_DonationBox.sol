/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity 0.5.16;

contract DonationBox {
  address payable owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(
      msg.sender == owner,
      "Only owner can call this function."
    );
    _;
  }

  function Donasi() payable external {}

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function greeting() public pure returns (string memory) {
    return "Hello, I am an ether receiver!";
  }

  function withdraw() onlyOwner public {
    owner.transfer(address(this).balance);
  }
}