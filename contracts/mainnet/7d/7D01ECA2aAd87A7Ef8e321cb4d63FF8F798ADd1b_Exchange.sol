/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}



contract Exchange{
    
    address public oldtoken;
    address public newtoken;
    address public owner;
    
    event Swap(address _user, uint _amount);
    
    modifier onlyOwner{
        require(msg.sender == owner, "only owner");
        _;
    }
    
    function transferOwnership(address _newowner)public onlyOwner{
        owner = _newowner;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    function setTokens(address _old, address _new)public onlyOwner{
        oldtoken = _old;
        newtoken = _new;
    }
    
    
    function swap(uint _amount) public{
        require(IERC20(oldtoken).balanceOf(msg.sender) >= _amount,"insufficient old tokens");
        require(IERC20(newtoken).balanceOf(address(this))>=_amount,"insufficient new tokens");
        
        IERC20(oldtoken).transferFrom(msg.sender, address(this), _amount);
        IERC20(newtoken).transfer(msg.sender, _amount);
        
        emit Swap(msg.sender, _amount);
    }
    
    
    
}