pragma solidity ^0.4.24;

// File: contracts/interfaces/IOwned.sol

/*
    Owned Contract Interface
*/
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

// File: contracts/utility/Owned.sol

/*
    This is the "owned" utility contract used by bancor with one additional function - transferOwnershipNow()
    
    The original unmodified version can be found here:
    https://github.com/bancorprotocol/contracts/commit/63480ca28534830f184d3c4bf799c1f90d113846
    
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == owner);
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

    /**
        @dev transfers the contract ownership without needing the new owner to accept ownership
        @param newContractOwner    new contract owner
    */
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

// File: contracts/interfaces/IRegistrar.sol

/*
    Smart Token interface
*/
contract IRegistrar is IOwned {
    function addNewAddress(address _newAddress) public;
    function getAddresses() public view returns (address[]);
}

// File: contracts/Registrar.sol

/**
@notice Contains a record of all previous and current address of a community; For upgradeability.
*/
contract Registrar is Owned, IRegistrar {

    address[] addresses;
    /// @notice Adds new community logic contract address to Registrar
    /// @param _newAddress Address of community logic contract to upgrade to
    function addNewAddress(address _newAddress) public ownerOnly {
        addresses.push(_newAddress);
    }

    /// @return Array of community logic contract addresses
    function getAddresses() public view returns (address[]) {
        return addresses;
    }
}