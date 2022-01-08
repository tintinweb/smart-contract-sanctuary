// SPDX-License-Identifier: MIT

pragma solidity =0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BattleRoyaleETH is Ownable {
    using SafeMath for uint256;

    uint256 public LAUNCH_TIME;
    uint256[] public REFERRAL_PERCENTS = [30, 15, 5];
    uint256 public constant INVEST_MIN_AMOUNT = 0.1 ether;
    uint256 public constant PERCENT_STEP = 3;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant DECREASE_DAY_STEP = 0.25 days;
    uint256 public constant PENALTY_STEP = 500;
    uint256 public constant MARKETING_FEE = 40;
    uint256 public constant PROJECT_FEE = 40;

    uint256 public totalStaked;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
        bool force;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
    }

    mapping(address => User) internal users;
    mapping(address => Deposit[]) internal penaltyDeposits;

    mapping (address => bool) private _isEarlyGladiator;

    address payable public marketingAddress;
    address payable public projectAddress;
    bool public initialized;
    bool public onlyEarly;

    event Newbie(address user);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    event Withdrawn(address indexed user, uint256 amount);
    event ForceWithdrawn(address indexed user, uint256 amount, uint256 penaltyAmount, uint256 penaltyID);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event Initialized(uint256 launchTime);

    modifier beforeStarted() {
        require(initialized, "Not initialized yet");
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

    constructor(address payable marketingAddr, address payable projectAddr) {
        require(!isContract(marketingAddr), "!marketingAddr");
        require(!isContract(projectAddr), "!projectAddr");

        marketingAddress    = marketingAddr;
        projectAddress      = projectAddr;
        initialized         = false;
        onlyEarly           = true;

        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
    }

    // allows one time setting of launch time
    function initializeBattleRoyale(uint256 launchTime) public onlyOwner {
        require(initialized == false, "Battle Royale already initialized");

        initialized = true;
        LAUNCH_TIME = launchTime;

        emit Initialized(launchTime);
    }

    function toggleEarlyMode(bool _enabled) external onlyOwner() {
        require(_enabled != onlyEarly, "Mode already set with this value");
        onlyEarly = _enabled;
    }

    function addEarlyGladiator(address account) external onlyOwner() {
        require(!_isEarlyGladiator[account], "Account is already an early gladiator");
        _isEarlyGladiator[account] = true;
    }

    function removeEarlyGladiator(address account) external onlyOwner() {
        require(_isEarlyGladiator[account], "Account already removed");
        _isEarlyGladiator[account] = false;
    }

    function invest(address referrer, uint8 plan) public payable beforeStarted() {
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");

        if (onlyEarly) {
            require(_isEarlyGladiator[msg.sender], "Only Gladiators can invest at the moment");
        }

        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount =
                    msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(
            Deposit(
                plan,
                percent,
                msg.value,
                profit,
                block.timestamp,
                finish,
                true
            )
        );

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            msg.value,
            profit,
            block.timestamp,
            finish
        );
    }

    function withdraw() public beforeStarted() {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    user.deposits[i].force = false;
                } else if (block.timestamp > user.deposits[i].finish) {
                    user.deposits[i].force = false;
                }
            }
        }

        msg.sender.transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function forceWithdraw(uint256 index) public beforeStarted() {
        User storage user = users[msg.sender];

        require(index < user.deposits.length, "Invalid index");
        require(user.deposits[index].force == true, "Force is false");

        uint256 depositAmount = user.deposits[index].amount;
        uint256 penaltyAmount = depositAmount.mul(PENALTY_STEP).div(PERCENTS_DIVIDER);

        msg.sender.transfer(depositAmount.sub(penaltyAmount));

        penaltyDeposits[msg.sender].push(user.deposits[index]);

        user.deposits[index] = user.deposits[user.deposits.length - 1];
        user.deposits.pop();

        // the reason length will not change that can't used
        // delete user.deposits[index];

        emit ForceWithdrawn(msg.sender, depositAmount, penaltyAmount, penaltyDeposits[msg.sender].length);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        if (block.timestamp > LAUNCH_TIME) {
            return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(LAUNCH_TIME)).div(TIME_STEP));
        } else {
            return plans[plan].percent;
        }
    }

    function getResult(uint8 plan, uint256 deposit) public view
    returns (uint256 percent, uint256 profit, uint256 current, uint256 finish) {
        percent = getPercent(plan);

        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
            }
        }

        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User memory user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;

                    if (from < to) {
                        uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress = planTime.div(getDecreaseDays(plans[user.deposits[i].plan].time));

                        totalAmount = totalAmount.add(share.mul(to.sub(from)).mul(redress).div(TIME_STEP));
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }

        return totalAmount;
    }

    function getDecreaseDays(uint256 planTime) public view returns (uint256) {
        uint256 limitDays       = uint256(5).mul(TIME_STEP);
        uint256 pastDays        = block.timestamp.sub(LAUNCH_TIME).div(TIME_STEP);
        uint256 decreaseDays    = pastDays.mul(DECREASE_DAY_STEP);

        if (planTime.mul(TIME_STEP) < decreaseDays) {
            return limitDays;
        }

        uint256 minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);
        if (minimumDays < limitDays) {
            return limitDays;
        }

        return minimumDays;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns (address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns (uint256, uint256, uint256) {
        return (
        users[userAddress].levels[0],
        users[userAddress].levels[1],
        users[userAddress].levels[2]
        );
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress) public view returns (uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserAmountOfPenaltyDeposits(address userAddress) public view returns (uint256) {
        return penaltyDeposits[userAddress].length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view
    returns (
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish,
        bool force
    )
    {
        User memory user = users[userAddress];

        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }

    function getUserPenaltyDepositInfo(address userAddress, uint256 index) public view
    returns (
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    )
    {
        require(index < penaltyDeposits[userAddress].length, "Invalid index");

        plan = penaltyDeposits[userAddress][index].plan;
        percent = penaltyDeposits[userAddress][index].percent;
        amount = penaltyDeposits[userAddress][index].amount;
        profit = penaltyDeposits[userAddress][index].profit;
        start = penaltyDeposits[userAddress][index].start;
        finish = penaltyDeposits[userAddress][index].finish;
    }

    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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