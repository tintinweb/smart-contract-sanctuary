// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
}

interface IManager {
  function isManager(address _addr, uint256 _type) external view returns (bool);

  function isAdmin(address _addr) external view returns (bool);
}

contract Data {
  IRealm public constant REALM =
    IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  IManager public constant MANAGER =
    IManager(0x20F20fbaCD2e1daE86da806FD1699fA35d3eFf71);

  uint256 private constant ACTION_TIME = 24 hours;
  uint256 private constant ONE_HOUR = 1 hours;

  mapping(uint256 => string) public dataNames;
  mapping(uint256 => mapping(uint256 => uint256)) public data;
  mapping(uint256 => mapping(uint256 => uint256)) public bonus;

  mapping(uint256 => uint256) public gold;
  mapping(uint256 => uint256) public religion;

  mapping(uint256 => mapping(uint256 => uint256)) public buildTime;
  mapping(uint256 => uint256) public collectTime;

  mapping(uint256 => uint256) public queueLimit;
  mapping(uint256 => uint256) public queueMod;
  mapping(uint256 => uint256) public foodBonus;
  mapping(uint256 => uint256) public foodMod;

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
  event AddedBonus(
    uint256 realmId,
    uint256 _type,
    string typeName,
    uint256 amount,
    uint256 totalBonus
  );
  event RemovedBonus(
    uint256 realmId,
    uint256 _type,
    string typeName,
    uint256 amount,
    uint256 totalBonus
  );
  event DataNameAdded(uint256 _type, string name);
  event AddedToBuildQueue(
    uint256 queueSlot,
    uint256 queueTime,
    uint256 queueLimit
  );
  event AddedReligionSupply(
    uint256 realmId,
    uint256 amount,
    uint256 totalAmount
  );
  event AddedGoldSupply(uint256 realmId, uint256 amount, uint256 totalAmount);

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0));
    _;
  }

  constructor() {
    dataNames[0] = "Gold";
    dataNames[1] = "Food";
    dataNames[2] = "Workforce";
    dataNames[3] = "Culture";
    dataNames[4] = "Religion";
    dataNames[5] = "Technology";
    dataNames[6] = "Reputation";
  }

  function collect(uint256 _realmId) external {
    address _owner = REALM.ownerOf(_realmId);

    require(_owner == msg.sender || REALM.isApprovedForAll(_owner, msg.sender));
    require(
      block.timestamp > collectTime[_realmId],
      "You are currently collecting"
    );

    uint256 _fb = _foodBonus(_realmId);
    data[_realmId][0] += gold[_realmId] + _fb + _bonus(_realmId, 0);
    data[_realmId][4] += religion[_realmId] + _fb + _bonus(_realmId, 4);

    collectTime[_realmId] = block.timestamp + ACTION_TIME;

    emit Added(_realmId, 0, dataNames[0], gold[_realmId], data[_realmId][0]);

    emit Added(
      _realmId,
      4,
      dataNames[4],
      religion[_realmId],
      data[_realmId][4]
    );
  }

  function addToBuildQueue(
    uint256 _realmId,
    uint256 _queueSlot,
    uint256 _hours
  ) external onlyManager {
    uint256 _limit = _buildQueueLimit(_realmId);

    require(_queueSlot < _limit, "_queueSlot not available");
    require(
      block.timestamp > buildTime[_realmId][_queueSlot],
      "You are currently building"
    );

    buildTime[_realmId][_queueSlot] = block.timestamp + _time(_realmId, _hours);

    emit AddedToBuildQueue(_queueSlot, buildTime[_realmId][_queueSlot], _limit);
  }

  function addGoldSupply(uint256 _realmId, uint256 _gold) external onlyManager {
    gold[_realmId] += _gold;

    emit AddedGoldSupply(_realmId, _gold, gold[_realmId]);
  }

  function addReligionSupply(uint256 _realmId, uint256 _religion)
    external
    onlyManager
  {
    religion[_realmId] += _religion;

    emit AddedReligionSupply(_realmId, _religion, religion[_realmId]);
  }

  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
    _amount += _foodBonus(_realmId) + _bonus(_realmId, _type);

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
    require(_amount >= data[_realmId][_type], "Not enough metrics");

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

  function addBonus(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
    bonus[_realmId][_type] += _amount;

    emit AddedBonus(
      _realmId,
      _type,
      dataNames[_type],
      _amount,
      bonus[_realmId][_type]
    );
  }

  function removeBonus(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
    require(_amount >= bonus[_realmId][_type], "Not enough bonus for metric");

    bonus[_realmId][_type] -= _amount;

    emit RemovedBonus(
      _realmId,
      _type,
      dataNames[_type],
      _amount,
      bonus[_realmId][_type]
    );
  }

  function addDataName(uint256 _type, string memory _name) external {
    require(MANAGER.isAdmin(msg.sender));

    dataNames[_type] = _name;

    emit DataNameAdded(_type, _name);
  }

  function _buildQueueLimit(uint256 _realmId) internal returns (uint256) {
    if (queueMod[_realmId] == 0) {
      queueMod[_realmId] = 25;
    }

    if (data[_realmId][2] % queueMod[_realmId] == 0 && data[_realmId][2] != 0) {
      queueLimit[_realmId]++;

      queueMod[_realmId] += queueMod[_realmId] / 2;
    }

    return 1 + queueLimit[_realmId];
  }

  function _foodBonus(uint256 _realmId) internal returns (uint256) {
    if (foodMod[_realmId] == 0) {
      foodMod[_realmId] = 25;
    }

    if (data[_realmId][1] % foodMod[_realmId] == 0 && data[_realmId][1] != 0) {
      foodBonus[_realmId]++;

      foodMod[_realmId] += foodMod[_realmId] / 2;
    }

    return foodBonus[_realmId];
  }

  function _time(uint256 _realmId, uint256 _hours)
    internal
    view
    returns (uint256)
  {
    uint256 _workforce = (data[_realmId][2] / 25) * ONE_HOUR;

    if ((_hours / 2) <= _workforce) {
      _workforce = (_hours / 2);
    }

    return _hours - _workforce;
  }

  function _bonus(uint256 _realmId, uint256 _type)
    internal
    view
    returns (uint256)
  {
    return bonus[_realmId][_type];
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