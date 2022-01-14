/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT License
// BUSD Reward ~ https://t.me/shibaprincessv2official
// Fair Launch 01/14/2022 15:00 CST

// File: contracts/IUniswapV2Factory.sol



pragma solidity ^0.8.6;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}
// File: contracts/IUniswapRouter.sol



pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}
// File: contracts/IUniswapV2Pair.sol



pragma solidity ^0.8.6;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}
// File: contracts/IterableMapping.sol


pragma solidity ^0.8.6;

library IterableMapping {
  // Iterable mapping from address to uint;
  struct Map {
    address[] keys;
    mapping(address => uint256) values;
    mapping(address => uint256) indexOf;
    mapping(address => bool) inserted;
  }

  function get(Map storage map, address key) public view returns (uint256) {
    return map.values[key];
  }

  function getIndexOfKey(Map storage map, address key)
    public
    view
    returns (int256)
  {
    if (!map.inserted[key]) {
      return -1;
    }
    return int256(map.indexOf[key]);
  }

  function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (address)
  {
    return map.keys[index];
  }

  function size(Map storage map) public view returns (uint256) {
    return map.keys.length;
  }

  function set(
    Map storage map,
    address key,
    uint256 val
  ) public {
    if (map.inserted[key]) {
      map.values[key] = val;
    } else {
      map.inserted[key] = true;
      map.values[key] = val;
      map.indexOf[key] = map.keys.length;
      map.keys.push(key);
    }
  }

  function remove(Map storage map, address key) public {
    if (!map.inserted[key]) {
      return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint256 index = map.indexOf[key];
    uint256 lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }
}
// File: contracts/SafeMathInt.sol



/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.6;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  /**
   * @dev Multiplies two int256 variables and fails on overflow.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;

    // Detect overflow when multiplying MIN_INT256 with -1
    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  /**
   * @dev Division of two int256 variables and fails on overflow.
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing MIN_INT256 by -1
    require(b != -1 || a != MIN_INT256);

    // Solidity already throws when dividing by 0.
    return a / b;
  }

  /**
   * @dev Subtracts two int256 variables and fails on overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  /**
   * @dev Adds two int256 variables and fails on overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  /**
   * @dev Converts to absolute value, and fails on overflow.
   */
  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256);
    return a < 0 ? -a : a;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}
// File: contracts/SafeMathUint.sol



pragma solidity ^0.8.6;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
// File: contracts/SafeMath.sol



pragma solidity ^0.8.6;

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
// File: contracts/Context.sol



pragma solidity ^0.8.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}
// File: contracts/Ownable.sol



pragma solidity ^0.8.6;


contract Ownable is Context {
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
// File: contracts/IERC20.sol



pragma solidity ^0.8.6;

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
// File: contracts/IERC20Metadata.sol



pragma solidity ^0.8.6;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}
// File: contracts/ERC20.sol



pragma solidity ^0.8.6;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      "ERC20: transfer amount exceeds balance"
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      "ERC20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}
// File: contracts/DividendPayingTokenOptionalInterface.sol



pragma solidity ^0.8.6;

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner)
    external
    view
    returns (uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns (uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner)
    external
    view
    returns (uint256);
}
// File: contracts/DividendPayingTokenInterface.sol



pragma solidity ^0.8.6;

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns (uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(address indexed from, uint256 weiAmount);

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(address indexed to, uint256 weiAmount);

  event RewardTokenUpdated(
    address indexed newAddress,
    address indexed oldAddress
  );
}
// File: contracts/DividendPayingToken.sol



pragma solidity ^0.8.6;






/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is
  ERC20,
  DividendPayingTokenInterface,
  DividendPayingTokenOptionalInterface
{
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 internal constant magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;

  address public rewardToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // mainnet BUSD

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
  {}

  receive() external payable {}

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public payable override {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user)
    internal
    returns (uint256)
  {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(
        _withdrawableDividend
      );
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(rewardToken).transfer(user, _withdrawableDividend);
      if (!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(
          _withdrawableDividend
        );
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns (uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner)
    public
    view
    override
    returns (uint256)
  {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner)
    public
    view
    override
    returns (uint256)
  {
    return withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner)
    public
    view
    override
    returns (uint256)
  {
    return
      magnifiedDividendPerShare
        .mul(balanceOf(_owner))
        .toInt256Safe()
        .add(magnifiedDividendCorrections[_owner])
        .toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(
    address from,
    address to,
    uint256 value
  ) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(
      _magCorrection
    );
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
      _magCorrection
    );
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
      account
    ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
      account
    ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}
// File: contracts/SIPTokenDividendTracker.sol


// Dividend Tracker contract

pragma solidity ^0.8.6;




contract SIPTokenDividendTracker is DividendPayingToken, Ownable {
  using SafeMath for uint256;
  using SafeMathInt for int256;
  using IterableMapping for IterableMapping.Map;

  IterableMapping.Map private tokenHoldersMap;
  uint256 public lastProcessedIndex;

  mapping(address => bool) public excludedFromDividends;

  mapping(address => uint256) public lastClaimTimes;

  uint256 public claimWait;
  uint256 public immutable minimumTokenBalanceForDividends;

  event ExcludeFromDividends(address indexed account);
  event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

  event Claim(address indexed account, uint256 amount, bool indexed automatic);

  constructor()
    DividendPayingToken("SIPToken_Dividend", "SIPToken_Dividend")
  {
    claimWait = 3600;
    minimumTokenBalanceForDividends = 500000 * (10**18); //must hold 0,0005% OF total supply tokens
  }

  function _transfer(
    address,
    address,
    uint256
  ) internal pure override {
    require(false, "RewardToken_Dividend_Tracker: No transfers allowed");
  }

  function withdrawDividend() public pure override {
    require(
      false,
      "RewardToken_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Token contract."
    );
  }

  function isExcludedFromDividends(address account)
    external
    view
    returns (bool)
  {
    return excludedFromDividends[account];
  }

  function excludeFromDividends(address account) external onlyOwner {
    excludedFromDividends[account] = true;

    _setBalance(account, 0);
    tokenHoldersMap.remove(account);

    emit ExcludeFromDividends(account);
  }

  function updateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(
      newClaimWait >= 3600 && newClaimWait <= 86400,
      "RewardToken_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
    );
    require(
      newClaimWait != claimWait,
      "RewardToken_Dividend_Tracker: Cannot update claimWait to same value"
    );
    emit ClaimWaitUpdated(newClaimWait, claimWait);
    claimWait = newClaimWait;
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return lastProcessedIndex;
  }

  function getNumberOfTokenHolders() external view returns (uint256) {
    return tokenHoldersMap.keys.length;
  }

  function getAccount(address _account)
    public
    view
    returns (
      address account,
      int256 index,
      int256 iterationsUntilProcessed,
      uint256 withdrawableDividends,
      uint256 withdrawnDividend,
      uint256 totalDividends,
      uint256 lastClaimTime,
      uint256 nextClaimTime,
      uint256 secondsUntilAutoClaimAvailable
    )
  {
    account = _account;

    index = tokenHoldersMap.getIndexOfKey(account);

    iterationsUntilProcessed = -1;

    if (index >= 0) {
      if (uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
      } else {
        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
          lastProcessedIndex
          ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
          : 0;

        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    withdrawnDividend = withdrawnDividendOf(account);
    totalDividends = accumulativeDividendOf(account);

    lastClaimTime = lastClaimTimes[account];

    nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
      ? nextClaimTime.sub(block.timestamp)
      : 0;
  }

  function getAccountAtIndex(uint256 index)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    if (index >= tokenHoldersMap.size()) {
      return (
        0x0000000000000000000000000000000000000000,
        -1,
        -1,
        0,
        0,
        0,
        0,
        0,
        0
      );
    }

    address account = tokenHoldersMap.getKeyAtIndex(index);

    return getAccount(account);
  }

  function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) {
      return false;
    }

    return block.timestamp.sub(lastClaimTime) >= claimWait;
  }

  function setBalance(address payable account, uint256 newBalance)
    external
    onlyOwner
  {
    if (excludedFromDividends[account]) {
      return;
    }

    if (newBalance >= minimumTokenBalanceForDividends) {
      _setBalance(account, newBalance);
      tokenHoldersMap.set(account, newBalance);
    } else {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    }

    processAccount(account, true);
  }

  function process(uint256 gas)
    public
    onlyOwner
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    if (numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }

    uint256 _lastProcessedIndex = lastProcessedIndex;

    uint256 gasUsed = 0;

    uint256 gasLeft = gasleft();

    uint256 iterations = 0;
    uint256 claims = 0;

    while (gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex++;

      if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }

      address account = tokenHoldersMap.keys[_lastProcessedIndex];

      if (canAutoClaim(lastClaimTimes[account])) {
        if (processAccount(payable(account), true)) {
          claims++;
        }
      }

      iterations++;

      uint256 newGasLeft = gasleft();

      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
      }

      gasLeft = newGasLeft;
    }

    lastProcessedIndex = _lastProcessedIndex;

    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(address payable account, bool automatic)
    public
    onlyOwner
    returns (bool)
  {
    uint256 amount = _withdrawDividendOfUser(account);
    if (amount > 0) {
      lastClaimTimes[account] = block.timestamp;
      emit Claim(account, amount, automatic);
      return true;
    }

    return false;
  }

  function distributeRewardTokenDividends(uint256 amount) external onlyOwner {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function getTotalDividendsDistributed() external view returns (uint256) {
    return totalDividendsDistributed;
  }
}
// File: contracts/SIP.sol









pragma solidity ^0.8.6;

contract SIP is ERC20, Ownable {
  using SafeMath for uint256;
  // Events Declarations

  event EnableTrading(uint256 indexed blockNumber);

  event UpdateDividendTracker(
    address indexed newAddress,
    address indexed oldAddress
  );
  event UpdateUniswapV2Router(
    address indexed newAddress,
    address indexed oldAddress
  );
  event UpdateMarketingWallet(
    address indexed newWallet,
    address indexed oldWallet
  );
  event UpdateBuybackWallet(
    address indexed newWallet,
    address indexed oldWallet
  );
  event UpdatePresaleWallet(
    address indexed newWallet,
    address indexed oldWallet
  );
  event UpdateGasForProcessing(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );

  event UpdateMarketingFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateBuybackFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateLiquidityFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateRewardsFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateSellFee(uint256 indexed newValue, uint256 indexed oldValue);

  event UpdateMaxBuyTransactionAmount(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );
  event UpdateMaxSellTransactionAmount(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );
  event UpdateSwapTokensAtAmount(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );
  event UpdateSwapAndLiquify(bool enabled);

  event WhitelistAccount(address indexed account, bool isWhitelisted);
  event ExcludeFromFees(address indexed account, bool isExcluded);
  event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  event SendDividends(uint256 tokensSwapped, uint256 amount);
  event SendRaffle(uint256 tokensSwapped, uint256 amount);

  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  event TransferETHToMarketingWallet(address indexed wallet, uint256 amount);
  event TransferETHToDevWallet(address indexed wallet, uint256 amount);
  event TransferTokensToMarketingWallet(address indexed wallet, uint256 amount);
  event TransferTokensToDevWallet(address indexed wallet, uint256 amount);
  event TransferETHToBuybackWallet(address indexed wallet, uint256 amount);
  event TransferTokensToBuybackWallet(address indexed wallet, uint256 amount);
  event ExcludeAccountFromDividends(address indexed account);
  event ExcludeFromMaxWallet(address indexed account, bool isExcluded);

  //
  IUniswapV2Router02 public uniswapV2Router;
  address public immutable uniswapV2Pair;

  bool private swapping;
  bool public swapAndLiquifyEnabled = true;

  SIPTokenDividendTracker public dividendTracker;

  uint256 public immutable MIN_BUY_TRANSACTION_AMOUNT = 0 * (10**18); // 0 of supply
  uint256 public immutable MAX_BUY_TRANSACTION_AMOUNT = 2000000 * (10**18); // 2% of supply
  uint256 public immutable MIN_SELL_TRANSACTION_AMOUNT = 0 * (10**18); // 0 of total supply
  uint256 public immutable MAX_SELL_TRANSACTION_AMOUNT =
    2000000 * (10**18); // 2% of total supply
  uint256 public immutable MIN_SWAP_TOKENS_AT_AMOUNT = 200 * (10**18);
  uint256 public immutable MAX_SWAP_TOKENS_AT_AMOUNT = 2000000 * (10**18); // 2% of total supply

  uint256 public maxBuyTransactionAmount = 2000000 * (10**18); // 2% of supply
  uint256 public maxSellTransactionAmount = 2000000 * (10**18); // 2% of supply
  uint256 public swapTokensAtAmount = 2000000 * (10**18); // 2% of supply
  uint256 public maxWallet = 2000000 * (10**18); // 2% of supply

  uint256 public immutable MAX_MARKETING_FEE = 15;
  uint256 public immutable MAX_DEV_FEE = 15;
  uint256 public immutable MAX_BUYBACK_FEE = 15;
  uint256 public immutable MAX_REWARDS_FEE = 15;
  uint256 public immutable MAX_LIQUIDITY_FEE = 5;
  uint256 public immutable MAX_TOTAL_FEES = 20;
  uint256 public immutable MAX_SELL_FEE = 30;

  uint256 public marketingFee = 90; // for trapping
  uint256 public devFee = 10;
  uint256 public buyBackFee = 0;
  uint256 public rewardsFee = 0;
  uint256 public liquidityFee = 0;
  uint256 public sellFee = 0; // fees are increased for sells

  // it can only be enabled, not disabled. Used so that contract can be deployed / liq added
  // without bots interfering.
  // SIPGuard is active on default
  // bool internal SIPGuardOffline = true;

  address payable public marketingWallet =
    payable(0xA1Ed6Ad3B452d964Df1ae6C711efAab9802c8336);
  address payable public devWallet =
    payable(0x4eC8Aa7f7A7a37C958aAaDD0cB940d95de0Df563);
  address payable public buyBackWallet =
    payable(0xA1Ed6Ad3B452d964Df1ae6C711efAab9802c8336);

  // BUSD Token
  address public rewardToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // mainnet BUSD

  // use by default 300,000 gas to process auto-claiming dividends
  uint256 public gasForProcessing = 300000;

  // Absolute max gas amount for processing dividends
  uint256 public immutable MAX_GAS_FOR_PROCESSING = 5000000;

  // exclude from fees
  mapping(address => bool) private _isExcludedFromFees;

  // exclude from max wallet
  mapping(address => bool) private _isExcludedFromMaxWallet;

  // Can add LP before trading is enabled
  mapping(address => bool) public isWhitelisted;

  uint256 public totalFeesCollected;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public automatedMarketMakerPairs;

  constructor() ERC20("SIPv2", "ShibaInuPrincessv2") {
    dividendTracker = new SIPTokenDividendTracker();
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x10ED43C718714eb63d5aA57B78B54704E256024E // mainnet
      //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 // testnet
    );

    // Create a uniswap pair for this new token
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    // exclude from receiving dividends. We purposely don't exclude
    // the marketing wallet from dividends since we're going to use
    // those dividends for things like giveaways and marketing. These
    // dividends are more useful than tokens in some cases since selling
    // them doesnt impact token price.
    dividendTracker.excludeFromDividends(address(dividendTracker));
    dividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(address(_uniswapV2Router));
    dividendTracker.excludeFromDividends(address(0xdEaD));
    dividendTracker.excludeFromDividends(address(0));
    dividendTracker.excludeFromDividends(owner());

    // exclude from paying fees or having max transaction amount
    excludeFromFees(address(this), true);
    excludeFromFees(marketingWallet, true);
    excludeFromFees(devWallet, true);
    excludeFromFees(owner(), true);
    excludeFromFees(address(0xdEaD), true);
    excludeFromFees(address(0), true);

    //exclude from max wallet
    excludeFromMaxWallet(address(dividendTracker), true);
    excludeFromMaxWallet(address(this), true);
    excludeFromMaxWallet(marketingWallet, true);
    excludeFromMaxWallet(devWallet, true);
    excludeFromMaxWallet(owner(), true);
    excludeFromMaxWallet(address(0xdEaD), true);
    excludeFromMaxWallet(address(0), true);
    excludeFromMaxWallet(address(uniswapV2Router), true);

    // Whitelist accounts so they can transfer tokens before trading is enabled
    whitelistAccount(address(this), true);
    whitelistAccount(owner(), true);
    whitelistAccount(devWallet, true);
    whitelistAccount(address(uniswapV2Router), true);

    /*
    _mint is an internal function in ERC20.sol that is only called here,
    and CANNOT be called ever again
    */
    _mint(owner(), 100000000 * (10**18)); // 100,000,000
  }

  receive() external payable {}

  function updateSwapAndLiquify(bool enabled) external onlyOwner {
    swapAndLiquifyEnabled = enabled;
    emit UpdateSwapAndLiquify(enabled);
  }

  // function is SIPGuardEnabled() public view returns (bool) {
  //   return SIPGuardOffline;
  // }

  function whitelistAccount(address account, bool whitelisted)
    public
    onlyOwner
  {
    isWhitelisted[account] = whitelisted;
  }

  function registerAsTeam(address account) external onlyOwner {
    excludeFromFees(account, true);
    excludeFromMaxWallet(account, true);
    whitelistAccount(account, true);
  }

  function isWhitelistedAccount(address account) public view returns (bool) {
    return isWhitelisted[account];
  }

  // function shutdownSIPGuard() external onlyOwner {
  //   require(!SIPGuardOffline, "SIP guard is already offline");
  //   SIPGuardOffline = true;
  // }

  function getTotalFees() public view returns (uint256) {
    return
      marketingFee.add(liquidityFee).add(rewardsFee).add(devFee).add(
        buyBackFee
      );
  }

  function updateMarketingWallet(address payable newAddress)
    external
    onlyOwner
  {
    require(marketingWallet != newAddress, "new address required");
    address oldWallet = marketingWallet;
    marketingWallet = newAddress;
    excludeFromFees(newAddress, true);
    emit UpdateMarketingWallet(marketingWallet, oldWallet);
  }

  function updateDividendTracker(address newAddress) public onlyOwner {
    require(
      newAddress != address(dividendTracker),
      "RewardToken: The dividend tracker already has that address"
    );

    SIPTokenDividendTracker newDividendTracker = SIPTokenDividendTracker(
      payable(newAddress)
    );

    require(
      newDividendTracker.owner() == address(this),
      "RewardToken: The new dividend tracker must be owned by the Dividend token contract"
    );

    newDividendTracker.excludeFromDividends(address(newDividendTracker));
    newDividendTracker.excludeFromDividends(address(this));
    newDividendTracker.excludeFromDividends(address(uniswapV2Router));
    newDividendTracker.excludeFromDividends(address(0xdEaD));
    newDividendTracker.excludeFromDividends(address(0));
    newDividendTracker.excludeFromDividends(owner());

    emit UpdateDividendTracker(newAddress, address(dividendTracker));

    dividendTracker = newDividendTracker;
  }

  function updateUniswapV2Router(address newAddress) public onlyOwner {
    require(
      newAddress != address(uniswapV2Router),
      "RewardToken: The router already has that address"
    );
    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
  }

  function excludeAccountFromDividends(address account) public onlyOwner {
    dividendTracker.excludeFromDividends(account);
    emit ExcludeAccountFromDividends(account);
  }

  function isExcludedFromDividends(address account) public view returns (bool) {
    return dividendTracker.isExcludedFromDividends(account);
  }

  function excludeFromMaxWallet(address account, bool excluded)
    public
    onlyOwner
  {
    _isExcludedFromMaxWallet[account] = excluded;
  }

  function updateMaxWallet(uint256 newValue) external onlyOwner {
    maxWallet = newValue * (10**18);
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
  }

  function excludeMultipleAccountsFromFees(
    address[] calldata accounts,
    bool excluded
  ) public onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      _isExcludedFromFees[accounts[i]] = excluded;
    }

    emit ExcludeMultipleAccountsFromFees(accounts, excluded);
  }

  function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
  {
    require(
      pair != uniswapV2Pair,
      "RewardToken: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
    );

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(
      automatedMarketMakerPairs[pair] != value,
      "RewardToken: Automated market maker pair is already set to that value"
    );
    automatedMarketMakerPairs[pair] = value;

    if (value) {
      dividendTracker.excludeFromDividends(pair);
    }

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function _validateFees() private view {
    require(getTotalFees() <= MAX_TOTAL_FEES, "total fees too high");
  }

  function launch() external onlyOwner {
    marketingFee = 9; // normalize the marketing fee
    maxBuyTransactionAmount = 2000000 * (10**18); // 2 of supply
    maxSellTransactionAmount = 2000000 * (10**18); // 2% of supply
    maxWallet = 2000000 * (10**18); // 3% of supply
  }

  function noLimit() external onlyOwner {
    maxBuyTransactionAmount = 2000000 * (10**18);
    maxSellTransactionAmount = 2000000 * (10**18);
    maxWallet = 2000000 * (10**18);
  }

  function updateMarketingFee(uint256 newFee) external onlyOwner {
    require(marketingFee != newFee, "new fee required");
    uint256 oldFee = marketingFee;
    marketingFee = newFee;
    _validateFees();
    emit UpdateMarketingFee(newFee, oldFee);
  }

  function updateBuybackFee(uint256 newFee) external onlyOwner {
    require(buyBackFee != newFee, "new fee required");
    require(newFee <= MAX_BUYBACK_FEE, "new fee too high");
    buyBackFee = newFee;
    _validateFees();
  }

  function updateLiquidityFee(uint256 newFee) external onlyOwner {
    require(liquidityFee != newFee, "new fee required");
    require(newFee <= MAX_LIQUIDITY_FEE, "new fee too high");
    uint256 oldFee = liquidityFee;
    liquidityFee = newFee;
    _validateFees();
    emit UpdateLiquidityFee(newFee, oldFee);
  }

  function updateRewardsFee(uint256 newFee) external onlyOwner {
    require(rewardsFee != newFee, "new fee required");
    require(newFee <= MAX_REWARDS_FEE, "new fee too high");
    uint256 oldFee = rewardsFee;
    rewardsFee = newFee;
    _validateFees();
    emit UpdateRewardsFee(newFee, oldFee);
  }

  function updateSellFee(uint256 newFee) external onlyOwner {
    require(sellFee != newFee, "new fee required");
    require(newFee <= MAX_SELL_FEE, "new fee too high");
    uint256 oldFee = sellFee;
    sellFee = newFee;
    emit UpdateSellFee(newFee, oldFee);
  }

  function updateMaxBuyTransactionAmount(uint256 newValue) external onlyOwner {
    require(maxBuyTransactionAmount != newValue, "new value required");
    require(
      newValue >= MIN_BUY_TRANSACTION_AMOUNT &&
        newValue <= MAX_BUY_TRANSACTION_AMOUNT,
      "new value must be >= MIN_BUY_TRANSACTION_AMOUNT and <= MAX_BUY_TRANSACTION_AMOUNT"
    );
    uint256 oldValue = maxBuyTransactionAmount;
    maxBuyTransactionAmount = newValue;
    emit UpdateMaxBuyTransactionAmount(newValue, oldValue);
  }

  function updateMaxSellTransactionAmount(uint256 newValue) external onlyOwner {
    require(maxSellTransactionAmount != newValue, "new value required");
    require(
      newValue >= MIN_SELL_TRANSACTION_AMOUNT &&
        newValue <= MAX_SELL_TRANSACTION_AMOUNT,
      "new value must be >= MIN_SELL_TRANSACTION_AMOUNT and <= MAX_SELL_TRANSACTION_AMOUNT"
    );
    uint256 oldValue = maxSellTransactionAmount;
    maxSellTransactionAmount = newValue;
    emit UpdateMaxSellTransactionAmount(newValue, oldValue);
  }

  function updateSwapTokensAtAmount(uint256 newValue) external onlyOwner {
    require(swapTokensAtAmount != newValue, "new value required");
    require(
      newValue >= MIN_SWAP_TOKENS_AT_AMOUNT &&
        newValue <= MAX_SWAP_TOKENS_AT_AMOUNT,
      "new value must be >= MIN_SWAP_TOKENS_AT_AMOUNT and <= MAX_SWAP_TOKENS_AT_AMOUNT"
    );
    uint256 oldValue = swapTokensAtAmount;
    swapTokensAtAmount = newValue;
    emit UpdateSwapTokensAtAmount(newValue, oldValue);
  }

  function updateGasForProcessing(uint256 newValue) public onlyOwner {
    require(
      newValue >= 200000 && newValue <= MAX_GAS_FOR_PROCESSING,
      "RewardToken: gasForProcessing must be between 200,000 and MAX_GAS_FOR_PROCESSING"
    );
    require(
      newValue != gasForProcessing,
      "RewardToken: Cannot update gasForProcessing to same value"
    );
    emit UpdateGasForProcessing(newValue, gasForProcessing);
    gasForProcessing = newValue;
  }

  function updateClaimWait(uint256 claimWait) external onlyOwner {
    dividendTracker.updateClaimWait(claimWait);
  }

  function getClaimWait() external view returns (uint256) {
    return dividendTracker.claimWait();
  }

  function getTotalDividendsDistributed() external view returns (uint256) {
    return dividendTracker.totalDividendsDistributed();
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function processDividendTracker(uint256 gas) external onlyOwner {
    (
      uint256 iterations,
      uint256 claims,
      uint256 lastProcessedIndex
    ) = dividendTracker.process(gas);
    emit ProcessedDividendTracker(
      iterations,
      claims,
      lastProcessedIndex,
      false,
      gas,
      tx.origin
    );
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    // max wallet
    if (
      to != uniswapV2Pair &&
      to != address(0xdead) &&
      (!_isExcludedFromMaxWallet[to] || !_isExcludedFromMaxWallet[from])
    ) {
      require(
        super.balanceOf(to) + amount <= maxWallet,
        "Transfer amount exceeds wallet"
      );
    }

    // Prohibit buys/sells before trading is enabled. This is useful for fair launches for obvious reasons
    // if (from == uniswapV2Pair) {
    //   require(
    //     SIPGuardOffline || isWhitelisted[to],
    //     "trading isnt enabled or account isnt whitelisted"
    //   );
    // } else if (to == uniswapV2Pair) {
    //   require(
    //     SIPGuardOffline || isWhitelisted[from],
    //     "trading isnt enabled or account isnt whitelisted"
    //   );
    // }

    // Enforce max buy
    if (
      automatedMarketMakerPairs[from] &&
      // No max buy when removing liq
      to != address(uniswapV2Router)
    ) {
      require(
        amount <= maxBuyTransactionAmount,
        "Transfer amount exceeds the maxTxAmount."
      );
    }

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    // Enforce max sell
    if (
      !swapping && automatedMarketMakerPairs[to] // sells only by detecting transfer to automated market maker pair
    ) {
      require(
        amount <= maxSellTransactionAmount,
        "Sell transfer amount exceeds the maxSellTransactionAmount."
      );
    }

    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = (contractTokenBalance >= swapTokensAtAmount) &&
      swapAndLiquifyEnabled;
    uint256 totalFees = getTotalFees();

    // Swap and liq for sells
    if (canSwap && !swapping && automatedMarketMakerPairs[to]) {
      swapping = true;
      uint256 liquidityAndTeamTokens = contractTokenBalance
        .mul(liquidityFee.add(marketingFee).add(devFee).add(buyBackFee))
        .div(totalFees);
      swapAndLiquifyAndFundTeam(liquidityAndTeamTokens);
      uint256 rewardTokens = balanceOf(address(this));
      swapAndSendDividends(rewardTokens);

      swapping = false;
    }

    // Only take taxes for buys/sells (and obviously dont take taxes during swap and liquify)
    bool takeFee = !swapping &&
      (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    if (takeFee) {
      uint256 fees = amount.mul(totalFees).div(100);

      // If sell, add extra fee
      if (automatedMarketMakerPairs[to]) {
        fees += amount.mul(sellFee).div(100);
      }

      totalFeesCollected += fees;

      amount = amount.sub(fees);

      super._transfer(from, address(this), fees);
    }

    super._transfer(from, to, amount);

    // Trigger dividends to be paid out
    try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
    try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

    if (!swapping) {
      uint256 gas = gasForProcessing;

      try dividendTracker.process(gas) returns (
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex
      ) {
        emit ProcessedDividendTracker(
          iterations,
          claims,
          lastProcessedIndex,
          true,
          gas,
          tx.origin
        );
      } catch {}
    }
  }

  function DoKENRewardAddress() external view returns (address) {
    return rewardToken;
  }

  function DoKENDividendTrackerAddress() external view returns (address) {
    return address(dividendTracker);
  }

  function DoKENRewardOnPool() external view returns (uint256) {
    return IERC20(rewardToken).balanceOf(address(dividendTracker));
  }

  function DoKENTokenFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      getTotalFees(),
      rewardsFee,
      liquidityFee,
      marketingFee,
      devFee,
      sellFee
    );
  }

  function DoKENRewardDistributed() external view returns (uint256) {
    return dividendTracker.getTotalDividendsDistributed();
  }

  function DoKENGetAccountDividendsInfo(address account)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccount(account);
  }

  function DoKENGetAccountDividendsInfoAtIndex(uint256 index)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccountAtIndex(index);
  }

  function DoKENRewardPaid(address holder) external view returns (uint256) {
    (, , , , uint256 paidAmount, , , , ) = DoKENGetAccountDividendsInfo(
      holder
    );
    return paidAmount;
  }


  function DoKENRewardUnPaid(address holder)
    external
    view
    returns (uint256)
  {
    (, , , uint256 unpaidAmount, , , , , ) = DoKENGetAccountDividendsInfo(
            holder
    );
    return unpaidAmount;
  }

  function DoKENRewardClaim() external {
    dividendTracker.processAccount(payable(msg.sender), false);
  }

  function DividendLastProcessedIndex() external view returns (uint256) {
    return dividendTracker.getLastProcessedIndex();
  }

  function DoKENNumberOfDividendTokenHolders()
    external
    view
    returns (uint256)
  {
    return dividendTracker.getNumberOfTokenHolders();
  }

  function DividendDividendBalanceOf(address account)
    public
    view
    returns (uint256)
  {
    return dividendTracker.balanceOf(account);
  }

  function swapAndLiquifyAndFundTeam(uint256 tokens) private {
    uint256 totalFees = marketingFee.add(liquidityFee).add(devFee);
    // calculate token for liquidity
    uint256 liquidityTokens = tokens.mul(liquidityFee).div(totalFees);
    uint256 tokensForLiquidity = liquidityTokens.div(2); // half each
    // now do swap first
    uint256 balanceBeforeLiq = address(this).balance;
    swapTokensForEth(tokensForLiquidity);
    uint256 balanceAfterLiq = address(this).balance.sub(balanceBeforeLiq);

    // add liquidity to uniswap (really PCS, duh)
    addLiquidity(tokensForLiquidity, balanceAfterLiq);
    emit SwapAndLiquify(tokensForLiquidity, balanceAfterLiq, balanceAfterLiq);

    uint256 otherHalf = tokens.sub(liquidityTokens);

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(otherHalf); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    //uint256 marketingTokens = half.mul(marketingFee).div(totalFees);
    uint256 mktAndDevAndBuyback = marketingFee.add(devFee).add(buyBackFee);

    uint256 marketingETH = newBalance.mul(marketingFee).div(
      mktAndDevAndBuyback
    );
    uint256 buyBackETH = (newBalance.mul(buyBackFee).div(mktAndDevAndBuyback))
      .div(2);

    uint256 devETH = (newBalance.mul(devFee).div(mktAndDevAndBuyback)).add(
      buyBackETH
    );

    marketingWallet.transfer(marketingETH);
    buyBackWallet.transfer(buyBackETH);
    devWallet.transfer(devETH);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function swapTokensForETH(uint256 tokenAmount, address recipient) private {
    // generate the uniswap pair path of tokens -> WETH
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETH(
      tokenAmount,
      0, // accept any amount of the reward token
      path,
      recipient,
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this), // lock LP tokens in this contract forever - no rugpull, SAFU!!
      block.timestamp
    );
  }

  function swapTokensForRewards(uint256 tokenAmount, address recipient)
    private
  {
    // generate the uniswap pair path of weth -> reward token
    address[] memory path = new address[](3);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    path[2] = rewardToken;

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of the reward token
      path,
      recipient,
      block.timestamp
    );
  }

  function sendDividends() private returns (bool, uint256) {
    uint256 dividends = IERC20(rewardToken).balanceOf(address(this));
    bool success = IERC20(rewardToken).transfer(
      address(dividendTracker),
      dividends
    );

    if (success) {
      dividendTracker.distributeRewardTokenDividends(dividends);
    }

    return (success, dividends);
  }

  function swapAndSendDividends(uint256 tokens) private {
    // Locks the LP tokens in this contract forever
    swapTokensForRewards(tokens, address(this));
    (bool success, uint256 dividends) = sendDividends();
    if (success) {
      emit SendDividends(tokens, dividends);
    }
  }

  // For withdrawing ETH accidentally sent to the contract so senders can be refunded
  function getETHBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function flushStuckBalance() external {
    address payable to = devWallet;
    to.transfer(getETHBalance());
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
    bytes4 SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(SELECTOR, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TRANSFER_FAILED"
    );
  }
}