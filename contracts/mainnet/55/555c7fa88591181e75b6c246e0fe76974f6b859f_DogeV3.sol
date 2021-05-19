/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.7.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.7.0;

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/library/SafeMath96.sol

pragma solidity ^0.7.1;

library SafeMath96 {
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
  function add(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
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
  function sub(uint96 a, uint96 b) internal pure returns (uint96) {
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
  function sub(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    uint96 c = a - b;

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
  function mul(uint96 a, uint96 b) internal pure returns (uint96) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint96 c = a * b;
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
  function div(uint96 a, uint96 b) internal pure returns (uint96) {
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
  function div(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b > 0, errorMessage);
    uint96 c = a / b;
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
  function mod(uint96 a, uint96 b) internal pure returns (uint96) {
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
  function mod(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/library/SafeCast96.sol

pragma solidity ^0.7.1;

library SafeCast96 {
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value < 2**96, "SafeCast: value doesn't fit in 96 bits");
    return uint96(value);
  }
}

// File: @openzeppelin/contracts/utils/SafeCast.sol

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value < 2**128, "SafeCast: value doesn't fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value < 2**64, "SafeCast: value doesn't fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value < 2**32, "SafeCast: value doesn't fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value < 2**16, "SafeCast: value doesn't fit in 16 bits");
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value < 2**8, "SafeCast: value doesn't fit in 8 bits");
    return uint8(value);
  }

  /**
   * @dev Converts a signed int256 into an unsigned uint256.
   *
   * Requirements:
   *
   * - input must be greater than or equal to 0.
   */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

  /**
   * @dev Returns the downcasted int128 from int256, reverting on
   * overflow (when the input is less than smallest int128 or
   * greater than largest int128).
   *
   * Counterpart to Solidity's `int128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   *
   * _Available since v3.1._
   */
  function toInt128(int256 value) internal pure returns (int128) {
    require(
      value >= -2**127 && value < 2**127,
      "SafeCast: value doesn't fit in 128 bits"
    );
    return int128(value);
  }

  /**
   * @dev Returns the downcasted int64 from int256, reverting on
   * overflow (when the input is less than smallest int64 or
   * greater than largest int64).
   *
   * Counterpart to Solidity's `int64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   *
   * _Available since v3.1._
   */
  function toInt64(int256 value) internal pure returns (int64) {
    require(
      value >= -2**63 && value < 2**63,
      "SafeCast: value doesn't fit in 64 bits"
    );
    return int64(value);
  }

  /**
   * @dev Returns the downcasted int32 from int256, reverting on
   * overflow (when the input is less than smallest int32 or
   * greater than largest int32).
   *
   * Counterpart to Solidity's `int32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   *
   * _Available since v3.1._
   */
  function toInt32(int256 value) internal pure returns (int32) {
    require(
      value >= -2**31 && value < 2**31,
      "SafeCast: value doesn't fit in 32 bits"
    );
    return int32(value);
  }

  /**
   * @dev Returns the downcasted int16 from int256, reverting on
   * overflow (when the input is less than smallest int16 or
   * greater than largest int16).
   *
   * Counterpart to Solidity's `int16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   *
   * _Available since v3.1._
   */
  function toInt16(int256 value) internal pure returns (int16) {
    require(
      value >= -2**15 && value < 2**15,
      "SafeCast: value doesn't fit in 16 bits"
    );
    return int16(value);
  }

  /**
   * @dev Returns the downcasted int8 from int256, reverting on
   * overflow (when the input is less than smallest int8 or
   * greater than largest int8).
   *
   * Counterpart to Solidity's `int8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   *
   * _Available since v3.1._
   */
  function toInt8(int256 value) internal pure returns (int8) {
    require(
      value >= -2**7 && value < 2**7,
      "SafeCast: value doesn't fit in 8 bits"
    );
    return int8(value);
  }

  /**
   * @dev Converts an unsigned uint256 into a signed int256.
   *
   * Requirements:
   *
   * - input must be less than or equal to maxInt256.
   */
  function toInt256(uint256 value) internal pure returns (int256) {
    require(value < 2**255, "SafeCast: value doesn't fit in an int256");
    return int256(value);
  }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.7.0;

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
library SafeMath {
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/Interfaces/BaseUniswapV3.sol

pragma solidity ^0.7.1;

library BaseUniswapV3 {
  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }
}

// File: contracts/Interfaces/LiquidityManagementInterface.sol

pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface LiquidityManagementInterface {
  /// @notice Returns the position information associated with a given token ID.
  /// @dev Throws if the token ID is not valid.
  /// @param tokenId The ID of the token that represents the position
  /// @return nonce The nonce for permits
  /// @return operator The address that is approved for spending
  /// @return token0 The address of the token0 for a specific pool
  /// @return token1 The address of the token1 for a specific pool
  /// @return fee The fee associated with the pool
  /// @return tickLower The lower end of the tick range for the position
  /// @return tickUpper The higher end of the tick range for the position
  /// @return liquidity The liquidity of the position
  /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
  /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
  /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
  /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  /// @notice Creates a new position wrapped in a NFT
  /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
  /// a method does not exist, i.e. the pool is assumed to be initialized.
  /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
  /// @return tokenId The ID of the token that represents the minted position
  /// @return liquidity The amount of liquidity for this position
  /// @return amount0 The amount of token0
  /// @return amount1 The amount of token1
  function mint(BaseUniswapV3.MintParams calldata params)
    external
    payable
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  /// @notice Decreases the amount of liquidity in a position and accounts it to the position
  /// @param params tokenId The ID of the token for which liquidity is being decreased,
  /// amount The amount by which liquidity will be decreased,
  /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
  /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
  /// deadline The time by which the transaction must be included to effect the change
  /// @return amount0 The amount of token0 accounted to the position's tokens owed
  /// @return amount1 The amount of token1 accounted to the position's tokens owed
  function decreaseLiquidity(
    BaseUniswapV3.DecreaseLiquidityParams calldata params
  ) external payable returns (uint256 amount0, uint256 amount1);

  function collect(BaseUniswapV3.CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);
}

// File: contracts/Interfaces/CalculatorInterface.sol

pragma solidity ^0.7.1;

interface DogeV3CalculatorInterface {
  function newTicks(
    int24 currentTick,
    int24 startTick,
    int24 endTick,
    int24 denominator,
    uint32 startTimestamp
  )
    external
    view
    returns (
      int24 upperTick,
      int24 lowerTick,
      bool isSafeIncrement
    );

  function setInitialTicks(int24 currentTick, int24 denominator)
    external
    view
    returns (int24 upperTick, int24 lowerTick);

  function getCurrentLiquidity(
    uint160 sqrtRatioX96,
    int24 upperTick,
    int24 lowerTick,
    uint256 amount0,
    uint256 amount1
  ) external pure returns (uint128 fullLiquidity, uint128 limitedLiquidity);

  function ratioE8() external view returns (uint64);

  function getPriceE8FromSQRTPrice(uint160 sqrtPriceX96)
    external
    pure
    returns (uint256 priceE8);

  function getPriceE8FromTick(int24 tick)
    external
    pure
    returns (uint256 priceE8);

  function roundDown(int24 tick, int24 denominator)
    external
    pure
    returns (int24 ans);

  function getTickFromSQRTPrice(uint160 sqrtPriceX96)
    external
    pure
    returns (int24);

  function getDifference() external view returns (int24 tickDifference);
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol

pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
  /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
  /// @return The contract address
  function factory() external view returns (address);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
  /// @return The fee
  function fee() external view returns (uint24);

  /// @notice The pool tick spacing
  /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
  /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The tick spacing
  function tickSpacing() external view returns (int24);

  /// @notice The maximum amount of position liquidity that can use any tick in the range
  /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxLiquidityPerTick() external view returns (uint128);
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol

pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
  /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
  /// when accessed externally.
  /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
  /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
  /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
  /// boundary.
  /// observationIndex The index of the last oracle observation that was written,
  /// observationCardinality The current maximum number of observations stored in the pool,
  /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  /// feeProtocol The protocol fee for both tokens of the pool.
  /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
  /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
  /// unlocked Whether the pool is currently locked to reentrancy
  function slot0()
    external
    view
    returns (
      uint160 sqrtPriceX96,
      int24 tick,
      uint16 observationIndex,
      uint16 observationCardinality,
      uint16 observationCardinalityNext,
      uint8 feeProtocol,
      bool unlocked
    );

  /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function feeGrowthGlobal0X128() external view returns (uint256);

  /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function feeGrowthGlobal1X128() external view returns (uint256);

  /// @notice The amounts of token0 and token1 that are owed to the protocol
  /// @dev Protocol fees will never exceed uint128 max in either token
  function protocolFees()
    external
    view
    returns (uint128 token0, uint128 token1);

  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks
  function liquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
  /// tick upper,
  /// liquidityNet how much liquidity changes when the pool price crosses the tick,
  /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
  /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
  /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
  /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
  /// secondsOutside the seconds spent on the other side of the tick from the current tick,
  /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
  /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
  /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
  /// a specific position.
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside0X128,
      uint256 feeGrowthOutside1X128,
      int56 tickCumulativeOutside,
      uint160 secondsPerLiquidityOutsideX128,
      uint32 secondsOutside,
      bool initialized
    );

  /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
  function tickBitmap(int16 wordPosition) external view returns (uint256);

  /// @notice Returns the information about a position by the position's key
  /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
  /// @return _liquidity The amount of liquidity in the position,
  /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
  /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
  /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
  /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 _liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  /// @notice Returns data about a specific observation index
  /// @param index The element of the observations array to fetch
  /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
  /// ago, rather than at a specific index in the array.
  /// @return blockTimestamp The timestamp of the observation,
  /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
  /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
  /// Returns initialized whether the observation has been initialized and the values are safe to use
  function observations(uint256 index)
    external
    view
    returns (
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulativeX128,
      bool initialized
    );
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolDerivedState.sol

pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
  /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
  /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
  /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
  /// you must call it with secondsAgos = [3600, 0].
  /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
  /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
  /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
  /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
  /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
  /// timestamp
  function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulativeX128s
    );

  /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
  /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
  /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
  /// snapshot is taken and the second snapshot is taken.
  /// @param tickLower The lower tick of the range
  /// @param tickUpper The upper tick of the range
  /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
  /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
  /// @return secondsInside The snapshot of seconds per liquidity for the range
  function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (
      int56 tickCumulativeInside,
      uint160 secondsPerLiquidityInsideX128,
      uint32 secondsInside
    );
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol

pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 sqrtPriceX96) external;

  /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
  /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on tickLower, tickUpper, the amount of liquidity, and the current price.
  /// @param recipient The address for which the liquidity will be created
  /// @param tickLower The lower tick of the position in which to add liquidity
  /// @param tickUpper The upper tick of the position in which to add liquidity
  /// @param amount The amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
  ) external returns (uint256 amount0, uint256 amount1);

  /// @notice Collects tokens owed to a position
  /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
  /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
  /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
  /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
  /// @param recipient The address which should receive the fees collected
  /// @param tickLower The lower tick of the position for which to collect fees
  /// @param tickUpper The upper tick of the position for which to collect fees
  /// @param amount0Requested How much token0 should be withdrawn from the fees owed
  /// @param amount1Requested How much token1 should be withdrawn from the fees owed
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param tickLower The lower tick of the position for which to burn liquidity
  /// @param tickUpper The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
  /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
  /// with 0 amount{0,1} and sending the donation amount(s) from the callback
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;

  /// @notice Increase the maximum number of price and liquidity observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(uint16 observationCardinalityNext)
    external;
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolOwnerActions.sol

pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
  /// @notice Set the denominator of the protocol's % share of the fees
  /// @param feeProtocol0 new protocol fee for token0 of the pool
  /// @param feeProtocol1 new protocol fee for token1 of the pool
  function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

  /// @notice Collect the protocol fee accrued to the pool
  /// @param recipient The address to which collected protocol fees should be sent
  /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
  /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
  /// @return amount0 The protocol fee collected in token0
  /// @return amount1 The protocol fee collected in token1
  function collectProtocol(
    address recipient,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolEvents.sol

pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
  /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
  /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  event Initialize(uint160 sqrtPriceX96, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @param sender The address that minted the liquidity
  /// @param owner The owner of the position and recipient of any minted liquidity
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount The amount of liquidity minted to the position range
  /// @param amount0 How much token0 was required for the minted liquidity
  /// @param amount1 How much token1 was required for the minted liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when fees are collected by the owner of a position
  /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
  /// @param owner The owner of the position for which fees are collected
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount0 The amount of token0 fees collected
  /// @param amount1 The amount of token1 fees collected
  event Collect(
    address indexed owner,
    address recipient,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount0,
    uint128 amount1
  );

  /// @notice Emitted when a position's liquidity is removed
  /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
  /// @param owner The owner of the position for which liquidity is removed
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount The amount of liquidity to remove
  /// @param amount0 The amount of token0 withdrawn
  /// @param amount1 The amount of token1 withdrawn
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted by the pool for any swaps between token0 and token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the output of the swap
  /// @param amount0 The delta of the token0 balance of the pool
  /// @param amount1 The delta of the token1 balance of the pool
  /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param liquidity The liquidity of the pool after the swap
  /// @param tick The log base 1.0001 of price of the pool after the swap
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 amount0,
    int256 amount1,
    uint160 sqrtPriceX96,
    uint128 liquidity,
    int24 tick
  );

  /// @notice Emitted by the pool for any flashes of token0/token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the tokens from flash
  /// @param amount0 The amount of token0 that was flashed
  /// @param amount1 The amount of token1 that was flashed
  /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
  /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 amount0,
    uint256 amount1,
    uint256 paid0,
    uint256 paid1
  );

  /// @notice Emitted by the pool for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(
    uint16 observationCardinalityNextOld,
    uint16 observationCardinalityNextNew
  );

  /// @notice Emitted when the protocol fee is changed by the pool
  /// @param feeProtocol0Old The previous value of the token0 protocol fee
  /// @param feeProtocol1Old The previous value of the token1 protocol fee
  /// @param feeProtocol0New The updated value of the token0 protocol fee
  /// @param feeProtocol1New The updated value of the token1 protocol fee
  event SetFeeProtocol(
    uint8 feeProtocol0Old,
    uint8 feeProtocol1Old,
    uint8 feeProtocol0New,
    uint8 feeProtocol1New
  );

  /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
  /// @param sender The address that collects the protocol fees
  /// @param recipient The address that receives the collected protocol fees
  /// @param amount0 The amount of token0 protocol fees that is withdrawn
  /// @param amount0 The amount of token1 protocol fees that is withdrawn
  event CollectProtocol(
    address indexed sender,
    address indexed recipient,
    uint128 amount0,
    uint128 amount1
  );
}

// File: @uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol

pragma solidity >=0.5.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
  IUniswapV3PoolImmutables,
  IUniswapV3PoolState,
  IUniswapV3PoolDerivedState,
  IUniswapV3PoolActions,
  IUniswapV3PoolOwnerActions,
  IUniswapV3PoolEvents
{

}

// File: contracts/Interfaces/DogeV3Interface.sol

pragma solidity 0.7.1;

interface DogeV3Interface {
  /*
  function getNFTInfo(uint16 stageID)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );
*/

  function currentStage() external view returns (uint16);

  function incrementStage() external;

  function changeCalculator(DogeV3CalculatorInterface newCalc) external;

  function depositFirstStage(uint256 amount, IUniswapV3Pool _swap) external;

  function getSwapInfo()
    external
    view
    returns (int24 tick, address swapAddress);

  function isReversedSwap() external view returns (bool);

  function getStageInfo(uint16 stageID)
    external
    view
    returns (
      bool isReversedSwap,
      int24 upterTick,
      int24 lowerTick,
      uint32 startTimestamp,
      uint128 tokenId,
      uint128 tokenId2
    );

  function isUpgradable() external view returns (bool upgradable);

  function currentStatus()
    external
    view
    returns (
      uint16 currentStageId,
      uint32 startTimestamp,
      uint128 tokenId,
      uint128 tokenId2,
      uint256 upperPrice,
      uint256 lowerPrice,
      uint256 currentPrice
    );
}

// File: contracts/DogeV3.sol

pragma solidity 0.7.1;

contract DogeV3 is Ownable, DogeV3Interface, IERC20 {
  using SafeMath96 for uint96;
  using SafeCast96 for uint256;
  using SafeCast for uint256;
  using SafeMath for uint256;
  enum LEGENDS { VITALIK, UNISWAP_DEPLOYER, NONE }
  struct Balance {
    uint96 balance;
    bool getBonusFromVitalik;
    bool getBonusFromUniswapDeployer;
  }

  struct StageInfo {
    int24 upperTick;
    int24 lowerTick;
    uint32 startTimestamp;
    uint96 tokenId;
    uint96 tokenId2;
  }

  uint96 public constant BonusAmount = 15000 * 10**8;

  uint16 public override currentStage;
  bool isGameContinuing = true;
  mapping(address => Balance) public balance;
  mapping(uint16 => StageInfo) public stage;
  mapping(address => mapping(address => uint96)) private _allowances;
  mapping(LEGENDS => bool) public isAcceptedByLegend;
  mapping(LEGENDS => address) public addresses;

  uint96 constant _totalSupply = 13 * 10**18;
  uint96 public constant donateAmount = 200000000 * 10**8;
  LiquidityManagementInterface public immutable LiquidityManager;
  IERC20 public immutable pair;
  DogeV3CalculatorInterface public calcs;
  IUniswapV3Pool public swap;

  uint8 public constant decimals = 8;
  uint96 public circulatingSupply;
  string public constant name = "DogeV3";
  string public constant symbol = "DOGEV3";

  address public immutable IndiaCovid;
  bool internal isReversed;

  event StageIncrement(
    uint16 newStage,
    int24 nextUpperTick,
    int24 nextLowerTick,
    bool isSeccess
  );
  event LegendAccepted(LEGENDS indexed Legend);
  event GetBonusFromLegends(address indexed recipient, LEGENDS Legend);
  event CheerForIndia(LEGENDS indexed Legend, uint96 amount);

  modifier onlyLegends() {
    require(isLegend(msg.sender), "ERROR: You are not legend");
    _;
  }

  constructor(
    LiquidityManagementInterface _LiquidityManager,
    address vitalik,
    address deployer,
    address indiaCovid,
    IERC20 _pair,
    DogeV3CalculatorInterface _calcs
  ) {
    LiquidityManager = _LiquidityManager;
    pair = _pair;
    addresses[LEGENDS.VITALIK] = vitalik;
    addresses[LEGENDS.UNISWAP_DEPLOYER] = deployer;
    IndiaCovid = indiaCovid;
    balance[address(this)].balance = _totalSupply - 10**12;
    balance[msg.sender].balance = 10**12;
    calcs = _calcs;
    if (address(this) > address(_pair)) {
      isReversed = true;
    }
  }

  function totalSupply() public pure override returns (uint256) {
    return _totalSupply;
  }

  function depositFirstStage(uint256 amount, IUniswapV3Pool _swap)
    external
    override
    onlyOwner
  {
    uint96 beforeBalance = balance[address(this)].balance;
    require(address(swap) == address(0), "Invalid swap Address");
    swap = _swap;
    (, int24 tick, , , , , ) = swap.slot0();
    (int24 upperTick, int24 lowerTick) =
      calcs.setInitialTicks(tick, _swap.tickSpacing());
    require(
      pair.transferFrom(msg.sender, address(this), amount),
      "Cannot transfer WETH"
    );
    IERC20(address(this)).approve(address(LiquidityManager), uint96(-1));
    pair.approve(address(LiquidityManager), uint256(-1));
    (uint256 tokenId, , , ) =
      LiquidityManager.mint(
        _getMintParams(
          upperTick,
          lowerTick,
          balance[address(this)].balance,
          (amount * 9) / 10
        )
      );
    LiquidityManager.mint(
      _getMintParams(
        887220,
        -887220,
        balance[address(this)].balance,
        (amount * 1) / 10
      )
    );
    uint96 afterBalance = balance[address(this)].balance;
    int96 balanceDiff = int96(beforeBalance) - int96(afterBalance);
    if (balanceDiff < 0) {
      circulatingSupply -= uint96(-1 * balanceDiff);
    } else {
      circulatingSupply += uint96(balanceDiff);
    }
    stage[1] = StageInfo(
      upperTick,
      lowerTick,
      block.timestamp.toUint32(),
      uint96(tokenId),
      0
    );
    currentStage = 1;
  }

  function changeCalculator(DogeV3CalculatorInterface newCalc)
    public
    override
    onlyOwner
  {
    calcs = newCalc;
  }

  function acceptByLegend() external onlyLegends {
    LEGENDS legendName = LegendToAddress(msg.sender);
    require(!isAcceptedByLegend[legendName], "Already Accepted");
    isAcceptedByLegend[legendName] = true;
    _transfer(address(this), IndiaCovid, donateAmount);
    emit LegendAccepted(legendName);
    emit CheerForIndia(legendName, donateAmount);
  }

  function getBonusFromLegend() external returns (uint96 bonusAmount) {
    require(balance[msg.sender].balance != 0, "ERROR: You have no DOGEV3");
    Balance memory recipient = balance[msg.sender];
    if (!recipient.getBonusFromVitalik && isAcceptedByLegend[LEGENDS.VITALIK]) {
      bonusAmount += BonusAmount;
      recipient.getBonusFromVitalik = true;
      emit GetBonusFromLegends(msg.sender, LEGENDS.VITALIK);
    }

    if (
      !recipient.getBonusFromUniswapDeployer &&
      isAcceptedByLegend[LEGENDS.UNISWAP_DEPLOYER]
    ) {
      bonusAmount += BonusAmount;
      recipient.getBonusFromUniswapDeployer = true;
      emit GetBonusFromLegends(msg.sender, LEGENDS.UNISWAP_DEPLOYER);
    }

    require(
      _transfer(address(this), msg.sender, bonusAmount),
      "Bonus Transfer failed"
    );
  }

  function checkTokenMove(Balance memory sender, Balance memory recipient)
    public
    pure
    returns (Balance memory)
  {
    if (sender.getBonusFromVitalik) {
      recipient.getBonusFromVitalik = true;
    }
    if (sender.getBonusFromUniswapDeployer) {
      recipient.getBonusFromUniswapDeployer = true;
    }
    return recipient;
  }

  function transfer(address to, uint256 value)
    external
    override
    returns (bool)
  {
    return _transfer(msg.sender, to, value);
  }

  function LegendToAddress(address legendAddress)
    public
    view
    returns (LEGENDS)
  {
    if (legendAddress == addresses[LEGENDS.VITALIK]) {
      return LEGENDS.VITALIK;
    } else if (legendAddress == addresses[LEGENDS.UNISWAP_DEPLOYER]) {
      return LEGENDS.UNISWAP_DEPLOYER;
    }
    return LEGENDS.NONE;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external override returns (bool) {
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
      value.toUint96()
    );
    return _transfer(from, to, value);
  }

  function approve(address to, uint256 value) external override returns (bool) {
    if (value > uint96(-1)) {
      value = uint96(-1);
    }
    _allowances[msg.sender][to] = value.toUint96();
    emit Approval(msg.sender, to, value);
    return true;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return (balance[account].balance);
  }

  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function incrementStage() external override {
    int24 tick;
    {
      (uint160 price, , , , , , ) = swap.slot0();
      tick = calcs.getTickFromSQRTPrice(price);
    }
    StageInfo memory stageInfo = stage[currentStage];
    int24 spacing = swap.tickSpacing();
    (int24 upperTick, int24 lowerTick, bool isSafeIncrement) =
      calcs.newTicks(
        tick,
        stageInfo.upperTick,
        stageInfo.lowerTick,
        spacing,
        stageInfo.startTimestamp
      );
    require(isSafeIncrement, "Invalid Incrementation of the stage");
    {
      (, , , , , , , uint128 liquidity, , , , ) =
        LiquidityManager.positions(stageInfo.tokenId);
      LiquidityManager.decreaseLiquidity(
        BaseUniswapV3.DecreaseLiquidityParams(
          stageInfo.tokenId,
          liquidity,
          0,
          0,
          block.timestamp + 1000000
        )
      );
      LiquidityManager.collect(
        BaseUniswapV3.CollectParams({
          tokenId: stageInfo.tokenId,
          recipient: address(this),
          amount0Max: uint128(-1),
          amount1Max: uint128(-1)
        })
      );
      if (stageInfo.tokenId2 != 0) {
        (, , , , , , , liquidity, , , , ) = LiquidityManager.positions(
          stageInfo.tokenId2
        );
        LiquidityManager.decreaseLiquidity(
          BaseUniswapV3.DecreaseLiquidityParams(
            stageInfo.tokenId2,
            liquidity,
            0,
            0,
            block.timestamp + 1000000
          )
        );
        LiquidityManager.collect(
          BaseUniswapV3.CollectParams({
            tokenId: stageInfo.tokenId2,
            recipient: address(this),
            amount0Max: uint128(-1),
            amount1Max: uint128(-1)
          })
        );
      }
    }
    (uint256 tokenId, uint256 tokenId2) =
      _mint(upperTick, lowerTick, calcs.roundDown(tick, spacing));

    stage[currentStage + 1] = StageInfo(
      upperTick,
      lowerTick,
      block.timestamp.toUint32(),
      tokenId.toUint96(),
      tokenId2.toUint96()
    );

    currentStage += 1;
  }

  function _transfer(
    address from,
    address to,
    uint256 value
  ) internal returns (bool) {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    Balance memory recipient = balance[to];
    recipient.balance = recipient.balance.add(value.toUint96());
    balance[from].balance = balance[from].balance.sub(value.toUint96());
    if (from != address(swap) && from != address(LiquidityManager)) {
      recipient = checkTokenMove(balance[from], recipient);
    }
    balance[to] = recipient;
    emit Transfer(from, to, value);
    return true;
  }

  function isLegend(address _legend) public view returns (bool) {
    return (_legend == addresses[LEGENDS.VITALIK] ||
      _legend == addresses[LEGENDS.UNISWAP_DEPLOYER]);
  }

  function _mint(
    int24 tickUpper,
    int24 tickLower,
    int24 currentTick
  ) internal returns (uint256 tokenId, uint256 tokenId2) {
    uint256 dogeAmount = balance[address(this)].balance;
    uint256 ethAmount = pair.balanceOf(address(this));
    uint256 tokenAmount;
    int24 secondUpperTick;
    int24 secondLowerTick;
    if (!isReversed) {
      tokenAmount = getFirstLiquidity(ethAmount);
      secondUpperTick = currentTick;
      secondLowerTick = tickLower;
    } else {
      tokenAmount = getFirstLiquidity(ethAmount);
      secondUpperTick = tickUpper;
      secondLowerTick = currentTick;
    }

    (tokenId, , , ) = LiquidityManager.mint(
      _getMintParams(tickUpper, tickLower, dogeAmount, tokenAmount)
    );
    if (pair.balanceOf(address(this)) != 0) {
      (tokenId2, , , ) = LiquidityManager.mint(
        _getMintParams(
          secondUpperTick,
          secondLowerTick,
          dogeAmount,
          ethAmount - tokenAmount
        )
      );
    }
  }

  function _getMintParams(
    int24 tickUpper,
    int24 tickLower,
    uint256 dogeBalance,
    uint256 wethbalance
  ) internal view returns (BaseUniswapV3.MintParams memory) {
    if (!isReversed) {
      return
        BaseUniswapV3.MintParams({
          token0: address(this),
          token1: address(pair),
          fee: swap.fee(),
          tickUpper: tickUpper,
          tickLower: tickLower,
          amount0Desired: dogeBalance,
          amount1Desired: wethbalance,
          amount0Min: 0,
          amount1Min: 0,
          recipient: address(this),
          deadline: block.timestamp + 1000000
        });
    }

    return
      BaseUniswapV3.MintParams({
        token0: address(pair),
        token1: address(this),
        fee: swap.fee(),
        tickUpper: tickUpper,
        tickLower: tickLower,
        amount0Desired: wethbalance,
        amount1Desired: dogeBalance,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp + 1000000
      });
  }

  function getStageInfo(uint16 stageID)
    external
    view
    override
    returns (
      bool isReversedSwap,
      int24 upperTick,
      int24 lowerTick,
      uint32 startTimestamp,
      uint128 tokenId,
      uint128 tokenId2
    )
  {
    return (
      isReversed,
      stage[stageID].upperTick,
      stage[stageID].lowerTick,
      stage[stageID].startTimestamp,
      stage[stageID].tokenId,
      stage[stageID].tokenId2
    );
  }

  function currentStatus()
    external
    view
    override
    returns (
      uint16 currentStageId,
      uint32 startTimestamp,
      uint128 tokenId,
      uint128 tokenId2,
      uint256 upperPrice,
      uint256 lowerPrice,
      uint256 currentPrice
    )
  {
    currentStageId = currentStage;
    (uint160 price, , , , , , ) = swap.slot0();
    if (isReversed) {
      lowerPrice = uint256(10**36)
        .div(
        calcs.getPriceE8FromTick(
          stage[currentStageId].upperTick - calcs.getDifference()
        )
      )
        .div(10**10);
      upperPrice = uint256(10**36)
        .div(
        calcs.getPriceE8FromTick(
          stage[currentStageId].lowerTick + calcs.getDifference()
        )
      )
        .div(10**10);
      currentPrice = uint256(10**36)
        .div(calcs.getPriceE8FromSQRTPrice(price))
        .div(10**10);
    } else {
      upperPrice = calcs
        .getPriceE8FromTick(stage[currentStageId].upperTick)
        .div(10**10);
      lowerPrice = calcs
        .getPriceE8FromTick(stage[currentStageId].lowerTick)
        .div(10**10);
      currentPrice = calcs.getPriceE8FromSQRTPrice(price).div(10**10);
    }
    startTimestamp = stage[currentStageId].startTimestamp;
    tokenId = stage[currentStageId].tokenId;
    tokenId2 = stage[currentStageId].tokenId2;
  }

  function getFirstLiquidity(uint256 wethAmount) public view returns (uint256) {
    uint64 ratioE8 = calcs.ratioE8();
    if (ratioE8 >= 10**8) {
      return wethAmount;
    }
    return wethAmount.mul(ratioE8).div(10**8);
  }

  function isReversedSwap() public view override returns (bool) {
    return isReversed;
  }

  function getSwapInfo()
    public
    view
    override
    returns (int24 tick, address swapAddress)
  {
    swapAddress = address(swap);
    (, tick, , , , , ) = swap.slot0();
  }

  function isUpgradable() external view override returns (bool upgradable) {
    (uint160 price, , , , , , ) = swap.slot0();
    int24 tick = calcs.getTickFromSQRTPrice(price);
    StageInfo memory stageInfo = stage[currentStage];
    (, , upgradable) = calcs.newTicks(
      tick,
      stageInfo.upperTick,
      stageInfo.lowerTick,
      swap.tickSpacing(),
      stageInfo.startTimestamp
    );
  }
}