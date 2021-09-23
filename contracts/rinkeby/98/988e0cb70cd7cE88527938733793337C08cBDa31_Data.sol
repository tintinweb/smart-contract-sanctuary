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

  function isDeployer(address _addr) external view returns (bool);
}

contract Data {
  IRealm public constant REALM =
    IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  IManager public constant MANAGER =
    IManager(0x0c0B966159f22762D217fa6231cD58897abf92b0);

  mapping(uint256 => string) public dataNames;
  mapping(uint256 => mapping(uint256 => uint256)) public data;
  mapping(uint256 => uint256) public buildQueue;
  mapping(uint256 => mapping(uint256 => uint256)) public buildTime;

  event Added(
    uint256 realmId,
    uint256 _type,
    string typeName,
    uint256 amount,
    uint256 totalAmount
  );
  event Removed(
    uint256 realmId,
    uint256 _type,
    string typeName,
    uint256 amount,
    uint256 totalAmount
  );
  event DataNameAdded(uint256 _type, string name);

  constructor() {
    dataNames[0] = "ETH";
    dataNames[1] = "Food";
    dataNames[2] = "Workforce";
    dataNames[3] = "Culture";
    dataNames[4] = "Religion";
    dataNames[5] = "Research";
    dataNames[6] = "Reputation";
  }

  function buildQueueLimit(uint256 _realmId) public view returns (uint256) {
    return 1 + (data[_realmId][2] / 100);
  }

  function addToBuildQueue(uint256 _realmId, uint256 _hours) external {
    require(MANAGER.isManager(msg.sender, 0));
    require(buildQueue[_realmId] < buildQueueLimit(_realmId));

    buildQueue[_realmId]++;
    buildTime[_realmId][buildQueue[_realmId]] = block.timestamp + _hours;
  }

  function bonus(uint256 _realmId, uint256[] memory _resourceBonus)
    external
    view
    returns (uint256)
  {
    uint256 _feature1 = REALM.realmFeatures(_realmId, 0);
    uint256 _feature2 = REALM.realmFeatures(_realmId, 1);
    uint256 _feature3 = REALM.realmFeatures(_realmId, 2);
    uint256 _b;

    for (uint256 i; i < _resourceBonus.length; i++) {
      if (
        _feature1 == _resourceBonus[i] ||
        _feature2 == _resourceBonus[i] ||
        _feature3 == _resourceBonus[i]
      ) {
        _b += 1;
      }
    }

    return _b;
  }

  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external {
    require(MANAGER.isManager(msg.sender, 0));

    data[_realmId][_type] += _amount;

    emit Added(
      _realmId,
      _type,
      dataNames[_type],
      _amount,
      data[_realmId][_type]
    );
  }

  function remove(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external {
    address _owner = REALM.ownerOf(_realmId);

    require(
      MANAGER.isManager(msg.sender, 0) ||
        _owner == msg.sender ||
        REALM.isApprovedForAll(_owner, msg.sender)
    );

    data[_realmId][_type] -= _amount;

    emit Removed(
      _realmId,
      _type,
      dataNames[_type],
      _amount,
      data[_realmId][_type]
    );
  }

  function addDataName(uint256 _type, string memory _name) external {
    require(MANAGER.isDeployer(msg.sender));

    dataNames[_type] = _name;

    emit DataNameAdded(_type, _name);
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