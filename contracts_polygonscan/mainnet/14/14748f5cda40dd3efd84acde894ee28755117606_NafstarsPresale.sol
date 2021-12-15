/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTContract {
  function mint(address to) external;
}

interface IWETH {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract NafstarsPresale {
  INFTContract public NFTContract;
  IWETH public WETH;
  address private _wallet;

  uint256 private salesLimit;
  uint256 private salesCounter;

  constructor(address contractAddress, address wethAddress, address wallet) {
    NFTContract = INFTContract(contractAddress);
    WETH = IWETH(wethAddress);
    _wallet = wallet;

    salesLimit = 875;
  }

  function sold() public view virtual returns (uint256) {
    return salesCounter;
  }

  function limit() public view virtual returns (uint256) {
    return salesLimit;
  }

  function remaining() public view virtual returns (uint256) {
    return salesLimit - salesCounter;
  }

  function mint() public virtual {
    require(block.timestamp > 1639587600, "Presale not started");
    require(salesCounter < salesLimit, "NFTs are sold out");

    WETH.transferFrom(msg.sender, _wallet, 0.25 ether);
    salesCounter = salesCounter + 1;

    NFTContract.mint(msg.sender);
  }

  function batchMint(uint256 total) public virtual {
    require(block.timestamp > 1639587600, "Presale not started");
    require(salesCounter < salesLimit, "NFTs are sold out");
    require(total > 0, "Invalid total");
    require(total <= 100, "Batch minting is limited to 100 NFTs");
    require(salesCounter + total <= salesLimit, "Not enough NFTs available");

    WETH.transferFrom(msg.sender, _wallet, total * 0.25 ether);
    salesCounter = salesCounter + total;

    for (uint256 i = 0; i < total; i++) {
      NFTContract.mint(msg.sender);
    }
  }
}