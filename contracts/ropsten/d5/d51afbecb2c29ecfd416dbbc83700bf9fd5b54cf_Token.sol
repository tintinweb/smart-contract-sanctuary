/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

//SPDX-License-Identifier: GPL - 3.0

pragma solidity >=0.8.7;

contract Token{
    string constant name = "DxDLover";
    string constant symbol = "D";
    uint8 constant decimals = 2;

    event Transfer(address _from, address _to, uint _value);
    event Approval(address _from, address _spender, uint _value);

    uint totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address owner;
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function mint(address toAdd, uint toSupply) onlyOwner public {
        totalSupply += toSupply;
        balances[toAdd] += toSupply;
    }

    function balanceOf(address toCheck) public view returns(uint){
        return balances[toCheck];
    }

    function balanceOf() public view returns(uint){
        return balances[msg.sender];
    }

    function transfer(address _to, uint _value )public{
        if(balances[msg.sender] >= _value){
            balances[_to] += _value;
            balances[msg.sender] -= _value;
            emit Transfer(msg.sender, _to, _value);
        }
    }

    function transferFrom(address _to, address _from, uint _value)public{
        if((allowance(_from, msg.sender) >= _value) && (balances[_from] >= _value)){
            balances[_from] -= _value;
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            allowed[_from][msg.sender] -= _value;
        }
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _from, address _spender) public view returns(uint){
        return allowed[_from][_spender];
    }
}