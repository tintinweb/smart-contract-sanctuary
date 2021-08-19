/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) internal isTokenHolder;
    uint public totalSupply = 1000*10**3;
    string public name = "Hufflecoin";
    string public symbol = "HUFF";
    uint public decimals = 3;
    uint totalTaxedAmount = 0;
    uint totalUniqueUsers = 0;
    uint tax = 2000;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        totalUniqueUsers = 1;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value - tax;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        if(!isTokenHolder[to]) {
            isTokenHolder[to] =  true;
            totalUniqueUsers++;
        }
        totalTaxedAmount += tax;
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value - tax;
        balances[from] -= value;
        emit Transfer(from, to, value);
        if(!isTokenHolder[to]) {
            isTokenHolder[to] =  true;
            totalUniqueUsers++;
        }
        totalTaxedAmount += tax;
        return true;   
    }

    function getTotalHolders() public view returns(uint) {
        return totalUniqueUsers;
    }
    
    function getTotalBurned() public view returns(uint) {
        return totalTaxedAmount;
    }
    
    function getTotalAvailableCoins() public view returns(uint) {
        return totalSupply-totalTaxedAmount;
    }
    
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
}