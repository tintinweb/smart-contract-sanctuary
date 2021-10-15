/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/*

So this is another pulseshiba fork, this will be a community token. I don't give a damn lel.
Make a group or something, or not, it's up to all of you degens.
I'll put 1 bnb lp and locking it for a week, you can verify it on the creator address txn, and held 0.5% of total supply as my fee.
The tax is 0, so use lower slippage, or else frontrun bots will rekt your capital.
There's no way I could rug you, cuz literally there's only transfer, approve, and balace function on this contract lmao.
Good luck, let this be a fun experiment !
*/

pragma solidity ^0.8.2;

contract BABYCALLISTO {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000000 * 10 ** 18;
    string public name = "BABY CALLISTO";
    string public symbol = "BABY CALLISTO";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
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
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}