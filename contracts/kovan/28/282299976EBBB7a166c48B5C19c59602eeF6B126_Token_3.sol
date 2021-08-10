/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.6;

contract Token_3{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    //mapping for balanceOf
    
    mapping(address => uint256)public balanceOf;
    
    //mapping  for allowance
    
    mapping (address => mapping(address => uint256))public allowance;
    
    //event_1
    
    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    
    //event_2
    
    event approve(address indexed _owner, address indexed spender, uint256 indexed value);
    
    //constructor fucntion
    
    constructor (string memory _name, string memory _symbol, uint _decimals, uint _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    //transfer function
    
    function transfer (address _to, uint256 _value)external returns(bool success){
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    //_transfer function
    
    function _transfer(address _from, address _to, uint256 _value)internal{
       require(_to != address(0));
       balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
       balanceOf[_to] = balanceOf[_to] + (_value);
       emit Transfer(_from, _to, _value);
    }
    
    //approval function 
    
    function approval(address _spender, uint256 _value)external returns (bool){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit approve(msg.sender, _spender, _value);
        return true;
    }
    
    //transferfrom function
    
    function transferfrom(address _from, address _to, uint256 _value)external returns(bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    
    
    
}