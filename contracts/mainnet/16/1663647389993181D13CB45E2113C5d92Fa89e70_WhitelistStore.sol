// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
// File: contracts/iface/Wallet.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Wallet
/// @dev Base contract for smart wallets.
///      Sub-contracts must NOT use non-default constructor to initialize
///      wallet states, instead, `init` shall be used. This is to enable
///      proxies to be deployed in front of the real wallet contract for
///      saving gas.
///
/// @author Daniel Wang - <daniel@loopring.org>
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
    ///      Note: 1) this method must ONLY allow invocations from a module that has
    ///      been added to this wallet. The wallet owner shall NOT be permitted
    ///      to call this method directly. 2) Reentrancy inside this function should
    ///      NOT cause any problems.
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

// File: contracts/base/DataStore.sol

// Copyright 2017 Loopring Technology Limited.



/// @title DataStore
/// @dev Modules share states by accessing the same storage instance.
///      Using ModuleStorage will achieve better module decoupling.
///
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract DataStore
{
    modifier onlyWalletModule(address wallet)
    {
        requireWalletModule(wallet);
        _;
    }

    function requireWalletModule(address wallet) view internal
    {
        require(Wallet(wallet).hasModule(msg.sender), "UNAUTHORIZED");
    }
}

// File: contracts/lib/AddressSet.sol

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

// File: contracts/lib/Ownable.sol

// Copyright 2017 Loopring Technology Limited.


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

// File: contracts/lib/Claimable.sol

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

// File: contracts/lib/OwnerManagable.sol

// Copyright 2017 Loopring Technology Limited.




contract OwnerManagable is Claimable, AddressSet
{
    bytes32 internal constant MANAGER = keccak256("__MANAGED__");

    event ManagerAdded  (address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyManager
    {
        require(isManager(msg.sender), "NOT_MANAGER");
        _;
    }

    modifier onlyOwnerOrManager
    {
        require(msg.sender == owner || isManager(msg.sender), "NOT_OWNER_OR_MANAGER");
        _;
    }

    constructor() Claimable() {}

    /// @dev Gets the managers.
    /// @return The list of managers.
    function managers()
        public
        view
        returns (address[] memory)
    {
        return addressesInSet(MANAGER);
    }

    /// @dev Gets the number of managers.
    /// @return The numer of managers.
    function numManagers()
        public
        view
        returns (uint)
    {
        return numAddressesInSet(MANAGER);
    }

    /// @dev Checks if an address is a manger.
    /// @param addr The address to check.
    /// @return True if the address is a manager, False otherwise.
    function isManager(address addr)
        public
        view
        returns (bool)
    {
        return isAddressInSet(MANAGER, addr);
    }

    /// @dev Adds a new manager.
    /// @param manager The new address to add.
    function addManager(address manager)
        public
        onlyOwner
    {
        addManagerInternal(manager);
    }

    /// @dev Removes a manager.
    /// @param manager The manager to remove.
    function removeManager(address manager)
        public
        onlyOwner
    {
        removeAddressFromSet(MANAGER, manager);
        emit ManagerRemoved(manager);
    }

    function addManagerInternal(address manager)
        internal
    {
        addAddressToSet(MANAGER, manager, true);
        emit ManagerAdded(manager);
    }
}

// File: contracts/stores/WhitelistStore.sol

// Copyright 2017 Loopring Technology Limited.





/// @title WhitelistStore
/// @dev This store maintains a wallet's whitelisted addresses.
contract WhitelistStore is DataStore, AddressSet, OwnerManagable
{
    bytes32 internal constant DAPPS = keccak256("__DAPPS__");

    // wallet => whitelisted_addr => effective_since
    mapping(address => mapping(address => uint)) public effectiveTimeMap;

    event Whitelisted(
        address wallet,
        address addr,
        bool    whitelisted,
        uint    effectiveTime
    );

    event DappWhitelisted(
        address addr,
        bool    whitelisted
    );

    constructor() DataStore() {}

    function addToWhitelist(
        address wallet,
        address addr,
        uint    effectiveTime
        )
        external
        onlyWalletModule(wallet)
    {
        addAddressToSet(_walletKey(wallet), addr, true);
        uint effective = effectiveTime >= block.timestamp ? effectiveTime : block.timestamp;
        effectiveTimeMap[wallet][addr] = effective;
        emit Whitelisted(wallet, addr, true, effective);
    }

    function removeFromWhitelist(
        address wallet,
        address addr
        )
        external
        onlyWalletModule(wallet)
    {
        removeAddressFromSet(_walletKey(wallet), addr);
        delete effectiveTimeMap[wallet][addr];
        emit Whitelisted(wallet, addr, false, 0);
    }

    function addDapp(address addr)
        external
        onlyManager
    {
        addAddressToSet(DAPPS, addr, true);
        emit DappWhitelisted(addr, true);
    }

    function removeDapp(address addr)
        external
        onlyManager
    {
        removeAddressFromSet(DAPPS, addr);
        emit DappWhitelisted(addr, false);
    }

    function whitelist(address wallet)
        public
        view
        returns (
            address[] memory addresses,
            uint[]    memory effectiveTimes
        )
    {
        addresses = addressesInSet(_walletKey(wallet));
        effectiveTimes = new uint[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            effectiveTimes[i] = effectiveTimeMap[wallet][addresses[i]];
        }
    }

    function isWhitelisted(
        address wallet,
        address addr
        )
        public
        view
        returns (
            bool isWhitelistedAndEffective,
            uint effectiveTime
        )
    {
        effectiveTime = effectiveTimeMap[wallet][addr];
        isWhitelistedAndEffective = effectiveTime > 0 && effectiveTime <= block.timestamp;
    }

    function whitelistSize(address wallet)
        public
        view
        returns (uint)
    {
        return numAddressesInSet(_walletKey(wallet));
    }

    function dapps()
        public
        view
        returns (
            address[] memory addresses
        )
    {
        return addressesInSet(DAPPS);
    }

    function isDapp(
        address addr
        )
        public
        view
        returns (bool)
    {
        return isAddressInSet(DAPPS, addr);
    }

    function numDapps()
        public
        view
        returns (uint)
    {
        return numAddressesInSet(DAPPS);
    }

    function isDappOrWhitelisted(
        address wallet,
        address addr
        )
        public
        view
        returns (bool res)
    {
        (res,) = isWhitelisted(wallet, addr);
        return res || isAddressInSet(DAPPS, addr);
    }

    function _walletKey(address addr)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("__WHITELIST__", addr));
    }

}