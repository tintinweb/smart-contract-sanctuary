// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);
}

interface IManager {
  function isManager(address _addr, uint256 _resourceId)
    external
    view
    returns (bool);

  function isAdmin(address _addr) external view returns (bool);
}

contract Resource {
  IRealm public immutable REALM;
  IManager public immutable MANAGER;

  mapping(uint256 => mapping(uint256 => uint256)) public data;

  event Added(
    uint256 realmId,
    uint256 resourceId,
    uint256 amount,
    uint256 totalAmount
  );
  event Removed(
    uint256 realmId,
    uint256 resourceId,
    uint256 amount,
    uint256 totalAmount
  );

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not a manager");
    _;
  }

  constructor(address realm, address manager) {
    REALM = IRealm(realm);
    MANAGER = IManager(manager);
  }

  function add(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external onlyManager {
    data[_realmId][_resourceId] += _amount;

    emit Added(_realmId, _resourceId, _amount, data[_realmId][_resourceId]);
  }

  function remove(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external {
    require(
      _amount <= data[_realmId][_resourceId],
      "Resource: Not enough resources"
    );

    address _owner = REALM.ownerOf(_realmId);

    require(
      MANAGER.isManager(msg.sender, 0) ||
        _owner == msg.sender ||
        REALM.isApprovedForAll(_owner, msg.sender)
    );

    data[_realmId][_resourceId] -= _amount;

    emit Removed(_realmId, _resourceId, _amount, data[_realmId][_resourceId]);
  }
}