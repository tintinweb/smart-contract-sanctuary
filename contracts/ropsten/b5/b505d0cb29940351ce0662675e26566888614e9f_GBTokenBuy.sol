/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GBTokenBuy {
    
    address usdtContract = 0x770AeC73Be6D022135cE40Dc23059c41cBbA837e;
	address usdcContract = 0x4b79FAe39f2f73ECd3DC1F6EE5C89955c472A082;
	address admin = 0x76f5327800A343F71b204dC6320464391051b164;
	address gbtContract = 0xaed0AF154eBDd5045802D1b0F07ec7dc6F6FCe39;
    
    function usdtBuyGBT(uint256 usdtAmount) public {
		require(usdtAmount > 0, "usd amount cannot be zero");
		
		IERC20 usdtToken = IERC20(usdtContract);
        require(usdtToken.balanceOf(msg.sender) >= usdtAmount, "USDT balance is not enough");
		require(usdtToken.allowance(msg.sender, address(this)) >= usdtAmount, "USDT allowance is not enough");
		
		IERC20 gbtToken = IERC20(gbtContract);
		uint256 tokenAmount = usdtAmount * 10**12 * 100;
		require(gbtToken.balanceOf(address(this)) >= tokenAmount, "GBT balance is not enough");
		
		// transfer after inspection
        usdtToken.transferFrom(msg.sender, admin, usdtAmount);
        gbtToken.transfer(msg.sender, tokenAmount);
    }
    
	function usdcBuyGBT(uint256 usdcAmount) public {
		require(usdcAmount > 0, "usd amount cannot be zero");
		
		IERC20 usdcToken = IERC20(usdcContract);
        require(usdcToken.balanceOf(msg.sender) >= usdcAmount, "USDC balance is not enough");
		require(usdcToken.allowance(msg.sender, address(this)) >= usdcAmount, "USDC allowance is not enough");
		
		IERC20 gbtToken = IERC20(gbtContract);
		uint256 tokenAmount = usdcAmount * 10**12 * 100;
		require(gbtToken.balanceOf(address(this)) >= tokenAmount, "GBT balance is not enough");
		
		// transfer after inspection
        usdcToken.transferFrom(msg.sender, admin, usdcAmount);
        gbtToken.transfer(msg.sender, tokenAmount);
    }
	
	// withdraw Erc20
	function withdrawErc20(address contractAddr) public {
		IERC20 erc20Token = IERC20(contractAddr);
		uint256 erc20Balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(admin, erc20Balance);
	}

}