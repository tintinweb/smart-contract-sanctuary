/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-22
*/

// File: contracts/Ownable.sol

pragma solidity >=0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/SafeMath.sol

pragma solidity >=0.6.2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/Address.sol

pragma solidity >=0.6.2;

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
        // (bool success, ) = recipient.call{value: amount}("");
        (bool success, ) = recipient.call.value(amount)("");
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
        // (bool success, bytes memory returndata) =
        //     target.call{value: value}(data);
        (bool success, bytes memory returndata) =
            target.call.value(value)(data);
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

// File: contracts/interfaces/IBEP20.sol

pragma solidity >=0.6.2;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/libs/SafeToken.sol

pragma solidity >=0.6.2;




library SafeToken {
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
            "approve from non-zero to non-zero allowance"
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
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
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
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "decreased allowance below zero"
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

        bytes memory returndata =
            address(token).functionCall(data, "low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "operation did not succeed"
            );
        }
    }
}

// File: contracts/interfaces/ITorCoin.sol

pragma solidity >=0.6.2;


interface ITorCoin is IBEP20 {
    function mint(address recipient_, uint256 amount_) external;

    function getTransferTaxRate() external view returns (uint256);

    function transferOwnership(address newOwner) external;
}

// File: contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: contracts/MasterChef.sol

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;







interface IAnonymousTree {
    function bind(bytes32 _commitment) external returns (bytes32, uint256);

    function unBind(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external;
}

interface IMigratorChef {
    function migrate(IBEP20 token) external returns (IBEP20);
}

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeToken for IBEP20;

    struct Global {
        uint256 totalDeposit;
        uint256 total24hDeposit;
        uint256 lastDepositAt;
    }

    struct PoolInfo {
        IBEP20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTorPerShare;
        uint16 depositFeeBP;
        uint256[] denominations;
        address[] anonymousTrees;
        uint256 freezeTokens;
        address[] paths;
    }

    struct UserInfo {
        DepositInfo[] depositInfos;
    }

    struct User {
        address referrer;
        uint256[3] levels;
        uint256 totalBonus;
    }

    struct DepositInfo {
        uint256 idx;
        uint256 denomination;
        uint256 rewardDebt;
        uint256 bonusForTors;
        uint256 at;
        bool invalid;
        bool excluded;
        IAnonymousTree anonymousTree;
    }

    ITorCoin public TOR;

    address public DEV_ADDRESS;
    address public FEE_ADDRESS;
    uint256 public TOR_PER_DAY;
    uint256 public constant BONUS_MULTIPLIER = 1;

    IMigratorChef public MIGRATOR;
    PoolInfo[] internal POOL_INFOR;

    mapping(uint256 => mapping(address => UserInfo)) internal USER_INFO;
    mapping(address => User) internal USERS;
    mapping(address => bool) internal EXECLUDED_FROM_LP;
    mapping(uint256 => Global) public GLOBALS;

    uint256 public TOTAL_ALLOC_POINT = 0;
    uint256 public STARTED_AT;
    uint256 public constant LIQUIDITY_PERCENT = 100;
    uint256 public constant PERCENTS_DIVIDER = 10000;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public constant BURN_BONUS_DAYS = 7 days;
    IUniswapV2Router02 public SWAP_ROUTER;
    uint256 public TOR_BURN_TOTAL;
    uint256[] public REFERRAL_PERCENTS = [250, 150, 50];
    bool private INITIALIZED;

    event Deposit(
        address indexed sender,
        uint256 depositAmount,
        uint256 denomination,
        uint256 bonusForTors
    );
    event Reward(
        address indexed sender,
        uint256 contractBalance,
        uint256 tors,
        uint256 burnForTors,
        uint256 bonusForTors
    );
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event UpdatePool(uint256 indexed pid, uint256 multiplier, uint256 timeAt);

    modifier initializer() {
        require(INITIALIZED, "!initializer");
        _;
    }

    constructor(
        uint256 _torPerDay,
        address _dev,
        address _fee
    ) public {
        TOR_PER_DAY = _torPerDay;

        DEV_ADDRESS = _dev;
        FEE_ADDRESS = _fee;
    }

    function initialize(uint256 _startedAt) external onlyOwner {
        require(!INITIALIZED, "Contract is already initialized");

        STARTED_AT = _startedAt == 0 ? block.number : _startedAt;

        for (uint256 _pid = 0; _pid < POOL_INFOR.length; _pid++) {
            if (POOL_INFOR[_pid].lastRewardBlock == 0) {
                POOL_INFOR[_pid].lastRewardBlock = _startedAt;
            }
        }

        INITIALIZED = true;
    }

    function poolLength() external view returns (uint256) {
        return POOL_INFOR.length;
    }

    function getPoolInfo(uint256 _pid)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint16,
            uint256[] memory,
            address[] memory,
            uint256 freezeTokens,
            address[] memory
        )
    {
        PoolInfo memory _pool = POOL_INFOR[_pid];

        return (
            address(_pool.lpToken),
            _pool.allocPoint,
            _pool.lastRewardBlock,
            _pool.accTorPerShare,
            _pool.depositFeeBP,
            _pool.denominations,
            _pool.anonymousTrees,
            _pool.freezeTokens,
            _pool.paths
        );
    }

    function addPool(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _depositFeeBP,
        uint256[] memory _denominations,
        bool _withUpdate,
        address[] memory _anonymousTrees,
        address[] memory _paths,
        uint256 _lastRewardBlock
    ) public onlyOwner {
        require(
            _depositFeeBP <= PERCENTS_DIVIDER,
            "add: invalid deposit fee basis points"
        );

        if (_withUpdate) {
            massUpdatePools();
        }

        // uint256 _lastRewardBlock =
        //     block.number > STARTED_AT ? block.number : STARTED_AT;

        TOTAL_ALLOC_POINT = TOTAL_ALLOC_POINT.add(_allocPoint);

        POOL_INFOR.push(
            PoolInfo({
                lpToken: ITorCoin(_lpToken),
                allocPoint: _allocPoint,
                lastRewardBlock: _lastRewardBlock > 0 ? _lastRewardBlock : 0,
                accTorPerShare: 0,
                depositFeeBP: _depositFeeBP,
                denominations: _denominations,
                anonymousTrees: _anonymousTrees,
                paths: _paths,
                freezeTokens: 0
            })
        );
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate,
        uint256[] memory _denominations,
        address[] memory _anonymousTrees,
        address[] memory _paths
    ) public onlyOwner {
        require(
            _depositFeeBP <= PERCENTS_DIVIDER,
            "set: invalid deposit fee basis points"
        );

        if (_withUpdate) {
            massUpdatePools();
        }

        TOTAL_ALLOC_POINT = TOTAL_ALLOC_POINT
            .sub(POOL_INFOR[_pid].allocPoint)
            .add(_allocPoint);

        POOL_INFOR[_pid].allocPoint = _allocPoint;
        POOL_INFOR[_pid].depositFeeBP = _depositFeeBP;

        if (_denominations.length > 0) {
            POOL_INFOR[_pid].denominations = _denominations;
        }

        if (_anonymousTrees.length > 0) {
            POOL_INFOR[_pid].anonymousTrees = _anonymousTrees;
        }

        if (_paths.length > 0) {
            POOL_INFOR[_pid].paths = _paths;
        }
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(MIGRATOR) != address(0), "!MIGRATOR");
        PoolInfo storage _pool = POOL_INFOR[_pid];

        IBEP20 lpToken = _pool.lpToken;

        uint256 _lpSupply = lpToken.balanceOf(address(this));

        lpToken.safeApprove(address(MIGRATOR), _lpSupply);

        IBEP20 _newLpToken = MIGRATOR.migrate(lpToken);

        require(
            _lpSupply == _newLpToken.balanceOf(address(this)),
            "migrate: bad"
        );

        _pool.lpToken = _newLpToken;
    }

    function massUpdatePools() public {
        for (uint256 _pid = 0; _pid < POOL_INFOR.length; _pid++) {
            updatePool(_pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage _pool = POOL_INFOR[_pid];

        if (block.number <= _pool.lastRewardBlock) {
            return;
        }

        Global storage _g = GLOBALS[_pid];

        uint256 _lpSupply = _g.totalDeposit.sub(_pool.freezeTokens);

        if (_lpSupply == 0 || _pool.allocPoint == 0) {
            _pool.lastRewardBlock = block.number;
            return;
        }

        uint256 _multiplier =
            getMultiplier(_pool.lastRewardBlock, block.number);
        uint256 _torReward =
            _multiplier.mul(TOR_PER_DAY).mul(_pool.allocPoint).div(
                TOTAL_ALLOC_POINT
            );

        if (_torReward == 0) {
            return;
        }

        TOR.mint(DEV_ADDRESS, _torReward.div(10));
        TOR.mint(address(this), _torReward);

        _pool.accTorPerShare = _pool.accTorPerShare.add(
            _torReward.mul(1e12).div(_lpSupply)
        );

        _pool.lastRewardBlock = block.number;

        emit UpdatePool(_pid, _multiplier, block.timestamp);
    }

    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function findDenomination(PoolInfo storage _pool, uint256 _amount)
        internal
        view
        returns (bool, uint256)
    {
        bool _found;
        uint256 _idx;

        for (uint256 i = 0; i < _pool.denominations.length; i++) {
            if (_pool.denominations[i] == _amount) {
                _found = true;
                _idx = i;
                break;
            }
        }

        return (_found, _idx);
    }

    function swapForTors(PoolInfo memory _pool, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        _pool.lpToken.safeTransferFrom(
            address(_msgSender()),
            address(this),
            _amount
        );

        if (isExcludedFromLP(address(_pool.lpToken)) || isDevMode()) {
            return (_amount, 0);
        }

        uint256 _swapAmount =
            _amount.mul(LIQUIDITY_PERCENT).div(PERCENTS_DIVIDER);

        _pool.lpToken.approve(address(SWAP_ROUTER), _swapAmount);

        // amounts[1] == _bonusForTors
        uint256[] memory _amounts =
            SWAP_ROUTER.swapExactTokensForTokens(
                _swapAmount,
                0,
                _pool.paths,
                address(this),
                block.timestamp
            );

        return (_amount.sub(_swapAmount), _amounts[_pool.paths.length - 1]);
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) external initializer {
        PoolInfo storage _pool = POOL_INFOR[_pid];
        UserInfo storage _userInfo = USER_INFO[_pid][_msgSender()];
        DepositInfo memory _depositInfo;

        if (isExcludedFromLP(address(_pool.lpToken))) {
            _depositInfo.excluded = true;
        } else {
            (bool _found, uint256 _idx) = findDenomination(_pool, _amount);

            require(_found, "!findDenomination");

            _depositInfo.idx = _idx;
            _depositInfo.anonymousTree = IAnonymousTree(
                _pool.anonymousTrees[_idx]
            );
        }

        (uint256 _denomination, uint256 _bonusForTors) =
            swapForTors(_pool, _amount);

        if (address(_pool.lpToken) == address(TOR)) {
            uint256 _transferTax =
                _denomination.mul(TOR.getTransferTaxRate()).div(
                    PERCENTS_DIVIDER
                );
            _denomination = _denomination.sub(_transferTax);
        }

        User storage user = USERS[_msgSender()];

        if (user.referrer == address(0)) {
            if (_referrer != _msgSender()) {
                user.referrer = _referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    USERS[upline].levels[i] = USERS[upline].levels[i].add(1);
                    upline = USERS[upline].referrer;
                } else break;
            }
        }

        if (_pool.depositFeeBP > 0) {
            uint256 _depositFee =
                _denomination.mul(_pool.depositFeeBP).div(PERCENTS_DIVIDER);
            _pool.lpToken.safeTransfer(FEE_ADDRESS, _depositFee);
            _depositInfo.denomination = _denomination.sub(_depositFee);
        } else {
            _depositInfo.denomination = _denomination;
        }

        Global storage _g = GLOBALS[_pid];

        if (
            block.timestamp.sub(_g.lastDepositAt) <= 24 hours ||
            _g.lastDepositAt == 0
        ) {
            _g.total24hDeposit = _g.total24hDeposit.add(
                _depositInfo.denomination
            );
        } else {
            _g.total24hDeposit = 0;
        }

        _g.totalDeposit = _g.totalDeposit.add(_depositInfo.denomination);
        _g.lastDepositAt = block.timestamp;

        updatePool(_pid);

        _depositInfo.rewardDebt = _depositInfo
            .denomination
            .mul(_pool.accTorPerShare)
            .div(1e12);
        _depositInfo.at = block.timestamp;
        _depositInfo.bonusForTors = _bonusForTors;

        _userInfo.depositInfos.push(_depositInfo);

        emit Deposit(
            _msgSender(),
            _amount,
            _depositInfo.denomination,
            _bonusForTors
        );
    }

    function bindNote(
        bytes32 _commitment,
        uint256 _pid,
        uint256 _depositId
    ) external initializer {
        PoolInfo storage _pool = POOL_INFOR[_pid];
        User storage user = USERS[_msgSender()];
        DepositInfo storage _depositInfo =
            USER_INFO[_pid][_msgSender()].depositInfos[_depositId];

        require(_depositInfo.at > 0, "!at");
        require(_depositInfo.invalid == false, "!invalid");

        updatePool(_pid);

        (
            uint256 _tors,
            uint256 _burnForTors,
            uint256 _bonusForTors,
            uint256 _rewardDebt
        ) = getReward(_pid, _depositId, _msgSender());

        if (user.referrer != address(0)) {
            address _upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (_upline != address(0)) {
                    uint256 _torBonus =
                        _tors.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    safeTorTransfer(_upline, _torBonus);
                    USERS[_upline].totalBonus = USERS[_upline].totalBonus.add(
                        _torBonus
                    );
                    _upline = USERS[_upline].referrer;
                    _tors = _tors.sub(_torBonus);

                    emit RefBonus(_upline, _msgSender(), i, _torBonus);
                } else break;
            }
        }

        if (_bonusForTors > 0) {
            safeTorTransfer(_msgSender(), _bonusForTors);
        } else {
            TOR_BURN_TOTAL = TOR_BURN_TOTAL.add(_burnForTors);

            safeTorTransfer(BURN_ADDRESS, _burnForTors);
        }

        safeTorTransfer(_msgSender(), _tors);

        if (isExcludedFromLP(address(_pool.lpToken)) && _depositInfo.excluded) {
            _pool.lpToken.safeTransfer(_msgSender(), _depositInfo.denomination);

            Global storage _g = GLOBALS[_pid];
            _g.totalDeposit = _g.totalDeposit.sub(_depositInfo.denomination);
        } else {
            _depositInfo.anonymousTree.bind(_commitment);

            _pool.freezeTokens = _pool.freezeTokens.add(
                _depositInfo.denomination
            );
        }

        _depositInfo.invalid = true;
        _depositInfo.rewardDebt = _rewardDebt;

        emit Reward(
            _msgSender(),
            TOR.balanceOf(address(this)),
            _tors,
            _burnForTors,
            _bonusForTors
        );
    }

    function withdraw(
        uint256 _pid,
        uint256 _idx,
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external initializer {
        PoolInfo storage _pool = POOL_INFOR[_pid];

        require(_idx < _pool.anonymousTrees.length, "!_idx");

        IAnonymousTree(_pool.anonymousTrees[_idx]).unBind(
            _proof,
            _root,
            _nullifierHash,
            _recipient,
            _relayer,
            _fee,
            _refund
        );

        uint256 _denomination = _pool.denominations[_idx];

        if (!isExcludedFromLP(address(_pool.lpToken))) {
            _denomination = _denomination.sub(
                _denomination.mul(LIQUIDITY_PERCENT).div(PERCENTS_DIVIDER)
            );
        }

        Global storage _g = GLOBALS[_pid];
        _g.totalDeposit = _g.totalDeposit.sub(_denomination);

        _pool.lpToken.safeTransfer(_recipient, _denomination - _fee);

        _pool.freezeTokens = _pool.freezeTokens.sub(_denomination);

        if (_fee > 0) {
            _pool.lpToken.safeTransfer(_relayer, _fee);
        }

        if (_refund > 0) {
            (bool success, ) = _recipient.call.value(_refund)("");
            if (!success) {
                _relayer.transfer(_refund);
            }
        }
    }

    function getDeposits(uint256 _pid, address _sender)
        public
        view
        returns (UserInfo memory)
    {
        UserInfo memory _userInfo = USER_INFO[_pid][_sender];

        return _userInfo;
    }

    function getReward(
        uint256 _pid,
        uint256 _depositId,
        address _sender
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        PoolInfo memory _pool = POOL_INFOR[_pid];
        DepositInfo memory _depositInfo =
            USER_INFO[_pid][_sender].depositInfos[_depositId];

        require(_depositInfo.at > 0, "!at");

        if (_depositInfo.invalid == true) {
            return (0, 0, 0, 0);
        }

        Global memory _g = GLOBALS[_pid];

        uint256 _lpSupply = _g.totalDeposit.sub(_pool.freezeTokens);
        uint256 _accTorPerShare = _pool.accTorPerShare;

        if (block.number > _pool.lastRewardBlock && _lpSupply > 0) {
            uint256 _multiplier =
                getMultiplier(_pool.lastRewardBlock, block.number);
            uint256 _torReward =
                _multiplier.mul(TOR_PER_DAY).mul(_pool.allocPoint).div(
                    TOTAL_ALLOC_POINT
                );

            _accTorPerShare = _accTorPerShare.add(
                _torReward.mul(1e12).div(_lpSupply)
            );
        }

        uint256 _rewardDebt =
            _depositInfo.denomination.mul(_accTorPerShare).div(1e12);

        uint256 _tors = _rewardDebt.sub(_depositInfo.rewardDebt);

        if (
            !_depositInfo.excluded &&
            _depositInfo.at.add(BURN_BONUS_DAYS) <= block.timestamp
        ) {
            return (
                _tors,
                _depositInfo.bonusForTors,
                _depositInfo.bonusForTors,
                _rewardDebt
            );
        }

        return (_tors, _depositInfo.bonusForTors, 0, _rewardDebt);
    }

    function safeTorTransfer(address _to, uint256 _amount) internal {
        uint256 masterChefBalance = TOR.balanceOf(address(this));

        if (_amount > masterChefBalance) {
            TOR.transfer(_to, masterChefBalance);
        } else {
            TOR.transfer(_to, _amount);
        }
    }

    function updateSwapRouter(address _router) public onlyOwner {
        SWAP_ROUTER = IUniswapV2Router02(_router);
    }

    function updateTor(address _tor) public onlyOwner {
        TOR = ITorCoin(_tor);
    }

    function updateTorTransferOwnership(address _v) public onlyOwner {
        TOR.transferOwnership(_v);
    }

    function setExcludedFromLP(address _v, bool _excluded) public onlyOwner {
        EXECLUDED_FROM_LP[_v] = _excluded;
    }

    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        MIGRATOR = _migrator;
    }

    function isExcludedFromLP(address _v) public view returns (bool) {
        return EXECLUDED_FROM_LP[_v];
    }

    function getUserReferrer(address _v) public view returns (address) {
        return USERS[_v].referrer;
    }

    function getUserDownlineCount(address _v)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (USERS[_v].levels[0], USERS[_v].levels[1], USERS[_v].levels[2]);
    }

    function getUserReferralTotalBonus(address _v)
        public
        view
        returns (uint256)
    {
        return USERS[_v].totalBonus;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        return chainId;
    }

    function isDevMode() public pure returns (bool) {
        return getChainId() == 97 ? true : false;
    }
}