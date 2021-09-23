pragma solidity ^0.8.0;

import "../interfaces/factorys/IPoolFactory.sol";
import "../interfaces/registers/IPoolRegister.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";
import "../pools/PrivatePool.sol";

contract PrivatePoolFactory is IPoolFactory, Managed {
    IPoolRegister public poolRegister;
    address public ownership;

    constructor(address _management) Managed(_management) {}

    function setDependency() external override onlyOwner {
        poolRegister = IPoolRegister(
            management.contractRegistry(CONTRACT_POOL_REGISTER)
        );
        ownership = management.contractRegistry(ADDRESS_OWNER);
    }

    function create(
        string memory _name,
        bool _isETHStake,
        address _depositeToken,
        address _ownerRecipient,
        uint256 _totalRaise,
        uint256 _feePercentage
    ) external override requirePermission(ROLE_ADMIN) {
        PrivatePool pool = new PrivatePool(
            address(management),
            _name,
            _isETHStake,
            _depositeToken,
            _ownerRecipient,
            _totalRaise,
            _feePercentage
        );
        pool.setDependency();
        pool.transferOwnership(ownership);
        poolRegister.add(address(pool), true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/DecimalsConverter.sol";

import "../management/Managed.sol";
import "../management/Constants.sol";

contract PrivatePool is Managed {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    event SetTotalRaise(uint256 amount);
    event Deposite(address indexed sender, uint256 amount);
    event Harvest(address indexed sender, uint256 amount);
    event WithdrawOwner(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 fee
    );
    event EmergencyCall(address indexed sender);

    struct RewardTokenInfo {
        uint256 amount;
        address token;
        string name;
    }

    event SetRewardTokenAddress(uint256 id, address token, bool isTransfer);
    event SetTokenAmount(uint256 id, uint256 amount, bool isTransfer);

    event AddRewardsTokens(
        string[] tokensName,
        address[] rewardsTokens,
        uint256[] tokenAmount
    );

    event SetVesting(
        bool withoutVesting,
        uint256 delayDuration,
        uint256 availiableImmediately,
        uint256 percentagePerBlock,
        uint256 blockDuration,
        uint256[] percentagePerMonth
    );

    event SetTimePoint(
        uint256 saleStartDate,
        uint256 firstRoundStart,
        uint256 secondRoundStart,
        uint256 saleEndDate
    );

    event SetWhitelist(address[] users, uint256[] allocation);

    event StartVesting(uint256 vestingStartDate);

    mapping(address => mapping(address => uint256)) internal harvestPaid;

    uint256 internal saleStartDate;
    uint256 internal vestingStartDate;
    uint256 internal firstRoundDuration;
    uint256 internal secondRoundDuration;
    uint256 internal saleEndDate;

    uint256 internal delayDuration;
    bool internal noVesting;
    uint256 internal availiableImmediately;
    uint256 internal percentagePerBlock;
    uint256[] internal percentagePerMonth;

    string public name;
    bool public isContribute;
    address public immutable ownerRecipient;
    address public immutable depositeToken;
    address payable internal tresuary;

    uint256 public totalRaise;
    uint256 public totalDeposited;
    uint256 public immutable feePercentage;
    uint256 public blockDuration;
    uint256 public depositeDecimals;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public allocation;

    RewardTokenInfo[] public rewardsTokenInfo;

    modifier canDeposite(bool isETHStake) {
        require(
            (depositeToken == address(0)) == isETHStake,
            "Pool: deposit method not available"
        );
        require(allocation[msg.sender] > 0, "Pool: absence in whitelist");
        require(
            block.timestamp >= saleStartDate && block.timestamp <= saleEndDate,
            "Pool: sale round is close"
        );
        _;
    }

    constructor(
        address _management,
        string memory _name,
        bool _isETHStake,
        address _depositeToken,
        address _ownerRecipient,
        uint256 _totalRaise,
        uint256 _feePercentage
    ) Managed(_management) {
        require(
            (_isETHStake && _depositeToken == address(0)) ||
                (!_isETHStake && _depositeToken != address(0)),
            "Pool: incorect setup type for deposite"
        );
        require(
            _ownerRecipient != address(0),
            "Pool: owner pecipient can't be zero"
        );
        require(_totalRaise > 0, "Pool: can't be zero");

        name = _name;

        ownerRecipient = _ownerRecipient;
        depositeToken = _depositeToken;
        totalRaise = _totalRaise;
        feePercentage = _feePercentage;
        if (_isETHStake) {
            depositeDecimals = 18;
        } else {
            depositeDecimals = IERC20Metadata(_depositeToken).decimals();
        }
    }

    function setDependency() external onlyOwner {
        tresuary = payable(management.contractRegistry(ADDRESS_TRESUARY));
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return deposited[_addr];
    }

    function getAvailHarvest(address _sender)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory availHarverst)
    {
        uint256 size = rewardsTokenInfo.length;
        rewardTokens = new address[](size);
        availHarverst = new uint256[](size);
        for (uint256 index = 0; index < size; index++) {
            RewardTokenInfo memory info = rewardsTokenInfo[index];
            rewardTokens[index] = info.token;
            availHarverst[index] = _calculateAvailHarvest(_sender, info);
        }
    }

    function getAvailAllocation(address _sender)
        external
        view
        returns (uint256)
    {
        return _getAvailAllocation(_sender);
    }

    function getAllTimePoint()
        external
        view
        returns (
            uint256 saleStart,
            uint256 vestingStart,
            uint256 firstRoundStart,
            uint256 secondRoundStart,
            uint256 saleEnd
        )
    {
        saleStart = saleStartDate;
        vestingStart = vestingStartDate;
        firstRoundStart = saleStartDate;
        secondRoundStart = saleStartDate + firstRoundDuration;
        saleEnd = saleEndDate;
    }

    function getVestingInfo()
        external
        view
        returns (
            bool withoutVesting,
            uint256 delay,
            uint256 availiableInStart,
            uint256 timeUnitDuration,
            uint256 percentPerBlock,
            uint256[] memory percentPerMonth
        )
    {
        withoutVesting = noVesting;
        delay = delayDuration;
        availiableInStart = availiableImmediately;
        percentPerBlock = percentagePerBlock;
        timeUnitDuration = blockDuration;
        percentPerMonth = new uint256[](percentagePerMonth.length);
        for (uint256 index = 0; index < percentagePerMonth.length; index++) {
            percentPerMonth[index] = percentagePerMonth[index];
        }
    }

    function getRewardsTokenInfo()
        external
        view
        returns (RewardTokenInfo[] memory rewardsInfo)
    {
        rewardsInfo = new RewardTokenInfo[](rewardsTokenInfo.length);
        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            rewardsInfo[index] = rewardsTokenInfo[index];
        }
    }

    function getTokenPriceInfo()
        external
        view
        returns (address[] memory tokens, uint256[] memory pricePerToken)
    {
        uint256 size = rewardsTokenInfo.length;
        tokens = new address[](size);
        pricePerToken = new uint256[](size);
        for (uint256 i = 0; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo memory info = rewardsTokenInfo[i];
            tokens[i] = info.token;
            pricePerToken[i] = (totalRaise * DECIMALS18) / info.amount;
        }
    }

    function harvest() external {
        require(
            vestingStartDate > 0 &&
                block.timestamp >= vestingStartDate + delayDuration,
            "Pool: Vesting can't be started"
        );
        for (uint256 i = 0; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo storage info = rewardsTokenInfo[i];
            uint256 availHarvest = _calculateAvailHarvest(msg.sender, info);
            if (availHarvest > 0) {
                harvestPaid[info.token][msg.sender] += availHarvest;
                IERC20(info.token).safeTransfer(
                    msg.sender,
                    DecimalsConverter.convertFrom18(
                        availHarvest,
                        IERC20Metadata(info.token).decimals()
                    )
                );
            }
            emit Harvest(msg.sender, availHarvest);
        }
    }

    function deposite(uint256 _amount)
        external
        requireKYCWhitelist
        canDeposite(false)
    {
        require(_amount > 0, "Pool: Can't be zero");
        require(
            _getAvailAllocation(msg.sender) >= _amount,
            "Pool: not enought allocation"
        );

        IERC20(depositeToken).safeTransferFrom(
            msg.sender,
            address(this),
            DecimalsConverter.convertFrom18(_amount, depositeDecimals)
        );
        deposited[msg.sender] += _amount;
        totalDeposited += _amount;
        emit Deposite(msg.sender, _amount);
    }

    function depositeETH()
        external
        payable
        requireKYCWhitelist
        canDeposite(true)
    {
        uint256 _amount = msg.value;
        require(_amount > 0, "Pool: Can't be zero");
        require(
            _getAvailAllocation(msg.sender) >= _amount,
            "Pool: not enought allocation"
        );

        deposited[msg.sender] += _amount;
        totalDeposited += _amount;
        emit Deposite(msg.sender, _amount);
    }

    function setWhitelist(
        address[] calldata _users,
        uint256[] calldata _allocation
    ) external requirePermission(ROLE_ADMIN) {
        require(_users.length == _allocation.length, "Pool: Incorrect input");
        for (uint256 i = 0; i < _users.length; i++) {
            allocation[_users[i]] = _allocation[i];
        }
        emit SetWhitelist(_users, _allocation);
    }

    function startVesting() external requirePermission(ROLE_ADMIN) {
        require(vestingStartDate == 0, "Pool: vesting already started");
        require(
            rewardsTokenInfo.length > 0,
            "Pool: not specified rewards tokens"
        );
        require(saleEndDate != 0, "Pool: not setup time point");

        vestingStartDate = Math.max(block.timestamp, saleEndDate);
        emit StartVesting(vestingStartDate);
    }

    function setRewardTokenAddress(
        uint256 _id,
        address _token,
        bool _isTransfer
    ) external requirePermission(ROLE_ADMIN) {
        RewardTokenInfo storage info = rewardsTokenInfo[_id];
        info.token = _token;
        if (_isTransfer)
            IERC20(_token).safeTransferFrom(
                msg.sender,
                address(this),
                DecimalsConverter.convertFrom18(info.amount, IERC20Metadata(_token).decimals())
            );

        emit SetRewardTokenAddress(_id, _token, _isTransfer);
    }

    function addRewardsTokens(
        string[] calldata _tokensName,
        address[] calldata _rewardsTokens,
        uint256[] calldata _tokenAmount,
        bool _isTransfer
    ) external requirePermission(ROLE_ADMIN) {
        require(
            _tokensName.length == _rewardsTokens.length,
            "Pool: Incorect input"
        );
        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            RewardTokenInfo memory info;

            info.amount = _tokenAmount[i];
            info.token = _rewardsTokens[i];
            info.name = _tokensName[i];

            rewardsTokenInfo.push(info);

            if (_isTransfer)
                IERC20(_rewardsTokens[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    DecimalsConverter.convertFrom18(_tokenAmount[i], IERC20Metadata(_rewardsTokens[i]).decimals())
                );
        }

        emit AddRewardsTokens(_tokensName, _rewardsTokens, _tokenAmount);
    }

    function setTotalRaise(uint256 _amount)
        external
        requirePermission(ROLE_ADMIN)
    {
        totalRaise = _amount;
        emit SetTotalRaise(_amount);
    }

    function setTokenAmount(
        uint256 _id,
        uint256 _amount,
        bool _isTransfer
    ) external requirePermission(ROLE_ADMIN) {
        require(
            block.timestamp <= saleEndDate,
            "Pool: can't change after end sale"
        );
        RewardTokenInfo storage info = rewardsTokenInfo[_id];
        if (_isTransfer && info.token != address(0)) {
            if (_amount > info.amount) {
                IERC20(info.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    DecimalsConverter.convertFrom18(_amount - info.amount, IERC20Metadata(info.token).decimals())
                );
            } else {
                IERC20(info.token).safeTransfer(
                    msg.sender,
                                        DecimalsConverter.convertFrom18(info.amount - _amount, IERC20Metadata(info.token).decimals())
                );
            }
        }

        info.amount = _amount;

        emit SetTokenAmount(_id, _amount, _isTransfer);
    }

    function withdrawContributions() external {
        require(
            ownerRecipient == msg.sender,
            "Pool: you don't have permission's"
        );

        require(!isContribute, "Pool: You already contribute");
        require(saleEndDate < block.timestamp, "Pool: Sale not finished");

        isContribute = true;

        uint256 balance = address(this).balance;
        uint256 fee = (feePercentage * balance) / PERCENTAGE_100;

        if (balance > 0) {
            payable(ownerRecipient).sendValue(balance - fee);
            tresuary.sendValue(fee);
            emit WithdrawOwner(msg.sender, address(0), balance, fee);
        }

        IERC20 erc20 = IERC20(depositeToken);

        balance = erc20.balanceOf(address(this));
        fee = (feePercentage * balance) / PERCENTAGE_100;

        erc20.safeTransfer(ownerRecipient, balance - fee);
        erc20.safeTransfer(tresuary, fee);

        emit WithdrawOwner(msg.sender, depositeToken, balance, fee);

        uint256 finishPercentage = (totalDeposited * DECIMALS18) / totalRaise;

        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            RewardTokenInfo memory info = rewardsTokenInfo[index];
            uint256 unsoldTokens = info.amount -
                ((info.amount * finishPercentage) / (DECIMALS18));
            erc20 = IERC20(info.token);
            erc20.safeTransfer(ownerRecipient, DecimalsConverter.convertFrom18(unsoldTokens, IERC20Metadata(info.token).decimals()));
            emit WithdrawOwner(
                msg.sender,
                info.token,
                unsoldTokens,
                finishPercentage
            );
        }
    }

    function emergencyFunction() external requirePermission(ROLE_ADMIN) {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            tresuary.sendValue(balance);
        }

        IERC20 erc20 = IERC20(depositeToken);

        balance = erc20.balanceOf(address(this));
        erc20.safeTransfer(EMERGENCY_ADDRESS, balance);

        for (uint256 index = 0; index < rewardsTokenInfo.length; index++) {
            RewardTokenInfo memory info = rewardsTokenInfo[index];
            erc20 = IERC20(info.token);
            erc20.safeTransfer(EMERGENCY_ADDRESS, erc20.balanceOf(address(this)));
        }

        emit EmergencyCall(msg.sender);
    }

    function setTimePoints(
        uint256 _saleStartDate,
        uint256 _firstRoundDuration,
        uint256 _secondRoundDuration
    ) external requirePermission(ROLE_ADMIN) {
        require(
            _saleStartDate > 0 &&
                _firstRoundDuration > 0 &&
                _secondRoundDuration > 0,
            "Pool: round duration can't be zero"
        );

        saleStartDate = _saleStartDate;
        firstRoundDuration = _firstRoundDuration;
        secondRoundDuration = _secondRoundDuration;
        saleEndDate =
            _saleStartDate +
            _firstRoundDuration +
            _secondRoundDuration;

        emit SetTimePoint(
            saleStartDate,
            saleStartDate,
            saleStartDate + firstRoundDuration,
            saleEndDate
        );
    }

    function setVesting(
        bool _withoutVesting,
        uint256 _delayDuration,
        uint256 _availiableImmediately,
        uint256 _percentagePerBlock,
        uint256 _blockDuration,
        uint256[] calldata _percentagePerMonth
    ) external requirePermission(ROLE_ADMIN) {
        if (_withoutVesting) {
            noVesting = _withoutVesting;
            return;
        }
        require(
            !(_percentagePerBlock > 0 && _percentagePerMonth.length > 0),
            "Pool: cannot be set"
        );
        blockDuration = _blockDuration;
        delayDuration = _delayDuration;
        availiableImmediately = _availiableImmediately;
        percentagePerBlock = _percentagePerBlock;
        delete percentagePerMonth;
        for (uint256 i = 0; i < _percentagePerMonth.length; i++) {
            percentagePerMonth.push(_percentagePerMonth[i]);
        }

        emit SetVesting(
            _withoutVesting,
            _delayDuration,
            _availiableImmediately,
            _percentagePerBlock,
            _blockDuration,
            _percentagePerMonth
        );
    }

    function _getAvailAllocation(address _sender)
        internal
        view
        returns (uint256)
    {
        if (allocation[_sender] == 0) return 0;

        if (block.timestamp > saleStartDate + firstRoundDuration) {
            return totalRaise - totalDeposited;
        }
        return
            (allocation[_sender] * totalRaise) /
            PERCENTAGE_100 -
            deposited[_sender];
    }

    function _calculateAvailHarvest(
        address _sender,
        RewardTokenInfo memory _info
    ) internal view returns (uint256) {
        if (
            vestingStartDate == 0 ||
            block.timestamp < vestingStartDate + delayDuration
        ) return 0;
        uint256 canHarvestAmount = (deposited[_sender] * DECIMALS18 * _info.amount) /
            totalRaise /
            DECIMALS18;

        if (noVesting) {
            return canHarvestAmount - harvestPaid[_info.token][_sender];
        }

        uint256 amountImmediatelu = (availiableImmediately * canHarvestAmount) /
            PERCENTAGE_100;

        uint256 accruedAmount;

        if (percentagePerMonth.length > 0) {
            uint256 sumPercentByMonth = 0;
            uint256 monthCount = (block.timestamp -
                vestingStartDate -
                delayDuration) / (30 days);

            monthCount = Math.min(monthCount, percentagePerMonth.length);

            for (uint256 i = 0; i < monthCount; i++) {
                sumPercentByMonth += percentagePerMonth[i];
            }
            accruedAmount =
                (sumPercentByMonth * canHarvestAmount) /
                PERCENTAGE_100;
        } else {
            uint256 blockPassted = (block.timestamp -
                vestingStartDate -
                delayDuration) / blockDuration;
            accruedAmount =
                (blockPassted * percentagePerBlock * canHarvestAmount) /
                PERCENTAGE_100;
        }
        canHarvestAmount = Math.min(
            canHarvestAmount,
            amountImmediatelu + accruedAmount
        );

        return canHarvestAmount - harvestPaid[_info.token][_sender];
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";

contract Management is Ownable {
    using SafeMath for uint256;

    // Contract Registry
    mapping(uint256 => address payable) public contractRegistry;

    // Permissions
    mapping(address => mapping(uint256 => bool)) public permissions;

    event PermissionsSet(
        address indexed subject,
        uint256[] indexed permissions,
        bool value
    );

    event UsersPermissionsSet(
        address[] indexed subject,
        uint256 indexed permissions,
        bool value
    );

    event PermissionSet(
        address indexed subject,
        uint256 indexed permission,
        bool value
    );

    event ContractRegistered(
        uint256 indexed key,
        address indexed source,
        address target
    );

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external onlyOwner {
        permissions[_address][_permission] = _value;
        emit PermissionSet(_address, _permission, _value);
    }

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external onlyOwner {
        for (uint256 i = 0; i < _permissions.length; i++) {
            permissions[_address][_permissions[i]] = _value;
        }
        emit PermissionsSet(_address, _permissions, _value);
    }

    function registerContract(uint256 _key, address payable _target)
        external
        onlyOwner
    {
        contractRegistry[_key] = _target;
        emit ContractRegistered(_key, address(0), _target);
    }

    function setKycWhitelist(address _address, bool _value) external {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        permissions[_address][WHITELISTED_KYC] = _value;

        emit PermissionSet(_address, WHITELISTED_KYC, _value);
    }

    function setKycWhitelists(address[] calldata _address, bool _value)
        external
    {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_KYC] = _value;
        }
        emit UsersPermissionsSet(_address, WHITELISTED_KYC, _value);
    }

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external
    {
        require(
            permissions[msg.sender][CAN_SET_PRIVATE_WHITELISTED],
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_PRIVATE] = _value;
        }

        emit UsersPermissionsSet(_address, WHITELISTED_PRIVATE, _value);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";
import "./Management.sol";

contract Managed is Ownable {
    using SafeMath for uint256;

    Management public management;

    modifier requirePermission(uint256 _permission) {
        require(
            hasPermission(msg.sender, _permission),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireKYCWhitelist() {
        require(
            hasPermission(msg.sender, WHITELISTED_KYC),
            ERROR_ACCESS_DENIED
        );
        _;
    }
    modifier requirePrivateWhitelist(bool _isPrivate) {
        if (_isPrivate) {
            require(
                hasPermission(msg.sender, WHITELISTED_PRIVATE),
                ERROR_ACCESS_DENIED
            );
        }
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(
            management.contractRegistry(_key) != address(0),
            ERROR_NO_CONTRACT
        );
        _;
    }

    constructor(address _managementAddress) {
        management = Management(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = Management(_management);
    }

    function hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }

}

pragma solidity ^0.8.0;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 10000;
uint256 constant PERCENTAGE_1 = 100;
uint256 constant MAX_FEE_PERCENTAGE = PERCENTAGE_100 - PERCENTAGE_1;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
string constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
string constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";


address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 5;

uint256 constant CAN_SET_KYC_WHITELISTED = 10;
uint256 constant CAN_SET_PRIVATE_WHITELISTED = 11;

uint256 constant WHITELISTED_KYC = 20;
uint256 constant WHITELISTED_PRIVATE = 21;

uint256 constant CAN_SET_REMAINING_SUPPLY = 29;

uint256 constant CAN_TRANSFER_NFT = 30;
uint256 constant CAN_MINT_NFT = 31;
uint256 constant CAN_BURN_NFT = 32;

uint256 constant CAN_ADD_STAKING = 43;
uint256 constant CAN_ADD_POOL = 45;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKE_FACTORY = 2;
uint256 constant CONTRACT_NFT_FACTORY = 3;
uint256 constant CONTRACT_LIQUIDITY_MINING_FACTORY = 4;
uint256 constant CONTRACT_STAKING_REGISTER = 5;
uint256 constant CONTRACT_POOL_REGISTER = 6;

uint256 constant ADDRESS_TRESUARY = 10;
uint256 constant ADDRESS_SIGNER = 11;
uint256 constant ADDRESS_OWNER = 12;

pragma solidity ^0.8.0;

library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

pragma solidity ^0.8.0;

interface IPoolRegister {
    event AddPool(address indexed sender, address pool, bool isPrivate);
    event RemovePool(address indexed sender, address pool);

    function add(address _pool, bool _isPrivate) external;

    function remove(address _pool) external;

    function list(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory result);
}

pragma solidity ^0.8.0;

interface IPoolFactory {
    function setDependency() external;

    function create(
        string memory _name,
        bool _isETHStake,
        address _depositeToken,
        address _ownerRecipient,
        uint256 _totalRaise,
        uint256 _feePercentage
    ) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}