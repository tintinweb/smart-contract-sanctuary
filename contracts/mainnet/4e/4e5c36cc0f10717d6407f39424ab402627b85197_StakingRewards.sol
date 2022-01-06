// SPDX-License-Identifier: BUSL-1.1

// Based on: https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Inheritance
import "./Owned.sol";

contract StakingRewards is Owned {
    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    // Address who can configure reward strategy
    address public rewardsDistribution;

    // Timestamp when the reward period is over. It can be extended with extendPeriod function
    uint256 public periodFinish;

    // Timestamp when the lock period is over. After this participants can take out their stake without penalty. Also the rewards are unlocked by month.
    // This period CANNOT be extended with the extendPeriod function
    uint256 public lockPeriodFinish;

    // Total token reward / period duration (seconds)
    uint256 public rewardRate;

    // Specifies the length of the time window in which rewards will be provided to stakers (seconds).
    uint256 public rewardsDuration;

    // Timestamp which specifies last time the reward has been updated during staking period
    uint256 public lastUpdateTime;

    // Reward per token stored with last reward update
    uint256 public rewardPerTokenStored;

    // Penalty that staker has to pay when it unstakes its tokens before lockPeriodFinish is finished
    uint256 public withdrawPenalty;

    // The total amount of rewards paid out
    uint256 public totalRewardsPaid;

    // The total amount of rewards lost due to unstaking before lockPeriodFinish
    uint256 public totalRewardsLost;

    // Mapping of last reward per tokens stored per user, updated when user stakes, withdraws or get its rewards
    mapping(address => uint256) public userRewardPerTokenPaid;

    // Mapping of rewards per user, updated with updateReward modifier. Do not use to calculated rewards so far, use earned function instead
    mapping(address => uint256) public rewards;

    // Mapping of rewards paid out so far per user.
    mapping(address => uint256) public rewardsPaid;

    // Total balance how much has been staked by the users
    uint256 public balance;

    // Mapping of staking balance per user
    mapping(address => uint256) public balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration,
        uint256 _withdrawPenalty
    ) Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        withdrawPenalty = _withdrawPenalty;
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // True if staking time window has past
    function isPeriodFinished() public view returns (bool) {
        return block.timestamp > periodFinish;
    }

    // Current reward per token per second
    function rewardPerToken() public view returns (uint256) {
        if (balance == 0) {
            return rewardPerTokenStored;
        }
        return (rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) /
            balance);
    }

    // Total amount of staking rewards earned by account
    function earned(address account) public view returns (uint256) {
        uint256 _rewardPerToken = rewardPerToken();
        return
            ((balances[account] *
                (_rewardPerToken - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    // Function for UI to retrieve the unlocked rewards
    function unlockedRewards(address account) public view returns (uint256) {
        return _calculateUnlocked(earned(account)) - rewardsPaid[account];
    }

    /* ========== PRIVATE VIEWS ========== */

    // Calculate how much of amount is unlocked based on current block and lockPeriod
    function _calculateUnlocked(uint256 amount) private view returns (uint256) {
        if (block.timestamp <= lockPeriodFinish) {
            return 0;
        }
        return ((amount / 12) *
            ((block.timestamp - lockPeriodFinish) / 30 days));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Stake amount in contract
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "412: cannot stake 0");
        balance += amount;
        balances[msg.sender] += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Withdraw stake, note that after period is finished the caller can only withdraw its full stake
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "412: cannot withdraw 0");

        uint256 penalty;
        // before lockPeriodFinish there is a penalty
        if (block.timestamp < lockPeriodFinish) {
            require(amount == balances[msg.sender], "412: amount not valid");
            penalty = (amount / 100) * withdrawPenalty;
            // remove the penalty from the user amount to transfer
            balance -= amount;
            amount -= penalty;
            totalRewardsLost += rewards[msg.sender];
            rewards[msg.sender] = 0;
            balances[msg.sender] = 0;
            // transfer the user lost token to the contract owner
            stakingToken.transfer(owner, penalty);
        } else {
            require(amount <= balances[msg.sender], "412: amount too high");
            balance -= amount;
            balances[msg.sender] -= amount;
        }

        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, penalty);
    }

    // Withdraw all unlocked rewards
    function getReward() public updateReward(msg.sender) {
        uint256 reward = _calculateUnlocked(rewards[msg.sender]) -
            rewardsPaid[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] -= reward;
            rewardsPaid[msg.sender] += reward;
            totalRewardsPaid += reward;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // User exits the staking
    function exit() external {
        withdraw(balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // start the period and set the amount of the total reward
    function startPeriod(uint256 reward)
        external
        onlyRewardsDistribution
        updateReward(address(0))
    {
        require(periodFinish == 0, "412: contract already started");
        rewardRate = reward / rewardsDuration;

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 currentBalance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= currentBalance / rewardsDuration,
            "412: reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        //Set the lock period time. Note this cannot be updated
        lockPeriodFinish = periodFinish;
        emit RewardSet(reward);
    }

    // Update the amount of reward to be devided over the remaining staking time.
    function updateRewardAmount(uint256 reward)
        external
        onlyBeforePeriodFinish
        onlyRewardsDistribution
        updateReward(address(0))
    {
        uint256 remaining = periodFinish - block.timestamp;
        uint256 leftover = remaining * rewardRate;
        rewardRate = (reward + leftover) / remaining;

        uint256 currentbalance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= (currentbalance / rewardsDuration),
            "412: reward too high"
        );

        emit RewardSet(reward);
    }

    // Extend the staking window. Note that the penalty will be not applicable in the extended time.
    function extendPeriod(uint256 extendTime)
        external
        onlyBeforePeriodFinish
        onlyRewardsDistribution
        updateReward(address(0))
    {
        // leftover reward tokens left
        uint256 remaining = periodFinish - block.timestamp;
        uint256 leftover = remaining * rewardRate;
        // extend the period
        periodFinish += extendTime;
        rewardsDuration += extendTime;
        // calculate remaining time
        remaining = periodFinish - block.timestamp;
        // new rewardRate
        rewardRate = leftover / remaining;

        uint256 currentbalance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= currentbalance / rewardsDuration,
            "412: reward too high"
        );

        emit PeriodExtend(periodFinish);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        if (tokenAddress == address(stakingToken)) {
            require(block.timestamp > periodFinish, "412: period not finished");
            // verify that the amount of entitled rewards are not transfered out.
            //
            // When the period is finished, as owner can take everything out, except of the balances that is owed to stakers.
            // Should not be possible for us to take out tokens which are entitled to stakers.
            // total token staken by the user + total rewards - rewards paid
            uint256 usersTokens = ((rewardRate * rewardsDuration) +
                balance -
                totalRewardsPaid) - totalRewardsLost;

            uint256 contractTokensBalance = IERC20(tokenAddress).balanceOf(
                address(this)
            );

            // owner cannot tranfer user balance and rewards
            require(
                (contractTokensBalance - usersTokens) >= tokenAmount,
                "412: amount to high"
            );
        }
        IERC20(tokenAddress).transfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    // Delegate restrictive function to new address
    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== MODIFIERS ========== */

    // Save in rewards the tokens earned
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Restrict admin function
    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution || msg.sender == owner,
            "401: not allowed"
        );
        _;
    }

    // Only when contract is still within active staking time window.
    modifier onlyBeforePeriodFinish() {
        require(block.timestamp < periodFinish, "412: period is finished");
        _;
    }

    /* ========== EVENTS ========== */

    // Reward has been set
    event RewardSet(uint256 indexed reward);

    // Period is extended
    event PeriodExtend(uint256 indexed periodEnds);

    // New staking participant
    event Staked(address indexed user, uint256 amount);

    // Participant has withdrawn part or full stake
    event Withdrawn(address indexed user, uint256 amount, uint256 penalty);

    // Reward has been paid out
    event RewardPaid(address indexed user, uint256 reward);

    // recovered all token from contract
    event Recovered(address indexed token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;

    constructor(address _owner)  {
        require(_owner != address(0), "400: invalid owner");
        owner = _owner;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "401: not owner");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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