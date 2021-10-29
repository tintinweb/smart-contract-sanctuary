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