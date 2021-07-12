/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// File: contracts/interfaces/IPositionStorage.sol
pragma solidity 0.6.12;
interface IPositionStorage {
  function createStrategy(address strategyLogic) external returns (bool);
  function setStrategy(uint256 strategyID, address strategyLogic) external returns (bool);
  function getStrategy(uint256 strategyID) external view returns (address);
  function newUserProduct(address user, address product) external returns (bool);
  function getUserProducts(address user) external view returns (address[] memory);
  function setFactory(address _factory) external returns (bool);
  function setProductToNFTID(address product, uint256 nftID) external returns (bool);
  function getNFTID(address product) external view returns (uint256);
}

// File: contracts/XFactory/storage/PositionStorage.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
  * @title BiFi-X Position Storage Contract
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract PositionStorage {
	address public owner;
  address public factory;

  struct Strategy {
    address logic;
    bool support;
  }

  mapping(uint256 => address) strategies;
  mapping(address => address[]) userProducts;
  mapping(address => uint256) productToNFTID;

  modifier onlyOwner {
    require((msg.sender == owner) || (msg.sender == factory), "onlyOwner");
    _;
  }

  modifier onlyFactory {
    require(msg.sender == factory, "onlyOwner");
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setFactory(address _factory) external onlyOwner returns (bool) {
    factory = _factory;
    return true;
  }

  function setStrategy(uint256 strategyID, address logic) external onlyOwner returns (bool) {
    strategies[strategyID] = logic;
    return true;
  }

  function getStrategy(uint256 strategyID) external view returns (address) {
    return strategies[strategyID];
  }

  function newUserProduct(address user, address product) external onlyFactory returns (bool) {
    userProducts[user].push(product);
    return true;
  }

  function getUserProducts(address user) external view returns (address[] memory) {
    return userProducts[user];
  }

  function setProductToNFTID(address product, uint256 nftID) external onlyFactory returns (bool){
    productToNFTID[product] = nftID;
    return true;
  }

  function getNFTID(address product) external view returns (uint256) {
    return productToNFTID[product];
  }
}