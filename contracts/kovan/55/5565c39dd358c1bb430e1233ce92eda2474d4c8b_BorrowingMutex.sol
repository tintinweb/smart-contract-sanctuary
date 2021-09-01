// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /**
     * @dev Return true if and only if the contract has been initialized
     * @return whether the contract has been initialized
     */
    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Context} from "Context.sol";

import {Initializable} from "Initializable.sol";

/**
 * @title UpgradeableClaimable
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. Since
 * this contract combines Claimable and UpgradableOwnable contracts, ownership
 * can be later change via 2 step method {transferOwnership} and {claimOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract UpgradeableClaimable is Initializable, Context {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting a custom initial owner of choice.
     * @param __owner Initial owner of contract to be set.
     */
    function initialize(address __owner) internal initializer {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface IBorrowingMutex {
    function lock(address borrower, address _locker) external;

    function unlock(address borrower) external;

    function isUnlocked(address borrower) external view returns (bool);

    function locker(address borrower) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {UpgradeableClaimable} from "UpgradeableClaimable.sol";

import {IBorrowingMutex} from "IBorrowingMutex.sol";

contract BorrowingMutex is IBorrowingMutex, UpgradeableClaimable {
    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    mapping(address => address) public override locker;

    mapping(address => bool) public canLock;

    // ======= STORAGE DECLARATION END ===========

    event LockerAllowed(address locker, bool isAllowed);

    event BorrowerLocked(address borrower, address locker);

    event BorrowerUnlocked(address borrower, address locker);

    function initialize() external initializer {
        UpgradeableClaimable.initialize(msg.sender);
    }

    function allowLocker(address _locker, bool isAllowed) external onlyOwner {
        canLock[_locker] = isAllowed;
        emit LockerAllowed(_locker, isAllowed);
    }

    function lock(address borrower, address _locker) external override {
        require(canLock[msg.sender], "BorrowingMutex: Sender is not allowed to lock borrowers");
        require(isUnlocked(borrower), "BorrowingMutex: Borrower is already locked");
        locker[borrower] = _locker;
        emit BorrowerLocked(borrower, _locker);
    }

    function unlock(address borrower) external override {
        address _locker = locker[borrower];
        require(_locker == msg.sender, "BorrowingMutex: Only locker can unlock");
        locker[borrower] = address(0);
        emit BorrowerUnlocked(borrower, _locker);
    }

    function isUnlocked(address borrower) public override view returns (bool) {
        return locker[borrower] == address(0);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}