//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";

contract RaiderInfo is Ownable, Pausable {

  // Easier to use an array, the order is TokenId, Race, Generation
  mapping(uint => uint[3]) raiderInfo;
  mapping(uint => bool) public raiderInfoAdded;
  mapping(uint => bool) public invalidRaider;
  mapping(uint => uint) public recruitedCount;

  // EVENTs

  event raiderAdded(uint tokenId, uint race, uint generation);

  function addRaider(uint _tokenId, uint _race, uint _generation) public onlyOwner {
    require(raiderInfoAdded[_tokenId] == false, "This Raider has already been added!");
    raiderInfo[_tokenId] = [
      _tokenId,
      _race,
      _generation
    ];
    raiderInfoAdded[_tokenId] = true;
    emit raiderAdded(_tokenId, _race, _generation);
  }

  function add10Raiders(
    uint[3] memory raider1, 
    uint[3] memory raider2, 
    uint[3] memory raider3, 
    uint[3] memory raider4, 
    uint[3] memory raider5,
    uint[3] memory raider6,
    uint[3] memory raider7,
    uint[3] memory raider8,
    uint[3] memory raider9,
    uint[3] memory raider10
  ) public onlyOwner {
    addRaider(raider1[0], raider1[1], raider1[2]);
    addRaider(raider2[0], raider2[1], raider2[2]);
    addRaider(raider3[0], raider3[1], raider3[2]);
    addRaider(raider4[0], raider4[1], raider4[2]);
    addRaider(raider5[0], raider5[1], raider5[2]);
    addRaider(raider6[0], raider6[1], raider6[2]);
    addRaider(raider7[0], raider7[1], raider7[2]);
    addRaider(raider8[0], raider8[1], raider8[2]);
    addRaider(raider9[0], raider9[1], raider9[2]);
    addRaider(raider10[0], raider10[1], raider10[2]);
  }

  function updateRaider(uint _tokenId, uint _race, uint _generation) public onlyOwner {
    raiderInfo[_tokenId] = [_tokenId, _race, _generation];
  }

  function addRecruitCount(uint _tokenId) public onlyOwner {
    recruitedCount[_tokenId] = recruitedCount[_tokenId] + 1;
  }

  function markInvalid(uint _tokenId) public onlyOwner {
    invalidRaider[_tokenId] = true;
  }

  function checkRaider(uint _tokenId) external view returns(uint[3] memory) {
    return raiderInfo[_tokenId];
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}