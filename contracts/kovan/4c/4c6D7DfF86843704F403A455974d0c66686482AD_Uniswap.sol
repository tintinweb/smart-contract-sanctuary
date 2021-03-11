/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


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

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IArbProxy {
	function setUint(uint _id, uint _val) external;
	function getUint(uint _id, uint _val) external returns (uint _num);
}

// 
contract Uniswap {

	// IUniswapV2Router02 constant public usi = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
	IArbProxy public arbProxy;

	constructor(address arbProxy_) 
		public
	{
		arbProxy = IArbProxy(arbProxy_);
	}
	
	
	function getTokenForETH(
		address router_,
		uint256 amountIn_,
		uint256 amountOutMin_,
		address[] calldata path_,
		uint256 getId_,
		uint256 setId_
	)
		external 
	{
		amountIn_ = arbProxy.getUint(getId_, amountIn_);
		require (address(this).balance >= amountIn_, "in amount is greater balance");
		uint[] memory _amounts = IUniswapV2Router02(router_).swapExactETHForTokens{value: amountIn_}
		(
			amountOutMin_, 
			path_, 
			address(this), 
			block.timestamp
		);
		arbProxy.setUint(setId_, _amounts[_amounts.length - 1]);
	}
	
	function getETHForToken(
		address router_,
		uint256 amountIn_,
		uint256 amountOutMin_,
		address[] calldata path_,
		uint256 getId_,
		uint256 setId_
	)
		external 
	{
		IERC20 token = IERC20(path_[0]);
		amountIn_ = arbProxy.getUint(getId_, amountIn_);
		require (token.balanceOf(address(this)) >= amountIn_, "in amount is greater balance");
		token.approve(address(IUniswapV2Router02(router_)), amountIn_);
		uint[] memory _amounts = IUniswapV2Router02(router_).swapExactTokensForETH
		(
			amountIn_,
			amountOutMin_,
			path_,
			address(this),
			block.timestamp
		);
		arbProxy.setUint(setId_, _amounts[_amounts.length - 1]);
	}
	
	function getTokenForToken(
		address router_,
		uint256 amountIn_,
		uint256 amountOutMin_,
		address[] calldata path_,
		uint256 getId_,
		uint256 setId_
	)
		external 
		returns (uint256)
	{
		IERC20 token = IERC20(path_[0]);
		amountIn_ = arbProxy.getUint(getId_, amountIn_);
		require (token.balanceOf(address(this)) >= amountIn_, "in amount is greater balance");
		token.approve(address(IUniswapV2Router02(router_)), amountIn_);
		uint[] memory _amounts = IUniswapV2Router02(router_).swapExactTokensForTokens(
			amountIn_,
			amountOutMin_, 
			path_,
			address(this),
			block.timestamp
		);
		arbProxy.setUint(setId_, _amounts[_amounts.length - 1]);
	}

}