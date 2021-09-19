// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealmManager {
  function isManager(address _addr, uint256 _type) external view returns (bool);
}

interface ILoot {
  function randomBag(uint256 salt, uint256 itemCount)
    external
    view
    returns (uint256[7][8] memory);

  function getItemName(uint256[7] memory ids)
    external
    view
    returns (string memory);
}

contract CitizenLootBag {
  IRealmManager constant REALM_MANAGER =
    IRealmManager(0x4b7d2C7aea58Ba080d4D242cd68b3f6cB4E05B36);
  ILoot constant LOOT = ILoot(0x085a1A6D0C542Fc842768acb75934ac2e002EA50);

  mapping(uint256 => mapping(uint256 => uint256[7][8])) public bags;
  mapping(uint256 => uint256) public bagCount;

  event AddedBag(uint256 citizenId, uint256 xp, uint256 level);
  event LootCollected(uint256 citizenId, string[8] loot);

  function add(uint256 _citizenId, uint256 _itemCount) external {
    require(REALM_MANAGER.isManager(msg.sender, 1));

    uint256[7][8] memory _bag = LOOT.randomBag(_citizenId, _itemCount);

    bags[_citizenId][bagCount[_citizenId]] = _bag;

    bagCount[_citizenId]++;

    // string[8] memory _itemNames;

    // for (uint256 i; i < 8; i++) {
    //   if (_bag[i][6] == 0) continue;

    //   _itemNames[i] = LOOT.getItemName(_bag[i]);
    // }

    // emit LootCollected(_citizenId, _itemNames);
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