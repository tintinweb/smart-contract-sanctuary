/**
 *Submitted for verification at FtmScan.com on 2022-01-08
*/

// SPDX-License-Identifier: Unlicensed


/**
 * 
 * The YourCoin contract itself has been heavily annotated to allow all frens
 * to understand what is going on. It is meant to be as transparent
 * as possible in explaining what each privileged function does, why it's needed,
 * the foreseen risks they present and the mitigation of those risks.
 * 
 * To that end, each privileged function is annotated in 4 parts as follows:
 * 
 * Function: [What the function does].
 * 
 * Justification: [Why it's in the contract].
 * 
 * Risk statement: [What the risks in principle are].
 * 
 * Mitigation: [How the risks are to be minimized].
 * 
 * The following global mitigation applies to the notion that the owner's private keys could 
 * be compromised and the malicious actor could call any number of the many privileged functions
 * or dump from the Fren Co. wallets:
 * 
 * "The owner recognises that its private keys are a potential single point of failure
 * since they could be compromised by a malicious actor. The owner is experienced in security 
 * and assures that the private keys will be carefully guarded and stored on an airgapped Qubes
 * machines. A multisig wallet could also be used in the future to provide additional assurance. 
 * A time-lock is unlikely to be added as the owner feels it would hamstring the project's agility,
 * and ability to resolve issues that may arise, such as an individual unable to withdraw tokens 
 * from a pool because it would violate the max Tx or max wallet rules. Being able to adjust the 
 * tokenomics on demand is a core tenet of the project. No privileged function has been added 
 * without careful consideration of its risk profile".
 */



// File: SafeMath.sol


pragma solidity 0.8.6;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking. Retained for backwards-compatibility.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



// File: Context.sol


pragma solidity 0.8.6;

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
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}



// File: IDEXRouter02.sol


pragma solidity 0.8.6;

interface IDEXRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit( address tokenA, address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountA, uint amountB);
        
    function removeLiquidityETHWithPermit(address token, uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
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



// File: IDEXFactory.sol


pragma solidity 0.8.6;

interface IDEXFactory {
    // Creates pair with FTM.
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);      

    // Gives a fee to the LP provider.
    function feeTo() external view returns (address);      
    // Gives a fee to the LP setter.
    function feeToSetter() external view returns (address);     

    // Gets the address of the LP token pair.
    function getPair(address tokenA, address tokenB) external view returns (address pair);  
    // Gets address of all pairs.
    function allPairs(uint) external view returns (address pair); 
    // Gets the length of pairs.
    function allPairsLength() external view returns (uint);     

    // Creates the pair.
    function createPair(address tokenA, address tokenB) external returns (address pair);    

    // Sets a fee to an address.
    function setFeeTo(address) external;  
    // Sets fee to the setter address.
    function setFeeToSetter(address) external;  

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
    
}



// File: IERC20.sol


pragma solidity 0.8.6;

interface IERC20 {

    /* Functions */
    
    // Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256); 

    // Returns the token decimals.
    function decimals() external view returns (uint8);  

    // Returns the token symbol.
    function symbol() external view returns (string memory); 

    // Returns the token name.
    function name() external view returns (string memory); 

    // Returns the token owner.
    function getOwner() external view returns (address); 

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);   
    
    // Transfers tokens to addr, emits a {Transfer} event.
    function transfer(address recipient, uint256 amount) external returns (bool);  

    // Returns remaining tokens that spender is allowed during {approve} or {transferFrom}.
    function allowance(address _owner, address spender) external view returns (uint256); 
    
    // Sets amount of allowance, emits {approval} event.
    function approve(address spender, uint256 amount) external returns (bool); 

    // Moves amount, then reduce allowance and emits a {transfer} event.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); 

    /* Events */

    // Emits when value tokens moved, value can be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);    

    // Emits when allowance of spender for owner is set by a call to approve. Value is new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);   

}



// File: Address.sol


pragma solidity 0.8.6;

/**
 * @dev Collection of functions related to the address type.
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
     * - the calling contract must have a FTM balance of at least `value`.
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

// File: SafeERC20.sol



pragma solidity 0.8.6;

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



// File: YourCoin.sol


pragma solidity 0.8.6;

contract Umani is Context, IERC20 {

    /* LIBRARIES */
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    /* BASIC TOKEN CONSTANTS */
    
    string public  _name = "https://fantom.umani.fun";
    
    string public  _symbol = "UMANI";
    
    uint8 private constant TOKEN_DECIMALS = 9;
    
    uint256 private constant TOKEN_MAX_SUPPLY = 1000000 * 10**9;
    
    uint256 private constant MAXintNum = ~uint256(0);
    
    /* RELEASE TIME STAMP VARIABLE */

    uint256 public LiquidityUnlockTime;
    
    /* TRACKING VARIABLES */
    uint256 public rewardPost;
    uint256 public postInterval;
    mapping(address => uint256) public rewardAmount;
    mapping(address => uint256) public lastPostTime;
    mapping(address => mapping(address => uint256)) private allowanceAmount;

    mapping(address => uint256) private reflectTokensOwned;
    
    mapping(address => uint256) private totalTokensOwned;

    /* RFI VARIABLES */
    
    uint256 private _rTotal;
    
    uint256 private totalFeeAmount;

    uint256 public reflectFeePercent;
    uint256 private previousReflectFeePercent;

    uint256 public charityFeePercent;
    uint256 private previousCharityFeePercent;

    uint256 public burnFeePercent;
    uint256 private previousBurnFeePercent;

    uint256 public funFeePercent;
    uint256 private previousFunFeePercent;

    uint256 public liquidityFeePercent;
    uint256 private previousLiquidityFeePercent;

    IDEXRouter02 public DEXRouter;
    
    address public DEXPair;
    address private previousDEXPair;
    
    address public DEXRouterAddress;
    address private previousDEXRouterAddress;

    bool private inAutoLiquidity;
    bool public isAutoLiquidityEnabled;

    uint256 public maxTxAmount;
    uint256 private previousMaxTxAmount;
    
    uint256 public maxWallet;
    uint256 private previousMaxWallet;
    
    uint256 public autoLiquidityThreshold;
    uint256 private previousAutoLiquidityThreshold;

    /* KEY ADDRESS VARIABLES */
    
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    address private ownerOfToken;
    address private previousOwnerOfToken;
    
    address public growthAddress;
    address private previousGrowthAddress;
    
    address public funAddress;
    address private previousFunAddress;
    
    address public charityAddress;
    address private previousCharityAddress;
    
    address public dexPadTokenLockerAddress;
    address public dexPadLPLockerAddress;
    address public dexPadAirdropperAddress;

    uint256 public _minUsdAmtToChangeTokenPost = 233*10**18;
    uint256 public _minUsdAmtToChangeToken = 432*10**18;
    uint256 public _minUsdAmtToMarket = 1440*10**18;
    uint256 public _minUsdAmtTobeAdmin = 3333*10**18;
   
    uint256 private _MinAmount = 100;

    address public usd = 0x82f0B8B456c1A451378467398982d4834b6829c1; //MIM
    string public _tokenMotto;
    string public _tokenMessage;
    string public _tokenLogo;
    string public _telegramLink = "https://t.me/umaniFTM";
    string public _discordLink = "https://discord.com";
    string public _twitterLink = "https://twitter.com";
    string public _tokenBackgroundImage;
 
    /* SPECIAL VARIABLES */
    
    mapping(address => bool) private isAddressExcludedFromReflections;
    address[] private excludedFromReflectionsAddresses;

    mapping(address => bool) private isAccountExcludedFromTax;
    
    mapping(address => bool) private isAccountExcludedFromMaxWallet;
    
    mapping(address => bool) private isAccountExcludedFromMaxTxAmount;

     struct PostMessage {
        string message;
        string image;
        address sender;
        uint256 time;
        address creator;
        uint256 created;
    }

    PostMessage[] public postMessages;

    /* EVENTS */
    
    /**
     * Here events are defined that will be called in privileged functions
     * so that the changes made are clearly broadcasted on the explorer
     * and cannot be obfuscated. The names of the events are intended
     * to make them self-explanatory.
     */
    
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );
    
    event AutoLiquidity(
        uint256 tokensSwapped,
        uint256 FTMReceived,
        uint256 tokensIntoLiquidity
    );
    
    event AutoLiquidityEnabledUpdated(bool enabled);
    
    event AutoLiquidityThresholdChanged(
        uint256 indexed previousAutoLiquidityThreshold, 
        uint256 indexed newAutoLiquidityThreshold
    );
    
    event GrowthAddressChanged(
        address indexed previousGrowthAddress, 
        address indexed newGrowthAddress
    );
    
    event FunAddressChanged(
        address indexed previousFunAddress, 
        address indexed newFunAddress
    );
    
    event CharityAddressChanged(
        address indexed previousCharityAddress, 
        address indexed newCharityAddress
    );
    
    event MaxTxAmountChanged(
        uint256 indexed previousMaxTxAmount, 
        uint256 indexed newMaxTxAmount
    );
    
    event MaxWalletChanged(
        uint256 indexed previousMaxWallet, 
        uint256 indexed newMaxWallet
    );
    
    event ReflectFeePercentChanged(
        uint256 indexed previousReflectFeePercent, 
        uint256 indexed newReflectFeePercent
    );
    
    event CharityFeePercentChanged(
        uint256 indexed previousCharityFeePercent, 
        uint256 indexed newCharityFeePercent
    );
    
    event BurnFeePercentChanged(
        uint256 indexed previousBurnFeePercent, 
        uint256 indexed newBurnFeePercent
    );
    
    event FunFeePercentChanged(
        uint256 indexed previousFunFeePercent, 
        uint256 indexed newFunFeePercent
    );
    
    event LiquidityFeePercentChanged(
        uint256 indexed previousLiquidityFeePercent, 
        uint256 indexed newLiquidityFeePercent
    );
    event LiquidityWithdraw(
        address indexed recipient,
        uint256 indexed amount
    );     
    event LiquidityLockExtended(
        uint256 indexed newliquidityunlocktime
    );     
    event RouterAddressChanged(
        address indexed previousRouterAddress,
        address indexed newRouterAddress
    );
    
    event PairAddressChanged(
        address indexed previousDEXPair,
        address indexed newDEXPair
    );
    
    event AddressExcludedFromReflections(
        address indexed excludedAddress
    );
    
    event AddressIncludedInReflections(
        address indexed includedAddress
    );
    
    event AddressWhitelistedFromTax(
        address indexed whitelistedAddress
    );
    
    event AddressIncludedInTax(
        address indexed includedAddress
    );
    
    event AddressWhitelistedFromMaxWallet(
        address indexed whitelistedAddress
    );
    
    event AddressIncludedInMaxWallet(
        address indexed includedAddress
    );
    
    event AddressWhitelistedFromMaxTx(
        address indexed whitelistedAddress
    );
    
    event AddressIncludedInMaxTx(
        address indexed addressIncludedInMaxTx
    );
    
    event YourCoinRecovered(
        address indexed recipient,
        uint256 indexed amount
    );
    
    event ERC20Recovered(
        address indexed token,
        address indexed recipient,
        uint256 indexed amount
    );
    
    event FTMRecovered(
        address indexed recipient,
        uint256 indexed amount
    );

    

constructor (){
    
        // This function is executed once when the contract is deployed
        // and it sets the values for important addresses and variables.
        
        // Sets wallets.
        growthAddress = 0xaE9F8d1600dD9c22865beb2a76065a191dca6EfE;
        funAddress = 0xaE9F8d1600dD9c22865beb2a76065a191dca6EfE;
        charityAddress = 0xaE9F8d1600dD9c22865beb2a76065a191dca6EfE;

        // Sets owner.
        ownerOfToken = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
        
        // Sets _rTotal.
        _rTotal = (MAXintNum - (MAXintNum % TOKEN_MAX_SUPPLY));       
        
        // Sets initial max Tx which acts as anti-snipe.
        maxTxAmount = 0 * 10**9;
        previousMaxTxAmount = maxTxAmount;
    
        // Sets initial max wallet which will be changed to 10000 after initial liquidty
        // is added but before trading is enabled, where it will act as anti-whale.
        maxWallet = 1000000 * 10**9;
        previousMaxWallet = maxWallet;
        rewardPost =  25 * 10**9;
        postInterval = 1 hours;
        // Sets initial reflection tax %.
        reflectFeePercent = 6;
        previousReflectFeePercent = reflectFeePercent;
        
        // Sets initial auto-liquidity tax %.
        liquidityFeePercent = 3;
        previousLiquidityFeePercent = liquidityFeePercent;
        
        // Sets initial fun tax % for competitions/giveaways etc.
        funFeePercent = 0; 
        previousFunFeePercent = funFeePercent;
        
        // Sets initial charity tax %.
        charityFeePercent = 0; 
        previousCharityFeePercent = charityFeePercent;
        
        // Sets initial burn tax %.
        burnFeePercent = 6; 
        previousBurnFeePercent = burnFeePercent;
        
        // Enables auto-liquidity and sets initial LP conversion threshold.
        isAutoLiquidityEnabled = false; 
        autoLiquidityThreshold = 300 * 10**9;

        // Tracks minting of tokens.
        reflectTokensOwned[owner()] = _rTotal; 
        emit Transfer(address(0), owner(), TOKEN_MAX_SUPPLY);      

        // Sets router address
        DEXRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        
        // Gets the router.
        IDEXRouter02 DEXRouterLocal = IDEXRouter02(DEXRouterAddress);
        
  
        
        // Sets the rest of the contract variables in the global router variable to the local one.
        DEXRouter = DEXRouterLocal;
        


        // Whitelists key addresses from tax.
        isAccountExcludedFromTax[owner()] = true; 
        isAccountExcludedFromTax[address(this)] = true; 
        isAccountExcludedFromTax[growthAddress] = true;  
        isAccountExcludedFromTax[funAddress] = true;  
        isAccountExcludedFromTax[charityAddress] = true;
        isAccountExcludedFromTax[deadAddress] = true;

        
        // Whitelists key addresses from max wallet limit.
        isAccountExcludedFromMaxWallet[owner()] = true;
        isAccountExcludedFromMaxWallet[address(this)] = true;
        isAccountExcludedFromMaxWallet[growthAddress] = true;
        isAccountExcludedFromMaxWallet[funAddress] = true;
        isAccountExcludedFromMaxWallet[charityAddress] = true;
        isAccountExcludedFromMaxWallet[deadAddress] = true;
        isAccountExcludedFromMaxWallet[dexPadTokenLockerAddress] = true;
        isAccountExcludedFromMaxWallet[dexPadAirdropperAddress] = true;
        
        // Whitelists key addresses from max Tx limit.
        isAccountExcludedFromMaxTxAmount[owner()] = true;
        isAccountExcludedFromMaxTxAmount[address(this)] = true;
        isAccountExcludedFromMaxTxAmount[growthAddress] = true;
        isAccountExcludedFromMaxTxAmount[funAddress] = true;
        isAccountExcludedFromMaxTxAmount[charityAddress] = true;
        isAccountExcludedFromMaxTxAmount[deadAddress] = true;
        isAccountExcludedFromMaxTxAmount[dexPadTokenLockerAddress] = true;
        isAccountExcludedFromMaxTxAmount[dexPadAirdropperAddress] = true;
        
        // Gets the block timestamp of when the contract is deployed.
        LiquidityUnlockTime = block.timestamp +30 days;
       
      
      
    }

    function tokenMotto() public view returns (string memory) {
        return _tokenMotto;
    }

    function tokenMessage() public view returns (string memory) {
        return _tokenMessage;
    }

    function tokenLogo() public view returns (string memory) {
        return _tokenLogo;
    }

    function telegramLink() public view returns (string memory) {
        return _telegramLink;
    }

    function discordLink() public view returns (string memory) {
        return _discordLink;
    }

    function twitterLink() public view returns (string memory) {
        return _twitterLink;
    }




     function changeName(string memory newName) external hasEnoughUsdToChangeStuff {
        _name = newName;
    }

    function changeSymbol(string memory newSymbol) external hasEnoughUsdToChangeStuff {
        _symbol = newSymbol;
    }
    function changeTokenLogo(string memory newTokenLogo) external hasEnoughUsdToChangeStuff {
        _tokenLogo = newTokenLogo;
    }
    function changeTokenMotto(string memory newTokenMotto) external hasEnoughUsdToChangeStuff {
        _tokenMotto = newTokenMotto;
    }


    function changeTokenBackground(string memory newTokenBackground) external hasEnoughUsdToChangeStuff {
        _tokenBackgroundImage = newTokenBackground;
    }    
    function messagelenght() public view returns (uint256){
        return postMessages.length;
    }

    function postMessage(string memory message,string memory image) external hasEnoughUsdToPost {
        PostMessage memory _postMessage;
        require(block.timestamp >=lastPostTime[msg.sender]+ postInterval ,"Please don't Spam");
 
        uint256 created = block.timestamp;

        _postMessage.message = message;
        _postMessage.image = image;
        _postMessage.sender = _msgSender();
        _postMessage.time = created;
        _postMessage.creator = _msgSender();
        _postMessage.created = created;

        postMessages.push(_postMessage);
        rewardAmount[msg.sender] =rewardAmount[msg.sender] +rewardPost;
        lastPostTime[msg.sender]= block.timestamp;
        _tokenMessage = message;
    }

    function getReward() external hasEnoughUsdToPost {
        require(block.timestamp >=lastPostTime[msg.sender],"wait until you can post again to claim");
        require (rewardAmount[msg.sender] <= balanceOf(address(this)), "Not enough YOURCOIN in contract");
        transferInternal(address(this), msg.sender, rewardAmount[msg.sender]);
        rewardAmount[msg.sender] = 0;
       
    } 
    function slippage() public view returns (uint256) {
      uint256 slip = burnFeePercent +  funFeePercent + reflectFeePercent+  liquidityFeePercent;
        return slip;
    }   

    function changRewardAmount(uint256 newReward) external hasEnoughUsdToAdmin() {
        require(newReward<= 69 * 10**9);
        rewardPost = newReward;
    }
   function changPostTime(uint256 newTime) external hasEnoughUsdToAdmin() {
        require(newTime>= 15);
        postInterval = newTime *60;
    }    

    function changMinUsd(uint256 newMinUsd) external onlyOwner {
        _minUsdAmtToChangeToken = newMinUsd;
    }

    function changMinMarket(uint256 newMinUsd) external onlyOwner {
        _minUsdAmtToMarket = newMinUsd;
    }

    function changMinUsdAdmin(uint256 newMinUsd) external onlyOwner {
        _minUsdAmtTobeAdmin = newMinUsd;
    }

    function changMinUsdPost(uint256 newMinUsd) external onlyOwner {
        _minUsdAmtToChangeTokenPost = newMinUsd;
    }
    
    
    /* CUSTOM TRANSFER FUNCTIONS */

    /** Transfer function that checks for whitelisting and processes transfers appropriately.
     *  It applies the max Tx and max wallet limit rules. It allows frens to send or sell 
     *  (but not buy or receive) YOURCOIN even if their balance exceeds the max wallet limit.
     *  It correctly exempts the owner from the max Tx limit in order to prevent Tx failures 
     *  if withdrawing large amounts from token lockers. It does not allow frens to withdraw 
     *  YOURCOIN from a pool if the withdrawal would violate the max Tx or max wallet limits.
     *  This is not deemed to be an issue because the max Tx and max wallet amounts will 
     *  gradually be raised after launch. As the market cap matures, it becomes less likely 
     *  that max Tx and max wallet amounts are exceeded. Any potential issues can be resolved 
     *  by the owner temporarily whitelisting an address from these limits.
     */
    function transferTokens(address sender, address recipient, uint256 transferAmount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

        (uint256 reflectAmount, uint256 reflectTransferAmount,uint256 reflectFee, uint256[6] memory reflectLiqCharityBurnFunFeeArray) = getTaxAndReflectionValues(transferAmount);

        if(isAddressExcludedFromReflections[sender]){
            totalTokensOwned[sender] = totalTokensOwned[sender].sub(transferAmount);
        }
        reflectTokensOwned[sender] = reflectTokensOwned[sender].sub(reflectAmount);

        if(isAddressExcludedFromReflections[recipient]){
            totalTokensOwned[recipient] = totalTokensOwned[recipient].add(reflectLiqCharityBurnFunFeeArray[5]);
        }
        reflectTokensOwned[recipient] = reflectTokensOwned[recipient].add(reflectTransferAmount);

        takeLiquidityFee(reflectLiqCharityBurnFunFeeArray[1]);   
        takeCharityFee(reflectLiqCharityBurnFunFeeArray[2]);      
        takeBurnFee(reflectLiqCharityBurnFunFeeArray[3]);      
        takeFunFee(reflectLiqCharityBurnFunFeeArray[4]);      
        takeReflectFee(reflectFee, reflectLiqCharityBurnFunFeeArray[0]);

        emit Transfer(sender, recipient, reflectLiqCharityBurnFunFeeArray[5]);

        if (!takeFee){
            restoreAllFee();
        } 
        
        if(!isAccountExcludedFromMaxTxAmount[sender] && recipient != ownerOfToken){ 
            require(transferAmount <= maxTxAmount, "Max Tx violation");
        }
        
        require(sender != address(0) && recipient != address(0), "Zero address");

        if(!isAccountExcludedFromMaxWallet[recipient]){ 
            require(balanceOf(recipient) < maxWallet, "Max wallet violation");
        }
  
    }

    /** Internal transfer function e.g. for executing recover functions. */
    function transferInternal(address senderAddr, address receiverAddr, uint256 amount) private {   
 
        require(senderAddr != address(0) && receiverAddr != address(0), "Zero address");
        require(amount > 0, "Transfer amount must be greater than 0");
        
        uint256 contractStoredReflectionTokenBalance = balanceOf(address(this));

        bool overMinContractStoredReflectionTokenBalance = false; 
        if(contractStoredReflectionTokenBalance >= autoLiquidityThreshold){
            overMinContractStoredReflectionTokenBalance = true;                        
        }

        if (overMinContractStoredReflectionTokenBalance && !inAutoLiquidity && senderAddr != DEXPair && isAutoLiquidityEnabled) {
            contractStoredReflectionTokenBalance = autoLiquidityThreshold;        
            autoLiquidity(contractStoredReflectionTokenBalance);   
        }

        bool takeFee = true;    
        if (isAccountExcludedFromTax[receiverAddr] || isAccountExcludedFromTax[senderAddr]) {   
            takeFee = false;    
        }


        transferTokens(senderAddr, receiverAddr, amount, takeFee); 
    }


    /* BASIC TRANSFER FUNCTIONS */

    /** Simple transfer to function with taxes applied. */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        transferInternal(_msgSender(), recipient, amount);
        return true;
    }

    /** Simple transfer from function with approval. */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        transferInternal(sender, recipient, amount); 
        approveInternal(sender, _msgSender(), allowanceAmount[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

   
    /* LIQUIDITY FUNCTIONS */

    /**
     * Adds liquidity having approved both tokens. The LP generated stays in this contract address. 
     * As with the autoLiquidity function, it presents a centralization risk over time. Thus, the LP 
     * generated will be recovered and locked before built up enough to warrant sufficient concern. 
     */
    function addLiquidity(uint256 tokenAmount, uint256 FTMAmount) private {
        approveInternal(address(this), address(DEXRouter), tokenAmount);        
        DEXRouter.addLiquidityETH{value: FTMAmount}(address(this),tokenAmount, 0, 0, address(this), block.timestamp);     
    }
    
    /** Swaps tokens for FTM having grabbed the router address and approved both tokens. */
    function swapTokensForFTM(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);      
        path[1] = usd;  
        path[2] = DEXRouter.WETH();     
        approveInternal(address(this), address(DEXRouter), tokenAmount);        
        DEXRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);     
    }

    function yourUSDValue(address yourAddress) public view returns (uint256) {
        address[] memory path = new address[](2);
        uint256 tokenBalance = balanceOf(yourAddress);
        uint256 zeroUsd = 0;
        
        path[0] = address(this);
        
        path[1] = usd;

        try DEXRouter.getAmountsOut(tokenBalance, path) returns (uint[] memory amounts) {
            return amounts[1];
        }
        catch {
            return zeroUsd;
        }       
    }    
        function TokenPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        uint256 zeroUsd = 0;
        
        path[0] = address(this);
       
        path[1] = usd;

        try DEXRouter.getAmountsOut(1*10**9, path) returns (uint[] memory amounts) {
            return amounts[1];
        }
        catch {
            return zeroUsd;
        }       
    }    

     /**
     * A typical auto-liquidity function often called swapAndLiquify.
     * It sells half of the YOURCOIN queued for LP conversion when the threshold is reached, triggered by sells.
     * It then grabs the amount of FTM the swap creates.
     * Finally it combines the FTM with YOURCOIN to add liquidity to the main WFTM-YOURCOIN pool to the DEX.
     * Over time, it will cause a build-up of YOURCOIN in this contract address.
     * This happens because swapping half the YOURCOIN into FTM reduces the price a bit.
     * In order to mitigate any centralization risk, YOURCOIN built up in the contract will be recovered and locked
     *  or distributed to the community.
     */
    function autoLiquidity(uint256 contractStoredReflectionTokenBalance) private {        
        inAutoLiquidity = true;
        uint256 half1 = contractStoredReflectionTokenBalance.div(2);
        uint256 half2 = contractStoredReflectionTokenBalance.sub(half1);
        uint256 initialBalance = address(this).balance;     
        swapTokensForFTM(half1); 
        uint256 newBalance = address(this).balance.sub(initialBalance);    
        addLiquidity(half2, newBalance);     
        emit AutoLiquidity(half1, newBalance, half2);
        inAutoLiquidity = false;
    }


    /* PRIVATE CALCULATION FUNCTIONS */

    /** Calculates tax from transfer amount. */
    function getTaxValues(uint256 transferAmount) private view returns (uint256[6] memory) {

        uint256[6] memory reflectLiqCharityBurnFunFeeArray;
        reflectLiqCharityBurnFunFeeArray[0] = transferAmount.mul(reflectFeePercent).div(10**2);    
        reflectLiqCharityBurnFunFeeArray[1] = transferAmount.mul(liquidityFeePercent).div(10**2);   
        reflectLiqCharityBurnFunFeeArray[2] = transferAmount.mul(charityFeePercent).div(10**2);   
        reflectLiqCharityBurnFunFeeArray[3] = transferAmount.mul(burnFeePercent).div(10**2);   
        reflectLiqCharityBurnFunFeeArray[4] = transferAmount.mul(funFeePercent).div(10**2);   
        reflectLiqCharityBurnFunFeeArray[5] = transferAmount.sub(reflectLiqCharityBurnFunFeeArray[0]).sub(reflectLiqCharityBurnFunFeeArray[1])
            .sub(reflectLiqCharityBurnFunFeeArray[2]).sub(reflectLiqCharityBurnFunFeeArray[3]).sub(reflectLiqCharityBurnFunFeeArray[4]);

        return (reflectLiqCharityBurnFunFeeArray);
    }

    /** Calculates reflections from transfer amount and tax fees. */
    function getReflectionValues(uint256 transferAmount, uint256 taxReflect, uint256 taxLiquidity, uint256 taxCharityFee, uint256 taxBurnFee, uint256 taxFunFee, uint256 currentRate) 
    private pure returns (uint256, uint256, uint256){
        uint256 reflectionAmount = transferAmount.mul(currentRate);
        uint256 reflectionFee = taxReflect.mul(currentRate);
        uint256 reflectionLiquidity = taxLiquidity.mul(currentRate);
        uint256 reflectionFeeCharity = taxCharityFee.mul(currentRate);
        uint256 reflectionFeeBurn = taxBurnFee.mul(currentRate);
        uint256 reflectionFeeFun = taxFunFee.mul(currentRate);
        uint256 reflectionTransferAmount = reflectionAmount.sub(reflectionFee).sub(reflectionLiquidity);
        reflectionTransferAmount = reflectionTransferAmount.sub(reflectionFeeCharity).sub(reflectionFeeBurn).sub(reflectionFeeFun);
        return (reflectionAmount, reflectionTransferAmount, reflectionFee);
    }

    /** Gets the total tax and reflection values from transfer amount. */
    function getTaxAndReflectionValues(uint256 tAmount) private view returns (uint256,uint256,uint256, uint256[6] memory) {

        (uint256[6] memory reflectLiqCharityBurnFunFeeArray) = getTaxValues(tAmount);
        (uint256 reflectAmount, uint256 reflectTransferAmount, uint256 reflectFee) = 
            getReflectionValues(tAmount, reflectLiqCharityBurnFunFeeArray[0], reflectLiqCharityBurnFunFeeArray[1], 
                reflectLiqCharityBurnFunFeeArray[2], reflectLiqCharityBurnFunFeeArray[3], reflectLiqCharityBurnFunFeeArray[4], getReflectRate());
        return (reflectAmount, reflectTransferAmount, reflectFee, reflectLiqCharityBurnFunFeeArray);

    }

    /** Gets the reflect rate by dividing the reflect supply by the total token supply. */
    function getReflectRate() private view returns (uint256) {
        (uint256 reflectSupply, uint256 tokenSupply) = getCurrentSupplyTotals();       
        return reflectSupply.div(tokenSupply);        
    }

    /** Subtracts the tax from the reflect totals and adds to the total tax amount. */
    function takeReflectFee(uint256 reflectFee, uint256 taxReflect) private {
        _rTotal = _rTotal.sub(reflectFee);      
        totalFeeAmount = totalFeeAmount.add(taxReflect);    
    }

    /** Takes the liquidity tax - used for calculating transactions. */
    function takeLiquidityFee(uint256 tLiquidity) private {
        uint256 currentRate = getReflectRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        reflectTokensOwned[address(this)] = reflectTokensOwned[address(this)].add(rLiquidity);
        if (isAddressExcludedFromReflections[address(this)]){
            totalTokensOwned[address(this)] = totalTokensOwned[address(this)].add(tLiquidity);
        }
    }

    /** Takes the charity tax - used for calculating transactions. */
    function takeCharityFee(uint256 taxCharityFee) private {
        uint256 currentRate = getReflectRate();
        uint256 rCharityTaxFee = taxCharityFee.mul(currentRate);
        reflectTokensOwned[charityAddress] = reflectTokensOwned[charityAddress].add(rCharityTaxFee); 
        if (isAddressExcludedFromReflections[charityAddress]){
            totalTokensOwned[charityAddress] = totalTokensOwned[charityAddress].add(taxCharityFee);
        }
    }

    /** Takes the burn tax - used for calculating transactions. */
    function takeBurnFee(uint256 taxBurnFee) private {
        uint256 currentRate = getReflectRate();
        uint256 rBurnTaxFee = taxBurnFee.mul(currentRate);
        reflectTokensOwned[deadAddress] = reflectTokensOwned[deadAddress].add(rBurnTaxFee); 
        if (isAddressExcludedFromReflections[deadAddress]){
            totalTokensOwned[deadAddress] = totalTokensOwned[deadAddress].add(taxBurnFee);
        }
    }

    /** Takes the fun tax - used for calculating transactions. */
    function takeFunFee(uint256 taxFunFee) private {
        uint256 currentRate = getReflectRate();
        uint256 rFunTaxFee = taxFunFee.mul(currentRate);
        reflectTokensOwned[funAddress] = reflectTokensOwned[funAddress].add(rFunTaxFee); 
        if (isAddressExcludedFromReflections[funAddress]){
            totalTokensOwned[funAddress] = totalTokensOwned[funAddress].add(taxFunFee);
        }
    }

    /** Removes all taxes - used to correctly process transactions for whitelisted addresses. */
    function removeAllFee() private {
        previousReflectFeePercent = reflectFeePercent;
        previousCharityFeePercent = charityFeePercent;
        previousBurnFeePercent = burnFeePercent;
        previousFunFeePercent = funFeePercent;
        previousLiquidityFeePercent = liquidityFeePercent;

        reflectFeePercent = 0;
        charityFeePercent = 0;
        burnFeePercent = 0;
        funFeePercent = 0;
        liquidityFeePercent = 0;
    }

    /** Restores all taxes - used to correctly process transactions for non-whitelisted addresses. */
    function restoreAllFee() private {
        reflectFeePercent = previousReflectFeePercent;
        charityFeePercent = previousCharityFeePercent;
        burnFeePercent = previousBurnFeePercent;
        funFeePercent = previousFunFeePercent;
        liquidityFeePercent = previousLiquidityFeePercent;
    }


    /* PUBLIC RFI FUNCTIONS */
    
    /** Returns the total YOURCOIN supply in uint256 format - 1000000000000000 i.e. 1,000,000 tokens. */
    function totalSupply() external pure override returns (uint256){
        return TOKEN_MAX_SUPPLY;   
    }
    
    /** Returns the number of decimals the token - 9. */
    function decimals() external pure override returns (uint8) {
        return TOKEN_DECIMALS;  
    }

    /** Returns the token ticker - YOURCOIN. */
    function symbol() external view override returns (string memory) {
        return _symbol;   
    }

    /** Returns the token name - YourCoin. */
    function name() external view override returns (string memory) {
        return _name;   
    }

    /** Returns the YOURCOIN balance of the address queried in uint256 format e.g. 5000000000000 = 5,000 tokens. */
    function balanceOf(address account) public view override returns (uint256) {
        if (isAddressExcludedFromReflections[account]) {   
            return totalTokensOwned[account];
        }
        return tokenFromReflection(reflectTokensOwned[account]);
    }
    
    /** Returns the current block timestamp in unix format e.g. 1635354360. 
     *  Use https://time.is/Unix_time_converter to convert to human time. 
     */
    function getNowBlockTime() external view returns (uint) {
        return block.timestamp;     
    }

    /** Returns the timestamp the contract was deployed in unix format as above. */
    function liquidityUnlockTime() external view returns (uint256) {
        return LiquidityUnlockTime;
    }
    
        /** Returns the total amount of tokens taxed in uint256 format. */
    function totalFees() external view returns (uint256) {
        return totalFeeAmount;
    }

    /** Returns the total amount of reflect tokens in uint256 format from a transfer amount with or without tax fees deducted. */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= TOKEN_MAX_SUPPLY, "Amount exceeds max supply");         
        (uint256 rAmount, uint256 rTransferAmount, , ) = getTaxAndReflectionValues(tAmount);
        if(deductTransferFee){
            return rTransferAmount;
        }
        else{
            return rAmount;
        }
    }

    /** Returns the amount of reflect tokens in uint256 format from the current reflect supply. */
    function tokenFromReflection(uint256 rAmount) public view returns (uint256){  
        require(rAmount <= _rTotal, "Amount exceeds total reflections");
        uint256 currentRate = getReflectRate();
        return rAmount.div(currentRate);
    }

    /** Gets the current supply totals by calculating from every address. */
    function getCurrentSupplyTotals() public view returns (uint256, uint256) { 

        uint256 rSupply = _rTotal;      
        uint256 tSupply = TOKEN_MAX_SUPPLY;       

        for (uint256 i = 0; i < excludedFromReflectionsAddresses.length; i++) {
            if ((reflectTokensOwned[excludedFromReflectionsAddresses[i]] > rSupply) || (totalTokensOwned[excludedFromReflectionsAddresses[i]] > tSupply)){
                return (_rTotal, TOKEN_MAX_SUPPLY);       
            } 
            rSupply = rSupply.sub(reflectTokensOwned[excludedFromReflectionsAddresses[i]]);  
            tSupply = tSupply.sub(totalTokensOwned[excludedFromReflectionsAddresses[i]]);    
            
        }

        if (rSupply < _rTotal.div(TOKEN_MAX_SUPPLY)){     
            return (_rTotal, TOKEN_MAX_SUPPLY);
        } 

        return (rSupply, tSupply);
    }
    

    /** Queries whether an address is excluded from receiving reflections and gives a boolean return. */
    function isExcludedFromReflections(address account) external view returns (bool) {
        return isAddressExcludedFromReflections[account];
    }
    
    /** Queries whether an address is whitelisted from tax fees and gives a boolean return. */
    function isExcludedFromTax(address account) external view returns (bool) {
        return isAccountExcludedFromTax[account];
    }
    

    
    /** Queries whether an address is whitelisted from the max Tx amount and gives a boolean return. */
    function isExcludedFromMaxTxAmount(address account) external view returns (bool) {
        return isAccountExcludedFromMaxTxAmount[account];
    }

    
    /* FALLBACK AND RECEIVE FUNCTIONS */
    
    // To receive FTM from the router when swapping.
    receive() external payable {}
    fallback() external payable {}
   
   
    /* ACCESS CONTROL FUNCTIONS */

    /** Returns the address of the current owner. */
    function owner() public view returns (address) {
        return ownerOfToken;       
    }
    
    /** As above. */
    function getOwner() external view override returns (address) {
        return owner(); 
    }
    
    /** Enables use of privileged functions that can only be called by the owner. */
    modifier onlyOwner() {
        require(ownerOfToken == _msgSender(), "Requires owner");
        _;      
    }
    modifier hasEnoughUsdToChangeStuff() {
        require(hasEnoughUsd() || _msgSender() == owner(), "Sorry: You don't hold enough USD to change Tokenomics");
        //require(contractCreated + warmUp < block.timestamp || _msgSender() == owner(), "Sorry:  Token in warmup");
        _;
    }

    modifier hasEnoughUsdToAdmin() {
        require(hasEnoughAdminUsd() || _msgSender() == owner(), "Sorry: You don't hold enough USD to change Token Meta");
        //require(contractCreated + warmUp < block.timestamp || _msgSender() == owner(), "Sorry:  Token in warmup");
        _;
    }

    modifier hasEnoughUsdToMarket() {
        require(hasEnoughMarketUsd() || _msgSender() == owner(), "Sorry: You don't hold enough USD to change Token Meta");
        //require(contractCreated + warmUp < block.timestamp || _msgSender() == owner(), "Sorry:  Token in warmup");
        _;
    }

    modifier hasEnoughUsdToPost() {
        require(hasEnoughPostUsd() || _msgSender() == owner(), "Sorry: You don't hold enough USD to change Post messages");
        //require(contractCreated + warmUp < block.timestamp || _msgSender() == owner(), "Sorry:  Token in warmup");
        _;
    }

  
    
    /** Allows the owner to change the owner address e.g. to a multisig wallet. */
    function transferOwnership(address _newAddress) external onlyOwner() {     
        require(_newAddress != address(0), "Zero address");   
        emit OwnershipTransferred(ownerOfToken, _newAddress);
        previousOwnerOfToken = ownerOfToken;
        ownerOfToken = _newAddress;
    }  
   
   
    /* ALLOWANCE FUNCTIONS */
    function hasEnoughUsd() private view returns (bool) {
        return yourUSDValue(_msgSender()) >= _minUsdAmtToChangeToken;
    }   
    function hasEnoughAdminUsd() private view returns (bool) {
        return yourUSDValue(_msgSender()) >= _minUsdAmtTobeAdmin;
    }
    function hasEnoughMarketUsd() private view returns (bool) {
        return yourUSDValue(_msgSender()) >= _minUsdAmtToMarket;
    }

    function hasEnoughPostUsd() private view returns (bool) {
        return yourUSDValue(_msgSender()) >= _minUsdAmtToChangeTokenPost;
    }     

    /** Returns number of tokens remaining in uint256 format that spender is allowed to approve or transfer. */
    function allowance(address ownerAddr, address spender) external view override returns (uint256) { 
        return allowanceAmount[ownerAddr][spender]; 
    }

    /** Approves token spend for the spender address. */
    function approve(address spender, uint256 amount) external override returns (bool){
        approveInternal(_msgSender(), spender, amount);     
        return true;
    }

    /** Increases the token spend allowance for the spender address. */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        approveInternal(_msgSender(), spender, allowanceAmount[_msgSender()][spender].add(addedValue));
        return true;
    }

    /** Decreases the token spend allowance for the spender address. */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool){
        approveInternal(_msgSender(),spender,allowanceAmount[_msgSender()][spender].sub(subtractedValue,"Cannot decrease allowance below 0."));
        return true;
    }
    
    /** Internal function to approve token spend. */
    function approveInternal(address ownerAddr, address spender, uint256 amount) private { 
        require(ownerAddr != address(0) && spender != address(0), "Zero address");
        allowanceAmount[ownerAddr][spender] = amount;
        emit Approval(ownerAddr, spender, amount);
    }

    
    /* PRIVILEGED DEX-UPDATING FUNCTIONS */

    /**
     * Function: Allows the owner to change the DEX router address the contract uses.
     *  
     * Justification: It would be called in the unlikely event that the DEX re-deploys its router 
     *  or if there is ever a need to desire to move over to a different DEX. This kind of Function
     *  would not be necessary on an established chain using an established and trusted DEX such as
     *  Uniswap, however the owner believes that having this function is necessary because the
     *  FTMnos chain is new at the time this contract is deployed, and there will be no established
     *  DEX as a result.
     * 
     * Risk statement: Owner could change the router address maliciously to a honeypot.
     * 
     * Mitigation: Safeguard prevents router being set to the zero address. 
     * Function emits an event on the explorer when called, clearly broadcasting
     *  the new router address for everytone to see.
     */
    function setRouterAddress(address _newAddress) external onlyOwner() {
        require(_newAddress != address(0), "Zero address");
        emit RouterAddressChanged(DEXRouterAddress, _newAddress);
        previousDEXRouterAddress = DEXRouterAddress;
        DEXRouterAddress = _newAddress;
        IDEXRouter02 DEXRouterLocal = IDEXRouter02(DEXRouterAddress);      
       
        DEXRouter = DEXRouterLocal;   
    }

    /**
     * Function: Allows the owner to change the liquidity pair the contract uses.
     *  
     * Justification: It would be called in the plausible event that was ever a need or desire
     *  to move over to a different DEX, which would have its own LP addresses. In a likely 
     *  situation where we have liquidity in more than one LP pair or on more than one DEX, 
     *  it could be called to change which pair autoFTM liquidity is added to.
     * 
     * Risk statement: Owner could change the LP address maliciously in order to change where
     *  liquidity is added. 
     * 
     * Mitigation: Function emits an event on the explorer when called, clearly broadcasting
     *  the new pair address for everyone to see.
     */
    function setPairAddress(address _newAddress) external onlyOwner() {
        require(_newAddress != address(0), "Zero address");
        emit PairAddressChanged(DEXPair, _newAddress);
        previousDEXPair = DEXPair;
        DEXPair = _newAddress;
    }
    
    
    /* PRIVILEGED PROJECT ADDRESS-UPDATING FUNCTIONS */

    /**
     * These allow the owner to change the Charity, Growth or Fun wallets to any address.
     *  
     * Justification: They would be called in the unlikely event that access to the original 
     *  wallets are lost, or if there is a plausible need to change them due to security concerns.
     * 
     * Risk statement: Owner could change them to different addresses to obfuscate where the 
     *  taxed tokens are sent and then dump them undetected.
     * 
     * Mitigation: Functions emit an event on the explorer when called, clearly broadcasting
     *  the change of addresses. Any such events will be made clear to the community.
     */
     

 

    



    /* PRIVILEGED FLEXIBLE TOKENOMICS FUNCTIONS */

    /**
     * Function: Allows the user with enough tokens  to change the liquidity lock the contract uses.
     *  
     * Risk statement:Anyone with enough tokens can extend the lock period. 
     * 
     */

    function ExtendLiquidityLock() external hasEnoughUsdToAdmin() {
       
       LiquidityUnlockTime= block.timestamp + 30 days;
         emit LiquidityLockExtended(LiquidityUnlockTime);
    } 
   
 

    /**
     * Function: Allows owner to withdraw the liquidity .
     *  
     * Risk statement: Owner could remove the LP when the unlock time is reached.
     * 
     * Mitigation: 
     *  It is requires that the curent block.timestamp is greater than the liquidity unlock time
     *  wich is setby any user with enough tokens.
     *  Function emits an event on the explorer when called, clearly broadcasting
     *  the removal for everyone to see.
     */   

    function WithdrawLiquidity(address _DEXPair) external onlyOwner() {
        require(block.timestamp >= LiquidityUnlockTime, "Liquidity Still Locked" );
        emit LiquidityWithdraw( payableAddr(), IERC20(_DEXPair).balanceOf(address(this)));
        IERC20(_DEXPair).safeTransfer(payableAddr(), IERC20(_DEXPair).balanceOf(address(this)));
    }    
   

     /**
     * Function: Allows the owner to set the max Tx limit to any value above 1000.
     *  
     * Justification: This is an indispensible element of our flexible tokenomics.
     *  The max Tx amount is initially set at 0 as an anti-snipe measure while the owner
     *  sets the conditions for a fair launch. It will then be set to 1000 for launch,
     *  and is intended to even the playing field and reduce Tx failure due to price impact.
     *  The limit will then gradually be raised shortly after launch to 2500 and then 5000. 
     *  Any changes thereafter will be decided with the input of the TrueDao.
     * 
     * Risk statement: Owner could change the max Tx limit to any value above 1000 at any
     *  time due to the absence of a time-lock.
     * 
     * Mitigation: Safeguard added so that the limit cannot be changed to below 1000.
     *  Function emits an event on the explorer when called, clearly broadcasting
     *  the limit change. Limit will not be changed after being raised to 5000 without
     *  the input of the TrueDao. The owner, Charity, Growth and Fun addresses are
     *  whitelisted from this limit by default, therefore this function does not pose an
     *  additional risk to the community.
     */
    function setMaxTxAmount (uint256 _newValue) external onlyOwner() {
        require(_newValue >= _MinAmount, "Min limit 1000 tokens");
        require(_newValue != maxTxAmount, "Value already set");
        emit MaxTxAmountChanged(maxTxAmount, _newValue);
        previousMaxTxAmount = maxTxAmount;
        maxTxAmount = _newValue;
    }
    
    /**
     * Function: Allows the owner to set the max wallet limit to any value above 10000.
     *  
     * Justification: This is an indispensible element of our flexible tokenomics.
     *  The max wallet is initially set at 1000000 so that the owner can add initial
     *  liquidity without the Tx failing. It will then be set to 10000 before trading
     *  is enabled and will function as an anti-whale measure. Owner will gradually
     *  increase the limit in 2500 or 5000 intervals up to 25000 with the input of the
     *  TrueDao. These measures ensure that the launch is as fair as possible.
     * 
     * Risk statement: Owner could change the max wallet limit at any time to any value
     *  between 5-10% due to the absence of a time-lock.
     * 
     * Mitigation: Safeguard added so that the limit cannot be changed to below 10000.
     *  Function emits an event on the explorer when called, clearly broadcasting
     *  the limit change. Limit will not be raised without the input of the TrueDao.
     */
    
    /** Allows the owner to adjust the max wallet to an amount that must be greater than 10,000 tokens. */
    function setMaxWallet (uint256 _newValue) external hasEnoughUsdToAdmin {
        require(_newValue >= _MinAmount, "Min limit 10000 tokens");
        require(_newValue != maxWallet, "Value already set");
        emit MaxWalletChanged(maxWallet, _newValue);
        previousMaxWallet = maxWallet;
        maxWallet = _newValue;
    }


     /**
     * Mitigation: Reasonable lower and upper bounds of 5% and 10% were chosen to ensure 
     *  the tax cannot be raised to a prohibitively high or unfairly low value. Function emits 
     *  an event on the explorer when called, clearly broadcasting the tax change. Tax will not 
     *  be changed unilaterally without the input of the TrueDao. The owner, Charity, Growth
     *  and Fun addresses are whitelisted from all taxes by default, therefore there is no
     *  financial incentive for a malicious actor to decrease them.
     */
    function setReflectFeePercent(uint256 _newPercent) external hasEnoughUsdToChangeStuff() {
        require(_newPercent >= 3 && _newPercent <= 10, "Reflect fee must be between 3-10");
        require(_newPercent != reflectFeePercent, "Value already set");
        emit ReflectFeePercentChanged(reflectFeePercent, _newPercent);
        previousReflectFeePercent = reflectFeePercent;
        reflectFeePercent = _newPercent;
    }


    /**
     * Function: Allows the owner to set the burn tax between 0-5%.
     *  
     * Justification: As above. Changing the burn tax is potentially one of the most
     * fun and effective ways of altering the token's dynamics, therefore the upper
     * bound is higher at 5%. YOURCOIN can be deflationary or not - frens decide.
     * 
     * Risk statement: Owner could change the burn tax at any time to any value
     *  between 0-5% due to the absence of a time-lock.
     * 
     * Mitigation: As above, with 0-5% bounds.
     */
    function setBurnFeePercent(uint256 _newPercent) external hasEnoughUsdToChangeStuff() {
        require(_newPercent >= 6 && _newPercent <= 20, "Burn fee must be between 6-20");
        require(_newPercent != burnFeePercent, "Value already set");
        emit BurnFeePercentChanged(burnFeePercent, _newPercent);
        previousBurnFeePercent = burnFeePercent;
        burnFeePercent = _newPercent;
    }
    function setFunFeePercent(uint256 _newPercent) external hasEnoughUsdToMarket() {
        require(_newPercent >= 0 && _newPercent <= 3, "Burn fee must be between 0-3");
        require(_newPercent != burnFeePercent, "Value already set");
        emit FunFeePercentChanged(funFeePercent, _newPercent);
        previousFunFeePercent = funFeePercent;
        funFeePercent = _newPercent;
    }    
    function setFunAddress(address _newaddress) external hasEnoughUsdToMarket() {
        require(_newaddress != funAddress, "address already set");
        emit FunAddressChanged(funAddress, _newaddress);
        previousFunAddress = funAddress;
        funAddress = _newaddress;
    }  
  

    /**
     * Function: Allows the owner to set the liquidity tax between 1-5%.
     *  
     * Justification: As above. Managing liquidity carefully is crucial and this
     *  is achieved by adjusting the liquidity tax along with the conversion threshold.
     *  If liquidity is particularly strong, the TrueDao may wish to prioritize
     *  other aspects of the tokenomics.
     * 
     * Risk statement: Owner could change the liquidty tax at any time to any value
     *  between 1-5% due to the absence of a time-lock.
     * 
     * Mitigation: As above, with 1-5% bounds. The owner believes that there
     *  should always be some amount of auto-liquidity, therefore the lower bound
     *  is 1% rather than 0%.
     */
    function setLiquidityFeePercent(uint256 _newPercent) external hasEnoughUsdToChangeStuff() {
        require(_newPercent >= 1 && _newPercent <= 5, "Liquidity fee must be between 1-5");
        require(_newPercent != liquidityFeePercent, "Value already set");
        emit LiquidityFeePercentChanged(liquidityFeePercent, _newPercent);
        previousLiquidityFeePercent = liquidityFeePercent;
        liquidityFeePercent = _newPercent;
    }
    
    /**
     * Function: Allows the owner to toggle autoFTM liquidity on and off.
     *  
     * Justification: Though deemed unlikely, being able to momentarily disable 
     *  auto-liquidity is important to be able to resolve hypothetical issues
     *  that may arise, such as being unable to withdraw YOURCOIN from a token
     *  locker because the tokenomics cause the Tx to fail, or gas estimation
     *  issues on sells due to the additional gas burden auto-liquidity adds.
     * 
     * Risk statement: Owner could toggle auto-liquidity off for an extended period
     *  which would result in a significant build-up of YOURCOIN in this contract address
     *  due to the tax and reflections gained. The YOURCOIN could then be recovered from
     *  the contract by the owner and dumped.
     * 
     * Mitigation: Function emits an event on the explorer when called, clearly broadcasting
     *  when auto-liquidity is toggled on or off.
     */
    function setAutoLiquidityEnabled(bool enableAutoLiquidity) external hasEnoughUsdToChangeStuff() {     
        isAutoLiquidityEnabled = enableAutoLiquidity;   
        emit AutoLiquidityEnabledUpdated(enableAutoLiquidity);
    }


    
    
    /* PRIVILEGED WHITELISTING FUNCTIONS */

    /**
     * Function: Allows the owner to exclude any address from receiving reflections.
     *  
     * Justification: The most important use of this function is to exclude LP addresses
     *  from reflections, otherwise they would swallow up the vast majority of them
     *  because they hold most of the YOURCOIN. The burn address is also excluded for The
     *  same reason. Finally, the function exists to deter anyone from attempting to
     *  circumvent the anti-whale measures by filling multiple wallets with the max amount
     *  on launch. It will only be used for this purpose if the abuser in question is
     *  deemed to threaten the future of the project by holding more YOURCOIN than intended,
     *  and will never be used without fair warning first.
     * 
     * Risk statement: Owner could toggle auto-liquidity off for an extended period
     *  which would result in a significant build-up of YOURCOIN in this contract address
     *  due to the tax and reflections gained. The YOURCOIN could then be recovered from
     *  the contract by the owner and dumped.
     * 
     * Mitigation: There is no mitigation for this in principle. The owner recognises that
     *  it is a powerful permission that must not ever be abused.
     */
    function excludeFromReflections(address _address) external onlyOwner() {
        require(_address != DEXRouterAddress, "Router exclusion disallowed");    
        require(!isAddressExcludedFromReflections[_address], "Address is already excluded");
        emit AddressExcludedFromReflections(_address);
        if (reflectTokensOwned[_address] > 0) {
            totalTokensOwned[_address] = tokenFromReflection(reflectTokensOwned[_address]);   
        }
        isAddressExcludedFromReflections[_address] = true;
        excludedFromReflectionsAddresses.push(_address);
    }

   

    /**
     * Function: Allows the owner to whitelist any address from all taxes.
     *  
     * Justification: This function exists primarily to whitelist YOURCOIN pools so that 
     *  frens do not get hammered by tax from staking and unstaking. It can also be used
     *  to whitelist the Fren Co. wallet addresses should they ever be changed. Moreover,
     *  to whitelist a zapper contract so that frens can use farms completely tax-free.
     * 
     * Risk statement: No additional risk posed due to the fact that the owner, Growth,
     *  Charity and Fun wallets are already whitelisted from taxes by default.
     * 
     * Mitigation: N/A.
     */
    function excludeFromTax(address _address) external onlyOwner() {
        isAccountExcludedFromTax[_address] = true;
        emit AddressWhitelistedFromTax(_address);
    }




    /**
     * Function: Allows the owner to whitelist any address from the max wallet limit.
     *  
     * Justification: This function is critical to be able to solve a number of potential
     *  issues: a fren may be unable to unstake YOURCOIN from a pool, harvest from a farm or 
     *  break LP if the Tx would take them over the max wallet limit; a fren may be unable 
     *  to receive YOURCOIN from giveaways and competitions. These isues are only expected to
     *  arise if at all shortly after launch before the market cap has matured. Thereafter,
     *  it is expected that the majority of wallets will not exceed the max wallet amount,
     *  which will have been raised since launch. It could also be used to whitelist new
     *  Fren Co. addresses and LP addresses if the need arises.
     * 
     * Risk statement: No additional risk posed due to the fact that the owner, Growth,
     *  Charity and Fun wallets are already whitelisted from the max wallet limit by default.
     * 
     * Mitigation: N/A.
     */
    function excludeFromMaxWallet(address _address) external onlyOwner() {
        isAccountExcludedFromMaxWallet[_address] = true;
        emit AddressWhitelistedFromMaxWallet(_address);
    }
    
    /**
     * Function: Allows the owner to re-include any address in the max wallet limit.
     *  
     * Justification: As above - this function will rarely be called, in order to
     *  de-whitelist a wallet address from the max wallet limit after having been 
     *  temporarily whitelisted.
     * 
     * Risk statement: Owner could de-whitelist the contract addresses for pools
     *  to break deposits but not withdrawals, but there would be little incentive
     *  to do so.
     * 
     * Mitigation: N/A.
     */
    function includeInMaxWallet(address _address) external onlyOwner() {
        isAccountExcludedFromMaxWallet[_address] = false;
        emit AddressIncludedInMaxWallet(_address);
    }
    
    /**
     * Function: Allows the owner to whitelist any address from the max Tx limit.
     *  
     * Justification: This function may be called to resolve issues where frens are unable
     *  to unstake YOURCOIN or break LP due to it violating the max Tx limit. It can also be used
     *  to whitelist new Fren Co. addresses should the need ever arise to change them.
     * 
     * Risk statement: No additional risk posed due to the fact that the owner, Growth,
     *  Charity and Fun wallets are already whitelisted from the max Tx limit by default.
     *  Only the owner address is able to evade the max Tx limit while swapping, whereas 
     *  all the above addresses can evade it while sending.
     * 
     * Mitigation: N/A.
     */
    function excludeFromMaxTxAmount(address _address) external onlyOwner() {
        isAccountExcludedFromMaxTxAmount[_address] = true;
        emit AddressWhitelistedFromMaxTx(_address);
    }
    
    /**
     * Function: Allows the owner to re-include any address in the max Tx limit.
     *  
     * Justification: As above - this function will rarely be called, in order to
     *  de-whitelist a wallet address from the max Tx limit after having been 
     *  temporarily whitelisted.
     * 
     * Risk statement: No additional risk posed due to the fact that the owner, Growth,
     *  Charity and Fun wallets are already whitelisted from the max Tx limit by default.
     * 
     * Mitigation: N/A.
     */
    function includeInMaxTxAmount(address _address) external onlyOwner() {
        isAccountExcludedFromMaxTxAmount[_address] = false;
        emit AddressIncludedInMaxTx(_address);
    }

    /* PRIVILEGED TOKEN RECOVER FUNCTIONS */
    
  

    
    /**
     * Function: Allows the owner to withdraw the total balance of a specific ERC20 token 
     *  from the YOURCOIN contract.
     *  
     * Justification: As above but for any token. The owner does not preclude the possibility of 
     *  taking some of this LP, breaking it, distributing the YOURCOIN back to the community via 
     *  the Growth wallet and keeping some FTM for personal use. This is hoped to be viewed as a 
     *  reasonable action due to the fact that 0% of the initial supply is held in reserve as an ROI. 
     * 
     * Risk statement: As above but for any token. Could be called to withdraw YOURCOIN awaiting
     *  LP conversion but this is redundant with the function below. Owner could withdraw all LP
     *  which would be of significant value once the market cap has matured and dump it.
     *  Clearly this presents a centralization risk and requires an amount of trust. It also 
     *  exists for if there arises a need or desire to add liquidity to another DEX before the LP
     *  from the initial liquidity has unlocked from the LP locker. 
     * 
     * Mitigation: Owner will regularly withdraw and lock or burn the accumulated LP
     *  to build trust and prevent it from creating a large centralization risk. Any intentions 
     *  to withdraw LP from the contract will be clearly announced and the input of the TrueDao 
     *  will be welcomed.
     */
    function recoverERC20(address _token) external onlyOwner() {
        emit ERC20Recovered(_token, payableAddr(), IERC20(_token).balanceOf(address(this)));
        IERC20(_token).safeTransfer(payableAddr(), IERC20(_token).balanceOf(address(this)));
    }
    
    /**
     * Function: Allows the owner to withdraw all FTM from the YOURCOIN contract.
     *  
     * Justification: The reason this is called a recover function is that its intended
     *  use is to recover FTM sent accidentally to the YOURCOIN contract address. This is
     *  a common and often costly mistake that usually results in tokens being lost forever.
     *  Some FTM will build up in the contract over time as a byproduct of the autoLiquidity 
     *  function. This is because every time half the amount of the auto-liquidity threshold 
     *  in YOURCOIN is swapped for FTM and combined to form LP, the swap itself marginally reduces 
     *  the price of YOURCOIN. The autoLiquidity function does not account for this the next 
     *  time it is called.
     * 
     * Risk statement: The amount of FTM that builds up due to auto-liquidity is likely to
     *  become significant over time, and this presents a centralization risk. 
     * 
     * Mitigation: The FTM will most likely be locked or redistributed to the community, with a 
     *  reasonable amount that could be kept aside for the owner's personal use after consultation 
     *  with the TrueDao.
     */
    function recoverFTM() external onlyOwner()  { 
        emit FTMRecovered(payableAddr(), balanceOf(address(this)));
        payableAddr().transfer(address(this).balance);
    }
    
    /** Gets the address to which tokens can be recovered from the YOURCOIN contract - the owner wallet. */
    function payableAddr() private view returns (address payable) {
        address payable payableMsgSender = payable(owner());      
        return payableMsgSender;
    }

}