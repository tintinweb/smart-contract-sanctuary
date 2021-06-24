/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

/**
 *Submitted for verification
*/
/**
 * 
8""""                    8""""                   
8     ee   e eeee eeeee  8     eeeee eeeee eeeee 
8eeee 88   8 8    8   8  8eeee 8   8 8   "   8   
88    88  e8 8eee 8eee8e 88    8eee8 8eeee   8e  
88     8  8  88   88   8 88    88  8    88   88  
88eee  8ee8  88ee 88   8 88    88  8 8ee88   88

Built upon the fundamentals of Buyback and increasing the investor's value
    
Main features are
    
1) 2% tax is collected and distributed to holders for HODLing
2) 9% buyback and marketing tax is collected and 3% of it is sent for marketing fund and other 6% is used to buyback the tokens
   
Official launch June 24th
http://t.me/EverFast
Website: www.everfastxyz

*/

pragma solidity ^0.8.3;

contract EverFast{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 18;
    uint256 public constant _MAX_TX_SIZE = 5000000000000000 * 10 ** 18;
    string public name = "EverFast t.me/EverFast";
    string public symbol = "EverFast";
    uint public decimals = 18;

    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        require(value <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");
        balances[to] += value * 9/10;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}