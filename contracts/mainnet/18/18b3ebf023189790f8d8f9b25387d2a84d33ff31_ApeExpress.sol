/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
/**
💰🍌 The Ape Express - AE 🦧🚂 Token JUST STEALTH LAUNCHED!!!

"Those who beat their chests the hardest tend to receive the best returns on their Crypto.  
Don't waste your time monkey-barring around with rug pulls and pump and dump crypto flash, join the Ape Train and evolve yourself into a better investor."

Imagine a Token with unlimited Marketing Funds and Consistent Liquid Banana additions (And we never have to sell against the Chart) ... We ripped off the Ceiling!!! APE IN and collect Bananas!

🗣https://t.me/ApeExpress

✅Locked Liquidity
✅No Team Tokens
✅No Presale
✅Constant Marketing!
✅Community Driven
✅5% Max Buy 1st minute
🆔Trusted and Fully Doxed Dev 
🍌Let's Go Bananas!
🔥10% Tokenomics that goes 100% back into the Community

💰 5% ETH to Marketing Wallet - The most Energetic and Obnoxious Apes who beat their Chests the Loudest will receive Free Bananas! 
Bananas = Ethereum Drops right on your big Ape head! Random Winners will be picked by @Idfightaghost so be sure to Impress her! Make her Belly Laugh and you win bigger!

"We use marketing funds to reward Community members, not just pay schmucks!"

🤑 5% for Banana Buybacks 🍌 and Adding to Liquidity (Will constantly use ETH rewards to buy Tokens and then add the equal amount of ETH/AE to the Locked Liquidity Pool) 
*Wallet Starts with 5% for Quick Liquidity Adds before Buybacks*

At the end of the day a Token can only Pump as high as Liquidity to Market Cap Gap allows it to, before future investor confidence is shot... So if we keep adding Bananas, the chart will keep Pumping!

The Ape Express 🦧🚂💰🍌, [20.08.21 07:45]
To Protect you... If we do not drop a Contract Address AND unlock chat at the same time... IT IS a DECOY TOKEN DESIGNED TO TAKE YOUR LIQUIDITY DO NOT BUY PLEASE ❤️
Disclaimer:It's only a scam if a Dev tells you to Buy the Token and then takes the liquidity... If I didn't tell you to buy my Token, don't Buy it! #NothingButLove
*/

pragma solidity ^0.8.0;

contract ApeExpress {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 constant _totalSupply = 1000000000 * 10**6 * 10**18;
    string constant _name = "The Ape Express";
    string constant _symbol = "AE";
    uint8 constant _decimals = 18;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}