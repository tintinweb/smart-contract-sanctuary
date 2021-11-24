/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.4.24;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts/utility/Owned.sol

pragma solidity ^0.4.24;


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
}

// File: contracts/utility/Utils.sol

pragma solidity ^0.4.24;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    constructor() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

// File: contracts/ConverterRegistryContract.sol

pragma solidity ^0.4.24;



/**
    Converter Registry

    The converter registry keeps converter addresses by token addresses and vice versa.
    The owner can update converter addresses so that a the token address always points to
    the updated list of converters for each token.

    The contract also allows to iterate through all the tokens in the network.

    Note that converter addresses for each token are returned in ascending order (from oldest
    to latest).
*/
contract ConverterRegistryContract is Owned, Utils {
    mapping (address => bool) private tokensRegistered;         // token address -> registered or not
    mapping (address => address[]) private tokensToConverters;  // token address -> converter addresses
    mapping (address => address) private convertersToTokens;    // converter address -> token address
    address[] public tokens;                                    // list of all token addresses

    // triggered when a converter is added to the registry
    event ConverterAddition(address indexed _token, address _address);

    // triggered when a converter is removed from the registry
    event ConverterRemoval(address indexed _token, address _address);

    /**
        @dev constructor
    */
    constructor() public {
    }

    /**
        @dev returns the number of tokens in the registry

        @return number of tokens
    */
    function tokenCount() public view returns (uint256) {
        return tokens.length;
    }

    /**
        @dev returns the number of converters associated with the given token
        or 0 if the token isn't registered

        @param _token   token address

        @return number of converters
    */
    function converterCount(address _token) public view returns (uint256) {
        return tokensToConverters[_token].length;
    }

    /**
        @dev returns the converter address associated with the given token
        or zero address if no such converter exists

        @param _token   token address
        @param _index   converter index

        @return converter address
    */
    function converterAddress(address _token, uint32 _index) public view returns (address) {
        if (_index >= tokensToConverters[_token].length)
            return address(0);

        return tokensToConverters[_token][_index];
    }

    /**
        @dev returns the token address associated with the given converter
        or zero address if no such converter exists

        @param _converter   converter address

        @return token address
    */
    function tokenAddress(address _converter) public view returns (address) {
        return convertersToTokens[_converter];
    }

    /**
        @dev adds a new converter address for a given token to the registry
        throws if the converter is already registered

        @param _token       token address
        @param _converter   converter address
    */
    function registerConverter(address _token, address _converter)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_converter)
    {
        require(convertersToTokens[_converter] == address(0));

        // add the token to the list of tokens
        if (!tokensRegistered[_token]) {
            tokens.push(_token);
            tokensRegistered[_token] = true;
        }

        tokensToConverters[_token].push(_converter);
        convertersToTokens[_converter] = _token;

        // dispatch the converter addition event
        emit ConverterAddition(_token, _converter);
    }

    /**
        @dev removes an existing converter from the registry
        note that the function doesn't scale and might be needed to be called
        multiple times when removing an older converter from a large converter list

        @param _token   token address
        @param _index   converter index
    */
    function unregisterConverter(address _token, uint32 _index)
        public
        ownerOnly
        validAddress(_token)
    {
        require(_index < tokensToConverters[_token].length);

        address converter = tokensToConverters[_token][_index];

        // move all newer converters 1 position lower
        for (uint32 i = _index + 1; i < tokensToConverters[_token].length; i++) {
            tokensToConverters[_token][i - 1] = tokensToConverters[_token][i];
        }

        // decrease the number of converters defined for the token by 1
        tokensToConverters[_token].length--;
        
        // removes the converter from the converters -> tokens list
        delete convertersToTokens[converter];

        // dispatch the converter removal event
        emit ConverterRemoval(_token, converter);
    }
}