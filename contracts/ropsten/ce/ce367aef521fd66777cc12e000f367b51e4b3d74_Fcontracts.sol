/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity >=0.4.22 <0.9.0;

contract Fcontracts {

  mapping (address => uint) fcontracts;

  function updateFcontracts(uint fcontract) public {
    fcontracts[msg.sender] = getFcontracts(msg.sender) + fcontract;
  }

  function getFcontracts(address addr) public view returns(uint) {
    return fcontracts[addr];
  }

}