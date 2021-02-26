/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/utils/Arrays.sol

pragma solidity ^0.5.0;


/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: @openzeppelin/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/PreStakingContract.sol

pragma solidity ^0.5.17;









contract PreStakingContract is Pausable, ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using Math for uint256;
    using Address for address;
    using Arrays for uint256[];

    enum ContractStatus {Setup, Running, RewardsDisabled}

    enum DepositStatus {NoDeposit, Deposited, WithdrawalInitialized, WithdrawalExecuted}

    // EVENTS
    event StakeDeposited(address indexed account, uint256 amount);
    event WithdrawInitiated(address indexed account, uint256 amount);
    event WithdrawExecuted(address indexed account, uint256 amount, uint256 reward);

    // STRUCT DECLARATIONS
    struct StakeDeposit {
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        uint256 startCheckpointIndex;
        uint256 endCheckpointIndex;
        bool exists;
    }

    struct SetupState {
        bool staking;
        bool rewards;
    }

    struct StakingLimitConfig {
        uint256[] amounts;
        uint256 daysInterval;
        uint256 unstakingPeriod;
    }

    struct BaseRewardCheckpoint {
        uint256 baseRewardIndex;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 fromBlock;
    }

    struct BaseReward {
        uint256 anualRewardRate;
        uint256 lowerBound;
        uint256 upperBound;
    }

    struct RewardConfig {
        BaseReward[] baseRewards;
        uint256[] upperBounds;
        uint256 multiplier; // percent of the base reward applicable
    }

    // CONTRACT STATE VARIABLES
    IERC20 public token;
    ContractStatus public currentContractStatus;

    SetupState public setupState;
    StakingLimitConfig public stakingLimitConfig;
    RewardConfig public rewardConfig;

    address public rewardsAddress;
    uint256 public launchTimestamp;
    uint256 public currentTotalStake;

    mapping(address => StakeDeposit) private _stakeDeposits;
    BaseRewardCheckpoint[] private _baseRewardHistory;

    // MODIFIERS
    modifier guardMaxStakingLimit(uint256 amount)
    {
        uint256 resultedStakedAmount = currentTotalStake.add(amount);
        uint256 currentStakingLimit = _computeCurrentStakingLimit();
        require(resultedStakedAmount <= currentStakingLimit, "[Deposit] Your deposit would exceed the current staking limit");
        _;
    }

    modifier guardForPrematureWithdrawal()
    {
        uint256 intervalsPassed = _getIntervalsPassed(); 
        require(now >= (launchTimestamp + ((2 * stakingLimitConfig.daysInterval) * 1 days) + 3 days), "[Withdraw] Not enough days passed");
        _;
    }

    modifier onlyContract(address account)
    {
        require(account.isContract(), "[Validation] The address does not contain a contract");
        _;
    }

    modifier onlyDuringSetup()
    {
        require(currentContractStatus == ContractStatus.Setup, "[Lifecycle] Setup is already done");
        _;
    }

    modifier onlyAfterSetup()
    {
        require(currentContractStatus != ContractStatus.Setup, "[Lifecycle] Setup is not done");
        _;
    }

    // PUBLIC FUNCTIONS
    constructor(address _token, address _rewardsAddress)
    onlyContract(_token) Ownable()
    public
    {
        require(_rewardsAddress != address(0), "[Validation] _rewardsAddress is the zero address");

        token = IERC20(_token);
        rewardsAddress = _rewardsAddress;
        launchTimestamp = now;
        currentContractStatus = ContractStatus.Setup;
        pause();
    }

    function deposit(uint256 amount)
    public
    nonReentrant
    onlyAfterSetup
    whenNotPaused
    guardMaxStakingLimit(amount)
    {
        require(amount > 0, "[Validation] The stake deposit has to be larger than 0");
        require(!_stakeDeposits[msg.sender].exists, "[Deposit] You already have a stake");

        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        stakeDeposit.amount = stakeDeposit.amount.add(amount);
        stakeDeposit.startDate = now;
        stakeDeposit.startCheckpointIndex = _baseRewardHistory.length - 1;
        stakeDeposit.exists = true;

        currentTotalStake = currentTotalStake.add(amount);
        _updateBaseRewardHistory();

        // Transfer the Tokens to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "[Deposit] Something went wrong during the token transfer");
        emit StakeDeposited(msg.sender, amount);
    }

    function initiateWithdrawal()
    external
    whenNotPaused
    onlyAfterSetup
    guardForPrematureWithdrawal
    {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        require(stakeDeposit.exists && stakeDeposit.amount != 0, "[Initiate Withdrawal] There is no stake deposit for this account");
        require(stakeDeposit.endDate == 0, "[Initiate Withdrawal] You already initiated the withdrawal");

        stakeDeposit.endDate = now;
        stakeDeposit.endCheckpointIndex = _baseRewardHistory.length - 1;
        emit WithdrawInitiated(msg.sender, stakeDeposit.amount);
    }

    function executeWithdrawal()
    external
    nonReentrant
    whenNotPaused
    onlyAfterSetup
    {
        StakeDeposit storage stakeDeposit = _stakeDeposits[msg.sender];
        require(stakeDeposit.exists && stakeDeposit.amount != 0, "[Withdraw] There is no stake deposit for this account");
        require(stakeDeposit.endDate != 0, "[Withdraw] Withdraw is not initialized");
        // validate enough days have passed from initiating the withdrawal
        uint256 daysPassed = (now - stakeDeposit.endDate) / 1 days;
        require(stakingLimitConfig.unstakingPeriod <= daysPassed, "[Withdraw] The unstaking period did not pass");

        uint256 amount = stakeDeposit.amount;
        uint256 reward = _computeReward(stakeDeposit);

        stakeDeposit.amount = 0;
        stakeDeposit.startDate = 0;
        stakeDeposit.endDate = 0;
        stakeDeposit.startCheckpointIndex = 0;
        stakeDeposit.endCheckpointIndex = 0;
        stakeDeposit.exists = false;

        currentTotalStake = currentTotalStake.sub(amount);
        _updateBaseRewardHistory();

        require(token.transfer(msg.sender, amount), "[Withdraw] Something went wrong while transferring your initial deposit");
        require(token.transferFrom(rewardsAddress, msg.sender, reward), "[Withdraw] Something went wrong while transferring your reward");

        emit WithdrawExecuted(msg.sender, amount, reward);
    }

    function toggleRewards(bool enabled)
    external
    onlyOwner
    onlyAfterSetup
    {
        ContractStatus newContractStatus = enabled ? ContractStatus.Running : ContractStatus.RewardsDisabled;
        require(currentContractStatus != newContractStatus, "[ToggleRewards] This status is already set");

        uint256 index;

        if (newContractStatus == ContractStatus.RewardsDisabled) {
            index = rewardConfig.baseRewards.length - 1;
        }

        if (newContractStatus == ContractStatus.Running) {
            index = _computeCurrentBaseReward();
        }

        _insertNewCheckpoint(index);

        currentContractStatus = newContractStatus;
    }

    // VIEW FUNCTIONS FOR HELPING THE USER AND CLIENT INTERFACE
    function currentStakingLimit()
    public
    onlyAfterSetup
    view
    returns (uint256)
    {
        return _computeCurrentStakingLimit();
    }

    function earned(address account)
    external
    onlyAfterSetup
    view
    returns (uint256)
    {
        if (!_stakeDeposits[account].exists || _stakeDeposits[account].amount == 0) {
            return 0;
        }
        StakeDeposit memory stakeDeposit = _stakeDeposits[account];
        stakeDeposit.endDate = now;

        return (_computeReward(stakeDeposit));
    }

    function balanceOf(address account)
    external
    onlyAfterSetup
    view
    returns (uint256)
    {
        StakeDeposit memory stakeDeposit = _stakeDeposits[account];
        return stakeDeposit.amount;
    }

    function status(address account)
    public
    onlyAfterSetup
    view
    returns (DepositStatus)
    {
        if (!_stakeDeposits[account].exists || (_stakeDeposits[account].exists && _stakeDeposits[account].amount == 0)) {
            return DepositStatus.NoDeposit;
        }
        if (_stakeDeposits[account].amount > 0) {
            return _stakeDeposits[account].endDate == 0 ? DepositStatus.Deposited : DepositStatus.WithdrawalInitialized;
        }
        return DepositStatus.WithdrawalExecuted;
    }

    function withdrawalTime(address account)
    external
    onlyAfterSetup
    view
    returns (uint256)
    {
        StakeDeposit memory stakeDeposit = _stakeDeposits[account];
        if (status(account) != DepositStatus.WithdrawalInitialized) {
            return 0;
        }
        return stakeDeposit.endDate + (stakingLimitConfig.unstakingPeriod * 1 days);
    }

    function getStakeDeposit()
    external
    onlyAfterSetup
    view
    returns (uint256 amount, uint256 startDate, uint256 endDate, uint256 startCheckpointIndex, uint256 endCheckpointIndex)
    {
        require(_stakeDeposits[msg.sender].exists, "[Validation] This account doesn't have a stake deposit");
        StakeDeposit memory s = _stakeDeposits[msg.sender];

        return (s.amount, s.startDate, s.endDate, s.startCheckpointIndex, s.endCheckpointIndex);
    }

    function rewardRate()
    external
    onlyAfterSetup
    view
    returns (uint256)
    {
        BaseReward memory br = rewardConfig.baseRewards[_baseRewardHistory[_baseRewardHistory.length - 1].baseRewardIndex];

        return br.anualRewardRate;
    }

    function baseRewardsLength()
    external
    onlyAfterSetup
    view
    returns (uint256)
    {
        return rewardConfig.baseRewards.length;
    }

    function baseReward(uint256 index)
    external
    onlyAfterSetup
    view
    returns (uint256, uint256, uint256)
    {
        BaseReward memory br = rewardConfig.baseRewards[index];

        return (br.anualRewardRate, br.lowerBound, br.upperBound);
    }

    function baseRewardHistoryLength()
    external
    view
    returns (uint256)
    {
        return _baseRewardHistory.length;
    }

    function baseRewardHistory(uint256 index)
    external
    onlyAfterSetup
    view
    returns (uint256, uint256, uint256, uint256)
    {
        BaseRewardCheckpoint memory c = _baseRewardHistory[index];

        return (c.baseRewardIndex, c.startTimestamp, c.endTimestamp, c.fromBlock);
    }

    function baseRewardIndex(uint256 index)
    external
    onlyAfterSetup
    view
    returns (uint256)
    {
        BaseRewardCheckpoint memory c = _baseRewardHistory[index];

        return (c.baseRewardIndex);
    }

    function getLimitAmounts()
    external
    view
    returns(uint256[] memory) {
        return stakingLimitConfig.amounts;
    }

    // OWNER SETUP
    function setupStakingLimit(uint256[] calldata amounts, uint256 daysInterval, uint256 unstakingPeriod)
    external
    onlyOwner
    whenPaused
    onlyDuringSetup
    {
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "[Validation] some of amounts are 0");
            if (i != 0) {
                require(amounts[i] > amounts[i-1], "[Validation] rewards should be in ascending order");
            }
        }
      
        require(daysInterval > 0 && unstakingPeriod >= 0, "[Validation] Some parameters are 0");

        for (uint256 i = 0; i < amounts.length; i++) {
            stakingLimitConfig.amounts.push(amounts[i]);
        }
        stakingLimitConfig.daysInterval = daysInterval;
        stakingLimitConfig.unstakingPeriod = unstakingPeriod;

        setupState.staking = true;
        _updateSetupState();
    }

    function setupRewards(
        uint256 multiplier,
        uint256[] calldata anualRewardRates,
        uint256[] calldata lowerBounds,
        uint256[] calldata upperBounds
    )
    external
    onlyOwner
    whenPaused
    onlyDuringSetup
    {
        _validateSetupRewardsParameters(multiplier, anualRewardRates, lowerBounds, upperBounds);

        // Setup rewards
        rewardConfig.multiplier = multiplier;

        for (uint256 i = 0; i < anualRewardRates.length; i++) {
            _addBaseReward(anualRewardRates[i], lowerBounds[i], upperBounds[i]);
        }

        uint256 highestUpperBound = upperBounds[upperBounds.length - 1];

        // Add the zero annual reward rate
        _addBaseReward(0, highestUpperBound, highestUpperBound + 10);

        // initiate baseRewardHistory with the first one which should start from 0
        _initBaseRewardHistory();

        setupState.rewards = true;
        _updateSetupState();
    }

    // INTERNAL
    function _updateSetupState()
    private
    {
        if (!setupState.rewards || !setupState.staking) {
            return;
        }

        currentContractStatus = ContractStatus.Running;
    }

    function _computeCurrentStakingLimit()
    private
    view
    returns (uint256)
    {
        uint256 intervalsPassed = _getIntervalsPassed();
        return stakingLimitConfig.amounts[intervalsPassed];
    }

    function _getIntervalsPassed()
    private
    view
    returns (uint256)
    {
        uint256 daysPassed = (now - launchTimestamp) / 1 days;
        return daysPassed / stakingLimitConfig.daysInterval;
    }

    function _computeReward(StakeDeposit memory stakeDeposit)
    private
    view
    returns (uint256)
    {
        uint256 scale = 10 ** 18;
        (uint256 weightedSum, uint256 stakingPeriod) = _computeRewardRatesWeightedSum(stakeDeposit);

        if (stakingPeriod == 0) {
            return 0;
        }
        // scaling weightedSum and stakingPeriod because the weightedSum is in the thousands magnitude
        // and we risk losing detail while rounding
        weightedSum = weightedSum.mul(scale);

        uint256 weightedAverage = weightedSum.div(stakingPeriod);

        // rewardConfig.multiplier is a percentage expressed in 1/10 (a tenth) of a percent hence we divide by 1000
        uint256 accumulator = rewardConfig.multiplier.mul(weightedSum).div(1000);
        uint256 effectiveRate = weightedAverage.add(accumulator);
        uint256 denominator = scale.mul(36500);

        return stakeDeposit.amount.mul(effectiveRate).mul(stakingPeriod).div(denominator);
    }

    function _computeRewardRatesWeightedSum(StakeDeposit memory stakeDeposit)
    private
    view
    returns (uint256, uint256)
    {
        uint256 stakingPeriod = (stakeDeposit.endDate - stakeDeposit.startDate) / 1 days;
        uint256 weight;
        uint256 rate;

        // The contract never left the first checkpoint
        if (stakeDeposit.startCheckpointIndex == stakeDeposit.endCheckpointIndex) {
            rate = _baseRewardFromHistoryIndex(stakeDeposit.startCheckpointIndex).anualRewardRate;

            return (rate.mul(stakingPeriod), stakingPeriod);
        }

        // Computing the first segment base reward
        // User could deposit in the middle of the segment so we need to get the segment from which the user deposited
        // to the moment the base reward changes
        weight = (_baseRewardHistory[stakeDeposit.startCheckpointIndex].endTimestamp - stakeDeposit.startDate) / 1 days;
        rate = _baseRewardFromHistoryIndex(stakeDeposit.startCheckpointIndex).anualRewardRate;
        uint256 weightedSum = rate.mul(weight);

        // Starting from the second checkpoint because the first one is already computed
        for (uint256 i = stakeDeposit.startCheckpointIndex + 1; i < stakeDeposit.endCheckpointIndex; i++) {
            weight = (_baseRewardHistory[i].endTimestamp - _baseRewardHistory[i].startTimestamp) / 1 days;
            rate = _baseRewardFromHistoryIndex(i).anualRewardRate;
            weightedSum = weightedSum.add(rate.mul(weight));
        }

        // Computing the base reward for the last segment
        // days between start timestamp of the last checkpoint to the moment he initialized the withdrawal
        weight = (stakeDeposit.endDate - _baseRewardHistory[stakeDeposit.endCheckpointIndex].startTimestamp) / 1 days;
        rate = _baseRewardFromHistoryIndex(stakeDeposit.endCheckpointIndex).anualRewardRate;
        weightedSum = weightedSum.add(weight.mul(rate));

        return (weightedSum, stakingPeriod);
    }

    function _addBaseReward(uint256 anualRewardRate, uint256 lowerBound, uint256 upperBound)
    private
    {
        rewardConfig.baseRewards.push(BaseReward(anualRewardRate, lowerBound, upperBound));
        rewardConfig.upperBounds.push(upperBound);
    }

    function _initBaseRewardHistory()
    private
    {
        require(_baseRewardHistory.length == 0, "[Logical] Base reward history has already been initialized");

        _baseRewardHistory.push(BaseRewardCheckpoint(0, now, 0, block.number));
    }

    function _updateBaseRewardHistory()
    private
    {
        if (currentContractStatus == ContractStatus.RewardsDisabled) {
            return;
        }

        BaseReward memory currentBaseReward = _currentBaseReward();

        // Do nothing if currentTotalStake is in the current base reward bounds or lower
        if (currentTotalStake <= currentBaseReward.upperBound) {
            return;
        }

        uint256 newIndex = _computeCurrentBaseReward();
        _insertNewCheckpoint(newIndex);
    }

    function _insertNewCheckpoint(uint256 newIndex)
    private
    {
        BaseRewardCheckpoint storage oldCheckPoint = _lastBaseRewardCheckpoint();

        if (oldCheckPoint.fromBlock < block.number) {
            oldCheckPoint.endTimestamp = now;
            _baseRewardHistory.push(BaseRewardCheckpoint(newIndex, now, 0, block.number));
        } else {
            oldCheckPoint.baseRewardIndex = newIndex;
        }
    }

    function _currentBaseReward()
    private
    view
    returns (BaseReward memory)
    {
        // search for the current base reward from current total staked amount
        uint256 currentBaseRewardIndex = _lastBaseRewardCheckpoint().baseRewardIndex;

        return rewardConfig.baseRewards[currentBaseRewardIndex];
    }

    function _baseRewardFromHistoryIndex(uint256 index)
    private
    view
    returns (BaseReward memory)
    {
        return rewardConfig.baseRewards[_baseRewardHistory[index].baseRewardIndex];
    }

    function _lastBaseRewardCheckpoint()
    private
    view
    returns (BaseRewardCheckpoint storage)
    {
        return _baseRewardHistory[_baseRewardHistory.length - 1];
    }

    function _computeCurrentBaseReward()
    private
    view
    returns (uint256)
    {
        uint256 index = rewardConfig.upperBounds.findUpperBound(currentTotalStake);

        require(index < rewardConfig.upperBounds.length, "[NotFound] The current total staked is out of bounds");

        return index;
    }

    function _validateSetupRewardsParameters
    (
        uint256 multiplier,
        uint256[] memory anualRewardRates,
        uint256[] memory lowerBounds,
        uint256[] memory upperBounds
    )
    private
    pure
    {
        require(
            anualRewardRates.length > 0 && lowerBounds.length > 0 && upperBounds.length > 0,
            "[Validation] All parameters must have at least one element"
        );
        require(
            anualRewardRates.length == lowerBounds.length && lowerBounds.length == upperBounds.length,
            "[Validation] All parameters must have the same number of elements"
        );
        require(lowerBounds[0] == 0, "[Validation] First lower bound should be 0");
        require(
            (multiplier < 100) && (uint256(100).mod(multiplier) == 0),
            "[Validation] Multiplier should be smaller than 100 and divide it equally"
        );
    }
}