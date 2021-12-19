/**
 *Submitted for verification at polygonscan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interfaces/IOwnableCallForwarder.sol

pragma solidity 0.8.9;

interface IOwnableCallForwarder {
    event ForwardedCall(
        address indexed targetAddress,
        uint256 forwardedValue,
        bytes forwardedCalldata,
        bytes returnedData
    );

    function forwardCall(
        address targetAddress,
        bytes calldata forwardedCalldata
    ) external payable returns (bytes memory returnedData);
}


// File contracts/OwnableCallForwarder.sol

pragma solidity 0.8.9;


/// @title Contract that forwards the calls that its owner sends
/// @dev AccessControlRegistry users that want their access control tables
/// to be transferrable (e.g., a DAO) will use this forwarder instead of
/// interacting with it directly. There are cases where this transferrability
/// is not desired, e.g., if the user is an Airnode and is immutably associated
/// with a single address, in which case the manager will interact with
/// AccessControlRegistry directly.
contract OwnableCallForwarder is Ownable, IOwnableCallForwarder {
    /// @notice Forwards the calldata to the target address if the sender is
    /// the owner and returns the data
    /// @dev This function emits its event after an untrusted low-level call,
    /// meaning that the order of these events within the transaction should
    /// not be taken seriously, yet the content will be sound.
    /// @param targetAddress Target address that the calldata will be forwarded
    /// to
    /// @param forwardedCalldata Calldata to be forwarded to the target address
    /// @return returnedData Data returned by the forwarded call
    function forwardCall(
        address targetAddress,
        bytes calldata forwardedCalldata
    ) external payable override onlyOwner returns (bytes memory returnedData) {
        bool callSuccess;
        (callSuccess, returnedData) = targetAddress.call{value: msg.value}( // solhint-disable-line avoid-low-level-calls
            forwardedCalldata
        );
        require(callSuccess, "Call unsuccessful");
        emit ForwardedCall(
            targetAddress,
            msg.value,
            forwardedCalldata,
            returnedData
        );
    }
}