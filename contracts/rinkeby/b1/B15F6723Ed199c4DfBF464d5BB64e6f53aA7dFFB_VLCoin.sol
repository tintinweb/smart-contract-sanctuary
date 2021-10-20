pragma solidity ^0.8.9;

contract VLCoin {
    
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    
    mapping(address => uint) balance;
    mapping(address => mapping(address => uint)) _allowance;
    
    constructor() {
        name = "VL Coin";
        symbol = "VLC";
        decimals = 18;
        totalSupply = 1000000 * 10 ** 18;
        
        balance[msg.sender] = totalSupply;
    }


    function balanceOf(address _owner) public view returns (uint) {
         return balance[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balance[msg.sender] >= _value);
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_allowance[_from][msg.sender] >= _value);
        require(balance[_from] >= _value, "To less founds");
        balance[_from] -= _value;
        balance[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}