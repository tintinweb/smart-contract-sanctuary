// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ISwapRouter.sol";
import "../libraries/Constants.sol";

contract UniswapV2SwapRouter is ISwapRouter, Constants {

    IUniswapV2Router02 public uniswapRouter;

    constructor(IUniswapV2Router02 _uniswapRouter) {
        uniswapRouter = _uniswapRouter;
    }

    function weth() external view override returns(address) {
        return uniswapRouter.WETH();
    }

    function swapExactTokensForTokens(
        address _token,
        uint _supplyTokenAmount,
        uint _minOutput,
        address _outputToken
    ) external override {
        require(_token != _outputToken, "Output token must not be given in input");

        IERC20(_token).transferFrom(msg.sender, address(this), _supplyTokenAmount);
        if (IERC20(_token).allowance(address(this), address(uniswapRouter)) < MAX_INT) {
            IERC20(_token).approve(address(uniswapRouter), MAX_INT);
        }

        uniswapRouter.swapExactTokensForTokens(
            _supplyTokenAmount,
            _minOutput,
            _path(_token, _outputToken),
            address(msg.sender),
            block.timestamp + 1000
        );
    }

    function compound(
        address _token,
        uint _amount
    ) external override {

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (IERC20(_token).allowance(address(this), address(uniswapRouter)) < MAX_INT) {
            IERC20(_token).approve(address(uniswapRouter), MAX_INT);
        }
        if (IERC20(uniswapRouter.WETH()).allowance(address(this), address(uniswapRouter)) < MAX_INT) {
            IERC20(uniswapRouter.WETH()).approve(address(uniswapRouter), MAX_INT);
        }

        uniswapRouter.swapExactTokensForTokens(
            _amount / 2,
            0,
            _path(_token, uniswapRouter.WETH()),
            address(this),
            block.timestamp + 1000
        );

        uniswapRouter.addLiquidity(
            _token,
            uniswapRouter.WETH(),
            IERC20(_token).balanceOf(address(this)),
            IERC20(uniswapRouter.WETH()).balanceOf(address(this)),
            0,
            0,
            address(msg.sender),
            block.timestamp + 1000
        );

        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
        IERC20(uniswapRouter.WETH()).transfer(msg.sender, IERC20(uniswapRouter.WETH()).balanceOf(address(this)));

    }

    function _path(address _token, address _outputToken) internal view returns (address[] memory) {

        if (_token == uniswapRouter.WETH() || _outputToken == uniswapRouter.WETH()) {

            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = _outputToken;

            return path;

        } else {

            address[] memory path = new address[](3);
            path[0] = _token;
            path[1] = uniswapRouter.WETH();
            path[2] = _outputToken;

            return path;
        }
    }

}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISwapRouter {

    function weth() external returns(address);

    function swapExactTokensForTokens(
        address _token,
        uint _supplyTokenAmount,
        uint _minOutput,
        address _outputToken
    ) external;

    function compound(
        address _token,
        uint _amount
    ) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Constants {

    uint MAX_INT = 2 ** 256 - 1;

}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

