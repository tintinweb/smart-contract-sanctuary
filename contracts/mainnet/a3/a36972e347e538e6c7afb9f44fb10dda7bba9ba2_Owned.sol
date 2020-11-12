// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;


/**
 * @notice Mixin that provide separate owner and admin roles for RBAC
 */
abstract contract Owned {
  address immutable _owner;
  address _admin;

  modifier onlyOwner {
    require(msg.sender == _owner, 'Caller must be owner');
    _;
  }
  modifier onlyAdmin {
    require(msg.sender == _admin, 'Caller must be admin');
    _;
  }

  /**
   * @notice Sets both the owner and admin roles to the contract creator
   */
  constructor() public {
    _owner = msg.sender;
    _admin = msg.sender;
  }

  /**
   * @notice Sets a new whitelisted admin wallet
   *
   * @param newAdmin The new whitelisted admin wallet. Must be different from the current one
   */
  function setAdmin(address newAdmin) external onlyOwner {
    require(newAdmin != address(0x0), 'Invalid wallet address');
    require(newAdmin != _admin, 'Must be different from current admin');

    _admin = newAdmin;
  }

  /**
   * @notice Clears the currently whitelisted admin wallet, effectively disabling any functions requiring
   * the admin role
   */
  function removeAdmin() external onlyOwner {
    _admin = address(0x0);
  }
}
