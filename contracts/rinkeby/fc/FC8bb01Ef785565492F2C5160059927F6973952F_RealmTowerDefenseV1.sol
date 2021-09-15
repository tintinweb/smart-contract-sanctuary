// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 realmId) external view returns (address owner);

  function getApproved(uint256 realmId) external view returns (address approved);

  function wealth(uint256 realmId) external view returns (uint256 wealth);

  function spendWealth(uint256 realmId, uint256 wealth) external view;
}

contract RealmTowerDefenseV1 {
  uint256 private constant BUILD_HOURS = 24 hours;
  uint256 private constant UPGRADE_HOURS = 12 hours;
  uint256 private constant WAVE_HOURS = 3 hours;

  struct Defender {
    uint256 level;
  }

  // 0 - single damage
  // 1 - multi damage
  // 2 - splash damage
  // 3 - effect damage
  // 4 - elemental damage
  mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public towers;

  mapping(uint256 => uint256) public buildTime;
  mapping(uint256 => uint256) public waveTime;
  mapping(uint256 => uint256) public upgradeTime;
  mapping(uint256 => Defender) public defenders;

  event BuildTower(uint256 realmId, uint256 kind, uint256 level);
  event UpgradeTower(uint256 realmId, uint256 kind, uint256 levelRemoved, uint256 levelAdded);
  event waveCompleted(uint256 realmId, uint256 level);

  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);

  function buildTower(uint256 _realmId, uint256 _kind) external {
    require(REALM.ownerOf(_realmId) == msg.sender || REALM.getApproved(_realmId) == msg.sender);
    require(_kind < 5, "Tower type doesn't exist");
    //require(block.timestamp > buildTime[_realmId], "You are currently building");

    // if (_kind == 3) {
    //   require(defenders[_realmId].level > 150, "Must be level 100");
    // }

    // if (_kind == 4) {
    //   require(defenders[_realmId].level > 200, "Must be level 200");
    // }

    towers[_realmId][_kind][0]++;

    buildTime[_realmId] = block.timestamp + (BUILD_HOURS * (_kind + 1));

    emit BuildTower(_realmId, _kind, 0);
  }

  function upgradeTower(
    uint256 _realmId,
    uint256 _kind,
    uint256 _level
  ) external {
    require(REALM.ownerOf(_realmId) == msg.sender || REALM.getApproved(_realmId) == msg.sender);
    require(_kind < 5, "Tower type doesn't exist");
    require(_level < 3, "Level doesn't exist");
    // require(block.timestamp > upgradeTime[_realmId], "You are currently upgrading");
    require(towers[_realmId][_kind][_level] > 0, "Not enough");

    towers[_realmId][_kind][_level]--;
    towers[_realmId][_kind][_level + 1]++;

    upgradeTime[_realmId] = block.timestamp + UPGRADE_HOURS;

    emit UpgradeTower(_realmId, _kind, _level, _level + 1);
  }

  function sendWave(uint256 _realmId) external {
    require(REALM.ownerOf(_realmId) == msg.sender || REALM.getApproved(_realmId) == msg.sender);
    //require(block.timestamp > waveTime[_realmId], "You are currently in battle");

    uint256 _level = defenders[_realmId].level + 1;

    uint256 _difficulty = 100 * _level;
    uint256 _wave = _random(_realmId, _difficulty) + _difficulty;
    uint256 threshold = _level;
    uint256 diff;

    if (_level < 10) {
      threshold = _level;
    } else {
      threshold = _level - ((_level / 10) * (_level % 11));
    }

    diff = _wave % _level;

    for (uint256 i; i < 3; i++) {
      if (diff > towers[_realmId][0][i]) {
        diff -= towers[_realmId][0][i];
      }
      if (diff > towers[_realmId][1][i]) {
        diff -= towers[_realmId][1][i];
      }
      if (diff > towers[_realmId][2][i]) {
        diff -= towers[_realmId][2][i] + (towers[_realmId][2][i] / 5);
      }
      if (diff > towers[_realmId][3][i]) {
        diff -= towers[_realmId][3][i] + (towers[_realmId][3][i] / 4);
      }
      if (diff > towers[_realmId][4][i]) {
        diff -= towers[_realmId][4][i] + (towers[_realmId][4][i] / 3);
      }
    }

    require(diff < threshold, "Wave is too powerful");

    defenders[_realmId].level++;

    waveTime[_realmId] = block.timestamp + WAVE_HOURS;

    emit waveCompleted(_realmId, defenders[_realmId].level);
  }

  function buildTowerWithWealth(
    uint256 _realmId,
    uint256 _wealth,
    uint256 _kind
  ) external {
    require(REALM.ownerOf(_realmId) == msg.sender || REALM.getApproved(_realmId) == msg.sender);
    require(REALM.wealth(_realmId) > 100, "Not enough wealth");
    //require(block.timestamp > buildTime[_realmId], "You are currently building");

    REALM.spendWealth(_realmId, _wealth);

    towers[_realmId][_kind][0]++;

    buildTime[_realmId] = block.timestamp + (BUILD_HOURS * (_kind + 1));

    emit BuildTower(_realmId, _kind, 0);
  }

  function _random(uint256 _salt, uint256 _limit) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, _salt))) % _limit;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}