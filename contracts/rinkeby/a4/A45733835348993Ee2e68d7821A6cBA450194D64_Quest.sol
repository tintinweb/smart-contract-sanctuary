// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 realmId) external view returns (address owner);

  function getRealm(uint256 _realmId)
    external
    view
    returns (
      string memory,
      uint256,
      uint256,
      bool
    );
}

interface ICitizen {
  function ownerOf(uint256 realmId) external view returns (address owner);
}

interface ICitizenLevel {
  function addXp(uint256 realmId, uint256 xp) external view;

  function level(uint256 realmId) external view returns (uint256);
}

interface ICitizenLootBag {
  function add(uint256 _citizenId, uint256 itemCount) external;
}

contract Quest {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  ICitizen constant CITIZEN =
    ICitizen(0x2dA91F39BA94467d3dF3668a323bc687Fc731C3a);
  ICitizenLevel constant CITIZEN_LEVEL =
    ICitizenLevel(0xC6cE1EA79B1245B82cFF657444176c7f7a76d8BF);
  ICitizenLootBag constant CITIZEN_LOOT_BAG =
    ICitizenLootBag(0xBE7B92dC92eef58c7E2490ea5c52aB4f16b886a0);

  // TODO: changed for testing
  uint256 constant XP = 5000000000;
  uint256 private constant ACTION_HOURS = 12 hours;

  mapping(uint256 => uint256) public questTime;

  event LootCollected(string[8] loot);
  event QuestCompleted(uint256 citizenId, uint256 TotalXp);

  function quest(
    uint256 _realmId,
    uint256 _citizenId,
    uint256 _difficulty
  ) external {
    require(CITIZEN.ownerOf(_citizenId) == msg.sender);

    // uint256 _level = CITIZEN_LEVEL.level(_citizenId);

    // if (_difficulty > 2) {
    //   (string memory name, , , ) = REALM.getRealm(_realmId);
    //   // Do some questing
    //   CITIZEN_LOOT_BAG.add(_citizenId, _difficulty);
    // }

    // questTime[_citizenId] = block.timestamp + ACTION_HOURS;

    CITIZEN_LEVEL.addXp(_citizenId, XP);

    emit QuestCompleted(_citizenId, CITIZEN_LEVEL.level(_citizenId));
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