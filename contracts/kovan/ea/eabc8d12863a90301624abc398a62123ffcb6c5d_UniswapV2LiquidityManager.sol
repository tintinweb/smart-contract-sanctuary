/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/integrations/uniswap/liquidity-managers/UniswapV2LiquidityManager.sol
pragma solidity =0.6.7 >=0.6.0 <0.8.0 >=0.6.7 <0.7.0;

////// src/integrations/uniswap/uni-v2/interfaces/IUniswapV2Pair.sol
/* pragma solidity 0.6.7; */

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

////// src/integrations/uniswap/uni-v2/interfaces/IUniswapV2Router01.sol
/* pragma solidity 0.6.7; */

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

////// src/integrations/uniswap/uni-v2/interfaces/IUniswapV2Router02.sol
/* pragma solidity 0.6.7; */

/* import './IUniswapV2Router01.sol'; */

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

////// src/interfaces/ERC20Like.sol
/* pragma solidity ^0.6.7; */

abstract contract ERC20Like {
    function approve(address guy, uint wad) virtual public returns (bool);
    function transfer(address dst, uint wad) virtual public returns (bool);
    function balanceOf(address) virtual external view returns (uint256);
    function transferFrom(address src, address dst, uint wad)
        virtual
        public
        returns (bool);
}

////// src/interfaces/UniswapLiquidityManagerLike.sol
/* pragma solidity 0.6.7; */

abstract contract UniswapLiquidityManagerLike {
    function getToken0FromLiquidity(uint256) virtual public view returns (uint256);
    function getToken1FromLiquidity(uint256) virtual public view returns (uint256);

    function getLiquidityFromToken0(uint256) virtual public view returns (uint256);
    function getLiquidityFromToken1(uint256) virtual public view returns (uint256);

    function removeLiquidity(
      uint256 liquidity,
      uint128 amount0Min,
      uint128 amount1Min,
      address to
    ) public virtual returns (uint256, uint256);
}

////// src/math/SafeMath.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
contract SafeMath_2 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

////// src/integrations/uniswap/liquidity-managers/UniswapV2LiquidityManager.sol
/* pragma solidity 0.6.7; */

/* import "../uni-v2/interfaces/IUniswapV2Pair.sol"; */
/* import "../uni-v2/interfaces/IUniswapV2Router02.sol"; */

/* import "../../../math/SafeMath.sol"; */

/* import "../../../interfaces/ERC20Like.sol"; */
/* import "../../../interfaces/UniswapLiquidityManagerLike.sol"; */

contract UniswapV2LiquidityManager is UniswapLiquidityManagerLike, SafeMath_2 {
    // The Uniswap v2 pair handled by this contract
    IUniswapV2Pair     public pair;
    // The official Uniswap v2 router V2
    IUniswapV2Router02 public router;

    constructor(address pair_, address router_) public {
        require(pair_ != address(0), "UniswapV2LiquidityManager/null-pair");
        require(router_ != address(0), "UniswapV2LiquidityManager/null-router");
        pair   = IUniswapV2Pair(pair_);
        router = IUniswapV2Router02(router_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Public Getters ---
    /*
    * @notice Return the amount of token0 tokens that someone would get back by burning a specific amount of LP tokens
    * @param liquidityAmount The amount of LP tokens to burn
    * @return The amount of token0 tokens that someone would get back
    */
    function getToken0FromLiquidity(uint256 liquidityAmount) public override view returns (uint256) {
        if (liquidityAmount == 0) return 0;

        (uint256 totalSupply, uint256 cumulativeLPBalance) = getSupplyAndCumulativeLiquidity(liquidityAmount);
        if (either(liquidityAmount == 0, cumulativeLPBalance > totalSupply)) return 0;

        return mul(cumulativeLPBalance, ERC20Like(pair.token0()).balanceOf(address(pair))) / totalSupply;
    }
    /*
    * @notice Return the amount of token1 tokens that someone would get back by burning a specific amount of LP tokens
    * @param liquidityAmount The amount of LP tokens to burn
    * @return The amount of token1 tokens that someone would get back
    */
    function getToken1FromLiquidity(uint256 liquidityAmount) public override view returns (uint256) {
        if (liquidityAmount == 0) return 0;

        (uint256 totalSupply, uint256 cumulativeLPBalance) = getSupplyAndCumulativeLiquidity(liquidityAmount);
        if (either(liquidityAmount == 0, cumulativeLPBalance > totalSupply)) return 0;

        return mul(cumulativeLPBalance, ERC20Like(pair.token1()).balanceOf(address(pair))) / totalSupply;
    }
    /*
    * @notice Return the amount of LP tokens needed to withdraw a specific amount of token0 tokens
    * @param token0Amount The amount of token0 tokens from which to determine the amount of LP tokens
    * @return The amount of LP tokens needed to withdraw a specific amount of token0 tokens
    */
    function getLiquidityFromToken0(uint256 token0Amount) public override view returns (uint256) {
        if (either(token0Amount == 0, ERC20Like(address(pair.token0())).balanceOf(address(pair)) < token0Amount)) return 0;
        return div(mul(token0Amount, pair.totalSupply()), ERC20Like(pair.token0()).balanceOf(address(pair)));
    }
    /*
    * @notice Return the amount of LP tokens needed to withdraw a specific amount of token1 tokens
    * @param token1Amount The amount of token1 tokens from which to determine the amount of LP tokens
    * @return The amount of LP tokens needed to withdraw a specific amount of token1 tokens
    */
    function getLiquidityFromToken1(uint256 token1Amount) public override view returns (uint256) {
        if (either(token1Amount == 0, ERC20Like(address(pair.token1())).balanceOf(address(pair)) < token1Amount)) return 0;
        return div(mul(token1Amount, pair.totalSupply()), ERC20Like(pair.token1()).balanceOf(address(pair)));
    }

    // --- Internal Getters ---
    /*
    * @notice Internal view function that returns the total supply of LP tokens in the 'pair' as well as the LP
    *         token balance of the pair contract itself if it were to have liquidityAmount extra tokens
    * @param liquidityAmount The amount of LP tokens that would be burned
    * @return The total supply of LP tokens in the 'pair' as well as the LP token balance
    *         of the pair contract itself if it were to have liquidityAmount extra tokens
    */
    function getSupplyAndCumulativeLiquidity(uint256 liquidityAmount) internal view returns (uint256, uint256) {
        return (pair.totalSupply(), add(pair.balanceOf(address(pair)), liquidityAmount));
    }

    // --- Liquidity Removal Logic ---
    /*
    * @notice Remove liquidity from the Uniswap pool
    * @param liquidity The amount of LP tokens to burn
    * @param amount0Min The min amount of token0 requested
    * @param amount1Min The min amount of token1 requested
    * @param to The address that receives token0 and token1 tokens after liquidity is removed
    * @return The amounts of token0 and token1 tokens returned
    */
    function removeLiquidity(
        uint256 liquidity,
        uint128 amount0Min,
        uint128 amount1Min,
        address to
    ) public override returns (uint256 amount0, uint256 amount1) {
        require(to != address(0), "UniswapV2LiquidityManager/null-dst");
        pair.transferFrom(msg.sender, address(this), liquidity);
        pair.approve(address(router), liquidity);
        (amount0, amount1) = router.removeLiquidity(
          pair.token0(),
          pair.token1(),
          liquidity,
          uint(amount0Min),
          uint(amount1Min),
          to,
          now
        );
    }
}