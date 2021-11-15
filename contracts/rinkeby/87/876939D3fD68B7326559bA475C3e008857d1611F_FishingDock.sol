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
    uint256 _type,
    uint256 _amount
  ) external;

  function addToBuildQueue(uint256 realmId, uint256 _hours) external;

  function bonus(uint256 _realmId, uint256[] memory _resourceBonus)
    external
    view
    returns (uint256);
}

contract FishingDock {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  IManager constant MANAGER =
    IManager(0x0c0B966159f22762D217fa6231cD58897abf92b0);
  //IData constant DATA = IData(0x9229f54E97c7E08C54DE43bC4c68E5C76E92A117);
  IData constant DATA = IData(0x988e0cb70cd7cE88527938733793337C08cBDa31);

  uint256 private constant ACTION_HOURS = 24 hours;

  uint256[] private resourceBonus = [2, 11, 12, 14, 17, 20, 23, 33];

  uint256[] public resourceProbability = [1, 70, 85, 90, 94, 98];
  string[6] public resourceNames = [
    "Tuna",
    "Salmon",
    "Coral",
    "Oysters"
    "Manta Ray",
    "Giant Squid"
  ];

  uint256[] public dataProbability = [1, 80, 90, 95];

  struct Dock {
    uint8 food;
    uint8 resourceId;
  }

  mapping(uint256 => mapping(uint256 => Dock)) public docks;
  mapping(uint256 => mapping(uint256 => uint256)) public resources;

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
    uint256 totalResources
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

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));

    //DATA.addToBuildQueue(_realmId, 12 hours);

    uint256 _id = totalDocks[_realmId];
    uint256 _resourceId = _rarity(_realmId, resourceProbability);

    Dock memory dock;
    dock.food = uint8(_rarity(_realmId, dataProbability));
    dock.resourceId = uint8(_resourceId);

    docks[_realmId][_id] = dock;
    totalDocks[_realmId]++;

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

    uint256 _resource = 1 + DATA.bonus(_realmId, resourceBonus);

    for (uint256 i; i < totalDocks[_realmId]; i++) {
      Dock memory dock = docks[_realmId][i];

      resources[_realmId][dock.resourceId] += _resource;

      if (dock.resourceId == 5 || dock.resourceId == 7) {
        // culture
        DATA.add(_realmId, 3, 1);
      } else if (dock.resourceId == 6) {
        // research
        DATA.add(_realmId, 5, 1);
      }

      // food
      DATA.add(_realmId, 1, dock.food);

      emit Collected(
        _realmId,
        i,
        _resource,
        dock.resourceId,
        resourceNames[dock.resourceId],
        resources[_realmId][dock.resourceId]
      );
    }

    collectTime[_realmId] = block.timestamp + ACTION_HOURS;
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
    return (_realmId, _dockId, docks[_realmId][_dockId].resourceId);
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

    require(
      MANAGER.isManager(msg.sender, 1) ||
        _owner == msg.sender ||
        REALM.isApprovedForAll(_owner, msg.sender)
    );

    resources[_realmId][_resourceId] -= _amount;

    emit ResourceRemoved(
      _realmId,
      _amount,
      _resourceId,
      resourceNames[_resourceId],
      resources[_realmId][_resourceId]
    );
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

