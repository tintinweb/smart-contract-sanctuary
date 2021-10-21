// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TickMath} from '../libraries/TickMath.sol';
import {SafeCast} from '../libraries/SafeCast.sol';
import {PathHelper} from './libraries/PathHelper.sol';
import {PoolAddress} from './libraries/PoolAddress.sol';

import {IPool} from '../interfaces/IPool.sol';
import {IFactory} from '../interfaces/IFactory.sol';
import {IRouter} from '../interfaces/periphery/IRouter.sol';
import {IWETH} from '../interfaces/IWETH.sol';

import {DeadlineValidation} from './base/DeadlineValidation.sol';
import {Multicall} from './base/Multicall.sol';
import {RouterTokenHelperWithFee} from './base/RouterTokenHelperWithFee.sol';

/// @title KyberDMM V2 Swap Router
contract Router is IRouter, RouterTokenHelperWithFee, Multicall, DeadlineValidation {
  using PathHelper for bytes;
  using SafeCast for uint256;

  /// @dev Use as the placeholder value for amountInCached
  uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

  /// @dev Use to cache the computed amount in for an exact output swap.
  uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

  constructor(address _factory, address _WETH) RouterTokenHelperWithFee(_factory, _WETH) {}

  struct SwapCallbackData {
    bytes path;
    address source;
  }

  function swapCallback(
    int256 deltaQty0,
    int256 deltaQty1,
    bytes calldata data
  ) external override {
    require(deltaQty0 > 0 || deltaQty1 > 0, 'Router: invalid delta qties');
    SwapCallbackData memory swapData = abi.decode(data, (SwapCallbackData));
    (address tokenIn, address tokenOut, uint16 fee) = swapData.path.decodeFirstPool();
    require(
      msg.sender == address(_getPool(tokenIn, tokenOut, fee)),
      'Router: invalid callback sender'
    );

    (bool isExactInput, uint256 amountToTransfer) = deltaQty0 > 0
      ? (tokenIn < tokenOut, uint256(deltaQty0))
      : (tokenOut < tokenIn, uint256(deltaQty1));
    if (isExactInput) {
      // transfer token from source to the pool which is the msg.sender
      // wrap eth -> weth and transfer if needed
      _transferTokens(tokenIn, swapData.source, msg.sender, amountToTransfer);
    } else {
      if (swapData.path.hasMultiplePools()) {
        swapData.path = swapData.path.skipToken();
        _swapExactOutputInternal(amountToTransfer, msg.sender, 0, swapData);
      } else {
        amountInCached = amountToTransfer;
        // transfer tokenOut to the pool (it's the original tokenIn)
        // wrap eth -> weth and transfer if user uses passes eth with the swap
        _transferTokens(tokenOut, swapData.source, msg.sender, amountToTransfer);
      }
    }
  }

  function swapExactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    override
    onlyNotExpired(params.deadline)
    returns (uint256 amountOut)
  {
    amountOut = _swapExactInputInternal(
      params.amountIn,
      params.recipient,
      params.limitSqrtP,
      SwapCallbackData({
        path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
        source: msg.sender
      })
    );
    require(amountOut >= params.minAmountOut, 'Router: insufficient amountOut');
  }

  function swapExactInput(ExactInputParams memory params)
    external
    payable
    override
    onlyNotExpired(params.deadline)
    returns (uint256 amountOut)
  {
    address source = msg.sender; // msg.sender is the source of tokenIn for the first swap

    while (true) {
      bool hasMultiplePools = params.path.hasMultiplePools();

      params.amountIn = _swapExactInputInternal(
        params.amountIn,
        hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
        0,
        SwapCallbackData({path: params.path.getFirstPool(), source: source})
      );

      if (hasMultiplePools) {
        source = address(this);
        params.path = params.path.skipToken();
      } else {
        amountOut = params.amountIn;
        break;
      }
    }

    require(amountOut >= params.minAmountOut, 'Router: insufficient amountOut');
  }

  function swapExactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    override
    onlyNotExpired(params.deadline)
    returns (uint256 amountIn)
  {
    amountIn = _swapExactOutputInternal(
      params.amountOut,
      params.recipient,
      params.limitSqrtP,
      SwapCallbackData({
        path: abi.encodePacked(params.tokenOut, params.fee, params.tokenIn),
        source: msg.sender
      })
    );
    require(amountIn <= params.maxAmountIn, 'Router: amountIn is too high');
    // has to be reset even though we don't use it in the single hop case
    amountInCached = DEFAULT_AMOUNT_IN_CACHED;
  }

  function swapExactOutput(ExactOutputParams calldata params)
    external
    payable
    override
    onlyNotExpired(params.deadline)
    returns (uint256 amountIn)
  {
    _swapExactOutputInternal(
      params.amountOut,
      params.recipient,
      0,
      SwapCallbackData({path: params.path, source: msg.sender})
    );

    amountIn = amountInCached;
    require(amountIn <= params.maxAmountIn, 'Router: amountIn is too high');
    amountInCached = DEFAULT_AMOUNT_IN_CACHED;
  }

  /// @dev Performs a single exact input swap
  function _swapExactInputInternal(
    uint256 amountIn,
    address recipient,
    uint160 limitSqrtP,
    SwapCallbackData memory data
  ) private returns (uint256 amountOut) {
    // allow swapping to the router address with address 0
    if (recipient == address(0)) recipient = address(this);

    (address tokenIn, address tokenOut, uint16 fee) = data.path.decodeFirstPool();

    bool isFromToken0 = tokenIn < tokenOut;

    (int256 amount0, int256 amount1) = _getPool(tokenIn, tokenOut, fee).swap(
      recipient,
      amountIn.toInt256(),
      isFromToken0,
      limitSqrtP == 0
        ? (isFromToken0 ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
        : limitSqrtP,
      abi.encode(data)
    );
    return uint256(-(isFromToken0 ? amount1 : amount0));
  }

  /// @dev Perform a swap exact amount out using callback
  function _swapExactOutputInternal(
    uint256 amountOut,
    address recipient,
    uint160 limitSqrtP,
    SwapCallbackData memory data
  ) private returns (uint256 amountIn) {
    // consider address 0 as the router address
    if (recipient == address(0)) recipient = address(this);

    (address tokenOut, address tokenIn, uint16 fee) = data.path.decodeFirstPool();

    bool isFromToken0 = tokenOut < tokenIn;

    (int256 amount0Delta, int256 amount1Delta) = _getPool(tokenIn, tokenOut, fee).swap(
      recipient,
      -amountOut.toInt256(),
      isFromToken0,
      limitSqrtP == 0
        ? (isFromToken0 ? TickMath.MAX_SQRT_RATIO - 1 : TickMath.MIN_SQRT_RATIO + 1)
        : limitSqrtP,
      abi.encode(data)
    );

    uint256 receivedAmountOut;
    (amountIn, receivedAmountOut) = isFromToken0
      ? (uint256(amount1Delta), uint256(-amount0Delta))
      : (uint256(amount0Delta), uint256(-amount1Delta));

    // if no price limit has been specified, receivedAmountOut should be equals to amountOut
    assert(limitSqrtP != 0 || receivedAmountOut == amountOut);
  }

  /// @dev Returns the pool address for the requested token pair swap fee
  ///   Because the function calculates it instead of fetching the address from the factory,
  ///   the returned pool address may not be in existence yet
  function _getPool(
    address tokenA,
    address tokenB,
    uint16 fee
  ) private view returns (IPool) {
    return IPool(PoolAddress.computeAddress(factory, tokenA, tokenB, fee, poolInitHash));
  }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return sqrtP A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtP) {
    unchecked {
      uint256 absTick = uint256(tick < 0 ? -int256(tick) : int256(tick));
      require(absTick <= uint256(int256(MAX_TICK)), 'T');

      // do bitwise comparison, if i-th bit is turned on,
      // multiply ratio by hardcoded values of sqrt(1.0001^-(2^i)) * 2^128
      // where 0 <= i <= 19
      uint256 ratio = (absTick & 0x1 != 0)
        ? 0xfffcb933bd6fad37aa2d162d1a594001
        : 0x100000000000000000000000000000000;
      if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
      if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
      if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
      if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
      if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
      if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
      if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
      if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
      if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
      if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
      if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
      if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
      if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
      if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
      if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
      if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
      if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
      if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
      if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

      // take reciprocal for positive tick values
      if (tick > 0) ratio = type(uint256).max / ratio;

      // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
      // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
      // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
      sqrtP = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtP < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtP The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 sqrtP) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(sqrtP >= MIN_SQRT_RATIO && sqrtP < MAX_SQRT_RATIO, 'R');
    uint256 ratio = uint256(sqrtP) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    unchecked {
      assembly {
        let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(5, gt(r, 0xFFFFFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(4, gt(r, 0xFFFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(3, gt(r, 0xFF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(2, gt(r, 0xF))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := shl(1, gt(r, 0x3))
        msb := or(msb, f)
        r := shr(f, r)
      }
      assembly {
        let f := gt(r, 0x1)
        msb := or(msb, f)
      }

      if (msb >= 128) r = ratio >> (msb - 127);
      else r = ratio << (127 - msb);

      int256 log_2 = (int256(msb) - 128) << 64;

      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(63, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(62, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(61, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(60, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(59, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(58, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(57, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(56, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(55, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(54, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(53, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(52, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(51, f))
        r := shr(f, r)
      }
      assembly {
        r := shr(127, mul(r, r))
        let f := shr(128, r)
        log_2 := or(log_2, shl(50, f))
      }

      int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

      int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
      int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

      tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtP ? tickHi : tickLow;
    }
  }

  function getMaxNumberTicks(int24 _tickDistance) internal pure returns (uint24 numTicks) {
    return uint24(TickMath.MAX_TICK / _tickDistance) * 2;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to uint32, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint32
  function toUint32(uint256 y) internal pure returns (uint32 z) {
    require((z = uint32(y)) == y);
  }

  /// @notice Cast a uint128 to a int128, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt128(uint128 y) internal pure returns (int128 z) {
    require(y < 2**127);
    z = int128(y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y the uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int128 to a uint128 and reverses the sign.
  /// @param y The int128 to be casted
  /// @return z = -y, now type uint128
  function revToUint128(int128 y) internal pure returns (uint128 z) {
    unchecked {
      return type(uint128).max - uint128(y) + 1;
    }
  }

  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  /// @notice Cast a uint256 to a int256 and reverses the sign, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z = -y, now type int256
  function revToInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = -int256(y);
  }

  /// @notice Cast a int256 to a uint256 and reverses the sign.
  /// @param y The int256 to be casted
  /// @return z = -y, now type uint256
  function revToUint256(int256 y) internal pure returns (uint256 z) {
    unchecked {
      return type(uint256).max - uint256(y) + 1;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library PathHelper {
  using BytesLib for bytes;

  /// @dev The length of the bytes encoded address
  uint256 private constant ADDR_SIZE = 20;
  /// @dev The length of the bytes encoded fee
  uint256 private constant FEE_SIZE = 2;

  /// @dev The offset of a single token address and pool fee
  uint256 private constant TOKEN_AND_POOL_OFFSET = ADDR_SIZE + FEE_SIZE;
  /// @dev The offset of an encoded pool data
  uint256 private constant POOL_DATA_OFFSET = TOKEN_AND_POOL_OFFSET + ADDR_SIZE;
  /// @dev The minimum length of an encoding that contains 2 or more pools
  uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POOL_DATA_OFFSET + TOKEN_AND_POOL_OFFSET;

  /// @notice Returns true iff the path contains two or more pools
  /// @param path The encoded swap path
  /// @return True if path contains two or more pools, otherwise false
  function hasMultiplePools(bytes memory path) internal pure returns (bool) {
    return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
  }

  /// @notice Returns the number of pools in the path
  /// @param path The encoded swap path
  /// @return The number of pools in the path
  function numPools(bytes memory path) internal pure returns (uint256) {
    // Ignore the first token address. From then on every fee and token offset indicates a pool.
    return ((path.length - ADDR_SIZE) / TOKEN_AND_POOL_OFFSET);
  }

  /// @notice Decodes the first pool in path
  /// @param path The bytes encoded swap path
  /// @return tokenA The first token of the given pool
  /// @return tokenB The second token of the given pool
  /// @return fee The fee level of the pool
  function decodeFirstPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint16 fee
    )
  {
    tokenA = path.toAddress(0);
    fee = path.toUint16(ADDR_SIZE);
    tokenB = path.toAddress(TOKEN_AND_POOL_OFFSET);
  }

  /// @notice Gets the segment corresponding to the first pool in the path
  /// @param path The bytes encoded swap path
  /// @return The segment containing all data necessary to target the first pool in the path
  function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(0, POOL_DATA_OFFSET);
  }

  /// @notice Skips a token + fee element from the buffer and returns the remainder
  /// @param path The swap path
  /// @return The remaining token + fee elements in the path
  function skipToken(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(TOKEN_AND_POOL_OFFSET, path.length - TOKEN_AND_POOL_OFFSET);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Provides a function for deriving a pool address from the factory, tokens, and swap fee
library PoolAddress {
  /// @notice Deterministically computes the pool address from the given data
  /// @param factory the factory address
  /// @param token0 One of the tokens constituting the token pair, regardless of order
  /// @param token1 The other token constituting the token pair, regardless of order
  /// @param swapFee Fee to be collected upon every swap in the pool, in basis points
  /// @param poolInitHash The keccak256 hash of the Pool creation code
  /// @return pool the pool address
  function computeAddress(
    address factory,
    address token0,
    address token1,
    uint16 swapFee,
    bytes32 poolInitHash
  ) internal pure returns (address pool) {
    (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
    bytes32 hashed = keccak256(
      abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encode(token0, token1, swapFee)),
        poolInitHash
      )
    );
    pool = address(uint160(uint256(hashed)));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IPoolActions} from './pool/IPoolActions.sol';
import {IPoolEvents} from './pool/IPoolEvents.sol';
import {IPoolStorage} from './pool/IPoolStorage.sol';

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title KyberDMM v2 factory
/// @notice Deploys KyberDMM v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint16 indexed swapFeeBps,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint16 indexed swapFeeBps, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint16 governmentFeeBps);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeBps Swap fee, in basis points.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint16 swapFeeBps) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in basis points
  function feeConfiguration() external view returns (address _feeTo, uint16 _governmentFeeBps);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address token0,
      address token1,
      uint16 swapFeeBps,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeBps Desired swap fee for the pool, in basis points
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeBps The fee amount to enable, in basis points
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint16 swapFeeBps, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import '../callback/ISwapCallback.sol';

/// @notice Functions for swapping tokens via KyberDMM v2
/// - Support swap with exact input or exact output
/// - Support swap with a price limit
/// - Support swap within a single pool and between multiple pools
interface IRouter is ISwapCallback {
  /// @dev Params for swapping exact input amount
  /// @param tokenIn the token to swap
  /// @param tokenOut the token to receive
  /// @param fee the pool's fee
  /// @param recipient address to receive tokenOut
  /// @param deadline time that the transaction will be expired
  /// @param amountIn the tokenIn amount to swap
  /// @param amountOutMinimum the minimum receive amount
  /// @param limitSqrtP the price limit, if reached, stop swapping
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint16 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 minAmountOut;
    uint160 limitSqrtP;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function swapExactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  /// @dev Params for swapping exact input using multiple pools
  /// @param path the encoded path to swap from tokenIn to tokenOut
  ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token0, fee01, token1, fee12, token2]
  /// @param recipient address to receive tokenOut
  /// @param deadline time that the transaction will be expired
  /// @param amountIn the tokenIn amount to swap
  /// @param amountOutMinimum the minimum receive amount
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 minAmountOut;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function swapExactInput(ExactInputParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  /// @dev Params for swapping exact output amount
  /// @param tokenIn the token to swap
  /// @param tokenOut the token to receive
  /// @param fee the pool's fee
  /// @param recipient address to receive tokenOut
  /// @param deadline time that the transaction will be expired
  /// @param amountOut the tokenOut amount of tokenOut
  /// @param amountInMaximum the minimum input amount
  /// @param limitSqrtP the price limit, if reached, stop swapping
  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint16 fee;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 maxAmountIn;
    uint160 limitSqrtP;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function swapExactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    returns (uint256 amountIn);

  /// @dev Params for swapping exact output using multiple pools
  /// @param path the encoded path to swap from tokenIn to tokenOut
  ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token2, fee12, token1, fee01, token0]
  /// @param recipient address to receive tokenOut
  /// @param deadline time that the transaction will be expired
  /// @param amountOut the tokenOut amount of tokenOut
  /// @param amountInMaximum the minimum input amount
  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 maxAmountIn;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function swapExactOutput(ExactOutputParams calldata params)
    external
    payable
    returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH
interface IWETH is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Validate if the transaction is still valid
abstract contract DeadlineValidation {
  modifier onlyNotExpired(uint256 deadline) {
    require(_blockTimestamp() <= deadline, 'Expired');
    _;
  }

  /// @dev Override this function to test easier with block timestamp
  function _blockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import {IMulticall} from '../../interfaces/periphery/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data)
    external
    payable
    override
    returns (bytes[] memory results)
  {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);

      if (!success) {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) revert();
        assembly {
          result := add(result, 0x04)
        }
        revert(abi.decode(result, (string)));
      }
      results[i] = result;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TokenHelper} from '../libraries/TokenHelper.sol';

import {IRouterTokenHelperWithFee} from '../../interfaces/periphery/IRouterTokenHelperWithFee.sol';
import {IWETH} from '../../interfaces/IWETH.sol';

import {RouterTokenHelper} from './RouterTokenHelper.sol';

abstract contract RouterTokenHelperWithFee is RouterTokenHelper, IRouterTokenHelperWithFee {
  uint256 constant FEE_BPS = 10000;

  constructor(address _factory, address _WETH) RouterTokenHelper(_factory, _WETH) {}

  function unwrapWethWithFee(
    uint256 minAmount,
    address recipient,
    uint256 feeBps,
    address feeRecipient
  ) public payable override {
    require(feeBps > 0 && feeBps <= 100, 'High fee');

    uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
    require(balanceWETH >= minAmount, 'Insufficient WETH');

    if (balanceWETH > 0) {
      IWETH(WETH).withdraw(balanceWETH);
      uint256 feeAmount = (balanceWETH * feeBps) / FEE_BPS;
      if (feeAmount > 0) TokenHelper.transferEth(feeRecipient, feeAmount);
      TokenHelper.transferEth(recipient, balanceWETH - feeAmount);
    }
  }

  function transferAllTokensWithFee(
    address token,
    uint256 minAmount,
    address recipient,
    uint256 feeBps,
    address feeRecipient
  ) public payable override {
    require(feeBps > 0 && feeBps <= 100, 'High fee');

    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= minAmount, 'Insufficient token');

    if (balanceToken > 0) {
      uint256 feeAmount = (balanceToken * feeBps) / FEE_BPS;
      if (feeAmount > 0)
        TokenHelper.transferToken(IERC20(token), feeAmount, address(this), feeRecipient);
      TokenHelper.transferToken(IERC20(token), balanceToken - feeAmount, address(this), recipient);
    }
  }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, 'slice_overflow');
    require(_bytes.length >= _start + _length, 'slice_outOfBounds');

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        // update free-memory pointer
        // allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        // zero out the 32 bytes slice we are about to return
        // we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }
    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, 'toUint16_outOfBounds');
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }

    return tempUint;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IPoolActions {
  /// @notice Adds initial liquidity and sets initial price for the pool
  /// @dev Function calls IMintCallback#mintCallback to receive
  /// required tokens from the caller. Hence, the caller is required to
  /// implement the mint callback as well
  /// @param initialSqrtP the initial sqrt price of the pool
  /// @param data Data (if any) to be passed through to the callback
  /// @param qty0 token0 quantity sent to and locked permanently in the pool
  /// @param qty1 token1 quantity sent to and locked permanently in the pool
  function unlockPool(uint160 initialSqrtP, bytes calldata data)
    external
    returns (uint256 qty0, uint256 qty1);

  /// @notice Adds liquidity for the specified recipient/tickLower/tickUpper position
  /// @dev Any token0 or token1 owed for the liquidity provision have to be paid for when
  /// the IMintCallback#mintCallback is called to this method's caller
  /// The quantity of token0/token1 to be sent depends on
  /// tickLower, tickUpper, the amount of liquidity, and the current price of the pool.
  /// Also sends reinvestment tokens (fees) to the recipient for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param recipient Address for which the added liquidity is credited to
  /// @param tickLower Recipient position's lower tick
  /// @param tickUpper Recipient position's upper tick
  /// @param ticksPrevious The nearest tick that is initialized and <= the lower & upper ticks
  /// @param qty Liquidity quantity to mint
  /// @param data Data (if any) to be passed through to the callback
  /// @return qty0 token0 quantity sent to the pool in exchange for the minted liquidity
  /// @return qty1 token1 quantity sent to the pool in exchange for the minted liquidity
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    int24[2] calldata ticksPrevious,
    uint128 qty,
    bytes calldata data
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Remove liquidity from the caller
  /// Also sends reinvestment tokens (fees) to the caller for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param tickLower Position's lower tick for which to burn liquidity
  /// @param tickUpper Position's upper tick for which to burn liquidity
  /// @param qty Liquidity quantity to burn
  /// @return qty0 token0 quantity sent to the caller
  /// @return qty1 token1 quantity sent to the caller
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 qty
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Burns reinvestment tokens in exchange to receive the fees collected in token0 and token1
  /// @param qty Reinvestment token quantity to burn
  /// @return qty0 token0 quantity sent to the caller for burnt reinvestment tokens
  /// @return qty1 token1 quantity sent to the caller for burnt reinvestment tokens
  function burnRTokens(uint256 qty, bool isLogicalBurn)
    external
    returns (uint256 qty0, uint256 qty1);

  /// @notice Swap token0 -> token1, or vice versa
  /// @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
  /// @dev swaps will execute up to limitSqrtP or swapQty is fully used
  /// @param recipient The address to receive the swap output
  /// @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
  /// @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
  /// @param limitSqrtP the limit of sqrt price after swapping
  /// could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
  /// @param data Any data to be passed through to the callback
  /// @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
  /// @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external returns (int256 qty0, int256 qty1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IFlashCallback#flashCallback
  /// @dev Fees collected are distributed to all rToken holders
  /// since no rTokens are minted from it
  /// @param recipient The address which will receive the token0 and token1 quantities
  /// @param qty0 token0 quantity to be loaned to the recipient
  /// @param qty1 token1 quantity to be loaned to the recipient
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 qty0,
    uint256 qty1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IPoolEvents {
  /// @notice Emitted only once per pool when #initialize is first called
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param sqrtP The initial price of the pool
  /// @param tick The initial tick of the pool
  event Initialize(uint160 sqrtP, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param sender address that minted the liquidity
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity minted to the position range
  /// @param qty0 token0 quantity needed to mint the liquidity
  /// @param qty1 token1 quantity needed to mint the liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when a position's liquidity is removed
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity removed
  /// @param qty0 token0 quantity withdrawn from removal of liquidity
  /// @param qty1 token1 quantity withdrawn from removal of liquidity
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when reinvestment tokens are burnt
  /// @param owner address which burnt the reinvestment tokens
  /// @param qty reinvestment token quantity burnt
  /// @param qty0 token0 quantity sent to owner for burning reinvestment tokens
  /// @param qty1 token1 quantity sent to owner for burning reinvestment tokens
  event BurnRTokens(address indexed owner, uint256 qty, uint256 qty0, uint256 qty1);

  /// @notice Emitted for swaps by the pool between token0 and token1
  /// @param sender Address that initiated the swap call, and that received the callback
  /// @param recipient Address that received the swap output
  /// @param deltaQty0 Change in pool's token0 balance
  /// @param deltaQty1 Change in pool's token1 balance
  /// @param sqrtP Pool's sqrt price after the swap
  /// @param liquidity Pool's liquidity after the swap
  /// @param currentTick Log base 1.0001 of pool's price after the swap
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 deltaQty0,
    int256 deltaQty1,
    uint160 sqrtP,
    uint128 liquidity,
    int24 currentTick
  );

  /// @notice Emitted by the pool for any flash loans of token0/token1
  /// @param sender The address that initiated the flash loan, and that received the callback
  /// @param recipient The address that received the flash loan quantities
  /// @param qty0 token0 quantity loaned to the recipient
  /// @param qty1 token1 quantity loaned to the recipient
  /// @param paid0 token0 quantity paid for the flash, which can exceed qty0 + fee
  /// @param paid1 token1 quantity paid for the flash, which can exceed qty0 + fee
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 qty0,
    uint256 qty1,
    uint256 paid0,
    uint256 paid1
  );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from '../IFactory.sol';

interface IPoolStorage {
  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeBps() external view returns (uint16);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title Callback for IPool#swap
/// @notice Any contract that calls IPool#swap must implement this interface
interface ISwapCallback {
  /// @notice Called to `msg.sender` after swap execution of IPool#swap.
  /// @dev This function's implementation must pay tokens owed to the pool for the swap.
  /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
  /// deltaQty0 and deltaQty1 can both be 0 if no tokens were swapped.
  /// @param deltaQty0 The token0 quantity that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send deltaQty0 of token0 to the pool.
  /// @param deltaQty1 The token1 quantity that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send deltaQty1 of token1 to the pool.
  /// @param data Data passed through by the caller via the IPool#swap call
  function swapCallback(
    int256 deltaQty0,
    int256 deltaQty1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/// @title Helper to transfer token or ETH
library TokenHelper {
  using SafeERC20 for IERC20;

  /// @dev Transfer token from the sender to the receiver
  /// @notice If the sender is the contract address, should just call transfer token to receiver
  ///   otherwise, tansfer tokens from the sender to the receiver
  function transferToken(
    IERC20 token,
    uint256 amount,
    address sender,
    address receiver
  ) internal {
    if (sender == address(this)) {
      token.safeTransfer(receiver, amount);
    } else {
      token.safeTransferFrom(sender, receiver, amount);
    }
  }

  /// @dev Transfer ETh to the receiver
  function transferEth(address receiver, uint256 amount) internal {
    if (receiver == address(this)) return;
    (bool success, ) = payable(receiver).call{value: amount}('');
    require(success, 'transfer eth failed');
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import './IRouterTokenHelper.sol';

interface IRouterTokenHelperWithFee is IRouterTokenHelper {
  /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH, with a percentage between
  /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
  /// @dev The minAmount parameter prevents malicious contracts from stealing WETH from users.
  function unwrapWethWithFee(
    uint256 minAmount,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) external payable;

  /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
  /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
  /// @dev The minAmount parameter prevents malicious contracts from stealing the token from users
  function transferAllTokensWithFee(
    address token,
    uint256 minAmount,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TokenHelper} from '../libraries/TokenHelper.sol';

import {IRouterTokenHelper} from '../../interfaces/periphery/IRouterTokenHelper.sol';
import {IWETH} from '../../interfaces/IWETH.sol';

import {ImmutablePeripheryStorage} from './ImmutablePeripheryStorage.sol';

abstract contract RouterTokenHelper is IRouterTokenHelper, ImmutablePeripheryStorage {
  constructor(address _factory, address _WETH) ImmutablePeripheryStorage(_factory, _WETH) {}

  receive() external payable {
    require(msg.sender == WETH, 'Not WETH');
  }

  /// @dev Unwrap all ETH balance and send to the recipient
  function unwrapWeth(uint256 minAmount, address recipient) external payable override {
    uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
    require(balanceWETH >= minAmount, 'Insufficient WETH');

    if (balanceWETH > 0) {
      IWETH(WETH).withdraw(balanceWETH);
      TokenHelper.transferEth(recipient, balanceWETH);
    }
  }

  /// @dev Transfer all tokens from the contract to the recipient
  function transferAllTokens(
    address token,
    uint256 minAmount,
    address recipient
  ) public payable virtual override {
    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= minAmount, 'Insufficient token');

    if (balanceToken > 0) {
      TokenHelper.transferToken(IERC20(token), balanceToken, address(this), recipient);
    }
  }

  /// @dev Send all ETH balance of this contract to the sender
  function refundEth() external payable override {
    if (address(this).balance > 0) TokenHelper.transferEth(msg.sender, address(this).balance);
  }

  /// @dev Transfer tokenAmount amount of token from the sender to the recipient
  function _transferTokens(
    address token,
    address sender,
    address recipient,
    uint256 tokenAmount
  ) internal {
    if (token == WETH && address(this).balance >= tokenAmount) {
      IWETH(WETH).deposit{value: tokenAmount}();
      IWETH(WETH).transfer(recipient, tokenAmount);
    } else {
      TokenHelper.transferToken(IERC20(token), tokenAmount, sender, recipient);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IRouterTokenHelper {
  /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
  /// @dev The minAmount parameter prevents malicious contracts from stealing WETH from users.
  /// @param minAmount The minimum amount of WETH to unwrap
  /// @param recipient The address receiving ETH
  function unwrapWeth(uint256 minAmount, address recipient) external payable;

  /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
  /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
  /// that use ether for the input amount
  function refundEth() external payable;

  /// @notice Transfers the full amount of a token held by this contract to recipient
  /// @dev The minAmount parameter prevents malicious contracts from stealing the token from users
  /// @param token The contract address of the token which will be transferred to `recipient`
  /// @param minAmount The minimum amount of token required for a transfer
  /// @param recipient The destination address of the token
  function transferAllTokens(
    address token,
    uint256 minAmount,
    address recipient
  ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import {IFactory} from '../../interfaces/IFactory.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract ImmutablePeripheryStorage {
  address public immutable factory;
  address public immutable WETH;
  bytes32 internal immutable poolInitHash;

  constructor(address _factory, address _WETH) {
    factory = _factory;
    WETH = _WETH;
    poolInitHash = IFactory(_factory).poolInitHash();
  }
}