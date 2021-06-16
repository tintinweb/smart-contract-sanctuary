// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0; 

contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
 
  constructor(){
      owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,"Caller is not owner");
    _;
  }


}