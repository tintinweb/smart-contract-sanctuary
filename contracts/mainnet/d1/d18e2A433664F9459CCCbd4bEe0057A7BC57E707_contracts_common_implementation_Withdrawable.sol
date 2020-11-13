/**
 * Withdrawable contract.
 */

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./MultiRole.sol";


/**
 * @title Base contract that allows a specific role to withdraw any ETH and/or ERC20 tokens that the contract holds.
 */
abstract contract Withdrawable is MultiRole {
    using SafeERC20 for IERC20;

    uint256 private roleId;

    /**
     * @notice Withdraws ETH from the contract.
     */
    function withdraw(uint256 amount) external onlyRoleHolder(roleId) {
        Address.sendValue(msg.sender, amount);
    }

    /**
     * @notice Withdraws ERC20 tokens from the contract.
     * @param erc20Address ERC20 token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdrawErc20(address erc20Address, uint256 amount) external onlyRoleHolder(roleId) {
        IERC20 erc20 = IERC20(erc20Address);
        erc20.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Internal method that allows derived contracts to create a role for withdrawal.
     * @dev Either this method or `_setWithdrawRole` must be called by the derived class for this contract to function
     * properly.
     * @param newRoleId ID corresponding to role whose members can withdraw.
     * @param managingRoleId ID corresponding to managing role who can modify the withdrawable role's membership.
     * @param withdrawerAddress new manager of withdrawable role.
     */
    function _createWithdrawRole(
        uint256 newRoleId,
        uint256 managingRoleId,
        address withdrawerAddress
    ) internal {
        roleId = newRoleId;
        _createExclusiveRole(newRoleId, managingRoleId, withdrawerAddress);
    }

    /**
     * @notice Internal method that allows derived contracts to choose the role for withdrawal.
     * @dev The role `setRoleId` must exist. Either this method or `_createWithdrawRole` must be
     * called by the derived class for this contract to function properly.
     * @param setRoleId ID corresponding to role whose members can withdraw.
     */
    function _setWithdrawRole(uint256 setRoleId) internal onlyValidRole(setRoleId) {
        roleId = setRoleId;
    }
}
