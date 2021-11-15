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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
pragma solidity 0.8.7;

import './interfaces/IInvestorV1Factory.sol';

import './InvestorV1PoolDeployer.sol';
import './InvestorV1Pool.sol';
import './NoDelegateCall.sol';

contract InvestorV1Factory is IInvestorV1Factory, InvestorV1PoolDeployer, NoDelegateCall {
    address public override owner;
    address[] public override poolList;
    uint256 public override pools = 0;

    mapping(address => mapping(string => mapping(uint256 => address))) public override getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function createPool(
        address operator,
        string memory name,
        uint256 maxCapacity,
        uint256 minCapacity,
        uint256 oraclePrice,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate
    ) external override noDelegateCall returns (address pool) {
        require(msg.sender == owner, "InvestorV1Factory: not owner");
        require(operator != address(0), "InvestorV1Factory: operator is zero address");
        require(maxCapacity > 0, "InvestorV1Factory: maxCapacity is zero");
        require(startTime > block.timestamp, "InvestorV1Factory: startTime before now");
        require(startTime < endTime, "InvestorV1Factory: startTime after endTime");
        require(startTime < stageTime, "InvestorV1Factory: startTime after stageTime");
        require(stageTime < endTime, "InvestorV1Factory: stageTime after endTime");
        require(fee < 10000, "InvestorV1Factory: fee over 10000");
        require(oraclePrice > 0, "InvestorV1Factory: zero oraclePrice");
        require(getPool[operator][name][startTime] == address(0), "InvestorV1Factory: pool exists");
        pool = deploy(
            address(this),
            operator,
            name,
            maxCapacity,
            minCapacity,
            oraclePrice,
            startTime,
            stageTime,
            endTime,
            fee,
            interestRate
        );
        getPool[operator][name][startTime] = pool;
        poolList.push(pool);
        pools = pools + 1;

        emit PoolCreated(operator,name,maxCapacity,minCapacity,startTime,stageTime,endTime,fee,interestRate,pool);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, "InvestorV1Factory: not owner");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IInvestorV1Pool.sol";
import "./interfaces/IInvestorV1PoolDeployer.sol";

contract InvestorV1Pool is IInvestorV1Pool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant HSF = 0xbA6B0dbb2bA8dAA8F5D6817946393Aef8D3A4487;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public immutable override factory;
    address public immutable override operator;
    string public override name;
    uint256 public immutable override maxCapacity;
    uint256 public immutable override minCapacity;
    uint256 public override oraclePrice;
    uint256 public immutable override startTime;
    uint256 public immutable override stageTime;
    uint256 public immutable override endTime;
    uint24 public immutable override fee;
    uint24 public immutable override interestRate;

    mapping(address => uint256) public override pooledAmt;
    mapping(address => uint256) public override restakeAmt;
    mapping(address => bool) public override claimed;

    address[] public override depositorList;
    address[] public override restakerList;

    uint256 public override funded = 0;
    uint256 public override exited = 0;
    uint256 public override restaked = 0;

    string public override collateralDocument;
    string public override collateralHash;
    string public override detailLink;

    enum PoolState { Created, Opened, Active, Reverted, Liquidated, Dishonored }

    PoolState private poolState = PoolState.Created;

    modifier onlyOperator() {
        require(operator == msg.sender, "InvestorV1Pool: not operator");
        _;
    }
    
    constructor() {
        ( 
            factory, 
            operator, 
            name, 
            maxCapacity, 
            minCapacity
        ) = IInvestorV1PoolDeployer(msg.sender).parameter1();
        (
            oraclePrice, 
            startTime, 
            stageTime, 
            endTime, 
            fee,
            interestRate
        ) = IInvestorV1PoolDeployer(msg.sender).parameter2();
    }

    function depositors() public override view returns(uint256) {
        return depositorList.length;
    }

    function restakers() public override view returns(uint256) {
        return restakerList.length;
    }

    function getInfo(address _account) public override view returns (string memory, string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint24, uint24) {
        uint256 mypool = pooledAmt[_account];
        uint256 myrestake = restakeAmt[_account];
        return (name, getPoolState(), maxCapacity, funded, restaked, exited, mypool, myrestake, fee, interestRate);
    }

    function getExtra() public override view returns (address, address, uint256, uint256, uint256, string memory, string memory, string memory) {
        return (operator, factory, oraclePrice, depositors(), restakers(), collateralDocument, collateralHash, detailLink);
    }

    function expectedRestakeRevenue(uint256 amount) public override view returns (uint256) {
        if(amount == 0) return 0;

        uint256 estimated = (10000 - fee);
        uint256 added = restaked.add(amount);
        estimated = estimated * (10000 + interestRate);
        estimated = exited.mul(estimated);
        estimated = estimated.div(100000000);
        estimated = estimated.mul(amount);
        estimated = estimated.div(added);

        return estimated;
    }

    function getPoolState() public override view returns (string memory) {
        if (poolState == PoolState.Opened) return "Opened";
        if (poolState == PoolState.Active) return "Active";
        if (poolState == PoolState.Created) return "Created";
        if (poolState == PoolState.Dishonored) return "Dishonored";
        if (poolState == PoolState.Liquidated) return "Liquidated";
        if (poolState == PoolState.Reverted) return "Reverted";
        return "Impossible";
    }

    function removeDepositor(address user) internal {
        require(depositorList.length >= 1);
        if(depositorList[depositorList.length-1] == user) {
            depositorList.pop();
            return;
        }

        for (uint i = 0; i < depositorList.length-1; i++){
            if(depositorList[i] == user) {
                depositorList[i] = depositorList[depositorList.length-1];
                depositorList.pop();
                return;
            }
        }
    }

    function removeRestaker(address user) internal {
        require(restakerList.length >= 1);
        if(restakerList[restakerList.length-1] == user) {
            restakerList.pop();
            return;
        }

        for (uint i = 0; i < restakerList.length-1; i++){
            if(restakerList[i] == user) {
                restakerList[i] = restakerList[restakerList.length-1];
                restakerList.pop();
                return;
            }
        }
    }

    // State Update
    function update() public override returns (bool) {
        if(poolState == PoolState.Opened && block.timestamp > stageTime) {
            if(funded >= minCapacity) { 
                poolState = PoolState.Active; 
                exited = maxCapacity - funded;
                emit PoolActiviated(funded);
            }
            else { 
                poolState = PoolState.Reverted; 
                emit PoolReverted(minCapacity, funded);
            }
            return true;
        }

        if(poolState == PoolState.Active && block.timestamp > endTime) {
            uint256 liquidityFund = IERC20(USDT).balanceOf(address(this));
            uint256 estimated = (10000 - fee);
            estimated = estimated * (10000 + interestRate);
            if(exited > 0 && restaked == 0) estimated = funded.mul(estimated);
            else estimated = maxCapacity.mul(estimated);
            estimated = estimated.div(100000000);
            if(liquidityFund >= estimated) { 
                poolState = PoolState.Liquidated; 
                emit PoolLiquidated(liquidityFund);
            }
            else { 
                poolState = PoolState.Dishonored; 
                emit PoolDishonored(estimated, liquidityFund);
            }
        }

        return true;
    }

    function setOraclePrice(uint256 _oraclePrice) public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Opened 
            || poolState == PoolState.Created, "InvestorV1Pool: pool not open");
        require(_oraclePrice != oraclePrice, "InvestorV1Pool: oraclePrice not changed");

        uint256 minDeposit = maxCapacity.mul(100);
        minDeposit = minDeposit.div(_oraclePrice);
        if (maxCapacity.mod(_oraclePrice) != 0) { minDeposit = minDeposit.add(1); }
        minDeposit = minDeposit.mul(10**12);

        if(oraclePrice > _oraclePrice) {
            minDeposit = minDeposit.sub(IERC20(HSF).balanceOf(address(this)));
            oraclePrice = _oraclePrice;

            IERC20(HSF).safeTransferFrom(msg.sender, address(this), minDeposit);
            emit Deposit(HSF, msg.sender, minDeposit);
        }
        else {
            uint256 operatorDeposits = IERC20(HSF).balanceOf(address(this));
            minDeposit = operatorDeposits.sub(minDeposit);
            oraclePrice = _oraclePrice;

            IERC20(HSF).safeTransfer(msg.sender, minDeposit);
            emit Withdrawal(HSF, msg.sender, msg.sender, minDeposit);
        }

        emit OraclePriceChanged(_oraclePrice);

        return true;
    }

    function setPoolDetailLink(string memory _newLink) public override onlyOperator returns (bool) {
        detailLink = _newLink;

        emit PoolDetailLinkChanged(detailLink);

        return true;
    }

    function setColletralHash(string memory _newHash) public override onlyOperator returns (bool) {
        string memory oldHash = collateralHash;
        collateralHash = _newHash;

        emit ColletralHashChanged(oldHash, collateralHash);

        return true;
    }
    function setColletralLink(string memory _newLink) public override onlyOperator returns (bool) {
        string memory oldLink = collateralDocument;
        collateralDocument = _newLink;

        emit ColletralLinkChanged(oldLink, collateralDocument);

        return true;
    }
    
    function rescue(address target) public override onlyOperator returns (bool) {
        require(target != USDT && target != HSF, "InvestorV1Pool: USDT and HSF cannot be rescued");
        require(IERC20(target).balanceOf(address(this)) > 0, "InvestorV1Pool: no target token here");

        IERC20(target).safeTransfer(msg.sender, IERC20(target).balanceOf(address(this)));

        emit Withdrawal(target, msg.sender, msg.sender, IERC20(target).balanceOf(address(this)));

        return true;
    }

    function pullDeposit() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Active, "InvestorV1Pool: pool not active");

        uint256 pooledTotal = IERC20(USDT).balanceOf(address(this));
        IERC20(USDT).safeTransfer(msg.sender, pooledTotal);

        emit Withdrawal(USDT, msg.sender, msg.sender, pooledTotal);

        return true;
    }

    function liquidate() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Active, "InvestorV1Pool: pool not active");
        uint256 estimated = (10000 - fee);
        estimated = estimated * (10000 + interestRate);

        if(exited > 0 && restaked == 0) estimated = funded.mul(estimated);
        else estimated = maxCapacity.mul(estimated);
        
        estimated = estimated.div(100000000);

        uint256 currentBalance = IERC20(USDT).balanceOf(address(this));

        if(estimated <= currentBalance) return true;

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), estimated.sub(currentBalance));

        emit Deposit(USDT, msg.sender, estimated.sub(currentBalance));

        return true;
    }

    function openPool() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Created, "InvestorV1Pool: not create state");

        uint256 minDeposit = maxCapacity.mul(100);
        minDeposit = minDeposit.div(oraclePrice);
        if (maxCapacity.mod(oraclePrice) != 0) { minDeposit = minDeposit.add(1); }
        minDeposit = minDeposit.mul(10**12);

        poolState = PoolState.Opened;

        IERC20(HSF).safeTransferFrom(msg.sender, address(this), minDeposit);

        emit Deposit(HSF, msg.sender, minDeposit);
        emit PoolOpened(msg.sender, startTime, minDeposit);

        return true;
    }
    function closePool() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Liquidated, "InvestorV1Pool: pool not finalized");

        uint256 stakedAmt = IERC20(HSF).balanceOf(address(this));
        IERC20(HSF).safeTransfer(msg.sender, stakedAmt);

        emit Withdrawal(HSF, msg.sender, msg.sender, stakedAmt);

        return true;
    }
    function revertPool() public override onlyOperator returns (bool) {
        update();

        require(poolState == PoolState.Opened 
            || poolState == PoolState.Created, "InvestorV1Pool: not revertable state");

        poolState = PoolState.Reverted;

        uint256 operatorDeposits = IERC20(HSF).balanceOf(address(this));
        IERC20(HSF).safeTransfer(msg.sender, operatorDeposits);

        emit Withdrawal(HSF, msg.sender, msg.sender, operatorDeposits);
        emit PoolReverted(minCapacity, funded);

        return true;
    }

    function deposit(uint256 amount) public override returns (bool) {
        update();

        require(poolState == PoolState.Opened, "InvestorV1Pool: pool not opened");
        require(block.timestamp >= startTime, "InvestorV1Pool: not started yet");
        require(amount > 0, "InvestorV1Pool: amount is zero");
        require(funded.add(amount) <= maxCapacity, "InvestorV1Pool: deposit over capacity");

        pooledAmt[msg.sender] = pooledAmt[msg.sender].add(amount);
        funded = funded.add(amount);
        depositorList.push(msg.sender);

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(USDT, msg.sender, amount);

        return true;
    }

    function withdraw(uint256 amount, address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Opened || poolState == PoolState.Reverted, "InvestorV1Pool: pool not opened");
        require(block.timestamp >= startTime, "InvestorV1Pool: not started yet");
        require(pooledAmt[msg.sender] >= amount, "InvestorV1Pool: not enough deposit");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        pooledAmt[msg.sender] = pooledAmt[msg.sender].sub(amount);
        funded = funded.sub(amount);
        if(pooledAmt[msg.sender]==0) {
            removeDepositor(msg.sender);
        }

        IERC20(USDT).safeTransfer(to, amount);

        emit Withdrawal(USDT, msg.sender, to, amount);

        return true;
    }

    function exit(uint256 amount, address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Active || poolState == PoolState.Dishonored, "InvestorV1Pool: pool not active");
        require(pooledAmt[msg.sender] >= amount, "InvestorV1Pool: not enough deposit");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        pooledAmt[msg.sender] = pooledAmt[msg.sender].sub(amount);
        exited = exited.add(amount);
        if(pooledAmt[msg.sender]==0) {
            removeDepositor(msg.sender);
        }

        uint256 exitAmt = amount.mul(10**14);
        exitAmt = exitAmt.div(oraclePrice);

        IERC20(HSF).safeTransfer(to, exitAmt);

        emit Exited(msg.sender, to, exitAmt);

        return true;
    }

    function claim(address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Liquidated, "InvestorV1Pool: pool not finalized");
        require(!claimed[msg.sender], "InvestorV1Pool: already claimed");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        
        uint256 liquidityTotal = (10000 - fee);
        liquidityTotal = liquidityTotal * (10000 + interestRate);
        liquidityTotal = maxCapacity.mul(liquidityTotal);
        liquidityTotal = liquidityTotal.div(100000000);

        uint256 poolClaim = 0;
        uint256 restakeClaim = 0;

        if(pooledAmt[msg.sender] > 0) {
            poolClaim = liquidityTotal.mul(pooledAmt[msg.sender]);
            poolClaim = poolClaim.div(maxCapacity);   
        }

        if(restakeAmt[msg.sender] > 0 && exited > 0) {
            restakeClaim = liquidityTotal.mul(exited);
            restakeClaim = restakeClaim.mul(restakeAmt[msg.sender]);
            restakeClaim = restakeClaim.div(maxCapacity);
            restakeClaim = restakeClaim.div(restaked);
        }

        claimed[msg.sender] = true;

        require(poolClaim.add(restakeClaim) > 0, "InvestorV1Pool: no claim for you");

        IERC20(USDT).safeTransfer(to, poolClaim.add(restakeClaim));

        emit Claim(msg.sender, to, poolClaim.add(restakeClaim));

        return true;

    }

    function restake(uint256 amount) public override returns (bool) {
        update();

        require(poolState == PoolState.Active, "InvestorV1Pool: pool not active");
        require(exited > 0, "InvestorV1Pool: no capacity for restake");

        restakeAmt[msg.sender] = restakeAmt[msg.sender].add(amount);
        restaked = restaked.add(amount);
        restakerList.push(msg.sender);

        IERC20(HSF).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(HSF, msg.sender, amount);

        return true;

    }

    function unstake(uint256 amount, address to) public override returns (bool) {
        update();

        require(poolState == PoolState.Active || poolState == PoolState.Dishonored, "InvestorV1Pool: pool not active");
        require(restakeAmt[msg.sender] >= amount, "InvestorV1Pool: not enough restake");
        require(to != address(0), "InvestorV1Pool: to address is zero");

        restakeAmt[msg.sender] = restakeAmt[msg.sender].sub(amount);
        restaked = restaked.sub(amount);
        if(restakeAmt[msg.sender]==0) {
            removeRestaker(msg.sender);
        }

        IERC20(HSF).safeTransfer(to, amount);

        emit Withdrawal(HSF, msg.sender, to, amount);

        return true;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './interfaces/IInvestorV1PoolDeployer.sol';

import './InvestorV1Pool.sol';

contract InvestorV1PoolDeployer is IInvestorV1PoolDeployer {
    struct Parameter1 {
        address factory;
        address operator;
        string  name;
        uint256 maxCapacity;
        uint256 minCapacity;
    }

    struct Parameter2 {
        uint256 oraclePrice;
        uint256 startTime;
        uint256 stageTime;
        uint256 endTime;
        uint24  fee;
        uint24  interestRate;
    }

    Parameter1 public override parameter1;
    Parameter2 public override parameter2;

    function deploy(
        address factory,
        address operator,
        string memory name,
        uint256 maxCapacity,
        uint256 minCapacity,
        uint256 oraclePrice,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate
    ) internal returns (address pool) {
        parameter1 = Parameter1({
            factory: factory, 
            operator: operator, 
            name: name, 
            maxCapacity: maxCapacity, 
            minCapacity: minCapacity
        });
        parameter2 = Parameter2({
            oraclePrice: oraclePrice,
            startTime: startTime,
            stageTime: stageTime,
            endTime: endTime,
            fee: fee,
            interestRate: interestRate
        });
        pool = address(new InvestorV1Pool{salt: keccak256(abi.encode(operator, name, startTime))}());
        delete parameter1;
        delete parameter2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract NoDelegateCall {
    address private immutable original;

    constructor() {
        original = address(this);
    }

    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1Factory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event PoolCreated(
        address operator,
        string name,
        uint256 maxCapacity,
        uint256 minCapacity,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate,
        address pool
    );

    function owner() external view returns (address); 

    function pools() external view returns (uint256);

    function poolList(uint256 index) external view returns (address);

    function getPool(
        address operator,
        string memory name,
        uint256 startTime
    ) external view returns (address pool);

    function createPool(
        address operator,
        string memory name,
        uint256 maxCapacity,
        uint256 minCapacity,
        uint256 oraclePrice,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate
    ) external returns (address pool);

    function setOwner(address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './IInvestorV1PoolImmutables.sol';
import './IInvestorV1PoolState.sol';
import './IInvestorV1PoolDerivedState.sol';
import './IInvestorV1PoolActions.sol';
import './IInvestorV1PoolOperatorActions.sol';
import './IInvestorV1PoolEvents.sol';

interface IInvestorV1Pool is 
    IInvestorV1PoolImmutables,
    IInvestorV1PoolState,
    IInvestorV1PoolDerivedState,
    IInvestorV1PoolActions,
    IInvestorV1PoolOperatorActions,
    IInvestorV1PoolEvents 
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolActions {
    function update() external returns (bool);
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount, address to) external returns (bool);
    function exit(uint256 amount, address to) external returns (bool);
    function claim(address to) external returns (bool);
    function restake(uint256 amount) external returns (bool);
    function unstake(uint256 amount, address to) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolDeployer {
    
    function parameter1()
        external
        view
        returns (
            address factory,
            address operator,
            string memory name,
            uint256 maxCapacity,
            uint256 minCapacity
        );

    function parameter2()
        external
        view
        returns (
            uint256 oraclePrice,
            uint256 startTime,
            uint256 stageTime,
            uint256 endTime,
            uint24 fee,
            uint24 interestRate
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolDerivedState {
    function expectedRestakeRevenue(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolEvents {
    event PoolOpened(address operator, uint256 startTime, uint256 tokenDeposit);
    event PoolActiviated(uint256 funded);
    event PoolLiquidated(uint256 liquidityFund);
    event PoolDishonored(uint256 requiredFund, uint256 liquidityFund);
    event PoolReverted(uint256 minCapacity, uint256 funded);

    event OraclePriceChanged(uint256 oraclePrice);
    event PoolDetailLinkChanged(string link);
    event ColletralHashChanged(string oldHash, string newHash);
    event ColletralLinkChanged(string oldLink, string newLink);

    event Deposit(address token, address from, uint256 amount);
    event Withdrawal(address token, address from, address to, uint256 amount);
    event Claim(address from, address to, uint256 amount);
    event Exited(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolImmutables {
    function factory() external view returns (address);
    function operator() external view returns (address);
    function name() external view returns (string memory);
    function maxCapacity() external view returns (uint256);
    function minCapacity() external view returns (uint256);
    function startTime() external view returns (uint256);
    function stageTime() external view returns (uint256);
    function endTime() external view returns (uint256);
    function fee() external view returns (uint24);
    function interestRate() external view returns (uint24);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolOperatorActions {
    function setOraclePrice(uint256 _oraclePrice) external returns (bool);
    function setColletralHash(string memory _newHash) external returns (bool);
    function setColletralLink(string memory _newLink) external returns (bool);
    function setPoolDetailLink(string memory _newLink) external returns (bool);
    function rescue(address target) external returns (bool);
    function pullDeposit() external returns (bool);
    function liquidate() external returns (bool);
    function openPool() external returns (bool);
    function closePool() external returns (bool);
    function revertPool() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolState {
    function funded() external view returns (uint256);
    function exited() external view returns (uint256);
    function restaked() external view returns (uint256);
    function oraclePrice() external view returns (uint256);
    function getPoolState() external view returns (string memory);
    function pooledAmt(address user) external view returns (uint256);
    function restakeAmt(address user) external view returns (uint256);
    function claimed(address user) external view returns (bool);
    function collateralDocument() external view returns (string memory);
    function detailLink() external view returns (string memory);
    function collateralHash() external view returns (string memory);
    function depositors() external view returns (uint256);
    function restakers() external view returns (uint256);
    function depositorList(uint256 index) external view returns (address);
    function restakerList(uint256 index) external view returns (address);
    function getInfo(address _account) external view returns (string memory, string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint24, uint24);
    function getExtra() external view returns (address, address, uint256, uint256, uint256, string memory, string memory, string memory);
}

