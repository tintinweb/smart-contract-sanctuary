// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
}

interface IData {
  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;

  function addToBuildQueue(uint256 realmId, uint256 _hours) external;

  function addGoldSupply(uint256 _realmId, uint256 _gold) external;

  function addReligionSupply(uint256 _realmId, uint256 _religion) external;
}

contract City {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  IData constant DATA = IData(0x57Fa5bd6e087a8112551FaEb01c7F5AdE99A4577);

  uint256 private constant BUILD_TIME = 72 hours;

  uint256[] public dataProbability = [1, 25, 50, 90, 95];

  mapping(uint256 => uint256) public totalCities;

  event Established(
    uint256 realmId,
    uint256 cityId,
    uint256 gold,
    uint256 workforce,
    uint256 culture,
    uint256 religion,
    uint256 technology,
    uint256 totalCities
  );

  function create(uint256 _realmId) external {
    address _owner = REALM.ownerOf(_realmId);

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));

    //DATA.addToBuildQueue(_realmId, BUILD_TIME);

    uint256 _cityId = totalCities[_realmId];
    uint256[5] memory _data;

    _data[0] = _rarity(1) + 2; // Gold
    _data[1] = _rarity(2) + 2; // Workforce
    _data[2] = _rarity(3) + 2; // Culture
    _data[3] = _rarity(4) + 2; // Religion
    _data[4] = _rarity(5) + 2; // Technology

    DATA.addGoldSupply(_realmId, _data[0]);
    DATA.addReligionSupply(_realmId, _data[3]);

    DATA.add(_realmId, 2, _data[1]);
    DATA.add(_realmId, 3, _data[2]);
    DATA.add(_realmId, 5, _data[4]);

    totalCities[_realmId]++;

    emit Established(
      _realmId,
      _cityId,
      _data[0],
      _data[1],
      _data[2],
      _data[3],
      _data[4],
      totalCities[_realmId]
    );
  }

  function _rarity(uint256 _salt) internal view returns (uint256) {
    uint256 _rand = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
    ) % 100;

    uint256 j = 0;
    for (; j < dataProbability.length; j++) {
      if (_rand <= dataProbability[j]) {
        break;
      }
    }

    return j;
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