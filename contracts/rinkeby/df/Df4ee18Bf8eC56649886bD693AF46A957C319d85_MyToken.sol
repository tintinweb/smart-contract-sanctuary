pragma solidity  ^0.8.0;


contract MyToken {
    string public name = "Token";
    string public symbol = "TKN";
    uint public decimals = 18;
    uint public totalSupply = 100*10**18;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint)) appovals;
    
    constructor() {
        balance[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balance[msg.sender] >= _value, "There is no enough tokens");
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balance[_from] >= _value, "There is no enough tokens");
        require(allowance(_from, msg.sender) >= _value);
        balance[_from] -= _value;
        balance[_to] += _value;
        appovals[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        appovals[msg.sender][_spender] += _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return appovals[_owner][_spender];
    }
    
}