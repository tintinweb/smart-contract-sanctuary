pragma solidity ^0.4.11;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
	bool public disabled = false;
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (disabled != true && balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (disabled != true && balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract NexxusToken is StandardToken {

    function () {throw;}

    string public name = "Nexxus";
    uint8 public decimals = 8;
    string public symbol = "NXX";
    address public owner;

    function NexxusToken() {
        totalSupply = 31500000000000000;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
	function mintToken(uint256 _amount) {
        if (msg.sender == owner) {
    		totalSupply += _amount;
            balances[owner] += _amount;
    		Transfer(0, owner, _amount);
        }
	}
	function disableToken(bool _disable) { 
        if (msg.sender == owner)
			disabled = _disable;
    }
}