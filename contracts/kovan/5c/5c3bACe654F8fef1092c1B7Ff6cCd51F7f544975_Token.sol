/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.6;

contract Token{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    //mapping_1
    mapping(address => uint256)public balanceOf;
    
    //mapping_2
    mapping(address => mapping(address => uint256))public allowance;
    
    //event_1
    event Transfer(address indexed from, address indexed to, uint256 value);
    //event_2 
    event approval (address indexed _owner, address indexed spender, uint256 indexed value);
    
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply){
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    //transfer fucntion
    function transfer(address _to, uint256 _value)external returns(bool success){
        require(balanceOf[msg.sender] <= _value);
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
    //approve fucntion 
    function approve(address _spender, uint256 _value)external returns(bool){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit approval(msg.sender, _spender, _value);
        return true;
    }
    //transferfrom function
    function transferfrom(address _from, address _to, uint256 _value)external returns(bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        _transfer(_from, _to, _value);
        return true;
    }
}