/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// File: contracts\libs\Context.sol

pragma solidity ^0.8.0;

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\libs\Ownable.sol

pragma solidity ^0.8.0;


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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\libs\Pausable.sol

pragma solidity ^0.8.0;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// File: contracts\libs\SafeMath.sol

pragma solidity ^0.8.0;

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

// File: contracts\libs\IBEP20.sol

pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts\libs\Address.sol

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts\libs\SafeBEP20.sol

pragma solidity ^0.8.0;



/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Factory.sol

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

// File: contracts\Merchant.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Merchant is Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    enum FeeMethod {
        SINGLE,
        DOUBLE
    }

    struct TransctionInfo {
        bytes16 txId;
        address userAddress;
        address payingToken;
        uint256 amount;
        uint256 timeStamp;
    }

    // Merchant factory contract address
    address public MERCHANT_FACTORY;

    // Whether it is initialized
    bool public isInitialized;
    
    // Change USDT test net address
    IBEP20 public constant USDT =
    IBEP20(address(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684));
    
    uint16 public transactionFee = 10; // Transaction fee multiplied by 100
    uint16 public constant MAX_TRANSACTION_FEE = 1000; // Max transacton fee 10%
    uint256 public wpayBalanceForFreeTransaction = 1000 ether; // If any wallet has 1000 WPAY tokens, it will be exempted from the transaction fee

    uint256 public minAmountToProcessFee = 1 ether; // When there is 1 BNB staked, fee will be processed
    FeeMethod public feeProcessingMethod = FeeMethod.SINGLE; // How to process fee

    IUniswapV2Router02 public pancakeV2Router =
        IUniswapV2Router02(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3)); // Pancake V2 router
    address public wpayBnbPair; // WPAY-BNB Pair

    address payable public marketingWallet; // Marketing address
    address public merchantWallet; // Merchant wallet

    IBEP20 public WPAY_TOKEN;

    uint256 public totalTxCount;
    mapping(address => uint256) public userTxCount;
    mapping(bytes16 => TransctionInfo) private txDetails;
    mapping(address => bytes16[]) private userTxDetails;

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event PancakeRouterUpdated(
        address indexed operator,
        address indexed router,
        address indexed pair
    );
    event MarketingWalletUpdated(
        address payable previousWallet,
        address payable newWallet
    );
    event MerchantWalletUpdated(
        address payable previousWallet,
        address payable newWallet
    );
    event TransactionFeeUpdated(uint16 previousFee, uint16 newFee);
    event WpayBalanceForFreeTransactionUpdated(
        uint256 previousBalance,
        uint256 newBalance
    );
    event NewTransaction(
        bytes16 txId,
        address userAddress,
        address payingToken,
        uint256 amount,
        uint256 timeStamp
    );

    constructor() {
        MERCHANT_FACTORY = _msgSender();
    }

    /**
     * @dev Initialize merchant contract
     * Only merchant factory callable
     */
    function initialize(
        address _wpayTokenAddress,
        address _marketingWallet,
        address _merchantWallet,
        address _admin
    ) external {
        require(!isInitialized, "Merchant:: already initialized");
        require(MERCHANT_FACTORY == _msgSender(), "Merchant:: only merchant factory can call this function");

        require(_wpayTokenAddress != address(0), "Mearchant:: invalid WPAY token address");
        require(_marketingWallet != address(0), "Merchant:: invalid marketing wallet address");
        require(_merchantWallet != address(0), "Merchant:: invalid merchant wallet address");
        require(_admin != address(0), "Merchant:: invalid admin address");

        WPAY_TOKEN = IBEP20(_wpayTokenAddress);

        wpayBnbPair = IUniswapV2Factory(pancakeV2Router.factory()).getPair(
            address(WPAY_TOKEN),
            pancakeV2Router.WETH()
        );

        marketingWallet = payable(_marketingWallet);
        emit MarketingWalletUpdated(payable(address(0)), marketingWallet);

        merchantWallet = _merchantWallet;
        emit MerchantWalletUpdated(payable(address(0)), payable(merchantWallet));

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /**
     * @dev Handle fee
     */
    function handleFee() internal {
        if (marketingWallet == address(0)) {
            return;
        }

        uint256 etherBalance = address(this).balance;
        // Fee will be processed only when it is more than specific amount
        if (etherBalance < minAmountToProcessFee || etherBalance == 0) {
            return;
        }

        if (feeProcessingMethod == FeeMethod.SINGLE) {
            marketingWallet.transfer(etherBalance);
        }
        if (feeProcessingMethod == FeeMethod.DOUBLE) {
            require(
                address(wpayBnbPair) != address(0),
                "Invalid WPAY-BNB Pair"
            );

            // 50% of staked fee is added to WPAY-BNB liquidity and sent to the marketing address
            uint256 liquidifyBalance = etherBalance.div(2);

            uint256 half = liquidifyBalance.div(2);
            uint256 otherHalf = liquidifyBalance.sub(half);

            uint256 initialWpayBalance = WPAY_TOKEN.balanceOf(address(this));

            // Swap bnb to wpay
            swapBnbToWpay(half);
            uint256 newWpayBalance = WPAY_TOKEN.balanceOf(address(this)).sub(
                initialWpayBalance
            );
            // Add liquidity
            addLiquidity(newWpayBalance, otherHalf);

            // 50% of staked fee is swapped to WPAY tokens to be sent to the marketing address
            uint256 directSwapBalance = address(this).balance;
            // Swap bnb to wpay
            swapBnbToWpay(directSwapBalance);
            // Send wpay tokens to marketing address
            WPAY_TOKEN.safeTransfer(
                marketingWallet,
                WPAY_TOKEN.balanceOf(address(this))
            );
        }
    }

    /// @dev Swap tokens for eth
    function swapBnbToWpay(uint256 etherAmount) private {
        // generate the pantherSwap pair path of bnb -> wpay
        address[] memory path = new address[](2);
        path[0] = pancakeV2Router.WETH();
        path[1] = address(WPAY_TOKEN);

        // make the swap
        pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: etherAmount
        }(
            0, // accept any amount of WPAY
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 wpayAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        WPAY_TOKEN.safeApprove(address(pancakeV2Router), wpayAmount);

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: bnbAmount}(
            address(WPAY_TOKEN),
            wpayAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp
        );
    }

    /**
     * @dev Swap token to usdt and transfer to the merchant wallet
     */
    function swapTokenToUsdtAndTransferToMerchantWallet(
        address _tokenAddress,
        uint256 _amountIn
    ) private {
        IBEP20 token = IBEP20(_tokenAddress);
        require(
            token.balanceOf(address(this)) >= _amountIn,
            "Merchant:: Insufficient token balance"
        );

        if (_tokenAddress == address(USDT)) {
            USDT.transfer(merchantWallet, _amountIn);
        } else if (_tokenAddress == pancakeV2Router.WETH()) {
            // generate the pantherSwap pair path of bnb -> usdt
            address[] memory path = new address[](2);
            path[0] = pancakeV2Router.WETH();
            path[1] = address(USDT);

            // make the swap
            pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                0, // accept any amount of usdt
                path,
                merchantWallet,
                block.timestamp
            );
        } else {
            // generate the pantherSwap pair path of bnb -> usdt
            address[] memory path = new address[](3);
            path[0] = _tokenAddress;
            path[1] = pancakeV2Router.WETH();
            path[2] = address(USDT);

            // make the swap
            pancakeV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountIn,
                    0, // accept any amount of usdt
                    path,
                    merchantWallet,
                    block.timestamp
                );
        }
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the owner.
     */
    function updatePancakeRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router address");
        pancakeV2Router = IUniswapV2Router02(_router);
        wpayBnbPair = IUniswapV2Factory(pancakeV2Router.factory()).getPair(
            address(WPAY_TOKEN),
            pancakeV2Router.WETH()
        );
        emit PancakeRouterUpdated(_msgSender(), _router, wpayBnbPair);
    }

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable _marketingWallet)
        external
        onlyOwner
    {
        require(_marketingWallet != address(0), "Invalid marketing address");
        emit MarketingWalletUpdated(marketingWallet, _marketingWallet);
        marketingWallet = _marketingWallet;
    }

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address _merchantWallet) external onlyOwner {
        require(_merchantWallet != address(0), "Invalid merchant address");
        emit MerchantWalletUpdated(payable(merchantWallet), payable(_merchantWallet));
        merchantWallet = _merchantWallet;
    }

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 _fee) external onlyOwner {
        require(
            _fee <= MAX_TRANSACTION_FEE,
            "Exceeds the limit of transaction fee"
        );
        require(transactionFee != _fee, "Already set");
        emit TransactionFeeUpdated(transactionFee, _fee);
        transactionFee = _fee;
    }

    /**
     * @dev Update the wpay balance for free transaction
     * Can only be called by the owner
     */
    function updateWpayBalanceForFreeTransaction(uint256 _wpayBalance)
        external
        onlyOwner
    {
        require(wpayBalanceForFreeTransaction != _wpayBalance, "Already set");
        emit WpayBalanceForFreeTransactionUpdated(
            wpayBalanceForFreeTransaction,
            _wpayBalance
        );
        wpayBalanceForFreeTransaction = _wpayBalance;
    }

    /**
     * @dev Get in-amount to get out-amount of USDT
     * @return in-amount of token
     */
    function getAmountIn(address _payingTokenAddress, uint256 amountOut)
        public
        view
        returns (uint256)
    {
        if (address(pancakeV2Router) == address(0)) {
            return 0;
        }
        if (_payingTokenAddress == address(USDT)) {
            return amountOut;
        }
        address WETH = pancakeV2Router.WETH();
        if (_payingTokenAddress == WETH) {
            address[] memory path_2 = new address[](2);
            path_2[0] = _payingTokenAddress;
            path_2[1] = address(USDT);
            uint256[] memory amounts_2 = pancakeV2Router.getAmountsIn(
                amountOut,
                path_2
            );
            return amounts_2[0];
        }
        address[] memory path_3 = new address[](3);
        path_3[0] = _payingTokenAddress;
        path_3[1] = WETH;
        path_3[2] = address(USDT);
        uint256[] memory amounts_3 = pancakeV2Router.getAmountsIn(amountOut, path_3);
        return amounts_3[0];
    }

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of USDT
     */
    function getAmountOut(address _payingTokenAddress, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        if (address(pancakeV2Router) == address(0)) {
            return 0;
        }
        if (_payingTokenAddress == address(USDT)) {
            return amountIn;
        }
        address WETH = pancakeV2Router.WETH();
        if (_payingTokenAddress == WETH) {
            address[] memory path_2 = new address[](2);
            path_2[0] = _payingTokenAddress;
            path_2[1] = address(USDT);
            uint256[] memory amounts_2 = pancakeV2Router.getAmountsOut(
                amountIn,
                path_2
            );
            return amounts_2[1];
        }
        address[] memory path_3 = new address[](3);
        path_3[0] = _payingTokenAddress;
        path_3[1] = WETH;
        path_3[2] = address(USDT);
        uint256[] memory amounts_3 = pancakeV2Router.getAmountsOut(amountIn, path_3);
        return amounts_3[2];
    }

    /**
     * @dev Get fee amount from the in-amount of token
     * @return fee amount in BNB
     */
    function getFeeAmount(address _payingTokenAddress, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        uint256 wpayBalanceOfCaller = WPAY_TOKEN.balanceOf(_msgSender());
        if (wpayBalanceOfCaller >= wpayBalanceForFreeTransaction) {
            return 0;
        }
        uint256 feeAmount = amountIn.div(uint256(transactionFee));
        if (feeAmount == 0) {
            return 0;
        }

        // Get fee amount in BNB
        address[] memory path = new address[](2);
        path[0] = _payingTokenAddress;
        path[1] = address(pancakeV2Router.WETH());
        uint256[] memory amounts = pancakeV2Router.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAddress != address(WPAY_TOKEN), "Cannot be $WPAY token");

        IBEP20(_tokenAddress).safeTransfer(_msgSender(), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    }

    function generateID(
        address x,
        uint256 y,
        bytes1 z
    ) internal pure returns (bytes16 b) {
        b = toBytes16(uint256(keccak256(abi.encodePacked(x, y, z))));
    }

    function generateTxID(address _userAddress)
        internal
        view
        returns (bytes16 stakeID)
    {
        return generateID(_userAddress, userTxCount[_userAddress], 0x01);
    }

    function getTxDetailById(bytes16 _txNumber)
        public
        view
        returns (TransctionInfo memory)
    {
        return txDetails[_txNumber];
    }

    function transactionPagination(
        address _userAddress,
        uint256 _offset,
        uint256 _length
    ) external view returns (bytes16[] memory _txIds) {
        uint256 start = _offset > 0 && userTxCount[_userAddress] > _offset
            ? userTxCount[_userAddress] - _offset
            : userTxCount[_userAddress];

        uint256 finish = _length > 0 && start > _length ? start - _length : 0;

        _txIds = new bytes16[](start - finish);
        uint256 i;
        for (uint256 _txIndex = start; _txIndex > finish; _txIndex--) {
            bytes16 _txID = generateID(_userAddress, _txIndex - 1, 0x01);
            _txIds[i] = _txID;
            i++;
        }
    }

    function getUserTxCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userTxCount[_userAddress];
    }

    function getUserAllTxDetails(address _userAddress)
        public
        view
        returns (uint256, bytes16[] memory)
    {
        return (userTxCount[_userAddress], userTxDetails[_userAddress]);
    }

    function updateWPayTokenAddress(address _tokenAddress) external onlyOwner {
        require(
            _tokenAddress != address(0x0),
            "Merchant: Invalid _token Address"
        );

        WPAY_TOKEN = IBEP20(_tokenAddress);
    }

    /**
     * @dev Submit transaction
     * @return txNumber Transaction number
     */
    function submitTransaction(address _payingTokenAddress, uint256 _amountIn)
        external
        payable
        whenNotPaused
        returns (bytes16 txNumber)
    {
        require(
            _amountIn > 0,
            "Merchant: Tansaction amount should be non-zero"
        );

        IBEP20 payingToken = IBEP20(_payingTokenAddress);

        require(
            payingToken.balanceOf(_msgSender()) >= _amountIn,
            "Merchant: User wallet does not have enough balance"
        );

        uint256 feeAmount = getFeeAmount(_payingTokenAddress, _amountIn);
        require(msg.value >= feeAmount, "Merchant:: Insufficient fee amount");

        uint256 balanceBefore = payingToken.balanceOf(address(this));
        require(
            payingToken.transferFrom(_msgSender(), address(this), _amountIn),
            "Merchant: TransferFrom failed"
        );
        _amountIn = payingToken.balanceOf(address(this)).sub(balanceBefore);

        // Swap token to usdt and transfer to the merchant wallet
        swapTokenToUsdtAndTransferToMerchantWallet(
            _payingTokenAddress,
            _amountIn
        );

        // Handle fee
        handleFee();

        txNumber = generateTxID(_msgSender());
        txDetails[txNumber].txId = txNumber;
        txDetails[txNumber].userAddress = _msgSender();
        txDetails[txNumber].payingToken = _payingTokenAddress;
        txDetails[txNumber].amount = _amountIn;
        txDetails[txNumber].timeStamp = block.timestamp;

        userTxDetails[_msgSender()].push(txNumber);

        totalTxCount = totalTxCount.add(1);
        userTxCount[_msgSender()] = userTxCount[_msgSender()].add(1);

        emit NewTransaction(
            txNumber,
            _msgSender(),
            _payingTokenAddress,
            _amountIn,
            block.timestamp
        );

        return txNumber;
    }
}

// File: contracts\MerchantFactory.sol

pragma solidity ^0.8.0;

contract MerchantFactory is Ownable{
    address public constant BURN_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
    IBEP20 public WPAY_TOKEN;

    event NewMerchant(address indexed merchant);

    /**
     * @notice Deploy the merchant
     * @param _marketingWallet: marketing wallet of new merchant
     * @param _merchantWallet: merchant wallet of new merchant
     * @param _admin: admin address with ownership
     */
    function deployMerchant(
        address _marketingWallet,
        address _merchantWallet,
        address _admin
    ) external onlyOwner {
        bytes memory bytecode = type(Merchant).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(
                _marketingWallet,
                _merchantWallet,
                _admin,
                block.timestamp
            )
        );
        address merchantContractAddress;

        assembly {
            merchantContractAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        Merchant(merchantContractAddress).initialize(
            address(WPAY_TOKEN),
            _marketingWallet,
            _merchantWallet,
            _admin
        );

        emit NewMerchant(merchantContractAddress);
    }
}