/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

interface IERC20 {
    function totalSupply()external view returns(uint256);
    function balanceOf(address who) external view returns(uint256);
    function transfer(address to,uint256 value) external returns(bool);
    function transferFrom(address owner,address spender,uint256 value) external returns(bool);
    function allowance(address from,address to) external view returns(uint256);
    function approve(address spender,uint256 value) external returns(bool);
    
    event Transfer(address from,address to,uint256 value);
    event Approval(address from,address to,uint256 value);
}



// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract MyERC20 is IERC20 {
    
    string public name;//名称 
    uint8  public decimals;//小数位 
    string public symbol;//简称 
    uint256 private totalsupply;//总量 

    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    constructor (string memory _name,string memory _symbol) {
        totalsupply = 5000000 * 18;
        balances[msg.sender] = totalsupply;
       
        name =_name;
        decimals = 18;
        symbol = _symbol;
     
    }
    
    function totalSupply() external override view returns(uint256) {
        return totalsupply;
    }
    
    function balanceOf(address who)external override view returns(uint256){
        return balances[who];
    }
    
    function transfer(address to,uint256 value) external override returns(bool){
        require(value > 0,"value must be greater than 0");
        require(balances[msg.sender] >= value,"The balance is too small");
        require(address(0) != to,"Must be a valid address");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    
    function transferFrom(address owner,address spender,uint256 value) external override returns(bool){
        require(value > 0,"value must be greater than 0");
        require(address(0) != spender,"Must be a valid address");
        require(allowed[owner][spender] >= value,"authorized amount must be greater than Transfer amount");
        balances[owner] -= value;
        balances[spender] += value;
        allowed[owner][msg.sender] -= value;
        emit Transfer(owner,spender,value);
        return true;
    }
    
    function allowance(address from,address to) external override view returns(uint256){
        return allowed[from][to];
    }
    
    function approve(address spender,uint256 value) external override returns (bool){
        require(value > 0,"value must be greater than 0");
        require(balances[msg.sender] >= value,"The balance is too small");
        require(address(0) != spender,"Must be a valid address");
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
    }
    
}