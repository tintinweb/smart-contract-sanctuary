pragma solidity ^0.4.24;

contract Fcontracts {

  mapping (address => uint) fcontracts;

  function updateFcontracts(uint fcontract) public {
    fcontracts[msg.sender] = getFcontracts(msg.sender) + fcontract;
  }

  function getFcontracts(address addr) public view returns(uint) {
    return fcontracts[addr];
  }

}