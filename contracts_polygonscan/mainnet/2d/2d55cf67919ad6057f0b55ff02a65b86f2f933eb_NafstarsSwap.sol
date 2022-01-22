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

  constructor(address fromContractAddress, address toContractAddress) {
    FromContract = INFTContract(fromContractAddress);
    ToContract = INFTContract(toContractAddress);
  }

  function swap() public virtual {
    require(executed == false, "Error: swap already executed");

    uint256 supply = FromContract.totalSupply();
    for (uint256 i = 1; i <= supply; i++) {
      ToContract.mint(FromContract.ownerOf(i), 5);
      FromContract.burn(i);
    }

    executed = true;
  }
}