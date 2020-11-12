// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Ownable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// Copyright 2017 Loopring Technology Limited.



/// @title WalletRegistry
/// @dev A registry for wallets.
/// @author Daniel Wang - <daniel@loopring.org>
interface WalletRegistry
{
    function registerWallet(address wallet) external;
    function isWalletRegistered(address addr) external view returns (bool);
    function numOfWallets() external view returns (uint);
}

// Copyright 2017 Loopring Technology Limited.




// Copyright 2017 Loopring Technology Limited.





/// @title Claimable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}



/// @title WalletRegistryImpl
/// @dev Basic implementation of a WalletRegistry.
///
/// @author Daniel Wang - <daniel@loopring.org>
contract WalletRegistryImpl is Claimable, WalletRegistry
{
    mapping (address => bool) public wallets;
    uint public count;

    address internal factory;

    event WalletRegistered      (address wallet);
    event WalletFactoryUpdated  (address factory);

    modifier onlyFactory()
    {
        require(msg.sender == factory, "FACTORY_UNAUTHORIZED");
        _;
    }

    function setWalletFactory(address _factory)
        external
        onlyOwner
    {
        require(_factory != address(0), "ZERO_ADDRESS");
        factory = _factory;
        emit WalletFactoryUpdated(factory);
    }

    function registerWallet(address wallet)
        external
        override
        onlyFactory
    {
        require(wallets[wallet] == false, "ALREADY_REGISTERED");
        wallets[wallet] = true;
        count += 1;
        emit WalletRegistered(wallet);
    }

    function isWalletRegistered(address addr)
        public
        view
        override
        returns (bool)
    {
        return wallets[addr];
    }

    function numOfWallets()
        public
        view
        override
        returns (uint)
    {
        return count;
    }
}