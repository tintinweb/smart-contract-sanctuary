/**
 *Submitted for verification at snowtrace.io on 2022-01-03
*/

// File: bao/IJoeChef.sol


pragma solidity ^0.8.0;

interface IJoeChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingTokens(uint256 _pid, address _user) external view returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 pid) external view returns (
            address lpToken,
            uint256 accJoePerShare,
            uint256 lastRewardTimestamp,
            uint256 allocPoint,
            address rewarder
        );
}

// File: bao/IMiniChef.sol


pragma solidity ^0.8.0;

interface IMiniChef {
    function userInfo(uint pid, address user) external view returns (
        uint256 amount,
        uint256 rewardDebt
    );

    function poolInfo(uint pid) external view returns (
        uint allocPoint,
        uint lastRewardTime,
        uint accRewardPerShare
    );

    function rewarder(uint pid) external view returns (address);
    function lpToken(uint pid) external view returns (address);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}
// File: bao/IStakingRewards.sol



pragma solidity ^0.8.0;

interface IStakingRewards {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function stake(uint256 amount) external;
    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
// File: bao/Context.sol



pragma solidity ^0.8.0;

/**
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

// File: bao/Ownable.sol



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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // constructor () internal {
    constructor () {
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
     * @dev Returns the address of the previous owner.
     */
    function previousOwner() public view returns (address) {
        return _previousOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyPreviousOwner() {
        require(_previousOwner == _msgSender(), "Ownable: caller is not the previous owner");
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
    
    function reclaimOwnership(address newOwner) public virtual onlyPreviousOwner {
        require(newOwner == _previousOwner, "Ownable: new owner must be previous owner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}
contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: bao/BavaMasterFarmerV2.sol



pragma solidity ^0.8.0;







interface IBavaToken {
    function transfer(address to, uint tokens) external returns (bool success);

    function mint(address to, uint tokens) external;

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function cap() external view returns (uint capSuppply);

    function totalSupply() external view returns (uint _totalSupply);

    function lock(address _holder, uint256 _amount) external;
}

// BavaMasterFarmer is the master of Bava. He can make Bava and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Bava is sufficiently
// distributed and the community can show to govern itself.
//
contract BavaMasterFarmerV2 is Ownable, Authorizable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many LP tokens the user has provided.
        uint256 rewardDebt;         // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock;  // the last block user stake
		uint256 lastWithdrawBlock;  // the last block a user withdrew at.
		uint256 firstDepositBlock;  // the first block a user deposited at.
		uint256 blockdelta;         // time passed since withdrawals
		uint256 lastDepositBlock;   // the last block a user deposited at.
        
        // We do some fancy math here. Basically, any point in time, the amount of Bavas
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBavaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBavaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. Bavas to distribute per block.
        uint256 lastRewardBlock;    // Last block number that Bavas distribution occurs.
        uint256 accBavaPerShare;    // Accumulated Bavas per share, times 1e12. See below.
        uint256 depositAmount;      // Total deposit amount
        uint256 receiptAmount;      // Restaking borrow amount
        bool deposits_enabled;
    }

    // Info of each pool 3rd party restaking farm 
    struct PoolRestakingInfo {
        IMiniChef pglStakingContract;           // Panglin LP Staking contract
        IStakingRewards pglSPStakingContract;   // Panglin SP Staking contract
        IJoeChef joeStakingContract;            // TraderJoe LP Staking contract
        uint256 restakingFarmID;                // RestakingFarm ID
        uint256 numberOfPair;                   // Single or Double pair 0 represent LP pair, 1 reprsent SP pair
        IERC20 reward;                          // reward token from 3rd party restaking
        uint256 rewardAmount;                   // reward token amount
        IERC20 reward1;                         // reward1 token from 3rd party restaking
        uint256 reward1Amount;                  // reward1 token amount
    }

    // The Bava TOKEN!
    IBavaToken public Bava;
    //An ETH/USDC Oracle (Chainlink)
    address public usdOracle;
    // Developer/Employee address.
    address public devaddr;
	// Future Treasury address
	address public futureTreasuryaddr;
	// Advisor Address
	address public advisoraddr;
	// Founder Reward
	address public founderaddr;
    // Bava tokens created per block.
    uint256 public REWARD_PER_BLOCK;
    // Bonus muliplier for early Bava makers.
    uint256[] public REWARD_MULTIPLIER;
    uint256[] public HALVING_AT_BLOCK; // init in constructor function
    uint256[] public blockDeltaStartStage;
    uint256[] public blockDeltaEndStage;
    uint256[] public userFeeStage;
    uint256[] public devFeeStage;
    uint256 public FINISH_BONUS_AT_BLOCK;
    uint256 public userDepFee;
    uint256 public devDepFee;
    uint256 constant internal MAX_UINT = type(uint256).max;

    // The block number when Bava mining starts.
    uint256 public START_BLOCK;

    uint256 public PERCENT_LOCK_BONUS_REWARD;   // lock xx% of bounus reward in 3 year
    uint256 public PERCENT_FOR_DEV;             // Dev bounties + Employees
	uint256 public PERCENT_FOR_FT;              // Future Treasury fund
	uint256 public PERCENT_FOR_ADR;             // Advisor fund
	uint256 public PERCENT_FOR_FOUNDERS;        // founders fund

    PoolInfo[] public poolInfo;                                             // Info of each pool.
    PoolRestakingInfo[] public poolRestakingInfo;
    mapping(address => uint256) public poolId1;                             // poolId1 count from 1, subtraction 1 before using with poolInfo
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;     // Info of each user that stakes LP tokens. pid => user address => info
    uint256 public totalAllocPoint = 0;                                     // Total allocation points. Must be the sum of all allocation points in all pools.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 devAmount);
    event SendBavaReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);
    event DepositsEnabled(uint pid, bool newValue);

    constructor(
        IBavaToken _IBava,
        address _devaddr,
		address _futureTreasuryaddr,
		address _advisoraddr,
		address _founderaddr,
        uint256 _userDepFee,
        uint256 _devDepFee,
        uint256[] memory _blockDeltaStartStage,
        uint256[] memory _blockDeltaEndStage,
        uint256[] memory _userFeeStage,
        uint256[] memory _devFeeStage
    ) {
        Bava = _IBava;
        devaddr = _devaddr;
		futureTreasuryaddr = _futureTreasuryaddr;
		advisoraddr = _advisoraddr;
		founderaddr = _founderaddr;
	    userDepFee = _userDepFee;
	    devDepFee = _devDepFee;
	    blockDeltaStartStage = _blockDeltaStartStage;
	    blockDeltaEndStage = _blockDeltaEndStage;
	    userFeeStage = _userFeeStage;
	    devFeeStage = _devFeeStage;        
    }

    function initPool(uint256 _rewardPerBlock, uint256 _startBlock,uint256 _halvingAfterBlock) external onlyOwner {
        REWARD_PER_BLOCK = _rewardPerBlock;
        START_BLOCK = _startBlock;
        for (uint256 i = 0; i < REWARD_MULTIPLIER.length - 1; i++) {
            uint256 halvingAtBlock = _halvingAfterBlock*(i + 1)+(_startBlock);
            HALVING_AT_BLOCK.push(halvingAtBlock);
        }
        FINISH_BONUS_AT_BLOCK = _halvingAfterBlock*(REWARD_MULTIPLIER.length - 1)+(_startBlock);
        HALVING_AT_BLOCK.push(type(uint256).max);
    }  

    // Add a new lp to the pool. Can only be called by the owner. Support LP from panglolin miniChef, PNG single assest staking contract and traderJOe masterChef
    function add(uint256 _allocPoint, IERC20 _lpToken, IMiniChef _stakingPglContract, IJoeChef _stakingJoeContract, uint256 _restakingFarmID, uint256 _numberOfPair, IERC20 _reward, IERC20 _reward1, bool _withUpdate) external onlyOwner {        
        require(poolId1[address(_lpToken)] == 0, "lp is in pool");
        require(_numberOfPair == 0 || _numberOfPair == 1, "no != 0/1");
        require(address(_stakingPglContract) == address(0) || address(_stakingJoeContract) == address(0), "Both add != 0");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > START_BLOCK ? block.number : START_BLOCK;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolId1[address(_lpToken)] = poolInfo.length + 1;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBavaPerShare: 0,
            depositAmount: 0,
            receiptAmount: 0,
            deposits_enabled: true
        }));
        poolRestakingInfo.push(PoolRestakingInfo({
            pglStakingContract: _stakingPglContract,
            pglSPStakingContract: IStakingRewards(address(_stakingPglContract)),
            joeStakingContract: _stakingJoeContract,
            restakingFarmID: _restakingFarmID,
            numberOfPair: _numberOfPair,
            reward: _reward,  
            rewardAmount: 0,
            reward1: _reward1,
            reward1Amount: 0
        }));
    }

    /**
     * @notice Approve tokens for use in Strategy, Restricted to avoid griefing attacks
     */
    function setAllowances(uint256 _pid, uint256 _amount) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];        
        if (address(poolRestaking.pglStakingContract) != address(0)) {
            pool.lpToken.approve(address(poolRestaking.pglStakingContract), _amount);
        }
        if (address(poolRestaking.joeStakingContract) != address(0)) {
            pool.lpToken.approve(address(poolRestaking.joeStakingContract), _amount);
        }
    }

    // Update the given pool's Bava allocation point. Can only be called by the owner.
    function set(uint256 _pid, IERC20 _lpToken, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint-(poolInfo[_pid].allocPoint)+(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lpToken = _lpToken;
    }

    // Update the given pool's Bava restaking contract. Can only be called by the owner.
    function setPoolRestakingInfo(uint256 _pid, IMiniChef _stakingPglContract, IJoeChef _stakingJoeContract, uint256 _restakingFarmID, uint256 _numberOfPair, IERC20 _reward, IERC20 _reward1, bool _withUpdate) external onlyOwner {
        require(address(_stakingPglContract) == address(0) || address(_stakingJoeContract) == address(0), "Both add != 0");        
        if (_withUpdate) {
            massUpdatePools();
        }
        poolRestakingInfo[_pid].pglStakingContract = _stakingPglContract;
        poolRestakingInfo[_pid].pglSPStakingContract = IStakingRewards(address(_stakingPglContract));
        poolRestakingInfo[_pid].joeStakingContract = _stakingJoeContract;
        poolRestakingInfo[_pid].restakingFarmID = _restakingFarmID;
        poolRestakingInfo[_pid].numberOfPair = _numberOfPair;
        poolRestakingInfo[_pid].reward = _reward;
        poolRestakingInfo[_pid].reward1 = _reward1;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.receiptAmount;
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 BavaForDev;
        uint256 BavaForFarmer;
		uint256 BavaForFT;
		uint256 BavaForAdr;
		uint256 BavaForFounders;
        (BavaForDev, BavaForFarmer, BavaForFT, BavaForAdr, BavaForFounders) = getPoolReward(pool.lastRewardBlock, block.number, pool.allocPoint);
        Bava.mint(address(this), BavaForFarmer);
        pool.accBavaPerShare = pool.accBavaPerShare+(BavaForFarmer*(1e12)/(lpSupply));
        pool.lastRewardBlock = block.number;
        if (BavaForDev > 0) {
            Bava.mint(address(devaddr), BavaForDev);
            //Dev fund has xx% locked during the starting bonus period. After which locked funds drip out linearly each block over 3 years.
            Bava.lock(address(devaddr), BavaForDev*(75)/(100));            
        }
		if (BavaForFT > 0) {
            Bava.mint(futureTreasuryaddr, BavaForFT);
			//FT + Partnership fund has only xx% locked over time as most of it is needed early on for incentives and listings. The locked amount will drip out linearly each block after the bonus period.
            Bava.lock(address(futureTreasuryaddr), BavaForFT*(45)/(100));            
        }
		if (BavaForAdr > 0) {
            Bava.mint(advisoraddr, BavaForAdr);
			//Advisor Fund has xx% locked during bonus period and then drips out linearly over 3 years.
            Bava.lock(address(advisoraddr), BavaForAdr*(85)/(100));
        }
		if (BavaForFounders > 0) {
            Bava.mint(founderaddr, BavaForFounders);
			//The Founders reward has xx% of their funds locked during the bonus period which then drip out linearly per block over 3 years.
            Bava.lock(address(founderaddr), BavaForFounders*(95)/(100));
        }
    }

    // |--------------------------------------|
    // [20, 30, 40, 50, 60, 70, 80, 99999999]
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < START_BLOCK) return 0;

        for (uint256 i = 0; i < HALVING_AT_BLOCK.length; i++) {
            uint256 endBlock = HALVING_AT_BLOCK[i];

            if (_to <= endBlock) {
                uint256 m = (_to-_from)*(REWARD_MULTIPLIER[i]);
                return result+(m);
            }

            if (_from < endBlock) {
                uint256 m = (endBlock-_from)*(REWARD_MULTIPLIER[i]);
                _from = endBlock;
                result = result+(m);
            }
        }
        return result;
    }

    function getPoolReward(uint256 _from, uint256 _to, uint256 _allocPoint) public view returns (uint256 forDev, uint256 forFarmer, uint256 forFT, uint256 forAdr, uint256 forFounders) {
        uint256 multiplier = getMultiplier(_from, _to);
        uint256 amount = multiplier*(REWARD_PER_BLOCK)*(_allocPoint)/(totalAllocPoint);
        uint256 BavaCanMint = Bava.cap()-(Bava.totalSupply());

        if (BavaCanMint < amount) {
            forDev = 0;
			forFarmer = BavaCanMint;
			forFT = 0;
			forAdr = 0;
			forFounders = 0;
        }
        else {
            forDev = amount*(PERCENT_FOR_DEV)/(100000);
			forFarmer = amount;
			forFT = amount*(PERCENT_FOR_FT)/(100);
			forAdr = amount*(PERCENT_FOR_ADR)/(10000);
			forFounders = amount*(PERCENT_FOR_FOUNDERS)/(100000);
        }
    }

    function claimReward(uint256 _pid) public {
        updatePool(_pid);
        _harvest(_pid);
    }

    // lock 95% of reward
    function _harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount > 0) {
            uint256 pending = user.amount*(pool.accBavaPerShare)/(1e12)-(user.rewardDebt);
            uint256 masterBal = Bava.balanceOf(address(this));

            if (pending > masterBal) {
                pending = masterBal;
            }
            
            if(pending > 0) {
                safeBavaTransfer(msg.sender, pending);
                uint256 lockAmount = 0;
                lockAmount = pending*(PERCENT_LOCK_BONUS_REWARD)/(100);
                Bava.lock(msg.sender, lockAmount);

                user.rewardDebtAtBlock = block.number;

                emit SendBavaReward(msg.sender, _pid, pending, lockAmount);
            }
            user.rewardDebt = user.amount*(pool.accBavaPerShare)/(1e12);
        }
    }
    
    // Deposit LP tokens to BavaMasterFarmer for $Bava allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(_amount > 0, "amount < 0");

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.deposits_enabled == true, "deposit false");
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserInfo storage devr = userInfo[_pid][devaddr];
        
        updatePool(_pid);
        _harvest(_pid);
        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);
        
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint poolReceiptAmount = getSharesForDepositTokens(_pid, _amount);
        pool.depositAmount += _amount;
        pool.receiptAmount += poolReceiptAmount;

        if (user.amount == 0) {
            user.rewardDebtAtBlock = block.number;
        }
        uint userReceiptAmount = poolReceiptAmount - poolReceiptAmount*(userDepFee)/(10000);  
        uint devrReceiptAmount = poolReceiptAmount - poolReceiptAmount*(devDepFee)/(10000);
        user.amount = user.amount+userReceiptAmount;
        user.rewardDebt = user.amount*(pool.accBavaPerShare)/(1e12);
        devr.amount = devr.amount+devrReceiptAmount;
        devr.rewardDebt = devr.amount*(pool.accBavaPerShare)/(1e12);

        _stakeDepositTokens(_pid, _amount);
        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);

        emit Deposit(msg.sender, _pid, _amount);
		if(user.firstDepositBlock > 0){
		} else {
			user.firstDepositBlock = block.number;
		}
		user.lastDepositBlock = block.number;
    }
    
  // Withdraw LP tokens from BavaMasterFarmer. argument "_amount" is receipt amount.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 lpBal = pool.depositAmount;
        uint depositTokenAmount = getDepositTokensForShares(_pid, _amount);

        require(lpBal >= depositTokenAmount, "withdraw > farmBal");
        require(user.amount >= _amount, "withdraw > stake");

        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);        
        updatePool(_pid);
        _harvest(_pid);
        _withdrawDepositTokens(_pid, depositTokenAmount);
        
        if(_amount > 0) {
            user.amount = user.amount-(_amount);
			if(user.lastWithdrawBlock > 0){
				user.blockdelta = block.number - user.lastWithdrawBlock; }
			else {
				user.blockdelta = block.number - user.firstDepositBlock;
			}
            pool.receiptAmount -= _amount;
			if(user.blockdelta == blockDeltaStartStage[0] || block.number == user.lastDepositBlock){
				//25% fee for withdrawals of LP tokens in the same block this is to prevent abuse from flashloans
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[0])/(100));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[0])/(100));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[0])/(100));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[0])/(100));
			} else if (user.blockdelta >= blockDeltaStartStage[1] && user.blockdelta <= blockDeltaEndStage[0]){
				//8% fee if a user deposits and withdraws in under between same block and 59 minutes.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[1])/(100));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[1])/(100));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[1])/(100));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[1])/(100));
			} else if (user.blockdelta >= blockDeltaStartStage[2] && user.blockdelta <= blockDeltaEndStage[1]){
				//4% fee if a user deposits and withdraws after 1 hour but before 1 day.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[2])/(100));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[2])/(100));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[2])/(100));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[2])/(100));
			} else if (user.blockdelta >= blockDeltaStartStage[3] && user.blockdelta <= blockDeltaEndStage[2]){
				//2% fee if a user deposits and withdraws between after 1 day but before 3 days.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[3])/(100));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[3])/(100));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[3])/(100));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[3])/(100));
			} else if (user.blockdelta >= blockDeltaStartStage[4] && user.blockdelta <= blockDeltaEndStage[3]){
				//1% fee if a user deposits and withdraws after 3 days but before 5 days.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[4])/(100));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[4])/(100));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[4])/(100));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[4])/(100));
			}  else if (user.blockdelta >= blockDeltaStartStage[5] && user.blockdelta <= blockDeltaEndStage[4]){
				//0.5% fee if a user deposits and withdraws if the user withdraws after 5 days but before 2 weeks.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[5])/(1000));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[5])/(1000));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[5])/(1000));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[5])/(1000));
			} else if (user.blockdelta >= blockDeltaStartStage[6] && user.blockdelta <= blockDeltaEndStage[5]){
				//0.25% fee if a user deposits and withdraws after 2 weeks.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[6])/(10000));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[6])/(10000));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[6])/(10000));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[6])/(10000));
			} else if (user.blockdelta > blockDeltaStartStage[7]) {
				//0.1% fee if a user deposits and withdraws after 4 weeks.
                pool.depositAmount -= (depositTokenAmount*(userFeeStage[7])/(10000));
                pool.depositAmount -= (depositTokenAmount*(devFeeStage[7])/(10000));
				pool.lpToken.safeTransfer(address(msg.sender), depositTokenAmount*(userFeeStage[7])/(10000));
				pool.lpToken.safeTransfer(address(devaddr), depositTokenAmount*(devFeeStage[7])/(10000));
			}
		user.rewardDebt = user.amount*(pool.accBavaPerShare)/(1e12);
        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);

        emit Withdraw(msg.sender, _pid, depositTokenAmount);
		user.lastWithdrawBlock = block.number;
			}
        }

    // Withdraw without caring about rewards. EMERGENCY ONLY. This has the same 25% fee as same block withdrawals to prevent abuse of thisfunction.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint depositTokenAmount = getDepositTokensForShares(_pid, user.amount);
        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);

        uint256 lpBal = pool.depositAmount;     //  pool.lpToken.balanceOf(address(this))
        require(lpBal >= depositTokenAmount, "withdraw > farmBal");
        _withdrawDepositTokens(_pid, depositTokenAmount);

        //reordered from Sushi function to prevent risk of reentrancy
        uint256 amountToSend = depositTokenAmount*(75)/(100);
        uint256 devToSend = depositTokenAmount*(25)/(100);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.receiptAmount -= user.amount;
        pool.depositAmount = pool.depositAmount-amountToSend-devToSend;

        pool.lpToken.safeTransfer(address(msg.sender), amountToSend);
        pool.lpToken.safeTransfer(address(devaddr), devToSend);
        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);

        emit EmergencyWithdraw(msg.sender, _pid, amountToSend, devToSend);
    }

    // Restake LP token to 3rd party restaking farm
    function _stakeDepositTokens(uint256 _pid, uint amount) private {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];
        require(amount > 0, "amount < 0");
        getReinvestReward(_pid);
        if (address(poolRestaking.pglStakingContract) != address(0)) {
            if(poolRestaking.numberOfPair == 0) {
                poolRestaking.pglStakingContract.deposit(poolRestaking.restakingFarmID, amount, address(this));                
            } else if (poolRestaking.numberOfPair == 1) {
                poolRestaking.pglSPStakingContract.stake(amount);
            }
        }
        if (address(poolRestaking.joeStakingContract) != address(0)) {
            poolRestaking.joeStakingContract.deposit(poolRestaking.restakingFarmID, amount);
        }
    }

    // Withdraw LP token to 3rd party restaking farm
    function _withdrawDepositTokens(uint256 _pid, uint amount) private {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];
        require(amount > 0, "amount < 0");
        getReinvestReward(_pid);
        if (address(poolRestaking.pglStakingContract) != address(0)) {
            if(poolRestaking.numberOfPair == 0) {
                (uint256 depositAmount,) = poolRestaking.pglStakingContract.userInfo(poolRestaking.restakingFarmID, address(this));
                if(depositAmount >= amount) {
                    poolRestaking.pglStakingContract.withdraw(poolRestaking.restakingFarmID, amount, address(this));
                } else {
                    poolRestaking.pglStakingContract.withdraw(poolRestaking.restakingFarmID, depositAmount, address(this));
                }
            } else if (poolRestaking.numberOfPair == 1) {
                uint256 depositAmount = poolRestaking.pglSPStakingContract.balanceOf(address(this));
                if(depositAmount >= amount) {  
                    poolRestaking.pglSPStakingContract.withdraw(amount);
                } else {
                    poolRestaking.pglSPStakingContract.withdraw(depositAmount);
                }
            }
        }
        if (address(poolRestaking.joeStakingContract) != address(0)) {
            (uint256 depositAmount,) = poolRestaking.joeStakingContract.userInfo(poolRestaking.restakingFarmID, address(this));
            if(depositAmount >= amount) {
                poolRestaking.joeStakingContract.withdraw(poolRestaking.restakingFarmID, amount);
            } else {
                poolRestaking.joeStakingContract.withdraw(poolRestaking.restakingFarmID, depositAmount);
            }
        }
    }

    // Claim LP restaking reward from 3rd party restaking contract
    function getReinvestReward(uint256 _pid) private {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];  

        if (address(poolRestaking.pglStakingContract) != address(0)) {
            if(poolRestaking.numberOfPair == 0) {
                poolRestaking.pglStakingContract.harvest(poolRestaking.restakingFarmID, address(this));
            } else if (poolRestaking.numberOfPair == 1) {
                poolRestaking.pglSPStakingContract.getReward();
            }
        }
        if (address(poolRestaking.joeStakingContract) != address(0)) {
            poolRestaking.joeStakingContract.deposit(poolRestaking.restakingFarmID, 0);
        }
    }

    // Claim LP restaking reward from 3rd party restaking contract
    function getReinvestRewardOwner(uint256 _pid) external onlyOwner {
        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);
        getReinvestReward(_pid);
        
        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);
    }

    // Emergency withdraw LP token from 3rd party restaking contract
    function emergencyWithdrawDepositTokens(uint256 _pid, bool disableDeposits) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];

        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);

        if (address(poolRestaking.pglStakingContract) != address(0)) {
            if(poolRestaking.numberOfPair == 0) {
                poolRestaking.pglStakingContract.emergencyWithdraw(poolRestaking.restakingFarmID, address(this));
            } else if (poolRestaking.numberOfPair == 1) {
                poolRestaking.pglSPStakingContract.exit();
            }
        }
        if (address(poolRestaking.joeStakingContract) != address(0)) {               
            poolRestaking.joeStakingContract.emergencyWithdraw(poolRestaking.restakingFarmID);
        } 
        if (pool.deposits_enabled == true && disableDeposits == true) {
            updateDepositsEnabled(_pid, false);
        }
        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);
    }

    // Compound reward token to restaking LP Token.
    function reinvest(uint _pid, uint256 _amount, address _to) external onlyOwner {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];

        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);

        uint256 rewardBal = poolRestaking.reward.balanceOf(address(this));
        if (rewardBal >= _amount) {
            poolRestaking.reward.safeTransfer(_to, _amount);
        } else {
            poolRestaking.reward.safeTransfer(_to, rewardBal);
        }

        if (address(poolRestaking.reward1) != address(0)) {
            uint256 reward1Bal = poolRestaking.reward1.balanceOf(address(this));
            if (reward1Bal >= _amount) {
                poolRestaking.reward1.safeTransfer(_to, _amount);
            } else {
                poolRestaking.reward1.safeTransfer(_to, reward1Bal);
            }
        }        

        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);       
    }

    // Return reinvest reward-> convert to LP token to the pool
    function returnReinvestReward(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        require(_amount > 0 , "Amount <= 0");
        (uint256 rewardBalBefore, uint256 reward1BalBefore) = _calRewardBefore(_pid);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        pool.depositAmount += _amount;

        _stakeDepositTokens(_pid, _amount);
        _calRewardAfter(_pid, rewardBalBefore, reward1BalBefore);
    }

    function _calRewardBefore(uint256 _pid) private view returns(uint256, uint256) {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];

        uint256 rewardBalBefore = 0;
        uint256 reward1BalBefore = 0;

        rewardBalBefore = poolRestaking.reward.balanceOf(address(this));        
        if (address(poolRestaking.reward1) != address(0)) {
            reward1BalBefore = poolRestaking.reward1.balanceOf(address(this));
        }
        return (rewardBalBefore, reward1BalBefore);
    }

    function _calRewardAfter(uint256 _pid, uint256 _rewardBalBefore, uint256 _reward1BalBefore) private {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];

        uint256 rewardBalAfter = 0;
        uint256 reward1BalAfter = 0;
        uint256 diffReward1Bal = 0;

        rewardBalAfter = poolRestaking.reward.balanceOf(address(this));
        if (rewardBalAfter >= _rewardBalBefore) {
            uint256 diffRewardBal = rewardBalAfter - _rewardBalBefore;
            poolRestaking.rewardAmount += diffRewardBal;
        } else {
            uint256 diffRewardBal = _rewardBalBefore - rewardBalAfter;
            poolRestaking.rewardAmount -= diffRewardBal;
        }

        if (address(poolRestaking.reward1) != address(0)) {
            reward1BalAfter = poolRestaking.reward1.balanceOf(address(this));
            if (reward1BalAfter >= _reward1BalBefore) {
                diffReward1Bal = reward1BalAfter - _reward1BalBefore;
                poolRestaking.reward1Amount += diffReward1Bal;
            } else {
                diffReward1Bal =  _reward1BalBefore - reward1BalAfter;
                poolRestaking.reward1Amount -= diffReward1Bal;
            }            
        }
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(uint _pid, bool newValue) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.deposits_enabled != newValue);
        pool.deposits_enabled = newValue;
        emit DepositsEnabled(_pid, newValue);
    }

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint _pid, uint amount) public view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.receiptAmount*pool.depositAmount == 0) {
            return amount;
        }
        return amount*pool.receiptAmount/pool.depositAmount;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint _pid, uint amount) public view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.receiptAmount*pool.depositAmount == 0) {
            return 0;
        }
        return amount*pool.depositAmount/pool.receiptAmount;
    }   

    // Safe Bava transfer function, just in case if rounding error causes pool to not have enough Bavas.
    function safeBavaTransfer(address _to, uint256 _amount) private {
        uint256 BavaBal = Bava.balanceOf(address(this));
        if (_amount > BavaBal) {
            Bava.transfer(_to, BavaBal);
        } else {
            Bava.transfer(_to, _amount);
        }
    }

    // Rescue any token function, just in case if any user not able to withdraw token from the smart contract.
    function rescueDeployedFunds(address token, uint256 amount, address _to) external onlyOwner {
        require(_to != address(0), "send to the zero address");
        IERC20(token).safeTransfer(_to, amount);
    }

    /****** ONLY AUTHORIZED FUNCTIONS ******/
    // Update smart contract general variable functions
    // Update dev address by the previous dev.
    function addrUpdate(address _devaddr, address _newFT, address _newAdr, address _newFounder) public onlyAuthorized {
        devaddr = _devaddr;
        futureTreasuryaddr = _newFT;
        advisoraddr = _newAdr;
        founderaddr = _newFounder;
    }

    // Update % lock for general users & percent for other roles
    function percentUpdate(uint _newlock, uint _newdev, uint _newft, uint _newadr, uint _newfounder) public onlyAuthorized {
       PERCENT_LOCK_BONUS_REWARD = _newlock;
       PERCENT_FOR_DEV = _newdev;
       PERCENT_FOR_FT = _newft;
       PERCENT_FOR_ADR = _newadr;
       PERCENT_FOR_FOUNDERS = _newfounder;
    }

    // Update Finish Bonus Block
    function bonusFinishUpdate(uint256 _newFinish) public onlyAuthorized {
        FINISH_BONUS_AT_BLOCK = _newFinish;
    }
    
    // Update Halving At Block
    function halvingUpdate(uint256[] memory _newHalving) public onlyAuthorized {
        HALVING_AT_BLOCK = _newHalving;
    }
    
    // Update Reward Per Block
    function rewardUpdate(uint256 _newReward) public onlyAuthorized {
       REWARD_PER_BLOCK = _newReward;
    }
    
    // Update Rewards Mulitplier Array
    function rewardMulUpdate(uint256[] memory _newMulReward) public onlyAuthorized {
       REWARD_MULTIPLIER = _newMulReward;
    }
    
    // Update START_BLOCK
    function starblockUpdate(uint _newstarblock) public onlyAuthorized {
       START_BLOCK = _newstarblock;
    }

	function setStageStarts(uint[] memory _blockStarts) public onlyAuthorized() {
        blockDeltaStartStage = _blockStarts;
    }
    
    function setStageEnds(uint[] memory _blockEnds) public onlyAuthorized() {
        blockDeltaEndStage = _blockEnds;
    }
    
    function setUserFeeStage(uint[] memory _userFees) public onlyAuthorized() {
        userFeeStage = _userFees;
    }
    
    function setDevFeeStage(uint[] memory _devFees) public onlyAuthorized() {
        devFeeStage = _devFees;
    }
    
    function setDevDepFee(uint _usrDepFees, uint _devDepFees) public onlyAuthorized() {
        userDepFee = _usrDepFees;
        devDepFee = _devDepFees;
    }
	
    // Update smart contract specific pool user variable function 
	function reviseWithdraw(uint _pid, address _user, uint256 _block) public onlyAuthorized() {
	   UserInfo storage user = userInfo[_pid][_user];
	   user.lastWithdrawBlock = _block;	    
	}
	
	function reviseDeposit(uint _pid, address _user, uint256 _block) public onlyAuthorized() {
	   UserInfo storage user = userInfo[_pid][_user];
	   user.firstDepositBlock = _block;	    
	}

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending Bavas on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBavaPerShare = pool.accBavaPerShare;
        uint256 lpSupply = pool.receiptAmount;

        if (block.number > pool.lastRewardBlock && lpSupply > 0) {
            uint256 BavaForFarmer;
            (, BavaForFarmer, , ,) = getPoolReward(pool.lastRewardBlock, block.number, pool.allocPoint);
            accBavaPerShare = accBavaPerShare+(BavaForFarmer*(1e12)/(lpSupply));
        }
        return user.amount*(accBavaPerShare)/(1e12)-(user.rewardDebt);
    }

    function pendingReinvestReward(uint256 _pid) public view returns (uint256 pending, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken) {
        PoolRestakingInfo storage poolRestaking = poolRestakingInfo[_pid];
        if (address(poolRestaking.pglStakingContract) != address(0)) {
            if(poolRestaking.numberOfPair == 0) {
                return (poolRestaking.pglStakingContract.pendingReward(poolRestaking.restakingFarmID, address(this)), address(0), string(''), 0);  
            } else if (poolRestaking.numberOfPair == 1) {
                return (poolRestaking.pglSPStakingContract.earned(address(this)), address(0), string(''), 0);  
            }
        }
        if (address(poolRestaking.joeStakingContract) != address(0)) {
            return poolRestaking.joeStakingContract.pendingTokens(poolRestaking.restakingFarmID, address(this));
        }   
    }
}