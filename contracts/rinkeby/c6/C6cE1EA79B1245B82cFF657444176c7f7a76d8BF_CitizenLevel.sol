// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealmManager {
  function isManager(address _addr, uint256 _type) external view returns (bool);
}

interface ICitizen {
  function ownerOf(uint256 citizenId) external view returns (address owner);

  function getApproved(uint256 citizenId)
    external
    view
    returns (address approved);
}

contract CitizenLevel {
  IRealmManager constant REALM_MANAGER =
    IRealmManager(0x4b7d2C7aea58Ba080d4D242cd68b3f6cB4E05B36);
  ICitizen constant CITIZEN =
    ICitizen(0x2dA91F39BA94467d3dF3668a323bc687Fc731C3a);

  uint256 constant LEVEL_UP = 500;

  mapping(uint256 => uint256) public xp;
  mapping(uint256 => uint256) public level;

  event Leveled(uint256 realmId, uint256 xp, uint256 level);

  function levelUp(uint256 _citizenId) external {
    require(
      CITIZEN.ownerOf(_citizenId) == msg.sender ||
        CITIZEN.getApproved(_citizenId) == msg.sender
    );

    uint256 _level = level[_citizenId];
    if (_level == 0) {
      _level = 1;
    }

    require(_level * LEVEL_UP * _level < xp[_citizenId], "Not enough XP");

    level[_citizenId] = _level + 1;

    emit Leveled(_citizenId, xp[_citizenId], level[_citizenId]);
  }

  function addXp(uint256 _citizenId, uint256 _xp) external {
    //require(REALM_MANAGER.isManager(msg.sender, 0));

    xp[_citizenId] += _xp;
  }
}

