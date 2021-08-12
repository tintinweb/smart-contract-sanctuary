pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./constants/CrowdclickEscrowErrors.sol";
import "./interfaces/ICrowdclickOracle.sol";

contract CrowdclickEscrow is
    CrowdclickEscrowErrors, 
    Ownable, 
    ReentrancyGuard
{
    using SafeMath for uint256;

    ICrowdclickOracle internal crowdclickOracle;

    event RewardForwarded(address recipient, address publisher, uint256 reward, string campaignUrl);
    event CampaignCreated(address publisher, uint256 campaignBudget, string campaignUrl);
    event UserWithdrawalEmitted(address recipient, uint256 amount);
    event PublisherWithdrawalEmitted(address recipient, uint256 amount, string campaignUrl);

    struct Task {
        uint256 taskBudget;
        uint256 taskReward;
        uint256 currentBudget;
        string url;
        bool isActive;
    }

    mapping(address => mapping(string => Task)) taskCollection;
    mapping(address => uint256) private publisherAccountBalance;
    mapping(address => uint256) private userAccountBalance;

    uint256 public feePercentage;
    uint256 public collectedFee;

    address payable public feeCollector;

    constructor(
        address _crowdclickOracleAddress, 
        uint256 _feePercentage,
        address payable _feeCollector
    ) {
        crowdclickOracle = ICrowdclickOracle(_crowdclickOracleAddress);
        feePercentage = _feePercentage;
        feeCollector = _feeCollector;
    }

    // EXTERNAL FUNCTIONS /

    function openTask(
        string calldata _uuid,
        uint256 _taskBudget,
        uint256 _taskReward,
        string calldata _campaignUrl
    ) external payable nonReentrant {
        require(msg.value == _taskBudget, WRONG_CAMPAIGN_BUDGET);
        require(_taskBudget >= _taskReward, WRONG_CAMPAIGN_REWARD);

        Task memory taskInstance;
        taskInstance.taskBudget = _taskBudget;
        taskInstance.taskReward = _taskReward;
        taskInstance.currentBudget = _taskBudget;
        taskInstance.isActive = true;
        taskInstance.url = _campaignUrl;
        taskCollection[msg.sender][_uuid] = taskInstance;
        /** publisher balance + taskBudget - fee */
        publisherAccountBalance[msg.sender] = publisherAccountBalance[msg
            .sender]
            .add(taskInstance.currentBudget);
        emit CampaignCreated(msg.sender, taskInstance.taskBudget, taskInstance.url);
    }

    function changeFeeCollector(address payable _newFeeCollector) external onlyOwner() {
        feeCollector = _newFeeCollector;
    }

    function changeFeePercentage(uint256 _newFeePercentage) external onlyOwner() {
        feePercentage = _newFeePercentage;
    }

    function balanceOfPublisher(address _address)
        external
        view
        returns (uint256)
    {
        return publisherAccountBalance[_address];
    }

    function balanceOfUser(address _address) external view returns (uint256) {
        return userAccountBalance[_address];
    }

    function withdrawUserBalance() 
        external
        payable 
        nonReentrant {
        uint256 fee = calculateFee(userAccountBalance[msg.sender]);
        require(userAccountBalance[msg.sender].sub(fee) > 0);
        collectedFee = collectedFee.add(fee);
        emit UserWithdrawalEmitted(msg.sender, userAccountBalance[msg.sender].sub(fee));
        payable(msg.sender).transfer(userAccountBalance[msg.sender].sub(fee));
        userAccountBalance[msg.sender] = 0;
    }

    function withdrawFromCampaign(string calldata _uuid)
        external
        payable
        nonReentrant
    {
        Task storage taskInstance = _selectTask(msg.sender, _uuid);
        require(
            taskInstance.currentBudget > 0,
            NOT_ENOUGH_CAMPAIGN_BALANCE
        );
        require(
            publisherAccountBalance[msg.sender] >=
                taskInstance.currentBudget,
            NOT_ENOUGH_PUBLISHER_BALANCE
        );
        taskInstance.isActive = false;
        publisherAccountBalance[msg.sender] = publisherAccountBalance[msg
            .sender]
            .sub(taskInstance.currentBudget);
        uint256 currentCampaignBudget = taskInstance.currentBudget;
        taskInstance.currentBudget = 0;
        payable(msg.sender).transfer(currentCampaignBudget);
        emit PublisherWithdrawalEmitted(msg.sender, taskInstance.currentBudget, taskInstance.url);
    }

    /** look up task based on the campaign's url */
    function lookupTask(string calldata _uuid, address _address)
        external
        view
        returns (Task memory task)
    {
        Task memory taskInstance = _selectTask(_address, _uuid);
        return taskInstance;
    }

    // forward rewards /
    function forwardRewards(
        address _userAddress,
        address _publisherAddress,
        string calldata _uuid
    ) external 
      payable 
      onlyOwner()
      nonReentrant
    {
        Task storage taskInstance = _selectTask(
            _publisherAddress,
            _uuid
        );
        require(
            taskInstance.isActive,
            CAMPAIGN_NOT_ACTIVE
        );
        require(
            publisherAccountBalance[_publisherAddress] >
                taskInstance.taskReward,
            NOT_ENOUGH_PUBLISHER_BALANCE
        );
        /** decreases campaign task's current budget by campaign's reward */
        taskInstance
            .currentBudget = taskInstance.currentBudget
            .sub(taskInstance.taskReward);
        /** decreases the balance of the campaign's owner by the campaign's reward */
        publisherAccountBalance[_publisherAddress] = publisherAccountBalance[_publisherAddress]
            .sub(taskInstance.taskReward);
        /** increases the user's balance by the campaign's reward */
        userAccountBalance[_userAddress] = userAccountBalance[_userAddress].add(
            taskInstance.taskReward
        );
        emit RewardForwarded(_userAddress, _publisherAddress, taskInstance.taskReward, taskInstance.url);
        // if the updated campaign's current budget is less than the campaign's reward, then the campaign is not active anymore
        if (
            publisherAccountBalance[_publisherAddress] <=
            taskInstance.taskReward ||
            taskInstance.currentBudget < taskInstance.taskReward
        ) {
            taskInstance.isActive = false;
        }
    }

    function collectFee() external {
        require(msg.sender == feeCollector, NOT_FEE_COLLECTOR);
        feeCollector.transfer(collectedFee);
        collectedFee = 0;
    }

    // Admin withdraws campaign's balance on publisher's behalf /
    function adminPublisherWithdrawal(
        string calldata _uuid,
        address payable _publisherAddress
        ) 
        onlyOwner()
        external
        payable
        nonReentrant
    {
        Task storage taskInstance = _selectTask(_publisherAddress, _uuid);
        require(
            taskInstance.currentBudget > 0,
            NOT_ENOUGH_CAMPAIGN_BALANCE
        );
        require(
            publisherAccountBalance[_publisherAddress] >=
                taskInstance.currentBudget,
            NOT_ENOUGH_PUBLISHER_BALANCE
        );
        taskInstance.isActive = false;
        publisherAccountBalance[_publisherAddress] = publisherAccountBalance[_publisherAddress]
            .sub(taskInstance.currentBudget);
        uint256 currentCampaignBudget = taskInstance.currentBudget;
        taskInstance.currentBudget = 0;
        _publisherAddress.transfer(currentCampaignBudget);
        emit PublisherWithdrawalEmitted(_publisherAddress, taskInstance.currentBudget, taskInstance.url);
    }

    // Admin withdraws user's balance on user's behalf /
    function adminUserWithdrawal(address payable _userAddress) 
        onlyOwner()
        external
        payable
        nonReentrant 
    {
        uint256 userBalance = userAccountBalance[_userAddress];
        require(
            userBalance > 0,
            NOT_ENOUGH_USER_BALANCE
        );
        userAccountBalance[_userAddress] = 0;
        _userAddress.transfer(userBalance);
        emit UserWithdrawalEmitted(_userAddress, userBalance);
    }

    // PRIVATE FUNCTIONS /    

    /** retrieves correct task based on the address of the publisher and the campaign's url */
    function _selectTask(address _address, string memory _uuid)
        private
        view
        returns (Task storage task)
    {
        return taskCollection[_address][_uuid];
    }

    function calculateFee(uint256 _amount) view private returns(uint256) {
        require(_amount > 0, VALUE_NOT_GREATER_THAN_0);
        return _amount.mul(feePercentage).div(100);
    }
}

pragma solidity ^0.8.0;

contract CrowdclickEscrowErrors {
    string internal constant WRONG_CAMPAIGN_BUDGET = "WRONG_CAMPAIGN_BUDGET";
    string
        internal constant LESS_THAN_MINIMUM_WITHDRAWAL = "LESS_THAN_MINIMUM_WITHDRAWAL";
    string
        internal constant NOT_ENOUGH_USER_BALANCE = "NOT_ENOUGH_USER_BALANCE";
    string
        internal constant NOT_ENOUGH_CAMPAIGN_BALANCE = " NOT_ENOUGH_CAMPAIGN_BALANCE";
    string
        internal constant NOT_ENOUGH_PUBLISHER_BALANCE = "NOT_ENOUGH_PUBLISHER_BALANCE";

    string internal constant CAMPAIGN_NOT_ACTIVE = "CAMPAIGN_NOT_ACTIVE";

    string internal constant WRONG_AMOUNT = "WRONG_AMOUNT";
    string
        internal constant BALANCE_GREATER_THAN_WITHDRAW_AMOUNT = "BALANCE_MUST_BE_>=_AMOUNT";
    string
        internal constant VALUE_NOT_GREATER_THAN_0 = "VALUE_NOT_GREATER_THAN_0";
    string internal constant WRONG_CAMPAIGN_REWARD = "WRONG_CAMPAIGN_REWARD";
    string internal constant NOT_FEE_COLLECTOR = "NOT_FEE_COLLECTOR";
    string internal constant DAILY_WITHDRAWALS_EXCEEDED = "DAILY_WITHDRAWALS_EXCEEDED";
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICrowdclickOracle {
    function getUnderlyingUsdPriceFeed() external returns(uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
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

    constructor () {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}