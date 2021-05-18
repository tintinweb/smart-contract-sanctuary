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

import {UpgradeableClaimable as Claimable} from "UpgradeableClaimable.sol";

/**
 * @title ImplementationReference
 * @dev This contract is made to serve a simple purpose only.
 * To hold the address of the implementation contract to be used by proxy.
 * The implementation address, is changeable anytime by the owner of this contract.
 */
contract ImplementationReference is Claimable {
    address public implementation;

    /**
     * @dev Event to show that implementation address has been changed
     * @param newImplementation New address of the implementation
     */
    event ImplementationChanged(address newImplementation);

    /**
     * @dev Set initial ownership and implementation address
     * @param _implementation Initial address of the implementation
     */
    constructor(address _implementation) public {
        Claimable.initialize(msg.sender);
        implementation = _implementation;
    }

    /**
     * @dev Function to change the implementation address, which can be called only by the owner
     * @param newImplementation New address of the implementation
     */
    function setImplementation(address newImplementation) external onlyOwner {
        implementation = newImplementation;
        emit ImplementationChanged(newImplementation);
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