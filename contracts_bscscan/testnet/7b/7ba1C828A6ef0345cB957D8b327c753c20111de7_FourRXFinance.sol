/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/InterestCalculator.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


contract InterestCalculator {
    using SafeMath for uint;
    uint private constant MAX_DAYS = 365;

    function _initCumulativeInterestForDays() internal pure returns(uint[366] memory) {
        uint[366] memory cumulativeInterestForDays = [
        uint(0), 1, 3, 5, 8, 12, 17, 23, 30, 37, 45, 54, 64, 75, 87, 100, 114, 129, 144, 160,
        177, 195, 214, 234, 255, 277, 300, 324, 349, 375, 402, 430, 459, 489, 520, 552, 585, 619, 654, 690,
        728, 767, 807, 848, 890, 933, 977, 1022, 1069, 1117, 1166, 1216, 1267, 1320, 1374, 1429, 1485, 1542, 1601, 1661,
        1722, 1785, 1849, 1914, 1981, 2049, 2118, 2189, 2261, 2334, 2409, 2485, 2562, 2641, 2721, 2803, 2886, 2971, 3057, 3145,
        3234, 3325, 3417, 3511, 3606, 3703, 3801, 3901, 4001, 4101, 4201, 4301, 4401, 4501, 4601, 4701, 4801, 4901, 5001, 5101,
        5201, 5301, 5401, 5501, 5601, 5701, 5801, 5901, 6001, 6101, 6201, 6301, 6401, 6501, 6601, 6701, 6801, 6901, 7001, 7101,
        7201, 7301, 7401, 7501, 7601, 7701, 7801, 7901, 8001, 8101, 8201, 8301, 8401, 8501, 8601, 8701, 8801, 8901, 9001, 9101,
        9201, 9301, 9401, 9501, 9601, 9701, 9801, 9901, 10001, 10101, 10201, 10301, 10401, 10501, 10601, 10701, 10801, 10901, 11001, 11101,
        11201, 11301, 11401, 11501, 11601, 11701, 11801, 11901, 12001, 12101, 12201, 12301, 12401, 12501, 12601, 12701, 12801, 12901, 13001, 13101,
        13201, 13301, 13401, 13501, 13601, 13701, 13801, 13901, 14001, 14101, 14201, 14301, 14401, 14501, 14601, 14701, 14801, 14901, 15001, 15101,
        15201, 15301, 15401, 15501, 15601, 15701, 15801, 15901, 16001, 16101, 16201, 16301, 16401, 16501, 16601, 16701, 16801, 16901, 17001, 17101,
        17201, 17301, 17401, 17501, 17601, 17701, 17801, 17901, 18001, 18101, 18201, 18301, 18401, 18501, 18601, 18701, 18801, 18901, 19001, 19101,
        19201, 19301, 19401, 19501, 19601, 19701, 19801, 19901, 20001, 20101, 20201, 20301, 20401, 20501, 20601, 20701, 20801, 20901, 21001, 21101,
        21201, 21301, 21401, 21501, 21601, 21701, 21801, 21901, 22001, 22101, 22201, 22301, 22401, 22501, 22601, 22701, 22801, 22901, 23001, 23101,
        23201, 23301, 23401, 23501, 23601, 23701, 23801, 23901, 24001, 24101, 24201, 24301, 24401, 24501, 24601, 24701, 24801, 24901, 25001, 25101,
        25201, 25301, 25401, 25501, 25601, 25701, 25801, 25901, 26001, 26101, 26201, 26301, 26401, 26501, 26601, 26701, 26801, 26901, 27001, 27101,
        27201, 27301, 27401, 27501, 27601, 27701, 27801, 27901, 28001, 28101, 28201, 28301, 28401, 28501, 28601, 28701, 28801, 28901, 29001, 29101,
        29201, 29301, 29401, 29501, 29601, 29701, 29801, 29901, 30001, 30101, 30201, 30301, 30401, 30501, 30601, 30701, 30801, 30901, 31001, 31101,
        31201, 31301, 31401, 31501, 31601, 31701
        ];


        return cumulativeInterestForDays;
    }

    function _getInterestTillDays(uint _day) internal pure returns(uint) {
        require(_day <= MAX_DAYS, 'FF: 1118');

        return _initCumulativeInterestForDays()[_day];
    }
}

// File: contracts/Events.sol


pragma solidity ^0.6.12;


contract Events {
    event Deposit(address user, uint amount, uint8 stakeId, address uplinkAddress, uint uplinkStakeId);
    event Withdrawn(address user, uint amount);
    event ReInvest(address user, uint amount);
    event Exited(address user, uint stakeId, uint amount);
    event PoolDrawn(uint refPoolAmount, uint sponsorPoolAmount);
}

// File: contracts/PercentageCalculator.sol


pragma solidity ^0.6.12;



contract PercentageCalculator {
    using SafeMath for uint;

    uint public constant PERCENT_MULTIPLIER = 10000;

    function _calcPercentage(uint amount, uint basisPoints) internal pure returns (uint) {
        require(basisPoints >= 0, 'FF: 1117');
        return amount.mul(basisPoints).div(PERCENT_MULTIPLIER);
    }

    function _calcBasisPoints(uint base, uint interest) internal pure returns (uint) {
        return interest.mul(PERCENT_MULTIPLIER).div(base);
    }
}

// File: contracts/utils/Utils.sol


pragma solidity ^0.6.12;



contract Utils {
    using SafeMath for uint;

    uint public constant DAY = 86400; // Seconds in a day

    function _calcDays(uint start, uint end) internal pure returns (uint) {
        return end.sub(start).div(DAY);
    }
}

// File: contracts/Constants.sol


pragma solidity ^0.6.12;


contract Constants {
    uint public constant MAX_CONTRACT_REWARD_BP = 31701; // 317.01%

//    uint public constant LP_FEE_BP = 500; // 5%
    uint public constant REF_COMMISSION_BP = 800; // 8%

    // Ref and sponsor pools
    uint public constant REF_POOL_FEE_BP = 50; // 0.5%, goes to ref pool from each deposit
    uint public constant SPONSOR_POOL_FEE_BP = 50; // 0.5%, goes to sponsor pool from each deposit

    uint public constant EXIT_PENALTY_BP = 5000; // 50%, deduct from user's initial deposit on exit

    // Contract bonus
    uint public constant MAX_CONTRACT_BONUS_BP = 300; // maximum bonus a user can get 3%
    uint public constant CONTRACT_BONUS_UNIT = 250;    // For each 250 token balance of contract, gives
    uint public constant CONTRACT_BONUS_PER_UNIT_BP = 1; // 0.01% extra interest

    // Hold bonus
    uint public constant MAX_HOLD_BONUS_BP = 100; // Maximum 1% hold bonus
    uint public constant HOLD_BONUS_UNIT = 43200; // 12 hours
    uint public constant HOLD_BONUS_PER_UNIT_BP = 2; // 0.02% hold bonus for each 12 hours of hold

    uint public constant REWARD_THRESHOLD_BP = 300; // User will only get hold bonus if his rewards are more then 3% of his deposit

    uint public constant MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP = 300; // Max daily withdrawal limit if user is above REWARD_THRESHOLD_BP

    uint public constant DEV_FEE_BP = 300; // 3%
}

// File: contracts/SharedVariables.sol


pragma solidity ^0.6.12;







contract SharedVariables is Constants, Events, PercentageCalculator, InterestCalculator, Utils {

    uint public constant fourRXTokenDecimals = 8;
    IERC20 public fourRXToken;
    address public devAddress;

    struct Stake {
        uint8 id;
        bool active;
        bool optInInsured; // Is insured ???
        uint16 stakeDuration; // In Days

//        uint32 holdFrom; // Timestamp from which hold should be counted
        uint32 interestCountFrom; // TimeStamp from which interest should be counted, from the beginning
        uint32 lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day

        uint origDeposit;
        uint deposit; // Initial Deposit
        uint withdrawn; // Total withdrawn from this stake
        uint penalty; // Total penalty on this stale

        uint rewards;
    }

    struct User {
        address wallet; // Wallet Address
        Stake[] stakes;
    }

    mapping (address => User) public users;

    uint public maxContractBalance;

    uint16 public poolCycle;
    uint32 public poolDrewAt;

    uint public refPoolBalance;
    uint public sponsorPoolBalance;

    uint public devBalance;

    uint[12] public refPoolBonuses;
    uint[10] public sponsorPoolBonuses;
}

// File: contracts/libs/SortedLinkedList.sol


pragma solidity ^0.6.12;



library SortedLinkedList {
    using SafeMath for uint;

    struct Item {
        address user;
        uint16 next;
        uint8 id;
        uint score;
    }

    uint16 internal constant GUARD = 0;

    function addNode(Item[] storage items, address user, uint score, uint8 id) internal {
        uint16 prev = findSortedIndex(items, score);
        require(_verifyIndex(items, score, prev), 'SLL: 1100');
        items.push(Item(user, items[prev].next, id, score));
        items[prev].next = uint16(items.length.sub(1));
    }

    function updateNode(Item[] storage items, address user, uint score, uint8 id) internal {
        (uint16 current, uint16 oldPrev) = findCurrentAndPrevIndex(items, user, id);
        require(items[oldPrev].next == current, 'SLL: 1101');
        require(items[current].user == user, 'SLL: 1102');
        require(items[current].id == id, 'SLL: 1103');
        score = score.add(items[current].score);
        items[oldPrev].next = items[current].next;
        addNode(items, user, score, id);
    }

    function initNodes(Item[] storage items) internal {
        items.push(Item(address(0), 0, 0, 0));
    }

    function _verifyIndex(Item[] storage items, uint score, uint16 prev) internal view returns (bool) {
        return prev == GUARD || (score <= items[prev].score && score > items[items[prev].next].score);
    }

    function findSortedIndex(Item[] storage items, uint score) internal view returns(uint16) {
        Item memory current = items[GUARD];
        uint16 index = GUARD;
        while(current.next != GUARD && items[current.next].score >= score) {
            index = current.next;
            current = items[current.next];
        }

        return index;
    }

    function findCurrentAndPrevIndex(Item[] storage items, address user, uint8 id) internal view returns (uint16, uint16) {
        Item memory current = items[GUARD];
        uint16 currentIndex = GUARD;
        uint16 prevIndex = GUARD;
        while(current.next != GUARD && !(current.user == user && current.id == id)) {
            prevIndex = currentIndex;
            currentIndex = current.next;
            current = items[current.next];
        }

        return (currentIndex, prevIndex);
    }

    function isInList(Item[] storage items, address user, uint8 id) internal view returns (bool) {
        Item memory current = items[GUARD];
        bool exists = false;

        while(current.next != GUARD ) {
            if (current.user == user && current.id == id) {
                exists = true;
                break;
            }
            current = items[current.next];
        }

        return exists;
    }
}

// File: contracts/Pools/SponsorPool.sol


pragma solidity ^0.6.12;


contract SponsorPool {
    SortedLinkedList.Item[] public sponsorPoolUsers;

    function _addSponsorPoolRecord(address user, uint amount, uint8 stakeId) internal {
        SortedLinkedList.addNode(sponsorPoolUsers, user, amount, stakeId);
    }

    function _cleanSponsorPoolUsers() internal {
        delete sponsorPoolUsers;
        SortedLinkedList.initNodes(sponsorPoolUsers);
    }
}

// File: contracts/Pools/ReferralPool.sol


pragma solidity ^0.6.12;



contract ReferralPool {
    SortedLinkedList.Item[] public refPoolUsers;

    function _addReferralPoolRecord(address user, uint amount, uint8 stakeId) internal {
        if (!SortedLinkedList.isInList(refPoolUsers, user, stakeId)) {
            SortedLinkedList.addNode(refPoolUsers, user, amount, stakeId);
        } else {
            SortedLinkedList.updateNode(refPoolUsers, user, amount, stakeId);
        }
    }

    function _cleanReferralPoolUsers() internal {
        delete refPoolUsers;
        SortedLinkedList.initNodes(refPoolUsers);
    }
}

// File: contracts/Pools.sol


pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;



contract Pools is SponsorPool, ReferralPool, SharedVariables {

    uint8 public constant MAX_REF_POOL_USERS = 12;
    uint8 public constant MAX_SPONSOR_POOL_USERS = 10;

    function _resetPools() internal {
        _cleanSponsorPoolUsers();
        _cleanReferralPoolUsers();
        delete refPoolBalance;
        delete sponsorPoolBalance;
        poolDrewAt = uint32(block.timestamp);
        poolCycle++;
    }

    function _updateSponsorPoolUsers(User memory user, Stake memory stake) internal {
        _addSponsorPoolRecord(user.wallet, stake.deposit, stake.id);
    }

    // Reorganise top ref-pool users to draw pool for
    function _updateRefPoolUsers(User memory uplinkUser , Stake memory stake, uint8 uplinkUserStakeId) internal {
        _addReferralPoolRecord(uplinkUser.wallet, stake.deposit, uplinkUserStakeId);
    }

    function drawPool() public {
        if (block.timestamp > poolDrewAt + 1 days) {

            SortedLinkedList.Item memory current = refPoolUsers[0];
            uint16 i = 0;

            while (i < MAX_REF_POOL_USERS && current.next != SortedLinkedList.GUARD) {
                current = refPoolUsers[current.next];
                _addRewards(users[current.user].stakes[current.id], _calcPercentage(refPoolBalance, refPoolBonuses[i]));
//                users[current.user].stakes[current.id].rewards = users[current.user].stakes[current.id].rewards.add(_calcPercentage(refPoolBalance, refPoolBonuses[i]));
                i++;
            }

            current = sponsorPoolUsers[0];
            i = 0;

            while (i < MAX_SPONSOR_POOL_USERS && current.next != SortedLinkedList.GUARD) {
                current = sponsorPoolUsers[current.next];
                _addRewards(users[current.user].stakes[current.id], _calcPercentage(sponsorPoolBalance, sponsorPoolBonuses[i]));
//                users[current.user].stakes[current.id].rewards = users[current.user].stakes[current.id].rewards.add(_calcPercentage(sponsorPoolBalance, sponsorPoolBonuses[i]));
                i++;
            }

            emit PoolDrawn(refPoolBalance, sponsorPoolBalance);

            _resetPools();
        }
    }

    // pool info getters

    function getPoolInfo() external view returns (uint32, uint16, uint, uint) {
        return (poolDrewAt, poolCycle, sponsorPoolBalance, refPoolBalance);
    }

    function getPoolParticipants() external view returns (address[] memory, uint8[] memory, uint[] memory, address[] memory, uint8[] memory, uint[] memory) {
        address[] memory sponsorPoolUsersAddresses = new address[](MAX_SPONSOR_POOL_USERS);
        uint8[] memory sponsorPoolUsersStakeIds = new uint8[](MAX_SPONSOR_POOL_USERS);
        uint[] memory sponsorPoolUsersAmounts = new uint[](MAX_SPONSOR_POOL_USERS);

        address[] memory refPoolUsersAddresses = new address[](MAX_REF_POOL_USERS);
        uint8[] memory refPoolUsersStakeIds = new uint8[](MAX_REF_POOL_USERS);
        uint[] memory refPoolUsersAmounts = new uint[](MAX_REF_POOL_USERS);

        uint16 i = 0;
        SortedLinkedList.Item memory current = sponsorPoolUsers[i];

        while (i < MAX_SPONSOR_POOL_USERS && current.next != SortedLinkedList.GUARD) {
            current = sponsorPoolUsers[current.next];
            sponsorPoolUsersAddresses[i] = current.user;
            sponsorPoolUsersStakeIds[i] = current.id;
            sponsorPoolUsersAmounts[i] = current.score;
            i++;
        }

        i = 0;
        current = refPoolUsers[i];

        while (i < MAX_REF_POOL_USERS && current.next != SortedLinkedList.GUARD) {
            current = refPoolUsers[current.next];
            refPoolUsersAddresses[i] = current.user;
            refPoolUsersStakeIds[i] = current.id;
            refPoolUsersAmounts[i] = current.score;
            i++;
        }

        return (sponsorPoolUsersAddresses, sponsorPoolUsersStakeIds, sponsorPoolUsersAmounts, refPoolUsersAddresses, refPoolUsersStakeIds, refPoolUsersAmounts);
    }

    function _addRewards(Stake storage stake, uint rewards) internal {
        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP);
        if (stake.rewards.add(rewards) > maxRewards) {
            rewards = maxRewards.sub(stake.rewards);
        }

        stake.rewards = stake.rewards.add(rewards);
    }
}

// File: contracts/RewardsAndPenalties.sol


pragma solidity ^0.6.12;




contract RewardsAndPenalties is Pools {
    using SafeMath for uint;

    function _distributeReferralReward(uint amount, Stake memory stake, address uplinkAddress, uint8 uplinkStakeId) internal {
        User storage uplinkUser = users[uplinkAddress];

        uint commission = _calcPercentage(amount, REF_COMMISSION_BP);

        _addRewards(uplinkUser.stakes[uplinkStakeId], commission);

//        uplinkUser.stakes[uplinkStakeId].rewards = uplinkUser.stakes[uplinkStakeId].rewards.add(commission);

        _updateRefPoolUsers(uplinkUser, stake, uplinkStakeId);
    }

    function _calcDepositRewards(uint amount) internal pure returns (uint) {
        uint rewardPercent = 0;

        if (amount > 175 * (10**fourRXTokenDecimals)) {
            rewardPercent = 50; // 0.5%
        } else if (amount > 150 * (10**fourRXTokenDecimals)) {
            rewardPercent = 40; // 0.4%
        } else if (amount > 135 * (10**fourRXTokenDecimals)) {
            rewardPercent = 35; // 0.35%
        } else if (amount > 119 * (10**fourRXTokenDecimals)) {
            rewardPercent = 30; // 0.3%
        } else if (amount > 100 * (10**fourRXTokenDecimals)) {
            rewardPercent = 25; // 0.25%
        } else if (amount > 89 * (10**fourRXTokenDecimals)) {
            rewardPercent = 20; // 0.2%
        } else if (amount > 75 * (10**fourRXTokenDecimals)) {
            rewardPercent = 15; // 0.15%
        } else if (amount > 59 * (10**fourRXTokenDecimals)) {
            rewardPercent = 10; // 0.1%
        } else if (amount > 45 * (10**fourRXTokenDecimals)) {
            rewardPercent = 5; // 0.05%
        } else if (amount > 20 * (10**fourRXTokenDecimals)) {
            rewardPercent = 2; // 0.02%
        } else if (amount > 9 * (10**fourRXTokenDecimals)) {
            rewardPercent = 1; // 0.01%
        }

        return _calcPercentage(amount, rewardPercent);
    }

    function _calcContractBonus(Stake memory stake) internal view returns (uint) {
        uint contractBonusPercent = fourRXToken.balanceOf(address(this)).mul(CONTRACT_BONUS_PER_UNIT_BP).div(CONTRACT_BONUS_UNIT).div(10**fourRXTokenDecimals);

        if (contractBonusPercent > MAX_CONTRACT_BONUS_BP) {
            contractBonusPercent = MAX_CONTRACT_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, contractBonusPercent);
    }

    function _calcHoldRewards(Stake memory stake) internal view returns (uint) {
        uint holdBonusPercent = (block.timestamp).sub(stake.lastWithdrawalAt).div(HOLD_BONUS_UNIT).mul(HOLD_BONUS_PER_UNIT_BP);

        if (holdBonusPercent > MAX_HOLD_BONUS_BP) {
            holdBonusPercent = MAX_HOLD_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, holdBonusPercent);
    }

    function _calcRewardsWithoutHoldBonus(Stake memory stake) internal view returns (uint) {
        uint interest = _calcPercentage(stake.deposit, _getInterestTillDays(_calcDays(stake.interestCountFrom, block.timestamp)));

        uint contractBonus = _calcContractBonus(stake);

        uint totalRewardsWithoutHoldBonus = stake.rewards.add(interest).add(contractBonus);

        return totalRewardsWithoutHoldBonus;
    }

    function _calcRewards(Stake memory stake) internal view returns (uint) {
        uint rewards = _calcRewardsWithoutHoldBonus(stake);

        if (_calcBasisPoints(stake.deposit, rewards) >= REWARD_THRESHOLD_BP) {
            rewards = rewards.add(_calcHoldRewards(stake));
        }

        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP);

        if (rewards > maxRewards) {
            rewards = maxRewards;
        }

        return rewards;
    }

    function _calcWithdrawalPenalty(Stake memory stake, uint withdrawalAmount) internal pure returns (uint) {
        uint basisPoints = _calcBasisPoints(stake.deposit, withdrawalAmount);
        // If user's rewards are more then REWARD_THRESHOLD_BP -- No penalty
        if (basisPoints >= REWARD_THRESHOLD_BP) {
            return 0;
        }

        if (basisPoints > REWARD_THRESHOLD_BP) {
            return 0;
        }

        return _calcPercentage(_calcPercentage(stake.origDeposit, REWARD_THRESHOLD_BP), PERCENT_MULTIPLIER.sub(basisPoints.mul(PERCENT_MULTIPLIER).div(REWARD_THRESHOLD_BP)));
    }
}

// File: contracts/Insurance.sol


pragma solidity ^0.6.12;



contract Insurance is RewardsAndPenalties {
    uint private constant BASE_INSURANCE_FOR_BP = 3500; // trigger insurance with contract balance fall below 35%
    uint private constant OPT_IN_INSURANCE_FEE_BP = 1000; // 10%
    uint private constant OPT_IN_INSURANCE_FOR_BP = 10000; // 100%

    bool public isInInsuranceState; // if contract is only allowing insured money this becomes true;

    function _checkForBaseInsuranceTrigger() internal {
        if (fourRXToken.balanceOf(address(this)) <= _calcPercentage(maxContractBalance, BASE_INSURANCE_FOR_BP)) {
            isInInsuranceState = true;
        } else {
            isInInsuranceState = false;
        }
    }

    function _getInsuredAvailableAmount(Stake memory stake, uint withdrawalAmount) internal pure returns (uint)
    {
        uint availableAmount = withdrawalAmount;
        // Calc correct insured value by checking which insurance should be applied
        uint insuredFor = BASE_INSURANCE_FOR_BP;
        if (stake.optInInsured) {
            insuredFor = OPT_IN_INSURANCE_FOR_BP;
        }

        uint maxWithdrawalAllowed = _calcPercentage(stake.deposit, insuredFor);

        require(maxWithdrawalAllowed >= stake.withdrawn.add(stake.penalty), 'FF: 1114'); // if contract is in insurance trigger, do not allow withdrawals for the users who already have withdrawn more then 35%

        if (stake.withdrawn.add(availableAmount).add(stake.penalty) > maxWithdrawalAllowed) {
            availableAmount = maxWithdrawalAllowed.sub(stake.withdrawn).sub(stake.penalty);
        }

        return availableAmount;
    }

    function _insureStake(address user, Stake storage stake) internal {
        require(!stake.optInInsured && stake.active, 'FF: 1115');
        require(fourRXToken.transferFrom(user, address(this), _calcPercentage(stake.deposit, OPT_IN_INSURANCE_FEE_BP)), 'FF: 1116');

        stake.optInInsured = true;
    }
}

// File: contracts/FourRXFinance.sol


pragma solidity ^0.6.12;


/// @title 4RX Finance Staking DAPP Contract
/// @notice Available functionality: Deposit, Withdraw, ExitProgram, Insure Stake
contract FourRXFinance is Insurance {

    constructor(address _devAddress, address fourRXTokenAddress) public {
        devAddress = _devAddress;
        fourRXToken = IERC20(fourRXTokenAddress);

        refPoolBonuses = [2000, 1700, 1400, 1100, 1000, 700, 600, 500, 400, 300, 200, 100];
        sponsorPoolBonuses = [3000, 2000, 1200, 1000, 800, 700, 600, 400, 200, 100];

        _resetPools();

        poolCycle = 0;

        isInInsuranceState = false;
    }

    function deposit(uint amount, uint16 stakeDuration, address uplinkAddress, uint8 uplinkStakeId) external {
        require(
            uplinkAddress == address(0) ||
            (users[uplinkAddress].wallet != address(0) && users[uplinkAddress].stakes[uplinkStakeId].active)
        , 'FF: 1100'); // Either uplink must be registered and be a active deposit or 0 address

        require(stakeDuration >= 1 && stakeDuration <= 365, 'FF: 1200');

        User storage user = users[msg.sender];

        if (users[msg.sender].stakes.length > 0) {
            require(amount >= users[msg.sender].stakes[user.stakes.length - 1].deposit.mul(2), 'FF: 1101'); // deposit amount must be greater 2x then last deposit
        }

        require(fourRXToken.transferFrom(msg.sender, address(this), amount), 'FF: 1102');

        drawPool(); // Draw old pool if qualified, and we're pretty sure that this stake is going to be created

        uint depositReward = _calcDepositRewards(amount);

        Stake memory stake;

        user.wallet = msg.sender;

        stake.id = uint8(user.stakes.length);
        stake.active = true;
        stake.stakeDuration = stakeDuration;
        stake.interestCountFrom = uint32(block.timestamp);
//        stake.holdFrom = uint32(block.timestamp);
        stake.lastWithdrawalAt = uint32(block.timestamp);

        stake.origDeposit = amount;
        stake.deposit = amount.sub(_calcPercentage(amount, DEV_FEE_BP)); // Deduct LP Commission

        _updateSponsorPoolUsers(user, stake);

        if (uplinkAddress != address(0)) {
            _distributeReferralReward(amount, stake, uplinkAddress, uplinkStakeId);
        }

        user.stakes.push(stake);

        _addRewards(user.stakes[user.stakes.length - 1], depositReward); // add deposit rewards to stake

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, REF_POOL_FEE_BP));

        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, SPONSOR_POOL_FEE_BP));

        devBalance = devBalance.add(_calcPercentage(amount, DEV_FEE_BP));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

//        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, amount, stake.id,  uplinkAddress, uplinkStakeId);
    }


    function balanceOf(address _userAddress, uint stakeId) public view returns (uint) {
        require(users[_userAddress].wallet == _userAddress, 'FF: 1103');
        User memory user = users[_userAddress];

        return _calcRewards(user.stakes[stakeId]).sub(user.stakes[stakeId].withdrawn).sub(user.stakes[stakeId].penalty);
    }

    function withdraw(uint stakeId) external {
        User storage user = users[msg.sender];
        Stake storage stake = user.stakes[stakeId];
        require(user.wallet == msg.sender && stake.active, 'FF: 1104'); // stake should be active

        if (stake.withdrawn != 0) {
            require(stake.lastWithdrawalAt + 1 days < block.timestamp, 'FF: 1105'); // we only allow one withdrawal each day
        }

        uint availableAmount = _calcRewards(stake).sub(stake.withdrawn).sub(stake.penalty);

        require(availableAmount > 0, 'FF: 1106');

        uint penalty = _calcWithdrawalPenalty(stake, availableAmount);

        if (penalty == 0) {
//            availableAmount = availableAmount.sub(_calcPercentage(stake.deposit, REWARD_THRESHOLD_BP)); // Only allow withdrawal if available is more then 3% of base

            uint maxAllowedWithdrawal = _calcPercentage(stake.origDeposit, MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP);

            if (availableAmount > maxAllowedWithdrawal) {
                availableAmount = maxAllowedWithdrawal;
            }
        }

        if (isInInsuranceState) {
            availableAmount = _getInsuredAvailableAmount(stake, availableAmount);
        }

//        availableAmount = availableAmount.sub(penalty);

        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP);

        if (stake.withdrawn.add(stake.penalty).add(availableAmount) >= maxRewards) {
            availableAmount = maxRewards.sub(stake.withdrawn).sub(stake.penalty);
            stake.active = false; // if stake has withdrawn equals to or more then the max amount, then mark stake in-active
        }

        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.lastWithdrawalAt = uint32(block.timestamp);
//        stake.holdFrom = uint32(block.timestamp);

        stake.penalty = stake.penalty.add(penalty);

        fourRXToken.transfer(user.wallet, availableAmount);

        _checkForBaseInsuranceTrigger();

        emit Withdrawn(user.wallet, availableAmount);
    }

    function exitProgram(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, 'FF: 1107');
        Stake storage stake = user.stakes[stakeId];

        require(stake.active, 'FF: 1108');
        uint durationInDays = _calcDays(stake.interestCountFrom, block.timestamp);
        if (durationInDays < stake.stakeDuration) {
            require(durationInDays <= 112, 'FF: 1109'); // No exit after 112 days
        }

        uint penaltyAmount = 0;

        if (durationInDays < stake.stakeDuration) {
            penaltyAmount = _calcPercentage(stake.origDeposit, EXIT_PENALTY_BP); // Exit penalty if stake duration is not over
        }

        uint balance = balanceOf(msg.sender, stakeId);

        uint availableAmount = stake.deposit + balance - penaltyAmount; // (deposit - entry fee) + (rewards - withdrawn - old penalties) - exitPenalty

        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP.add(PERCENT_MULTIPLIER).sub(DEV_FEE_BP)); // at the time of exit, max withdrawal possible is  => max interest + base deposit - dev fee

        if (stake.withdrawn.add(stake.penalty).add(availableAmount) >= maxRewards) {
            availableAmount = maxRewards.sub(stake.withdrawn).sub(stake.penalty);
        }

        if (availableAmount > 0) {
            fourRXToken.transfer(user.wallet, availableAmount);
            stake.withdrawn = stake.withdrawn.add(availableAmount);
        }

        stake.active = false;
        stake.penalty = stake.penalty.add(penaltyAmount);
        stake.lastWithdrawalAt = uint32(block.timestamp);

//        totalExited = totalExited.add(1);

        emit Exited(user.wallet, stakeId, availableAmount > 0 ? availableAmount : 0);
    }

    function insureStake(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, 'FF: 1110');
        Stake storage stake = user.stakes[stakeId];
        _insureStake(user.wallet, stake);
    }

    // Getters

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getContractInfo() external view returns (uint, bool) {
        return (maxContractBalance, isInInsuranceState);
    }

    function withdrawDevFee(address withdrawingAddress, uint amount) external {
        require(msg.sender == devAddress, 'FF: 1111');
        require(amount <= devBalance, 'FF: 1112');
        devBalance = devBalance.sub(amount);
        fourRXToken.transfer(withdrawingAddress, amount);
    }

    function updateDevAddress(address newDevAddress) external {
        require(msg.sender == devAddress, 'FF: 1113');
        devAddress = newDevAddress;
    }
}