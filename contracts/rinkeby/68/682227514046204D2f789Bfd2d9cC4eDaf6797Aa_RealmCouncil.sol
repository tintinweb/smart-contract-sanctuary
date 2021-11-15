// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function ownerOf(uint256 realmId) external view returns (address owner);
}

contract RealmCouncil {
  IRealm constant REALM = IRealm(0x190357CbC57847137EdC10cC5D7f86cc19F133f5);
  uint256 constant COUNCIL_LIMIT = 10;

  mapping(uint256 => mapping(address => bool)) public council;
  mapping(uint256 => uint256) public councilCount;

  event ModifiedMembers(uint256 realmId, bool toggle, address[] members);

  function modifyMember(
    uint256 _realmId,
    address[] memory _members,
    bool _toggle
  ) external {
    require(councilCount[_realmId] < COUNCIL_LIMIT, "Reached council limit");
    require(
      REALM.ownerOf(_realmId) == msg.sender || council[_realmId][msg.sender]
    );

    for (uint256 i; i < _members.length; i++) {
      council[_realmId][_members[i]] = _toggle;
    }
    councilCount[_realmId] += _members.length;

    emit ModifiedMembers(_realmId, _toggle, _members);
  }

  function isApproved(uint256 _realmId, address _member)
    external
    view
    returns (bool)
  {
    return council[_realmId][_member];
  }
}

