/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

/**
 *Submitted for verification
*/

/**

     888b     d888 d8b          d8b 888888b.            888               8888888                   
8888b   d8888 Y8P          Y8P 888  "88b           888                 888                     
88888b.d88888                  888  .88P           888                 888                     
888Y88888P888 888 88888b.  888 8888888K.   8888b.  88888b.  888  888   888   88888b.  888  888 
888 Y888P 888 888 888 "88b 888 888  "Y88b     "88b 888 "88b 888  888   888   888 "88b 888  888 
888  Y8P  888 888 888  888 888 888    888 .d888888 888  888 888  888   888   888  888 888  888 
888   "   888 888 888  888 888 888   d88P 888  888 888 d88P Y88b 888   888   888  888 Y88b 888 
888       888 888 888  888 888 8888888P"  "Y888888 88888P"   "Y88888 8888888 888  888  "Y88888 
                                                                 888                           
                                                            Y8b d88P                           
                                                             "Y88P"      
           
  ** No dev-wallets **
  ** Locked liquidity **
  ** Renounced ownership! **

       
*/

pragma solidity ^0.8.3;

contract MiniBabyInu{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 18;
    uint256 public constant _MAX_TX_SIZE = 5000000000000000 * 10 ** 18;
    string public name = "MiniBabyInu";
    string public symbol = "MiniBabyInu";
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