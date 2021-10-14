// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./interface/IUniswapV2Router02.sol";
import "./lib/IERC20.sol";

contract TestSwap {
     address token0;
     address token1;
     address to;
    constructor(address _token0, address _token1,address _to){
       token0=_token0;
        token1=_token1;
        to=_to;
    }
//    address token0 = 0x74b095e48eb8ba11c79b5e400b5f552a32ea82d4;
//    address token1 = 0xadc8cc224b13805418abc245f08f08e9bd1f686e;
    function addLp() external{
        IERC20(token0).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,1000000000000000000);
        IERC20(token1).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,1000000000000000000);
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).addLiquidity(token0,
        token1,
        1000000000000000000,
        1000000000000000000,
        1000000,
        1000000,
        to,
        2632590264
    );
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

interface IUniswapV2Router02  {
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
}

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}