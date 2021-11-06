// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MercurySwapper {
  //constants
  address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address public constant USDC = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
  address public constant UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  IUniswap uniswap = IUniswap(UNISWAP);
  IUSDC usdc = IUSDC(USDC);

  constructor() {}

  function estimateUsdcToWeth(uint256 _eth) external view returns (uint256) { // WETH wei = 18 decimals
    address[] memory path = new address[](2);
    path[0] = USDC;
    path[1] = uniswap.WETH();
    uint256[] memory amounts = uniswap.getAmountsIn(_eth, path);
    return amounts[0];
  }

  function estimateUsdcToWbtc(uint256 _btc) external view returns (uint256) { // WBTC = 8 decimals
    address[] memory path = new address[](2);
    path[0] = USDC;
    path[1] = WBTC;
    uint256[] memory amounts = uniswap.getAmountsIn(_btc, path);
    return amounts[0];
  }

  function fromUsdcToWeth(
    uint _amountIn,
    uint _amountOutMin,
    uint _deadline
  ) external {
    require(usdc.balanceOf(msg.sender) >= _amountIn, "Swap: Dont have enough USDC.");
    require(usdc.allowance(msg.sender, address(this)) >= _amountIn, "Swap: Swap amount needs to be approved.");

    usdc.transferFrom(msg.sender, address(this), _amountIn);
    usdc.approve(address(uniswap), _amountIn);

    address[] memory path = new address[](2);
    path[0] = USDC;
    path[1] = uniswap.WETH();
    uniswap.swapExactTokensForETH(_amountIn, _amountOutMin, path, msg.sender, _deadline);
  }

  function fromUsdcToWbtc(
    uint _amountIn,
    uint _amountOutMin,
    uint _deadline
  ) external {
    require(usdc.balanceOf(msg.sender) >= _amountIn, "Swap: Dont have enough USDC.");
    require(usdc.allowance(msg.sender, address(this)) >= _amountIn, "Swap: Swap amount needs to be approved.");

    usdc.transferFrom(msg.sender, address(this), _amountIn);
    usdc.approve(address(uniswap), _amountIn);

    address[] memory path = new address[](2);
    path[0] = USDC;
    path[1] = WBTC;
    uniswap.swapExactTokensForETH(_amountIn, _amountOutMin, path, msg.sender, _deadline);
  }
}

interface IUniswap {
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}

interface IUSDC is IERC20 {}

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