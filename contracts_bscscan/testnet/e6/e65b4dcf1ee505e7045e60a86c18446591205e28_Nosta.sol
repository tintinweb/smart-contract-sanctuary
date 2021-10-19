/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
     *Submitted for verification at BscScan.com on 2021-05-30
    */
    
    // SPDX-License-Identifier: MIT
    
    /**
     * 
     * Have fun with NOSTA!
     * 
     * Original features include referencing influencers and members.
     * Influencers get paid charity fees of every transactions of their members.
     * Members get burn fees divided by 2 when registered.
     * 
     */
    
    pragma solidity ^0.8.2;
    
    abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return payable(msg.sender);
        }
    
        function _msgData() internal view virtual returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }

    /**
     * @dev Interface of the BEP20 standard as defined in the EIP.
     */
    interface IBEP20 {
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
    
    /**
     * @title SafeMathInt
     * @dev Math operations with safety checks that revert on error
     * @dev SafeMath adapted for int256
     * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
     */
    library SafeMathInt {
      function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
    
        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
      }
    
      function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));
    
        return a / b;
      }
    
      function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
    
        return a - b;
      }
    
      function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
      }
    
      function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
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
    
    /// @title Dividend-Paying Token Optional Interface
    /// @author Roger Wu (https://github.com/roger-wu)
    /// @dev OPTIONAL functions for a dividend-paying token contract.
    interface IDividendPayingTokenOptional {
      /// @notice View the amount of dividend in wei that an address can withdraw.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` can withdraw.
      function withdrawableDividendOfPart(address _owner) external view returns(uint256);
      function withdrawableDividendOfHolder(address _owner) external view returns(uint256);     
      /// @notice View the amount of dividend in wei that an address has withdrawn.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` has withdrawn.
      function withdrawnDividendOfHolder(address _owner) external view returns(uint256);
      function withdrawnDividendOfPart(address _owner) external view returns(uint256);
      
      /// @notice View the amount of dividend in wei that an address has earned in total.
      /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` has earned in total.
      function accumulativeDividendOfHolders(address _owner) external view returns(uint256);
      function accumulativeDividendOfPart(address _owner) external view returns(uint256);
    }
    
    /// @title Dividend-Paying Token Interface
    /// @author Roger Wu (https://github.com/roger-wu)
    /// @dev An interface for a dividend-paying token contract.
    interface IDividendPayingToken {
      /// @notice View the amount of dividend in wei that an address can withdraw.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` can withdraw.
      function dividendOfHolder(address _owner) external view returns(uint256);
      function dividendOfPart(address _owner) external view returns(uint256);
    
      /// @notice Distributes ether to token holders as dividends.
      /// @dev SHOULD distribute the paid ether to token holders as dividends.
      ///  SHOULD NOT directly transfer ether to token holders in this function.
      ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
      function distributeDividends() external payable;
    
      /// @notice Withdraws the ether distributed to the sender.
      /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
      ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
      function withdrawDividendOfPart() external;
      function withdrawDividendOfHolder() external;
      
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
            // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
            // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
            // for accounts without code, i.e. `keccak256('')`
            bytes32 codehash;
            bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
            // solhint-disable-next-line no-inline-assembly
            assembly { codehash := extcodehash(account) }
            return (codehash != accountHash && codehash != 0x0);
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
    
            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = recipient.call{ value: amount }("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    
        /**
         * @dev Performs a Solidity function call using a low level `call`. A
         * plain`call` is an unsafe replacement for a function call: use this
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
        function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
            return _functionCallWithValue(target, data, 0, errorMessage);
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
        function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        }
    
        /**
         * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
         * with `errorMessage` as a fallback revert reason when `target` reverts.
         *
         * _Available since v3.1._
         */
        function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
            require(address(this).balance >= value, "Address: insufficient balance for call");
            return _functionCallWithValue(target, data, value, errorMessage);
        }
    
        function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
            require(isContract(target), "Address: call to non-contract");
    
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
            if (success) {
                return returndata;
            } else {
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
    
                    // solhint-disable-next-line no-inline-assembly
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

    // IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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
    
    // IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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
    
    // IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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
    
    // IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol 
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
    contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
        /**
         * @dev Initializes the contract setting the deployer as the initial owner.
         */
        constructor() {
            _owner = _msgSender();
            _transferOwnership(_msgSender());
        }
    
        /**
         * @dev Returns the address of the current owner.
         */
        function owner() public view virtual returns (address) {
            return _owner;
        }
    
        /**
         * @dev Throws if called by any account other than the owner.
         */
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
            _transferOwnership(address(0));
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account (`newOwner`).
         * Can only be called by the current owner.
         */
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _transferOwnership(newOwner);
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account (`newOwner`).
         * Internal function without access restriction.
         */
        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }
    
    contract ERC20 is Context, IBEP20 {
        using SafeMath for uint256;
    
        mapping (address => uint256) private _balances;
    
        mapping (address => mapping (address => uint256)) private _allowances;
    
        uint256 private _totalSupply;
    
        string private _name;
        string private _symbol;
        uint8 private _decimals;
    
        /**
         * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
         * a default value of 18.
         *
         * To select a different value for {decimals}, use {_setupDecimals}.
         *
         * All three of these values are immutable: they can only be set once during
         * construction.
         */
        constructor (string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
            _decimals = 18;
        }
    
        /**
         * @dev Returns the name of the token.
         */
        function name() public view virtual returns (string memory) {
            return _name;
        }
    
        /**
         * @dev Returns the symbol of the token, usually a shorter version of the
         * name.
         */
        function symbol() public view virtual returns (string memory) {
            return _symbol;
        }
    
        /**
         * @dev Returns the number of decimals used to get its user representation.
         * For example, if `decimals` equals `2`, a balance of `505` tokens should
         * be displayed to a user as `5,05` (`505 / 10 ** 2`).
         *
         * Tokens usually opt for a value of 18, imitating the relationship between
         * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
         * called.
         *
         * NOTE: This information is only used for _display_ purposes: it in
         * no way affects any of the arithmetic of the contract, including
         * {IERC20-balanceOf} and {IERC20-transfer}.
         */
        function decimals() public view virtual returns (uint8) {
            return _decimals;
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
        function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
         * - `to` cannot be the zero address.
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
        function _approve(address owner, address spender, uint256 amount) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
    
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    
        /**
         * @dev Sets {decimals} to a value other than the default one of 18.
         *
         * WARNING: This function should only be called from the constructor. Most
         * applications that interact with token contracts will not expect
         * {decimals} to ever change, and may work incorrectly if it does.
         */
        function _setupDecimals(uint8 decimals_) internal virtual {
            _decimals = decimals_;
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
        function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    }
    
    /// @title Dividend-Paying Token
    /// @author Roger Wu (https://github.com/roger-wu)
    /// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
    ///  to token holders as dividends and allows token holders to withdraw their dividends.
    ///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
    contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional {
      using SafeMath for uint256;
      using SafeMathUint for uint256;
      using SafeMathInt for int256;
    
      // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
      // For more discussion about choosing the value of `magnitude`,
      //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
      uint256 constant internal magnitude = 2**128;
    
      uint256 internal magnifiedDividendPerShareHolders;
      uint256 internal magnifiedDividendPerSharePart;
      uint256 internal lastAmount;
      
      address public immutable BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD TESTNET
      //address public immutable BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
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
    
      constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
      
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
      function distributeDividends() public override payable {
        require(totalSupply() > 0);
        uint256 supply_parts    = (totalSupply().mul(2)).div(3);
        uint256 supply_holders  = totalSupply().div(3);
        
        uint256 amount_parts    = (msg.value.mul(2)).div(3);
        uint256 amount_holders  = msg.value.div(3);
        
        if (msg.value > 0) {
          magnifiedDividendPerShareHolders = magnifiedDividendPerShareHolders.add(
            (amount_holders).mul(magnitude) / supply_holders
          );
          magnifiedDividendPerSharePart    = magnifiedDividendPerSharePart.add(
            (amount_parts).mul(magnitude) / supply_parts
          );
          
          emit DividendsDistributed(msg.sender, msg.value);
    
          totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
      }
      
    
      function distributeBusdDividends(uint256 amount, bool _isPart) public {
        require(totalSupply() > 0);
        uint256 supply_parts    = (totalSupply().mul(2)).div(3);
        uint256 supply_holders  = totalSupply().div(3);
        
        uint256 amount_parts    = (amount.mul(2)).div(3);
        uint256 amount_holders  = amount.div(3);
        
        if (amount > 0) {
            if(_isPart){
                magnifiedDividendPerSharePart = magnifiedDividendPerSharePart.add(
                (amount_parts).mul(magnitude) / supply_parts
                );
            }else {
                magnifiedDividendPerShareHolders = magnifiedDividendPerShareHolders.add(
                (amount_holders).mul(magnitude) / supply_holders
                );
            }
          
          emit DividendsDistributed(msg.sender, amount);
    
          totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
      }
    
      /// @notice Withdraws the ether distributed to the sender.
      /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
      function withdrawDividendOfHolder() public virtual override {
        _withdrawDividendOfHolder(_msgSender());
      }
    
      /// @notice Withdraws the ether distributed to the sender.
      /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
      function _withdrawDividendOfHolder(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOfHolder(user);
        if (_withdrawableDividend > 0) {
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          bool success = ERC20(BUSD).transfer(user, _withdrawableDividend);
    
          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
    
          return _withdrawableDividend;
        }
    
        return 0;
      }
      
      /// @notice Withdraws the ether distributed to the sender.
      /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
      function withdrawDividendOfPart() public virtual override {
        _withdrawDividendOfPart(_msgSender());
      }
    
      /// @notice Withdraws the ether distributed to the sender.
      /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
      function _withdrawDividendOfPart(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOfPart(user);
        if (_withdrawableDividend > 0) {
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          bool success = ERC20(BUSD).transfer(user, _withdrawableDividend);
    
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
      function dividendOfHolder(address _owner) public view override returns(uint256) {
        return withdrawableDividendOfHolder(_owner);
      }
    
    /// @notice View the amount of dividend in wei that an address can withdraw.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` can withdraw.
      function dividendOfPart(address _owner) public view override returns(uint256) {
        return withdrawableDividendOfPart(_owner);
      }
      
      /// @notice View the amount of dividend in wei that an address can withdraw.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` can withdraw.
      function withdrawableDividendOfHolder(address _owner) public view override returns(uint256) {
        return accumulativeDividendOfHolders(_owner).sub(withdrawnDividends[_owner]);
      }
    
      /// @notice View the amount of dividend in wei that an address has withdrawn.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` has withdrawn.
      function withdrawnDividendOfHolder(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
      }
    
        /// @notice View the amount of dividend in wei that an address can withdraw.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` can withdraw.
      function withdrawableDividendOfPart(address _owner) public view override returns(uint256) {
        return accumulativeDividendOfPart(_owner).sub(withdrawnDividends[_owner]);
      }
    
      /// @notice View the amount of dividend in wei that an address has withdrawn.
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` has withdrawn.
      function withdrawnDividendOfPart(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
      }
    
      /// @notice View the amount of dividend in wei that an address has earned in total.
      /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
      /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
      /// @param _owner The address of a token holder.
      /// @return The amount of dividend in wei that `_owner` has earned in total.
      function accumulativeDividendOfHolders(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShareHolders.mul(balanceOf(_owner)).toInt256Safe()
          .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
      }
    
      function accumulativeDividendOfPart(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerSharePart.mul(balanceOf(_owner)).toInt256Safe()
          .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
      }
      /// @dev Internal function that transfer tokens from one address to another.
      /// Update magnifiedDividendCorrections to keep dividends unchanged.
      /// @param from The address to transfer from.
      /// @param to The address to transfer to.
      /// @param value The amount to be transferred.
      function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);
    
        int256 _magCorrection = (magnifiedDividendPerShareHolders.add(magnifiedDividendPerSharePart)).mul(value).toInt256Safe();
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
          .sub( (magnifiedDividendPerShareHolders.add(magnifiedDividendPerSharePart).mul(value)).toInt256Safe() );
      }
    
      /// @dev Internal function that burns an amount of the token of a given account.
      /// Update magnifiedDividendCorrections to keep dividends unchanged.
      /// @param account The account whose tokens will be burnt.
      /// @param value The amount that will be burnt.
      function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
    
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
          .add( (magnifiedDividendPerShareHolders.add(magnifiedDividendPerSharePart).mul(value)).toInt256Safe() );
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
    
    contract NostaBUSDDividendTracker is DividendPayingToken, Ownable {
        using SafeMath for uint256;
        using SafeMathInt for int256;
        using IterableMapping for IterableMapping.Map;
    
        IterableMapping.Map private tokenHoldersMap;
        IterableMapping.Map private tokenPartMap;

        uint256 public lastProcessedIndex;
    
        mapping (address => bool) public excludedFromDividends;
    
        mapping (address => uint256) public lastClaimTimes;
    
        uint256 public claimWait;
        uint256 public immutable minimumTokenBalanceForDividends;
    
        event ExcludeFromDividends(address indexed account);
        event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    
        event Claim(address indexed account, uint256 amount, bool indexed automatic);
    
        constructor()  DividendPayingToken("NostaBUSD_Dividend_Tracker", "NostaBUSD_Dividend_Tracker") {
        	claimWait = 3600;
            minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
        }
    
        function _transfer(address, address, uint256) internal pure override {
            require(false, "NostaBUSD_Dividend_Tracker: No transfers allowed");
        }
    
        function withdrawDividendOfPart() public pure override {
            require(false, "NostaBUSD_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main NostaBUSD contract.");
        }
        function withdrawDividendOfHolder() public pure override {
            require(false, "NostaBUSD_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main NostaBUSD contract.");
        }
    
        function excludeFromDividends(address account, bool _isPart) external onlyOwner {
        	require(!excludedFromDividends[account]);
        	excludedFromDividends[account] = true;
    
        	_setBalance(account, 0);
        	
        	if(_isPart){
        	    tokenPartMap.remove(account);
        	}else {
        	    tokenHoldersMap.remove(account);
        	}

        	emit ExcludeFromDividends(account);
        }
    
        function updateClaimWait(uint256 newClaimWait) external onlyOwner {
            require(newClaimWait >= 3600 && newClaimWait <= 86400, "NostaBUSD_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
            require(newClaimWait != claimWait, "NostaBUSD_Dividend_Tracker: Cannot update claimWait to same value");
            emit ClaimWaitUpdated(newClaimWait, claimWait);
            claimWait = newClaimWait;
        }
    
        function getLastProcessedIndex() external view returns(uint256) {
        	return lastProcessedIndex;
        }
    
        function getNumberOfTokenHolders() external view returns(uint256) {
            return tokenHoldersMap.keys.length;
        }
    
        function getNumberOfTokenPart() external view returns(uint256) {
            return tokenPartMap.keys.length;
        }
        
        function getAccountHolder(address _account)
            private view returns (
                address account,
                int256 index,
                int256 iterationsUntilProcessed,
                uint256 withdrawableDividends,
                uint256 totalDividends,
                uint256 lastClaimTime,
                uint256 nextClaimTime,
                uint256 secondsUntilAutoClaimAvailable) {
                    
                index = tokenHoldersMap.getIndexOfKey(_account);
    
                iterationsUntilProcessed = -1;
        
                if(index >= 0) {
                    if(uint256(index) > lastProcessedIndex) {
                        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
                    }
                    else {
                        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                                tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                                0;
        
        
                        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
                    }
                }
        
        
                withdrawableDividends = withdrawableDividendOfHolder(account);
                totalDividends = accumulativeDividendOfHolders(account);
        
                lastClaimTime = lastClaimTimes[account];
        
                nextClaimTime = lastClaimTime > 0 ?
                                            lastClaimTime.add(claimWait) :
                                            0;
        
                secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                            nextClaimTime.sub(block.timestamp) :
                                                            0;
        }
                
        function getAccountPart(address _account)
            private view returns (
                address account,
                int256 index,
                int256 iterationsUntilProcessed,
                uint256 withdrawableDividends,
                uint256 totalDividends,
                uint256 lastClaimTime,
                uint256 nextClaimTime,
                uint256 secondsUntilAutoClaimAvailable) {
                    
                index = tokenPartMap.getIndexOfKey(_account);
    
                iterationsUntilProcessed = -1;
        
                if(index >= 0) {
                    if(uint256(index) > lastProcessedIndex) {
                        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
                    }
                    else {
                        uint256 processesUntilEndOfArray = tokenPartMap.keys.length > lastProcessedIndex ?
                                                                tokenPartMap.keys.length.sub(lastProcessedIndex) :
                                                                0;
        
        
                        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
                    }
                }
        
        
                withdrawableDividends = withdrawableDividendOfPart(account);
                totalDividends = accumulativeDividendOfPart(account);
        
                lastClaimTime = lastClaimTimes[account];
        
                nextClaimTime = lastClaimTime > 0 ?
                                            lastClaimTime.add(claimWait) :
                                            0;
        
                secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                            nextClaimTime.sub(block.timestamp) :
                                                            0;
        }
        
        function getAccountAtIndex(uint256 index, bool _isPart)
            public view returns (
                address,
                int256,
                int256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256) {
        	
        	if(_isPart){
        	    if(index >= tokenPartMap.size()) {
                    return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
                }
    
                address account = tokenPartMap.getKeyAtIndex(index);
                return getAccountPart(account);
                
        	} else{
        	    if(index >= tokenHoldersMap.size()) {
                return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
            }
    
                address account = tokenHoldersMap.getKeyAtIndex(index);
                return getAccountHolder(account);
        	}
        }
    
        function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        	if(lastClaimTime > block.timestamp)  {
        		return false;
        	}
    
        	return block.timestamp.sub(lastClaimTime) >= claimWait;
        }
    
        function setBalance(address payable account, uint256 newBalance, bool _isPart) external onlyOwner {
        	if(excludedFromDividends[account]) {
        		return;
        	}
    
        	if(newBalance >= minimumTokenBalanceForDividends) {
                _setBalance(account, newBalance);
                if(_isPart){
                    tokenPartMap.set(account, newBalance);
                }else {
                    tokenHoldersMap.set(account, newBalance);
                }
        	}
        	else {
                _setBalance(account, 0);
                if(_isPart){
                    tokenPartMap.remove(account);
                }else {
                    tokenHoldersMap.remove(account);
                }
        	}
            if(_isPart) processAccount(account, true, true); 
            else processAccount(account, true, false);
        	
        }
    
        function processHolders(uint256 gas) public returns (uint256, uint256, uint256) {
        	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
    
        	if(numberOfTokenHolders == 0) {
        		return (0, 0, lastProcessedIndex);
        	}
    
        	uint256 _lastProcessedIndex = lastProcessedIndex;
    
        	uint256 gasUsed = 0;
    
        	uint256 gasLeft = gasleft();
    
        	uint256 iterations = 0;
        	uint256 claims = 0;
    
        	while(gasUsed < gas && iterations < numberOfTokenHolders) {
        		_lastProcessedIndex++;
    
        		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        			_lastProcessedIndex = 0;
        		}
    
        		address account = tokenHoldersMap.keys[_lastProcessedIndex];
    
        		if(canAutoClaim(lastClaimTimes[account])) {
        			if(processAccount(payable(account), true, false)) {
        				claims++;
        			}
        		}
    
        		iterations++;
    
        		uint256 newGasLeft = gasleft();
    
        		if(gasLeft > newGasLeft) {
        			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
        		}
    
        		gasLeft = newGasLeft;
        	}
    
        	lastProcessedIndex = _lastProcessedIndex;
    
        	return (iterations, claims, lastProcessedIndex);
        }
        
        function processPart(uint256 gas) public returns (uint256, uint256, uint256) {
        	uint256 numberOfTokenPart = tokenPartMap.keys.length;
    
        	if(numberOfTokenPart == 0) {
        		return (0, 0, lastProcessedIndex);
        	}
    
        	uint256 _lastProcessedIndex = lastProcessedIndex;
    
        	uint256 gasUsed = 0;
    
        	uint256 gasLeft = gasleft();
    
        	uint256 iterations = 0;
        	uint256 claims = 0;
    
        	while(gasUsed < gas && iterations < numberOfTokenPart) {
        		_lastProcessedIndex++;
    
        		if(_lastProcessedIndex >= tokenPartMap.keys.length) {
        			_lastProcessedIndex = 0;
        		}
    
        		address account = tokenPartMap.keys[_lastProcessedIndex];
    
        		if(canAutoClaim(lastClaimTimes[account])) {
        			if(processAccount(payable(account), true, true)) {
        				claims++;
        			}
        		}
    
        		iterations++;
    
        		uint256 newGasLeft = gasleft();
    
        		if(gasLeft > newGasLeft) {
        			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
        		}
    
        		gasLeft = newGasLeft;
        	}
    
        	lastProcessedIndex = _lastProcessedIndex;
    
        	return (iterations, claims, lastProcessedIndex);
        }
    
        function processAccount(address payable account, bool automatic, bool _isPart) public onlyOwner returns (bool) {
            uint256 amount;
            if(_isPart){
                amount = _withdrawDividendOfPart(account);
            } else {
                amount = _withdrawDividendOfHolder(account);
            }
        	if(amount > 0) {
        		lastClaimTimes[account] = block.timestamp;
                emit Claim(account, amount, automatic);
        		return true;
        	}
    
        	return false;
        }
    }

    contract Nosta is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    // General Info
    string  private _NAME     = "Test";
    string  private _SYMBOL   = "TEST";
    uint256 private _DECIMALS = 18;
    
    // Liquidity Settings
    IUniswapV2Router02 public _pancakeswapV2Router; // The address of the PancakeSwap V2 Router
    address public _pancakeswapV2LiquidityPair;    
    bool public currentlySwapping;
    bool public _enableLiquidity  = false; // Controls whether the contract will swap tokens
        
    // Balances
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // Blacklist if TP
    mapping(address => bool) public _isBlacklisted;

    // Exclusions
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    // NOSTA original feature: members and influencers addresses
    mapping (address => uint256) private _influencers;
    mapping (address => bool) private _isInfluencer;
    mapping (address => address) private _members;
    
    // BUSD tracker for rewards holders and Partenaires
    NostaBUSDDividendTracker public dividendTracker;
    
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    
    // addresses
	address payable public _burnAddress      = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
    address payable public _wallet_supply    = payable(0x683f5C7a783a6C621094689a9b234Cf22aDCBdd7); // Wallet Supply-team (là où nous enverrons les tokens à la création du smartcontract avant d'airdrop la v2)
    address payable public _wallet_part      = payable(0xbFc9B7F6352C4f684c93d09e049b006f203DBbF5); // Wallet Partenaires "générique" (quand nous n'avons pas add influenceur un acheteur pour le link à un partenaire, pour les 1,5% partenaires en BUSD et 1,5% partenaires en Nosta)
    address payable public _wallet_team      = payable(0x580229A61fA58291ee518d54B7e82Df259bB0020); // Wallet Team (pour les 1% de transaction fees "Team" 
    address payable public _wallet_algo      = payable(0x301a2372486c9E70c61E750E7962f876Ec66156F); // Wallet Algo (pour les 7% transaction fees sur price impact > 2%)
    //address public immutable BUSD            = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
    address public immutable BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD TESTNET
    
    // Supply    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000 * 10**(_DECIMALS);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalReflections; // Total reflections
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tCharityTotal;
    uint256 private _tInfluencersTotal;
    uint256 private _othersPortions; // How many reflections are in the smart contract 
        
    // Token Tax Settings
    uint256 public    _TAX_TOTAL_FEE     = 8; // Total Transactions fees
    uint256 public    _CHARITY_FEE       = 3; // Transactions fees Partenaires (Nosta 1,5% et BUSD 1,5%) 
    uint256 public    _TAX_FEE           = 1; //  Transactions fees Rewards holders (Nosta 0,5% et BUSD 0,5%)
    uint256 public    _BURN_FEE          = 1; // Transactions fees Burn (Nosta) => 1%
    uint256 public    _LP_FEE            = 2; // Transactions fees LP (Nosta 1% et BUSD 1%)
    uint256 public    _TEAM_FEE          = 1; // Transactions fees team (Nosta) => 1% 
    uint256 public    _TAX_MORE_FEE      = 7; // Transactions fees Price impact (BUSD) => 7% 
    
    // Track original fees to bypass fees for charity account
    uint256 private ORIG_TAX_TOTAL_FEE = _TAX_TOTAL_FEE; 
    uint256 private ORIG_CHARITY_FEE  = _CHARITY_FEE; 
    uint256 private ORIG_TAX_FEE      = _TAX_FEE; 
    uint256 private ORIG_BURN_FEE     = _BURN_FEE; 
    uint256 private ORIG_LP_FEE       = _LP_FEE; 
    uint256 private ORIG_TEAM_FEE     = _TEAM_FEE;
    uint256 private ORIG_TAX_MORE_FEE = _TAX_MORE_FEE;
    
    // Timer Constants 
    uint256 private constant TWO_DAYS = 86400 * 2; // How many seconds in two days
    
    // Anti-Whale Settings (price impact)
    uint256    public _whaleSellTimer     = TWO_DAYS;  // 48 hours
    mapping (address => uint256) private _amountSold;
    mapping (address => uint) private _timeLastSell;
    
    // Token Limits
    uint256 public _tokenSwapThreshold = 100 * 10**9 * 10**9; // 100 billion
        
    // Events 
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);  
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex,
        bool indexed automatic, uint256 gas, address indexed processor
    );
    
    event Watch1(address _from, address _to);
    event Watch2(address _from, address _to);
    event Watch3(uint256 _price_impact, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    event Watch4(string _msg);
    event Watch5(address[] _path);
    event Watch6(string _msg, uint256 tax); 
    
    // Modifiers 
    modifier lockSwapping {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }
          
    constructor () {
        // Mint the total reflection balance to the deployer of this contract
        _rOwned[_msgSender()] = _rTotal;
            
        // Exclude the owner and the contract from paying fees
        _isExcludedFromFees[_msgSender()]   = true;
        _isExcludedFromFees[address(this)]  = true;
        _isExcludedFromFees[_wallet_supply] = true;
        _isExcludedFromFees[_wallet_part]   = true;
        _isExcludedFromFees[_wallet_team]   = true;
        _isExcludedFromFees[_wallet_algo]   = true;
		
        // PANCAKE ROUTER V2 TESTNET
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    	// PANCAKE ROUTER V2 LIVENET
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), BUSD);

        _pancakeswapV2Router          = _uniswapV2Router;
        _pancakeswapV2LiquidityPair   = _uniswapV2Pair;

        // BUSD Dividends tracker
        dividendTracker = new NostaBUSDDividendTracker();
        
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker), false);
        dividendTracker.excludeFromDividends(address(this), false);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router), false);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    /**
    * @notice Required to recieve BNB from PancakeSwap V2 Router when swaping
    */
    receive() external payable {}
    
    /**
    * @notice Withdraws BNB from the contract
    */
    function withdrawBNB(uint256 amount) public onlyOwner() {
        if(amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }
        
    /**
    * @notice Withdraws non-Nosta tokens that are stuck as to not interfere with the liquidity
    */
    function withdrawForeignToken(address token) public onlyOwner() {
        require(address(this) != address(token), "Cannot withdraw native token");
        IBEP20(address(token)).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
    }
    
    /**
    * @notice Allows the contract to change the router, in the instance when PancakeSwap upgrades making the contract future proof
    */
    function setRouterAddress(address router) public onlyOwner() {
        // Connect to the new router
        IUniswapV2Router02 newPancakeSwapRouter = IUniswapV2Router02(router);
            
        // Grab an existing pair, or create one if it doesnt exist
        address newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).getPair(address(this), newPancakeSwapRouter.WETH());
        if(newPair == address(0)){
            newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).createPair(address(this), newPancakeSwapRouter.WETH());
        }
        _pancakeswapV2LiquidityPair = newPair;
    
        _pancakeswapV2Router = newPancakeSwapRouter;
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "NostaBUSD: The dividend tracker already has that address");

        NostaBUSDDividendTracker newDividendTracker = NostaBUSDDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "NostaBUSD: The new dividend tracker must be owned by the NostaBUSD token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker), false);
        newDividendTracker.excludeFromDividends(address(this), false);
        newDividendTracker.excludeFromDividends(address(_pancakeswapV2Router), false);

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }
    
    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint256) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TOKEN20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TOKEN20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }
        
    function isExcludedFromReflection(address account) external view returns(bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    
    function totalCharity() public view returns (uint256) {
        return _tCharityTotal;
    }

    //NOSTA: return total fees distributed to influencers
    function totalInfluencers() public view returns (uint256) {
        return _tInfluencersTotal;
    }
    
    function setTokenSwapThreshold(uint256 tokenSwapThreshold) external onlyOwner() {
        _tokenSwapThreshold = tokenSwapThreshold;
    }
    
    /**
    * @notice Allows a user to voluntarily reflect their tokens to everyone else
    */
    function reflect(uint256 tAmount) public {
        require(!_isExcluded[_msgSender()], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _totalReflections = _totalReflections.add(tAmount);
    }

   /**
    * @notice Excludes an address from receiving reflections
    */
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    
    /**
    * @notice Includes an address back into the reflection system
    */
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = true;
    }
        
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = false;
    }
    
    // NOSTA: changing burn to Only Owner
	function burn(uint256 _value) external onlyOwner() {
		_burnTokens(_value);
	}
	
	function updateFee(uint256 _tx_charityFee, uint256 _txFee, uint256 _burnFee, uint256 _teamFee, uint256 _moreTxFee, uint256 _LPFee) onlyOwner() public{
		_CHARITY_FEE       = _tx_charityFee; 
        _TAX_FEE           = _txFee; 
        _BURN_FEE          = _burnFee; 
        _TEAM_FEE          = _teamFee;
        _LP_FEE            = _LPFee;
        _TAX_MORE_FEE      = _moreTxFee; 
        _TAX_TOTAL_FEE     = _CHARITY_FEE.add(_TAX_FEE).add(_BURN_FEE).add(_TEAM_FEE).add(_LP_FEE);

        ORIG_CHARITY_FEE   = _CHARITY_FEE; 
        ORIG_TAX_FEE       = _TAX_FEE; 
        ORIG_BURN_FEE      = _BURN_FEE; 
        ORIG_TEAM_FEE      = _TEAM_FEE;
        ORIG_LP_FEE        = _LP_FEE; 
        ORIG_TAX_MORE_FEE  = _TAX_MORE_FEE;
        ORIG_TAX_TOTAL_FEE = _TAX_TOTAL_FEE;
	}


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
    * @notice Converts a token value to a reflection value
    */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    
    /**
    * @notice Converts a reflection value to a token value
    */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    /**
    * @notice Calculates transfer token values
    */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_TAX_TOTAL_FEE).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    
    /**
    * @notice Calculates transfer reflection values
    */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    /**
    * @notice Handles the before and after of a token transfer, such as taking fees and firing off a swap and liquify event
    */
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        
        
        // ANTI-WHALE BLACKLIST
        // BUY
        if (from == _pancakeswapV2LiquidityPair) {
            // Blacklist when last time sell < 48 H (TP)   
            // Get the time difference in seconds between now and the last sell
            uint delta = block.timestamp.sub(_timeLastSell[from]);
                
            // If the last time of sell < 48H then blacklist the _msgSender  
            if (delta > 0 && delta <= TWO_DAYS) {
                // blacklist; 
                _isBlacklisted[from] = true;
                revert();
            }else {
                _isBlacklisted[from] = false;
            }
            
            takeFee = false;
        }
        
        // Gets the contracts tokens balance for buybacks, charity, liquidity and marketing
        uint256 tokenBalance = balanceOf(address(this));
        
        // AUTO-LIQUIDITY MECHANISM
        // Check that the contract balance has reached the threshold required to execute a swap and liquify event
        // Do not execute the swap and liquify if there is already a swap happening
        // Do not allow the adding of liquidity if the sender is the PancakeSwap V2 liquidity pool
        if (_enableLiquidity && tokenBalance >= _tokenSwapThreshold && !currentlySwapping && from != _pancakeswapV2LiquidityPair) {
            tokenBalance = _tokenSwapThreshold;
            swapAndLiquify(tokenBalance);
        }
            
        // SELL NOT OWNER 
        // If any account belongs to _isExcludedFromFee account then remove the fee
        takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
        
        
        if (takeFee && to == _pancakeswapV2LiquidityPair) {
            // We will assume that the normal sell tax rate will apply
            if(takeFee){
                uint256 fee = _TAX_TOTAL_FEE;
                emit Watch1(from, to);
    
                // if price impact is more than 2% then tax more fees (7%)
                if (_priceImpactTax(amount)) {
                    fee = _TAX_TOTAL_FEE.add(_TAX_MORE_FEE);
                } 
                            
                // Set the tax rate to the sell tax rate, if the price impact sell tax rate applies then we set that
                ORIG_TAX_FEE = _TAX_TOTAL_FEE;
                _TAX_TOTAL_FEE = fee;
                emit Watch6("_TAX_TOTAL_FEE = ", _TAX_TOTAL_FEE);
            }
            
            _isBlacklisted[from] = true;
            _timeLastSell[from] = block.timestamp;
                
            emit Watch4("_transfer : _isBlacklisted");
            
            swapAndSendToFee(_othersPortions);  
                
            emit Watch4("_transfer : swapAndSendToFee");
        }
        
        
        
        // Remove fees completely from the transfer if either wallet are excluded
        if (!takeFee) {
            emit Watch4("_transfer !takeFee : 2197");
            removeAllFees();
        }
        
        _tokenTransfer(from, to, amount);
        
            
        // If we removed the fees for this transaction, then restore them for future transactions
        if (!takeFee) {
            emit Watch4("_transfer !takeFee : 2206");
            restoreAllFees();
        }
            
        // If this transaction was a sell, and we took a fee, restore the fee amount back to the original buy amount
        if (takeFee && to == _pancakeswapV2LiquidityPair) {
            emit Watch4("_transfer !takeFee : 2112");
            _TAX_TOTAL_FEE = ORIG_TAX_FEE;
        }
        
        try dividendTracker.setBalance(payable(from), balanceOf(from), _isInfluencer[from]) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to), _isInfluencer[from]) {} catch {}

        if(!currentlySwapping) {
            emit Watch4("_transfer !currentlySwapping : 2220");

	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.processHolders(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
	    	
	    	try dividendTracker.processPart(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }
        
    /**
    * @notice Handles the actual token transfer
    */
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        // Calculate the values required to execute a transfer
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, _getRate());
            
        // Transfer from sender to recipient
    	if (_isExcluded[sender]) {
    	    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    	}
    	_rOwned[sender] = _rOwned[sender].sub(rAmount);
    		
    	if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    	}
    	_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
    		
    	if (tFee > 0) {
    	    uint256 tPortion        = tFee.div(8); // 1%
    	    uint256 tPortionNosta   = tPortion.mul(3); // 3% (1.5% Partenaires 0.5% Holders 1% LP)
    	    uint256 tPortionBUSD    = tPortion.mul(4); // 4% (1.5% Partenaires 0.5% Holders 1% LP 1% Team)

            // Burn some of the taxed tokens 
            _burnTokens(tPortion);
                
            // Reflect some of the taxed tokens 
        	_reflectTokens(tPortionNosta);
                
            // Take the rest of the taxed tokens for the other functions 
            // (Team BUSD, LP (BUSD) , Rewards BUSD, Partenaires BUSD & TAX_MORE)
            _takeTokens(tPortion.mul(4).add(tFee.sub(tPortion).sub(tPortionNosta).sub(tPortionBUSD)), tPortionBUSD);
            emit Watch2(sender, recipient);
    	}
                
        // Emit an event 
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    // TODO check if onlyOwner ??
    /**
    * @notice Burns  tokens straight to the burn address
    */
    function _burnTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rFee);
        if(_isExcluded[_burnAddress]) {
            _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tFee);
        }
    }
    
    /**
    * @notice Increases the rate of how many reflections each token is worth
    */
    function _reflectTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _totalReflections = _totalReflections.add(tFee);
    }
        
    /**
    * @notice The contract takes a portion of tokens from taxed transactions to swap them to BUSD
    */
    function _takeTokens(uint256 tTakeAmount, uint256 tOtherPortions) private {
        uint256 rTakeAmount = tTakeAmount.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
        }
        // Add a portion to get BUSD
        uint256 rOthersPortions = tOtherPortions.mul(_getRate());
        _othersPortions = _othersPortions.add(rOthersPortions);
    }
    
    function removeAllFees() private {
        if(_CHARITY_FEE == 0 && _TAX_FEE ==  0 && _BURN_FEE ==  0 && _TEAM_FEE == 0 && _TAX_MORE_FEE ==  0 && _LP_FEE ==  0 && _TAX_TOTAL_FEE == 0) return;
        
        ORIG_CHARITY_FEE   = _CHARITY_FEE; 
        ORIG_TAX_FEE       = _TAX_FEE; 
        ORIG_BURN_FEE      = _BURN_FEE; 
        ORIG_LP_FEE        = _LP_FEE; 
        ORIG_TEAM_FEE      = _TEAM_FEE;
        ORIG_TAX_MORE_FEE  = _TAX_MORE_FEE;
        ORIG_TAX_TOTAL_FEE = _TAX_TOTAL_FEE;
        
        _CHARITY_FEE       = 0; 
        _TAX_FEE           = 0; 
        _BURN_FEE          = 0; 
        _TEAM_FEE          = 0;
        _TAX_MORE_FEE      = 0;
        _LP_FEE            = 0;
        _TAX_TOTAL_FEE     = 0;
        
    }
    
    function restoreAllFees() private {
        _CHARITY_FEE      = ORIG_CHARITY_FEE;
        _TAX_FEE          = ORIG_TAX_FEE;
        _BURN_FEE         = ORIG_BURN_FEE;
        _TEAM_FEE         = ORIG_TEAM_FEE;
        _TAX_MORE_FEE     = ORIG_TAX_MORE_FEE;
        _LP_FEE           = ORIG_LP_FEE;
        _TAX_TOTAL_FEE    = ORIG_TAX_TOTAL_FEE;
    }
    
    function _getTaxFee() private view returns(uint256) {
        return _TAX_TOTAL_FEE;
    }
    
    // Check for price impact before doing transfer
    function _priceImpactTax(uint256 amount) public returns(bool) { 
        (uint256 _reserveA, uint256 _reserveB, ) = IUniswapV2Pair(_pancakeswapV2LiquidityPair).getReserves();
        uint256 _constant = IUniswapV2Pair(_pancakeswapV2LiquidityPair).kLast();
        uint256 _market_price = _reserveA.div(_reserveB);

        uint256 _reserveA_new = _reserveA.sub(amount);
        uint256 _reserveB_new = _constant.div(_reserveA_new);
        uint256 receivedBUSD = _reserveB_new.sub(_reserveB);
        
        uint256 _new_price    = (amount.div(receivedBUSD)).mul(10**_DECIMALS);
        uint256 _delta_price  = _new_price.div(_market_price);
        uint256 _portion      = uint256(1).mul(10**_DECIMALS);
        uint256 _price_impact = _portion.sub(_delta_price); 
        uint256 _price_impact_percent =  _price_impact.mul(100);
    
        return (_price_impact_percent > uint256(200).mul(10**_DECIMALS));
    }
    
    /**
    * @notice Generates BUSD by selling tokens and pairs some of the received BUSD with tokens to add and grow the liquidity pool
    */
    function swapAndSendToFee(uint256 token) private lockSwapping {
        // Capture the contract's current BUSD balance so that we know exactly the amount of BUSD that the
        // swap creates. This way the liquidity event wont include any BUSD that has been collected by other means.
        uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));
        emit Watch4("swapAndSendToFee - 2368");

        // Split the contract balance into the swap portion and the liquidity portion
        if(_TAX_TOTAL_FEE == 8){
            uint256 portion      = token.div(4);       // 1/4 of the tokens, used for liquidity
            uint256 swapAmount   = token.sub(portion); // 3/4 of the tokens, used to swap for BUSD
            emit Watch4("swapAndSendToFee - 2374");

            swapTokensForBUSD(swapAmount); 
            
            // How much BUSD did we just receive
            uint256 receivedBUSD = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
            uint256 liquidityBUSD = receivedBUSD.div(4);
            uint256 BUSDDividends = receivedBUSD.div(2);
            
            // Add liquidity via the PancakeSwap V2 Router 1% Nosta 1% BUSD 
            addLiquidity(portion, liquidityBUSD);
            
            // add to dividends 1,5% partenaires 
            sendDividendsForPart((BUSDDividends.mul(3)).div(4));
            // add to dividends 0,5% holders
            sendDividendsForHolders(BUSDDividends.div(4));
            // transfer 1% BUSD received to team wallet 
            IBEP20(BUSD).transfer(_wallet_team, liquidityBUSD);
            
            emit Watch4("swapAndSendToFee - 2393");
        }else {
            uint256 portion      = token.div(11);      // 1/11 of the tokens, used for liquidity
            uint256 swapAmount   = token.sub(portion); // 10/11 of the tokens, used to swap for BUSD
            emit Watch4("");
            swapTokensForBUSD(swapAmount); 
            
            // How much BUSD did we just receive
            uint256 receivedBUSD = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);

            uint256 liquidityBUSD = receivedBUSD.div(11);
            uint256 BUSDDividends = (receivedBUSD.mul(2)).div(11);

            // Add liquidity via the PancakeSwap V2 Router 1% Nosta 1% BUSD 
            addLiquidity(portion, liquidityBUSD);
            
            // add to dividends 1,5% partenaires 
            sendDividendsForPart(BUSDDividends.mul(3).div(4));
            // add to dividends 0,5% holders
            sendDividendsForHolders(BUSDDividends.div(4)); 
            // transfer 1% BUSD received to team wallet 
            IBEP20(BUSD).transfer(_wallet_team, liquidityBUSD);
            // transfer 1% BUSD received to algo wallet 
            IBEP20(BUSD).transfer(_wallet_algo, liquidityBUSD.mul(7));
            
            emit Watch4("watch 4 - 2");
        }
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        emit Watch4("swapAndLiquify");

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;

        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // make the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }
    
    /**
    * @notice Swap tokens for BUSD storing the resulting BUSD in the contract
    */
    function swapTokensForBUSD(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH();
        path[2] = BUSD;
        
        emit Watch5(path);

        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // make the swap
        _pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        emit Watch4("swapTokensForBUSD : fin ");
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // add the liquidity
        _pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );

    }

    function sendDividendsForHolders(uint256 tokens) private {
        uint256 dividends = ERC20(BUSD).balanceOf(address(this));
        bool success = ERC20(BUSD).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeBusdDividends(dividends, false);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function sendDividendsForPart(uint256 tokens) private {
        uint256 dividends = ERC20(BUSD).balanceOf(address(this));
        bool success = ERC20(BUSD).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeBusdDividends(dividends, true);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function enableLiquidity(bool _enable) onlyOwner public {
        _enableLiquidity = _enable;
    }
    
    /**
    *
    * NOSTA referal functions
    * 
    * addInfluencer: reference an influencer by the owner
    * registerMember: for member to register with their influencer address in parameter -> burn amount will be divided by 2 (see changes in function _getTBasics)
    * registerMemberByOwner: owner can register a member in case member has trouble doing it by himself
    * totalMembersForInfluencer: returns the number of members referenced by an influencer address in parameter
    * isMember: checks if address is member, for internal calls
    * getInfluencerForMember: returns the influencer address for a member sent in parameter
    * 
    * Note: using standard arithmetic operators, SafeMath is not reqired anymore from Solidity 0.8
    * 
    */
    
    function addInfluencer(address _influencer) external onlyOwner {
        require(!_isInfluencer[_influencer], "Address is already registered as influencer");
        _isInfluencer[_influencer] = true;
        _members[_influencer] = _influencer;
        _influencers[_influencer] += 1;
    }
    
    function registerMember(address _influencer) external {
        require(_isInfluencer[_influencer], "Address is not registered as influencer");
        require(!isMember(_msgSender()), "Member already registered");
        _members[_msgSender()] = _influencer;
        _influencers[_influencer] += 1;
    }
    
    function registerMemberByOwner(address _member, address _influencer) external onlyOwner {
        require(_isInfluencer[_influencer], "Address is not registered as influencer");
        require(!isMember(_member), "Member already registered");
        _members[_member] = _influencer;
        _influencers[_influencer] += 1;
    }
    
    function totalMembersForInfluencer(address _influencer) external view returns (uint256) {
        return _influencers[_influencer];
    }

    function isMember(address _member) private view returns (bool) {
        if (_members[_member] == address(0)) return false;
        return true;
    }

    function getInfluencerForMember(address _member) external view returns (address) {
        return _members[_member];
    }
    
    // BLACKLISTING A ADDRESS
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
}