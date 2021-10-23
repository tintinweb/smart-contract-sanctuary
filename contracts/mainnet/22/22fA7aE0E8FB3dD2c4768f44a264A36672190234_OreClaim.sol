// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILandCollection.sol";
import "./IOre.sol";


// Handles weekly ore claims for genesis token holders
contract OreClaim is Ownable, ReentrancyGuard {
  // Collection token contract interface
  ILandCollection public collection;
  // Ore token contract interface
  IOre public ore;

  // Stores the timestamp of the initial claim week for each group
  mapping (uint256 => uint256) private _initialClaimTimestampByGroupId;
  // Stores the last claimed week count for each token
  mapping (uint256 => uint256) private _lastClaimedWeekByTokenId;
  // Stores the timestamp for the final claimable week in the case of contract upgrade
  uint256 private _finalClaimTimestamp;
  // Determines the maximum number of claimable tokens in a single tx
  uint256 private _claimLimit;

  // Amount of ore claimable for each token based on the groupId per week
  mapping (uint256 => uint256) public orePerTokenByGroupId;
  // Amount of ore claimable for each cartel set per week
  uint256 public orePerCartelSet;

  // Stores analytic data regarding total amount claims
  uint256 public totalTokenClaim;
  uint256 public totalCartelSetClaim;

  constructor(address _ore, address _collection) {
    ore = IOre(_ore);
    collection = ILandCollection(_collection);
    _claimLimit = 70;
  }

  function lastClaimedWeekByTokenId(uint256 _tokenId) external view returns (uint256) {
    return _lastClaimedWeekByTokenId[_tokenId];
  }

  function initialClaimTimestampByGroupId(uint256 _groupId) external view returns (uint256) {
    return _initialClaimTimestampByGroupId[_groupId];
  }

  function setInitialClaimTimestamp(uint256 _groupId, uint256 _timestamp) external onlyOwner {
    _initialClaimTimestampByGroupId[_groupId] = _timestamp;
  }

  function finalClaimTimestamp() external view returns (uint256) {
    return _finalClaimTimestamp;
  }

  function setFinalClaimTimestamp(uint256 _timestamp) external onlyOwner {
    _finalClaimTimestamp = _timestamp;
  }

  function claimLimit() external view returns (uint256) {
    return _claimLimit;
  }

  function setClaimLimit(uint256 _limit) external onlyOwner {
    require(_claimLimit > 0, "Invalid Limit");
    _claimLimit = _limit;
  }

  function setOrePerTokenByGroupId(uint256 _groupId, uint256 _amount) external onlyOwner {
    orePerTokenByGroupId[_groupId] = _amount;
  }

  function setOrePerCartelSet(uint256 _amount) external onlyOwner {
    orePerCartelSet = _amount;
  }

  function claimWeek(uint256 _groupId) public view returns (uint256) {
    // Calculate and return the number of weeks elapsed since the initial claim timestamp for the groupId 
    uint256 initial = _initialClaimTimestampByGroupId[_groupId];
    require(initial > 0, "Weekly Claim Not Started For The Specified Group");

    // In the case of the claiming being paused for the current contract due to contract upgrade
    // make sure that the maximum claimable week is within the set final timestamp
    uint256 timestamp = (_finalClaimTimestamp > 0 && block.timestamp > _finalClaimTimestamp ? _finalClaimTimestamp : block.timestamp);
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
      uint256 lastClaimedWeek = _lastClaimedWeekByTokenId[tokenId];

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
      uint256 lastClaimedWeek = _lastClaimedWeekByTokenId[tokenId];

      if (currentWeek > lastClaimedWeek) {
        tokenIds[j] = tokenId;
        elapsedWeeks[j++] = currentWeek - lastClaimedWeek;
      }
    }

    return (tokenIds, elapsedWeeks);
  }

  function claim(uint256[] calldata _tokenIds) external nonReentrant {
    // Limit up to certain number of tokens to be processed
    uint256 maxCount = (_tokenIds.length > _claimLimit ? _claimLimit : _tokenIds.length);
    uint256 totalOre = 0;
    uint256[] memory setCounter = new uint256[](7);

    // Iterate through all owned land-genesis collection tokens and calculate claimable ore
    // Then track the claims properly
    for (uint256 i = 0; i < maxCount; i++) {
      uint256 tokenId = _tokenIds[i];
      uint256 lastClaimed = _lastClaimedWeekByTokenId[tokenId];
      uint256 groupId = tokenId / 100000;
      uint256 memberId = tokenId % 100000;
      uint256 currentWeek = claimWeek(groupId);

      if (collection.ownerOf(tokenId) == msg.sender && orePerTokenByGroupId[groupId] > 0 && currentWeek > lastClaimed) {
        uint256 claimableWeeks = currentWeek - lastClaimed;

        // Check for any claimable set bonus for cartels only if needed
        if (maxCount >= 7 && (groupId == 1000 || groupId == 1002)) {
          uint256 memberType;
          uint256 num;

          if (groupId == 1000) {
            num = memberId - 1;
          } else if (groupId == 1002) {
            num = memberId + 1255;
          }

          if (num % 9 == 0) {
            memberType = num % 5;
          } else if (num % 10 == 0) {
            memberType = num % 6;
          } else {
            memberType = num % 7;
          }

          setCounter[memberType] += claimableWeeks;
        }

        totalOre += orePerTokenByGroupId[groupId] * claimableWeeks;
        totalTokenClaim += claimableWeeks;
        _lastClaimedWeekByTokenId[tokenId] = currentWeek;
      }
    }

    // Calculate the total number of set eligible for cartel set bonus
    uint256 setCount = maxCount;
    for (uint256 i = 0; i < 7; i++) {
      if (setCount > setCounter[i]) {
        setCount = setCounter[i];
      }
    }

    if (setCount > 0) {
      totalCartelSetClaim += setCount;
      totalOre += setCount * orePerCartelSet;
    }

    require(totalOre > 0, "Insufficient Claimable Ore");
    
    ore.mint(msg.sender, totalOre);
  }
}