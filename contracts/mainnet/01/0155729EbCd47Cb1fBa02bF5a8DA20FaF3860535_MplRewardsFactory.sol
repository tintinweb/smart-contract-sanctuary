/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/MplRewardsFactory.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0;

////// contracts/interfaces/IERC2258.sol
/* pragma solidity 0.6.11; */

interface IERC2258 {

    // Increase the custody limit of a custodian either directly or via signed authorization
    function increaseCustodyAllowance(address custodian, uint256 amount) external;

    // Query individual custody limit and total custody limit across all custodians
    function custodyAllowance(address account, address custodian) external view returns (uint256);
    function totalCustodyAllowance(address account) external view returns (uint256);

    // Allows a custodian to exercise their right to transfer custodied tokens
    function transferByCustodian(address account, address receiver, uint256 amount) external;

    // Custody Events
    event CustodyTransfer(address custodian, address from, address to, uint256 amount);
    event CustodyAllowanceChanged(address account, address custodian, uint256 oldAllowance, uint256 newAllowance);

}

////// lib/openzeppelin-contracts/contracts/GSN/Context.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
/* pragma solidity >=0.6.0 <0.8.0; */

/* import "../GSN/Context.sol"; */
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

////// lib/openzeppelin-contracts/contracts/math/Math.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

////// lib/openzeppelin-contracts/contracts/math/SafeMath.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol
/* pragma solidity >=0.6.2 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol
/* pragma solidity >=0.6.0 <0.8.0; */

/* import "./IERC20.sol"; */
/* import "../../math/SafeMath.sol"; */
/* import "../../utils/Address.sol"; */

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

////// contracts/MplRewards.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/Math.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */
/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/* import "./interfaces/IERC2258.sol"; */

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
/// @title MplRewards Synthetix farming contract fork for liquidity mining.
contract MplRewards is Ownable {

    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    IERC20    public immutable rewardsToken;
    IERC2258  public immutable stakingToken;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public lastPauseTime;
    bool    public paused;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    event            RewardAdded(uint256 reward);
    event                 Staked(address indexed account, uint256 amount);
    event              Withdrawn(address indexed account, uint256 amount);
    event             RewardPaid(address indexed account, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event              Recovered(address token, uint256 amount);
    event           PauseChanged(bool isPaused);

    constructor(address _rewardsToken, address _stakingToken, address _owner) public {
        rewardsToken    = IERC20(_rewardsToken);
        stakingToken    = IERC2258(_stakingToken);
        rewardsDuration = 7 days;
        transferOwnership(_owner);
    }

    function _updateReward(address account) internal {
        uint256 _rewardPerTokenStored = rewardPerToken();
        rewardPerTokenStored          = _rewardPerTokenStored;
        lastUpdateTime                = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
    }

    function _notPaused() internal view {
        require(!paused, "R:PAUSED");
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        return _totalSupply == 0
            ? rewardPerTokenStored
            : rewardPerTokenStored.add(
                  lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
              );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /**
        @dev It emits a `Staked` event.
    */
    function stake(uint256 amount) external {
        _notPaused();
        _updateReward(msg.sender);
        uint256 newBalance = _balances[msg.sender].add(amount);
        require(amount > 0, "R:ZERO_STAKE");
        require(stakingToken.custodyAllowance(msg.sender, address(this)) >= newBalance, "R:INSUF_CUST_ALLOWANCE");
        _totalSupply          = _totalSupply.add(amount);
        _balances[msg.sender] = newBalance;
        emit Staked(msg.sender, amount);
    }

    /**
        @dev It emits a `Withdrawn` event.
    */
    function withdraw(uint256 amount) public {
        _notPaused();
        _updateReward(msg.sender);
        require(amount > 0, "R:ZERO_WITHDRAW");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.transferByCustodian(msg.sender, msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
        @dev It emits a `RewardPaid` event if any rewards are received.
    */
    function getReward() public {
        _notPaused();
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];

        if (reward == uint256(0)) return;

        rewards[msg.sender] = uint256(0);
        rewardsToken.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /**
        @dev Only the contract Owner may call this.
        @dev It emits a `RewardAdded` event.
    */
    function notifyRewardAmount(uint256 reward) external onlyOwner {
        _updateReward(address(0));

        uint256 _rewardRate = block.timestamp >= periodFinish
            ? reward.div(rewardsDuration)
            : reward.add(
                  periodFinish.sub(block.timestamp).mul(rewardRate)
              ).div(rewardsDuration);

        rewardRate = _rewardRate;

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(_rewardRate <= balance.div(rewardsDuration), "R:REWARD_TOO_HIGH");

        lastUpdateTime = block.timestamp;
        periodFinish   = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /**
        @dev End rewards emission earlier. Only the contract Owner may call this.
    */
    function updatePeriodFinish(uint256 timestamp) external onlyOwner {
        _updateReward(address(0));
        periodFinish = timestamp;
    }

    /**
        @dev Added to support recovering tokens unintentionally sent to this contract.
             Only the contract Owner may call this.
        @dev It emits a `Recovered` event.
    */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
        @dev Only the contract Owner may call this.
        @dev It emits a `RewardsDurationUpdated` event.
    */
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish, "R:PERIOD_NOT_FINISHED");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
        @dev Change the paused state of the contract. Only the contract Owner may call this.
        @dev It emits a `PauseChanged` event.
    */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        require(_paused != paused, "R:ALREADY_SET");

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (_paused) lastPauseTime = block.timestamp;

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

}

////// contracts/interfaces/IMapleGlobals.sol
/* pragma solidity 0.6.11; */

interface IMapleGlobals {

    function pendingGovernor() external view returns (address);

    function governor() external view returns (address);

    function globalAdmin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validCalcs(address) external view returns (bool);

    function isValidCalc(address, uint8) external view returns (bool);

    function getLpCooldownParams() external view returns (uint256, uint256);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns (uint256);

    function lpCooldownPeriod() external view returns (uint256);

    function stakerUnstakeWindow() external view returns (uint256);

    function lpWithdrawWindow() external view returns (uint256);

    function oracleFor(address) external view returns (address);

    function validSubFactories(address, address) external view returns (bool);

    function setStakerCooldownPeriod(uint256) external;

    function setLpCooldownPeriod(uint256) external;

    function setStakerUnstakeWindow(uint256) external;

    function setLpWithdrawWindow(uint256) external;

    function setMaxSwapSlippage(uint256) external;

    function setGlobalAdmin(address) external;

    function setValidBalancerPool(address, bool) external;

    function setProtocolPause(bool) external;

    function setValidPoolFactory(address, bool) external;

    function setValidLoanFactory(address, bool) external;

    function setValidSubFactory(address, address, bool) external;

    function setDefaultUniswapPath(address, address, address) external;

    function setPoolDelegateAllowlist(address, bool) external;

    function setCollateralAsset(address, bool) external;

    function setLiquidityAsset(address, bool) external;

    function setCalc(address, bool) external;

    function setInvestorFee(uint256) external;

    function setTreasuryFee(uint256) external;

    function setMapleTreasury(address) external;

    function setDefaultGracePeriod(uint256) external;

    function setMinLoanEquity(uint256) external;

    function setFundingPeriod(uint256) external;

    function setSwapOutRequired(uint256) external;

    function setPriceOracle(address, address) external;

    function setPendingGovernor(address) external;

    function acceptGovernor() external;

}

////// contracts/MplRewardsFactory.sol
/* pragma solidity 0.6.11; */

/* import "./interfaces/IMapleGlobals.sol"; */

/* import "./MplRewards.sol"; */

/// @title MplRewardsFactory instantiates MplRewards contracts.
contract MplRewardsFactory {

    IMapleGlobals public globals;  // Instance of MapleGlobals, used to retrieve the current Governor.

    mapping(address => bool) public isMplRewards;  // True only if an MplRewards was created by this factory.

    event MplRewardsCreated(address indexed rewardsToken, address indexed stakingToken, address indexed mplRewards, address owner);

    constructor(address _globals) public {
        globals = IMapleGlobals(_globals);
    }

    /**
        @dev   Updates the MapleGlobals instance. Only the Governor can call this function.
        @param _globals Address of new MapleGlobals contract.
    */
    function setGlobals(address _globals) external {
        require(msg.sender == globals.governor(), "RF:NOT_GOV");
        globals = IMapleGlobals(_globals);
    }

    /**
        @dev   Instantiates a MplRewards contract. Only the Governor can call this function.
        @dev   It emits a `MplRewardsCreated` event.
        @param rewardsToken Address of the rewards token (will always be MPL).
        @param stakingToken Address of the staking token (token used to stake to earn rewards).
                            (i.e., Pool address for PoolFDT mining, StakeLocker address for staked BPT mining.)
        @return mplRewards  Address of the instantiated MplRewards.
    */
    function createMplRewards(address rewardsToken, address stakingToken) external returns (address mplRewards) {
        require(msg.sender == globals.governor(), "RF:NOT_GOV");
        mplRewards               = address(new MplRewards(rewardsToken, stakingToken, msg.sender));
        isMplRewards[mplRewards] = true;

        emit MplRewardsCreated(rewardsToken, stakingToken, mplRewards, msg.sender);
    }

}