/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


// 
interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

interface ILiquidityPool {
	function TOKENS (uint256) external returns (address);
	function TOKENS_MUL (uint256) external returns (uint256);
	function balance (uint256 token_) external returns (uint256);
	function calcBorrowFee (uint256 amount_) external returns (uint256);
	function borrow (
		uint256[5] calldata amounts_,
		bytes calldata data_
	) external;
}

contract SimpleFlashLoaner {
	
	address public owner;
	uint256 constant public N_TOKENS = 5;
	ILiquidityPool public liquidityPool;
	IERC20[N_TOKENS] public TOKENS;

	modifier onlyOwner() {
		require(msg.sender == owner, "caller is not the owner");
		_;
	}
	
	constructor(address liquidityPool_) {
		owner = address(0x2CadAa8DEAeb13Ee93064CCde2D6360DAB42122a);
		liquidityPool = ILiquidityPool(liquidityPool_);
		for (uint256 i = 0; i < N_TOKENS; i++)
			TOKENS[i] = IERC20(liquidityPool.TOKENS(i));
	}

	function transferOwnership(address address_) 
		external 
		onlyOwner 
	{
		require(address_ != address(0), "new owner is the zero address");
		owner = address_;
	}
	
    // Call this func initilize flashloan on []amounts of each token
    function flashLoan(
        uint256[N_TOKENS] calldata amounts_,
        uint256[N_TOKENS] calldata payAmounts_
    )
    	onlyOwner
    	external
    {
        bytes memory _data = abi.encodeWithSignature("callBack(uint256[5])", payAmounts_);
        liquidityPool.borrow(amounts_, _data);
    }

    // Callback implementing custom logic (there will be arbitrage/trades/market-making/liquidations logic). 
    function callBack(
        uint256[N_TOKENS] calldata payAmounts_
    )
    	// onlyOwner
    	external
    {
    	require(msg.sender == address(liquidityPool), "caller is not the LiquidityPool");

        // Do your logic HERE

        // return flash loan 
        for (uint256 i = 0; i < N_TOKENS; i++) {
            if (payAmounts_[i] != 0) {
                TOKENS[i].transfer(address(liquidityPool), payAmounts_[i]);
            }
        }
    }

    function withdrawERC20(address tokenAddress_)
		external
		onlyOwner
	{
		IERC20 _token = IERC20(tokenAddress_);
		uint256 _balance = _token.balanceOf(address(this));
		if (_balance > 0) {
			_token.transfer(msg.sender, _balance);
		}
	}

}