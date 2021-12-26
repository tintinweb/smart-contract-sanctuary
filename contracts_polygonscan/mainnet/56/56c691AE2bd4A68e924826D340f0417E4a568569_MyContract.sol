/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/IDescriptorUser.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://ethereum.stackexchange.com/questions/27259/how-can-you-share-a-struct-definition-between-contracts-in-separate-files
interface IDescriptorUser {
  struct Descriptor {
    uint score;
    uint stars;
    uint traitCount;

    uint resurrectionPrice;
    uint resurrectionCount;
    uint onResurrectionScore;
    uint onResurrectionStars;
    uint onResurrectionTraitCount;
    string onResurrectionTokenURI;

    // required to recalculate probability density on exit from the game
    uint onGameEntryTraitCount; 
    uint deathTime;
    bool gameAllowed; // contract get the token to play only when this flag is true
  }
}


// File contracts/MyContract.sol


pragma solidity ^0.8.0;

contract MyContract is IDescriptorUser {
  mapping (uint=>Descriptor) _descriptors;
  address _game;
  uint _number;
  constructor(address game, uint number) {
    _game = game;
    _number = number;
  }

  function getDescriptor(uint tokenId)  public view returns(Descriptor memory) {
    return _descriptors[tokenId];
  }
  function setDescriptor(uint tokenId, Descriptor memory descriptor) public {
    _descriptors[tokenId] = descriptor;
  }
  function deleteDescriptor(uint tokenId) public {
    delete _descriptors[tokenId];
  }

}