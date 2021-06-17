/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Storage {
  address public owner;
  uint256 public number;

  constructor(uint256 _number) public {
    owner = msg.sender;
    number = _number;
  }

  function getNumber() public view returns(uint256){
    return number;
  }

  function changeNumber(uint256 _number)public  returns( bool){
    require(owner == msg.sender, "Only owner allow to change it.");
    number = _number;
    return true;
  }

  function getOwnerAddress()public view returns(address){
    return owner;
  }

  function changeOwner(address _address)public returns(bool){
    require(owner == msg.sender, "Only owner allow to change it.");
    owner = _address;
    return true;
  }

}