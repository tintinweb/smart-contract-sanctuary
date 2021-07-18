/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

pragma solidity ^0.8.2;


contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "HAVANA DOGE";
    string public symbol = "HDOGE";
    uint public decimals = 18;
    uint public fee;

     //address to which the fees go
    address public feeAddress = address(0x0000000000000000000000000000000000000000);
    
    event Transfer(address indexed from, address indexed to, address indexed feeAddress, uint value);
    event Approval(address indexed owner, address indexed spender, address indexed feeAddress, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
   
//transaction  
    function transfer(address to, uint value) external returns (bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low'); 
        balances[to] += value;   //send amount to receiver
        balances[msg.sender] -= value; // subtract the full amount
        emit Transfer(msg.sender, to, feeAddress, value);
        return true; 
    }   
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        fee = (value / 100) * 20; // Calculate 20% fee
        balances[to] += value - fee; //send amount-fee to receiver
        balances[from] -= value; // subtract the full amount
        balances[feeAddress] += fee; // add the fee to the feeAddress balance
        emit Transfer(from, to,feeAddress, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender,feeAddress, value);
        return true;   
    }
    
}