// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
}

interface IData {
  function data(uint256 _realmId, uint256 _type) external;

  function gold(uint256 _realmId) external returns (uint256);

  function religion(uint256 _realmId) external returns (uint256);

  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;
}

contract Collector {
  IRealm public immutable REALM;
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

  mapping(uint256 => uint256) public collected;

  constructor(address realm, address data) {
    REALM = IRealm(realm);
    DATA = IData(data);
  }

  function collect(uint256 _realmId) external {
    address _owner = REALM.ownerOf(_realmId);

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));

    uint256 multiplier = _multiplier(_realmId);

    DATA.add(_realmId, 0, DATA.gold(_realmId) * multiplier);
    DATA.add(_realmId, 4, DATA.religion(_realmId) * multiplier);

    collected[_realmId] = block.timestamp;
  }

  function steal(uint256 _realmId, uint256 _stealerRealmId) external {
    uint256 d = _days(_realmId);

    require(d > 7, "Collector: Can't steal yet");

    uint256 multiplier = _multiplier(_realmId);

    DATA.add(_stealerRealmId, 0, DATA.gold(_realmId) * multiplier);
    DATA.add(_stealerRealmId, 4, DATA.religion(_realmId) * multiplier);

    collected[_realmId] = block.timestamp;
  }

  function _multiplier(uint256 _realmId) internal view returns (uint256) {
    uint256 mul = _days(_realmId);

    return mul;
  }

  function _days(uint256 _realmId) internal view returns (uint256) {
    if (collected[_realmId] == 0) {
      return 1;
    }

    return (block.number - collected[_realmId]) / 60 / 60 / 24;
  }
}