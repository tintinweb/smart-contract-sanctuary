// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract AdminControl {

  address public superAdmin;
  address public pendingSuperAdmin;
  address public admin;
  address public serviceAdmin;

  uint8 public constant SUPER_ADMIN = 0;
  uint8 public constant ADMIN = 1;
  uint8 public constant SERVICE_ADMIN = 2;

  modifier onlyRole(uint8 _role) {
    require(hasRole(_role, msg.sender), "no access");
    _;
  }

  function hasRole(uint8 _role, address _account) public view returns (bool) {
    if (_role == SUPER_ADMIN) {
      return _account == superAdmin;
    }
    if (_role == ADMIN) {
      return _account == superAdmin || _account == admin;
    }
    if (_role == SERVICE_ADMIN) {
      return _account == superAdmin || _account == admin || _account == serviceAdmin;
    }

    return false;
  }

  function updateAdmin(address _newAdmin) public onlyRole(ADMIN) {
    admin = _newAdmin;
  }

  function updateServiceAdmin(address _newServiceAdmin) public onlyRole(SUPER_ADMIN) {
    serviceAdmin = _newServiceAdmin;
  }

  function setPendingSuperAdmin(address _newPendingSuperAdmin) public {
    require(hasRole(SUPER_ADMIN, msg.sender) || superAdmin == address(0), "no access");
    pendingSuperAdmin = _newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pending");
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

}

