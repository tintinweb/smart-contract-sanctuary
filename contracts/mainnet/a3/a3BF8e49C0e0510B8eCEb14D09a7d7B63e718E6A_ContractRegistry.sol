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
    Contract Registry interface
*/
contract IContractRegistry {
    function getAddress(bytes32 _contractName) public view returns (address);
}

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
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

/**
    Contract Registry

    The contract registry keeps contract addresses by name.
    The owner can update contract addresses so that a contract name always points to the latest version
    of the given contract.
    Other contracts can query the registry to get updated addresses instead of depending on specific
    addresses.

    Note that contract names are limited to 32 bytes UTF8 strings to optimize gas costs
*/
contract ContractRegistry is IContractRegistry, Owned, Utils {
    struct RegistryItem {
        address contractAddress;
        uint256 nameIndex;
        bool isSet;
    }

    mapping (bytes32 => RegistryItem) private items;    // name -> address mapping
    bytes32[] public names;                             // list of all registered contract names

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
        return items[_contractName].contractAddress;
    }

    /**
        @dev registers a new address for the contract name in the registry

       @param _contractName     contract name
       @param _contractAddress  contract address
    */
    function registerAddress(bytes32 _contractName, address _contractAddress)
        public
        ownerOnly
        validAddress(_contractAddress)
    {
        require(_contractName.length > 0); // validate input

        // update the address in the registry
        items[_contractName].contractAddress = _contractAddress;
        
        if (!items[_contractName].isSet) {
            // mark the item as set
            items[_contractName].isSet = true;
            // add the contract name to the name list and update the item&#39;s index in the list
            items[_contractName].nameIndex = names.push(_contractName) - 1;
        }

        // dispatch the address update event
        emit AddressUpdate(_contractName, _contractAddress);
    }

    /**
        @dev removes an existing contract address from the registry

       @param _contractName contract name
    */
    function unregisterAddress(bytes32 _contractName) public ownerOnly {
        require(_contractName.length > 0); // validate input

        // remove the address from the registry
        items[_contractName].contractAddress = address(0);

        if (items[_contractName].isSet) {
            // mark the item as empty
            items[_contractName].isSet = false;
            // move the last element to the deleted element&#39;s position
            names[items[_contractName].nameIndex] = names[names.length - 1];
            // remove the last element from the name list
            names.length--;
            // zero the deleted element&#39;s index
            items[_contractName].nameIndex = 0;
        }

        // dispatch the address update event
        emit AddressUpdate(_contractName, address(0));
    }
}