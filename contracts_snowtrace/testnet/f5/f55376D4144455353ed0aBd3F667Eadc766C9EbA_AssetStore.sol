// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IFactory.sol";

contract AssetStore {
  struct Asset {
    string name;
    string promo;
    string[] asset;
    address author;
    uint256 price;
    uint256 stock;
  }

  event AssetUpdated(uint256 assetId, Asset asset);

  address implementation_;
  address admin_;

  bool public initialized;

  IFactory public factory;
  Asset[] assets;
  mapping(uint256 => uint256) public mints;

  function initialize(address _factory) external {
    require(msg.sender == admin_);
    require(!initialized);
    initialized = true;
    factory = IFactory(_factory);
  }

  modifier onlyAuthor(uint256 assetId) {
    require(msg.sender == assets[assetId].author);
    _;
  }

  function registerAsset(
    uint256 index,
    string calldata name,
    string calldata promo,
    string[] calldata asset,
    uint256 price,
    uint256 stock
  ) external returns (uint256 assetId) {
    require(msg.sender == factory.utilities(index));
    assetId = assets.length;
    assets.push(Asset(name, promo, asset, msg.sender, price, stock));
    emit AssetUpdated(assetId, assets[assetId]);
  }

  function updateAssetPrice(uint256 assetId, uint256 price) external onlyAuthor(assetId) {
    require(price <= assets[assetId].price);
    assets[assetId].price = price;
    emit AssetUpdated(assetId, assets[assetId]);
  }

  function getAsset(uint256 assetId) external view returns (Asset memory) {
    return assets[assetId];
  }

  function totalAssets() external view returns (uint256 total) {
    total = assets.length;
  }

  function useAsset(uint256 assetId, uint256 amount) external onlyAuthor(assetId) returns (uint256 cost) {
    require(amount <= assets[assetId].stock);
    assets[assetId].stock -= amount;
    cost = assets[assetId].price * amount;
    emit AssetUpdated(assetId, assets[assetId]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
  function owner() external view returns (address);

  function treasury() external view returns (address);

  function store() external view returns (address);

  function utilities(uint256) external view returns (address);
}