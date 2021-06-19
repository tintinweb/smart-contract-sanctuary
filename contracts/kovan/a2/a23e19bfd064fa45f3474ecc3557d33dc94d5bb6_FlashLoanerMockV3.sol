/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// 
interface ILiquidityPoolV3 {

	function TOKENS_MUL (uint256) external returns (uint256);

	function TOKENS (uint256) external returns (address);

	function borrow (
		uint256[5] calldata amounts_,
		bytes calldata data_
	) external;
}

contract FlashLoanerMockV3 {
	
	uint256 constant public N_TOKENS = 5;
	ILiquidityPoolV3 public liquidityPool;
	IERC20[N_TOKENS] public TOKENS;
	
	constructor(address liquidityPool_) {
		liquidityPool = ILiquidityPoolV3(liquidityPool_);
		for (uint256 i = 0; i < N_TOKENS; i++)
			TOKENS[i] = IERC20(liquidityPool.TOKENS(i));
	}

	function callBack (
		uint256[N_TOKENS] calldata amounts_
	)
		external
	{
		for (uint256 i = 0; i < N_TOKENS; i++)
			if(amounts_[i] != 0) TOKENS[i].transfer(address(liquidityPool), amounts_[i]);
	}

	function flashLoan (
		uint256[N_TOKENS] calldata amounts_,
		uint256[N_TOKENS] calldata payAmounts_
	)
		external
	{
		bytes memory _data = abi.encodeWithSignature("callBack(uint256[5])", payAmounts_);
		liquidityPool.borrow(amounts_, _data);
	}

}