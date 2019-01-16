pragma solidity ^0.4.25;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract IdentityService is Ownable {
    mapping(address => bytes32) public birthdays;
    
    function addID(address person, bytes32 hashdate) onlyOwner public{
        birthdays[person] = hashdate;
    }
}