/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma abicoder v2;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: Ownable

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
//        require(
//            newOwner != address(0),
//            "Ownable: new owner is the zero address"
//        );
//        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: SafeModuleCore

/// @title The core contract that implements a role based access control module for Gnosis Safe
/// @author Cobo Safe Dev Team ([email protected])
/// @notice The core implementation of Cobo Safe Moudule
/// @dev This contract implements the core data structure and its related features.
abstract contract SafeModuleCore is Ownable {

    string public constant NAME = "Safe Module";
    string public constant VERSION = "0.2.2";


}

// File: CoboSafeModule.sol

/// @title A GnosisSafe module that implements Cobo's role based access control policy
/// @author Cobo Safe Dev Team ([email protected])
/// @notice Use this module to access Gnosis Safe with role based access control policy
contract SafeModule is SafeModuleCore {
    /// @notice Contructor function for CoboSafeModule
    /// @dev When this module is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance. The instance is
    ///      supposed to call `enableModule` on the constructed module instance
    ///      in order for it to function properly.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    constructor(address payable _safe) {
        // make the given safe the owner of the current module.
//        _transferOwnership(_safe);

    }
}