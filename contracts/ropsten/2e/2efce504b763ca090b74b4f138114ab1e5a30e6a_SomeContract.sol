/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: GPL-3.0
//Устанавливаем версии компилятора
pragma solidity >=0.8.0;
contract SomeContract
{
    event Transfer(address _address_x,address _address_y,uint _value);
    event Approval(address _address_x,address _address_y,uint _value);
    string public name="Baitkoin";
    string public symbol="BAT";
    uint8 public decimals=3;
    mapping(address => mapping(address => uint)) public allowed;
    uint totalSupply=0;
    address owner = msg.sender;
    mapping(address => uint) balances;
    function mint(address _address,uint _value) public payable
    {
        require(owner == msg.sender && totalSupply<=totalSupply+_value && balances[_address]<= balances[_address]+_value);
        totalSupply+=_value;
        balances[_address]+=_value;
    }
    function balanceOf(address _address) public view returns(uint)
    {
        return balances[_address];
    }
    function balanceOf() public view returns(uint)
    {
        return balances[msg.sender];
    }
    function transfer(address _address,uint _value) public
    {
        require( balances[_address] >= _value);
        require( balances[_address]+_value >= balances[_address]);
        balances[msg.sender]-=_value;
        balances[_address]+=_value;
        emit Transfer(msg.sender,_address,_value);
        
    }
    function approve(address _address_y,uint _value) public payable
    {
        allowed[msg.sender][_address_y]=_value;
        emit Approval (msg.sender,_address_y,_value);
        
    }
    function allowance(address _address_x,address _address_y) public view returns(uint)
    {
       return allowed[_address_x][_address_y];
        
    }
    function transferForm(address _address_x,address _address_y,uint _value) public payable
    {
        require( balances[_address_x] >= _value);
        require( balances[_address_y]+_value >= balances[_address_y]);
        balances[_address_x]-=_value;
        balances[_address_y]+=_value;
        allowed[_address_x][msg.sender]-=_value;
        emit Transfer(_address_x,_address_y,_value);
        emit Approval (_address_x,msg.sender,_value);
        
    }
    
}