/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.5.0;

contract Adoption {

  address[16] public adopters;  // 保存领养者的地址

    // 领养宠物
  function adopt(uint petId) public returns (uint) {
    require(petId >= 0 && petId <= 15);  // 确保id在数组长度内

    adopters[petId] = msg.sender;        // 保存调用这地址
    return petId;
  }

  // 返回领养者
  function getAdopters() public view returns (address[16] memory) {
    return adopters;
  }

}