// Created using ICO Wizard https://github.com/poanetwork/ico-wizard by POA Network 
pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




/**
 * Registry of contracts deployed from ICO Wizard.
 */
contract Registry is Ownable {
  mapping (address => address[]) public deployedContracts;

  event Added(address indexed sender, address indexed deployAddress);

  function add(address deployAddress) public {
    deployedContracts[msg.sender].push(deployAddress);
    Added(msg.sender, deployAddress);
  }

  function count(address deployer) constant returns (uint) {
    return deployedContracts[deployer].length;
  }
}