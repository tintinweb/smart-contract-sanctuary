/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity >=0.7.0 <0.9.0;

 /**
   * This contract module provides a basic access control mechanism where
   * the owner can add or remove Approved Vaccination Centre's (APC)
   * and where a public query can be made to ascertain if an APC 
   * is on the whitelist, returning a boolean value
  */


contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * Set the original `owner` of the contract to the sender account
   */
   
  constructor() public{
    owner = msg.sender;
  }
  
  /**
   * checks if called by the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  /**
   * Allows transfer of ownership.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
   * function to allow additions to the whitelist, or deletion by the Owner
   * and allows a query for the whitelist
   */
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isAPCWhitelisted(msg.sender));
        _;
    }

    function addAPC(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeAPC(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isAPCWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}