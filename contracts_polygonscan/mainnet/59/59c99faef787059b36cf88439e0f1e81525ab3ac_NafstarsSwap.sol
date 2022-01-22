/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTContract {
  function mint(address to) external;
  function mint(address to, uint256 cards) external;
  function burn(uint256 tokenId) external;
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract NafstarsSwap {
  INFTContract public FromContract;
  INFTContract public ToContract;

  bool public executed = false; 
  address public owner;

  constructor(address fromContractAddress, address toContractAddress) {
    FromContract = INFTContract(fromContractAddress);
    ToContract = INFTContract(toContractAddress);

    owner = msg.sender;
  }

  function batchSwap(uint256 fromId, uint256 toId) public virtual {
    require(owner == msg.sender, "Error: owner required");
    require(fromId <= toId, "Error: incorrect from/to values");

    for (uint256 i = fromId; i <= toId; i++) {
      swapGenesisPack(i);
    }
  }

  function swapGenesisPack(uint256 tokenId) public virtual {
    require(owner == msg.sender, "Error: owner required");

    address tokenOwner = FromContract.ownerOf(tokenId);
    FromContract.burn(tokenId);
    ToContract.mint(tokenOwner, 5);
  }
}