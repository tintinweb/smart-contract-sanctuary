pragma solidity ^0.4.24;


/* Contract used to asign admins to Ethrental Rental Agreements */

contract owned {
  address public owner;
  mapping (address => bool) public admin;

  constructor() public {
    owner = msg.sender;
    admin[owner] = true;
  }

  modifier onlyOwner {
    require(msg.sender == owner,"Your know the owner of this smart contract. Bad account");
    _;
  }

  modifier onlyAdmin {
    require(admin[msg.sender]);
    _;
  }

  function addAdmin(address newAdmin) onlyOwner public {
    admin[newAdmin] = true;
  }

  function removeAdmin(address oldAdmin) onlyOwner public {
    admin[oldAdmin] = false;
  }

  function transferOwnership(address newOwner) public {
    require(msg.sender == owner,"Your are not the owner of this smart contract. Bad account");
    owner = newOwner;
  }
}