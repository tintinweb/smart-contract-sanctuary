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



/// @title AddressSet
/// @author Daniel Wang - <daniel@loopring.org>
contract AddressSet
{
    struct Set
    {
        address[] addresses;
        mapping (address => uint) positions;
        uint count;
    }
    mapping (bytes32 => Set) private sets;

    function addAddressToSet(
        bytes32 key,
        address addr,
        bool    maintainList
        ) internal
    {
        Set storage set = sets[key];
        require(set.positions[addr] == 0, "ALREADY_IN_SET");

        if (maintainList) {
            require(set.addresses.length == set.count, "PREVIOUSLY_NOT_MAINTAILED");
            set.addresses.push(addr);
        } else {
            require(set.addresses.length == 0, "MUST_MAINTAIN");
        }

        set.count += 1;
        set.positions[addr] = set.count;
    }

    function removeAddressFromSet(
        bytes32 key,
        address addr
        )
        internal
    {
        Set storage set = sets[key];
        uint pos = set.positions[addr];
        require(pos != 0, "NOT_IN_SET");

        delete set.positions[addr];
        set.count -= 1;

        if (set.addresses.length > 0) {
            address lastAddr = set.addresses[set.count];
            if (lastAddr != addr) {
                set.addresses[pos - 1] = lastAddr;
                set.positions[lastAddr] = pos;
            }
            set.addresses.pop();
        }
    }

    function removeSet(bytes32 key)
        internal
    {
        delete sets[key];
    }

    function isAddressInSet(
        bytes32 key,
        address addr
        )
        internal
        view
        returns (bool)
    {
        return sets[key].positions[addr] != 0;
    }

    function numAddressesInSet(bytes32 key)
        internal
        view
        returns (uint)
    {
        Set storage set = sets[key];
        return set.count;
    }

    function addressesInSet(bytes32 key)
        internal
        view
        returns (address[] memory)
    {
        Set storage set = sets[key];
        require(set.count == set.addresses.length, "NOT_MAINTAINED");
        return sets[key].addresses;
    }
}
// Copyright 2017 Loopring Technology Limited.



// Copyright 2017 Loopring Technology Limited.



/// @title ModuleRegistry
/// @dev A registry for modules.
///
/// @author Daniel Wang - <daniel@loopring.org>
interface ModuleRegistry
{
	/// @dev Registers and enables a new module.
    function registerModule(address module) external;

    /// @dev Disables a module
    function disableModule(address module) external;

    /// @dev Returns true if the module is registered and enabled.
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns the list of enabled modules.
    function enabledModules() external view returns (address[] memory _modules);

    /// @dev Returns the number of enbaled modules.
    function numOfEnabledModules() external view returns (uint);

    /// @dev Returns true if the module is ever registered.
    function isModuleRegistered(address module) external view returns (bool);
}



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



/// @title ModuleRegistryImpl
/// @dev Basic implementation of a ModuleRegistry.
///
/// @author Daniel Wang - <daniel@loopring.org>
contract ModuleRegistryImpl is Claimable, AddressSet, ModuleRegistry
{
    bytes32 internal constant ENABLED_MODULE = keccak256("__ENABLED_MODULE__");
    bytes32 internal constant ALL_MODULE     = keccak256("__ALL_MODULE__");

    event ModuleRegistered      (address module);
    event ModuleDeregistered    (address module);

    constructor() Claimable() {}

    function registerModule(address module)
        external
        override
        onlyOwner
    {
        addAddressToSet(ENABLED_MODULE, module, true);

        if (!isAddressInSet(ALL_MODULE, module)) {
            addAddressToSet(ALL_MODULE, module, false);
        }
        emit ModuleRegistered(module);
    }

    function disableModule(address module)
        external
        override
        onlyOwner
    {
        removeAddressFromSet(ENABLED_MODULE, module);
        emit ModuleDeregistered(module);
    }

    function isModuleEnabled(address module)
        external
        view
        override
        returns (bool)
    {
        return isAddressInSet(ENABLED_MODULE, module);
    }

    function isModuleRegistered(address module)
        external
        view
        override
        returns (bool)
    {
        return isAddressInSet(ALL_MODULE, module);
    }

    function enabledModules()
        external
        view
        override
        returns (address[] memory)
    {
        return addressesInSet(ENABLED_MODULE);
    }

    function numOfEnabledModules()
        external
        view
        override
        returns (uint)
    {
        return numAddressesInSet(ENABLED_MODULE);
    }
}