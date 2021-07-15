/**
 *Submitted for verification at polygonscan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.2;


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

interface ILiquidityPool {
	function PCT_PRECISION () external view returns (uint256);
	function TOKENS (uint256) external view returns (address);
	function TOKENS_MUL (uint256) external view returns (uint256);
	function balance (uint256 token_) external view returns (uint256);
	function borrowFee() external view returns(uint256);
	function calcBorrowFee (uint256 amount_) external view returns (uint256);
	function borrow (
		uint256[5] calldata amounts_,
		bytes calldata data_
	) external;
}

// 
contract FlashLoanerMockV3 {
	
	address public owner;
	uint256 constant public N_TOKENS = 5;
	ILiquidityPool public liquidityPool;
	IERC20[N_TOKENS] public TOKENS;

	modifier onlyOwner() {
		require(msg.sender == owner, "caller is not the owner");
		_;
	}
	
	constructor(address liquidityPool_) {
		owner = msg.sender;
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

	function kill (address payable beneficiary)
		onlyOwner 
		external
	{
		selfdestruct(beneficiary);
	}

	receive() external payable {}
}