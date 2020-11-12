// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface Proxy {
  function upgradeTo(address newImplementation) external;
}

contract sbUpgrader {
  event Upgraded(address indexed proxyAddress, address indexed implementationAddress);

  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;

  constructor(address adminAddress, address superAdminAddress) public {
    admin = adminAddress;
    superAdmin = superAdminAddress;
  }

  // ADMIN
  // *************************************************************************************
  function setPendingAdmin(address newPendingAdmin) public {
    require(msg.sender == admin, 'not admin');
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), 'not pendingAdmin');
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(msg.sender == superAdmin, 'not superAdmin');
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), 'not pendingSuperAdmin');
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  // UPGRADE
  // *************************************************************************************
  function upgrade(address proxyAddress, address implementationAddress) external {
    require(msg.sender == admin || msg.sender == superAdmin, 'not admin');
    Proxy proxy = Proxy(proxyAddress);
    proxy.upgradeTo(implementationAddress);
    emit Upgraded(proxyAddress, implementationAddress);
  }
}