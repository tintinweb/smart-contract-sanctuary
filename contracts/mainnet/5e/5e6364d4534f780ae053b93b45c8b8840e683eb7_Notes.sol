pragma solidity ^0.4.18;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// The NOTES ERC20 Token. There is a delay before addresses that are not added to the "activeGroup" can transfer tokens. 
// That delay ends when admin calls the "activate()" function.
// Otherwise it is a generic ERC20 standard token, based originally on the BAT token
// https://etherscan.io/address/0x0d8775f648430679a709e98d2b0cb6250d2887ef#code

// The standard ERC20 Token interface
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// NOTES Token Implementation - transfers are prohibited unless switched on by admin
contract Notes is Token {

    using SafeMath for uint256;

    //// CONSTANTS

    // Number of NOTES (800 million)
    uint256 public constant TOTAL_SUPPLY = 2000 * (10**6) * 10**uint256(decimals);

    // Token Metadata
    string public constant name = "NOTES";
    string public constant symbol = "NOTES";
    uint8 public constant decimals = 18;
    string public version = "1.0";

    //// PROPERTIES

    address admin;
    bool public activated = false;
    mapping (address => bool) public activeGroup;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;

    //// MODIFIERS

    modifier active()
    {
        require(activated || activeGroup[msg.sender]);
        _;
    }

    modifier onlyAdmin()
    {
        require(msg.sender == admin);
        _;
    }

    //// CONSTRUCTOR

    function Notes(address fund, address _admin)
    {
        admin = _admin;
        totalSupply = TOTAL_SUPPLY;
        balances[fund] = TOTAL_SUPPLY;    // Deposit all to fund
        Transfer(address(this), fund, TOTAL_SUPPLY);
        activeGroup[fund] = true;  // Allow the fund to transfer
    }

    //// ADMIN FUNCTIONS

    function addToActiveGroup(address a) onlyAdmin {
        activeGroup[a] = true;
    }

    function activate() onlyAdmin {
        activated = true;
    }

    //// TOKEN FUNCTIONS

    function transfer(address _to, uint256 _value) active returns (bool success) {
        require(_to != address(0));
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) active returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) active returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}