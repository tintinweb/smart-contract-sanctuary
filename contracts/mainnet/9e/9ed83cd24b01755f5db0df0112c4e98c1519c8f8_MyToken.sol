/**
 *Submitted for verification at Etherscan.io on 2020-12-03
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

contract PublicOwned { // owned by the public, lol
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    address payable owner;
    address payable newOwner;
  
}

abstract contract ISERC20TOKEN {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is PublicOwned,  ISERC20TOKEN {
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;

    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}

    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract MyToken is Token{

    constructor() public{
        symbol = "DFII";
        name = "DragonFinance";
        decimals = 18;
        totalSupply = 51000000000000000000000;   // 51m
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

receive () payable external {
require(msg.value>0);
owner.transfer(msg.value);
}
}