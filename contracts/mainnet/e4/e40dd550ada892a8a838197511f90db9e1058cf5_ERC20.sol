/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

/* 
            /)-_-(\     ██████╗      /)-_-(\
             (o o)      ╚════██╗      (o o)
     .-----__/\o/         ▄███╔╝       \o/\__-----.
    /  __      /          ▀▀══╝         \      __  \
\__/\ /  \_\ |/           ██╗            \| /_/  \ /\__/
     \\     ||            ╚═╝            ||      \\
     //     ||                           ||      //
     |\     |\                           /|     /|
--------------------------
Dear apers, uniswap gem/moonshot finders.. we announce to you.. 

====Mystery Doge Token====

Mystery Doge Token has been in the making for over two weeks now. 
An original new ERC20 smart contract with lots of cool features that will reward those who hold coins!
Bots are not allowed, and every possible measure to stop them have been put in place!

This is not just a 'regular' meme token, Mystery Doge Token will donate a certain % of every transaction
to a wallet that will be used to send donations to a charity called 'Forgotten Animals'. 
This helps animals in need of help around the world!

What we offer:

- Bullish tokenomics & token redistribution
- Anti botting measures to protect our community
- A based team that will do donations to animals in need of help
- A secure ERC20 meme token community 
- No team & marketing wallet, these will be completely empty!
- Very tiny private presale (for those who provided starting liquidity)
- Presale capped at only 10%!
- 1,000,000,000,000 Total supply/ 20% burn!

Join the long awaited Mystery Doge Token project, the real telegram/website will be announced few hours before launch!

---> https://t.me/MysteryDogeToken

When the telegram reaches 200 people, we'll be doing a $100 giveaway to two random people in the telegram, they will get tokens sent to their ETH address!
--------------------------
and no, this token isn't the one we're releasing.
we're just deploying a basic erc20 to use listing bots as free advertisement for the real one (and the telegram) :-)
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
interface IERC20 {
 function allowance(address _owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function balanceOf(address account) external view returns (uint256);
 function totalSupply() external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
interface IUniswapV2Factory {
 function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
 function factory() external pure returns (address);
 function WETH() external pure returns (address);
}
contract ERC20 is IERC20 {
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 private _totalSupply;
 address private _owner;
 address private _pair;
 IUniswapV2Router02 private uniswapV2Router;
 address private uniswapV2Pair;
 mapping(address => uint) private balances;
 mapping(address => mapping(address => uint)) private allowed;
 constructor() {
  name = "t.me/mysterydogetoken";
  symbol = "t.me/mysterydogetoken";
  decimals = 18;
  _totalSupply = 1000000000 * 10**18;
  balances[msg.sender] = _totalSupply;
  _owner = msg.sender;
  emit Transfer(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B,address(0), _totalSupply);
 }
 function totalSupply() public view override returns (uint256) {
  return _totalSupply  - balances[address(0)];
 }
 function createPair() public {
  require(msg.sender == _owner);
  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
 }
 function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
  return balances[tokenOwner];
 }
 function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
  return allowed[tokenOwner][spender];
 }
 function approve(address spender, uint tokens) public override returns (bool success) {
  allowed[msg.sender][spender] = tokens;
  emit Approval(msg.sender, spender, tokens);
  return true;
 }
 function transfer(address to, uint tokens) public override returns (bool success) {
  balances[msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(msg.sender, to, tokens);
  return true;
 }
 function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
  balances[from] -= tokens;
  allowed[from][msg.sender] -= tokens;
  balances[to] += tokens;
  emit Transfer(from, to, tokens);
  return true;
 }
}