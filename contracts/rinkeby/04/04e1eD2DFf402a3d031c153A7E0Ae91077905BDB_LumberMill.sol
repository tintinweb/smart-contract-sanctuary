// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);

  function realmFeatures(uint256 realmId, uint256 index)
    external
    view
    returns (uint256);
}

interface IData {
  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;

  function addToBuildQueue(uint256 realmId, uint256 _hours) external;
}

contract LumberMill {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  IData constant DATA = IData(0x167EBa605030001A9a9F7890b80b3C260ce253e3);

  uint256 private constant BUILD_TIME = 12 hours;

  uint256[3] private resourceBonus = [11, 14, 32];

  mapping(uint256 => uint256) public totalLumberMills;

  event Built(uint256 realmId, uint256 totalLumberMills);

  function build(uint256 _realmId) external {
    address _owner = REALM.ownerOf(_realmId);

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));

    //DATA.addToBuildQueue(_realmId, BUILD_TIME);

    // workforce
    DATA.add(_realmId, 2, 1 + _bonus(_realmId));

    totalLumberMills[_realmId]++;

    emit Built(_realmId, totalLumberMills[_realmId]);
  }

  function _bonus(uint256 _realmId) internal view returns (uint256) {
    uint256 _feature1 = REALM.realmFeatures(_realmId, 0);
    uint256 _feature2 = REALM.realmFeatures(_realmId, 1);
    uint256 _feature3 = REALM.realmFeatures(_realmId, 2);
    uint256 _b;

    for (uint256 i; i < resourceBonus.length; i++) {
      if (
        _feature1 == resourceBonus[i] ||
        _feature2 == resourceBonus[i] ||
        _feature3 == resourceBonus[i]
      ) {
        _b += 1;
      }
    }

    return _b;
  }
}

