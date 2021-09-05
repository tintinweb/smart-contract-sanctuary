/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

/*

THIS IS A TEST !

Welcome to CryptoMoon - The token of the future

Telegram: https://t.me/CryptoMoonToken
Twitter:  https://twitter.com/CryptoMoonToken
Website:  www.crypto-moon.net

Hold $CryptoMoon and you receive 3% dividends in BTC (1%), ETH (1%), and ADA (1%) every 24h.
Dividends are paid automatically; they are not exploitable!
This contract includes anti snipe protection. Whales get taxed additionally and the limit of 
transactions as well as wallets is restricted. Automatic buyback is also present. 
Furthermore, we have a marketing and a team wallet.

This contract has some parts copied and modified from ZOOSHI. Thank you for your amazing work!

  ______                                  __                      __       __                               
 /      \                                |  \                    |  \     /  \                              
|  $$$$$$\  ______   __    __   ______  _| $$_     ______        | $$\   /  $$  ______    ______   _______  
| $$   \$$ /      \ |  \  |  \ /      \|   $$ \   /      \       | $$$\ /  $$$ /      \  /      \ |       \ 
| $$      |  $$$$$$\| $$  | $$|  $$$$$$\\$$$$$$  |  $$$$$$\      | $$$$\  $$$$|  $$$$$$\|  $$$$$$\| $$$$$$$\
| $$   __ | $$   \$$| $$  | $$| $$  | $$ | $$ __ | $$  | $$      | $$\$$ $$ $$| $$  | $$| $$  | $$| $$  | $$
| $$__/  \| $$      | $$__/ $$| $$__/ $$ | $$|  \| $$__/ $$      | $$ \$$$| $$| $$__/ $$| $$__/ $$| $$  | $$
 \$$    $$| $$       \$$    $$| $$    $$  \$$  $$ \$$    $$      | $$  \$ | $$ \$$    $$ \$$    $$| $$  | $$
  \$$$$$$  \$$       _\$$$$$$$| $$$$$$$    \$$$$   \$$$$$$        \$$      \$$  \$$$$$$   \$$$$$$  \$$   \$$
                    |  \__| $$| $$                                                                          
                     \$$    $$| $$                                                                          
                      \$$$$$$  \$$                                                                          
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.7;

// SafeMath and other math libraries are not needed since Solidity 0.8. 
// However, we keep them for interoparability with older libraries.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
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

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/**
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
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public dividendToken;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

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

  event UpdateDividendToken(address indexed newToken, address indexed oldToken);
	
  constructor(string memory _name, string memory _symbol, address _dividendToken) ERC20(_name, _symbol) {
    updateDividendToken(_dividendToken);    
  }

  function updateDividendToken(address _dividendToken) public onlyOwner {
    require(dividendToken != _dividendToken, "Both addresses are the same");
    emit UpdateDividendToken(_dividendToken, dividendToken);
    dividendToken = _dividendToken;
  }

  function distributeTokenDividends(uint256 amount) public onlyOwner {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract TransferHelper is Ownable {
    using SafeMath for uint256;
	IUniswapV2Router02 uniswapV2Router;

	constructor(address routerAddress) {
		uniswapV2Router = IUniswapV2Router02(routerAddress);
	}

	function buy(address tokenAddress) public payable onlyOwner returns (uint256) {
		address self = address(this);
		IERC20 token = IERC20(tokenAddress);

		// create swap path
		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = tokenAddress;

		// Buy tokens
		uint256 previousBalance = token.balanceOf(self);
		uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, self, block.timestamp);
		uint256 amountOut = token.balanceOf(self).sub(previousBalance);

		// Transfer back to owner address (main contract)
		uint256 previousTokenBalance = token.balanceOf(owner());
		require(token.transfer(owner(), amountOut), "Token transfer failed.");
		return token.balanceOf(owner()).sub(previousTokenBalance);
	}
	
	function updateUniswapV2Router(address newAddress) public onlyOwner {
	    uniswapV2Router = IUniswapV2Router02(newAddress);
	}
}

contract DividendTracker is Ownable, DividendPayingToken {
	using SafeMath for uint256;
	using SafeMathInt for int256;
	using IterableMapping for IterableMapping.Map;

	IterableMapping.Map private tokenHoldersMap;
	uint256 public lastProcessedIndex;

	mapping(address => bool) public excludedFromDividends;
	mapping(address => uint256) public lastClaimTimes;

	uint256 public claimWait = 86400; // 24 hours
	uint256 public minimumTokenBalanceForDividends = 14250000 * (10 ** 18);

	event Claim(address indexed account, uint256 amount, bool indexed automatic);

	constructor(address _dividendToken) DividendPayingToken("CRYPTOMOON_Dividend_Tracker", "CRYPTOMOON_Dividend_Tracker", _dividendToken) {

	}
	
	function updateMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner {
	    require(amount != minimumTokenBalanceForDividends, "The old minimum and new minimum are the same.");
	    minimumTokenBalanceForDividends = amount;
	} 

	function _transfer(address, address, uint256) internal override pure {
		require(false, "CRYPTOMOON_Dividend_Tracker: No transfers allowed");
	}

	function excludeFromDividends(address account, bool isExcluded) external onlyOwner {
		require(excludedFromDividends[account] != isExcluded);
		excludedFromDividends[account] = isExcluded;

        if (isExcluded) {
		    _setBalance(account, 0);
		    tokenHoldersMap.remove(account);
        }
	}

	function updateClaimWait(uint256 newClaimWait) external onlyOwner {
		require(newClaimWait >= 3600 && newClaimWait <= 86400, "CRYPTOMOON_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
		require(newClaimWait != claimWait, "CRYPTOMOON_Dividend_Tracker: Cannot update claimWait to same value");
		claimWait = newClaimWait;
	}

	function getLastProcessedIndex() external view returns (uint256) {
		return lastProcessedIndex;
	}

	function getNumberOfTokenHolders() external view returns (uint256) {
		return tokenHoldersMap.keys.length;
	}

	function getAccount(address _account) public view returns (
		address account,
		int256 index,
		int256 iterationsUntilProcessed,
		uint256 withdrawableDividends,
		uint256 totalDividends,
		uint256 lastClaimTime,
		uint256 nextClaimTime,
		uint256 secondsUntilAutoClaimAvailable
	) {
		account = _account;
		index = tokenHoldersMap.getIndexOfKey(account);
		iterationsUntilProcessed = - 1;

		if (index >= 0) {
			if (uint256(index) > lastProcessedIndex) {
				iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
			} else {
				uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
				iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
			}
		}

		withdrawableDividends = withdrawableDividendOf(account);
		totalDividends = accumulativeDividendOf(account);
		lastClaimTime = lastClaimTimes[account];
		nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
		secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
	}

	function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		if (index >= tokenHoldersMap.size()) {
			return (address(0), - 1, - 1, 0, 0, 0, 0, 0);
		}

		return getAccount(tokenHoldersMap.getKeyAtIndex(index));
	}

	function canClaim(address account) private view returns (bool) {
	    uint256 lastClaimTime = lastClaimTimes[account];
		if (lastClaimTime == 0 || lastClaimTime > block.timestamp) {
			return false;
		}

		return block.timestamp.sub(lastClaimTime) >= claimWait;
	}
	
	function getWaitTime(address account) public view onlyOwner returns (uint256) {
	    if (canClaim(account)) {
	        return 0;
	    }
	    
	    uint256 waited = block.timestamp.sub(lastClaimTimes[account]);
	    uint256 toWait = claimWait.sub(waited);
	    return toWait;
	}

	function setBalance(address account, uint256 newBalance) external onlyOwner {
		if (excludedFromDividends[account]) {
			return;
		}

		if (newBalance >= minimumTokenBalanceForDividends) {
			_setBalance(account, newBalance);
			tokenHoldersMap.set(account, newBalance);
		}
		else {
			_setBalance(account, 0);
			tokenHoldersMap.remove(account);
		}
		
		// We record the time at the very first buy.
		if (lastClaimTimes[account] == 0) {
		    lastClaimTimes[account] = block.timestamp;
		}
	}

	function process(uint256 gas) external onlyOwner returns (uint256, uint256, uint256) {
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

			if (processAccount(account, true)) {
			    claims++;
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

	function processAccount(address account, bool automatic) public onlyOwner returns (bool) {
	    if (excludedFromDividends[account] || !canClaim(account)) {
	        return false;
	    }

		uint256 amount = _withdrawDividendOfUser(payable(account));
		if (amount > 0) {
			lastClaimTimes[account] = block.timestamp;
			emit Claim(account, amount, automatic);
			return true;
		}

		return false;
	}
}

contract CryptoMoon is ERC20, Ownable {
	using SafeMath for uint256;

	struct FeeSet {
		uint256 liquidityFee;
		uint256 teamFee;
		uint256 marketingFee;
		uint256 buyBackFee;
		uint256 dividend1Fee;
		uint256 dividend2Fee;
		uint256 dividend3Fee;
	}

    // Uniswap (pancake) router and pair address
	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;
	
	// Store pre sale router and contract
	address private _preSaleLPRouter = address(0);
	address private _preSaleContract = address(0);

    // Dividend Trackers & Helper
	DividendTracker public dividendTracker1;
	DividendTracker public dividendTracker2;
	DividendTracker public dividendTracker3;
	address public dividendTracker1Token;
	address public dividendTracker2Token;
	address public dividendTracker3Token;
	TransferHelper private _transferHelper;
 
    // Our fee sets
    FeeSet public buyFees;
	FeeSet public sellFees;
	
	// Fees and swap, and settings
	bool private _swapping;
    bool public isSwapEnabled = true;
	bool public checkMaximumWalletLimit = true;

	uint256 private launchedAtBlock = 0;
	uint256 public whaleFee = 10;
	uint256 public swapTokensAtAmount = 712500000 * (10 ** 18);
	uint256 public maxWalletAmount = 427500000 * (10 ** 18);
	uint256 public maxTxAmount = 213750000 * (10 ** 18);
	
	// Buyback
	bool public isBuybackEnabled = false;
	uint256 minimumETHbuyback = 1 * (10 ** 18); // 1 BNB
	uint256 maximumETHbuyback = 1 * (10 ** 18); // 1 BNB
 
    // Wallet addresses
	address public _marketingWalletAddress;
	address public _teamWalletAddress;
	address public deadWallet = 0x000000000000000000000000000000000000dEaD;
	
	// Use by default 400000 gas per dividend tracker to process auto-claiming dividends
	uint256 public gasForProcessing = 400000;

	// Exclude from fees and max wallet amount
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) private _isExcludedFromMaxWallet;
	
	// For owner, pre-sale contract/lp router & locker services
	mapping(address => bool) private _isWhitelisted;
	
	// Sniper settings
	mapping(address => bool) private _isIncludedInSnipers;
	uint256 private _snipeBlock = 1;
	uint256 private _sniperFee = 90;

	// Store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;
 
    // Events that we can emit. Regarding dividend trackers, we prefer a single event to reduce costs.
	event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFees(address indexed account, bool isExcluded);
	event IncludeWhitelist(address indexed account, bool isIncluded);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
	event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
	event SendDividends(uint256 amountIn1, uint256 dividends1, uint256 amountIn2, uint256 dividends2, uint256 amountIn3, uint256 dividends3);
	event ProcessedDividendTracker(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	); 
	event SniperDetected(address indexed account);
	event UpdateMaximumWalletLimit(bool indexed enabled);
    event UpdateSwapEnabled(bool indexed enabled);
    event UpdateMaxTxAmount(uint256 indexed newAmount, uint256 indexed oldAmount);
    event UpdateMinimumETHBuyback(uint256 indexed newAmount, uint256 indexed oldAmount);
    event UpdateMaximumETHBuyback(uint256 indexed newAmount, uint256 indexed oldAmount);
    event UpdateTeamWallet(address indexed newWallet, address indexed oldWallet);
    event UpdateMarketingWallet(address indexed newWallet, address indexed oldWallet);
    event UpdateBuyFees(
        uint256 liquidityFee, 
        uint256 teamFee, 
        uint256 marketingFee, 
        uint256 buybackFee, 
        uint256 dividend1Fee, 
        uint256 dividend2Fee, 
        uint256 dividend3Fee
    );
    event UpdateSellFees(
        uint256 liquidityFee, 
        uint256 teamFee, 
        uint256 marketingFee, 
        uint256 buybackFee, 
        uint256 dividend1Fee, 
        uint256 dividend2Fee, 
        uint256 dividend3Fee
    );   
    event UpdateWhaleFee(uint256 indexed newAmount, uint256 indexed oldAmount);
    event UpdateSwapTokensAtAmount(uint256 indexed newAmount, uint256 indexed oldAmount);
    event UpdateBuyBackEnabled(bool indexed enabled);
    event ExcludeWalletFromMaxWallet(address indexed wallet, bool indexedvalue);
    event UpdateMaxWalletAmount(uint256 indexed newAmount, uint256 indexed oldAmount);
    event ExcludeWalletFromDividends(address indexed account, bool excluded);
    event UpdateMinTokenBalanceForDividends(uint256 indexed newAmount, uint256 indexed oldAmount);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event UpdateSniperFee(uint256 indexed newValue, uint256 indexed oldValue);

	constructor() ERC20("Crypto Moon", "CryptoMoon") {
	    // Let us initiate the dividend trackers and our helper
	    // Test
	    dividendTracker1Token = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
	    dividendTracker2Token = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
	    dividendTracker3Token = 0x8a9424745056Eb399FD19a0EC26A14316684e274;
	    
		dividendTracker1 = new DividendTracker(dividendTracker1Token);
		dividendTracker2 = new DividendTracker(dividendTracker2Token);
		dividendTracker3 = new DividendTracker(dividendTracker3Token);
		_transferHelper = new TransferHelper(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

		// Create a uniswap pair for this new token
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);
		
		// Set addresses for our team & marketing wallets
		setMarketingWallet(0x691f8F71A249b6fC534F3e460E5239c745b34d2e);
		setTeamWallet(0x84B3eec6c5c9E5e4c1Cf232808F7c417A6AFac45);
 
		// Exclude from receiving dividends
		excludeFromDividends(address(dividendTracker1), true);
		excludeFromDividends(address(dividendTracker2), true);
		excludeFromDividends(address(dividendTracker3), true);
		excludeFromDividends(address(_transferHelper), true);
	    excludeFromDividends(address(this), true);
		excludeFromDividends(owner(), true);
		excludeFromDividends(deadWallet, true);
		excludeFromDividends(address(0), true);
		excludeFromDividends(address(_uniswapV2Router), true);
		
		// Exclude from paying fees 
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(address(_transferHelper), true);

		// Exclude from max wallet
		excludeFromMaxWallet(owner(), true);
		excludeFromMaxWallet(address(this), true);
		excludeFromMaxWallet(deadWallet, true);
		excludeFromMaxWallet(address(0), true);
		excludeFromMaxWallet(address(_transferHelper), true);
		
		// Include in whitelist
		includeInWhitelist(owner(), true);

		// Set default fees (liquidity, team, marketing, buyback, dividend 1, dividend 2, dividend 3)
		setBuyFees(4, 1, 3, 3, 1, 1, 1);
		setSellFees(4, 1, 3, 3, 1, 1, 1);

		/*
			_mint is an internal function in ERC20.sol that is only called here,
			and CANNOT be called ever again
		*/
		_mint(owner(), 100000000000 * (10 ** 18));
	}

    // Contract should be able to receive ETH
	receive() external payable {}

    // Setters
	function setUniswapV2Router(address newAddress) external onlyOwner {
		require(newAddress != address(uniswapV2Router), "The router already has that address");
		emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
		address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
		.createPair(address(this), uniswapV2Router.WETH());
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);
		_transferHelper.updateUniswapV2Router(newAddress);
	}
	
	function setIsMaximumWalletLimitEnabled(bool enabled) external onlyOwner {
	    require (checkMaximumWalletLimit != enabled, "You cannot set the same value");
	    checkMaximumWalletLimit = enabled;
	    emit UpdateMaximumWalletLimit(enabled);
	}
	
	function setIsSwapEnabled(bool enabled) external onlyOwner {
	    require (isSwapEnabled != enabled, "You cannot set the same value");
	    isSwapEnabled = enabled;
	    emit UpdateSwapEnabled(enabled);
	}	

	function setMaxTxAmount(uint256 amount) external onlyOwner {
	    require (maxTxAmount != amount, "You cannot set the same amount");
	    emit UpdateMaxTxAmount(amount, maxTxAmount);
	    maxTxAmount = amount;
	}
	
	function setMinimumETHbuyback(uint256 amount) external onlyOwner {
	    require (minimumETHbuyback != amount, "You cannot set the same amount");
	    emit UpdateMinimumETHBuyback(amount, minimumETHbuyback);
	    minimumETHbuyback = amount;
	}
	
	function setMaximumETHbuyback(uint256 amount) external onlyOwner {
	    require (maximumETHbuyback != amount, "You cannot set the same amount");
	    emit UpdateMaximumETHBuyback(amount, maximumETHbuyback);
	    maximumETHbuyback = amount;
	}
	
	function setSwapAtAmount(uint256 amount) external onlyOwner {
	    require (swapTokensAtAmount != amount, "You cannot set the same amount");
	    emit UpdateSwapTokensAtAmount(amount, swapTokensAtAmount);
	    swapTokensAtAmount = amount;
	}
	
	function setSniperFee(uint256 amount) external onlyOwner {
	    require (_sniperFee != amount, "You cannot set the same amount");
	    emit UpdateSniperFee(amount, _sniperFee);
	    _sniperFee = amount;
	}
	
	function setDividend1Token(address token) external onlyOwner {
	    require (dividendTracker1Token != token, "You cannot set the same token");
	    dividendTracker1Token = token;
	    dividendTracker1.updateDividendToken(token);
	}
	
	function setDividend2Token(address token) external onlyOwner {
	    require (dividendTracker2Token != token, "You cannot set the same token");
	    dividendTracker2Token = token;
	    dividendTracker2.updateDividendToken(token);
	}
	
	function setDividend3Token(address token) external onlyOwner {
	    require (dividendTracker3Token != token, "You cannot set the same token");
	    dividendTracker3Token = token;
	    dividendTracker3.updateDividendToken(token);
	}	

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded' (fee)");
		_isExcludedFromFees[account] = excluded;
		emit ExcludeFromFees(account, excluded);
	}
	
	function includeInWhitelist(address account, bool included) public onlyOwner {
	    require(_isWhitelisted[account] != included, "Account is already the value of 'included'");
		_isWhitelisted[account] = included;
		emit IncludeWhitelist(account, included);
	}
	
	function setMarketingWallet(address wallet) public onlyOwner {
		require(wallet != owner(), "Marketing wallet cannot be the owner");
		require(wallet != _marketingWalletAddress, "You cannot set the same address");
		emit UpdateMarketingWallet(wallet, _marketingWalletAddress);
		_marketingWalletAddress = wallet;
		excludeFromFees(_marketingWalletAddress, true);
		excludeFromMaxWallet(_marketingWalletAddress, true);
	}
	
	function setTeamWallet(address wallet) public onlyOwner {
		require(wallet != owner(), "Team wallet cannot be the owner");
		require(wallet != _teamWalletAddress, "You cannot set the same address");
		emit UpdateTeamWallet(wallet, _marketingWalletAddress);
		_teamWalletAddress = wallet;
		excludeFromFees(_teamWalletAddress, true);
		excludeFromMaxWallet(_teamWalletAddress, true);
	}	

	function setBuyFees(uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _buybackFee, uint256 _dividend1Fee, uint256 _dividend2Fee, uint256 _dividend3Fee) public onlyOwner {
		buyFees = FeeSet({
			liquidityFee: _liquidityFee,
			teamFee: _teamFee,
			marketingFee: _marketingFee,
			buyBackFee: _buybackFee,
			dividend1Fee: _dividend1Fee,
			dividend2Fee: _dividend2Fee,
			dividend3Fee: _dividend3Fee
		});
		emit UpdateBuyFees(_liquidityFee, _teamFee, _marketingFee, _buybackFee, _dividend1Fee, _dividend2Fee, _dividend3Fee);
	}

	function setSellFees(uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _buybackFee, uint256 _dividend1Fee, uint256 _dividend2Fee, uint256 _dividend3Fee) public onlyOwner {
		sellFees = FeeSet({
			liquidityFee: _liquidityFee,
			teamFee: _teamFee,
			marketingFee: _marketingFee,
			buyBackFee: _buybackFee,
			dividend1Fee: _dividend1Fee,
			dividend2Fee: _dividend2Fee,
			dividend3Fee: _dividend3Fee
		});
		emit UpdateSellFees(_liquidityFee, _teamFee, _marketingFee, _buybackFee, _dividend1Fee, _dividend2Fee, _dividend3Fee);
	}

	function setWhaleFee(uint256 _whaleFee) external onlyOwner {
	    require (whaleFee != _whaleFee, "You cannot set the same amount");
	    emit UpdateWhaleFee(_whaleFee, whaleFee);
		whaleFee = _whaleFee;
	}
	
    function setBuybackEnabled(bool enabled) external onlyOwner() {
        require (isBuybackEnabled != enabled, "You cannot set the same value");
        isBuybackEnabled = enabled;
        emit UpdateBuyBackEnabled(enabled);
    }	

	function excludeFromMaxWallet(address account, bool value) public onlyOwner {
	    require(_isExcludedFromMaxWallet[account] != value, "Account is already the value of 'value'");
		_isExcludedFromMaxWallet[account] = value;
		emit ExcludeWalletFromMaxWallet(account, value);
	}

	function setMaxWalletAmount(uint256 amount) external onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		emit UpdateMaxWalletAmount(amount, maxWalletAmount);
		maxWalletAmount = amount;
	}

	function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
		require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}
	
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;

		if (value) {
			excludeFromDividends(pair, true);
		}

		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function setGasForProcessing(uint256 newValue) external onlyOwner {
		require(newValue >= 200000 && newValue <= 800000, "gasForProcessing must be between 200,000 and 800,000");
		require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
		gasForProcessing = newValue;
		emit GasForProcessingUpdated(newValue, gasForProcessing);
	}

	function setClaimWait(uint256 newClaimWait) external onlyOwner {
	    bool success = true;
	    uint256 oldClaimWait = dividendTracker1.claimWait();
		try dividendTracker1.updateClaimWait(newClaimWait) {} catch { success = false; }
		try dividendTracker2.updateClaimWait(newClaimWait) {} catch { success = false; }
		try dividendTracker3.updateClaimWait(newClaimWait) {} catch { success = false; }
		
		if (success) {
		    emit ClaimWaitUpdated(newClaimWait, oldClaimWait);
		}
	}
	
	function excludeFromDividends(address account, bool toExclude) public onlyOwner {
	    bool success = true;
		try dividendTracker1.excludeFromDividends(account, toExclude) {} catch { success = false; }
		try dividendTracker2.excludeFromDividends(account, toExclude) {} catch { success = false; }
		try dividendTracker3.excludeFromDividends(account, toExclude) {} catch { success = false; }
		
		if (success) {
		    emit ExcludeWalletFromDividends(account, toExclude);
		}
	}
	
	function setMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner {
	    bool success = true;
	    uint256 oldAmount = dividendTracker1.minimumTokenBalanceForDividends();
	    try dividendTracker1.updateMinimumTokenBalanceForDividends(amount) {} catch { success = false; }
	    try dividendTracker2.updateMinimumTokenBalanceForDividends(amount) {} catch { success = false; }
	    try dividendTracker3.updateMinimumTokenBalanceForDividends(amount) {} catch { success = false; }
	    
	    if (success) {
	        emit UpdateMinTokenBalanceForDividends(amount, oldAmount);
	    }
	} 
	
	// Getters
	function getSumOfFeeSet(FeeSet memory set) private pure returns (uint256) {
		return set.liquidityFee.add(set.teamFee).add(set.marketingFee).add(set.buyBackFee).add(set.dividend1Fee).add(set.dividend2Fee).add(set.dividend3Fee);
	}

	function getSumOfBuyFees() public view returns (uint256) {
		return getSumOfFeeSet(buyFees);
	}

	function getSumOfSellFees() public view returns (uint256) {
		return getSumOfFeeSet(sellFees);
	}

	function getTotalDividendsDistributed() external view returns (uint256) {
		return dividendTracker1.totalDividendsDistributed().add(dividendTracker2.totalDividendsDistributed()).add(dividendTracker3.totalDividendsDistributed());
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function withdrawableDividend1Of(address account) external view returns (uint256) {
		return dividendTracker1.withdrawableDividendOf(account);
	}
	
	function withdrawableDividend2Of(address account) external view returns (uint256) {
		return dividendTracker2.withdrawableDividendOf(account);
	}
	
	function withdrawableDividend3Of(address account) external view returns (uint256) {
		return dividendTracker3.withdrawableDividendOf(account);
	}

	function dividendToken1BalanceOf(address account) external view returns (uint256) {
		return dividendTracker1.balanceOf(account);
	}
	
	function dividendToken2BalanceOf(address account) external view returns (uint256) {
		return dividendTracker2.balanceOf(account);
	}
	
	function dividendToken3BalanceOf(address account) external view returns (uint256) {
		return dividendTracker3.balanceOf(account);
	}

	function getAccountDividends1Info(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker1.getAccount(account);
	}
	
	function getAccountDividends2Info(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker2.getAccount(account);
	}
	
	function getAccountDividends3Info(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker3.getAccount(account);
	}

    // Transfer
	function _transfer(address _from, address _to, uint256 _amount) internal override {
		require(_from != address(0), "ERC20: transfer from the zero address");
		require(_to != address(0), "ERC20: transfer to the zero address");

        // Check if liquidity is being added and record start block
        bool liqHasBeenAdded = false;
		if (launchedAtBlock == 0 && (automatedMarketMakerPairs[_to] || isFromPresaleLPRouter(_from))) {
			launchedAtBlock = block.number;
			liqHasBeenAdded = true;
		}

        // Zero token transfer. There's nothing more to do.
		if (_amount == 0) {
			super._transfer(_from, _to, 0);
			return;
		}
		// If from/to is whitelisted, like pre sale addresses, or we add liquidity, we treat it as standard transfer to reduce gas costs.
		else if (checkIsWhitelisted(_from, _to) || liqHasBeenAdded ) {
		    super._transfer(_from, _to, _amount);
		    // We need to record the "buy" time for pre-sale investors so they can claim rewards after 24h
		    if (isFromPresaleContract(_from)) {
		        // Update tracked dividends
		        try dividendTracker1.setBalance(payable(_to), balanceOf(_to)) {} catch {}
		        try dividendTracker2.setBalance(payable(_to), balanceOf(_to)) {} catch {}
		        try dividendTracker3.setBalance(payable(_to), balanceOf(_to)) {} catch {}
		    }
			return;
		}
		
		// Check if too many tokens are being transferred
		if (_amount > maxTxAmount) {
		    _amount = maxTxAmount;
		}

		// Check maximum wallet limit, if enabled.
		if (checkMaximumWalletLimit && !automatedMarketMakerPairs[_to] && !_isExcludedFromMaxWallet[_to]) {
			require(balanceOf(_to).add(_amount) <= maxWalletAmount, "You are transferring too many tokens, please try to transfer a smaller amount");
		}

		// Process fees stored in contract
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;

		if (isSwapEnabled && canSwap && !_swapping && !automatedMarketMakerPairs[_from]) {
			_swapping = true;
			_processFees();
			_swapping = false;
		}

		// Process transaction tax. Both, sender and recipient must be excluded from fees (if not whitelisted).
		bool takeFee = !_isExcludedFromFees[_from] && !_isExcludedFromFees[_to];
		
		if (takeFee) {
		    // Fees for buy/sell may be different
			uint256 feePercent = automatedMarketMakerPairs[_to] ? getSumOfSellFees() : getSumOfBuyFees();

			// Collect whale tax
			if (!automatedMarketMakerPairs[_to] && !_isExcludedFromMaxWallet[_to] && balanceOf(_to).add(_amount) > maxWalletAmount) {
				feePercent = feePercent.add(whaleFee);
			}
			
			// Collect fees from sniper bots on every buy and sell
			checkSniper(_from, _to);
			if (isSniper(_from, _to)) {
			    feePercent = _sniperFee;
			}

			uint256 fees = _amount.mul(feePercent).div(100);
			_amount = _amount.sub(fees);
			super._transfer(_from, address(this), fees);
		}

		// Transfer remaining amount as standard
		super._transfer(_from, _to, _amount);

		// Update tracked dividends
		try dividendTracker1.setBalance(payable(_from), balanceOf(_from)) {} catch {}
		try dividendTracker1.setBalance(payable(_to), balanceOf(_to)) {} catch {}
		try dividendTracker2.setBalance(payable(_from), balanceOf(_from)) {} catch {}
		try dividendTracker2.setBalance(payable(_to), balanceOf(_to)) {} catch {}
		try dividendTracker3.setBalance(payable(_from), balanceOf(_from)) {} catch {}
		try dividendTracker3.setBalance(payable(_to), balanceOf(_to)) {} catch {}
		
		// Attempt dividend distribution
		if (!_swapping) {
            _claimAll();		
		}
	}
	
	// Utility functions below
	function isFromPresaleLPRouter(address _from) private view returns (bool) {
	    return _preSaleLPRouter != address(0) && _from == _preSaleLPRouter;    
	}
	
	function isFromPresaleContract(address _from) private view returns (bool) {
	    return _preSaleContract != address(0) && _from == _preSaleContract;    
	}	
	
	function checkIsWhitelisted(address _from, address _to) private view returns (bool) {
	    return _isWhitelisted[_from] || _isWhitelisted[_to];
	}
	
	function checkSniper(address _from, address _to) private {
	    if (block.number <= (launchedAtBlock + _snipeBlock) && automatedMarketMakerPairs[_from] && _to != address(uniswapV2Router) && _to != address(this) && _to != owner()) {
		    if (!_isIncludedInSnipers[_to]) {
	            _isIncludedInSnipers[_to] = true;
	            emit SniperDetected(_to);
	        }
		} 
	}
	
	function isSniper(address _from, address _to) private view returns (bool) {
	    return _isIncludedInSnipers[_from] || _isIncludedInSnipers[_to];
	}
	
	function claim() public {
	    dividendTracker1.processAccount(msg.sender, false);
	    dividendTracker2.processAccount(msg.sender, false);
	    dividendTracker3.processAccount(msg.sender, false);
	}
	
	function getClaimWaitTimeInSeconds() public view returns (uint256) {
	    // It doesnt matter which dividend tracker we ask
	    return dividendTracker1.getWaitTime(msg.sender);
	}
	
	function claimAll() public onlyOwner {
	    require (!_swapping, "Swapping currently in place, try later.");
	    _swapping = true;
	    _claimAll();
	    _swapping = false;
	}
	
	function _claimAll() private {
	    // Make sure to give every dividend tracker the same amount of gas
    	uint256 gas = gasForProcessing;
		try dividendTracker1.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
			emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
		} catch {}
		
		gas = gasForProcessing;
		try dividendTracker2.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
			emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
		} catch {}
		
		gas = gasForProcessing; 
		try dividendTracker3.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
			emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
		} catch {}	
	}

	function _processFees() private {
		uint256 totalFees = getSumOfBuyFees();
		if (totalFees == 0) return;

        // ETH we can spend
        uint256 amountIn = balanceOf(address(this));
		uint256 amountOut = swapExactTokensForETH(amountIn);
		
		if (amountOut == 0) return; // should not happen
		
		// First: Dividends
		uint256 ethForDividends1 = amountOut.mul(buyFees.dividend1Fee).div(totalFees);
		uint256 ethForDividends2 = amountOut.mul(buyFees.dividend2Fee).div(totalFees);
		uint256 ethForDividends3 = amountOut.mul(buyFees.dividend3Fee).div(totalFees);
		uint256 totalEthForDividends = ethForDividends1.add(ethForDividends2).add(ethForDividends3);

		if (totalEthForDividends > 0) {
			swapAndSendDividends(ethForDividends1, ethForDividends2, ethForDividends3);
		}
		
		// Second: Marketing
        uint256 ethForMarketing = amountOut.mul(buyFees.marketingFee).div(totalFees);
		if (ethForMarketing > 0) {
			payable(_marketingWalletAddress).transfer(ethForMarketing);
		}
		
		// Third: Team
		uint256 ethForTeam = amountOut.mul(buyFees.teamFee).div(totalFees);
		if (ethForTeam > 0) {
			payable(_teamWalletAddress).transfer(ethForTeam);
		}

		// Fourth: Buyback
		uint256 ethForBuyback = amountOut.mul(buyFees.buyBackFee).div(totalFees);
		if (isBuybackEnabled && ethForBuyback > 0 && ethForBuyback > minimumETHbuyback) {
		    if (ethForBuyback > maximumETHbuyback) {
		        ethForBuyback = maximumETHbuyback;
		    }
		    swapExactETHForTokens(ethForBuyback, address(this));
		}
		else {
		    ethForBuyback = 0;
		}
		
		// Last: Liquidity
		uint256 ethForLiquidity = amountOut.sub(totalEthForDividends);
		        // Avoid stack too deep error
		        ethForLiquidity = ethForLiquidity.sub(ethForMarketing).sub(ethForTeam).sub(ethForBuyback);
		if (ethForLiquidity > 0) {
			swapAndLiquify(ethForLiquidity);
		}
	}

	function swapAndSendDividends(uint256 amountIn1, uint256 amountIn2, uint256 amountIn3) private {
	    // We send a mass event to reduce costs
	    bool emitMassEvent = false;
	    
	    // Following code is ugly, but it works!
	    uint256 dividends1;
	    if (amountIn1 > 0) {
    	    dividends1 = swapExactETHForTokens(amountIn1, dividendTracker1Token);
    		bool success1 = IERC20(dividendTracker1Token).transfer(address(dividendTracker1), dividends1);
    
    		if (success1) {
    			dividendTracker1.distributeTokenDividends(dividends1); 
    			emitMassEvent = true;
    		}
    		else {
    		    dividends1 = 0;
    		}
	    }
	    
	    uint256 dividends2;
	    if (amountIn2 > 0) {
    	    dividends2 = swapExactETHForTokens(amountIn2, dividendTracker2Token);
    		bool success2 = IERC20(dividendTracker2Token).transfer(address(dividendTracker2), dividends2);
    
    		if (success2) {
    			dividendTracker2.distributeTokenDividends(dividends2);
    			emitMassEvent = true;
    		}
    		else {
    		    dividends2 = 0;
    		}
	    }
	    
	    uint256 dividends3;
	    if (amountIn3 > 0) {
    	    dividends3 = swapExactETHForTokens(amountIn3, dividendTracker3Token);
    		bool success3 = IERC20(dividendTracker3Token).transfer(address(dividendTracker3), dividends3);
    
    		if (success3) {
    			dividendTracker3.distributeTokenDividends(dividends3);
    			emitMassEvent = true;
    		}
    		else {
    		    dividends3 = 0;
    		}
	    }
	    
	    if (emitMassEvent) {
	        emit SendDividends (amountIn1, dividends1, amountIn2, dividends2, amountIn3, dividends3);
	    }
	}

	function swapAndLiquify(uint256 amountIn) private {
		uint256 halfForEth = amountIn.div(2);
		uint256 halfForTokens = amountIn.sub(halfForEth);

		uint256 tokensOut = swapExactETHForTokens(halfForTokens, address(this));
		_approve(address(this), address(uniswapV2Router), tokensOut);
		uniswapV2Router.addLiquidityETH{value: halfForEth}(address(this), tokensOut, 0, 0, owner(), block.timestamp);
	}

	function swapExactTokensForETH(uint256 amountIn) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), amountIn);

		uint256 previousBalance = address(this).balance;
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp);
		return address(this).balance.sub(previousBalance);
	}

	function swapExactETHForTokens(uint256 amountIn, address tokenAddress) private returns (uint256) {
		return _transferHelper.buy{value: amountIn}(tokenAddress);
	}

	function recover() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
	
	function manualBuyback(uint256 amount) external onlyOwner {
	    require (amount > 0, "Amount must be greater than zero");
	    require (amount <= address(this).balance, "You cannot spend more than the contract's balance");
	    require (!_swapping, "Swapping currently in place, try later.");
	    _swapping = true;
	    swapExactETHForTokens(amount, address(this));
	    _swapping = false;
	}
	
	function manualAddLiquidity(uint256 amount) external onlyOwner {
	    require (amount > 0, "Amount must be greater than zero");
	    require (amount <= address(this).balance, "You cannot spend more than the contract's balance");
	    require (!_swapping, "Swapping currently in place, try later.");
	    
	    _swapping = true;
	    uint256 halfForEth = amount.div(2);
		uint256 halfForTokens = amount.sub(halfForEth);
		uint256 tokensOut = swapExactETHForTokens(halfForTokens, address(this));
		
		_approve(address(this), address(uniswapV2Router), tokensOut);
		
		uniswapV2Router.addLiquidityETH{value: halfForEth}(address(this), tokensOut, 0, 0, owner(), block.timestamp);
        _swapping = false;
	}
	
	// Presale utility functions
	function prepareForPresale() external onlyOwner {
	    setBuyFees(0, 0, 0, 0, 0, 0, 0);
	    setSellFees(0, 0, 0, 0, 0, 0, 0); 
	    maxWalletAmount = 100000000000 * (10 ** 18);
	    maxTxAmount = 100000000000 * (10 ** 18);
	    checkMaximumWalletLimit = false;
        isBuybackEnabled = false;
        isSwapEnabled = false;
	}
	
	function prepareForLaunch() external onlyOwner {
	    setBuyFees(4, 1, 3, 3, 1, 1, 1);
	    setSellFees(4, 1, 3, 3, 1, 1, 1); 
	    maxWalletAmount = 336000000 * (10 ** 18); // 0.336%
	    maxTxAmount = 168000000 * (10 ** 18); // 0.168%
	    checkMaximumWalletLimit = true;
        isBuybackEnabled = false;
        isSwapEnabled = true;
	}
	
	function setPresaleAddresses(address preSaleLPRouter, address preSaleContract) external onlyOwner {
        if (_preSaleLPRouter != preSaleLPRouter) {
	        _preSaleLPRouter = preSaleLPRouter;
	        excludeFromDividends(_preSaleLPRouter, true);
	        includeInWhitelist(_preSaleLPRouter, true);
        }
        
        if (_preSaleContract != preSaleContract) {
	        _preSaleContract = preSaleContract;
	        excludeFromDividends(_preSaleContract, true);
	        includeInWhitelist(_preSaleContract, true);
        }
	}	
}