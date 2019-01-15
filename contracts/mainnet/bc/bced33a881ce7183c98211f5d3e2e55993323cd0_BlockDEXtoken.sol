pragma solidity ^0.4.2;

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract BlockDEXtoken is StandardToken {

    function () external {
        revert();
    }

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = &#39;1.0&#39;;

    constructor () public {
        balances[msg.sender] = 500000000 * 1 ether / 1 wei;               // Give the creator all initial tokens
        totalSupply = 500000000 * 1 ether / 1 wei;                        // Update total supply
        name = &#39;BlockDEX&#39;;                                   // Set the name for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = &#39;BDEX&#39;;                               // Set the symbol for display purposes
    }
}