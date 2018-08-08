pragma solidity 0.4.16;

contract Token {

    function totalSupply() constant returns (uint supply) {}
    function balanceOf(address _owner) constant returns (uint balance) {}
    function transfer(address _to, uint _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}
    function approve(address _spender, uint _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract SDToken is StandardToken {

    uint8 constant public decimals = 18;
    uint public totalSupply = 2*(10**9)*(10**18);
    string constant public name = "SixDomainToken";
    string constant public symbol = "SDT";

    function SDToken() {
        balances[msg.sender] = totalSupply;
    }
}