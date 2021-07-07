// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../uniswapv2/interfaces/IUniswapV2Pair.sol";

contract SpotPriceLens {

    function consultUniswapV2LPToken(
        IUniswapV2Pair lpToken,
        uint256 amountIn,
        address[] memory token0Route,
        address[] memory token1Route,
        address chainlinkAddress0,
        address chainlinkAddress1
    ) external view returns (uint256) {
        address token0 = lpToken.token0();
        address token1 = lpToken.token1();

        uint256 token0Amount = (amountIn) * IERC20(token0).balanceOf(address(lpToken));
        uint256 token1Amount = (amountIn) * IERC20(token0).balanceOf(address(lpToken));

        token0Amount = consultTokenToToken(token0, token0Amount, token0Route);
        token0Amount = consultTokenToToken(token1, token1Amount, token1Route);

        (uint256 price0, uint256 decimals0) = getChainlinkPrice(chainlinkAddress0);
        (uint256 price1, uint256 decimals1) = getChainlinkPrice(chainlinkAddress1);

        return
            (((token0Amount * price0) / 10**decimals0) + ((token1Amount * price1) / 10**decimals1)) /
            lpToken.totalSupply();
    }

    /**
     * calculate token price from series of Uniswap pair and chainlink price feed.
     * Once swap route is empty
     * @param token address of token to consult
     * @param amountIn amount in
     * @param pairs swap route to get price
     * @param chainlinkAddress chainlink price feed
     */
    function consultToken(
        address token,
        uint256 amountIn,
        address[] memory pairs,
        address chainlinkAddress
    ) external view returns (uint256) {
        require(pairs.length >= 1 || chainlinkAddress != address(0), "route empty");

        amountIn = consultTokenToToken(token, amountIn, pairs);
        (uint256 price, uint256 decimals) = getChainlinkPrice(chainlinkAddress);
        return (amountIn * price) / (10**decimals);
    }

    // internal function
    function consultTokenToToken(
        address token,
        uint256 amountIn,
        address[] memory pairs
    ) internal view returns (uint256) {
        address tokenIn = token;
        for (uint256 i = 0; i < pairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
            if (tokenIn == pair.token0()) {
                amountIn = getAmountOut(amountIn, reserve0, reserve1);
                tokenIn = pair.token1();
            } else {
                assert(tokenIn == pair.token1());
                amountIn = getAmountOut(amountIn, reserve1, reserve0);
                tokenIn = pair.token0();
            }
        }

        return amountIn;
    }

    // UniswapV2Libarary.getAmountOut
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getChainlinkPrice(address chainlinkAddress) internal view returns (uint256, uint256) {
        AggregatorV3Interface chainlink = AggregatorV3Interface(chainlinkAddress);
        (, int256 price, , , ) = chainlink.latestRoundData();
        uint256 decimals = chainlink.decimals();
        return (uint256(price), decimals);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

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