pragma solidity ^0.4.24;

/******************************************/
/*       Netkiller ADVANCED TOKEN         */
/******************************************/
/* Author netkiller <netkiller@msn.com>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-06-13 - SafeMatch         */
/******************************************/
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract NetkillerAdvancedToken {
    
    using SafeMath for uint256;
    
    address public owner;
    string public name;
    string public symbol;
    uint public decimals;
    uint256 public totalSupply;
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address indexed target, bool frozen);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) public {
        owner = msg.sender;
        name = tokenName;
        symbol = tokenSymbol; 
        decimals = decimalUnits;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }
    function balanceOf(address _address) view public returns (uint256 balance) {
        return balances[_address];
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0));                        // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);                // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]);   // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balances[_from] = balances[_from].sub(_value);      // Subtract from the sender
        balances[_to] = balances[_to].add(_value);          // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function transferBatch(address[] _to, uint256 _value) public returns (bool success) {
        for (uint i=0; i<_to.length; i++) {
            _transfer(msg.sender, _to[i], _value);
        }
        return true;
    }
}