// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";

/// @title Firestarter WhiteList Contract
/// @notice You can use this contract to manage WL users
/// @dev All function calls are currently implemented without side effects
contract Whitelist is Ownable {
    bool public whitelistEnabled;

    /// @dev White List
    mapping(address => bool) private whitelisted;

    /// @notice An event emitted when the whitelist is enabled or disabled
    event WhitelistEnabled(bool enabled);

    /// @notice An event emitted when a user is added or removed. True: Added, False: Removed
    event AddedOrRemoved(bool added, address user, uint256 timestamp);

    constructor() {
        whitelistEnabled = true;
    }

    /**
     * @notice Enable or disable whitelisting feature
     * @dev Only owner can do this action
     * @param enabled boolean value
     */
    function setWhitelistEnabled(bool enabled) external onlyOwner {
        require(whitelistEnabled != enabled);
        whitelistEnabled = enabled;
        emit WhitelistEnabled(enabled);
    }

    /**
     * @notice Add users to white list
     * @dev Only owner can do this operation
     * @param users List of user data
     */
    function addToWhitelist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelisted[users[i]] = true;
            emit AddedOrRemoved(true, users[i], block.timestamp);
        }
    }

    /**
     * @notice Remove from white lsit
     * @dev Only owner can do this operation
     * @param users addresses to be removed
     */
    function removeFromWhitelist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelisted[users[i]] = false;
            emit AddedOrRemoved(false, users[i], block.timestamp);
        }
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return !whitelistEnabled || whitelisted[addr];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

