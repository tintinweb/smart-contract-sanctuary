pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract IndorseStaking is Ownable, ReentrancyGuard {

    using SafeMath for uint;

    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping(address => Checkpoint[]) balances;

    function getCheckpoint(address _owner, uint _index)
    view
    external
    returns (
        uint128 fromBlock,
        uint128 value
    )
    {
        Checkpoint storage checkpoint_ = balances[_owner][_index];
        fromBlock = checkpoint_.fromBlock;
        value = checkpoint_.value;
    }

    // Tracks the history of the total delegations of the token
    Checkpoint[] totalSupplyHistory;

    struct Staker {
        uint stake;
        uint lastDepositAt;
        uint delegatedAmount;
        address delegatee;
    }

    mapping(address => Staker) public stakers;

    // Tracks sums of delegations for delegatees
    mapping(address => uint) public delegationSums;

    uint private constant GRANULARITY = 10e11;
    uint private constant NUMBER_OF_VARIABLE_REWARD_PERIODS = 59;

    IERC20 public tokenAddress = ERC20(0xf8e386EDa857484f5a12e4B5DAa9984E06E73705);
    address public indorseMultiSigHolder = 0xe27308bd67E07a5c0a899aa6632183CAb8c2818A;
    uint public rewardsPaid;
    uint public totalStake;
    uint public stakingStartBlock;
    uint public stakingRewardPeriodLength; //in blocks
    uint public stakingStartingReward;
    uint public stakingRewardDownwardStep;
    uint public delegationStakeRequirement;
    uint public totalVotingPower;

    constructor(uint _stakingRewardPeriodLength, uint _stakingStartingReward, uint _stakingRewardDownwardStep, uint _delegationStakeRequirement) public {
        stakingStartBlock = block.number;
        stakingRewardPeriodLength = _stakingRewardPeriodLength;
        stakingStartingReward = _stakingStartingReward;
        stakingRewardDownwardStep = _stakingRewardDownwardStep;
        delegationStakeRequirement = _delegationStakeRequirement;
        
    }

    function setDelegationStakeRequirement(uint _delegationStakeRequirement) external onlyOwner {
        delegationStakeRequirement = _delegationStakeRequirement;
    }

    function getRewardAtBlock(uint _stake, uint _lastDepositAt, uint _blockNumber) public view returns (uint reward)  {
        if(_stake == 0) {
            return 0;
        }

        uint depositingInterval = _lastDepositAt.sub(stakingStartBlock).div(stakingRewardPeriodLength);
        //0 is the first period
        uint currentInterval = _blockNumber.sub(stakingStartBlock).div(stakingRewardPeriodLength);

        uint lastVariableRewardInterval = currentInterval > NUMBER_OF_VARIABLE_REWARD_PERIODS ? NUMBER_OF_VARIABLE_REWARD_PERIODS : currentInterval;

        if (currentInterval > depositingInterval) {
            //first interval, A
            uint rewardAtFirstInterval = stakingStartingReward.sub((depositingInterval.mul(stakingRewardDownwardStep)));

            uint widthOfFirstIntervalSection = stakingStartBlock.add(depositingInterval.add(1).mul(stakingRewardPeriodLength)).sub(_lastDepositAt);

            reward = reward.add(rewardAtFirstInterval.mul(widthOfFirstIntervalSection));

            //last interval, C
            uint rewardAtLastInterval = stakingStartingReward.sub(lastVariableRewardInterval.mul(stakingRewardDownwardStep));

            uint widthOfLastIntervalSection = _blockNumber.sub(stakingStartBlock.add(lastVariableRewardInterval.mul(stakingRewardPeriodLength)));

            reward = reward.add(widthOfLastIntervalSection.mul(rewardAtLastInterval));

            if (lastVariableRewardInterval.sub(depositingInterval) > 1) {
                uint rewardAtPenultimateInterval = rewardAtLastInterval.add(stakingRewardDownwardStep);

                uint widthOfMiddleSections = (lastVariableRewardInterval.sub(depositingInterval).sub(1)).mul(stakingRewardPeriodLength);

                //middle intervals base, B
                reward = reward.add(rewardAtPenultimateInterval.mul(widthOfMiddleSections));

                //middle intervals triangle, B'
                uint rewardAtSecondInterval = rewardAtFirstInterval.sub(stakingRewardDownwardStep);

                reward.add(((rewardAtSecondInterval.sub(rewardAtPenultimateInterval)).mul(widthOfMiddleSections)).div(2));
            }
        } else {
            reward = reward.add(_blockNumber.sub(_lastDepositAt).mul(stakingStartingReward.sub(depositingInterval.mul(stakingRewardDownwardStep))));
        }

        reward = reward.mul(_stake);
        reward = reward.div(GRANULARITY);
    }

    //Adds the amount to the stake
    //If staker exists, it reaps the rewards and adds them to the stake as well
    function stake(uint _amount) external {
        // The tokens will be held in a Gnosis multisig contract for which the owners will be the Indorse board members
        require(tokenAddress.transferFrom(msg.sender, indorseMultiSigHolder, _amount), "Insufficient token balance");
        Staker storage staker = stakers[msg.sender];

        //New staker
        if (staker.stake == 0) {
            staker.stake = _amount;
            staker.lastDepositAt = block.number;
            totalStake = totalStake.add(_amount);
            //Existing staker - adding current reward to the stake
        } else {
            uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
            staker.stake = staker.stake.add(_amount.add(reward));
            rewardsPaid = rewardsPaid.add(reward);
            totalStake = totalStake.add(_amount).add(reward);
            staker.lastDepositAt = block.number;
        }
    }

    function delegate(uint _amount, address _delegatee) external {
        Staker storage staker = stakers[msg.sender];

        Staker storage delegateeStaker = stakers[_delegatee];

        require(delegateeStaker.stake >= delegationStakeRequirement, "Delegator does not meet staking requirement.");
        require(_amount > 0, "Amount cannot equal 0.");
        require(_amount <= staker.stake, "Amount must be lesser or equal to the stake.");

        if (staker.delegatee != _delegatee) {
            //New delegation
            if (staker.delegatedAmount != 0) {
                //Undelegating previous delegation
                delegationSums[staker.delegatee] = delegationSums[staker.delegatee].sub(staker.delegatedAmount);
                updateValueAtNow(balances[staker.delegatee], delegationSums[staker.delegatee]);
                totalVotingPower = totalVotingPower.sub(staker.delegatedAmount);
            }

            delegationSums[_delegatee] = delegationSums[_delegatee].add(_amount);
            totalVotingPower = totalVotingPower.add(_amount);
            staker.delegatee = _delegatee;
        } else if (staker.delegatedAmount != 0 && staker.delegatee == _delegatee) {
            //Changing the delegated amount
            if (_amount < staker.delegatedAmount) {
                //Decreasing delegation
                delegationSums[_delegatee] = delegationSums[_delegatee].sub(staker.delegatedAmount.sub(_amount));
                totalVotingPower = totalVotingPower.sub(staker.delegatedAmount.sub(_amount));
            } else {
                //Increasing delegation
                delegationSums[_delegatee] = delegationSums[_delegatee].add(_amount.sub(staker.delegatedAmount));
                totalVotingPower = totalVotingPower.add(_amount.sub(staker.delegatedAmount));
            }
        }

        staker.delegatedAmount = _amount;

        updateValueAtNow(balances[_delegatee], delegationSums[_delegatee]);
        updateValueAtNow(totalSupplyHistory, totalVotingPower);
    }

    function undelegate() external {
        Staker storage staker = stakers[msg.sender];
        _undelegate(staker);
    }

    //Withdraws the entire stake and rewards
    function claimAndWithdraw() external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        if (staker.stake == 0) {
            return;
        }

        uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
        totalStake = totalStake.sub(staker.stake);
        rewardsPaid = rewardsPaid.add(reward);
        require(tokenAddress.transferFrom(indorseMultiSigHolder, msg.sender, staker.stake.add(reward)));
        staker.stake = 0;

        if (staker.delegatedAmount != 0) {
            _undelegate(staker);
        }
    }

    //Withdraw without reward, reward is lost
    function withdraw() external nonReentrant {
        Staker storage staker = stakers[msg.sender];

        if (staker.stake == 0) {
            return;
        }

        totalStake = totalStake.sub(staker.stake);
        require(tokenAddress.transferFrom(indorseMultiSigHolder, msg.sender, staker.stake));
        staker.stake = 0;

        if (staker.delegatedAmount != 0) {
            _undelegate(staker);
        }
    }

    //Transfers the accumulated rewards to sender, leaves the principal untouched
    function claim() external nonReentrant {
        Staker storage staker = stakers[msg.sender];

        if(staker.stake == 0) {
            return;
        }

        uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
        require(tokenAddress.transferFrom(indorseMultiSigHolder, msg.sender, reward));
        rewardsPaid = rewardsPaid.add(reward);
        staker.lastDepositAt = block.number;
    }

    //Add current reward to stake
    //Can move it to a separate function, make clearing all delegations a prerequisite for withdrawal
    function claimAndStake() external {
        Staker storage staker = stakers[msg.sender];

        if (staker.stake == 0) {
            return;
        }

        uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
        totalStake = totalStake.add(reward);
        rewardsPaid = rewardsPaid.add(reward);
        staker.stake = staker.stake.add(reward);
        staker.lastDepositAt = block.number;
    }

    function getStaker(address _addr)
    external
    view
    returns (
        uint stake_,
        uint lastDepositAt_,
        uint delegatedAmount_,
        address delegatee_
    )
    {
        Staker storage staker_ = stakers[_addr];

        stake_ = staker_.stake;
        lastDepositAt_ = staker_.lastDepositAt;
        delegatedAmount_ = staker_.delegatedAmount;
        delegatee_ = staker_.delegatee;
    }

    function getStake(address _addr) external view returns (uint) {
        return stakers[_addr].stake;
    }

    function getLastDepositAt(address _addr) external view returns (uint) {
        return stakers[_addr].lastDepositAt;
    }

    function getDelegatee(address _addr) external view returns (address) {
        return stakers[_addr].delegatee;
    }

    function getDelegatedAmount(address _addr) external view returns (uint) {
        return stakers[_addr].delegatedAmount;
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) external view returns (uint) {
        return getValueAt(totalSupplyHistory, _blockNumber);
    }

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint) {
        return getValueAt(balances[_owner], _blockNumber);
    }

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length.sub(1)];
            oldCheckPoint.value = uint128(_value);
        }
    }

    function _undelegate(Staker storage _staker) internal {
        require(_staker.delegatedAmount > 0, "There is no delegation to un-delegate.");

        delegationSums[_staker.delegatee] = delegationSums[_staker.delegatee].sub(_staker.delegatedAmount);
        updateValueAtNow(balances[_staker.delegatee], delegationSums[_staker.delegatee]);

        totalVotingPower = totalVotingPower.sub(_staker.delegatedAmount);
        updateValueAtNow(totalSupplyHistory, totalVotingPower);

        _staker.delegatedAmount = 0;
        _staker.delegatee = address(0);
    }
}

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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
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

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

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