/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity 0.8.7; //SPDX-License-Identifier: UNLICENSED"

interface IERC20{
    function transfer(address sender, address receiver, uint256 amount) external returns (bool);
    function transferFrom(address sender, address receiver, uint256 amount) external returns(bool);
    function approve(address sender, address receiver, uint256 amount) external returns (bool);
    function allowance(address sender, address user) external view returns(uint256);
    function mint(address user, uint256 amount) external returns (bool);
    function burn(address user, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns(uint256);
}

contract ERC20 is IERC20 {
    
    uint256 public totalSupply;
    mapping(address => uint256) balances_;
    mapping(address =>mapping ( address =>uint256)) allowances_;
    
    
    function transfer(address sender, address receiver, uint256 amount) public override returns (bool){
        require(amount<= balanceOf(sender),"not enough money" );
        balances_[sender] -=  amount;
        balances_[receiver] += amount;
        return true;
        //beforeTransfer()
    }
    
        
    function transferFrom(address sender, address receiver, uint256 amount) public override returns(bool){
        require(allowance(sender,msg.sender) >= amount,"transferFrom: exceed allowance");
        transfer(sender,receiver,amount);
        return true;
    }
    function approve(address sender, address receiver, uint256 amount) public override returns (bool){
        allowances_[sender][receiver] += amount;
        return true;
    }
    function allowance(address sender, address user) public view override returns(uint256){
        return allowances_[sender][user];
    }
    function mint(address user, uint256 amount) public override returns (bool) {
        totalSupply += amount;
        balances_[user] += amount;
        return true;
    }
    function burn(address user, uint256 amount) public override returns (bool) {
        totalSupply -= amount;
        balances_[user] -= amount;
        return true;
    }
    function balanceOf(address user) public view override returns(uint256){
        return balances_[user];
    }
    
}