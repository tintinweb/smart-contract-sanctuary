// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../tunnel/FxBaseChildTunnel.sol";
import "../lib/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/Pausable.sol";
import "./RETHSubscription.sol";

contract RETHChildPool is FxBaseChildTunnel, Ownable, Pausable{

    using SafeMath for uint256;

    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _isLocked;

    event RETHTransfer(address from, address to, uint256 amount);
    event RETHDeposit(address user, uint256 amount);
    event RETHCharge(address user, uint256 amount);

    RETHSubscription private _rethSubscription;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {
        // Create a subscription object
        _rethSubscription = new RETHSubscription();
    }
    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message)
    internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(message, (bytes32, bytes));

        // When deposit
        if (syncType == DEPOSIT) {
            (address depositor, uint256 ethers) = abi.decode(syncData, (address, uint256));
            _deposit(depositor, ethers);
        }
    }

    /**
    @dev issue ether from admin
    */
    function deposit(address to_, uint256 ethers_) external onlyOwner {
        _deposit(to_, ethers_);
    }

    function balanceOf(address user_) public view returns (uint256) {
        return _balances[user_];
    }

    function pause() external whenNotPaused onlyOwner{
        _pause();
    }

    function unPause() external whenPaused onlyOwner {
        _unpause();
    }

    function isLocked(address user_) public view returns (bool) {
        return _isLocked[user_];
    }

    function lockUser(address user_) external onlyOwner {
        _isLocked[user_] = true;
    }

    function unlockUser(address user_) external onlyOwner{
        _isLocked[user_] = false;
    }

    function transfer(address to_, uint256 amount_) public whenNotPaused{
        address _msgSender = _msgSender();
        require(!isLocked(_msgSender), "RETHChildPool: Sender locked");
        require(!isLocked(to_), "RETHChildPool: Receiver locked");

        _transfer(_msgSender, to_, amount_);
    }

    /**
     @dev charge amoun from user_
    */
    function charge(address user_, uint256 amount_) public onlyOwner {
        // Spend amount, the spender will be this contract,
        _rethSubscription.spend(user_, amount_);

        // if spent success, move assets to the admin
        transfer(owner(), amount_);

        // Emit the event that owner charged the reth
        emit RETHCharge(user_, amount_);
    }

    /**
        @dev returns the linked subscription address
    */
    function getSubscriptionAddress() public view returns (address){
        return address(_rethSubscription);
    }

    /**
        @dev deposit ethers
    */
    function _deposit(address depositor_, uint256 ethers_) private {
        // Add balance to depositor
        _balances[depositor_] = _balances[depositor_].add(ethers_);

        emit RETHDeposit(depositor_, ethers_);
    }

    function _transfer(address from_, address to_, uint256 amount_) private {
        require(_balances[from_] >= amount_, "RETHChildPool: transfer insufficient funds");

        // Actual transfer
        _balances[from_] = _balances[from_].sub(amount_);
        _balances[to_] = _balances[to_].add(amount_);

        emit RETHTransfer(from_, to_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";

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
abstract contract Ownable is Context{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Context.sol";
import "../lib/EnumerableSet.sol";
import "../lib/SafeMath.sol";

contract RETHSubscription is Context {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase, this is structure on javascript side
    bytes32 private immutable _SUBSCRIPTION_TYPEHASH = keccak256("Subscription(address parent,address child,uint256 totalLimit,uint256 cycle,uint256 limitPerCycle,address startTime,address endTime)");
    uint256 private immutable _ONE_DAY_IN_SECONDS = 86400;
    uint256 private immutable _ONE_WEEK_IN_SECONDS = 604800;
    /**
        parent allows child totalLimit, limit per cycle, from startTime, to endTime
        After endTime, child will not be able to use parent's reth balance
    */
    struct Subscription {
        address parent;
        address child;
        uint256 totalLimit;
        uint256 weeklyLimit;
        uint256 dailyLimit;
        uint256 transactionLimit;
        uint256 startTime;
        uint256 endTime;
    }

    struct SubscriptionStatus {
        bool isDisabled;
        uint256 totalSpent;
        uint256 weeklySpent;
        uint256 dailySpent;
        uint256 lastSpentTime;
    }

    struct SubscriptionInfo {
        Subscription subscription;
        SubscriptionStatus status;
    }

    // Enumerable keys for subscription
    EnumerableSet.Bytes32Set private _allSubscriptions;

    // Storage for hash(parent+child) => Subscription
    mapping (bytes32 => Subscription) private _subscriptions;

    mapping (bytes32 => SubscriptionStatus) private _subscriptionStatus;

    // Enumerable keys for parent address => [child address]
    mapping (address => EnumerableSet.AddressSet) private _childs;

    // Enumerable keys for child address => [parent address]
    mapping (address => EnumerableSet.AddressSet) private _parents;

    constructor() {

    }

    /**
       @dev Adds or remove subscription
    */
    function addSubscription(Subscription memory subscription_) external{
        require(!_allSubscriptions.contains(hashKey(_msgSender(), subscription_.child)), "RETHSubscription: Already has subscription");
        updateSubscription(subscription_);
    }

    function removeSubscription(address child_) public{
        bytes32 key = hashKey(_msgSender(), child_);
        require(_allSubscriptions.contains(key), "RETHSubscription: No subscription");

        // Remove all
        address parent = _msgSender();
        _allSubscriptions.remove(key);
        _childs[parent].remove(child_);
        _parents[child_].remove(parent);

        delete _subscriptionStatus[key];
        delete _subscriptions[key];
    }

    function updateSubscription(Subscription memory subscription_) public {
        address parent = _msgSender();
        address child = subscription_.child;
        require(child != address(0), "RETHSubscription: Child should not be zero address");
        require(parent != child, "RETHSubscription: Can't allow the same address");
        bytes32 key = hashKey(parent, child);

        uint256 maxInt = ~uint256(0);

        subscription_.parent = parent;

        // Set default values;
        if (subscription_.startTime == 0) {
            subscription_.startTime = block.timestamp;
        }

        if (subscription_.endTime == 0) {
            subscription_.endTime = maxInt;
        }

        if (subscription_.transactionLimit == 0) {
            subscription_.transactionLimit = maxInt;
        }

        if (subscription_.totalLimit == 0) {
            subscription_.totalLimit = maxInt;
        }

        if (subscription_.weeklyLimit == 0) {
            subscription_.weeklyLimit = maxInt;
        }

        if (subscription_.dailyLimit == 0) {
            subscription_.dailyLimit = maxInt;
        }

        // Assign subscription
        _subscriptions[key] = subscription_;

        // Add address
        _allSubscriptions.add(key);
        _childs[parent].add(child);
        _parents[child].add(parent);

        // Clear data for fresh start
        delete _subscriptionStatus[key];
    }

    function hashKey(address parent, address child) public pure returns (bytes32) {
        return keccak256(abi.encode(parent, child));
    }

    /**
       @dev check whether child can spend parent's amount now
    */
    function isSpendable(address child_, address parent_, uint256 amount_) public view returns (bool, string memory){
        bytes32 key = hashKey(parent_, child_);
        if (!_allSubscriptions.contains(key)) {
            return (false, "RETHSubscription: No subscription");
        }

        uint256 now = block.timestamp;
        Subscription memory subscription = _subscriptions[key];
        SubscriptionStatus memory status = _subscriptionStatus[key];

        if (status.isDisabled) {
            return (false, "RETHSubscription: Subscription is disabled");
        }

        if (subscription.endTime < now) {
            return (false, "RETHSubscription: Subscription expired");
        }

        if (subscription.startTime > now) {
            return (false, "RETHSubscription: Subscription did not start");
        }

        if (status.totalSpent.add(amount_) > subscription.totalLimit) {
            return (false, "RETHSubscription: Exceeds total spend limit");
        }

        if (amount_ > subscription.weeklyLimit) {
            return (false, "RETHSubscription: Exceeds weekly limit on a single transaction");
        }

        if (amount_ > subscription.dailyLimit) {
            return (false, "RETHSubscription: Exceeds daily limit on a single transaction");
        }

        if (amount_ > subscription.transactionLimit) {
            return (false, "RETHSubscription: Exceeds per transaction limit");
        }

        // Check weekly spent
        if (isWithInSamePeriod(subscription.startTime, _ONE_WEEK_IN_SECONDS, status.lastSpentTime, block.timestamp)){
            if (status.weeklySpent.add(amount_) > subscription.weeklyLimit) {
                return (false, "RETHSubscription: Exceeds weekly spend");
            }
            if (isWithInSamePeriod(subscription.startTime, _ONE_DAY_IN_SECONDS, status.lastSpentTime, block.timestamp)) {
                if (status.dailySpent.add(amount_) > subscription.dailyLimit) {
                    return (false, "RETHSubscription: Exceeds daily spend");
                }
            }
        }

        return (true, "");
    }

    /**
       @dev spend parent's asset
    */
    function spend(address parent_, uint256 amount) public returns (bool){
        address child = _msgSender();

        (bool allowed, string memory reason) = isSpendable(child, parent_, amount);

        // Reject if not spendable
        require(allowed, reason);

        bytes32 key = hashKey(parent_, child);
        require(_allSubscriptions.contains(key), "RETHSubscription: No subscription");

        SubscriptionStatus storage status = _subscriptionStatus[key];
        uint256 startTime = _subscriptions[key].startTime;
        uint256 lastSpent = status.lastSpentTime;
        uint256 now = block.timestamp;

        status.totalSpent += amount;
        if (isWithInSamePeriod(startTime, _ONE_WEEK_IN_SECONDS, lastSpent, now)) {
            status.weeklySpent += amount;
            if (isWithInSamePeriod(startTime, _ONE_DAY_IN_SECONDS, lastSpent, now)) {
                status.dailySpent += amount;
            } else {
                status.dailySpent = amount;
            }
        } else {
            status.weeklySpent = amount;
            status.dailySpent = amount;
        }
        // Assign last spent time
        status.lastSpentTime = block.timestamp;
        return true;
    }

    function isSubscriptionEnabled(address child_, address parent_) public view returns (bool){
        return !_subscriptionStatus[hashKey(parent_, child_)].isDisabled;
    }

    function disableSubscription(address child_) external {
        bytes32 key = hashKey(_msgSender(), child_);
        require(!_subscriptionStatus[key].isDisabled, "RETHSubscription: Already disabled");
        _subscriptionStatus[key].isDisabled = true;
    }

    function enableSubscription(address child_) external {
        bytes32 key = hashKey(_msgSender(), child_);
        require(_subscriptionStatus[key].isDisabled, "RETHSubscription: Already enabled");
        _subscriptionStatus[key].isDisabled = false;
    }

    /**
       @dev Check if a_ and _b are in the same time frame based on start_ and period_
    */
    function isWithInSamePeriod(uint256 start_, uint256 period_, uint256 a_, uint256 b_) public pure returns (bool) {
        uint abDiff = b_ - a_;
        // if difference between two timeframe is greater than period_, no need to check.
        if (abDiff > period_) {
            return false;
        }

        // Calculate nearest from start_
        uint aOffset = a_.sub(start_).mod(period_);

        // If within same timeframe, return true
        return (abDiff + aOffset) <= period_;
    }


    /**
       @dev return subscription information for child & parent
    */
    function subscriptionInfo(address child_, address parent_) public view returns (SubscriptionInfo memory) {
        bytes32 key = hashKey(parent_, child_);
        SubscriptionInfo memory info;
        info.subscription = _subscriptions[key];
        info.status = _subscriptionStatus[key];
        return info;
    }

    /**
       @dev return child addresses
    */
    function childAddresses(address parent_) public view returns (address[] memory) {
        uint256 count =  _childs[parent_].length();
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = _childs[parent_].at(i);
        }
        return result;
    }

    /**
       @dev return parent addresses
    */
    function parentAddresses(address child_) public view returns (address[] memory) {
        uint256 count =  _parents[child_].length();
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = _parents[child_].at(i);
        }
        return result;
    }

    /**
       @dev Get subscriptions for user
    */
    function subscriptions(address user_) public view returns (SubscriptionInfo[] memory) {
        uint256 count =  _childs[user_].length();
        uint256 count1 =  _parents[user_].length();
        SubscriptionInfo[] memory result = new SubscriptionInfo[](count + count1);
        for (uint i = 0; i < count; i++) {
            address child_ = _childs[user_].at(i);
            bytes32 key = hashKey(user_, child_);
            result[i].subscription = _subscriptions[key];
            result[i].status = _subscriptionStatus[key];
        }

        for (uint i = 0; i < count1; i++) {
            address parent_ = _parents[user_].at(i);
            bytes32 key = hashKey(parent_, user_);
            result[i + count].subscription = _subscriptions[key];
            result[i + count].status = _subscriptionStatus[key];
        }
        return result;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}