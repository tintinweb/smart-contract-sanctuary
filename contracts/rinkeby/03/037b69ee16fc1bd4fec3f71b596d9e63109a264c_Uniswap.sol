/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/Uniswap.sol

pragma solidity >=0.8.0;


interface IUniswapV2Router {
    
    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  
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
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}


contract Uniswap {
    
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    event Log(string message, uint val);


  function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _to) external {
     IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
     IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    
    IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to,block.timestamp+1200);
  }
  
  function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB) external {
    IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
    IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

    IERC20(_tokenA).approve(UNISWAP_V2_ROUTER, _amountA);
    IERC20(_tokenB).approve(UNISWAP_V2_ROUTER, _amountB);

    (uint amountA, uint amountB, uint liquidity) =
      IUniswapV2Router(UNISWAP_V2_ROUTER).addLiquidity(
        _tokenA,
        _tokenB,
        _amountA,
        _amountB,
        1,
        1,
        address(this),
        block.timestamp+1200
      );

    emit Log("amountA", amountA);
    emit Log("amountB", amountB);
    emit Log("liquidity", liquidity);
  }

  function removeLiquidity(address _tokenA, address _tokenB) external {
    address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(_tokenA, _tokenB);

    uint liquidity = IERC20(pair).balanceOf(address(this));
    IERC20(pair).approve(UNISWAP_V2_ROUTER, liquidity);

    (uint amountA, uint amountB) =
      IUniswapV2Router(UNISWAP_V2_ROUTER).removeLiquidity(
        _tokenA,
        _tokenB,
        liquidity,
        1,
        1,
        address(this),
        block.timestamp+1200
      );

    emit Log("amountA", amountA);
    emit Log("amountB", amountB);
  }
}