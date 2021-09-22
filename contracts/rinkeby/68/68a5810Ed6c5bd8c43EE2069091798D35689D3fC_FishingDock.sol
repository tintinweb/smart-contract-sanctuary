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

interface IManager {
  function isManager(address _addr, uint256 _type) external view returns (bool);
}

interface IData {
  function data(uint256 realmId, uint256 _type) external view returns (uint256);

  function add(
    uint256 _realmId,
    uint256 _amount,
    uint256 _type
  ) external;
}

interface IRarity {
  function rarity(uint256 _salt, uint256[] memory probability)
    external
    view
    returns (uint256);
}

contract FishingDock {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  IManager constant MANAGER =
    IManager(0x0c0B966159f22762D217fa6231cD58897abf92b0);
  IData constant DATA = IData(0x9229f54E97c7E08C54DE43bC4c68E5C76E92A117);
  IRarity constant RARITY = IRarity(0x79ff44ae04600531A6eaFb6C6280455213792665);

  uint256 private constant ACTION_HOURS = 12 hours;
  uint256 private constant LIMIT = 15;

  uint256[8] private resourceBonus = [2, 11, 12, 14, 17, 20, 23, 33];

  uint256[] public resourceProbability = [1, 40, 50, 70, 85, 90, 94, 98];
  string[8] public resourceNames = [
    "Seaweed",
    "Tuna",
    "Salmon",
    "Coral",
    "Lobster",
    "Oysters"
    "Manta Ray",
    "Giant Squid"
  ];

  uint256[] public dataProbability = [1, 80, 90, 95];

  struct Dock {
    uint256 realmId;
    uint8 id;
    uint8 food;
    uint8 workforce;
    uint8 resourceId;
  }

  mapping(uint256 => mapping(uint256 => Dock)) public docks;
  mapping(uint256 => mapping(uint256 => uint256)) public resources;

  mapping(uint256 => uint256) public establishTime;
  mapping(uint256 => uint256) public collectTime;
  mapping(uint256 => uint256) public totalDocks;

  event Established(
    uint256 realmId,
    uint256 dockId,
    uint256 resourceId,
    string resourceName,
    uint256 totalDocks
  );
  event Collected(
    uint256 realmId,
    uint256 dockId,
    uint256 collected,
    uint256 resourceId,
    string resourceName,
    uint256 totalDocks
  );
  event ResourceAdded(
    uint256 realmId,
    uint256 amount,
    uint256 resourceId,
    string resourceName,
    uint256 totalResources
  );
  event ResourceRemoved(
    uint256 realmId,
    uint256 amount,
    uint256 resourceId,
    string resourceName,
    uint256 totalResources
  );

  function create(uint256 _realmId) external {
    address _owner = REALM.ownerOf(_realmId);

    require(totalDocks[_realmId] < limit(_realmId));
    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));
    // require(
    //   block.timestamp > establishTime[_realmId],
    //   "You are currently building a dock"
    // );

    uint256 _id = totalDocks[_realmId];
    uint256 _resourceId = _rarity(_realmId, resourceProbability);

    Dock memory dock;
    // TODO: Maybe use _owner as salt
    dock.id = uint8(_id);
    dock.realmId = _realmId;
    dock.food = uint8(_rarity(_realmId, dataProbability));
    dock.workforce = uint8(_rarity(dock.food, dataProbability));
    dock.resourceId = uint8(_resourceId);

    docks[_realmId][_id] = dock;
    totalDocks[_realmId]++;

    establishTime[_realmId] = block.timestamp + _time(_realmId);

    emit Established(
      _realmId,
      _id,
      _resourceId,
      resourceNames[_resourceId],
      totalDocks[_realmId]
    );
  }

  function collect(uint256 _realmId) external {
    address _owner = REALM.ownerOf(_realmId);

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));
    require(
      block.timestamp > collectTime[_realmId],
      "You are currently fishing"
    );

    uint256 _resource = 1 + bonus(_realmId);

    for (uint256 i; i < totalDocks[_realmId]; i++) {
      Dock memory dock = docks[_realmId][i];

      resources[_realmId][dock.resourceId] += _resource;

      if (dock.resourceId == 5 || dock.resourceId == 7) {
        DATA.add(_realmId, 1, 3);
      }

      if (dock.resourceId == 6) {
        DATA.add(_realmId, 1, 5);
      }

      DATA.add(_realmId, dock.workforce, 1);
      DATA.add(_realmId, dock.food, 2);

      collectTime[_realmId] = block.timestamp + ACTION_HOURS;

      emit Collected(
        _realmId,
        dock.id,
        _resource,
        dock.resourceId,
        resourceNames[dock.resourceId],
        resources[_realmId][dock.resourceId]
      );
    }
  }

  function getDock(uint256 _realmId, uint256 _dockId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      docks[_realmId][_dockId].id,
      docks[_realmId][_dockId].realmId,
      docks[_realmId][_dockId].resourceId
    );
  }

  function add(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external {
    require(MANAGER.isManager(msg.sender, 1));

    resources[_realmId][_resourceId] += _amount;

    emit ResourceAdded(
      _realmId,
      _amount,
      _resourceId,
      resourceNames[_resourceId],
      resources[_realmId][_resourceId]
    );
  }

  function remove(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external {
    address _owner = REALM.ownerOf(_realmId);

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));

    resources[_realmId][_resourceId] -= _amount;

    emit ResourceRemoved(
      _realmId,
      _amount,
      _resourceId,
      resourceNames[_resourceId],
      resources[_realmId][_resourceId]
    );
  }

  function limit(uint256 _realmId) internal view returns (uint256) {
    return LIMIT + bonus(_realmId);
  }

  function bonus(uint256 _realmId) internal view returns (uint256) {
    uint256 _feature1 = REALM.realmFeatures(_realmId, 0);
    uint256 _feature2 = REALM.realmFeatures(_realmId, 1);
    uint256 _feature3 = REALM.realmFeatures(_realmId, 2);
    uint256 _bonus;

    for (uint256 i; i < resourceBonus.length; i++) {
      if (
        _feature1 == resourceBonus[i] ||
        _feature2 == resourceBonus[i] ||
        _feature3 == resourceBonus[i]
      ) {
        _bonus += 1;
      }
    }

    return _bonus;
  }

  function _time(uint256 _realmId) internal view returns (uint256) {
    uint256 _workforce = DATA.data(_realmId, 1) / 50;

    if (_workforce > 6) {
      _workforce = 6;
    }

    return ACTION_HOURS - _workforce;
  }

  function _rarity(uint256 _salt, uint256[] memory probability)
    internal
    view
    returns (uint256)
  {
    uint256 _rand = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, _salt))
    ) % 100;

    uint256 j = 0;
    for (; j < probability.length; j++) {
      if (_rand <= probability[j]) {
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