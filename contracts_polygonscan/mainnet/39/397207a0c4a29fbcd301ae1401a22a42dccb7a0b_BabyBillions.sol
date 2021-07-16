/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

/**
 *Submitted for verification
*/

/**
 * 
______       _          ______ _ _ _ _                 
| ___ \     | |         | ___ (_) | (_)                
| |_/ / __ _| |__  _   _| |_/ /_| | |_  ___  _ __  ___ 
| ___ \/ _` | '_ \| | | | ___ \ | | | |/ _ \| '_ \/ __|
| |_/ / (_| | |_) | |_| | |_/ / | | | | (_) | | | \__ \
\____/ \__,_|_.__/ \__, \____/|_|_|_|_|\___/|_| |_|___/
                    __/ |                              
                   |___/
       
*/

pragma solidity ^0.8.3;

contract BabyBillions{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 18;
    uint256 public constant _MAX_TX_SIZE = 5000000000000000 * 10 ** 18;
    string public name = "BabyBillions";
    string public symbol = "BB";
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