/**
 *Submitted for verification at snowtrace.io on 2021-12-20
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/PermissionManager.sol



interface IPermissionManager {
    function initOwner(address) external;

    function isAllowed(address) external view returns (bool);
}

contract PermissionManager is InitializableOwnable {
    bool public _WHITELIST_MODE_ON_;

    mapping(address => bool) internal _whitelist_;
    mapping(address => bool) internal _blacklist_;

    function isAllowed(address account) external view returns (bool) {
        if (_WHITELIST_MODE_ON_) {
            return _whitelist_[account];
        } else {
            return !_blacklist_[account];
        }
    }

    function openBlacklistMode() external onlyOwner {
        _WHITELIST_MODE_ON_ = false;
    }

    function openWhitelistMode() external onlyOwner {
        _WHITELIST_MODE_ON_ = true;
    }

    function addToWhitelist(address account) external onlyOwner {
        _whitelist_[account] = true;
    }

    function removeFromWhitelist(address account) external onlyOwner {
        _whitelist_[account] = false;
    }

    function addToBlacklist(address account) external onlyOwner {
        _blacklist_[account] = true;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        _blacklist_[account] = false;
    }
}