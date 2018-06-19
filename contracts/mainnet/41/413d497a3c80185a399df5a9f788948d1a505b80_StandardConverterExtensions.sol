pragma solidity ^0.4.11;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
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
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
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
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() {
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
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/*
    Standard Formula interface
*/
contract IStandardFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256);
}

/*
    Standard Gas Price Limit interface
*/
contract IStandardGasPriceLimit {
    function gasPrice() public constant returns (uint256) {}
}

/*
    Standard Quick Converter interface
*/
contract IStandardQuickConverter {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
}

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

/*
    We consider every contract to be a &#39;token holder&#39; since it&#39;s currently not possible
    for a contract to deny receiving tokens.

    The TokenHolder&#39;s contract sole purpose is to provide a safety mechanism that allows
    the owner to send tokens that were sent to the contract by mistake back to their sender.
*/
contract TokenHolder is ITokenHolder, Owned, Utils {
    /**
        @dev constructor
    */
    function TokenHolder() {
    }

    /**
        @dev withdraws tokens held by the contract and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

/*
    Standard Converter Extensions interface
*/
contract IStandardConverterExtensions {
    function formula() public constant returns (IStandardFormula) {}
    function gasPriceLimit() public constant returns (IStandardGasPriceLimit) {}
    function quickConverter() public constant returns (IStandardQuickConverter) {}
}

/**
    @dev the StandardConverterExtensions contract is an owned contract that serves as a single point of access
    to the StandardFormula, StandardGasPriceLimit and StandardQuickConverter contracts from all StandardConverter contract instances.
    it allows upgrading these contracts without the need to update each and every
    StandardConverter contract instance individually.
*/
contract StandardConverterExtensions is IStandardConverterExtensions, TokenHolder {
    IStandardFormula public formula;  // standard calculation formula contract
    IStandardGasPriceLimit public gasPriceLimit; // standard universal gas price limit contract
    IStandardQuickConverter public quickConverter; // standard quick changer contract

    /**
        @dev constructor

        @param _formula         address of a standard formula contract
        @param _gasPriceLimit   address of a standard gas price limit contract
        @param _quickConverter  address of a standard quick changer contract
    */
    function StandardConverterExtensions(IStandardFormula _formula, IStandardGasPriceLimit _gasPriceLimit, IStandardQuickConverter _quickConverter)
        validAddress(_formula)
        validAddress(_gasPriceLimit)
        validAddress(_quickConverter)
    {
        formula = _formula;
        gasPriceLimit = _gasPriceLimit;
        quickConverter = _quickConverter;
    }

    /*
        @dev allows the owner to update the formula contract address

        @param _formula    address of a standard formula contract
    */
    function setFormula(IStandardFormula _formula)
        public
        ownerOnly
        validAddress(_formula)
        notThis(_formula)
    {
        formula = _formula;
    }

    /*
        @dev allows the owner to update the gas price limit contract address

        @param _gasPriceLimit   address of a standard gas price limit contract
    */
    function setGasPriceLimit(IStandardGasPriceLimit _gasPriceLimit)
        public
        ownerOnly
        validAddress(_gasPriceLimit)
        notThis(_gasPriceLimit)
    {
        gasPriceLimit = _gasPriceLimit;
    }

    /*
        @dev allows the owner to update the quick changer contract address

        @param _quickConverter  address of a standard quick changer contract
    */
    function setQuickConverter(IStandardQuickConverter _quickConverter)
        public
        ownerOnly
        validAddress(_quickConverter)
        notThis(_quickConverter)
    {
        quickConverter = _quickConverter;
    }
}