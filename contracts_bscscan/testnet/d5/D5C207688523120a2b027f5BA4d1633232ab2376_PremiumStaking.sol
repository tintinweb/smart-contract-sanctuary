// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PremiumStaking {
	using SafeMath for uint256;
	uint256 public constant PRECISION = 10_000_000;
	uint256 public constant SECONDS_IN_YEAR = 365 days;

	mapping(address => uint256) private _stakes;

	string public name;
	address public tokenAddress;
	uint256 public stakingStarts;
	uint256 public stakingEnds;
	uint256 public withdrawStarts;
	uint256 public withdrawEnds;
	uint256 public stakedTotal;
	uint256 public stakingCap;
	uint256 public totalReward;
	uint256 public earlyWithdrawReward;
	uint256 public rewardBalance;
	uint256 public stakedBalance;
	uint256 public stakingOpened;

	ERC20 public ERC20Interface;
	event Staked(
		address indexed token,
		address indexed staker_,
		uint256 requestedAmount_,
		uint256 stakedAmount_
	);
	event PaidOut(
		address indexed token,
		address indexed staker_,
		uint256 amount_,
		uint256 reward_
	);
	event Refunded(address indexed token, address indexed staker_, uint256 amount_);

	/**
	 */
	constructor(
		string memory name_,
		address tokenAddress_,
		uint256 stakingStarts_,
		uint256 stakingEnds_,
		uint256 withdrawStarts_,
		uint256 withdrawEnds_,
		uint256 stakingCap_
	) {
		name = name_;
		require(tokenAddress_ != address(0), "PremiumStaking: 0 address");
		tokenAddress = tokenAddress_;

		require(stakingStarts_ > 0, "PremiumStaking: zero staking start time");
		if (stakingStarts_ < block.timestamp) {
			stakingStarts = block.timestamp;
		} else {
			stakingStarts = stakingStarts_;
		}

		require(
			stakingEnds_ > stakingStarts,
			"PremiumStaking: staking end must be after staking starts"
		);
		stakingEnds = stakingEnds_;

		require(
			withdrawStarts_ >= stakingEnds,
			"PremiumStaking: withdrawStarts must be after staking ends"
		);
		withdrawStarts = withdrawStarts_;

		require(
			withdrawEnds_ > withdrawStarts,
			"PremiumStaking: withdrawEnds must be after withdraw starts"
		);
		withdrawEnds = withdrawEnds_;

		require(stakingCap_ > 0, "PremiumStaking: stakingCap must be positive");
		stakingCap = stakingCap_;

		stakingOpened = 2 weeks;
	}
	
	/// @notice returns APY% with 10**5 precision
	function getAPY() public view returns(uint256 APY) {
		uint256 stakingDuration = stakingEnds.sub(stakingStarts);

		APY = totalReward
			.mul(PRECISION)
			.div(stakingCap)
			.mul(SECONDS_IN_YEAR)
			.div(stakingDuration);
	}

	/// @notice returns earned tokens by user with 10**5 precision
	function earned(address staker) external view returns(uint256 reward) {
		uint256 stakedPeriod = block.timestamp.sub(stakingStarts);
		uint256 stakingDuration = stakingEnds.sub(stakingStarts);
		
		if (stakedPeriod < stakingDuration) {
			reward = stakeOf(staker)
				.mul(
					stakedPeriod
					.mul(totalReward.mul(PRECISION).div(stakingCap))
					.div(stakingDuration)
				)
				.div(PRECISION);
		} else {
			reward = totalReward.mul(stakeOf(staker)).div(stakingCap);
		}
	}

	function addReward(uint256 rewardAmount, uint256 withdrawableAmount)
		public
		_before(withdrawStarts)
		_hasAllowance(msg.sender, rewardAmount)
		returns (bool)
	{
		require(rewardAmount > 0, "PremiumStaking: reward must be positive");
		require(withdrawableAmount >= 0, "PremiumStaking: withdrawable amount cannot be negative");
		require(
			withdrawableAmount <= rewardAmount,
			"PremiumStaking: withdrawable amount must be less than or equal to the reward amount"
		);
		address from = msg.sender;
		if (!_payMe(from, rewardAmount)) {
			return false;
		}

		totalReward = totalReward.add(rewardAmount);
		rewardBalance = totalReward;
		earlyWithdrawReward = earlyWithdrawReward.add(withdrawableAmount);
		return true;
	}

	function stakeOf(address account) public view returns (uint256) {
		return _stakes[account];
	}

	/**
	 * Requirements:
	 * - `amount` Amount to be staked
	 */
	function stake(uint256 amount)
		public
		_positive(amount)
		_realAddress(msg.sender)
		returns (bool)
	{
		address from = msg.sender;
		return _stake(from, amount);
	}

	function withdraw(uint256 amount)
		public
		_after(withdrawStarts)
		_positive(amount)
		_realAddress(msg.sender)
		returns (bool)
	{
		address from = msg.sender;
		require(amount <= _stakes[from], "PremiumStaking: not enough balance");
		if (block.timestamp < withdrawEnds) {
			return _withdrawEarly(from, amount);
		} else {
			return _withdrawAfterClose(from, amount);
		}
	}

	function _withdrawEarly(address from, uint256 amount)
		private
		_realAddress(from)
		returns (bool)
	{
		// This is the formula to calculate reward:
		// r = (earlyWithdrawReward / stakedTotal) * (block.timestamp - stakingEnds) / (withdrawEnds - stakingEnds)
		// w = (1+r) * a
		uint256 denom = (withdrawEnds.sub(stakingEnds)).mul(stakedTotal);
		uint256 reward = (
			((block.timestamp.sub(stakingEnds)).mul(earlyWithdrawReward)).mul(amount)
		)
		.div(denom);
		uint256 payOut = amount.add(reward);
		rewardBalance = rewardBalance.sub(reward);
		stakedBalance = stakedBalance.sub(amount);
		_stakes[from] = _stakes[from].sub(amount);
		if (_payDirect(from, payOut)) {
			emit PaidOut(tokenAddress, from, amount, reward);
			return true;
		}
		return false;
	}

	function _withdrawAfterClose(address from, uint256 amount)
		private
		_realAddress(from)
		returns (bool)
	{
		uint256 reward = (rewardBalance.mul(amount)).div(stakedBalance);
		uint256 payOut = amount.add(reward);
		_stakes[from] = _stakes[from].sub(amount);
		if (_payDirect(from, payOut)) {
			emit PaidOut(tokenAddress, from, amount, reward);
			return true;
		}
		return false;
	}

	function _stake(address staker, uint256 amount)
		private
		_after(stakingStarts)
		_before(stakingStarts.add(stakingOpened))
		_positive(amount)
		_hasAllowance(staker, amount)
		returns (bool)
	{
		// check the remaining amount to be staked
		uint256 remaining = amount;
		if (remaining > (stakingCap.sub(stakedBalance))) {
			remaining = stakingCap.sub(stakedBalance);
		}
		// These requires are not necessary, because it will never happen, but won't hurt to double check
		// this is because stakedTotal and stakedBalance are only modified in this method during the staking period
		require(remaining > 0, "PremiumStaking: Staking cap is filled");
		require(
			(remaining + stakedTotal) <= stakingCap,
			"PremiumStaking: this will increase staking amount pass the cap"
		);
		if (!_payMe(staker, remaining)) {
			return false;
		}
		emit Staked(tokenAddress, staker, amount, remaining);

		if (remaining < amount) {
			// Return the unstaked amount to sender (from allowance)
			uint256 refund = amount.sub(remaining);
			if (_payTo(staker, staker, refund)) {
				emit Refunded(tokenAddress, staker, refund);
			}
		}

		// Transfer is completed
		stakedBalance = stakedBalance.add(remaining);
		stakedTotal = stakedTotal.add(remaining);
		_stakes[staker] = _stakes[staker].add(remaining);
		return true;
	}

	function _payMe(address payer, uint256 amount) private returns (bool) {
		return _payTo(payer, address(this), amount);
	}

	function _payTo(
		address allower,
		address receiver,
		uint256 amount
	) private _hasAllowance(allower, amount) returns (bool) {
		// Request to transfer amount from the contract to receiver.
		// contract does not own the funds, so the allower must have added allowance to the contract
		// Allower is the original owner.
		ERC20Interface = ERC20(tokenAddress);
		return ERC20Interface.transferFrom(allower, receiver, amount);
	}

	function _payDirect(address to, uint256 amount) private _positive(amount) returns (bool) {
		ERC20Interface = ERC20(tokenAddress);
		return ERC20Interface.transfer(to, amount);
	}

	modifier _realAddress(address addr) {
		require(addr != address(0), "PremiumStaking: zero address");
		_;
	}

	modifier _positive(uint256 amount) {
		require(amount >= 0, "PremiumStaking: negative amount");
		_;
	}

	modifier _after(uint256 eventTime) {
		require(block.timestamp >= eventTime, "PremiumStaking: bad timing for the request");
		_;
	}

	modifier _before(uint256 eventTime) {
		require(block.timestamp < eventTime, "PremiumStaking: bad timing for the request");
		_;
	}

	modifier _hasAllowance(address allower, uint256 amount) {
		// Make sure the allower has provided the right allowance.
		ERC20Interface = ERC20(tokenAddress);
		uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
		require(amount <= ourAllowance, "PremiumStaking: Make sure to add enough allowance");
		_;
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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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