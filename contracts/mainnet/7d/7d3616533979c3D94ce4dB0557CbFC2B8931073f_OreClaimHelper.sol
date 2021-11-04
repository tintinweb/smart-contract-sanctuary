// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./ILandCollection.sol";
import "./IOreClaim.sol";


// Contains getter methods used by the webapp for ore claiming
contract OreClaimHelper is Ownable {
  // Collection token contract interface
  ILandCollection public collection;
  // Ore token contract interface
  IOreClaim public oreClaim;

  constructor(address _oreClaim, address _collection) {
    oreClaim = IOreClaim(_oreClaim);
    collection = ILandCollection(_collection);
  }

  function claimWeek(uint256 _groupId) public view returns (uint256) {
    // Calculate and return the number of weeks elapsed since the initial claim timestamp for the groupId 
    uint256 initial = oreClaim.initialClaimTimestampByGroupId(_groupId);
    // In the case of the claiming being paused for the current contract due to contract upgrade
    // make sure that the maximum claimable week is within the set final timestamp
    uint256 finalClaimTimestamp = oreClaim.finalClaimTimestamp();
    uint256 timestamp = (finalClaimTimestamp > 0 && block.timestamp > finalClaimTimestamp ? finalClaimTimestamp : block.timestamp);

    if (initial == 0 || timestamp < initial) {
      return 0;
    }

    uint256 elapsed = timestamp - initial;
    return (elapsed / 60 / 60 / 24 / 7) + 1;
  }

  // Returns the list of tokenIds (with elapsed weeks for each) eligible for claiming owned by the specified address
  function unclaimedTokenIds(address _address) external view returns (uint256[] memory, uint256[] memory) {
    uint256 owned = collection.balanceOf(_address);
    uint256 count = 0;

    // Count the total number of eligible tokens
    for (uint256 i = 0; i < owned; i++) {
      uint256 tokenId = collection.tokenOfOwnerByIndex(_address, i);
      uint256 groupId = tokenId / 100000;
      
      uint256 currentWeek = claimWeek(groupId);
      uint256 lastClaimedWeek = oreClaim.lastClaimedWeekByTokenId(tokenId);

      if (currentWeek > lastClaimedWeek) {
        count++;
      }
    }

    // Fill the array to be returned containing the eligible tokenIds along with the elapsed weeks
    uint256[] memory tokenIds = new uint256[](count);
    uint256[] memory elapsedWeeks = new uint256[](count);
    uint256 j = 0;
    for (uint256 i = 0; i < owned; i++) {
      uint256 tokenId = collection.tokenOfOwnerByIndex(_address, i);
      uint256 groupId = tokenId / 100000;
      uint256 currentWeek = claimWeek(groupId);
      uint256 lastClaimedWeek = oreClaim.lastClaimedWeekByTokenId(tokenId);

      if (currentWeek > lastClaimedWeek) {
        tokenIds[j] = tokenId;
        elapsedWeeks[j++] = currentWeek - lastClaimedWeek;
      }
    }

    return (tokenIds, elapsedWeeks);
  }
}