pragma solidity ^0.4.8;
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}
contract Vtoken is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    function Vtoken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
    }
    function balanceOf(address who) returns (uint256) {
        return SafeMath.safeAdd(balances[who], freezeOf[who]);
    }
    function freeBalanceOf(address who) returns (uint256) {
        return balances[who];
    }

    function transfer(address _to, uint256 _value) {
        if(_to == 0x0) throw;
        if (_value <= 0) throw; 
        if (balances[msg.sender] < _value) throw;
        if (balances[_to] + _value < balances[_to]) throw;
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;
        if (_value <= 0) throw; 
        if (balances[_from] < _value) throw;
        if (balances[_to] + _value < balances[_to]) throw;
        if (_value > allowance[_from][msg.sender]) throw;
        balances[_from] = SafeMath.safeSub(balances[_from], _value);
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) throw;
        if (_value <= 0) throw; 
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value);
        Burn(msg.sender, _value);
        return true;
    }
    function freeze(address _to, uint256 _value) returns (bool success) {
        if (msg.sender != owner) throw;
        if (balances[_to] < _value) throw;
        if (_value <= 0) throw; 
        balances[_to] = SafeMath.safeSub(balances[_to], _value);
        freezeOf[_to] = SafeMath.safeAdd(freezeOf[_to], _value);
        Freeze(_to, _value);
        return true;
    }
    function unfreeze(address _to, uint256 _value) returns (bool success) {
        if (msg.sender != owner) throw;
        if (freezeOf[_to] < _value) throw;
        if (_value <= 0) throw; 
        freezeOf[_to] = SafeMath.safeSub(freezeOf[_to], _value);
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);
        Unfreeze(_to, _value);
        return true;
    }
}