/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-07
*/

// File: solidity\contracts\utility\interfaces\IOwned.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

// File: solidity\contracts\converter\interfaces\IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {
}

// File: solidity\contracts\token\interfaces\IERC20Token.sol


pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity\contracts\utility\interfaces\IWhitelist.sol


pragma solidity 0.6.12;

/*
    Whitelist interface
*/
interface IWhitelist {
    function isWhitelisted(address _address) external view returns (bool);
}

// File: solidity\contracts\converter\interfaces\IConverter.sol


pragma solidity 0.6.12;





/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);
    function anchor() external view returns (IConverterAnchor);
    function isActive() external view returns (bool);

    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) external view returns (uint256, uint256);
    function convert(IERC20Token _sourceToken,
                     IERC20Token _targetToken,
                     uint256 _amount,
                     address _trader,
                     address payable _beneficiary) external payable returns (uint256);

    function conversionWhitelist() external view returns (IWhitelist);
    function conversionFee() external view returns (uint32);
    function maxConversionFee() external view returns (uint32);
    function reserveBalance(IERC20Token _reserveToken) external view returns (uint256);
    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;
    function acceptAnchorOwnership() external;
    function setConversionFee(uint32 _conversionFee) external;
    function setConversionWhitelist(IWhitelist _whitelist) external;
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
    function withdrawETH(address payable _to) external;
    function addReserve(IERC20Token _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);
    function transferTokenOwnership(address _newOwner) external;
    function acceptTokenOwnership() external;
    function connectors(IERC20Token _address) external view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) external view returns (uint256);
    function connectorTokens(uint256 _index) external view returns (IERC20Token);
    function connectorTokenCount() external view returns (uint16);
}

// File: solidity\contracts\converter\interfaces\ITypedConverterCustomFactory.sol


pragma solidity 0.6.12;

/*
    Typed Converter Custom Factory interface
*/
interface ITypedConverterCustomFactory {
    function converterType() external pure returns (uint16);
}

// File: solidity\contracts\utility\interfaces\IContractRegistry.sol


pragma solidity 0.6.12;

/*
    Contract Registry interface
*/
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

// File: solidity\contracts\converter\interfaces\IConverterFactory.sol


pragma solidity 0.6.12;





/*
    Converter Factory interface
*/
interface IConverterFactory {
    function createAnchor(uint16 _type, string memory _name, string memory _symbol, uint8 _decimals) external returns (IConverterAnchor);
    function createConverter(uint16 _type, IConverterAnchor _anchor, IContractRegistry _registry, uint32 _maxConversionFee) external returns (IConverter);

    function customFactories(uint16 _type) external view returns (ITypedConverterCustomFactory);
}

// File: solidity\contracts\converter\interfaces\ITypedConverterFactory.sol


pragma solidity 0.6.12;




/*
    Typed Converter Factory interface
*/
interface ITypedConverterFactory {
    function converterType() external pure returns (uint16);
    function createConverter(IConverterAnchor _anchor, IContractRegistry _registry, uint32 _maxConversionFee) external returns (IConverter);
}

// File: solidity\contracts\converter\interfaces\ITypedConverterAnchorFactory.sol


pragma solidity 0.6.12;


/*
    Typed Converter Anchor Factory interface
*/
interface ITypedConverterAnchorFactory {
    function converterType() external pure returns (uint16);
    function createAnchor(string memory _name, string memory _symbol, uint8 _decimals) external returns (IConverterAnchor);
}

// File: solidity\contracts\utility\Owned.sol


pragma solidity 0.6.12;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity\contracts\utility\Utils.sol


pragma solidity 0.6.12;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: solidity\contracts\utility\SafeMath.sol


pragma solidity 0.6.12;

/**
  * @dev Library for basic math operations with overflow/underflow protection
*/
library SafeMath {
    /**
      * @dev returns the sum of _x and _y, reverts if the calculation overflows
      *
      * @param _x   value 1
      * @param _y   value 2
      *
      * @return sum
    */
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev returns the difference of _x minus _y, reverts if the calculation underflows
      *
      * @param _x   minuend
      * @param _y   subtrahend
      *
      * @return difference
    */
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y, "ERR_UNDERFLOW");
        return _x - _y;
    }

    /**
      * @dev returns the product of multiplying _x by _y, reverts if the calculation overflows
      *
      * @param _x   factor 1
      * @param _y   factor 2
      *
      * @return product
    */
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // gas optimization
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      *
      * @param _x   dividend
      * @param _y   divisor
      *
      * @return quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
}

// File: solidity\contracts\token\ERC20Token.sol


pragma solidity 0.6.12;




/**
  * @dev ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    using SafeMath for uint256;


    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint256 public override totalSupply;
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    /**
      * @dev triggered when tokens are transferred between wallets
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
      * @dev triggered when a wallet allows another wallet to transfer tokens from on its behalf
      *
      * @param _owner   wallet that approves the allowance
      * @param _spender wallet that receives the allowance
      * @param _value   allowance amount
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
      * @dev initializes a new ERC20Token instance
      *
      * @param _name        token name
      * @param _symbol      token symbol
      * @param _decimals    decimal points, for display purposes
      * @param _totalSupply total supply of token units
    */
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
        // validate input
        require(bytes(_name).length > 0, "ERR_INVALID_NAME");
        require(bytes(_symbol).length > 0, "ERR_INVALID_SYMBOL");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    /**
      * @dev transfers tokens to a given address
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_to)
        returns (bool)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
      * @dev transfers tokens to a given address on behalf of another address
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_from)
        validAddress(_to)
        returns (bool)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
      * @dev allows another account/contract to transfers tokens on behalf of the caller
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _spender approved address
      * @param _value   allowance amount
      *
      * @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        validAddress(_spender)
        returns (bool)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

// File: solidity\contracts\token\interfaces\IDSToken.sol


pragma solidity 0.6.12;




/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20Token {
    function issue(address _to, uint256 _amount) external;
    function destroy(address _from, uint256 _amount) external;
}

// File: solidity\contracts\token\DSToken.sol


pragma solidity 0.6.12;




/**
  * @dev DSToken represents a token with dynamic supply.
  * The owner of the token can mint/burn tokens to/from any account.
  *
*/
contract DSToken is IDSToken, ERC20Token, Owned {
    using SafeMath for uint256;

    /**
      * @dev triggered when the total supply is increased
      *
      * @param _amount  amount that gets added to the supply
    */
    event Issuance(uint256 _amount);

    /**
      * @dev triggered when the total supply is decreased
      *
      * @param _amount  amount that gets removed from the supply
    */
    event Destruction(uint256 _amount);

    /**
      * @dev initializes a new DSToken instance
      *
      * @param _name       token name
      * @param _symbol     token short symbol, minimum 1 character
      * @param _decimals   for display purposes only
    */
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        public
        ERC20Token(_name, _symbol, _decimals, 0)
    {
    }

    /**
      * @dev increases the token supply and sends the new tokens to the given account
      * can only be called by the contract owner
      *
      * @param _to      account to receive the new amount
      * @param _amount  amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        override
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
      * @dev removes tokens from the given account and decreases the token supply
      * can only be called by the contract owner
      *
      * @param _from    account to remove the amount from
      * @param _amount  amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public override ownerOnly {
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }

    // ERC20 standard method overrides with some extra functionality

    /**
      * @dev send coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      *
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
      * @dev an account/contract attempts to get the coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }
}

// File: solidity\contracts\converter\ConverterFactory.sol


pragma solidity 0.6.12;









/*
    Converter Factory
*/
contract ConverterFactory is IConverterFactory, Owned {
    /**
      * @dev triggered when a new converter is created
      *
      * @param _type        converter type, see ConverterBase contract main doc
      * @param _converter   new converter address
      * @param _owner       converter owner address
    */
    event NewConverter(uint16 indexed _type, IConverter indexed _converter, address indexed _owner);

    mapping (uint16 => ITypedConverterFactory) public converterFactories;
    mapping (uint16 => ITypedConverterAnchorFactory) public anchorFactories;
    mapping (uint16 => ITypedConverterCustomFactory) public override customFactories;

    /**
      * @dev initializes the factory with a specific typed converter factory
      * can only be called by the owner
      *
      * @param _factory typed converter factory
    */
    function registerTypedConverterFactory(ITypedConverterFactory _factory) public ownerOnly {
        converterFactories[_factory.converterType()] = _factory;
    }

    /**
      * @dev initializes the factory with a specific typed converter anchor factory
      * can only be called by the owner
      *
      * @param _factory typed converter anchor factory
    */
    function registerTypedConverterAnchorFactory(ITypedConverterAnchorFactory _factory) public ownerOnly {
        anchorFactories[_factory.converterType()] = _factory;
    }

    /**
      * @dev initializes the factory with a specific typed converter custom factory
      * can only be called by the owner
      *
      * @param _factory typed converter custom factory
    */
    function registerTypedConverterCustomFactory(ITypedConverterCustomFactory _factory) public ownerOnly {
        customFactories[_factory.converterType()] = _factory;
    }

    /**
      * @dev creates a new converter anchor with the given arguments and transfers
      * the ownership to the caller
      *
      * @param _converterType   converter type, see ConverterBase contract main doc
      * @param _name            name
      * @param _symbol          symbol
      * @param _decimals        decimals
      *
      * @return new converter anchor
    */
    function createAnchor(uint16 _converterType, string memory _name, string memory _symbol, uint8 _decimals)
        public
        virtual
        override
        returns (IConverterAnchor)
    {
        IConverterAnchor anchor;
        ITypedConverterAnchorFactory factory = anchorFactories[_converterType];

        if (address(factory) == address(0)) {
            // create default anchor (DSToken)
            anchor = new DSToken(_name, _symbol, _decimals);
        }
        else {
            // create custom anchor
            anchor = factory.createAnchor(_name, _symbol, _decimals);
            anchor.acceptOwnership();
        }

        anchor.transferOwnership(msg.sender);
        return anchor;
    }

    /**
      * @dev creates a new converter with the given arguments and transfers
      * the ownership to the caller
      *
      * @param _type              converter type, see ConverterBase contract main doc
      * @param _anchor            anchor governed by the converter
      * @param _registry          address of a contract registry contract
      * @param _maxConversionFee  maximum conversion fee, represented in ppm
      *
      * @return new converter
    */
    function createConverter(uint16 _type, IConverterAnchor _anchor, IContractRegistry _registry, uint32 _maxConversionFee)
        public
        virtual
        override
        returns (IConverter)
    {
        IConverter converter = converterFactories[_type].createConverter(_anchor, _registry, _maxConversionFee);
        converter.acceptOwnership();
        converter.transferOwnership(msg.sender);

        emit NewConverter(_type, converter, msg.sender);
        return converter;
    }
}