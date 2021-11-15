// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../interfaces/IReign.sol";
import "../interfaces/IPoolRouter.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BasketBalancer {
    using SafeMath for uint256;

    uint256 public full_allocation;
    uint128 public lastEpochUpdate;
    uint256 public lastEpochEnd;
    uint256 public maxDelta;

    address[] public allTokens;

    mapping(address => uint256) public continuousVote;
    mapping(address => uint256) public tokenAllocation;
    mapping(address => uint256) public tokenAllocationBefore;
    mapping(address => mapping(uint128 => bool)) public votedInEpoch;

    IReign private reign;
    address public poolRouter;
    address public reignDAO;
    address public reignDiamond;

    event UpdateAllocation(
        uint128 indexed epoch,
        address indexed pool,
        uint256 indexed allocation
    );
    event VoteOnAllocation(
        address indexed sender,
        address indexed pool,
        uint256 indexed allocation,
        uint128 epoch
    );

    event NewToken(address indexed pool, uint256 indexed allocation);
    event RemoveToken(address indexed pool);

    modifier onlyDAO() {
        require(msg.sender == reignDAO, "Only the DAO can execute this");
        _;
    }

    constructor(
        address _reignDiamond,
        address _reignDAO,
        address _poolRouter,
        uint256 _maxDelta
    ) {
        uint256 amountAllocated = 0;

        address[] memory tokens = IPoolRouter(_poolRouter).getPoolTokens();
        uint256[] memory weights = IPoolRouter(_poolRouter).getTokenWeights();

        for (uint256 i = 0; i < tokens.length; i++) {
            tokenAllocation[tokens[i]] = weights[i];
            tokenAllocationBefore[tokens[i]] = weights[i];
            continuousVote[tokens[i]] = weights[i];
            amountAllocated = amountAllocated.add(weights[i]);
        }
        full_allocation = amountAllocated;

        lastEpochUpdate = 0;
        maxDelta = _maxDelta;
        allTokens = tokens;
        reign = IReign(_reignDiamond);
        reignDiamond = _reignDiamond;
        reignDAO = _reignDAO;
        poolRouter = _poolRouter;
    }

    // Counts votes and sets the outcome allocation for each pool,
    // can be called by anyone through DAO after an epoch ends.
    // The new allocation value is the average of the vote outcome and the current value
    function updateBasketBalance() public onlyDAO {
        uint128 _epochId = getCurrentEpoch();
        require(lastEpochUpdate < _epochId, "Epoch is not over");

        for (uint256 i = 0; i < allTokens.length; i++) {
            uint256 _currentValue = continuousVote[allTokens[i]]; // new vote outcome
            uint256 _previousValue = tokenAllocation[allTokens[i]]; // before this vote

            // the new current value is the average between the 2 values
            tokenAllocation[allTokens[i]] = (_currentValue.add(_previousValue))
                .div(2);

            // update the previous value
            tokenAllocationBefore[allTokens[i]] = _previousValue;

            emit UpdateAllocation(
                _epochId,
                allTokens[i],
                tokenAllocation[allTokens[i]]
            );
        }

        lastEpochUpdate = _epochId;
        lastEpochEnd = block.timestamp;
    }

    // Allows users to update their vote by giving a desired allocation for each pool
    // tokens and allocations need to share the index, pool at index 1 will get allocation at index 1
    function updateAllocationVote(
        address[] calldata tokens,
        uint256[] calldata allocations
    ) external {
        uint128 _epoch = getCurrentEpoch();

        // Checks
        require(
            tokens.length == allTokens.length,
            "Need to vote for all tokens"
        );
        require(
            tokens.length == allocations.length,
            "Need to have same length"
        );
        require(reign.balanceOf(msg.sender) > 0, "Not allowed to vote");

        require(
            votedInEpoch[msg.sender][_epoch] == false,
            "Can not vote twice in an epoch"
        );

        // we take the voting power as it was at the end of the last epoch to avoid flashloan attacks
        // or users sending their stake to new wallets and vote again
        uint256 _votingPower = reign.votingPowerAtTs(msg.sender, lastEpochEnd);
        uint256 _totalPower = reign.reignStaked();

        //users vote "against" all other users
        uint256 _remainingPower = _totalPower.sub(_votingPower);

        uint256 amountAllocated = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            //tokens need to have the same order as allTokens
            require(allTokens[i] == tokens[i], "tokens have incorrect order");
            uint256 _votedFor = allocations[i];
            uint256 _current = continuousVote[allTokens[i]];
            amountAllocated = amountAllocated.add(_votedFor);

            // The difference between the voted for allocation and the current value can not exceed maxDelta
            if (_votedFor > _current) {
                require(_votedFor - _current <= maxDelta, "Above Max Delta");
            } else {
                require(_current - _votedFor <= maxDelta, "Above Max Delta");
            }
            // if all checks have passed, we update the allocation vote
            continuousVote[allTokens[i]] = (
                _current.mul(_remainingPower).add(_votedFor.mul(_votingPower))
            )
                .div(_totalPower);

            //emit event for each token
            emit VoteOnAllocation(msg.sender, allTokens[i], _votedFor, _epoch);
        }

        //transaction will revert if allocation is not complete
        require(
            amountAllocated == full_allocation,
            "Allocation is not complete"
        );

        // apply boost
        votedInEpoch[msg.sender][_epoch] = true;
    }

    // adds a token to the baskte balancer
    // this mirrors the tokens in the pool both in allocation and order added
    // every time a token is added to the pool it needs to be added here as well
    function addToken(address token, uint256 allocation)
        external
        onlyDAO
        returns (uint256)
    {
        // add token and store allocation
        allTokens.push(token);
        tokenAllocationBefore[token] = allocation;
        tokenAllocation[token] = allocation;
        continuousVote[token] = allocation;

        //update total allocation
        full_allocation = full_allocation.add(allocation);

        emit NewToken(token, allocation);

        return allTokens.length;
    }

    // removes a token from the baskte balancer
    // every time a token is removed to the pool it needs to be removed here as well
    function removeToken(address token) external onlyDAO returns (uint256) {
        require(tokenAllocation[token] != 0, "Token is not part of Basket");

        full_allocation = full_allocation.sub(continuousVote[token]);

        //remove token from array, moving all others 1 down if necessary
        uint256 index;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i] == token) {
                index = i;
                break;
            }
        }

        for (uint256 i = index; i < allTokens.length - 1; i++) {
            allTokens[i] = allTokens[i + 1];
        }
        allTokens.pop();

        // reset allocations
        tokenAllocationBefore[token] = 0;
        tokenAllocation[token] = 0;
        continuousVote[token] = 0;

        emit RemoveToken(token);

        return allTokens.length;
    }

    /*
     *   SETTERS
     */

    function setRouter(address _poolRouter) public onlyDAO {
        poolRouter = _poolRouter;
    }

    function setReignDAO(address _reignDAO) public onlyDAO {
        reignDAO = _reignDAO;
    }

    function setMaxDelta(uint256 _maxDelta) public onlyDAO {
        maxDelta = _maxDelta;
    }

    /*
     *   VIEWS
     */

    // gets the current target allocation
    function getTargetAllocation(address pool) public view returns (uint256) {
        return tokenAllocation[pool];
    }

    //Returns the id of the current epoch from reignDiamond
    function getCurrentEpoch() public view returns (uint128) {
        return reign.getCurrentEpoch();
    }

    function getTokens() external view returns (address[] memory) {
        return allTokens;
    }

    function hasVotedInEpoch(address user, uint128 epoch)
        external
        view
        returns (bool)
    {
        return votedInEpoch[user][epoch];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibReignStorage.sol";

interface IReign {
    function BASE_MULTIPLIER() external view returns (uint256);

    // deposit allows a user to add more bond to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current BOND balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of BOND that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp)
        external
        view
        returns (LibReignStorage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // bondStaked returns the total raw amount of BOND staked at the current block
    function reignStaked() external view returns (uint256);

    // reignStakedAtTs returns the total raw amount of BOND users have deposited into the contract
    // it does not include any bonus
    function reignStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakingBoost calculates the multiplier on the user's stake at the current timestamp
    function stakingBoost(address user) external view returns (uint256);

    // stackingBoostAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    function stackingBoostAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);

    // returns the last timestamp in which the user intercated with the staking contarct
    function userLastAction(address user) external view returns (uint256);

    // reignCirculatingSupply returns the current circulating supply of BOND
    function reignCirculatingSupply() external view returns (uint256);

    function getEpochDuration() external view returns (uint256);

    function getEpoch1Start() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint128);

    function stakingBoostAtEpoch(address, uint128)
        external
        view
        returns (uint256);

    function getEpochUserBalance(address, uint128)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IPoolRouter {
    // gets all tokens currently in the pool
    function getPoolTokens() external view returns (address[] memory);

    // gets all tokens currently in the pool
    function getTokenWeights() external view returns (uint256[] memory);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibReignStorage {

    bytes32 constant STORAGE_POSITION = keccak256("org.sovreign.reign.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct EpochBalance {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
        uint256 stakingBoost;
    }

    struct Storage {
        bool initialized;
        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;
        mapping(address => EpochBalance[]) userBalanceHistory;
        mapping(address => uint128) lastWithdrawEpochId;
        // array of reign staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] reignStakedHistory;
        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 reign; // the reign Token
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function reignStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

