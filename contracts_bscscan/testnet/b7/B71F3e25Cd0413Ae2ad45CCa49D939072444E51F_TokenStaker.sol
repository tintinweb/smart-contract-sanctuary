// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// Part: Minter

interface Minter {
    function mint(address _receiver, uint256 _amount) external;
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: OpenZeppelin/[email protected]/Ownable

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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// File: TokenStaker.sol
contract TokenStaker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 userId;
        uint256 amount;
        uint256 rewardEarned;
        uint256 depositTime;
    }

    /* 
    Info of pool:
    stakeToken: The address of Stake token contract.
    periodRewardTokenCount: number of reward tokens per reward period
    lastMassUpdate: last calculation of rewards for all the users
    poolTotalSupply: the total number of staked tokens in the contract
    poolTotalRewardDebt: the total reward debt to the stakers
    */ 
    struct PoolInfo {
        IERC20 stakeToken;
        uint256 periodRewardTokenCount;
        uint256 lastMassUpdate;
        uint256 poolTotalSupply;
        uint256 poolTotalRewardDebt; 
    }

    //uint constant rewardDuration = 86400; // 24 * 60 * 60 in second
    uint constant rewardDuration = 60; // Every 60 seconds
    uint private calculationFactor = 10**5;
    uint private minimumBalance = 10**5;
    string constant public lockPeriod = '30 Min';  // locked period in text to be shown by the GUI
    uint256 private contractLockPeriod = 1800; // 30 min for test,  in real second = 60*60*24*30*3
    address private poolUnusedRewardAddress; // address for withdrawal of the unused rewards
    uint256 private poolLostRewardTotalAmount; // Keeps track of the lost reward due to early withdrawal

    // Info of pool.
    PoolInfo public poolInfo;

    // Info of each user that stakes Stake tokens.
    uint256 private userCount = 0;
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => address) private userMapping;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount
    );

    constructor(
        IERC20 _stakeToken,
        uint256 _periodRewardTokenCount
    ) {
        /*
        @dev - single pool staking contract
        */ 
        poolInfo.stakeToken = _stakeToken;
        poolInfo.periodRewardTokenCount = _periodRewardTokenCount;
        poolInfo.lastMassUpdate = block.timestamp;
        poolInfo.poolTotalRewardDebt = 0;
        poolInfo.poolTotalSupply = 0;
    }

    /*
    * Pool daily rewards token count
    */
    function getPeriodRewardTokenCount() public view onlyOwner returns(uint256) {
        return poolInfo.periodRewardTokenCount;
    }

    /*
    * pool address to withdraw unused rewards
    */
    function getpoolUnusedRewardAddress() public view onlyOwner returns(address) {
        return poolUnusedRewardAddress;
    }

    /*
    * set wallet address to withdraw unused rewards
    */
    function setpoolUnusedRewardAddress(address _poolUnusedRewardAddress) public onlyOwner {
        poolUnusedRewardAddress = _poolUnusedRewardAddress;
    }

    /*
    * returns total number of staked token
    */
    function getPoolTotalStakedSupply() public view returns(uint256) {
        return poolInfo.poolTotalSupply;
    }

    /*
    * returns total number of reward token
    */
    function getPoolTotalRewardSupply() public view returns(uint256) {
        return poolInfo.stakeToken.balanceOf(address(this)).sub(poolInfo.poolTotalSupply);
    }

    /*
    * returns rewards lost due to early withdrawal
    */
    function getPoolTotalLostRewardAmount() public view onlyOwner returns(uint256) {
        return poolLostRewardTotalAmount;
    }

    /*
    * set number of reward token for one reward period
    */
    function setPoolRewardTokenCount(uint256 _rewardTokenCount) public onlyOwner {
        poolInfo.periodRewardTokenCount = _rewardTokenCount;
    }
    
    /*
    * returns the calculation factor
    */
    function getCalculationFactor() public view onlyOwner returns(uint) {
        return calculationFactor;
    }

    /*
    * sets the calculation factor
    */
    function setCalculationFactor(uint _calculationFactor) public onlyOwner {
        calculationFactor = _calculationFactor;
    }

    // Release Reward Token Count in the Contract!
    function releaseReward(uint256 _amount) public onlyOwner {
        require(_amount > 0,'releaseReward: invalid amount!');
        PoolInfo storage pool = poolInfo;
        uint256 totalRewardAmount = poolInfo.stakeToken.balanceOf(address(this)).sub(poolInfo.poolTotalSupply);
        require(_amount <= totalRewardAmount, "releaseReward: insufficient reward token!");
        pool.stakeToken.safeTransfer(poolUnusedRewardAddress, _amount);        
    }

    /*
    * Returns the remaining lock period for a user
    */
    function remainLockTime(address _user) 
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 timeElapsed = block.timestamp.sub(user.depositTime);
        uint256 remainingLockTime = 0;
        if (user.depositTime == 0) {
            remainingLockTime = 0;
        } else if(timeElapsed < contractLockPeriod) {
            remainingLockTime = contractLockPeriod.sub(timeElapsed);
        }

        return remainingLockTime;
    }

    /*
    * The mass update calculates the earned rewards for all the user until the current timestamp and 
    * stores the results in the userInfo.
    * This is necessary on any change to any user blance i.e. (deposite, withdrawal, emergencyWithdraw)
    * Also needed on claim as the userInfo needs to be updated. 
    */
    function _MassUpdate() internal {
        PoolInfo storage pool = poolInfo; 
        uint256 _updateTime = block.timestamp;
        uint256 reward;
        uint256 poolTotalRewardDebt = 0;
        // Do not calculte before reward durarion
        if (_updateTime.sub(pool.lastMassUpdate) >= rewardDuration) {
            for (uint256 i = 1; i <= userCount; i++) {
                reward = claimableReward(userMapping[i], _updateTime);
                UserInfo storage user = userInfo[userMapping[i]];
                user.rewardEarned = user.rewardEarned.add(reward);
                poolTotalRewardDebt = poolTotalRewardDebt.add(user.rewardEarned);
            }
            pool.lastMassUpdate = _updateTime;
            pool.poolTotalRewardDebt = poolTotalRewardDebt;
        }
    }

    /*
    * View function to see pending reward tokens on frontend.
    */
    function claimableReward(address _user, uint256 _calculationTime)
        public
        view
        returns (uint256)
    {
        // update all user reward and save 
        PoolInfo storage pool = poolInfo; 
        UserInfo storage user = userInfo[_user];
        
        uint256 totalSupply = pool.poolTotalSupply;
        uint256 duration;
        uint durationCount;
        uint256 rewardTokenCount;
        if (_calculationTime == 0) {
            _calculationTime = block.timestamp;
        }
        
        if (_calculationTime > pool.lastMassUpdate && totalSupply > 0) {
            duration = _calculationTime.sub(pool.lastMassUpdate);
            durationCount = duration.div(rewardDuration); 
            rewardTokenCount = durationCount.mul(pool.periodRewardTokenCount); 
        }

        uint userPercent = 0;
        if (totalSupply != 0) {
            userPercent = user.amount.mul(calculationFactor).div(totalSupply);
        }

        uint256 userReward = userPercent.mul(rewardTokenCount).div(calculationFactor);

        return userReward;
    }

    /*
    * Deposit tokens into the contract.
    * Also triggers a MassUpdate to ensure correct calculation of earned rewards.
    * Important! Make sure to pass amount in wei  (10**18)
    */
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo; 
        UserInfo storage user = userInfo[msg.sender];

        _MassUpdate(); // Update and store the earned reward before a new deposit

        user.rewardEarned = user.rewardEarned.add(claimableReward(msg.sender, 0));
        
        // reset user deposit time if the balance less than the minimumBalance
        if (user.amount <= minimumBalance) { 
            user.depositTime = block.timestamp;
        }

        pool.stakeToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);

        // if new user, increase user count
        if (user.userId == 0) {
            userCount = userCount.add(1);
            user.userId = userCount;
            userMapping[userCount] = msg.sender;
        }
        pool.poolTotalSupply = pool.poolTotalSupply.add(_amount);

        emit Deposit(msg.sender, _amount);
    }

    /*
    * Withdraws staked tokens if the locked period has passed.
    * If locked period is not passed, this function fail. 
    * To withdraw before locked period is finished, call emergencyWithdraw()
    * Also triggers a MassUpdate to ensure correct calculation of earned rewards.
    * Important! Make sure to pass amount in wei  (10**18)
    */
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        uint256 remainLock = remainLockTime(msg.sender);

        require(user.amount >= _amount, "withdraw: the requested amount exceeds the balance!");
        require(remainLock <= 0, "withdraw: locktime remains!");

        _MassUpdate();
        user.rewardEarned = user.rewardEarned.add(claimableReward(msg.sender, 0));
        user.amount = user.amount.sub(_amount);

        pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        pool.poolTotalSupply = pool.poolTotalSupply.sub(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    /*
    * Withdraw the staked token before the lock period is finished.
    * User rewards will be losed.
    * To keep track of amount of lost rewards, the amount is stored in poolLostRewardTotalAmount
    */
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo; 
        UserInfo storage user = userInfo[msg.sender];
        
        // calculates the reward the user have earned so far
        _MassUpdate();
        user.rewardEarned = user.rewardEarned.add(claimableReward(msg.sender, 0));
    
        // retuns the staked tokens to the user
        pool.stakeToken.safeTransfer(address(msg.sender), user.amount);
        pool.poolTotalSupply = pool.poolTotalSupply.sub(user.amount);

        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;

        // update reward information
        pool.poolTotalRewardDebt = pool.poolTotalRewardDebt.sub(user.rewardEarned);
        poolLostRewardTotalAmount = poolLostRewardTotalAmount.add(user.rewardEarned); 
        user.rewardEarned = 0;
    }

    /*
    * returns the pending rewards for the user.
    */
    function claim() external {
        uint256 remainLock = remainLockTime(msg.sender);
        PoolInfo storage pool = poolInfo;
        require(remainLock <= 0, "claim: locktime remain");

        // update user rewards
        UserInfo storage user = userInfo[msg.sender];
        _MassUpdate();

        // make sure there is enough reward token in the contarct
        uint256 poolRewardTokenSupply = poolInfo.stakeToken.balanceOf(address(this)).sub(poolInfo.poolTotalSupply);
        require(user.rewardEarned < poolRewardTokenSupply, 'claim: Insufficient reward token in the contract');
        
        // transfer the reward
        if (user.rewardEarned > 0) {
            poolInfo.stakeToken.safeTransfer(msg.sender, user.rewardEarned);
            pool.poolTotalRewardDebt = pool.poolTotalRewardDebt.sub(user.rewardEarned);
        }
        user.rewardEarned = 0;
    }

}