/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// File: node_modules/@openzeppelin/contracts/math/SafeMath.sol

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

// File: node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: node_modules/@openzeppelin/contracts/GSN/Context.sol

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

// File: node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




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

// File: contracts/StakingContract.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;



/**
 * @title Staking Contract
 * @author Samarth Bhadane
 * @dev Use this contract for Staking tokens with a certain APY. Rewards are locked for 30 days.
 */

contract Staking {
    using SafeMath for uint256;

    ERC20 public token; // Address of ERC20 token.

    /**
     * @dev Returns APY set.
     * @return Annual Percentage Yield
     */
    uint256 public apy; // APY for rewards.

    /**
     * @dev Following is a struct to Store details of User.
     * totalStaked : Total tokens staked by the User.
     * totalRewardsCollected: Total rewards, locked as well as unlocked.
     * lastRewardClaimed: Timestamp of last reward (transferred to Locked) claimed by user.
     * lastStaked: Timestamp of last stake of user.
     */
    struct User {
        uint256 totalStaked;
        uint256 totalRewardsCollected;
        uint256 lastRewardClaimed;
        uint256 lastStaked;
    }

    /**
     * @dev Following is a Struct to store rewards.
     * amountPerWeek : Amount of rewards per week.
     * noOfWeeks : No. of Weeks.
     * lastCollectionTime: Time when tokens are unlocked.
     */
    struct Reward {
        uint256 amountPerWeek;
        uint256 noOfWeeks;
        uint256 lastCollectionTime;
    }

    mapping(address => User) public user;
    mapping(address => Reward) public rewards;

    /**
     * @dev total amount staked
     */
    uint256 public totalStaked;

    address[] public stakeholders;

    event Staked(address indexed _user, uint256 _amount, uint256 _total);
    event Unstaked(address indexed _user, uint256 _amount, uint256 _total);

    /**
     * @dev Initialize the contract.
     * @param _token ERC20 token contract.
     * @param _apy APY for rewards.
     */
    constructor(ERC20 _token, uint256 _apy) public {
        token = _token;
        apy = _apy;
    }

    /**
     * @dev Check if an address is a Stakeholder or not.
     * @param _address : Address to check if it is a Stakeholder.
     * @return true if _address is a stakeholder.
     */
    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < stakeholders.length; i++) {
            if (_address == stakeholders[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Add an address as a Stakeholder.
     * @param _address : Address to check if it is a Stakeholder.
     */
    function addStakeholder(address _address) internal {
        (bool sh, ) = isStakeholder(_address);
        if (!sh) {
            stakeholders.push(_address);
        }
    }

    /**
     * @dev Remove an address as a Stakeholder.
     * @param _address : Address to check if it is a Stakeholder.
     */
    function removeStakeholder(address _address) internal {
        (bool sh, uint256 index) = isStakeholder(_address);
        if (sh) {
            stakeholders[index] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    /**
     * @dev Stake the tokens. Any reward collected is transferred to Locking State.
     * @param _amount : Amount of tokens to be staked.
     */
    function stake(uint256 _amount) public {

        require(user[msg.sender].totalStaked == 0, "User already staked");
        require(user[msg.sender].totalRewardsCollected == 0, "User already staked");
        require(user[msg.sender].lastRewardClaimed == 0, "User already staked");
        require(user[msg.sender].lastStaked == 0, "User already staked");

        user[msg.sender].totalStaked = user[msg.sender].totalStaked.add(
            _amount
        );
        totalStaked = totalStaked.add(_amount);
        user[msg.sender].lastStaked = block.timestamp;
        user[msg.sender].lastRewardClaimed = 0;
        addStakeholder(msg.sender);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount, user[msg.sender].totalStaked);
    }

    /**
     * @dev Unstake the tokens. Any reward collected is transferred to Locking State.
     */
    function unstake() public {
        require(user[msg.sender].totalStaked > 0, "Invalid Amount");
        claimReward();
        (
            ,
            ,
            ,
            ,
            uint256 _rewardsPerWeek,
            uint256 _weeksPassed,
            uint256 _claimedWeeks,

        ) = getRewardStats(msg.sender);

        uint256 unclaimedWeeks = _weeksPassed.sub(_claimedWeeks);
        if (unclaimedWeeks != 0) {
            Reward memory _reward = Reward(
                _rewardsPerWeek,
                unclaimedWeeks,
                user[msg.sender].lastRewardClaimed
            );
            rewards[msg.sender] = _reward;
        }
        uint256 _amount = user[msg.sender].totalStaked;
        user[msg.sender].totalStaked = 0;
        totalStaked = totalStaked.sub(_amount);
        removeStakeholder(msg.sender);
        token.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, _amount);
    }

    function claimRewardAfterUnstake() public {
        require(rewards[msg.sender].noOfWeeks != 0, "No Rewards To claim");

        uint256 amount = 0;
        uint256 _weeksPassed = (
            block.timestamp.sub(rewards[msg.sender].lastCollectionTime)
        ).div(1 weeks);
        if (_weeksPassed > rewards[msg.sender].noOfWeeks) {
            _weeksPassed = rewards[msg.sender].noOfWeeks;
        }
        amount = amount.add(
            _weeksPassed.mul(rewards[msg.sender].amountPerWeek)
        );
        rewards[msg.sender].noOfWeeks = rewards[msg.sender].noOfWeeks.sub(
            _weeksPassed
        );
        rewards[msg.sender].lastCollectionTime = rewards[msg.sender]
            .lastCollectionTime
            .add(_weeksPassed.mul(1 weeks));
        token.transfer(msg.sender, amount);
    }

    /**
     * @dev Claim the rewards after their unlocking period.
     */
    function claimReward() public {
        require(user[msg.sender].totalStaked != 0, "No Rewards to claim");

        if (user[msg.sender].totalStaked != 0) {
            (
                uint256 _claimableRewards,
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 _rewardWeeks
            ) = getRewardStats(msg.sender);

            if (_claimableRewards != 0) {
                if (user[msg.sender].lastRewardClaimed == 0) {
                    user[msg.sender].lastRewardClaimed = user[msg.sender]
                        .lastStaked
                        .add(30 days);
                }
                user[msg.sender].lastRewardClaimed = user[msg.sender]
                    .lastRewardClaimed
                    .add(_rewardWeeks * 1 weeks);
                user[msg.sender].totalRewardsCollected = user[msg.sender]
                    .totalRewardsCollected
                    .add(_claimableRewards);
                token.transfer(msg.sender, _claimableRewards);
            }
        }
    }

    /**
     * @dev Total Stake Holders
     */
    function totalStakers() public view returns (uint256) {
        return stakeholders.length;
    }

    /**
     * @dev Returns stats. of Rewards
     * @param _address Address of User
     * @return _claimableRewards Total Claimable rewards until now.
     * @return _totalPendingRewards Total rewards pending.
     * @return _rewardsPerWeek Rewards accumulated per week.
     * @return _weeksPassed Total weeks Passed.
     */
    function getRewardStats(address _address)
        public
        view
        returns (
            uint256 _claimableRewards,
            uint256 _claimedRewards,
            uint256 _totalPendingRewards,
            uint256 _totalRewards,
            uint256 _rewardsPerWeek,
            uint256 _weeksPassed,
            uint256 _claimedWeeks,
            uint256 _rewardWeeks
        )
    {
        if (user[msg.sender].totalStaked == 0) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }
        uint256 daysPassed = (block.timestamp.sub(user[_address].lastStaked))
            .div(1 days);
        _weeksPassed = daysPassed.div(7);
        if (daysPassed > 30) {
            _rewardWeeks = (daysPassed.sub(30)).div(7);

            if (user[_address].lastRewardClaimed != 0) {
                uint256 diff = user[_address].lastRewardClaimed.sub(
                    user[_address].lastStaked
                );
                _claimedWeeks = ((diff.div(1 days)).sub(30)).div(7);
            }
            _rewardWeeks = _rewardWeeks.sub(_claimedWeeks);
        }
        _rewardsPerWeek = (
            (apy.mul(10**18).div(36500)).mul(7).mul(user[_address].totalStaked)
        ).div(10**18);
        _totalRewards = _weeksPassed.mul(_rewardsPerWeek);

        _claimableRewards = _rewardWeeks.mul(_rewardsPerWeek);
        _claimedRewards = _claimedWeeks.mul(_rewardsPerWeek);

        _totalPendingRewards = _rewardsPerWeek.mul(
            _weeksPassed.sub(_claimedWeeks)
        );

        return (
            _claimableRewards,
            _claimedRewards,
            _totalPendingRewards,
            _totalRewards,
            _rewardsPerWeek,
            _weeksPassed,
            _claimedWeeks,
            _rewardWeeks
        );
    }

    /**
     * @dev Get User Stats
     * @param _address Address of User
     */
    function getUserStats(address _address)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalStakedByUser = user[_address].totalStaked;
        uint256 stakedOn = user[_address].lastStaked;
        uint256 lastRewardsWithdrawn = user[_address].lastRewardClaimed;
        uint256 lastWeekWithdrawn;

        (, , , , , , lastWeekWithdrawn, ) = getRewardStats(msg.sender);

        uint256 totalRewardsInAYear = ((apy.mul(10**18)).div(100))
            .mul(totalStaked)
            .div(10**18);

        return (
            totalStakedByUser,
            stakedOn,
            lastRewardsWithdrawn,
            lastWeekWithdrawn,
            totalRewardsInAYear
        );
    }
}