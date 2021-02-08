/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// File: contracts\token\interfaces\IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);    
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts\utility\Utils.sol

pragma solidity 0.4.26;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    /**
      * constructor
    */
    constructor() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0, "greaterThanZero");
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0), "validAddress");
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this), "notThis");
        _;
    }

}

// File: contracts\utility\SafeMath.sol

pragma solidity 0.4.26;

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
        require(z >= _x, "add() z >= _x");
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
        require(_x >= _y, "sub() _x >= _y");
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
        require(z / _x == _y, "mul() z / _x == _y");
        return z;
    }

      /**
        * ev Integer division of two numbers truncating the quotient, reverts on division by zero.
        * 
        * aram _x   dividend
        * aram _y   divisor
        * 
        * eturn quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "div() _y > 0");
        uint256 c = _x / _y;

        return c;
    }
}

// File: contracts\token\ERC20Token.sol

pragma solidity 0.4.26;




/**
  * @dev ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This is for debug purpose
    //event Log(address from, string message);

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

    // This is for debug purpose
    event Log(address from, string message);

    /**
      * @dev initializes a new ERC20Token instance
      * 
      * @param _name        token name
      * @param _symbol      token symbol
      * @param _decimals    decimal points, for display purposes
      * @param _totalSupply total supply of token units
    */
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply ) public {
        require(bytes(_name).length > 0  , "constructor: name == 0"); // validate input
        require(bytes(_symbol).length > 0, "constructor: symbol == 0"); // validate input

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        //emit Log(msg.sender, "constractor()");
    }

    /**
      * @dev send coins
      * throws on any error rather then return a false flag to minimize user errors
      * 
      * @param _to      target address
      * @param _value   transfer amount
      * 
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        //emit Log(msg.sender, "transfer() sender");
        return _transfer( msg.sender, _to, _value );
    }
    
    /**
      * @dev an account/contract attempts to get the coins
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
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        return _transfer( _from, _to, _value );
    }

    /**
      * @dev allow another account/contract to spend some tokens on your behalf
      * throws on any error rather then return a false flag to minimize user errors
      * 
      * also, to minimize the risk of the approve/transferFrom attack vector
      * (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
      * in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value
      * 
      * @param _spender approved address
      * @param _value   allowance amount
      * 
      * @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        return _approve(msg.sender, _spender, _value );
    }

    /**
      * @dev 
      * 
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      * 
      * @return true if the transfer was successful, false if it wasn't
    */
    function _transfer(address _from, address _to, uint256 _value)
        internal
        returns (bool success)
    {
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _from, address _spender, uint256 _value)
        internal
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[_from][_spender] == 0);

        allowance[_from][_spender] = _value;

        emit Approval(_from, _spender, _value);
        return true;
    }
}

// File: contracts\meta_test\TxRelayUtil.sol

pragma solidity 0.4.26;
// -*- coding: utf-8-unix -*-

contract TxRelayUtil {

    address txrelay;

    modifier onlyTxRelay() {
        require(address(0) != txrelay, "TxRelay null");
        require(msg.sender == txrelay, "sender not TxRelay");
        _;
    }
}

// File: contracts\token\CHMToken.sol

pragma solidity 0.4.26;



/**
  * @dev ERC20 Standard Token implementation
*/
contract CHMToken is ERC20Token, TxRelayUtil {
    /**
      * @dev initializes a new ERC20Token instance
      * 
      * @param _name        token name
      * @param _symbol      token symbol
      * @param _decimals    decimal points, for display purposes
      * @param _totalSupply total supply of token units
    */
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply ) public
        ERC20Token(_name, _symbol, _decimals, _totalSupply )
    {
    }

    function set_txrelay( address _to ) public
        validAddress(_to)
        returns (bool success)
    {
        require(txrelay == address(0), "It has been set txrelay address.");
        txrelay = _to;
        return true;
    }

    /**
      * @dev 
      * 
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      * 
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferRelay(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        onlyTxRelay
        returns (bool success)
    {
        //emit Log(msg.sender, "transferRelay() sender");
        //emit Log(_from, "transferRelay() from");
        //emit Log(_to, "transferRelay() to");
        //emit Log(txrelay, "transferRelay() txrelay");
        return _transfer( _from, _to, _value );
    }

    /**
      * @dev allow another account/contract to spend some tokens on your behalf
      * throws on any error rather then return a false flag to minimize user errors
      * 
      * also, to minimize the risk of the approve/transferFrom attack vector
      * (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
      * in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value
      * 
      * @param _spender approved address
      * @param _value   allowance amount
      * 
      * @return true if the approval was successful, false if it wasn't
    */
    function approveRelay(address _from, address _spender, uint256 _value)
        public
        validAddress(_from)
        validAddress(_spender)
        onlyTxRelay
        returns (bool success)
    {
        return _approve(_from, _spender, _value );
    }
}