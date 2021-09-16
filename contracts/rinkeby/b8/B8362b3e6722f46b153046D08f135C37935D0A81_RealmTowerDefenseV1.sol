// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 realmId) external view returns (address owner);

  function getApproved(uint256 realmId)
    external
    view
    returns (address approved);

  function getRealm(uint256 realmdId)
    external
    view
    returns (
      string memory,
      uint256,
      uint256,
      bool
    );
}

contract RealmTowerDefenseV1 {
  uint256 private constant WAVE_HOURS = 3 hours;
  uint256 private constant UPGRADE_HOURS = 6 hours;
  uint256 private constant LEVELS = 5;

  struct Defender {
    uint256 level;
    uint256 upgrades;
    uint256 army;
    uint256 towers;
  }

  mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
    public towers;

  mapping(uint256 => uint256) public waveTime;
  mapping(uint256 => uint256) public upgradeTime;
  mapping(uint256 => Defender) public defenders;

  event BuildTower(
    uint256 realmId,
    uint256 kind,
    uint256 level,
    uint256 totalTowers
  );
  event UpgradeTower(
    uint256 realmId,
    uint256 kind,
    uint256 levelRemoved,
    uint256 levelAdded,
    uint256 totalUpgrades
  );
  event waveCompleted(
    uint256 realmId,
    uint256 level,
    uint256 totalUpgrades,
    uint256 totalArmy,
    uint256 totalBuildableTowers
  );

  IRealm constant REALM = IRealm(0x4de95c1E202102E22E801590C51D7B979f167FBB);

  function buildTower(uint256 _realmId, uint256 _kind) external {
    require(
      REALM.ownerOf(_realmId) == msg.sender ||
        REALM.getApproved(_realmId) == msg.sender
    );
    require(_kind < 5, "Tower type doesn't exist");

    uint256 _cost = _kind + 1;

    require(defenders[_realmId].towers >= _cost, "You have no towers");

    if (_kind == 3) {
      require(defenders[_realmId].level > 150, "Must be level 100");
    }

    if (_kind == 4) {
      require(defenders[_realmId].level > 200, "Must be level 200");
    }

    towers[_realmId][_kind][0]++;
    defenders[_realmId].towers -= _cost;

    emit BuildTower(_realmId, _kind, 0, defenders[_realmId].towers);
  }

  function upgradeTower(
    uint256 _realmId,
    uint256 _kind,
    uint256 _level
  ) external {
    require(
      REALM.ownerOf(_realmId) == msg.sender ||
        REALM.getApproved(_realmId) == msg.sender
    );
    require(_kind < 5, "Tower type doesn't exist");
    require(_level < LEVELS - 1, "Level doesn't exist");
    require(defenders[_realmId].upgrades > 0, "You have no upgrades");
    require(towers[_realmId][_kind][_level] > 0, "Not enough");

    towers[_realmId][_kind][_level]--;
    towers[_realmId][_kind][_level + 1]++;
    defenders[_realmId].upgrades--;

    emit UpgradeTower(
      _realmId,
      _kind,
      _level,
      _level + 1,
      defenders[_realmId].upgrades
    );
  }

  function startWave(uint256 _realmId, uint256 _useArmy) external {
    require(
      REALM.ownerOf(_realmId) == msg.sender ||
        REALM.getApproved(_realmId) == msg.sender
    );
    // require(
    //   block.timestamp > waveTime[_realmId],
    //   "You are currently in battle"
    // );

    (string memory name, , , ) = REALM.getRealm(_realmId);

    uint256 _level = defenders[_realmId].level + 1;
    uint256 _difficulty = 100 * _level;
    uint256 _wave = _randomFromString(name, _difficulty) + _difficulty;
    uint256 threshold = _level;
    uint256 _wavePower;

    if (_level <= 10) {
      threshold = _level;
    } else {
      threshold = _level - ((_level / 10) * (_level % 11));
    }

    _wavePower = _wave % _level;

    for (uint256 i; i < LEVELS; i++) {
      uint256 _towerPower;

      if (towers[_realmId][0][i] > 0) {
        _towerPower = towers[_realmId][0][i];

        if (_towerPower > _wavePower) {
          _wavePower = 0;
        } else {
          _wavePower -= _towerPower;
        }
      }
      if (towers[_realmId][1][i] > 0) {
        _towerPower =
          towers[_realmId][1][i] +
          (towers[_realmId][1][i] / (10 - i));

        if (_towerPower > _wavePower) {
          _wavePower = 0;
        } else {
          _wavePower -= _towerPower;
        }
      }
      if (towers[_realmId][2][i] > 0) {
        _towerPower =
          towers[_realmId][2][i] +
          (towers[_realmId][2][i] / (8 - i));

        if (_towerPower > _wavePower) {
          _wavePower = 0;
        } else {
          _wavePower -= _towerPower;
        }
      }
      if (towers[_realmId][3][i] > 0) {
        _towerPower =
          towers[_realmId][3][i] +
          (towers[_realmId][3][i] / (6 - i));

        if (_towerPower > _wavePower) {
          _wavePower = 0;
        } else {
          _wavePower -= _towerPower;
        }
      }
      if (towers[_realmId][4][i] > 0) {
        _towerPower =
          towers[_realmId][4][i] +
          (towers[_realmId][4][i] / (5 - i));

        if (_towerPower > _wavePower) {
          _wavePower = 0;
        } else {
          _wavePower -= _towerPower;
        }
      }

      if (_wavePower == 0) break;
    }

    if (
      _useArmy == 1 &&
      defenders[_realmId].army > 0 &&
      _wavePower >= defenders[_realmId].army
    ) {
      _wavePower -= defenders[_realmId].army;
      defenders[_realmId].army = 0;
    }

    require(_wavePower <= threshold, "Wave is too powerful");

    if (block.timestamp > upgradeTime[_realmId]) {
      defenders[_realmId].upgrades++;
    }

    defenders[_realmId].army += (defenders[_realmId].level % 2);
    defenders[_realmId].towers += (defenders[_realmId].level % 2);
    defenders[_realmId].level++;

    waveTime[_realmId] = block.timestamp + WAVE_HOURS;
    upgradeTime[_realmId] = block.timestamp + UPGRADE_HOURS;

    emit waveCompleted(
      _realmId,
      defenders[_realmId].level,
      defenders[_realmId].upgrades,
      defenders[_realmId].army,
      defenders[_realmId].towers
    );
  }

  function _randomFromString(string memory _salt, uint256 _limit)
    internal
    view
    returns (uint256)
  {
    return
      uint256(
        keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
      ) % _limit;
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