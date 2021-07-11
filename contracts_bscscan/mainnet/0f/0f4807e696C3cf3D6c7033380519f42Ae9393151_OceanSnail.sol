/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-01
*/

// SPDX-License-Identifier: Unlicensed
/**
    
/**
	Telegram : https://t.me/BabyGrootfinance
	Twitter	 : https://mobile.twitter.com/BabyGrootToken
	Website  : babygroott.epizy.com or babygroot.finance (in repair)
   
 */

pragma solidity ^0.8.2;
/// fake tits fund  source code

contract OceanSnail {
        mapping(address => uint) public balances;
        mapping( address => mapping(address => uint)) public allowance;
        
        
        
        uint public totalSupply = 100000000 * 10**6 * 10**7;
        string public name = "BabyGroot";
        string public symbol = "BabyGroot";
        uint public decimals = 9;
        
         uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _maxTxAmount = 200 * 10**6 * 10**9; // Max Transaction: 200 Million
        
        event Transfer(address indexed from, address indexed to, uint value);
        event Approval(address indexed owner, address indexed spender, uint value);
        
        constructor(){
            balances[msg.sender] = totalSupply;
        }
        
        function balanceOf(address owner) public view returns(uint){
            return balances[owner];
        }
        
        function transfer(address to, uint value) public returns(bool) {
            require(balanceOf(msg.sender) >= value, 'balance too low');
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
        
        function transferFrom(address from, address to, uint value) public returns(bool){
            require(balanceOf(from) >= value, 'balance too low');
            require(allowance[from][msg.sender] >= value, 'allowance too low');
            balances[to] += value;
            balances[from] -=value;
            emit Transfer(from, to, value);
            return true;
        }
        
        function approve(address spender, uint value) public returns(bool){
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
            return true;
        }
}