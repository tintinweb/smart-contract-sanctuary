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

pragma experimental ABIEncoderV2;

interface IAmmSharedConfig
{
    function maxForcedExitAge() external view returns (uint);
    function maxForcedExitCount() external view returns (uint);
    function forcedExitFee() external view returns (uint);
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



contract LoopringAmmSharedConfig is Claimable, IAmmSharedConfig
{
    uint _maxForcedExitAge;
    uint _maxForcedExitCount;
    uint _forcedExitFee;

    event ValueChanged(string name, uint value);

    function maxForcedExitAge()
        external
        view
        override
        returns (uint)
    {
        return _maxForcedExitAge;
    }

    function maxForcedExitCount()
        external
        view
        override
        returns (uint)
    {
        return _maxForcedExitCount;
    }

    function forcedExitFee()
        external
        view
        override
        returns (uint)
    {
        return _forcedExitFee;
    }

    function setMaxForcedExitAge(uint v)
        external
        onlyOwner
    {
        _maxForcedExitAge = v;
        emit ValueChanged("maxForcedExitAge", v);
    }

    function setMaxForcedExitCount(uint v)
        external
        onlyOwner
    {
        _maxForcedExitCount = v;
        emit ValueChanged("maxForcedExitCount", v);
    }

    function setForcedExitFee(uint v)
        external
        onlyOwner
    {
        _forcedExitFee = v;
        emit ValueChanged("forcedExitFee", v);
    }
}