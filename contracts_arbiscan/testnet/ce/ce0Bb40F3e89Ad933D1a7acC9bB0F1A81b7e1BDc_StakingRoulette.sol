// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
}

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);
}

interface IData {
  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;

  function addToBuildQueue(
    uint256 realmId,
    uint256 queueSlot,
    uint256 _hours
  ) external;

  function remove(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;
}

contract StakingRoulette {
  IRealm public immutable REALM;
  IManager public immutable MANAGER;
  IData public immutable DATA;

  uint256 public epoch;
  uint256 public epochBlocks;

  struct Staked {
    uint256 gold;
    uint256 food;
    uint256 workforce;
    uint256 culture;
    uint256 technology;
  }

  mapping(uint256 => Staked) public staked;

  constructor(
    address realm,
    address manager,
    address data
  ) {
    REALM = IRealm(realm);
    MANAGER = IManager(manager);
    DATA = IData(data);
  }

  function stake(uint256 _realmId, uint256 _gold) external {
    DATA.remove(_realmId, 0, _gold);

    updateStake(_realmId, _gold, 0, 0, 0, 0);
  }

  function stake(
    uint256 _realmId,
    uint256 _gold,
    uint256 _food
  ) external {
    DATA.remove(_realmId, 0, _gold);
    DATA.remove(_realmId, 1, _food);

    updateStake(_realmId, _gold, _food, 0, 0, 0);
  }

  function stake(
    uint256 _realmId,
    uint256 _gold,
    uint256 _food,
    uint256 _workforce
  ) external {
    DATA.remove(_realmId, 0, _gold);
    DATA.remove(_realmId, 1, _food);
    DATA.remove(_realmId, 2, _workforce);

    updateStake(_realmId, _gold, _food, _workforce, 0, 0);
  }

  function stake(
    uint256 _realmId,
    uint256 _gold,
    uint256 _food,
    uint256 _workforce,
    uint256 _culture
  ) external {
    DATA.remove(_realmId, 0, _gold);
    DATA.remove(_realmId, 1, _food);
    DATA.remove(_realmId, 2, _workforce);
    DATA.remove(_realmId, 3, _culture);

    updateStake(_realmId, _gold, _food, _workforce, _culture, 0);
  }

  function stake(
    uint256 _realmId,
    uint256 _gold,
    uint256 _food,
    uint256 _workforce,
    uint256 _culture,
    uint256 _technology
  ) external {
    DATA.remove(_realmId, 0, _gold);
    DATA.remove(_realmId, 1, _food);
    DATA.remove(_realmId, 2, _workforce);
    DATA.remove(_realmId, 3, _culture);
    DATA.remove(_realmId, 5, _technology);

    updateStake(_realmId, _gold, _food, _workforce, _culture, _technology);
  }

  function unstake(uint256 _realmId) external {
    uint8[2] memory probability = [50, 100];

    _rarity(_realmId, probability);

    Staked memory stke = staked[_realmId];

    if (stke.gold != 0) {
      DATA.add(_realmId, 0, stke.gold * 2);
    } else if (stke.food != 0) {
      DATA.add(_realmId, 1, stke.food * 2);
    } else if (stke.workforce != 0) {
      DATA.add(_realmId, 2, stke.workforce * 2);
    } else if (stke.culture != 0) {
      DATA.add(_realmId, 3, stke.culture * 2);
    } else if (stke.technology != 0) {
      DATA.add(_realmId, 5, stke.technology * 2);
    }
  }

  function updateStake(
    uint256 _realmId,
    uint256 _gold,
    uint256 _food,
    uint256 _workforce,
    uint256 _culture,
    uint256 _technology
  ) internal {
    staked[_realmId] = Staked({
      gold: _gold,
      food: _food,
      workforce: _workforce,
      culture: _culture,
      technology: _technology
    });
  }

  function _rarity(uint256 _salt, uint8[2] memory probability)
    internal
    view
    returns (uint256)
  {
    uint256 rand = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
    ) % 100;

    uint256 j = 0;
    for (; j < probability.length; j++) {
      if (rand <= probability[j]) {
        break;
      }
    }
    return j;
  }
}