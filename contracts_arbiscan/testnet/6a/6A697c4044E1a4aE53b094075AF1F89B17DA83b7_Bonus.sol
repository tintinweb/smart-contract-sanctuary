// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function realmFeatures(uint256 realmId, uint256 index)
    external
    view
    returns (uint256);

  function totalSupply() external view returns (uint256);
}

interface IManager {
  function isAdmin(address _addr) external view returns (bool);
}

contract Bonus {
  IRealm public immutable REALM;
  IManager public immutable MANAGER;

  uint256[8] public featureBonus = [2, 11, 12, 14, 17, 20, 23, 33];

  uint256 public maxSupply = 5000;

  // EVENTS

  event maxSupplyUpdated(uint256 maxSupply);

  constructor(address realm, address manager) {
    REALM = IRealm(realm);
    MANAGER = IManager(manager);
  }

  // MODIFIER

  modifier onlyAdmins() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  // EXTERNAL

  function amount(uint256 _realmId) external view returns (uint256) {
    return _features(_realmId) + _supply();
  }

  // ADMINS

  function updateMaxSupply(uint256 _maxSupply) external onlyAdmins {
    maxSupply = _maxSupply;

    emit maxSupplyUpdated(maxSupply);
  }

  // INTERNAL

  function _features(uint256 _realmId) internal view returns (uint256) {
    uint256 feature1 = REALM.realmFeatures(_realmId, 0);
    uint256 feature2 = REALM.realmFeatures(_realmId, 1);
    uint256 feature3 = REALM.realmFeatures(_realmId, 2);
    uint256 b;

    for (uint256 i; i < featureBonus.length; i++) {
      if (
        feature1 == featureBonus[i] ||
        feature2 == featureBonus[i] ||
        feature3 == featureBonus[i]
      ) {
        b += 1;
      }
    }

    return b;
  }

  function _supply() internal view returns (uint256) {
    uint256 supply = REALM.totalSupply();

    if (supply < 250) {
      return 0;
    } else if (supply < 1000) {
      return 1;
    } else if (supply < 1500) {
      return 2;
    } else if (supply < 2000) {
      return 3;
    } else if (supply < 2500) {
      return 4;
    } else if (supply < 3000) {
      return 5;
    } else if (supply < 3500) {
      return 6;
    } else if (supply < 4000) {
      return 7;
    } else if (supply < 4500) {
      return 8;
    } else {
      return 9;
    }
  }
}