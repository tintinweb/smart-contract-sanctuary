// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
}

interface IManager {
  function isManager(address _addr, uint256 _type) external view returns (bool);
}

contract Structure {
  IRealm public immutable REALM;
  IManager public immutable MANAGER;

  mapping(uint256 => string) public dataNames;
  mapping(uint256 => mapping(uint256 => uint256)) public data;

  //=======================================
  // EVENTS
  //=======================================
  event DataNameAdded(uint256 _type, string name);

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

  //=======================================
  // MODIFIERS
  //=======================================
  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0));
    _;
  }

  //=======================================
  // Constructor
  //=======================================
  constructor(address _realm, address _manager) {
    REALM = IRealm(_realm);
    MANAGER = IManager(_manager);

    dataNames[0] = "Cities";
    dataNames[1] = "Farms";
    dataNames[2] = "Aquariums";
    dataNames[3] = "Research Labs";
  }

  //=======================================
  // External
  //=======================================
  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
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
    require(
      _amount <= data[_realmId][_type],
      "Structure: Not enough structures"
    );

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
}