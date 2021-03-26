/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @paulrberg/contracts/access/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AdminStorage {
    /// @notice The address of the administrator account or contract.
    address public admin;
}


// File @paulrberg/contracts/access/[email protected]

/// @title AdminInterface
/// @author Paul Razvan Berg
abstract contract AdminInterface is AdminStorage {
    /// NON-CONSTANT FUNCTIONS ///
    function _renounceAdmin() external virtual;

    function _transferAdmin(address newAdmin) external virtual;

    /// EVENTS ///
    event TransferAdmin(address indexed oldAdmin, address indexed newAdmin);
}


// File @paulrberg/contracts/access/[email protected]

/// @title Admin
/// @author Paul Razvan Berg
/// @notice Contract module which provides a basic access control mechanism, where there is an
/// account (an admin) that can be granted exclusive access to specific functions.
///
/// By default, the admin account will be the one that deploys the contract. This can later be
/// changed with {transferAdmin}.
///
/// This module is used through inheritance. It will make available the modifier `onlyAdmin`,
/// which can be applied to your functions to restrict their use to the admin.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol
abstract contract Admin is AdminInterface {
    /// @notice Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(admin == msg.sender, "ERR_NOT_ADMIN");
        _;
    }

    /// @notice Initializes the contract setting the deployer as the initial admin.
    constructor() {
        address msgSender = msg.sender;
        admin = msgSender;
        emit TransferAdmin(address(0x00), msgSender);
    }

    /// @notice Leaves the contract without admin, so it will not be possible to call `onlyAdmin`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an admin, thereby removing any
    /// functionality that is only available to the admin.
    ///
    /// Requirements:
    ///
    /// - The caller must be the administrator.
    function _renounceAdmin() external virtual override onlyAdmin {
        emit TransferAdmin(admin, address(0x00));
        admin = address(0x00);
    }

    /// @notice Transfers the admin of the contract to a new account (`newAdmin`). Can only be
    /// called by the current admin.
    /// @param newAdmin The acount of the new admin.
    function _transferAdmin(address newAdmin) external virtual override onlyAdmin {
        require(newAdmin != address(0x00), "ERR_SET_ADMIN_ZERO_ADDRESS");
        emit TransferAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}


// File @paulrberg/contracts/token/erc20/[email protected]


/// @title Erc20Storage
/// @author Paul Razvan Berg
/// @notice The storage interface of an Erc20 contract.
abstract contract Erc20Storage {
    /// @notice Returns the number of decimals used to get its user representation.
    uint8 public decimals;

    /// @notice Returns the name of the token.
    string public name;

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    string public symbol;

    /// @notice Returns the amount of tokens in existence.
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;
}


// File @paulrberg/contracts/token/erc20/[email protected]

/// @title Erc20Interface
/// @author Paul Razvan Berg
/// @notice Contract interface adhering to the Erc20 standard.
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/IERC20.sol
abstract contract Erc20Interface is Erc20Storage {
    /// CONSTANT FUNCTIONS ///
    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    /// EVENTS ///
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Burn(address indexed holder, uint256 burnAmount);

    event Mint(address indexed beneficiary, uint256 mintAmount);

    event Transfer(address indexed from, address indexed to, uint256 amount);
}


// File contracts/mftToHifiMigrator/MftToHifiMigratorStorage.sol

abstract contract MftToHifMigratorStorage {
    /// @notice The Erc20 contract for HIFI.
    Erc20Interface public hifi;

    /// @notice The exchange rate between HIFI and MFT.
    uint256 public hifiMftRatio;

    /// @notice The Erc20 contract for MFT.
    Erc20Interface public mft;

    /// @notice The unix timestamp after which reclaim may occur.
    uint256 public reclaimAllowedAfter;

    /// @notice Amount of MFT migrated in total.
    uint256 public totalMftMigrated;

    /// @notice Whether the contract allows migration of MFT.
    bool public isEnabled;
}


// File contracts/mftToHifiMigrator/MftToHifiMigratorInterface.sol

abstract contract MftToHifMigratorInterface is MftToHifMigratorStorage {
    /// EVENTS ///

    /// @notice Emitted on migration.
    /// @param holder The caller of the migration.
    /// @param mftAmount The amount of MFT to migrate.
    /// @param hifiAmount The amount of HIFI tu get.
    event MigrateMftToHifi(address indexed holder, uint256 mftAmount, uint256 hifiAmount);

    /// @notice Emitted on reclaiming HIFI.
    /// @param admin The address of the admin.
    /// @param hifiAmount Amount
    event ReclaimHifi(address indexed admin, uint256 hifiAmount);

    /// @notice Emitted on enabling or disabling the migration.
    /// @param admin The address of the admin.
    /// @param isEnabled The new state put in storage.
    event SetIsEnabled(address indexed admin, bool isEnabled);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Executes the migration from MFT to HIFI.
    /// @dev Emits a {MigrateMftToHifi} event.
    ///
    /// Requirements:
    /// - The contract must be enabled.
    /// - The caller must have allowed this contract to spend `mftAmount` tokens.
    /// - The contract must have been previously funded with sufficient HIFI tokens.
    ///
    /// @param mftAmount The amount of MFT to migrate.
    /// @return bool true = success, otherwise it reverts.
    function migrateMftToHifi(uint256 mftAmount) external virtual returns (bool);

    /// @notice Reclaims the HIFI that was deposited in the contract.
    ///
    /// @dev Emits a {ReclaimHifi} event.
    ///
    /// Requirements:
    /// - The caller must be the administrator.
    /// - At least `minimumTimeBeforeReclaim` time must have passed.
    /// - There must be enough HIFI tokens in the contract.
    ///
    /// @param hifiAmount The amount of HIFI to relcima.
    /// @return bool true = success, otherwise it reverts.
    function _reclaimHifi(uint256 hifiAmount) external virtual returns (bool);

    /// @notice Enables or disables the contract. It is not an error to enable or disable twice.
    ///
    /// @dev Emits a {SetIsEnabled} event.
    ///
    /// Requirements:
    /// - The caller must be the administrator.
    ///
    /// @param isEnabled_ The new state to put in storage.
    /// @return bool true = success, otherwise it reverts.
    function _setIsEnabled(bool isEnabled_) external virtual returns (bool);
}


// File contracts/mftToHifiMigrator/MftToHifiMigrator.sol


/// @title MftToHifiMigrator
/// @notice Implements the migration from MFT to HIFI token.
/// @author Hifi
contract MftToHifiMigrator is
    MftToHifMigratorInterface, /// one dependency
    Admin /// two dependencies
{
    /// @param mft_ The Erc20 contract for MFT.
    /// @param hifi_ The Erc20 contract for HIFI.
    /// @param hifiMftRatio_ The exchange rate between HIFI and MFT.
    /// @param reclaimAllowedAfter_ The unix timestamp after which reclaim may occur.
    constructor(
        Erc20Interface mft_,
        Erc20Interface hifi_,
        uint256 hifiMftRatio_,
        uint256 reclaimAllowedAfter_
    ) Admin() {
        mft = mft_;
        hifi = hifi_;
        hifiMftRatio = hifiMftRatio_;
        reclaimAllowedAfter = reclaimAllowedAfter_;
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc MftToHifMigratorInterface
    function migrateMftToHifi(uint256 mftAmount) external override returns (bool) {
        // Checks: migration is enabled.
        require(isEnabled, "ERR_MIGRATOR_NOT_ENABLED");

        // Checks: sufficient liquidity.
        uint256 hifiBalance = hifi.balanceOf(address(this));
        uint256 hifiAmount = mftAmount / hifiMftRatio;
        require(hifiBalance >= hifiAmount, "ERR_MIGRATE_INSUFFICIENT_HIFI_BALANCE");

        // Effects: update the total amount of MFT migrated.
        totalMftMigrated = totalMftMigrated + mftAmount;

        // Interactions: transfer the MFT tokens to this contract.
        require(mft.transferFrom(msg.sender, address(this), mftAmount), "ERR_MIGRATE_CALL_HIFI_TRANSFER_FROM");

        // Interactions: transfer the HIFI tokens to the user.
        require(hifi.transfer(msg.sender, hifiAmount), "ERR_MIGRATE_CALL_HIFI_TRANSFER");

        emit MigrateMftToHifi(msg.sender, mftAmount, hifiAmount);

        return true;
    }

    /// @inheritdoc MftToHifMigratorInterface
    function _reclaimHifi(uint256 hifiAmount) external override onlyAdmin returns (bool) {
        // Checks: sufficient time passed.
        require(block.timestamp >= reclaimAllowedAfter, "ERR_RECLAIM_HIFI_TOO_EARLY");

        // Checks: sufficient liquidity.
        uint256 hifiBalance = hifi.balanceOf(address(this));
        require(hifiBalance >= hifiAmount, "ERR_RECLAIM_HIFI_INSUFFICIENT_BALANCE");

        // Interactions: transfer the HIFI tokens to the admin.
        require(hifi.transfer(admin, hifiAmount), "ERR_RECLAIM_HIFI_CALL_HIFI_TRANSFER");

        emit ReclaimHifi(admin, hifiAmount);

        return true;
    }

    /// @inheritdoc MftToHifMigratorInterface
    function _setIsEnabled(bool isEnabled_) external override onlyAdmin returns (bool) {
        isEnabled = isEnabled_;
        emit SetIsEnabled(admin, isEnabled_);
        return true;
    }
}