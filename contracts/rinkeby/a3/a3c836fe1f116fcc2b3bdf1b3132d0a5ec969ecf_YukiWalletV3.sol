// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./YERC20.sol";

contract YukiWalletV3 {
    
    address owner;
    
    constructor() {
        owner=msg.sender;
    }
    
    function name() public pure returns (string memory){
        return "Yuki Chain Wallet V3";
    }
    
    function symbol() public pure returns (string memory){
        return "YUKIWALLETV3";
    }
	
	function decimals() public view virtual returns (uint8) {
        return 0;
    }
	
    function totalSupply() public view virtual returns (uint256) {
        return 1;
    }

    
    function balanceOf(address account) public view virtual returns (uint256) {
		if(account==owner)
		{
			return 1;
		}
		else
		{
		 return 0;
		}
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        recipient;
        amount;
        require(1>2, "YukiWallet: This is a private wallet on chain, token is used for identification only.");
        return false;
    }
    
    function generator() public pure returns (string memory){
        return "Remix 0.4.1 with Solidity 0.8.4";
    }
    
    function license() public pure returns (string memory){
        return "MIT License";
    }
    
    function authorIdentifier() public pure returns (string memory){
        return "Yuki Kurosawa (@YukiKurosawaDev)";
    }
    
    function authorTwitter() public pure returns (string memory){
        return "https://twitter.com/YukiKurosawaDev";
    }
    
    function addressOfYuki() public view returns (address){
        return address(owner);
    }
    
    function balanceOfYuki() public view returns (uint256){
        return owner.balance;
    }
    
    function balanceOfYukiToken(address token) public view returns (uint256){
        YERC20 yerc20=YERC20(token);
        return yerc20.balanceOf(owner);
    }
    
    function balanceOfWallet() public view returns (uint256){
        return address(this).balance;
    }
    
    function balanceOfWalletToken(address token) public view returns (uint256){
        YERC20 yerc20=YERC20(token);
        return yerc20.balanceOf(address(this));
    }
    
    receive () external payable{
        
    }
    
    function transferBalanceToYuki(uint256 money) public {
        require(money<=address(this).balance);
        payable(owner).transfer(money);
    }
    
    function transferTokenToYuki(address token,uint256 money) public{
        YERC20 yerc20=YERC20(token);
        require(money<=yerc20.balanceOf(address(this)));
        yerc20.transfer(address(owner),money);
    }
	
	function transferBalanceToUser(address user,uint256 money) public {
        require(money<=address(this).balance);
        payable(user).transfer(money);
    }
    
    function transferTokenToUser(address user,uint256 money) public {
        YERC20 yerc20=YERC20(address(this));
        require(money<=yerc20.balanceOf(address(this)));
        yerc20.transfer(user,money);
    }
    
    function nameOfToken(address token) public view returns(string memory) {
        YERC20 yerc20=YERC20(token);
        return yerc20.name();
    }
    
    function symbolOfToken(address token) public view returns(string memory) {
        YERC20 yerc20=YERC20(token);
        return yerc20.symbol();
    }
    
}