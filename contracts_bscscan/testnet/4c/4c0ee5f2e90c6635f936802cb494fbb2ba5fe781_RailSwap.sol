/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract RailSwap {
    uint256 public totalLiquidity;
    mapping (address => uint256) public liquidity;
    
    IERC20 public token;
    constructor() {
        token = IERC20(0xA832190e277f3b97cea80B9a428fC71E79866222);
    }
    
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity==0,"DEX:init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens));
        return totalLiquidity;
    }
    function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
        return (input_amount * 997 * output_reserve) / (input_reserve * 1000 + input_amount * 997);
    } 
    function ethToToken() public payable returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = price(msg.value, address(this).balance - msg.value, token_reserve);
        require(token.transfer(msg.sender, tokens_bought));
        return tokens_bought;
    }
    function tokenToEth(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_bought = price(tokens, token_reserve, address(this).balance);
        payable(msg.sender).transfer(eth_bought);
        require(token.transferFrom(msg.sender, address(this), tokens));
        return eth_bought;
    }
    function deposit() public payable returns (uint256) {
        uint256 eth_reserve = address(this).balance - msg.value;
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 token_amount = msg.value * token_reserve / eth_reserve + 1;
        uint256 liquidity_minted = msg.value * totalLiquidity / eth_reserve;
        liquidity[msg.sender] = liquidity[msg.sender] + liquidity_minted;
        totalLiquidity = totalLiquidity + liquidity_minted;
        require(token.transferFrom(msg.sender, address(this), token_amount));
        return liquidity_minted;
    }
    function withdraw(uint256 amount) public returns (uint256, uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_amount = amount * address(this).balance / totalLiquidity;
        uint256 token_amount = amount * token_reserve / totalLiquidity;
        liquidity[msg.sender] = liquidity[msg.sender] - eth_amount;
        totalLiquidity = totalLiquidity - eth_amount;
        payable(msg.sender).transfer(eth_amount);
        require(token.transfer(msg.sender, token_amount));
        return (eth_amount, token_amount);
    }    
}