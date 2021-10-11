// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILandCollection.sol";
import "./IOre.sol";


contract CartelOreClaim is Ownable, ReentrancyGuard {
  // Collection token contract interface
  ILandCollection public collection;
  // Ore token contract interface
  IOre public ore;

  mapping (uint256 => bool) public claimedByTokenId;

  uint256 public orePerToken;
  uint256 public orePerSet;

  uint256 public totalTokenClaim;
  uint256 public totalSetClaim;

  constructor(address _ore, address _collection, uint256 _orePerToken, uint256 _orePerSet) {
    ore = IOre(_ore);
    collection = ILandCollection(_collection);
    orePerToken = _orePerToken;
    orePerSet = _orePerSet;
  }

  function unclaimedTokenIds(address _address) external view returns (uint256[] memory) {
    uint256 owned = collection.balanceOf(_address);
    uint256 count = 0;

    for (uint256 i = 0; i < owned; i++) {
      uint256 tokenId = collection.tokenOfOwnerByIndex(_address, i);
      uint256 groupId = tokenId / 100000;

      if ((groupId == 1000 || groupId == 1002) && !claimedByTokenId[tokenId]) {
        count++;
      }
    }

    uint256[] memory tokenIds = new uint256[](count);
    uint256 j = 0;
    for (uint256 i = 0; i < owned; i++) {
      uint256 tokenId = collection.tokenOfOwnerByIndex(_address, i);
      uint256 groupId = tokenId / 100000;

      if ((groupId == 1000 || groupId == 1002) && !claimedByTokenId[tokenId]) {
        tokenIds[j++] = tokenId;
      }
    }

    return tokenIds;
  }

  function claim(uint256[] calldata _tokenIds) external nonReentrant {
    // Limit up to 50 tokens to be processed
    uint256 maxCount = (_tokenIds.length > 50 ? 50 : _tokenIds.length);
    uint256 tokenCount = 0;
    uint256[] memory setCounter = new uint256[](7);

    // Iterate through all owned land-genesis collection tokens and calculate claimable ore
    // Then track the claims properly
    for (uint256 i = 0; i < maxCount; i++) {
      uint256 tokenId = _tokenIds[i];
      require(collection.ownerOf(tokenId) == msg.sender, "Invalid Tokens Specified");

      if (!claimedByTokenId[tokenId]) {
        tokenCount++;
        
        // Check for any claimable set bonus
        uint256 memberType;
        uint256 groupId = tokenId / 100000;
        uint256 memberId = tokenId % 100000;
        uint256 num;

        require(groupId == 1000 || groupId == 1002, "Invalid Token Id");

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

        setCounter[memberType]++;
        claimedByTokenId[tokenId] = true;
      }
    }

    uint256 totalOre = 0;

    if (tokenCount > 0) {
      totalTokenClaim += tokenCount;
      totalOre += tokenCount * orePerToken;
    }

    // Calculate the total number of set eligible for bonus
    uint256 setCount = maxCount;
    for (uint256 i = 0; i < 7; i++) {
      if (setCount > setCounter[i]) {
        setCount = setCounter[i];
      }
    }

    if (setCount > 0) {
      totalSetClaim += setCount;
      totalOre += setCount * orePerSet;
    }

    require(totalOre > 0, "Insufficient Claimable Ore");
    
    ore.mint(msg.sender, totalOre);
  }
}