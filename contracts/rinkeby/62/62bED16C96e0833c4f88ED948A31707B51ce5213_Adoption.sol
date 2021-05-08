/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity ^0.5.0;

contract Adoption {
  address[16] public adopters;

  event Adopted(uint petId, address owner);

  function adopt(uint petId) external returns (uint) {
    require(petId >= 0 && petId <= 15);

    address owner = msg.sender;
    adopters[petId] = owner;

    emit Adopted(petId, owner);

    return petId;
  }

  function getAdopters() external view returns (address[16] memory) {
    return adopters;
  }
}