//SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;
import "owned.sol";

contract YFCoin is owned{
    uint256 public totalSupply;
    string public name = "YFCoin";
    string public symbol = "YFC";
    uint8 public decimals = 5;
    
    constructor (){
        totalSupply = 20000000000000;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];    
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != address(0x0));
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from]>=_value&&allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    event Transfer (address indexed _from, address indexed _to, uint256 _value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function Mint(uint256 _value) public onlyOwner returns (bool success){
        balances[msg.sender] += _value;
        totalSupply += _value;
        
        emit Transfer(address(0x0), msg.sender, _value);
        
        return true;
    }
    
    function Burn(uint256 _value) public returns (bool success){
        require (balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        
        return true;
    }
}