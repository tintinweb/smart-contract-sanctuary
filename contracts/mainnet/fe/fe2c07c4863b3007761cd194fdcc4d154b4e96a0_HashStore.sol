// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <daniel@loopring.org>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}

// Copyright 2017 Loopring Technology Limited.



// Copyright 2017 Loopring Technology Limited.



// Copyright 2017 Loopring Technology Limited.



/// @title Wallet
/// @dev Base contract for smart wallets.
///      Sub-contracts must NOT use non-default constructor to initialize
///      wallet states, instead, `init` shall be used. This is to enable
///      proxies to be deployed in front of the real wallet contract for
///      saving gas.
///
/// @author Daniel Wang - <daniel@loopring.org>
///
/// The design of this contract is inspired by Argent's contract codebase:
/// https://github.com/argentlabs/argent-contracts
interface Wallet
{
    function version() external pure returns (string memory);

    function owner() external view returns (address);

    /// @dev Set a new owner.
    function setOwner(address newOwner) external;

    /// @dev Adds a new module. The `init` method of the module
    ///      will be called with `address(this)` as the parameter.
    ///      This method must throw if the module has already been added.
    /// @param _module The module's address.
    function addModule(address _module) external;

    /// @dev Removes an existing module. This method must throw if the module
    ///      has NOT been added or the module is the wallet's only module.
    /// @param _module The module's address.
    function removeModule(address _module) external;

    /// @dev Checks if a module has been added to this wallet.
    /// @param _module The module to check.
    /// @return True if the module exists; False otherwise.
    function hasModule(address _module) external view returns (bool);

    /// @dev Binds a method from the given module to this
    ///      wallet so the method can be invoked using this wallet's default
    ///      function.
    ///      Note that this method must throw when the given module has
    ///      not been added to this wallet.
    /// @param _method The method's 4-byte selector.
    /// @param _module The module's address. Use address(0) to unbind the method.
    function bindMethod(bytes4 _method, address _module) external;

    /// @dev Returns the module the given method has been bound to.
    /// @param _method The method's 4-byte selector.
    /// @return _module The address of the bound module. If no binding exists,
    ///                 returns address(0) instead.
    function boundMethodModule(bytes4 _method) external view returns (address _module);

    /// @dev Performs generic transactions. Any module that has been added to this
    ///      wallet can use this method to transact on any third-party contract with
    ///      msg.sender as this wallet itself.
    ///
    ///      This method will emit `Transacted` event if it doesn't throw.
    ///
    ///      Note: this method must ONLY allow invocations from a module that has
    ///      been added to this wallet. The wallet owner shall NOT be permitted
    ///      to call this method directly.
    ///
    /// @param mode The transaction mode, 1 for CALL, 2 for DELEGATECALL.
    /// @param to The desitination address.
    /// @param value The amount of Ether to transfer.
    /// @param data The data to send over using `to.call{value: value}(data)`
    /// @return returnData The transaction's return value.
    function transact(
        uint8    mode,
        address  to,
        uint     value,
        bytes    calldata data
        )
        external
        returns (bytes memory returnData);
}



/// @title DataStore
/// @dev Modules share states by accessing the same storage instance.
///      Using ModuleStorage will achieve better module decoupling.
///
/// @author Daniel Wang - <daniel@loopring.org>
///
/// The design of this contract is inspired by Argent's contract codebase:
/// https://github.com/argentlabs/argent-contracts
abstract contract DataStore
{
    modifier onlyWalletModule(address wallet)
    {
        require(Wallet(wallet).hasModule(msg.sender), "UNAUTHORIZED");
        _;
    }
}



/// @title HashStore
/// @dev This store maintains all hashes for SignedRequest.
contract HashStore is DataStore
{
    // wallet => hash => consumed
    mapping(address => mapping(bytes32 => bool)) public hashes;

    constructor() {}

    function verifyAndUpdate(address wallet, bytes32 hash)
        public
        onlyWalletModule(wallet)
    {
        require(!hashes[wallet][hash], "HASH_EXIST");
        hashes[wallet][hash] = true;
    }
}