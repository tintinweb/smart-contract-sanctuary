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

    staked[_realmId] = Staked({
      gold: _gold,
      food: _food,
      workforce: _workforce,
      culture: _culture,
      technology: _technology
    });
  }

  function unstake(uint256 _realmId) external {}
}