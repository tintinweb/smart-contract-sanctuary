/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity ^0.4.22;

contract TokenErc20 {
    string public name;
    string public symbol;
    uint8 decimals;
    
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint value);
    event Approval(address indexed _owner, address indexed _spender, uint value);
    
    mapping(address=>uint) public balances;
    mapping(address => mapping(address => uint)) allowances;
    
    constructor(
        string _name, 
        string _symbol,
        uint8 _decimals,
        uint _initialSupply
        ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[msg.sender] = _initialSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];    
    }
    
    function transfer(address _to, uint _value) public returns(bool success) {
        transferFrom(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public {
        require(balances[_from] >= _value);
        require(allowance(_from, _to) >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint _value) public {
        allowances[msg.sender][_spender] = _value;   
    }
    
    function allowance(address _owner, address _spender) public view returns(uint) {
        allowances[_owner][_spender];    
    }
}