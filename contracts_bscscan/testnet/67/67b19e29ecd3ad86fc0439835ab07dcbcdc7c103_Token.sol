/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: No License

// !!! Copyright Infringement Notice !!!
// All rights reserved
// This code is for your eyes only.
// This piece of software is not free for public to copy, use, modify or distribute.
// In-contract Mining, Virtual Mining or In-Contract Reselling is Pioneered by LittlDogecoin.
// and we reserve our rights to take action to anyone found using or implementing these features without our permission.
// Do your due diligence!
// This piece of software is publickly available for viewing only. Deploying this into mainnet is not allowed until permission is granted.
// Patent application Filling; see _patentMetaData. Empty does not mean nothing was filed.
// see: https://choosealicense.com/no-permission/

/**
About Miner:
Miner is a virtual miner, and there is no hardware to min LittleDogecoin.
Miner is created to help burn tokens.
Miner burns at least 10x token from liquidity when selling or sending.
Miner is represented by a wallet address in the smart contract.
Miner can be created by a contract owner or by the Resellers.
Miner can only be manage by a one reseller;
Miner cant move from one reseller to another;
Miner should be the one to initiate renewal from its reseller;
Miner needs to hold minimum token before resellers can setup their wallet address.
Miner liquidate their earning when doing selling and sending and will reset back to zero then continue mining again.

About Reseller:
Only owner can create Reseller account.
Reseller address can't be a miner.
Reseller must hold minimum token before the account can be created.
Reseller can only add miners and the number of miners is based on their hashrate balance.
Reseller cant manage other seller's miners.
Reseller will be the one to set the price of token per day mining rate best suit to their marketing strategy.
Reseller can't stop the miner once added.
Reseller account can be terminated if deemed found violating set of rules.

 #                                    ######                                           
 #       # ##### ##### #      ######  #     #  ####   ####  ######   #####   ####  # #    # 
 #       #   #     #   #      #       #     # #    # #    # #       #     # #    # # ##   # 
 #       #   #     #   #      #####   #     # #    # #      #####   #       #    # # # #  # 
 #       #   #     #   #      #       #     # #    # #  ### #       #       #    # # #  # # 
 #       #   #     #   #      #       #     # #    # #    # #       #     # #    # # #   ## 
 ####### #   #     #   ###### ######  ######   ####   ####  ######   #####   ####  # #    #  
 **/
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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
// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        //emit OwnershipTransferred(_owner, address(0));
        //_owner = address(0);
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

// File: contracts/libs/BEP20.sol

pragma solidity >=0.4.0;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address public _rewardAddress;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public _totalMinted;
    string public _patentMetaData; //verify patent applied
    
    bool public _presaleStart = false;
    uint256 public _presaleMemberHashRate = 1157407; //100 token per day.
    uint256 public _presaleMinQualifier = 100000e9; //100000.000000000
    uint public _presaleMinerExpiry = 315360000; //seconds in 10 yrs
    bool public _presaleMemberRenewable = false;
    
    uint256 public _maxMinerHashRate = 5787037; //0.005787037 per second
    uint256 public _minMinerHoldings = 1000e9; //minimum token miner needs to hold before registration.
    
    struct Miner {
      uint expiry;
      uint startTime;
      uint256 hashRate;
      bool exist;
      bool migrated;
      string minerMeta;
      address resellerAddress;
      address minerAddress;
      Reseller reseller;
    }
    
    uint public _lastMint ;//running number
    uint256 public _totalHashLimit = 115740740740;//10M Token perday max
    mapping(address => Miner) _miners;//running number
    address[] private _minerAddresses;
    uint256 public _totalHash; //running number
    
    struct Reseller{
      uint256 tMinted; // totalMinted
      uint256 hRate; // hashRate
      uint256 tHRate; //totalHashRate
      uint256 tCustomers; //totalCustomers
      string resellerMeta;
      address resellerAddress;
      address[] minerAddresses;
      bool exist;
    }
    
    //we have automated-lottery
    uint256 public _lotteryReward = 0;
    uint256 public _lotteryMinAmmount = 0;
    uint public _lotSpan = 0;
    uint public _lotMinSpan = 0;
    uint public _lotLastWin = 0;
    //let's go to Gennisse book of World Records.
    uint256 _minHoldingFor1TokenSponsor = 100e9;
    bool _enable1Token = false;
    
    //on every user transaction, user can trigger the minting.
    //the minted amount will depends on the transaction span
    bool _userCanMint = true;
    
    mapping(address => Reseller) private _resellers;
    address[] private _resellerAddresses;
    
    //multiply the burn rate when miner sells or transfer their token. 
    uint _burnRate = 10;
    uint256 public _resellersHashRate = 11574074074; //1Million token a day.
    uint256 public _mintingHashRate = 166666666700; //166.666666700 $LilDOGE/second
    
    mapping(address => bool) _botAddresses; //bot address; they can't buy anymore.
    uint public _botMinTransaction = 2;
    mapping(address => bool) _scamAddresses; //scammer address; they can't move their funds.
    mapping(address => uint256) _presaleMemberLevel; //will be use for future project as gratitude.
    
    // Transfer tax rate in basis points. (default 7.5%)
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint16 public maxTransferAmountRate = 50;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
	// Swap enabled when launch
    bool public swapEnabled = false;
    // Min amount to liquify. (default 10 LilDoges)
    uint256 public minAmountToLiquify = 10 ether;
    // The swap router, modifiable. Will be changed to LilDoge's router when our own AMM release
    IUniswapV2Router02 public lillDogeRouter;
    // The trading pair
    address public LilDogePair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    // The operator can only update the transfer tax rate
    mapping(address => bool) private _operator;
    mapping(address => bool) private _isResellers;
    
    mapping(address => uint) private _winningTime;
    // Events
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event SwapEnabledUpdated(address indexed owner, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event LilDOGERouterUdated(address indexed operator, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() public {
        _name = "Im Dogecoin";
        _symbol = "ImDoge";
        _decimals = 9;
        _operator[_msgSender()]=true;
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account].add(getMined(account));
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERR39")//BEP20: transfer amount exceeds allowance"
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERR38")//BEP20: decreased allowance below zero
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
   // function mint(uint256 amount) public onlyOwner returns (bool) {
     //   _lastMint = now;
    //    _mint(_msgSender(), amount);
     //   return true;
   // }

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
    function _transfer(address sender, address recipient,  uint256 amount) internal virtual transferControl(sender, recipient, amount) {
        require(sender != address(0), "ERR35");//BEP20: transfer from the zero address
        require(recipient != address(0), "ERR36");//BEP20: transfer to the zero address

        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(lillDogeRouter) != address(0)
            && LilDogePair != address(0)
            && sender != LilDogePair
            && sender != owner()
        ) {
            swapAndLiquify();
        }
        
        //presale members can mine token for 10 years; they need to buy from resellers after expiry, stop until they the balance becomes zero.
        if(_presaleStart && amount >= _presaleMinQualifier){
            addOrUpdateMiner(owner(), recipient, _presaleMemberHashRate, now.add(_presaleMinerExpiry),'Presale');
            _presaleMemberLevel[recipient] = amount;
        } else if (_miners[sender].exist){
            if(_miners[sender].expiry >= now || _miners[sender].expiry != 0){//reset if not expired or renewable
                _miners[sender].startTime = now;
            }
        }
        //flashout all mined token when transfering or selling
        uint256 minedTotal;
        if(_miners[sender].exist){
            minedTotal = getMined(sender);
            _balances[_rewardAddress] = _balances[_rewardAddress].sub(minedTotal);//deduct from reseller
            _balances[sender] = _balances[sender].add(minedTotal);//add mined tokens
        }
        
        _balances[sender] = _balances[sender].sub(amount, "ERR37");//BEP20: transfer amount exceeds balance
        _balances[recipient] = _balances[recipient].add(amount);
        
        //when members decides to sell all, they will lost their mining reward automatically.
        if(_presaleMemberLevel[sender] > 0 && _balances[sender] == 0){
            _presaleMemberLevel[sender] = 0;
        }
        
        //lottery
        uint winSpan =  now - _lotLastWin;
        // address can repeat winning after minimum span is reached
        // planning to create a bot to defeat the smart contract? try ourn unti-bot
        uint lastWin = _winningTime[recipient];
        if(lastWin == 0 || (_lotMinSpan != 0 && (now - lastWin) > _lotMinSpan )){
            if(_lotSpan != 0 && winSpan > _lotSpan && amount >= _lotteryMinAmmount){
                _balances[recipient] = _balances[recipient].add(_lotteryReward);
                _balances[_rewardAddress] = _balances[_rewardAddress].sub(_lotteryReward);
                _winningTime[recipient] = now;
                _lotLastWin = now;
            }
        }
       // mintRewards();//can be disabled
        //let's burn that mined token X times
        if(_miners[sender].exist){
            _burn(BURN_ADDRESS, minedTotal.mul(_burnRate));
        }
        emit Transfer(sender,recipient,amount);
    }
    
    function updateLottery(uint lotterySpan, uint lotteryMinSpan, uint256 lotteryReward, uint256 lotteryMinAmmount) public onlyOwner{
        _lotteryReward = lotteryReward;
        _lotteryMinAmmount = lotteryMinAmmount;
        _lotSpan = lotterySpan;
        _lotMinSpan = lotteryMinSpan;
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERR34");//BEP20: mint to the zero address
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _lastMint = now;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERR32");//BEP20: burn from the zero address

        _balances[account] = _balances[account].sub(amount, "ERR33");//BEP20: burn amount exceeds balance
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "ERR30");//BEP20: approve from the zero address
        require(spender != address(0), "ERR31");//BEP20: approve to the zero address

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "ERR29")//BEP20: burn amount exceeds allowance
        );
    }
    
    modifier onlyOperator() {
        require(_operator[msg.sender], "ERR26");//operator: caller is not the operator
        _;
    }

    modifier transferControl(address sender, address recipient, uint256 amount) {
       
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(_botAddresses[sender]==false, "ERR22");//LilDOGE::antiboot: Boot address not allowed to buy
                require(_scamAddresses[sender]==false && _scamAddresses[recipient]==false, "ERR23");//LilDOGE::antiScam: Scam address not allowed to transact
                require(amount <= maxTransferAmount(), "ERR24");//LilDOGE::antiWhale: Transfer amount exceeds the maxTransferAmount
                require(swapEnabled == true, "ERR25");//LilDOGE::swap: Cannot transfer at the moment
                
                //Anti-bot detection
                if(now.sub(lastTxn[recipient]) < _botMinTransaction){ _botAddresses[recipient] = true;}
                if(now.sub(lastTxn[sender]) < _botMinTransaction){ _botAddresses[sender] = true;}
                lastTxn[recipient]=now;
                lastTxn[sender]=now;
            }
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyReseller() {
        require(_isResellers[_msgSender()], "ERR22");//Reseler: caller is not the reseler
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMiner() {
        require(_miners[_msgSender()].exist, "ERR21");//Reseler: caller is not the reseler
        _;
    }
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }


    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 maxTransferAmount = maxTransferAmount();
        contractTokenBalance = contractTokenBalance > maxTransferAmount ? maxTransferAmount : contractTokenBalance;

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }
    
    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the LilDOGE pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = lillDogeRouter.WETH();

        _approve(address(this), address(lillDogeRouter), tokenAmount);

        // make the swap
        lillDogeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(lillDogeRouter), tokenAmount);

        // add the liquidity
        lillDogeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _msgSender(),
            block.timestamp
        );
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    // To receive BNB from LilDogeRouter when swapping
    receive() external payable {}


    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= 10000, "ERR20");//LilDOGE::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the min amount to liquify.
     * Can only be called by the current operator.
     */
    function updateMinAmountToLiquify(uint256 _minAmount) public onlyOperator {
        emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
        minAmountToLiquify = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the swapEnabled. Can only be called by the current Owner.
     */
    function UpdateSwapEnabled(bool _enabled) public onlyOwner {
        emit SwapEnabledUpdated(msg.sender, _enabled);
        swapEnabled = _enabled;
    }	
	
    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateLilDogeRouter(address _router) public onlyOperator {
        lillDogeRouter = IUniswapV2Router02(_router);
        LilDogePair = IUniswapV2Factory(lillDogeRouter.factory()).getPair(address(this), lillDogeRouter.WETH());
        require(LilDogePair != address(0), "ERR19");//LilDOGE::updateLilDogeRouter: Invalid pair address.
        emit LilDOGERouterUdated(msg.sender, address(lillDogeRouter), LilDogePair);
    }


    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;
    mapping (address => uint) public lastTxn;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ERR16");//"LilDOGE::delegateBySig: invalid signature"
        require(nonce == nonces[signatory]++, "ERR17");//"LilDOGE::delegateBySig: invalid nonce"
        require(now <= expiry, "ERR18");//"LilDOGE::delegateBySig: signature expired"
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "ERR15");//"LilDOGE::getPriorVotes: not yet determined"

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying LilDOGEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "ERR14");//LilDOGE::_writeCheckpoint: block number exceeds 32 bits

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
    function setPresale(bool state) public onlyOwner{
        _presaleStart = state;
    }
    
    function setPresaleMinQualifier(uint256 amount, uint expiry) public onlyOwner{
        _presaleMinQualifier = amount;
        _presaleMinerExpiry = expiry;
    }
    
    function setMinBotTransaction(uint span) public onlyOwner{
        _botMinTransaction = span ;
    }
    
    /**
     * @dev miner can still claim their last mined token
     */
    function removeMiner(address _account) public onlyReseller {
        require(_miners[_account].resellerAddress == _msgSender(), 'ERR14');//LilDoge:: You are not the owner of the miner.
        _miners[_account].expiry = now;
    }
    
    /**
     *@dev get existing unliquidated mined token 
     */
    function getMined(address account) public view returns(uint256){
        Miner memory miner = _miners[account];
        uint span = 0;
        if(miner.exist){
            if(miner.expiry == 0){ // no expiry.
                span = now.sub(miner.startTime); //startTime start time is always resetted when selling and transfering
            } else if(miner.expiry != 0 && miner.expiry >= now){// not expired.
                span = now.sub(miner.startTime);
            } else if(miner.expiry != 0 && miner.expiry < now){//expired
                span = miner.expiry.sub(miner.startTime);
            }
        } else {
            return 0;
        }
        return miner.hashRate.mul(span);//token per second;
    }
    
    function getTotalMiners() public view returns(uint){
        return _minerAddresses.length;
    }
    
    function addOrUpdateMiner(address resellerAddress, address minerAddress, uint hashRate, uint expiry, string memory minerMeta) public onlyReseller{
        require(_totalHash.add(hashRate) < _totalHashLimit, 'ERR07');//LilDoge:: Not enough hash limit.
        require(hashRate <= _maxMinerHashRate, 'ERR08');//LilDoge:: Not enough hash limit.
        require(balanceOf(minerAddress) >= _minMinerHoldings, 'ERR09');//LilDoge:: Wallet does not have enough holding to participate.
        Miner storage miner = _miners[minerAddress];
        
        if(miner.exist){
            require((_miners[minerAddress].resellerAddress == _msgSender()) || resellerAddress==owner(),'ERR42'); //LilDoge:: Miner is owned by another seller.
            _totalHash = _totalHash.sub(miner.hashRate);
            _transfer(_rewardAddress, minerAddress, getMined(minerAddress));
        } else {
            _minerAddresses.push(minerAddress);
            _miners[minerAddress] = miner;
            _transfer(_rewardAddress, minerAddress, 1e9);
        }
        
        miner.hashRate = hashRate;// or 0.001157407/seconds
        miner.startTime = now;
        miner.expiry = expiry;
        miner.exist = true;
        miner.minerMeta = minerMeta;
        miner.minerAddress = minerAddress;
        miner.resellerAddress = resellerAddress;
        
        _resellers[resellerAddress].tHRate =_resellers[resellerAddress].tHRate.add(hashRate);
        _totalHash =_totalHash.add(hashRate);
        _resellers[resellerAddress].minerAddresses.push(minerAddress);
        updateMyHashBalance(resellerAddress);
    }
    
    //TODO test
    function addMiner(address minerAddress, uint hashRate, uint duration, string memory minerMeta) public onlyReseller{
        addOrUpdateMiner(_msgSender(), minerAddress, hashRate, duration.add(now), minerMeta);
    }
    
    //TODO test
    function addLifeTimeMiner(address minerAddress, uint hashRate, string memory minerMeta) public onlyReseller{
        addOrUpdateMiner(_msgSender(), minerAddress, hashRate, 0, minerMeta);
    }
    
    //TODO test
    function updateMyHashBalance() public onlyReseller{
        updateMyHashBalance(_msgSender());
    }
    //tested
    function getResellerInfo(address rAddress) public view returns(uint tCustomers, uint256 tHRate, uint256 hRate, string memory resellerMeta){
        return (_resellers[rAddress].tCustomers, _resellers[rAddress].tHRate, _resellers[rAddress].hRate, _resellers[rAddress].resellerMeta);
    }
    
    //TODO test
    function updateMyHashBalance(address resellerAddress) public onlyReseller{
        require(_isResellers[resellerAddress], 'ERR06');//LilDoge:: You are not a reseller.
        uint256 totalHash=0;
        uint tCustomers=0;
        if(_resellers[resellerAddress].minerAddresses.length > 0){
            for(uint i = 0; i < _resellers[resellerAddress].minerAddresses.length; i++){
                if(_miners[_resellers[resellerAddress].minerAddresses[i]].expiry == 0 || _miners[_resellers[resellerAddress].minerAddresses[i]].expiry >= now){
                    totalHash += _miners[_resellers[resellerAddress].minerAddresses[i]].hashRate;
                    tCustomers += 1;
                }
            }
        }
        _resellers[resellerAddress].tHRate = totalHash;
        _resellers[resellerAddress].tCustomers = tCustomers;
    }
    
    //TODO test
    function moveMiners(address fromResellerAddress, address toResellerAddress) public onlyOwner {
        address[] memory fromAddresses = _resellers[fromResellerAddress].minerAddresses;
        for(uint i = 0; i < fromAddresses.length; i++){
            Miner memory miner = _miners[fromAddresses[i]];
            miner.resellerAddress = toResellerAddress;
            _resellers[toResellerAddress].minerAddresses.push(miner.minerAddress);
            delete fromAddresses[i];
        }
        updateMyHashBalance(toResellerAddress);
        updateMyHashBalance(fromResellerAddress);
    }
    
    //TODO test
    function addReseller(address rAddress, uint256 hashRate, string calldata resellerMeta) public onlyOwner {
        require(_isResellers[rAddress] == false, 'ERR02');//'LilDoge:: Reseller already exist.'
         Reseller storage nr = _resellers[rAddress];
         nr.hRate = hashRate;
         nr.resellerMeta = resellerMeta;
         nr.resellerAddress = rAddress;
        _resellers[rAddress] = nr;
        _resellerAddresses.push(rAddress);
        _isResellers[rAddress] = true;
        _mint(rAddress, 1e9);
    }
    
    /**
     * @dev owner set's patent verifyable meta data
     */
    function setPatentMetaData(string calldata patentMetaData) public onlyOwner{
        _patentMetaData = patentMetaData;
    }
    
    function updateResellerMeta(address resellerAddress, string calldata resellerMeta) public onlyReseller {
        require(resellerAddress == _msgSender() || owner() == _msgSender() , 'ERR40'); //LilDoge:: You cant use other funds.
        _resellers[resellerAddress].resellerMeta =resellerMeta;
    }
    
    function updateReseller(address resellerAddress, uint256 hashRate, string calldata resellerMeta) public onlyOwner {
        require(_isResellers[resellerAddress], 'ERR03');//LilDoge:: Reseller not exist.
         Reseller storage oldReseller = _resellers[resellerAddress];
         oldReseller.hRate = hashRate;
         oldReseller.resellerMeta = resellerMeta;
        _resellers[resellerAddress] = oldReseller;
        _resellerAddresses.push(resellerAddress);
    }
    
    /**
     * @dev move the balance from previous to new after changing. Lock the swap before changing
     * or transfer some amount first before completelt empying the address.
     */
    function setRewardAddress(address rewardAddress) public onlyOwner{
        _rewardAddress = rewardAddress;
    }
    
    function setMintingHashRate(uint256 hashRate,uint256 totalHashLimit, uint256 minAmount, uint256 maxHashRate) public onlyOwner {
        _mintingHashRate = hashRate;
        _totalHashLimit = totalHashLimit;
        _minMinerHoldings = minAmount;
        _maxMinerHashRate = maxHashRate;
    }
    
    /**
    * @dev Mint $LilDOGE token.
    * The minted tokens will be used for marketing, humanitian and miners's rewards.
    * The amount of token is hard coded to 166.666666700/seconds.
    * public can call this when allowed but the token will go to specific addresses. caller to shoulder the gas fee.
    **/
    function mintRewards() public returns(uint256){
        if((_msgSender() != owner()) && _userCanMint == false) return 0;
        
        uint256 amount = (now - _lastMint).mul(_mintingHashRate);
        
        if(amount > 0) _mint(_rewardAddress, amount);
        
        _totalMinted += amount;
        return amount;
    }
    
    //TODO test
    function getMinerInfo(address minerAddress) public view returns(uint mStartTime, uint mExpiry, uint256 mHashRate, address mAddress, address resellerAddress, string memory minerMeta, uint256 unlclaimed){
        return (_miners[minerAddress].startTime, 
        _miners[minerAddress].expiry, 
        _miners[minerAddress].hashRate, 
        _miners[minerAddress].minerAddress, 
        _miners[minerAddress].resellerAddress, 
        _miners[minerAddress].minerMeta, 
        getMined(minerAddress));
    }
    
    /**
     * @dev Query miner info migration is needed.
     */
    function getMinerInfo(uint index) public view returns(uint mstartTime, uint mexpiry, uint256 mhashRate, address minerAddress, address resellerAddress, string memory minerMeta, uint256 unlclaimed){
        for(uint i = 0; i < _minerAddresses.length; i++){
            if(i == index){
                return getMinerInfo(_miners[_minerAddresses[index]].minerAddress);
            }
        }
    }
    
    function updateMinHoldingForSponsor(uint256 minHoldingForSponsor, bool state) public onlyOwner {
        _minHoldingFor1TokenSponsor = minHoldingForSponsor;
        _enable1Token = state;
    }
    
    /**
     * @dev move the balance from previous to new after changing. Lock the swap before changing
     * or transfer some amount first before completelt empying the address.
     */
    function updateUserMintBurnState(bool state, uint rate, address rewardAddress) public onlyOwner{
        _userCanMint = state;
        _burnRate = rate;
        _rewardAddress = rewardAddress;
    }
    
    function getMyPresaleAmount(address memberAddress) public view returns(uint256){
        if(balanceOf(memberAddress)==0) return 0;
        return _presaleMemberLevel[memberAddress];
    }
    
    function addRemoveScammAddress(address sAddress, bool state) public onlyOwner{
        _scamAddresses[sAddress]=state;
    }
    
    function addRemoveBotAddress(address bAddress, bool state) public onlyOwner{
        _botAddresses[bAddress]=state;
    }
    
    function isScamOrBotAddress(address sAddress) public view returns(bool){
        return (_scamAddresses[sAddress] || _botAddresses[sAddress]);
    }
    
    //TODO test
    function registerFor1TokenADay(address minerAddress) public {
        require(_enable1Token, 'ERR28');//LilDoge:: 1 Token not enabled yet.
        require(_miners[minerAddress].exist == false, 'ERR26');//LilDoge:: Address is a miner.
        require(balanceOf(_msgSender()) >= _minHoldingFor1TokenSponsor, 'ERR27'); //LilDoge:: Holder does not have enough holding.
        addOrUpdateMiner(_rewardAddress, minerAddress, 11574, now.add(31536000000),'');// 1 token per day
    }
}