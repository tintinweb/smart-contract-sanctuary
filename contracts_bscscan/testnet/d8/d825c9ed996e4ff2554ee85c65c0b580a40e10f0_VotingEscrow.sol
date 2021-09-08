/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: @openzeppelin/contracts/proxy/Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// File: contracts/UpgradeableOwnable.sol



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
contract UpgradeableOwnable {
    bytes32 private constant _OWNER_SLOT = 0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        assert(_OWNER_SLOT == bytes32(uint256(keccak256("eip1967.proxy.owner")) - 1));
        _setOwner(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function _setOwner(address newOwner) private {
        bytes32 slot = _OWNER_SLOT;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(slot, newOwner)
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address o) {
        bytes32 slot = _OWNER_SLOT;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            o := sload(slot)
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(owner(), address(0));
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}

// File: contracts/interfaces/IStakingPools.sol

pragma solidity ^0.6.12;

interface IStakingPools  {
  function deposit(uint256 _poolId, uint256 _depositAmount) external;
  function exit(uint256 _poolId) external;
  function claim(uint256 _poolId) external;
  function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256);
}

// File: contracts/vaults/Interfaces.sol

pragma solidity ^0.6.0;



interface IPancakeRouter01 {
    // function factory() external pure returns (address);

    // function WETH() external pure returns (address);

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

    // function addLiquidityETH(
    //     address token,
    //     uint256 amountTokenDesired,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // )
    //     external
    //     payable
    //     returns (
    //         uint256 amountToken,
    //         uint256 amountETH,
    //         uint256 liquidity
    //     );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    // function removeLiquidityETH(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountToken, uint256 amountETH);

    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint256 liquidity,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 amountA, uint256 amountB);

    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    // function swapTokensForExactTokens(
    //     uint256 amountOut,
    //     uint256 amountInMax,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256[] memory amounts);

    // function swapExactETHForTokens(
    //     uint256 amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external payable returns (uint256[] memory amounts);

    // function swapTokensForExactETH(
    //     uint256 amountOut,
    //     uint256 amountInMax,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256[] memory amounts);

    // function swapExactTokensForETH(
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256[] memory amounts);

    // function swapETHForExactTokens(
    //     uint256 amountOut,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external payable returns (uint256[] memory amounts);

    // function quote(
    //     uint256 amountA,
    //     uint256 reserveA,
    //     uint256 reserveB
    // ) external pure returns (uint256 amountB);

    // function getAmountOut(
    //     uint256 amountIn,
    //     uint256 reserveIn,
    //     uint256 reserveOut
    // ) external pure returns (uint256 amountOut);

    // function getAmountIn(
    //     uint256 amountOut,
    //     uint256 reserveIn,
    //     uint256 reserveOut
    // ) external pure returns (uint256 amountIn);

    // function getAmountsOut(uint256 amountIn, address[] calldata path)
    //     external
    //     view
    //     returns (uint256[] memory amounts);

    // function getAmountsIn(uint256 amountOut, address[] calldata path)
    //     external
    //     view
    //     returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountETH);
    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 amountETH);
    // function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external;
    // function swapExactETHForTokensSupportingFeeOnTransferTokens(
    //     uint256 amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external payable;
    // function swapExactTokensForETHSupportingFeeOnTransferTokens(
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external;
}


interface IVenusDistribution {
    function claimVenus(address holder) external;

    function enterMarkets(address[] memory _vtokens) external;

    function exitMarket(address _vtoken) external;

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IVBNB {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable;

    // function getAccountSnapshot(address account)
    //     external
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     );

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);
}

interface IVToken is IERC20 {
    function underlying() external returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);
}


interface IBurningStrategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(uint256) external;
    function updateBalance() external;
    function balanceOf() external view returns (uint256);
    function retireStrat() external;
    function harvest() external;
}

interface ISimpleStrategy {
    function deposit(uint256 _tokenAmount) external;
    function withdraw(uint256 _tokenAmount) external;
    function totalBalance() external view returns (uint256);
    function harvest(uint256 priceMin) external;
}

// File: contracts/ReentrancyGuardPausable.sol



pragma solidity ^0.6.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Reuse openzeppelin's ReentrancyGuard with Pausable feature
 */
contract ReentrancyGuardPausable {
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
    uint256 private constant _ENTERED_OR_PAUSED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrantAndUnpaused() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED_OR_PAUSED, "ReentrancyGuard: reentrant call or paused");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED_OR_PAUSED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function _pause() internal {
        _status = _ENTERED_OR_PAUSED;
    }

    function _unpause() internal {
        _status = _NOT_ENTERED;
    }
}

// File: contracts/VotingEscrow.sol



pragma solidity >=0.6.0 <0.8.0;










contract VotingEscrow is IERC20, UpgradeableOwnable, Initializable, ReentrancyGuardPausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _scix;
    IERC20 public _busd;
    address public _collector;
    address public _stakingPools;
    address public _poolToken;
    uint256 public _poolId;
    address public _pancakeRouterAddress;
    address[] public _busdToSCIXPath;

    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public constant MAX_TIME = 1460 days;

    struct LockData {
        uint256 amount;
        uint256 end;
    }
    mapping (address => LockData) private _locks;
    uint256 public _totalLockedSCIX;

    uint256 private _accRewardPerBalance;
    
    mapping (address => uint256) private _rewardDebt;

    mapping (address => bool) public _keepers;

    event LockCreate(address indexed user, uint256 amount, uint256 veAmount, uint256 lockEnd);
    event LockExtend(address indexed user, uint256 amount, uint256 veAmount, uint256 lockEnd);
    event LockIncreaseAmount(address indexed user, uint256 amount, uint256 veAmount, uint256 lockEnd);
    event Withdraw(address indexed user, uint256 amount);
    event KeepersSet(address[] keepers, bool[] states);

    // solium-disable-next-line
    constructor() public {}

    modifier claimReward() {
        _collectReward(false, 0);

        if (_balances[msg.sender] > 0) {
            uint256 pending = _balances[msg.sender].mul(_accRewardPerBalance).div(1e18).sub(_rewardDebt[msg.sender]);
            _scix.safeTransfer(msg.sender, pending);
        }

        _; // _balances[msg.sender] may changed.

        _rewardDebt[msg.sender] = _balances[msg.sender].mul(_accRewardPerBalance).div(1e18);
    }

    modifier onlyKeeper() {
        require(_keepers[msg.sender], "VotingEscrow: !keeper");
        _;
    }

    /*
     * Owner methods
     */
    function initialize(
        IERC20 scix, 
        IERC20 busd, 
        address collector, 
        address stakingPools, 
        address poolToken,
        uint256 poolId,
        address pancakeRouterAddress
    )
        external
        initializer
        onlyOwner
    {
        _name = "Voting Escrow SCIX Token";
        _symbol = "veSCIX";
        _decimals = 18;
        _scix = scix;
        _busd = busd;
        _collector = collector;
        _stakingPools = stakingPools;
        _poolToken = poolToken;
        _poolId = poolId;
        _pancakeRouterAddress = pancakeRouterAddress;

        _busdToSCIXPath = [address(_busd), address(_scix)];
        _busd.safeApprove(_pancakeRouterAddress, uint256(-1));
    }

    // veSCIX ERC20 interface
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        return false;
    }

    function allowance(
        address owner,
        address spender
    )
        public view virtual override returns (uint256)
    {
        return 0;
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external virtual override returns (bool)
    {
        return false;
    }

    function amountOf(address account) public view returns (uint256) {
        return _locks[account].amount;
    }

    function endOf(address account) public view returns (uint256) {
        return _locks[account].end;
    }

    function maxEnd() public view returns (uint256) {
        return block.timestamp + MAX_TIME;
    }

    function createLock(uint256 amount, uint256 end) external nonReentrantAndUnpaused {
        _createLock(amount, end, block.timestamp);
    }

    function _createLock(uint256 amount, uint256 end, uint256 timestamp) internal claimReward {
        LockData storage lock = _locks[msg.sender];

        require(lock.amount == 0, "must no locked");
        require(end <= timestamp + MAX_TIME, "end too long");
        require(end > timestamp, "end too short");
        require(amount != 0, "amount must be non-zero");

        _scix.safeTransferFrom(msg.sender, address(this), amount);
        _totalLockedSCIX = _totalLockedSCIX.add(amount);

        lock.amount = amount;
        lock.end = end;

        _updateBalance(msg.sender, (end - timestamp).mul(amount).div(MAX_TIME));

        emit LockCreate(msg.sender, lock.amount, _balances[msg.sender], lock.end);
    }

    function addAmount(uint256 amount) external nonReentrantAndUnpaused {
        _addAmount(amount, block.timestamp);
    }

    function _addAmount(uint256 amount, uint256 timestamp) internal claimReward {
        LockData storage lock = _locks[msg.sender];

        require(lock.amount != 0, "must locked");
        require(lock.end > timestamp, "must not expired");
        require(amount != 0, "_amount must be nonzero");

        _scix.safeTransferFrom(msg.sender, address(this), amount);

        lock.amount = lock.amount.add(amount);
        _totalLockedSCIX = _totalLockedSCIX.add(amount);

        _updateBalance(
            msg.sender,
            _balances[msg.sender].add((lock.end - timestamp).mul(amount).div(MAX_TIME))
        );

        emit LockIncreaseAmount(msg.sender, lock.amount, _balances[msg.sender], lock.end);
    }

    function extendLock(uint256 end) external nonReentrantAndUnpaused {
        _extendLock(end, block.timestamp);
    }

    function _extendLock(uint256 end, uint256 timestamp) internal claimReward {
        LockData storage lock = _locks[msg.sender];
        require(lock.amount != 0, "must locked");
        require(lock.end < end, "new end must be longer");
        require(end <= timestamp + MAX_TIME, "end too long");

        // calculate equivalent lock duration
        uint256 duration = _balances[msg.sender].mul(MAX_TIME).div(lock.amount);
        duration += (end - lock.end);
        require(duration <= MAX_TIME, "duration too long");

        lock.end = end;
        _updateBalance(msg.sender, duration.mul(lock.amount).div(MAX_TIME));

        emit LockExtend(msg.sender, lock.amount, _balances[msg.sender], lock.end);
    }

    function withdraw() external nonReentrantAndUnpaused {
        _withdraw(block.timestamp);
    }

    function _withdraw(uint256 timestamp) internal claimReward {
        LockData storage lock = _locks[msg.sender];

        require(lock.end <= timestamp, "must expired");

        uint256 amount = lock.amount;
        _scix.safeTransfer(msg.sender, amount);
        _totalLockedSCIX = _totalLockedSCIX.sub(amount);
        
        lock.amount = 0;
        _updateBalance(msg.sender, 0);

        emit Withdraw(msg.sender, amount);
    }

    function depositPoolToken() external onlyOwner nonReentrantAndUnpaused {
        uint256 poolTokenBalance = IERC20(_poolToken).balanceOf(address(this));
        IERC20(_poolToken).approve(_stakingPools, poolTokenBalance);
        IStakingPools(_stakingPools).deposit(_poolId, poolTokenBalance);
    }

    function exitPool() external onlyOwner nonReentrantAndUnpaused {
        IStakingPools(_stakingPools).exit(_poolId);
    }

    function pause(uint256 flag) external onlyOwner {
        _pause();
        _busd.safeApprove(_pancakeRouterAddress, 0);
    }

    function unpause(uint256 flag) external onlyOwner {
        _unpause();
        _busd.safeApprove(_pancakeRouterAddress, uint256(-1));
    }
    
    function setKeepers(address[] calldata keepers, bool[] calldata states) external onlyOwner {
        uint256 n = keepers.length;
        for(uint256 i = 0; i < n; i++) {
            _keepers[keepers[i]] = states[i];
        }
        emit KeepersSet(keepers, states);
    }

    // solium-disable-next-line no-empty-blocks
    function claim() external claimReward nonReentrantAndUnpaused {
    }

    function _updateBalance(address account, uint256 newBalance) internal {
        _totalSupply = _totalSupply.sub(_balances[account]).add(newBalance);
        _balances[account] = newBalance;
    }

    function collectReward(bool buyback, uint256 priceMin) external onlyKeeper nonReentrantAndUnpaused {
        _collectReward(buyback, priceMin);
    }

    function _collectReward(bool buyback, uint256 priceMin) private {
        if (_totalSupply == 0)
            return;
        
        uint256 balanceBefore = IERC20(_scix).balanceOf(address(this));

        uint256 newReward = _busd.balanceOf(_collector);
        if (buyback && newReward > 0) {
            _busd.safeTransferFrom(_collector, address(this), newReward);
            IPancakeRouter02(_pancakeRouterAddress).swapExactTokensForTokens(
                newReward,
                newReward.mul(priceMin),
                _busdToSCIXPath,
                address(this),
                now.add(600)
            );
        }
        
        IStakingPools(_stakingPools).claim(_poolId);
        uint256 rewards = IERC20(_scix).balanceOf(address(this)).sub(balanceBefore);
        
        _accRewardPerBalance = _accRewardPerBalance.add(rewards.mul(1e18).div(_totalSupply));
    }

    function pendingReward() public view returns (uint256 pending) {
        if (_balances[msg.sender] > 0) {
            uint256 newStakingReward = IStakingPools(_stakingPools).getStakeTotalUnclaimed(address(this), _poolId);
            uint256 newAccRewardPerBalance = _accRewardPerBalance.add(newStakingReward.mul(1e18).div(_totalSupply));
            pending = _balances[msg.sender].mul(newAccRewardPerBalance).div(1e18).sub(_rewardDebt[msg.sender]);
        }
    }

    function setNewRouter(address routerAddress) external {
        _pancakeRouterAddress = routerAddress;
    }
}