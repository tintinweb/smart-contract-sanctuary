// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

interface ILendingPoolConfigurator {
  function setPoolPause(bool pause) external;
}

interface IPermissionManager {
  /**
   * @dev Allows owner to add new permission admins
   * @param admins The addresses to promote to permission admin
   **/
  function addPermissionAdmins(address[] calldata admins) external;
}

interface IProposalExecutor {
  function execute() external;
}

contract EnableArcProposal is IProposalExecutor {
  address public constant ARC_POOL_CONFIGURATOR_ADDRESS =
    0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA;
  address public constant ARC_PERMISSION_MANAGER_ADDRESS =
    0xF4a1F5fEA79C3609514A417425971FadC10eCfBE;

  // Fireblock's Address
  address public constant FIREBLOCKS_ADDRESS = 0x33B09130b035d6D7e57d76fEa0873d9545FA7557;

  function execute() external override {
    address[] memory admins = new address[](1);
    admins[0] = FIREBLOCKS_ADDRESS;

    // Add Fireblocks as PermissionAdmin
    IPermissionManager(ARC_PERMISSION_MANAGER_ADDRESS).addPermissionAdmins(admins);

    // Enable Arc market
    ILendingPoolConfigurator(ARC_POOL_CONFIGURATOR_ADDRESS).setPoolPause(false);
  }
}