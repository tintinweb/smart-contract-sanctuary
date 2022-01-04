/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.7.0;

// 這是一個叫做 Token 的合約
contract Token {

    // 貨幣的名稱叫做...
    string public name = "SYL's token";
    
    // 貨幣的代號是...
    string public symbol = "SYL";

    // 貨幣的總供給量
    uint256 public totalSupply = 1000000;
    
    // 此合約擁有者的地址
    address public owner;
    
    // 將不同地址映射到不同的貨幣持有量
    mapping(address => uint256) balances;

    // 當合約一部屬上鏈，就執行 constructor 裡的程式，謹此一次，此後就不會再執行
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // 此合約提供的第一個 function，貨幣轉移，填入一個地址和數量即可執行
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 此合約第二個 function，查詢持有的數量，填入一個地址就會回傳該地址擁有的貨幣持有量
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}