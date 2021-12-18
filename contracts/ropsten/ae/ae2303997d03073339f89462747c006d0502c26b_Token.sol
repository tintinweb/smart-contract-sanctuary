/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Token{
    string public constant name="TheBestTokenInTheWorld";
    string public constant symbol="TBTITW";
    uint8 public constant decimals=12;

    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) balances;
    uint totalSupply=0;
    address immutable owner;

    event Transfer(address, address, uint);
    event Approval(address, address, uint);

    constructor(){
        owner = msg.sender;
    }

    modifier ownerOnly{
        require(msg.sender == owner);
        _;
    }

    function mint(address _add, uint _val)public ownerOnly{
        totalSupply += _val;
        balances[_add] += _val;
    }

    function balanceOf(address _add)public view returns(uint){
        return balances[_add];
    }

    function balanceOf()public view returns(uint){
        return balances[msg.sender];
    }

    function transfer(address _to, uint _val)public{
        require(balances[msg.sender] >= _val);
        balances[msg.sender] -= _val;
        balances[_to] += _val;
        emit Transfer(msg.sender, _to, _val);
    }

    function transferFrom(address _from, address _to, uint _val)public{
        require(allowed[_from][msg.sender] >= _val);
        require(balances[_from] >= _val);
        balances[_from] -= _val;
        allowed[_from][msg.sender] -= _val;
        balances[_to] += _val;
        emit Transfer(_from, _to, _val);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
    }

    function approve(address _to, uint _val)public{
        allowed[msg.sender][_to] = _val;
        emit Approval(msg.sender, _to, _val);
    }

    function allowance(address _from, address _to)public view returns(uint){
        return allowed[_from][_to];
    }
}