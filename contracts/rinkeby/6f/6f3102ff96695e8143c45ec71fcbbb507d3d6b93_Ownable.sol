/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity ^0.4.26;


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Own ()  public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner  public {
    if (newOwner != address(0)) owner = newOwner;
  }

}