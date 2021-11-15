// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../libraries/SortitionSumTreeFactory.sol";
import "../libraries/UniformRandomNumber.sol";

import "../interfaces/IRNGenerator.sol";
import "../interfaces/IPinataManager.sol";

import "../manager/PinataManageable.sol";

/**
 * @dev Implementation of a prize pool to holding funds that would be distributed as prize for lucky winners.
 * This is the contract that receives funds from strategy (when harvesting) and distribute it when drawing time come.
 */
contract PrizePool is PinataManageable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    /* ========================== Variables ========================== */

    // Structure
    struct Entry {
        address addr;
        uint256 chances;
        uint256 lastEnterId;
        uint256 lastDeposit;
        uint256 claimableReward;
    }

    struct History {
        uint256 roundId;
        uint256 rewardNumber;
        address[] winners;
        uint256 roundReward;
    }

    // Constant
    uint256 private constant MAX_TREE_LEAVES = 5;
    bytes32 public constant SUM_TREE_KEY = "PrizePool";

    IERC20 public prizeToken;

    // RandomNumberGenerator
    bytes32 internal _requestId;
    uint256 internal _randomness;

    // State
    SortitionSumTreeFactory.SortitionSumTrees private sortitionSumTrees;
    mapping(address => Entry) private entries;
    uint256 public numOfParticipants;
    uint8 public numOfWinners;
    uint256 public _totalChances;
    uint256 public currentRound;
    mapping(uint256 => History) public histories;
    uint256 public allocatedRewards;
    uint256 public claimedRewards;

    /* ========================== Events ========================== */

    /**
     * @dev Emitted when reward is claimed.
     */
    event RewardClaimed(address claimer, uint256 amount);

    /**
     * @dev Emitted when drawing reward.
     */
    event DrawReward(bytes32 requestId, uint256 round);

    /**
     * @dev Emitted when winners is selected.
     */
    event WinnersDrawn(uint256 round);

    /**
     * @dev Emitted when reward successfully distributed.
     */
    event RewardDistributed(uint256 round);

    /* ========================== Functions ========================== */

    /**
     * @dev Setting up contract's state, Manager contract which will be use to observe state.
     *  the prize token is token that would be distribute as prize, and number of winners in each round.
     *  also creating a new tree which will need to use.
     * @param _manager address of PinataManager contract.
     * @param _prizeToken address of token will be distribute as reward.
     * @param _numOfWinners is number of lucky winner in each round.
     */
    constructor(
        address _manager,
        address _prizeToken,
        uint8 _numOfWinners
    ) public PinataManageable(_manager) {
        prizeToken = IERC20(_prizeToken);
        numOfWinners = _numOfWinners;
        allocatedRewards = 0;
        claimedRewards = 0;
        _totalChances = 0;
        currentRound = 0;
        numOfParticipants = 0;
        sortitionSumTrees.createTree(SUM_TREE_KEY, MAX_TREE_LEAVES);
    }

    /**
     * @dev add chances to win for participant may only call by vault.
     * @param participant address participant.
     * @param _chances number of chances to win.
     */
    function addChances(address participant, uint256 _chances)
        external
        onlyVault
    {
        require(_chances > 0, "PrizePool: Chances cannot be less than zero");
        _totalChances = _totalChances.add(_chances);
        if (entries[participant].chances > 0) {
            entries[participant].lastEnterId = currentRound;
            entries[participant].lastDeposit = block.timestamp;
            entries[participant].chances = entries[participant].chances.add(
                _chances
            );
        } else {
            entries[participant] = Entry(
                participant,
                _chances,
                currentRound,
                block.timestamp,
                0
            );
            numOfParticipants = numOfParticipants.add(1);
        }

        sortitionSumTrees.set(
            SUM_TREE_KEY,
            entries[participant].chances,
            bytes32(uint256(participant))
        );
    }

    /**
     * @dev withdraw all of chances of participant.
     * @param participant address participant.
     */
    function withdraw(address participant) external onlyVault {
        require(
            entries[participant].chances > 0,
            "PrizePool: Chances of participant already less than zero"
        );
        _totalChances = _totalChances.sub(entries[participant].chances);
        numOfParticipants = numOfParticipants.sub(1);
        entries[participant].chances = 0;

        sortitionSumTrees.set(SUM_TREE_KEY, 0, bytes32(uint256(participant)));
    }

    /**
     * @dev get chances of participant.
     * @param participant address participant.
     */
    function chancesOf(address participant) public view returns (uint256) {
        return entries[participant].chances;
    }

    /**
     * @dev return owner of ticket id.
     * @param ticketId is ticket id wish to know owner.
     */
    function ownerOf(uint256 ticketId) public view returns (address) {
        if (ticketId >= _totalChances) {
            return address(0);
        }

        return address(uint256(sortitionSumTrees.draw(SUM_TREE_KEY, ticketId)));
    }

    /**
     * @dev draw number to be use in reward distribution process.
     *  calling RandomNumberGenerator and keep requestId to check later when result comes.
     *  only allow to be call by manager.
     */
    function drawNumber() external onlyManager {
        (uint256 openTime, , uint256 drawTime) = getTimeline();
        uint256 timeOfRound = drawTime.sub(openTime);
        require(timeOfRound > 0, "PrizePool: time of round is zeroes!");

        _requestId = IRNGenerator(getRandomNumberGenerator()).getRandomNumber(
            currentRound,
            block.difficulty
        );

        emit DrawReward(_requestId, currentRound);
    }

    /**
     * @dev callback function for RandomNumberGenerator to return randomness.
     *  after randomness is recieve this contract would use it to distribute rewards.
     *  from funds inside the contract.
     *  this function is only allow to be call from random generator to ensure fairness.
     */
    function numbersDrawn(
        bytes32 requestId,
        uint256 roundId,
        uint256 randomness
    ) external onlyRandomGenerator {
        require(requestId == _requestId, "PrizePool: requestId not match!");
        require(roundId == currentRound, "PrizePool: roundId not match!");

        _randomness = randomness;

        manager.winnersCalculated();

        emit WinnersDrawn(currentRound);
    }

    /**
     * @dev internal function to calculate rewards with randomness got from RandomNumberGenerator.
     */
    function distributeRewards()
        public
        onlyTimekeeper
        whenInState(IPinataManager.LOTTERY_STATE.WINNERS_PENDING)
        returns (address[] memory, uint256)
    {
        address[] memory _winners = new address[](numOfWinners);
        uint256 allocatablePrize = allocatePrize();
        uint256 roundReward = 0;

        if (allocatablePrize > 0 && _totalChances > 0) {
            for (uint8 winner = 0; winner < numOfWinners; winner++) {
                // Picking ticket index that won the prize.
                uint256 winnerIdx = _selectRandom(
                    uint256(keccak256(abi.encode(_randomness, winner)))
                );
                // Address of ticket owner
                _winners[winner] = ownerOf(winnerIdx);

                Entry storage _winner = entries[_winners[winner]];
                // allocated prize for reward winner
                uint256 allocatedRewardFor = _allocatedRewardFor(
                    _winners[winner],
                    allocatablePrize.div(numOfWinners)
                );
                // set claimableReward for winner
                _winner.claimableReward = _winner.claimableReward.add(
                    allocatedRewardFor
                );
                roundReward = roundReward.add(allocatedRewardFor);
            }
        }

        allocatedRewards = allocatedRewards.add(roundReward);

        histories[currentRound] = History(
            currentRound,
            _randomness,
            _winners,
            roundReward
        );
        currentRound = currentRound.add(1);

        manager.rewardDistributed();

        emit RewardDistributed(currentRound.sub(1));
    }

    /**
     * @dev internal function to calculate reward for each winner.
     */
    function _allocatedRewardFor(address _winner, uint256 _allocatablePrizeFor)
        internal
        returns (uint256)
    {
        uint256 calculatedReward = 0;

        (uint256 openTime, , uint256 drawTime) = getTimeline();
        if (entries[_winner].lastDeposit >= openTime) {
            // Check if enter before openning of current round.
            uint256 timeOfRound = drawTime.sub(openTime);
            uint256 timeStaying = drawTime.sub(entries[_winner].lastDeposit);
            calculatedReward = _allocatablePrizeFor.mul(timeStaying).div(
                timeOfRound
            );

            // left over reward will be send back to vault.
            prizeToken.safeTransfer(
                getVault(),
                _allocatablePrizeFor.sub(calculatedReward)
            );
        } else {
            calculatedReward = _allocatablePrizeFor;
        }

        return calculatedReward;
    }

    /**
     * @dev function for claming reward.
     * @param _amount is amount of reward to claim
     */
    function claimReward(uint256 _amount) public {
        Entry storage claimer = entries[msg.sender];

        if (_amount > claimer.claimableReward) {
            _amount = claimer.claimableReward;
        }

        claimedRewards = claimedRewards.add(_amount);
        claimer.claimableReward = claimer.claimableReward.sub(_amount);

        prizeToken.safeTransfer(msg.sender, _amount);

        emit RewardClaimed(msg.sender, _amount);
    }

    /**
     * @dev get allocatePrize for current round.
     */
    function allocatePrize() public view returns (uint256) {
        return
            prizeToken.balanceOf(address(this)).add(claimedRewards).sub(
                allocatedRewards
            );
    }

    /**
     * @dev Selects a random number in the range [0, randomness)
     * @param randomness total The upper bound for the random number.
     */
    function _selectRandom(uint256 randomness) internal view returns (uint256) {
        return UniformRandomNumber.uniform(randomness, _totalChances);
    }

    /**
     * @dev entry info of participant.
     */
    function getEntryInfo(address _entry) public view returns (Entry memory) {
        return entries[_entry];
    }

    /**
     * @dev return number of participant in prize pool.
     */
    function getNumOfParticipants() public view returns (uint256) {
        return numOfParticipants;
    }

    /**
     * @dev get history of reward round.
     * @param _round is round wish to know history
     */
    function getHistory(uint256 _round)
        public
        view
        returns (History memory history)
    {
        return histories[_round];
    }

    /**
     * @dev use when want to retire prize pool.
     *  transfer all of token that has not been distribute as reward yet to vault.
     */
    function retirePrizePool() external onlyManager {
        IERC20(prizeToken).transfer(getVault(), allocatePrize());
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: GPL-3.0

/**
    This contract is copied from
    https://github.com/kleros/kleros/blob/master/contracts/data-structures/SortitionSumTreeFactory.sol
 */

/**
 *   We modified the version here
 *   the original one was using solidity ^0.4.24
 *   queryLeafs() function also remove since we not using it.
 */

/**
 *  @authors: [@epiqueras]
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer, @remedcu, @shalzz]
 *  @auditors: []
 *  @bounties: [{ duration: 28 days, link: https://github.com/kleros/kleros/issues/115, maxPayout: 50 ETH }]
 *  @deployments: [ https://etherscan.io/address/0x180eba68d164c3f8c3f6dc354125ebccf4dfcb86 ]
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* Public Views */

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }

        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

/**
  This contract is copied from https://github.com/pooltogether/pooltogether-pool-contracts/blob/v1/contracts/UniformRandomNumber.sol
 */

library UniformRandomNumber {
  /// @author Brendan Asselstine
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IRNGenerator {
    function getRandomNumber(uint256 _roundId, uint256 _userProvidedSeed)
        external
        returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPinataManager {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER,
        WINNERS_PENDING,
        READY
    }

    function startNewLottery(uint256 _closingTime, uint256 _drawingTime)
        external;

    function closePool() external;

    function calculateWinners() external;

    function winnersCalculated() external;
    
    function rewardDistributed() external;

    function getState() external view returns (LOTTERY_STATE);

    function getTimeline()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getVault() external view returns (address);

    function getStrategy() external view returns (address);

    function getPrizePool() external view returns (address);

    function getRandomNumberGenerator() external view returns (address);

    function getStrategist() external view returns (address);

    function getPinataFeeRecipient() external view returns (address);

    function getIsManager(address manager) external view returns (bool);

    function getIsTimekeeper(address timekeeper) external view returns (bool);

    function setVault(address _vault) external;

    function setStrategy(address _strategy) external;

    function setPrizePool(address _prizePool) external;

    function setRandomNumberGenerator(address _randomNumberGenerator) external;

    function setStrategist(address _strategist) external;

    function setPinataFeeRecipient(address _pinataFeeRecipient) external;

    function setManager(address _manager, bool status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IPinataManager.sol";

/**
 * @dev Base contract for every contract which is part of Pinata Finance's Prize Farming Game pool.
 *  main purpose of it was to simply enable easier ways for reading PinataManager state.
 */
abstract contract PinataManageable {
    /* ========================== Variables ========================== */

    IPinataManager public manager; // PinataManager contract

    /* ========================== Constructor ========================== */

    /**
     * @dev Modifier to make a function callable only when called by random generator.
     *
     * Requirements:
     *
     * - The caller have to be setted as random generator.
     */
    modifier onlyRandomGenerator() {
        require(
            msg.sender == getRandomNumberGenerator(),
            "PinataManageable: Only random generator allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by manager.
     *
     * Requirements:
     *
     * - The caller have to be setted as manager.
     */
    modifier onlyManager() {
        require(
            msg.sender == address(manager) || manager.getIsManager(msg.sender),
            "PinataManageable: Only PinataManager allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by timekeeper.
     *
     * Requirements:
     *
     * - The caller have to be setted as timekeeper.
     */
    modifier onlyTimekeeper() {
        require(
            msg.sender == address(manager) || manager.getIsTimekeeper(msg.sender),
            "PinataManageable: Only Timekeeper allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by Vault.
     *
     * Requirements:
     *
     * - The caller have to be setted as vault.
     */
    modifier onlyVault() {
        require(
            msg.sender == getVault(),
            "PinataManageable: Only vault allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by prize pool.
     *
     * Requirements:
     *
     * - The caller have to be setted as prize pool.
     */
    modifier onlyPrizePool() {
        require(
            msg.sender == getPrizePool(),
            "PinataManageable: Only prize pool allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when called by strategy.
     *
     * Requirements:
     *
     * - The caller have to be setted as strategy.
     */
    modifier onlyStrategy() {
        require(
            msg.sender == getStrategy(),
            "PinataManageable: Only strategy allowed!"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when pool is not in undesired state.
     *
     * @param state is state wish to not allow.
     *
     * Requirements:
     *
     * - Must calling when pool is not in undesired state.
     *
     */
    modifier whenNotInState(IPinataManager.LOTTERY_STATE state) {
        require(getState() != state, "PinataManageable: Not in desire state!");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when pool is in desired state.
     *
     * @param state is state wish to allow.
     *
     * Requirements:
     *
     * - Must calling when pool is in desired state.
     *
     */
    modifier whenInState(IPinataManager.LOTTERY_STATE state) {
        require(getState() == state, "PinataManageable: Not in desire state!");
        _;
    }

    /* ========================== Functions ========================== */

    /**
     * @dev Linking to manager wishes to read its state.
     * @param _manager address of manager contract.
     */
    constructor(address _manager) public {
        manager = IPinataManager(_manager);
    }

    /* ========================== Getter Functions ========================== */

    /**
     * @dev Read current state of pool.
     */
    function getState() public view returns (IPinataManager.LOTTERY_STATE) {
        return manager.getState();
    }

    /**
     * @dev Read if address was manager.
     * @param _manager address wish to know.
     */
    function getIfManager(address _manager) public view returns (bool) {
        return manager.getIsManager(_manager);
    }

    /**
     * @dev Get current timeline of pool (openning, closing, drawing).
     */
    function getTimeline() public view returns (uint256, uint256, uint256) {
        return manager.getTimeline();
    }

    /**
     * @dev Read vault contract address.
     */
    function getVault() public view returns (address) {
        return manager.getVault();
    }

    /**
     * @dev Read strategy contract address.
     */
    function getStrategy() public view returns (address) {
        return manager.getStrategy();
    }

    /**
     * @dev Read prize pool contract address.
     */
    function getPrizePool() public view returns (address) {
        return manager.getPrizePool();
    }

    /**
     * @dev Read random number generator contract address.
     */
    function getRandomNumberGenerator() public view returns (address) {
        return manager.getRandomNumberGenerator();
    }

    /**
     * @dev Read strategist address.
     */
    function getStrategist() public view returns (address) {
        return manager.getStrategist();
    }

    /**
     * @dev Read pinata fee recipient address.
     */
    function getPinataFeeRecipient() public view returns (address) {
        return manager.getPinataFeeRecipient();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

