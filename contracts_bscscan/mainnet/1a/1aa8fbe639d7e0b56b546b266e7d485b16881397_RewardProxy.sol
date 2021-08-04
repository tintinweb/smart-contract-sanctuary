/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
/*
 *       $$$$$$_$$__$$__$$$$__$$$$$$
 *       ____$$_$$__$$_$$_______$$
 *       ____$$_$$__$$__$$$$____$$
 *       $$__$$_$$__$$_____$$___$$
 *       _$$$$___$$$$___$$$$____$$
 *
 *       $$__$$_$$$$$$_$$$$$__$$_____$$$$$
 *       _$$$$____$$___$$_____$$_____$$__$$
 *       __$$_____$$___$$$$___$$_____$$__$$
 *       __$$_____$$___$$_____$$_____$$__$$
 *       __$$___$$$$$$_$$$$$__$$$$$$_$$$$$
 *
 *       $$___$_$$$$$$_$$$$$$_$$__$$
 *       $$___$___$$_____$$___$$__$$
 *       $$_$_$___$$_____$$___$$$$$$
 *       $$$$$$___$$_____$$___$$__$$
 *       _$$_$$_$$$$$$___$$___$$__$$
 *
 *       $$__$$_$$$$$__$$
 *       _$$$$__$$_____$$
 *       __$$___$$$$___$$
 *       __$$___$$_____$$
 *       __$$___$$$$$__$$$$$$
 */


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
contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {

            require(newOwner != address(0) || renounce, "Ownable: zero address");

            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            pendingOwner = newOwner;
        }
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }
}

contract StorageBuffer {

    // Reserved storage space to allow for layout changes in the future.
    uint256[20] private _gap;

    function getStore(uint a) internal view returns(uint) {
        require(a < 20, "Not allowed");
        return _gap[a];
    }

    function setStore(uint a, uint val) internal {
        require(a < 20, "Not allowed");
        _gap[a] = val;
    }
}

// This contract is dedicated to process LP tokens of the users. More precisely, this allows to track how much tokens
// the user has deposited and indicate how much he is eligible to withdraw 
abstract contract LPTokenWrapper is StorageBuffer {
    using SafeERC20 for IERC20;

    IERC20 public immutable yel; // Address of YEL token
    IERC20 public immutable lpToken; // Address of LP token
    uint256 private _totalSupply; // Amount of Lp tokens deposited
    mapping(address => uint256) private _balances; // A place where user token balance is stored

    constructor(address _yel, address _lpToken) {
        require(_yel != address(0) && _lpToken != address(0), "NULL_ADDRESS");
        yel = IERC20(_yel);
        lpToken = IERC20(_lpToken);
    }

    // Function modifier that calls update reward function
    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }
    
    // View function that provides tptal supply for the front end 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    // View function that provides the LP balance of a user
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    // Fuction that is responsible for the recival of  LP tokens of the user and the update of the user balance 
    function stake(uint256 amount) virtual public {
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }
    
    // Function that is reponsible for releasing LP tokens to the user and for the update of the user balance 
    function withdraw(uint256 amount) virtual public {
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        lpToken.safeTransfer(msg.sender, amount);
    }

    //Interface 
    function _updateReward(address account) virtual internal;
}


// Implemented to call functions of masterApe
interface IMasterApe {
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function pendingCake(uint256 pid, address user) external view returns(uint);
}

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
}


/**
 * This contract is responsible for forwarding LP tokens to Masterape contract.
 * It calculates YEL rewards and distrubutes both YEL and Banana
 */
contract RewardProxy is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Immutable Address of Banana token
    IERC20 public immutable banana;
    // Immutable masterape contract address
    IMasterApe public immutable masterApe;
    uint256 public immutable pid; // banana pool id

    // Reward rate - This is done to set YEL reward rate proportion.
    uint256 public rewardRate = 2000000;
    uint256 public SECONDS_IN_A_DAY = 86400;
    // Custom divisioner that is implemented in order to give
    // the ability to alter rate reward according to the project needs
    uint256 public constant DIVISIONER = 10 ** 6;

    // Set of variables that is storing user Banana rewards
    uint256 public bananaPerTokenStored;
    
    uint256 claimingStart;
    // totalLpInPool is a value that shows how much LPs have passed through the contract
    // (not how much in total on ApeMasterchef)
    uint256 public totalLpInPool;

    mapping(address => uint256) private _lastClaim;
    // Info of each user.
    struct UserInfo {
        uint256 remainingYelTokenReward; // Remaining Token amount that is owned to the user.
        uint256 bananaPerTokenPaid;
        uint256 bananaRewards;
    }
    
    // Info of each user that stakes YEL tokens.
    mapping(address => UserInfo) public userInfo;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event BananaPaid(address indexed user, uint256 reward);

    constructor(
        address _yel,
        address _banana,
        address _lpToken,
        address _masterApe,
        uint256 _pid
    )
        LPTokenWrapper(_yel, _lpToken)
    {
        require(
           _banana != address(0) && _masterApe != address(0),
           "banana and master ape addresses can not be zero addresses"
        );
        banana = IERC20(_banana);
        masterApe = IMasterApe(_masterApe);
        pid = _pid;
        claimingStart = block.timestamp;
    }

    function lastClaim(address sender) public view returns (uint256) {
        return uint256(_lastClaim[sender]) != 0 ? uint256(_lastClaim[sender]) : claimingStart;
    }

    /*
    stake visibility is public as overriding LPTokenWrapper's stake() function
    Recieves users LP tokens and deposits them to MasterApe contract
    */
    function stake(uint256 amount) override public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        lpToken.approve(address(masterApe), amount);
        masterApe.deposit(pid, amount);
        totalLpInPool = totalLpInPool.add(amount);
        emit Staked(msg.sender, amount);
    }

    // Recieves Lp tokens from Masterape and give it out to the user
    // all funds should 
    function withdraw(uint256 amount) override public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        address sender = msg.sender;
        masterApe.withdraw(pid, amount); // harvests banana
        super.withdraw(amount);

        uint256 lastClaimed = lastClaim(sender);
        // how much yel accrued in a sec
        uint256 yelAccruedInSec = (yel.balanceOf(sender)).div(totalLpInPool);
        // yel accumulated from the last claimed period
        uint256 totalAccumulated = (block.timestamp).sub(lastClaimed).mul(yelAccruedInSec).div(SECONDS_IN_A_DAY);
        yel.transfer(sender, totalAccumulated);
        if (totalAccumulated != 0) {
            _lastClaim[sender] = block.timestamp;
        }
        emit Withdrawn(sender, amount);
    }

    // "Go home" function which withdraws all Funds and distributes all rewards to the user
    function exit() external {
        require(msg.sender != address(0));

        UserInfo storage user = userInfo[msg.sender];
        uint _then = banana.balanceOf(address(this));
        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "Cannot withdraw 0");

        masterApe.withdraw(pid, amount); // harvests banana
        bananaPerTokenStored = _bananaPerToken(banana.balanceOf(address(this)) - _then);

        user.bananaRewards = _bananaEarned(msg.sender, bananaPerTokenStored);
        user.bananaPerTokenPaid = bananaPerTokenStored;
        
        super.withdraw(amount); // lp tokens transfer to the msg.sender
        emit Withdrawn(msg.sender, amount);
        
        uint256 reward = user.bananaRewards;
        if (reward > 0) {
            user.bananaRewards = 0;
            banana.safeTransfer(msg.sender, reward); // banana rewards transfer to the msg.sender
            emit BananaPaid(msg.sender, reward);
        }
        reward = reward * rewardRate / DIVISIONER + user.remainingYelTokenReward;
        if (reward > 0)
        {
            // yel safe distribution to the msg.sender
            user.remainingYelTokenReward = safeRewardTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // View function which shows user YEL reward for displayment on frontend
    function earned(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];
        return _bananaEarned(account, bananaPerToken()) * rewardRate / DIVISIONER + user.remainingYelTokenReward;
    }

    // View function which shows user Banana reward for displayment on frontend
    function bananaEarned(address account) public view returns (uint256) {
        return _bananaEarned(account, bananaPerToken());
    }

    // View function which shows banana rewards amount of our Pool 
    function bananaPerToken() public view returns (uint256) {
        return _bananaPerToken(masterApe.pendingCake(pid, address(this)));
    }

    // Harvests banana rewards to the user but leaves the Lp tokens deposited
    function getReward() public updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];
        uint256 reward = user.bananaRewards;
        if (reward > 0) {
            user.bananaRewards = 0;
            banana.safeTransfer(msg.sender, reward);
            emit BananaPaid(msg.sender, reward);
        }
        reward = reward * rewardRate / DIVISIONER + user.remainingYelTokenReward;
        if (reward > 0)
        {
            user.remainingYelTokenReward = safeRewardTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Changes rewards rate of YEL token
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    // Calculates how much banana is provied per LP token 
    function _bananaPerToken(uint earned_) internal view returns (uint256) {
        uint _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            return bananaPerTokenStored + earned_ * 1e18 / _totalSupply;
        }
        return bananaPerTokenStored;
    }

    // Function which tracks rewards of a user and harvests all banana rewards from Masterape
    function _updateReward(address account) override internal {
        UserInfo storage user = userInfo[msg.sender];
        uint _then = banana.balanceOf(address(this));
        // TODO: suspicious variable, should fail in the masterApe contract 
        masterApe.withdraw(pid, 0); // harvests banana
        bananaPerTokenStored = _bananaPerToken(banana.balanceOf(address(this)) - _then);

        if (account != address(0)) {
            user.bananaRewards = _bananaEarned(account, bananaPerTokenStored);
            user.bananaPerTokenPaid = bananaPerTokenStored;
        }
    }

    // Calculates how much banana is entitled for a particular user
    function _bananaEarned(address account, uint256 bananaPerToken_) internal view returns (uint256) {
        UserInfo memory user = userInfo[account];
        return
            balanceOf(account) * (bananaPerToken_ - user.bananaPerTokenPaid) / 1e18 + user.bananaRewards;
    }
    
    // Safe token distribution
    function safeRewardTransfer(address _to, uint256 _amount) internal returns(uint256) {
        uint256 rewardTokenBalance = yel.balanceOf(address(this));
        if (rewardTokenBalance == 0) { //save some gas fee
            return _amount;
        }
        if (_amount > rewardTokenBalance) { //save some gas fee
            yel.transfer(_to, rewardTokenBalance);
            return _amount - rewardTokenBalance;
        }
        yel.transfer(_to, _amount);
        return 0;
    }
}