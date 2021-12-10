/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity  0.8.0;


interface IERC20 {
    
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
pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
pragma solidity 0.8.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




interface IPancakeRouter01 {
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


interface IPancakeRouter02 is IPancakeRouter01 {
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
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
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
     * _Available since v3.3._
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
     * _Available since v3.3._
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface TransferReward {
    function update() external;
}

interface TenFarm {
    
    function poolInfo(uint256 _pid) external view returns (address,uint256,uint256,uint256,address);
    
    function userInfo(uint256 _pid, address _user) external view returns (uint256,uint256);
    //Deposit LP tokens
    function deposit(uint256 _pid, uint256 _wantAmount
    ) external;
    
    function withdraw(uint256 _pid ,uint256 _amountIn) external;
    
    function stakedWantTokens(uint256 _pid, address _user) external view returns(uint256);
    
    function pendingTENFI(uint256 _pid, address _user) external view returns (uint256);
}

interface alpaca {
    function deposit(uint256 amountToken) external payable;
    function withdraw(uint256 share) external;
}

interface TENFI_STRAT {
    function wantLockedTotal() external view returns (uint256);
    function sharesTotal() external view returns (uint256);
}

interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

contract Yieldex is Ownable,ReentrancyGuard{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    /*
      Max_LP is the maximum number of LP tokens which can exist in the pool;
    */
    uint8 public MAX_LP = 6;
    struct PoolInfo {
        IERC20[] Lpaddress;
        uint256[] weights;
        uint256[] pids;
        bool status;
        uint256 length;
    }
    
    address public TenLots;
    uint256 public depositFeeFactor = 9990;
    uint256 public constant depositFeeFactorMax = 10000;
    uint256 public constant depositFeeFactorLL = 9500;
    uint256 public maxPools = 11;
    
    // Max allowance
    uint256 allow = 1e28;
    
    // Array consisting info of each pool
    PoolInfo[] public poolInfo;
    
    // Path to convert the BNB to BUSD
    address[] public feesSwapPath;
    
    //PanCakeSwapRouter
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public farmAddress = 0x264A1b3F6db28De4D3dD4eD23Ab31A468B0C1A96;
    address public wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public tenToken =  0xd15C444F1199Ae72795eba15E8C1db44E47abF62;
    address public busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public feeAddress = 0x6e6B21d8A5Fe2Be12fc9EBe79B21fDeE44faEb02;
    address public devWalletAddress = 0x393c7C3EbCBFf2c1138D123df5827e215458F0c4;
    address public ibBNB = 0xd7D069493685A581d27824Fc46EdA46B7EfC0063;
    uint256 rewardShare ;
    uint256 subValue;
    address[] public alpacaPools;
    
    // Address for token swap
    struct swapPath{
        address[] token0path;
        // address[] token1path;
    }
    
    struct swapPathToken{
        address[] token0path;
        // address[] token1path;
    }
    
    /* reverse Path are to convert LP single token to desired output
    * eg. TENFI-BUSD --> swapPaths are used to convert input token to token0 and token1path
    * eg. reversePath --> reversePath is used to convert TENFI and BUSD into BNB
    */
    
    struct reverseSwapPath {
        address[] token0path;
        // address[] token1path;
    }
    
    struct reverseSwapPathToken {
        address[] token0path;
        // address[] token1path;
    }
       
    // This struct is used to store detials of LP-pools in each Index
    struct vaultDetail{
        uint256 totalShare;
        uint256 totalReward;
        uint256 accTenPerShare;
    }
    
    // UserInfo -> stores shares and rewardDebt
    
    struct UserInfo{
            uint256 shares;
            uint256 rewardDebt;
        }
        
    struct indexValue {
        IERC20 Lpaddress;
        uint256 weight;
    }
    
    mapping(IERC20 => uint256) addressWeight;

    mapping(uint256 => mapping(IERC20 => vaultDetail)) indexLpTotalShares;
    
    mapping(uint256 => mapping(IERC20 => mapping(address =>UserInfo))) public userIndexInfo;
    
    // Mappings for respective swap
    mapping(IERC20 => swapPath) swapPaths;
    
    mapping(IERC20 => swapPath) swapPathsToken;
    
    mapping(IERC20 => reverseSwapPath) reverseSwapPaths;
    
    mapping(IERC20 => reverseSwapPath) reverseSwapPathsToken;
    
    mapping(IERC20 => bool) isPresent;
    
    modifier validPool(uint256 _pid) {
        require(_pid < poolInfo.length, "deposit:pool exists?");
        _;
    }
    
    function TokenpPathWBNB(IERC20 _lpAddress,uint256 _tokenIndex, uint256 _path) public view returns(address){
        if(_tokenIndex == 0){
            return swapPaths[_lpAddress].token0path[_path];
        }
    }
    
    function addPaths(IERC20  _lpAddress, address[] memory _token0path) public onlyOwner {
        uint i;
        
        for(i = _token0path.length-1; i > 0; i--) {
            reverseSwapPaths[_lpAddress].token0path.push(_token0path[i]);
        }
        
        reverseSwapPaths[_lpAddress].token0path.push(_token0path[i]);
        
        swapPaths[_lpAddress].token0path = _token0path;
    }
    
    
    
    function setFees(uint256 fees) external onlyOwner {
        require(fees > depositFeeFactorLL, 'Fees too low');
        require(fees < depositFeeFactorMax, 'Fees too high');
        depositFeeFactor = fees;
    }
    
    function setCollector(address _collector) external onlyOwner {
        require(_collector != (address(0)), 'wrong address');
        feeAddress = _collector;
    }
    
    function setFeesSwapPath(address[] memory path) external onlyOwner {
        feesSwapPath = path;
    }
    
    function editMaxPools(uint256 len) onlyOwner external {
        maxPools = len;
    }
    
    

    function createPool(
        IERC20 [] memory _Lpaddress,
        uint256[] memory _weights,
        uint256[] memory _pids
        )
    external
    onlyOwner
    returns(bool)
    {
        require(_Lpaddress.length < maxPools,"Error: LPaddres array should be < maxPools");
        require(_Lpaddress.length == _weights.length && _Lpaddress.length == _pids.length, "createPool: Error in Pool lengths");
        uint256 sumWeight = 0;
        for(uint8 i = 0; i < _Lpaddress.length ; i++){
        require(_weights[i] > 0 , "Error : Incorrect Pool Weight");
         sumWeight = sumWeight.add(_weights[i]);
         isPresent[_Lpaddress[i]] = true;
        }
        require(sumWeight == 50 ,"Error: Total weight Not Equal to 50");
        
        poolInfo.push(
            PoolInfo({
              Lpaddress:_Lpaddress,
              weights:_weights,
              pids:_pids,
              status:false,
              length: _Lpaddress.length
            })
            );
        return true;
    }
    
    function addAlpacaPools(address[] memory _alpacaPools) public onlyOwner {
        alpacaPools = _alpacaPools; 
    }

    function viewAddress(uint256 pool, uint256 index) external view returns(IERC20){
       return poolInfo[pool].Lpaddress[index];
    }
    
    function viewWeight(uint256 pool, uint256 index) external view returns(uint256){
       return poolInfo[pool].weights[index];
    }
    
    function _wrapBNB( uint256 amount) internal {
        if (amount > 0) {
            IWBNB(wbnbAddress).deposit{value: amount}();
        }
    }
        function deposit(uint256 poolId, address depositTokenAddress,uint256 _slippageFactor) nonReentrant validPool(poolId) public payable  {
        uint256 tenSwaped = 0;
        uint256 amount = msg.value;
        if(depositTokenAddress == address(0)) {
            _wrapBNB(msg.value);
            depositTokenAddress = wbnbAddress;
            uint256 fees = amount.sub(amount.mul(depositFeeFactor).div(10000));
            
             uint256 feesBusd = _safeSwap(
                routerAddress,
                fees,
                _slippageFactor,
                feesSwapPath,
                address(this),
                block.timestamp.add(600)
            );
            
            // transfer fees to the tenlots
            
        IERC20(busdAddress).safeTransfer(feeAddress,feesBusd.mul(800).div(1000));
        TransferReward(feeAddress).update();
        
            // ends here
            
        IERC20(busdAddress).safeTransfer(devWalletAddress,feesBusd.mul(200).div(1000));
        amount = amount.sub(fees);
            
            for(uint i = 0; i < poolInfo[poolId].Lpaddress.length ; i++){
                
            if(address(poolInfo[poolId].Lpaddress[i]) != tenToken) {
                
                IERC20 iAddress = poolInfo[poolId].Lpaddress[i];
                
                uint256 iweight = poolInfo[poolId].weights[i];
                
                uint256 amountin = amount.mul(iweight).div(50);
                
                uint256 token0Amt = amountin;
                
                if( swapPaths[iAddress].token0path[swapPaths[iAddress].token0path.length.sub(1)] != depositTokenAddress && depositTokenAddress == swapPaths[iAddress].token0path[0]) {
                // Swap token0 ;
                token0Amt = _safeSwap(
                    routerAddress,
                    amountin,
                    _slippageFactor,
                    swapPaths[iAddress].token0path,
                    address(this),
                    block.timestamp.add(600)
                    );   
                }
                if (token0Amt > 0)  {
                    
                    IERC20(swapPaths[iAddress].token0path[swapPaths[iAddress].token0path.length.sub(1)]).safeApprove(alpacaPools[i],0);
                    IERC20(swapPaths[iAddress].token0path[swapPaths[iAddress].token0path.length.sub(1)]).safeIncreaseAllowance(
                        alpacaPools[i],
                        token0Amt
                    );
                }
                
                alpaca(alpacaPools[i]).deposit(
                    token0Amt
                    );
                }
                else {
                    
                    IERC20 iAddress = poolInfo[poolId].Lpaddress[i];
                    
                    uint256 iweight = poolInfo[poolId].weights[i];
                    
                    uint256 amountin = amount.mul(iweight).div(50);
                    
                    tenSwaped = amountin;
                    
                    if(swapPaths[iAddress].token0path[swapPaths[iAddress].token0path.length.sub(1)] != depositTokenAddress && depositTokenAddress == swapPaths[iAddress].token0path[0]) {
                        // swap token1
                        tenSwaped = _safeSwap(
                            routerAddress,
                            amountin,
                            _slippageFactor,
                            swapPaths[iAddress].token0path,
                            address(this),
                            block.timestamp.add(600)
                        );   
                    }
                }
        
            }
            
        }
        supplyFarm(poolId,tenSwaped);
        emit _deposit(msg.sender, depositTokenAddress, amount);
    }
    
    
    function supplyFarm(uint256 yieldPoolId ,uint256 _tenSwaped) internal {
        for(uint i = 0; i < poolInfo[yieldPoolId].length; ++i) {
            if (address(poolInfo[yieldPoolId].Lpaddress[i]) == tenToken) {
                // Fetch the LP Address of the pool
                IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
                
                // Fetch the LP balance the pool
                uint256 balance =  _tenSwaped;
                
                // Decrease the allowance
                IERC20(iAddress).safeApprove(farmAddress,0);
                
                // Increase the allowance
                IERC20(iAddress).safeIncreaseAllowance(farmAddress, balance);
                
                // Ten Earned
                uint256 tenEarned = TenFarm(farmAddress).pendingTENFI(poolInfo[yieldPoolId].pids[i],address(this));
                
                // deposit the balance in the farm
                TenFarm(farmAddress).deposit(poolInfo[yieldPoolId].pids[i],balance);
                
                // uint256 tenEarned = IERC20(tenToken).balanceOf(address(this)).sub(tenbalance);
                rewardShare = 0 ;
                subValue = 0;
                // accTennPerShare is calculated here 
                if(indexLpTotalShares[yieldPoolId][iAddress].totalShare > 0){
                indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.add(tenEarned.mul(1e12).div(indexLpTotalShares[yieldPoolId][iAddress].totalShare));
                rewardShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares);
                }
                indexLpTotalShares[yieldPoolId][iAddress].totalReward = indexLpTotalShares[yieldPoolId][iAddress].totalReward.add(tenEarned);
                {
                        subValue = userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt;
                }
                if(rewardShare.div(1e12) > userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt) {
                        IERC20(tenToken).safeTransfer(msg.sender,(rewardShare.div(1e12).sub(subValue)));
                    }
                
                indexLpTotalShares[yieldPoolId][iAddress].totalShare = indexLpTotalShares[yieldPoolId][iAddress].totalShare.add(balance);
                userIndexInfo[yieldPoolId][iAddress][msg.sender].shares = userIndexInfo[yieldPoolId][iAddress][msg.sender].shares.add(balance);
                userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares).div(1e12);
                
            } 
            
            else {
                
                // Fetch the LP Address of the pool
                IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
                
                // Fetch the LP balance the pool
                uint256 balance =  IERC20(iAddress).balanceOf(address(this));
                
                // Decrease the allowance
                IERC20(iAddress).safeApprove(farmAddress,0);
                
                // Increase the allowance
                IERC20(iAddress).safeIncreaseAllowance(farmAddress, balance);
                
                // Check the balance of the ten Token 
                uint256 tenbalance = IERC20(tenToken).balanceOf(address(this));
                
                // deposit the balance in the farm
                TenFarm(farmAddress).deposit(poolInfo[yieldPoolId].pids[i],balance);
                
                // Ten Earned
                uint256 tenEarned = IERC20(tenToken).balanceOf(address(this)).sub(tenbalance);
                rewardShare = 0 ;
                subValue = 0;
                // accTennPerShare is calculated here 
                if(indexLpTotalShares[yieldPoolId][iAddress].totalShare > 0){
                indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.add(tenEarned.mul(1e12).div(indexLpTotalShares[yieldPoolId][iAddress].totalShare));
                rewardShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares);
                }
                indexLpTotalShares[yieldPoolId][iAddress].totalReward = indexLpTotalShares[yieldPoolId][iAddress].totalReward.add(tenEarned);
                {
                        subValue = userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt;
                }
                if(rewardShare.div(1e12) > userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt) {
                        IERC20(tenToken).safeTransfer(msg.sender,(rewardShare.div(1e12).sub(subValue)));
                    }
                
                indexLpTotalShares[yieldPoolId][iAddress].totalShare = indexLpTotalShares[yieldPoolId][iAddress].totalShare.add(balance);
                userIndexInfo[yieldPoolId][iAddress][msg.sender].shares = userIndexInfo[yieldPoolId][iAddress][msg.sender].shares.add(balance);
                userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares).div(1e12);
                
            }
        }
            
    }
    
    

    
    
    
    function returnReward(uint i, address user,uint256 yieldPoolId) view public returns(uint256){
        IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
        uint256 _rewardShare  =0;
        uint256 tenEarned = TenFarm(farmAddress).pendingTENFI(poolInfo[yieldPoolId].pids[i],address(this));
        uint256 accPerShare;
        if(tenEarned > 0) {
           accPerShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.add(tenEarned.mul(1e12).div(indexLpTotalShares[yieldPoolId][iAddress].totalShare));
        }
        if(accPerShare.mul(userIndexInfo[yieldPoolId][iAddress][user].shares) > userIndexInfo[yieldPoolId][iAddress][user].rewardDebt){
        _rewardShare = accPerShare.mul(userIndexInfo[yieldPoolId][iAddress][user].shares).div(1e12).sub(userIndexInfo[yieldPoolId][iAddress][user].rewardDebt);
            
        }
        return _rewardShare;
    }
     
    function userShare(uint i, address user,uint256 yieldPoolId) view public returns(uint256 , uint256 , uint256 ){
        IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
        uint256 _shares = userIndexInfo[yieldPoolId][iAddress][user].shares;
        uint256 _totalShares = indexLpTotalShares[yieldPoolId][iAddress].totalShare;
        uint256 _rewardDebt = userIndexInfo[yieldPoolId][iAddress][user].rewardDebt;
        return (_shares,_totalShares,_rewardDebt);
        
    }
    
    function returnLpAddress(uint i, uint256 yieldPoolId) view public returns (IERC20){
        IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
        return iAddress;
    }
    

   function withdrawBalance(address userAddress, uint256 yieldPoolId, IERC20 lpAddress, uint256 percent )internal view returns(uint256){
       require(percent <= 1000,"withdraw: percent <=1000");
       uint256 share = userIndexInfo[yieldPoolId][lpAddress][userAddress].shares.mul(1e12).mul(percent).div(1000);
       return share.div(1e12);
   }
   
    function Calc_Withdraw_Amount(uint256 pid, uint256 withdrawBalance, IERC20 iAddress,uint256 yieldPoolId) internal returns(uint256) {
        (,,,,address strat) = TenFarm(farmAddress).poolInfo(pid);
        (uint256 shares,) = TenFarm(farmAddress).userInfo(pid,address(this));
        uint256 wantLockedTotal = TENFI_STRAT(strat).wantLockedTotal();
        uint256 sharesTotal = TENFI_STRAT(strat).sharesTotal();
        uint256 returnedLPs = (shares.mul(wantLockedTotal)).div(sharesTotal);
        if(withdrawBalance > returnedLPs * withdrawBalance / indexLpTotalShares[yieldPoolId][iAddress].totalShare) {
            return returnedLPs * withdrawBalance / indexLpTotalShares[yieldPoolId][iAddress].totalShare;
        } else {
            withdrawBalance;
        }
    }
   
    function withdraw(uint256 yieldPoolId, uint percent, address tokenAddress, uint256 slippage) public validPool(yieldPoolId) nonReentrant {
        
        for(uint i = 0; i < poolInfo[yieldPoolId].length; i++) {
            if(address(poolInfo[yieldPoolId].Lpaddress[i]) == tenToken) {
                rewardShare = 0;
                subValue = 0;
                IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
                uint256 _withdrawBalance = withdrawBalance(msg.sender, yieldPoolId, iAddress, percent);
                if (_withdrawBalance > indexLpTotalShares[yieldPoolId][iAddress].totalShare) {
                  _withdrawBalance = indexLpTotalShares[yieldPoolId][iAddress].totalShare;
                }
                
                uint256 tenbalance = IERC20(tenToken).balanceOf(address(this));
                _withdrawBalance = Calc_Withdraw_Amount(poolInfo[yieldPoolId].pids[i],_withdrawBalance, iAddress, yieldPoolId);
                TenFarm(farmAddress).withdraw(poolInfo[yieldPoolId].pids[i],_withdrawBalance);
                // accTennPerShare is calculated here
                uint256 tenEarned = (IERC20(tenToken).balanceOf(address(this))).sub(tenbalance).sub(_withdrawBalance);
    
                // accTennPerShare is calculated here
                if(indexLpTotalShares[yieldPoolId][iAddress].totalShare > 0) {
                    indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.add(tenEarned.mul(1e12).div(indexLpTotalShares[yieldPoolId][iAddress].totalShare));
                    rewardShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares);
                }
                 
                indexLpTotalShares[yieldPoolId][iAddress].totalReward = indexLpTotalShares[yieldPoolId][iAddress].totalReward.add(tenEarned);
                {
                    subValue = userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt;
                }
               
                if(rewardShare.div(1e12) > userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt) {
                    IERC20(tenToken).safeTransfer(msg.sender,(rewardShare.div(1e12).sub(subValue)));
                }
                
                if (percent != 0) {
                        if(tokenAddress == address(0)) {
                            IERC20(iAddress).safeTransfer(msg.sender,_withdrawBalance);
                        }
                        else {
                            lpToToken(iAddress, tokenAddress, slippage, _withdrawBalance);
                        }
                    }
                indexLpTotalShares[yieldPoolId][iAddress].totalShare = indexLpTotalShares[yieldPoolId][iAddress].totalShare.sub(_withdrawBalance);
                
                if(percent == 1000) {
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt = 0;
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].shares = 0;
                }
                
                else {
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].shares = userIndexInfo[yieldPoolId][iAddress][msg.sender].shares.sub(_withdrawBalance);
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares).div(1e12);
                }
            } else {
                rewardShare = 0;
                subValue = 0;
                IERC20 iAddress = poolInfo[yieldPoolId].Lpaddress[i];
                uint256 _withdrawBalance = withdrawBalance(msg.sender, yieldPoolId, iAddress, percent);
                if (_withdrawBalance > indexLpTotalShares[yieldPoolId][iAddress].totalShare) {
                  _withdrawBalance = indexLpTotalShares[yieldPoolId][iAddress].totalShare;
                }
                
                uint256 tenbalance = IERC20(tenToken).balanceOf(address(this));
                _withdrawBalance = Calc_Withdraw_Amount(poolInfo[yieldPoolId].pids[i],_withdrawBalance, iAddress, yieldPoolId);
                TenFarm(farmAddress).withdraw(poolInfo[yieldPoolId].pids[i],_withdrawBalance);
                // accTennPerShare is calculated here 
                uint256 tenEarned = (IERC20(tenToken).balanceOf(address(this))).sub(tenbalance);
    
                // accTennPerShare is calculated here
                if(indexLpTotalShares[yieldPoolId][iAddress].totalShare > 0) {
                    indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.add(tenEarned.mul(1e12).div(indexLpTotalShares[yieldPoolId][iAddress].totalShare));
                    rewardShare = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares);
                }
                 
                indexLpTotalShares[yieldPoolId][iAddress].totalReward = indexLpTotalShares[yieldPoolId][iAddress].totalReward.add(tenEarned);
                {
                    subValue = userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt;
                }
               
                if(rewardShare.div(1e12) > userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt) {
                    IERC20(tenToken).safeTransfer(msg.sender,(rewardShare.div(1e12).sub(subValue)));
                }
                
                if (percent != 0) {
                        if(tokenAddress == address(0)) {
                            IERC20(iAddress).safeTransfer(msg.sender,IERC20(iAddress).balanceOf(address(this)));
                        }
                        else {
                            lpToToken(iAddress, tokenAddress, slippage, 0);
                        }
                    }
                indexLpTotalShares[yieldPoolId][iAddress].totalShare = indexLpTotalShares[yieldPoolId][iAddress].totalShare.sub(_withdrawBalance);
                
                if(percent == 1000){
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt = 0;
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].shares = 0;
                }
                
                else{
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].shares = userIndexInfo[yieldPoolId][iAddress][msg.sender].shares.sub(_withdrawBalance);
                    userIndexInfo[yieldPoolId][iAddress][msg.sender].rewardDebt = indexLpTotalShares[yieldPoolId][iAddress].accTenPerShare.mul(userIndexInfo[yieldPoolId][iAddress][msg.sender].shares).div(1e12);
                }
            }
        }
        emit _withdraw(msg.sender, tokenAddress, percent);
    }
    
    function _approveTokenIfNeeded(address token, address _routerAddress) private {
            IERC20(token).safeApprove(_routerAddress, 0);
            IERC20(token).safeIncreaseAllowance(_routerAddress,allow);
    }
    
    
 
    function lpToToken(IERC20 iAddress, address tokenAddress, uint256 slippage, uint256 tenTokenValue ) internal alloweWithdrawTokens(tokenAddress)  {
        if(tokenAddress == wbnbAddress) {
            if(address(iAddress) == tenToken) {
                _approveTokenIfNeeded(address(iAddress),routerAddress);
                if(reverseSwapPaths[iAddress].token0path[0] != tokenAddress && reverseSwapPaths[iAddress].token0path[reverseSwapPaths[iAddress].token0path.length.sub(1)] == tokenAddress) {
                    uint256 _returned1 = _safeSwap(
                        routerAddress,
                        tenTokenValue,
                        slippage,
                        reverseSwapPaths[iAddress].token0path,
                        address(this),
                        block.timestamp.add(600)
                    );
                    _unwrapBNB(_returned1);
                    Address.sendValue(payable(msg.sender),_returned1);
                }
            } 
            
            else {
                    if(address(iAddress) == ibBNB) {
                        _approveTokenIfNeeded(address(iAddress),address(iAddress));
                        uint256 _tokenBalance = address(this).balance;
                        alpaca(address(iAddress)).withdraw(
                            IERC20(iAddress).balanceOf(address(this))
                        );
                        uint256 tokenBalance = address(this).balance - _tokenBalance;
                        Address.sendValue(payable(msg.sender),tokenBalance);
                    }
                    
                    else {
                        
                        _approveTokenIfNeeded(address(iAddress),address(iAddress));
                        uint256 _tokenBalance = IERC20(reverseSwapPaths[iAddress].token0path[0]).balanceOf(address(this));
                        alpaca(address(iAddress)).withdraw(
                            IERC20(iAddress).balanceOf(address(this))
                        );
                        uint256 tokenBalance = IERC20(reverseSwapPaths[iAddress].token0path[0]).balanceOf(address(this)) - _tokenBalance;
                        uint256 _returned1 = 0;
                        if(reverseSwapPaths[iAddress].token0path[0] != tokenAddress && reverseSwapPaths[iAddress].token0path[reverseSwapPaths[iAddress].token0path.length.sub(1)] == tokenAddress) {
                            _returned1 = _safeSwap(
                                routerAddress,
                                tokenBalance,
                                slippage,
                                reverseSwapPaths[iAddress].token0path,
                                address(this),
                                block.timestamp.add(600)
                            );
                        }
                        _unwrapBNB(_returned1);
                        Address.sendValue(payable(msg.sender),_returned1);
                    }
                }
        }
        
    }
    
    function withdrawTokens(IERC20[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(!isPresent[tokens[i]],"ERROR: Cannot withdraw LPs");
            require(tokens[i] != IERC20(tenToken), "ERROR: Cannot withdraw reward token");
            uint256 qty;

            if (tokens[i] == IERC20(address(0))) {
                qty = address(this).balance;
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    
    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual returns(uint256) {
        _approveTokenIfNeeded(_path[0],_uniRouterAddress);
        uint256[] memory amounts =
            IPancakeRouter02(_uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)].mul(_slippageFactor).div(1000);
        uint256 _returned = IPancakeRouter02(_uniRouterAddress)
            .swapExactTokensForTokens(
            _amountIn,
            amountOut,
            _path,
            _to,
            _deadline
        )[amounts.length.sub(1)];
        return _returned;
    }
    
    function _unwrapBNB(uint256 amount) internal virtual {
        // WBNB -> BNB
        if (amount > 0) {
            IWBNB(wbnbAddress).withdraw(amount); // WBNB -> BNB
        }
    }
    
    receive() external payable{
        // require(msg.sender == wbnbAddress);
    }
    
    modifier alloweWithdrawTokens (address tokenAddress) {
        require(tokenAddress == wbnbAddress, "Not Allowed");
        _;
    }
    
    event _deposit (address indexed user, address indexed token, uint256 indexed amount);
    event _withdraw (address indexed user, address indexed token, uint256 indexed percent);
    
}