/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 




abstract contract USDTInterface{
    function transfer(address to, uint value) public virtual;
    function transferFrom(address from, address to, uint value) public virtual;
}





contract DepositAsset  {
    using SafeMath for uint;
    
    USDTInterface USDT = USDTInterface(address(0x015FF40F138dd03Dce1F72c38A7758C21B34F3fB));
    
    constructor(){
        owner = msg.sender;
        cash = 1e6;
        point = 1000e6;
    }
    
    uint cash;
    uint point;
    address owner;
    mapping (address => uint)balance; 
    mapping (address => bool)legal;
    
    
    
    
    function deposit(uint usdt_amount, address user)external {
        USDT.transferFrom(user,address(this),usdt_amount);
        uint point_amount = usdt_amount.mul(point).div(cash);
        balance[user] = balance[user].add(point_amount);
        
        point = point.add(point_amount);
        cash = cash.add(usdt_amount);
    }
    
    
    function withdraw(uint point_amount)public {
        require(balance[msg.sender] >= point_amount);
        uint usdt_amount = point_amount.mul(cash).div(point);
        balance[msg.sender] = balance[msg.sender].sub(point_amount);
        USDT.transfer(msg.sender,usdt_amount);
        
        point = point.sub(point_amount);
        cash = cash.sub(usdt_amount);
    }
    
    
    function transfer(address _from, address to, uint point_amount)public {
        require(legal[msg.sender] == true);
        balance[_from] = balance[_from].sub(point_amount);
        balance[to] = balance[to].add(point_amount);
    }
    
    
    function interest(uint cash_amount)public {
        require(legal[msg.sender] == true);
        cash = cash.add(cash_amount);
    }
    
    
    
  
    
    
    
    // ------------------------------------------------------------------------ admin
    
    
    function set_access(address contract_address, bool btn)public{
        require(msg.sender == owner);
        legal[contract_address] = btn;
    }
    
    
    // ------------------------------------------------------------------------ view
    
    
    function get_balance(address user)public view returns(uint){
        return balance[user];
    }
    
    
    function total_cash()public view returns(uint){
        return cash;
    }
    
    
    function total_point()public view returns(uint){
        return point;
    }
    
    
    
    
    
   
   
    
    
    
}