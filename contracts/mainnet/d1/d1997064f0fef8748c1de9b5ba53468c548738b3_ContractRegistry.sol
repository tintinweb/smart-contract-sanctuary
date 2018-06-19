pragma solidity ^0.4.21;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    function Owned() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function getAddress(bytes32 _contractName) public view returns (address);
}

/**
    Contract Registry

    The contract registry keeps contract addresses by name.
    The owner can update contract addresses so that a contract name always points to the latest version
    of the given contract.
    Other contracts can query the registry to get updated addresses instead of depending on specific
    addresses.

    Note that contract names are limited to 32 bytes, UTF8 strings to optimize gas costs
*/
contract ContractRegistry is IContractRegistry, Owned {
    mapping (bytes32 => address) addresses;

    event AddressUpdate(bytes32 indexed _contractName, address _contractAddress);

    /**
        @dev constructor
    */
    function ContractRegistry() public {
    }

    /**
        @dev returns the address associated with the given contract name

        @param _contractName    contract name

        @return contract address
    */
    function getAddress(bytes32 _contractName) public view returns (address) {
        return addresses[_contractName];
    }

    /**
        @dev registers a new address for the contract name

       @param _contractName     contract name
       @param _contractAddress  contract address
    */
    function registerAddress(bytes32 _contractName, address _contractAddress) public ownerOnly {
        require(_contractName.length > 0); // validating input

        addresses[_contractName] = _contractAddress;
        emit AddressUpdate(_contractName, _contractAddress);
    }
}