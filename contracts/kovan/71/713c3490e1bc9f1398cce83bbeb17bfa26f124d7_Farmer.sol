/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

contract ReentrancyGuard {
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

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _owner;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

interface ControlledToken is IERC20 {
    /// Controller is the only contract that can mint
    function mint(address _to, uint256 _amount) external returns (bool);
    function minter() external view returns (address);
    function taxSplit() external view returns (uint256);
    function devFund() external view returns (address);
    function stakePool() external view returns (address);
}

pragma solidity =0.6.6;

contract Farmer is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ControlledToken;
    using Address for address;
    
    // variables
    uint256 constant DIVISION_FACTOR = 100000;
    address public controlledTokenAddress;
    
    // Fee structure
    // Users must keep their tokens in the contract for a minimal vesting period to earn rewards
    // If the user exits the contract before the minimal vest, they are taxed the entire reward earned
    // If the exit before the maximum vest, they are taxed only a percentage of the reward earned
    // Each new deposit resets the vesting time, each withdraw has no effect on the vesting time
    uint256 minimalRewardVest = 86400; // Minimal length is 1 day
    uint256 vestingLength = 518400; // Vesting length is 6 days

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. The amount of rewards already given to depositer
        uint256 unclaimedReward; // Total reward potential
        uint256 depositTime; // Updates upon each new deposit
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 _token; // token contract.
        uint256 rewardRate; // The rate at which reward token is earned per second
        uint256 rewardPerTokenStored; // Reward per token stored which should gradually increase with time
        uint256 lastUpdateTime; // Time the pool was last updated
        uint256 totalSupply; // The total amount of tokens in the pool
        bool deactivated; // If deactivated, users cannot enter the pool
        uint256 poolID; // ID for the pool
        // Reward variables
        uint256 timeRewardEnds;
    }

    // Info of each pool.
    PoolInfo[] private totalPools;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;

    // Events
    event RewardAdded(uint256 pid, uint256 reward);
    event Deposited(uint256 pid, address indexed user, uint256 amount);
    event Withdrawn(uint256 pid, address indexed user, uint256 amount);
    event RewardPaid(uint256 pid, address indexed user, uint256 reward, uint256 fee);

    constructor(
        address _token
    ) public {
        controlledTokenAddress = _token;
    }
    
    // Modifiers
    
    modifier updateRewardEarned(uint256 _pid, address account) {
        totalPools[_pid].rewardPerTokenStored = rewardPerToken(_pid);
        totalPools[_pid].lastUpdateTime = lastTimeRewardApplicable(_pid);
        if (account != address(0)) {
            userInfo[_pid][account].unclaimedReward = rewardEarned(_pid,account);
            userInfo[_pid][account].rewardDebt = totalPools[_pid].rewardPerTokenStored;
        }
        _;
    }
    
    // Initialization functions
    
    function forceUpdateRewardEarned(uint256 _pid, address _address) internal updateRewardEarned(_pid, _address) {
        
    }
    
    function calculateUserFeePercent(uint256 _pid, address _address) public view returns (uint256) {
        // This returns the percentage of the user amount that will be taxed based on vesting
        if(now >= userInfo[_pid][_address].depositTime.add(minimalRewardVest).add(vestingLength)){
            return 0; // No fee for long vests
        }else if(now <= userInfo[_pid][_address].depositTime.add(minimalRewardVest)){
            return DIVISION_FACTOR; // Fee is complete
        }else{
            uint256 timeDiff = now.sub(userInfo[_pid][_address].depositTime.add(minimalRewardVest));
            uint256 feePercent = DIVISION_FACTOR.sub(timeDiff * DIVISION_FACTOR / vestingLength);
            return feePercent;
        }
    }
    
    function poolLength() public view returns (uint256) {
        return totalPools.length;
    }
    
    function lastTimeRewardApplicable(uint256 _pid) public view returns (uint256) {
        return block.timestamp < totalPools[_pid].timeRewardEnds ? block.timestamp : totalPools[_pid].timeRewardEnds;
    }
    
    function rewardRate(uint256 _pid) external view returns (uint256) {
        if(now < totalPools[_pid].timeRewardEnds){
            return totalPools[_pid].rewardRate;
        }else{
            // No more rewards
            return 0;
        }
    }
    
    function poolSize(uint256 _pid) external view returns (uint256) {
        return totalPools[_pid].totalSupply;
    }
    
    function poolBalance(uint256 _pid, address _address) external view returns (uint256) {
        return userInfo[_pid][_address].amount;
    }
    
    function poolTokenAddress(uint256 _pid) external view returns (address) {
        return address(totalPools[_pid]._token);
    }

    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        if (totalPools[_pid].totalSupply == 0) {
            return totalPools[_pid].rewardPerTokenStored;
        }
        return
            totalPools[_pid].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_pid)
                    .sub(totalPools[_pid].lastUpdateTime)
                    .mul(totalPools[_pid].rewardRate)
                    .mul(1e18)
                    .div(totalPools[_pid].totalSupply)
            );
    }

    function rewardEarned(uint256 _pid, address account) public view returns (uint256) {
        return
            userInfo[_pid][account].amount
                .mul(rewardPerToken(_pid).sub(userInfo[_pid][account].rewardDebt))
                .div(1e18)
                .add(userInfo[_pid][account].unclaimedReward);
    }

    function deposit(uint256 _pid, uint256 amount) public nonReentrant updateRewardEarned(_pid, _msgSender()) {
        require(amount > 0, "Cannot deposit 0");
        require(totalPools[_pid].deactivated == false, "This pool is no longer active");
        totalPools[_pid].totalSupply = totalPools[_pid].totalSupply.add(amount);
        userInfo[_pid][_msgSender()].amount = userInfo[_pid][_msgSender()].amount.add(amount);
        userInfo[_pid][_msgSender()].depositTime = now; // Resets the vest
        totalPools[_pid]._token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposited(_pid, _msgSender(), amount);
    }

    // User can withdraw without claiming reward tokens
    function withdraw(uint256 _pid, uint256 amount) public nonReentrant updateRewardEarned(_pid, _msgSender()) {
        require(amount > 0, "Cannot withdraw 0");
        totalPools[_pid].totalSupply = totalPools[_pid].totalSupply.sub(amount);
        userInfo[_pid][_msgSender()].amount = userInfo[_pid][_msgSender()].amount.sub(amount);
        totalPools[_pid]._token.safeTransfer(_msgSender(), amount);
        emit Withdrawn(_pid, _msgSender(), amount);
    }

    // Normally used to exit the contract and claim reward tokens
    function exit(uint256 _pid, uint256 _amount) external nonReentrant {
        withdraw(_pid, _amount);
        getReward(_pid);
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    function pushReward(uint256 _pid, address recipient) external updateRewardEarned(_pid, recipient) onlyGovernance {
        uint256 reward = rewardEarned(_pid,recipient);
        if (reward > 0) {
            userInfo[_pid][recipient].unclaimedReward = 0;
            // Calculate the fee
            uint256 fee = calculateUserFeePercent(_pid, recipient);
            require(fee == 0, "Cannot push rewards to someone who has a fee");
            fee = reward.mul(fee).div(DIVISION_FACTOR);
            emit RewardPaid(_pid, recipient, reward, fee);
            reward = reward.sub(fee);
            ControlledToken cToken = ControlledToken(controlledTokenAddress);
            cToken.mint(recipient, reward);
            if(fee > 0){
                uint256 split = cToken.taxSplit();
                address devAddress = cToken.devFund();
                address stakeAddress = cToken.stakePool();
                uint256 devFee = fee.mul(split).div(DIVISION_FACTOR);
                cToken.mint(devAddress, devFee);
                devFee = fee.sub(devFee);
                cToken.mint(stakeAddress, devFee);                
            }
        }
    }

    function getReward(uint256 _pid) public nonReentrant updateRewardEarned(_pid, _msgSender()) {
        uint256 reward = rewardEarned(_pid,_msgSender());
        if (reward > 0) {
            userInfo[_pid][_msgSender()].unclaimedReward = 0;
            // Calculate the fee
            uint256 fee = calculateUserFeePercent(_pid, _msgSender());
            fee = reward.mul(fee).div(DIVISION_FACTOR);
            emit RewardPaid(_pid, _msgSender(), reward, fee);
            reward = reward.sub(fee);
            ControlledToken cToken = ControlledToken(controlledTokenAddress);
            cToken.mint(_msgSender(), reward);
            if(fee > 0){
                uint256 split = cToken.taxSplit();
                address devAddress = cToken.devFund();
                address stakeAddress = cToken.stakePool();
                uint256 devFee = fee.mul(split).div(DIVISION_FACTOR);
                cToken.mint(devAddress, devFee);
                devFee = fee.sub(devFee);
                cToken.mint(stakeAddress, devFee);                
            }
        }
    }
    
    // Governance only functions
    
    // This function can be called by governance to reallocate pool funds for a specific duration
    // Set this reward amount to zero to stop the rewards
    function reallocatePool(uint256 _pid, uint256 rewardAmount, uint256 duration) external onlyGovernance {
        // First update the current rewards for the pool
        forceUpdateRewardEarned(_pid, address(0));
        totalPools[_pid].rewardRate = 0;
        
        // Next set the new reward rate
        totalPools[_pid].timeRewardEnds = now.add(duration);
        forceUpdateRewardEarned(_pid, address(0)); // Since we've updated the end of rewards, force another update
        uint256 newRate = rewardAmount.div(duration);
        totalPools[_pid].rewardRate = newRate;
        if(newRate == 0){
            totalPools[_pid].deactivated = true;
        }else{
            totalPools[_pid].deactivated = false;
            emit RewardAdded(_pid, rewardAmount);
        }
    }
    
    // Add a new token to the pool
    function addNewPool(address tokenAddress) public onlyGovernance {
        // This adds a new pool to the pool lists
        totalPools.push(
            PoolInfo({
                _token: IERC20(tokenAddress),
                poolID: poolLength(),
                rewardRate: 0,
                rewardPerTokenStored: 0,
                lastUpdateTime: 0,
                totalSupply: 0,
                deactivated: false,
                timeRewardEnds: 0
            })
        );
    }
    // --------------------
    
    // Timelock variables
    // Timelock doesn't activate until protocol has started to distribute rewards
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    uint256[2] private _timelock_data;
    address private _timelock_address;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        _;
    }
    
    // Change the governance
    // --------------------
    function startChangeGovernance(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishChangeGovernance() external onlyGovernance timelockConditionsMet(1) {
        _transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the vesting period
    // --------------------
    function startChangeVestingPeriods(uint256 minVest, uint256 vestLength) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_data[0] = minVest;
        _timelock_data[1] = vestLength;
    }
    
    function finishChangeVestingPeriods() external onlyGovernance timelockConditionsMet(2) {
        minimalRewardVest = _timelock_data[0];
        vestingLength = _timelock_data[1];
    }
    // --------------------
    
}