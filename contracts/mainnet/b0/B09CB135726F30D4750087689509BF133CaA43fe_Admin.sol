/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./AdminInterface.sol";

/**
 * @title Admin
 * @author Paul Razvan Berg
 * @notice Contract module which provides a basic access control mechanism, where there is
 * an account (an admin) that can be granted exclusive access to specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This can later
 * be changed with {transferAdmin}.
 *
 * This module is used through inheritance. It will make available the modifier `onlyAdmin`,
 * which can be applied to your functions to restrict their use to the admin.
 *
 * @dev Forked from OpenZeppelin
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/access/Ownable.sol
 */
abstract contract Admin is AdminInterface {
    /**
     * @notice Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin == msg.sender, "ERR_NOT_ADMIN");
        _;
    }

    /**
     * @notice Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        address msgSender = msg.sender;
        admin = msgSender;
        emit TransferAdmin(address(0x00), msgSender);
    }

    /**
     * @notice Leaves the contract without admin, so it will not be possible to call
     * `onlyAdmin` functions anymore.
     *
     * Requirements:
     *
     * - The caller must be the administrator.
     *
     * WARNING: Doing this will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function _renounceAdmin() external virtual override onlyAdmin {
        emit TransferAdmin(admin, address(0x00));
        admin = address(0x00);
    }

    /**
     * @notice Transfers the admin of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     * @param newAdmin The acount of the new admin.
     */
    function _transferAdmin(address newAdmin) external virtual override onlyAdmin {
        require(newAdmin != address(0x00), "ERR_SET_ADMIN_ZERO_ADDRESS");
        emit TransferAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}
