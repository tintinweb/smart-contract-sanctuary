/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.6.0;


// SPDX-License-Identifier: MIT
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
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal {
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
/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable {
    IERC20 public token;
    bool private _isTokenRescuable;

    constructor(IERC20 _token) public {
        token = _token;
        _isTokenRescuable = false;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function setRescuable(bool rescuable) public onlyOwner {
        _isTokenRescuable = rescuable;
    }

    function transfer(address to, uint256 value)
        external
        onlyOwner
        returns (bool)
    {
        return token.transfer(to, value);
    }

    function rescueFunds(
        address tokenToRescue,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        if (!_isTokenRescuable) {
            require(
                address(token) != tokenToRescue,
                "TokenPool: Cannot claim token held by the contract"
            );
        }

        return IERC20(tokenToRescue).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
/**
 * @title IOU vesting interface
 */
interface IIouVesting {
    /**
     * @dev Get current rewards amount for sender
     * @param includeForfeited Include forfeited amount of other users who unstaked early
     */
    function getCurrentRewards(bool includeForfeited)
        external
        view
        returns (uint256);

    /**
     * @dev Get the total possible rewards, without forfeited rewards, if user stakes for the entire period
     * @param includeForfeited Include forfeited amount of other users who unstaked early
     */
    function getTotalPossibleRewards(bool includeForfeited)
        external
        view
        returns (uint256);

    /**
     * @dev Used for burning user shares and withdrawing rewards based on the requested amount
     * @param amount The amount of IOU you want to burn and get rewards for
     * @param donationRatio The percentage ratio you want to donate (in 18 decimals; 0.15 * 10^18)
     */
    function unstake(uint256 amount, uint256 donationRatio) external;

    /**
     * @dev Used for adding user's shares into IouVesting contract
     * @param amount The amount you want to stake
     */
    function stake(uint256 amount) external;

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() external view returns (uint256);

    /**
     * @return The total number of IOUs locked in the contract
     */
    function totalLocked() external view returns (uint256);

    /**
     * @return The total number of IOUs staked by user.
     */
    function totalStakedFor(address user) external view returns (uint256);

    /**
     * @return The total number of rewards tokens.
     */
    function totalRewards() external view returns (uint256);

    /**
     * @return Total earnings for a user
     */
    function getEarnings(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/**
 * @title IOU vesting contract
 */
contract IouVesting is IIouVesting, Ownable {
    using SafeMath for uint256;

    uint256 public startTimestamp;
    uint256 public availableForfeitedAmount;
    uint256 public totalUsers = 0;

    uint256 public constant ratio = 1449697206000000; //0.001449697206
    uint256 public constant totalMonths = 6;

    address public donationAddress;

    mapping(address => uint256) userShares;
    mapping(address => uint256) userEarnings;

    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDonated(address indexed user, uint256 amount);
    event TokensLocked(address indexed user, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 total);

    TokenPool private _iouPool;
    TokenPool private _lockedIouPool;
    TokenPool private _rewardsPool;

    /**
     * @param iouToken The token users deposit as stake.
     * @param rewardToken The token users receive as they unstake.
     */
    constructor(IERC20 iouToken, IERC20 rewardToken) public {
        startTimestamp = block.timestamp;
        availableForfeitedAmount = 0;
        _iouPool = new TokenPool(iouToken);
        _lockedIouPool = new TokenPool(iouToken);
        _rewardsPool = new TokenPool(rewardToken);
        _rewardsPool.setRescuable(true);
    }

    function setDonationAddress(address donationReceiver) external onlyOwner {
        donationAddress = donationReceiver;
    }

    /**
     * @dev Rescue rewards
     */
    function rescueRewards() external onlyOwner {
        require(_rewardsPool.balance() > 0, "IouVesting: Nothing to rescue");
        require(
            _rewardsPool.transfer(msg.sender, _rewardsPool.balance()),
            "IouVesting: rescue rewards from rewards pool failed"
        );
    }

    /**
     * @dev Get current rewards amount for sender
     * @param includeForfeited Include forfeited amount of other users who unstaked early
     */
    function getCurrentRewards(bool includeForfeited)
        public
        view
        override
        returns (uint256)
    {
        require(
            msg.sender != address(0),
            "IouVesting: Cannot get rewards for address(0)."
        );

        require(
            userShares[msg.sender] != uint256(0),
            "IouVesting: Sender hasn't staked anything."
        );

        return computeRewards(msg.sender, includeForfeited);
    }

    /**
     * @return The token users deposit as stake.
     */
    function getStakingToken() public view returns (IERC20) {
        return _iouPool.token();
    }

    /**
     * @return The token users deposit as stake.
     */
    function getRewardToken() public view returns (IERC20) {
        return _rewardsPool.token();
    }

    /**
     * @return Total earnings for a user
     */
    function getEarnings(address user) public view override returns (uint256) {
        return userEarnings[user];
    }

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() public view override returns (uint256) {
        return _iouPool.balance();
    }

    /**
     * @return The total number of IOUs locked in the contract
     */
    function totalLocked() public view override returns (uint256) {
        return _lockedIouPool.balance();
    }

    /**
     * @return The total number of IOUs staked by user.
     */
    function totalStakedFor(address user)
        public
        view
        override
        returns (uint256)
    {
        return userShares[user];
    }

    /**
     * @return The total number of rewards tokens.
     */
    function totalRewards() public view override returns (uint256) {
        return _rewardsPool.balance();
    }

    /**
     * @dev Lets the owner rescue funds air-dropped to the staking pool.
     * @param tokenToRescue Address of the token to be rescued.
     * @param to Address to which the rescued funds are to be sent.
     * @param amount Amount of tokens to be rescued.
     * @return Transfer success.
     */
    function rescueFundsFromStakingPool(
        address tokenToRescue,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        return _iouPool.rescueFunds(tokenToRescue, to, amount);
    }

    /**
     * @dev Get the total possible rewards, without forfeited rewards, if user stakes for the entire period
     * @param includeForfeited Include forfeited amount of other users who unstaked early
     */
    function getTotalPossibleRewards(bool includeForfeited)
        external
        view
        override
        returns (uint256)
    {
        return computeUserTotalPossibleRewards(msg.sender, includeForfeited);
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) private view returns (uint256) {
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function computeUserTotalPossibleRewards(
        address user,
        bool includeForfeited
    ) private view returns (uint256) {
        uint256 originalAmount = (userShares[user] * ratio) / (10**18);
        if (!includeForfeited) return originalAmount;

        uint256 shareVsTotalStakedRatio =
            getRatio(userShares[user], totalStaked(), 18);
        uint256 forfeitedAmount =
            (shareVsTotalStakedRatio * availableForfeitedAmount) / (10**18);

        return originalAmount.add(forfeitedAmount);
    }

    /**
     * @dev Get current rewards amount for sender
     * @param user The address of the user you want to calculate rewards for
     * @param includeForfeited Include forfeited amount of other users who unstaked early
     */
    function computeRewards(address user, bool includeForfeited)
        private
        view
        returns (uint256)
    {
        uint256 nowTimestamp = block.timestamp;
        uint256 endTimestamp = startTimestamp + (totalMonths * 30 days);
        if (nowTimestamp > endTimestamp) {
            nowTimestamp = endTimestamp;
        }

        uint256 stakingMonths =
            (nowTimestamp - startTimestamp) / 60 / 60 / 24 / 30; //months
        if (stakingMonths == uint256(0)) {
            //even if 1 second has passed, it's counted as 1 month
            stakingMonths = 1;
        }

        if (includeForfeited) {
            uint256 totalUserPossibleReward =
                computeUserTotalPossibleRewards(user, true);

            return (totalUserPossibleReward * stakingMonths) / totalMonths;
        } else {
            uint256 totalUserPossibleRewardWithoutForfeited =
                computeUserTotalPossibleRewards(user, false);
            uint256 rewardsWithoutForfeited =
                ((totalUserPossibleRewardWithoutForfeited * stakingMonths) /
                    totalMonths);

            if (!includeForfeited) return rewardsWithoutForfeited;
        }
    }

    /**
     * @dev Used for adding the necessary warp tokens amount based on the IOU's token total supply at the given ratio
     * @param iouToken The address of the IOU token
     * @param amount The amount you want to lock into the rewards pool
     */
    function lockTokens(IERC20 iouToken, uint256 amount) external {
        //11333
        uint256 supply = iouToken.totalSupply();
        uint256 necessaryRewardSupply = (supply * ratio) / (10**18);

        require(
            amount >= necessaryRewardSupply,
            "IouVesting: The amount provided for locking is not right"
        );

        require(
            _rewardsPool.token().transferFrom(
                msg.sender,
                address(_rewardsPool),
                amount
            ),
            "TokenGeyser: transfer into locked pool failed"
        );

        emit TokensLocked(msg.sender, amount);
    }

    /**
     * @dev Used for burning user shares and withdrawing rewards based on the requested amount
     * @param amount The amount of IOU you want to burn and get rewards for
     * @param donationRatio The percentage ratio you want to donate (in 18 decimals; 0.15 * 10^18)
     */
    function unstake(uint256 amount, uint256 donationRatio) external override {
        require(
            amount > uint256(0),
            "IouVesting: Unstake amount needs to be greater than 0"
        );
        require(
            userShares[msg.sender] != uint256(0),
            "IouVesting: There is nothing to unstake for you"
        );

        require(
            userShares[msg.sender] >= amount,
            "IouVesting: You cannot unstake more than you staked"
        );

        require(
            donationRatio <= uint256(100),
            "IouVesting: You cannot donate more than you earned"
        );

        uint256 amountVsSharesRatio =
            getRatio(amount, userShares[msg.sender], 18);
        uint256 totalUserPossibleRewards =
            (computeUserTotalPossibleRewards(msg.sender, false) *
                amountVsSharesRatio) / (10**18);

        uint256 totalCurrentUserRewards =
            (getCurrentRewards(true) * amountVsSharesRatio) / (10**18);

        //in case rewards were rescued
        if (totalRewards() > 0) {
            uint256 donationAmount = 0;
            if (donationAddress != address(0) && donationRatio > 0) {
                donationAmount =
                    (donationRatio * totalCurrentUserRewards) /
                    (10**18);
            }

            uint256 toTransferToUser = totalCurrentUserRewards;
            if (donationAmount > 0) {
                toTransferToUser = totalCurrentUserRewards - donationAmount;
                require(
                    _rewardsPool.transfer(donationAddress, donationAmount),
                    "IouVesting: transfer from rewards pool to donation receiver failed"
                );
            }

            require(
                _rewardsPool.transfer(msg.sender, toTransferToUser),
                "IouVesting: transfer from rewards pool failed"
            );
            emit RewardsClaimed(msg.sender, toTransferToUser);
            emit RewardsDonated(msg.sender, donationAmount);

            userEarnings[msg.sender] += totalCurrentUserRewards;

            availableForfeitedAmount += (totalUserPossibleRewards -
                totalCurrentUserRewards);
        }

        require(
            _iouPool.transfer(address(_lockedIouPool), amount),
            "IouVesting: transfer from iou pool to locked iou pool failed"
        );

        userShares[msg.sender] -= amount;
        if (userShares[msg.sender] == uint256(0)) {
            totalUsers--;
        }
    }

    /**
     * @dev Used for adding user's shares into IouVesting contract
     * @param amount The amount you want to stake
     */
    function stake(uint256 amount) external override {
        require(amount > 0, "IouVesting: You cannot stake 0");
        require(
            _rewardsPool.balance() > 0,
            "IouVesting: No rewards are available"
        );

        require(
            _iouPool.token().transferFrom(
                msg.sender,
                address(_iouPool),
                amount
            ),
            "IouVesting: transfer into iou pool failed"
        );

        if (userShares[msg.sender] == uint256(0)) {
            totalUsers++;
        }
        userShares[msg.sender] += amount;

        emit TokensStaked(msg.sender, amount, totalStaked());
    }
}