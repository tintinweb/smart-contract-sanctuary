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
    bool onSale;
    uint flag;
  }
}


// File contracts/MyContract.sol


pragma solidity ^0.8.0;

contract MyContract is IDescriptorUser {
  mapping (uint=>Descriptor) _descriptors;
  address public game = 0x591bF5B96b18d02E6B187b917c759Cc5FD94242d;
  uint public number = 1;
  Descriptor public descriptorInStorage;
  uint public number2;

  function getDescriptor(uint tokenId)  public view returns(Descriptor memory) {
    return _descriptors[tokenId];
  }
  function setDescriptor(uint tokenId, Descriptor memory descriptor) public {
    _descriptors[tokenId] = descriptor;
  }
  function deleteDescriptor(uint tokenId) public {
    delete _descriptors[tokenId];
  }

  function setNumber2(uint _number2) public  {
    number2 = _number2;
  }

  function setDescriptorInStorage(Descriptor memory descriptor) public {
    descriptorInStorage = descriptor;
  }
}