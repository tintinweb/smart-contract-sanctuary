/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.8.2;
// SPDX-License-Identifier: Unlicensed
// Telegram: https://t.me/shibainupumping 

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    
    uint256 private constant MAX = ~uint256(0);
    bool inSwapAndLiquify;
    
    uint256 private constant _tTotal = 1_000_000_000_000;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _taxFee = 5;
    uint256 public _liquidityFee = 8;
    uint256 public _previousTaxFee = _taxFee;
    uint256 public _previousLiquidityFee = _liquidityFee;

    uint256 public _maxTxAmount = 50_000;      // Max Buy/Sell: 5.0%
    uint256 public _maxWalletAmount = 60_000; // Max Wallet:    6.0%

    uint256 public _numTokensSellToAddToLiquidity = 5_000_000_000; // Number of tokens to sell before Liquidity gets added: (0.1%)
    string public name = "ShibaInuPumping";
    string public symbol = "SIP";
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