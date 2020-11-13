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
        bool maintainList
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

pragma experimental ABIEncoderV2;


// Copyright 2017 Loopring Technology Limited.


interface IAgent{}

interface IAgentRegistry
{
    /// @dev Returns whether an agent address is an agent of an account owner
    /// @param owner The account owner.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address owner,
        address agent
        )
        external
        view
        returns (bool);

    /// @dev Returns whether an agent address is an agent of all account owners
    /// @param owners The account owners.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address[] calldata owners,
        address            agent
        )
        external
        view
        returns (bool);
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



contract AgentRegistry is IAgentRegistry, AddressSet, Claimable
{
    bytes32 internal constant UNIVERSAL_AGENTS = keccak256("__UNVERSAL_AGENTS__");

    event AgentRegistered(
        address indexed user,
        address indexed agent,
        bool            registered
    );

    event TrustUniversalAgents(
        address indexed user,
        bool            trust
    );

    constructor() Claimable() {}

    function isAgent(
        address user,
        address agent
        )
        external
        override
        view
        returns (bool)
    {
        return isUniversalAgent(agent) || isUserAgent(user, agent);
    }

    function isAgent(
        address[] calldata users,
        address            agent
        )
        external
        override
        view
        returns (bool)
    {
        if (isUniversalAgent(agent)) {
            return true;
        }
        for (uint i = 0; i < users.length; i++) {
            if (!isUserAgent(users[i], agent)) {
                return false;
            }
        }
        return true;
    }

    function registerUniversalAgent(
        address agent,
        bool    toRegister
        )
        external
        onlyOwner
    {
        registerInternal(UNIVERSAL_AGENTS, agent, toRegister);
        emit AgentRegistered(address(0), agent, toRegister);
    }

    function isUniversalAgent(address agent)
        public
        view
        returns (bool)
    {
        return isAddressInSet(UNIVERSAL_AGENTS, agent);
    }

    function registerUserAgent(
        address agent,
        bool    toRegister
        )
        external
    {
        registerInternal(userKey(msg.sender), agent, toRegister);
        emit AgentRegistered(msg.sender, agent, toRegister);
    }

    function isUserAgent(
        address user,
        address agent
        )
        public
        view
        returns (bool)
    {
        return isAddressInSet(userKey(user), agent);
    }

    function registerInternal(
        bytes32 key,
        address agent,
        bool    toRegister
        )
        private
    {
        require(agent != address(0), "ZERO_ADDRESS");
        if (toRegister) {
            addAddressToSet(key, agent, false /* maintanList */);
        } else {
            removeAddressFromSet(key, agent);
        }
    }

    function userKey(address addr)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("__AGENT__", addr));
    }
}