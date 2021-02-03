// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract AdminManager {
  mapping(string => address) roles;

  modifier onlyOwner(string memory _role) {
    // abi.encodePacked() appends strings
    require(roles[_role] == msg.sender, string(abi.encodePacked("AdminManager: Not", _role)));
    _;
  }

  function onlyOwnerF(string memory _role) internal onlyOwner(_role) { }

  function setupRole(string memory _role, address _owner) public {
    require(roles[_role] == address(0), "AdminManager: RoleAlreadySet");
    roles[_role] = _owner;
  }

  function getRoleOwner(string memory _role) public view returns(address) {
    return roles[_role];
  }

  function safeGetRoleOwner(string memory _role) public view returns(address) {
    address _owner = roles[_role];
    require(_owner != address(0), "AdminManager: RoleNotSet");
    return _owner;
  }

  function transferOwnership(string memory _role, address _newOwner) public onlyOwner(_role) {
    roles[_role] = _newOwner;
  }
}

abstract contract MembersManager is AdminManager {
  struct Members {
    string    admin;
    mapping(address => bool) members;
  }
  mapping(string => Members) public groups;

  function createGroup(string memory _groupName, string memory _adminRole) external onlyOwner(_adminRole) {
    require(AdminManager.getRoleOwner(groups[_groupName].admin) == address(0), "GroupAlreadyCreated");
    groups[_groupName].admin = _adminRole;
  }

  function addMember(string memory _groupName, address _newMember) external onlyOwner(groups[_groupName].admin) {
    groups[_groupName].members[_newMember] = true;
  }

  function removeMember(string memory _groupName, address _memberToRemove) external onlyOwner(groups[_groupName].admin) {
    groups[_groupName].members[_memberToRemove] = false;
  }

  function isMember(string memory _groupName, address _member) public view returns(bool) {
    return groups[_groupName].members[_member];
  }
}