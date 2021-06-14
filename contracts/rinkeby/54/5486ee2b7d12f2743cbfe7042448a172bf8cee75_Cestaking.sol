/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

// File: contracts/SafeMath.sol
pragma solidity 0.8.4;

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/Cestaking.sol

pragma solidity 0.8.4;




contract Cestaking is Ownable {
    using SafeMath for uint256;

    // season to stake records mapping
    mapping(uint256 => mapping(address => uint256)) stakes;
    // remaining balance of users in each season
    mapping(uint256 => mapping(address => uint256)) remainingBalance;

    uint256 currentActiveSeason;

    struct StakingSeason {
        address tokenAddress;
        uint256 stakingStarts;
        uint256 stakingEnds;
        uint256 withdrawStarts;
        uint256 withdrawEnds;
        uint256 stakedTotal;
        uint256 stakingCap;
        uint256 totalReward;
        uint256 earlyWithdrawReward;
        uint256 rewardBalance;
        uint256 stakedBalance;
    }

    StakingSeason[] stakingSeasons;

    function deleteLastSeason() external onlyOwner {
        require(
            stakingSeasons[stakingSeasons.length - 1].stakingStarts >
                block.timestamp,
            "Cestaking: cannot remove last added season after staking has started"
        );
        stakingSeasons.pop();
    }

    ERC20 public ERC20Interface;

    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 requestedAmount_,
        uint256 stakedAmount_,
        uint256 season
    );
    event PaidOut(
        address indexed token,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_,
        uint256 season
    );
    event Refunded(
        address indexed token,
        address indexed staker_,
        uint256 amount_,
        uint256 season
    );

    /**
     */
    function addSeason(
        address tokenAddress_,
        uint256 stakingStarts_,
        uint256 stakingEnds_,
        uint256 withdrawStarts_,
        uint256 withdrawEnds_,
        uint256 stakingCap_
    ) external onlyOwner {
        require(tokenAddress_ != address(0), "Cestaking: 0 address");

        require(
            stakingStarts_ >
                stakingSeasons[stakingSeasons.length - 1].withdrawEnds,
            "Cestaking: Next season must start after withdraw period of previous ends"
        );

        require(stakingStarts_ > 0, "Cestaking: zero staking start time");

        uint256 stakingStarts;

        if (stakingStarts_ < block.timestamp) {
            stakingStarts = block.timestamp;
        } else {
            stakingStarts = stakingStarts_;
        }

        require(
            stakingEnds_ > stakingSeasons[currentActiveSeason].stakingStarts,
            "Cestaking: staking end must be after staking starts"
        );

        require(
            withdrawStarts_ >= stakingSeasons[currentActiveSeason].stakingEnds,
            "Cestaking: withdrawStarts must be after staking ends"
        );

        require(
            withdrawEnds_ > stakingSeasons[currentActiveSeason].withdrawStarts,
            "Cestaking: withdrawEnds must be after withdraw starts"
        );

        require(stakingCap_ > 0, "Cestaking: stakingCap must be positive");

        stakingSeasons.push(
            StakingSeason({
                tokenAddress: tokenAddress_,
                stakingStarts: stakingStarts,
                stakingEnds: stakingEnds_,
                withdrawStarts: withdrawStarts_,
                withdrawEnds: withdrawEnds_,
                stakedTotal: 0,
                stakingCap: stakingCap_,
                totalReward: 0,
                earlyWithdrawReward: 0,
                rewardBalance: 0,
                stakedBalance: 0
            })
        );
    }

    // rewards would be added in current active season
    function addReward(uint256 rewardAmount, uint256 withdrawableAmount)
        public
        _before(stakingSeasons[currentActiveSeason].withdrawStarts)
        _hasAllowance(msg.sender, rewardAmount)
        _checkSeasonUpdate()
        returns (bool)
    {
        // require(stakingSeasons.length != 0, "Cestaking: No season exists");
        require(rewardAmount > 0, "Cestaking: reward must be positive");
        require(
            withdrawableAmount >= 0,
            "Cestaking: withdrawable amount cannot be negative"
        );
        require(
            withdrawableAmount <= rewardAmount,
            "Cestaking: withdrawable amount must be less than or equal to the reward amount"
        );
        address from = msg.sender;
        if (!_payMe(from, rewardAmount)) {
            return false;
        }

        stakingSeasons[currentActiveSeason].totalReward = stakingSeasons[
            currentActiveSeason
        ]
            .totalReward
            .add(rewardAmount);
        stakingSeasons[currentActiveSeason].rewardBalance = stakingSeasons[
            currentActiveSeason
        ]
            .totalReward;
        stakingSeasons[currentActiveSeason]
            .earlyWithdrawReward = stakingSeasons[currentActiveSeason]
            .earlyWithdrawReward
            .add(withdrawableAmount);
        return true;
    }

    function currentStakeOf(address account) public view returns (uint256) {
        return stakes[currentActiveSeason][account];
    }

    function stakeOf(address account, uint256 season)
        public
        view
        returns (uint256)
    {
        return stakes[season][account];
    }

    /**
     * Requirements:
     * - `amount` Amount to be staked
     */

    // stake will be added in current season
    function stake(uint256 amount)
        public
        _positive(amount)
        _realAddress(msg.sender)
        _checkSeasonUpdate()
        returns (bool)
    {
        address from = msg.sender;
        return _stake(from, amount);
    }

    function withdraw(uint256 amount)
        public
        _after(stakingSeasons[currentActiveSeason].withdrawStarts)
        _positive(amount)
        _realAddress(msg.sender)
        returns (bool)
    {
        address from = msg.sender;
        require(
            amount <= stakes[currentActiveSeason][from],
            "Cestaking: not enough balance"
        );
        if (
            block.timestamp < stakingSeasons[currentActiveSeason].withdrawEnds
        ) {
            return _withdrawEarly(from, amount);
        } else {
            return _withdrawAfterClose(from, amount, currentActiveSeason);
        }
    }

    function withdrawOldSeason(uint256 amount, uint256 season)
        external
        _after(stakingSeasons[season].withdrawStarts)
        _positive(amount)
        _realAddress(msg.sender)
        returns (bool)
    {
        address from = msg.sender;
        require(
            amount <= stakes[season][from],
            "Cestaking: not enough balance"
        );
        require(
            stakingSeasons.length - 1 > season,
            "Cestaking: Active season not allowed, use withdraw()"
        );
        require(
            block.timestamp > stakingSeasons[season].withdrawEnds,
            "Cestaking: Old season withdraw period not ended, use withdraw()"
        );

        return _withdrawAfterClose(from, amount, season);
    }

    function _withdrawEarly(address from, uint256 amount)
        private
        _realAddress(from)
        returns (bool)
    {
        // This is the formula to calculate reward:
        // r = (earlyWithdrawReward / stakedTotal) * (block.timestamp - stakingEnds) / (withdrawEnds - stakingEnds)
        // w = (1+r) * a
        uint256 denom =
            (
                stakingSeasons[currentActiveSeason].withdrawEnds.sub(
                    stakingSeasons[currentActiveSeason].stakingEnds
                )
            )
                .mul(stakingSeasons[currentActiveSeason].stakedTotal);
        uint256 reward =
            (
                (
                    (
                        block.timestamp.sub(
                            stakingSeasons[currentActiveSeason].stakingEnds
                        )
                    )
                        .mul(
                        stakingSeasons[currentActiveSeason].earlyWithdrawReward
                    )
                )
                    .mul(amount)
            )
                .div(denom);
        uint256 payOut = amount.add(reward);
        stakingSeasons[currentActiveSeason].rewardBalance = stakingSeasons[
            currentActiveSeason
        ]
            .rewardBalance
            .sub(reward);
        stakingSeasons[currentActiveSeason].stakedBalance = stakingSeasons[
            currentActiveSeason
        ]
            .stakedBalance
            .sub(amount);
        stakes[currentActiveSeason][from] = stakes[currentActiveSeason][from]
            .sub(amount);
        if (_payDirect(from, payOut)) {
            emit PaidOut(
                stakingSeasons[currentActiveSeason].tokenAddress,
                from,
                amount,
                reward,
                currentActiveSeason
            );
            return true;
        }
        return false;
    }

    function _withdrawAfterClose(
        address from,
        uint256 amount,
        uint256 season
    ) private _realAddress(from) returns (bool) {
        uint256 reward =
            (stakingSeasons[season].rewardBalance.mul(amount)).div(
                stakingSeasons[season].stakedBalance
            );
        uint256 payOut = amount.add(reward);
        stakes[season][from] = stakes[season][from].sub(amount);
        if (_payDirect(from, payOut)) {
            emit PaidOut(
                stakingSeasons[season].tokenAddress,
                from,
                amount,
                reward,
                season
            );
            return true;
        }
        return false;
    }

    function _stake(address staker, uint256 amount)
        private
        _after(stakingSeasons[currentActiveSeason].stakingStarts)
        _before(stakingSeasons[currentActiveSeason].stakingEnds)
        _positive(amount)
        _hasAllowance(staker, amount)
        returns (bool)
    {
        // check the remaining amount to be staked
        uint256 remaining = amount;
        if (
            remaining >
            (
                stakingSeasons[currentActiveSeason].stakingCap.sub(
                    stakingSeasons[currentActiveSeason].stakedBalance
                )
            )
        ) {
            remaining = stakingSeasons[currentActiveSeason].stakingCap.sub(
                stakingSeasons[currentActiveSeason].stakedBalance
            );
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal and stakedBalance are only modified in this method during the staking period
        require(remaining > 0, "Cestaking: Staking cap is filled");
        require(
            (remaining + stakingSeasons[currentActiveSeason].stakedTotal) <=
                stakingSeasons[currentActiveSeason].stakingCap,
            "Cestaking: this will increase staking amount pass the cap"
        );
        if (!_payMe(staker, remaining)) {
            return false;
        }
        emit Staked(
            stakingSeasons[currentActiveSeason].tokenAddress,
            staker,
            amount,
            remaining,
            currentActiveSeason
        );

        if (remaining < amount) {
            // Return the unstaked amount to sender (from allowance)
            uint256 refund = amount.sub(remaining);
            if (_payTo(staker, staker, refund)) {
                emit Refunded(
                    stakingSeasons[currentActiveSeason].tokenAddress,
                    staker,
                    refund,
                    currentActiveSeason
                );
            }
        }

        // Transfer is completed
        stakingSeasons[currentActiveSeason].stakedBalance = stakingSeasons[
            currentActiveSeason
        ]
            .stakedBalance
            .add(remaining);
        stakingSeasons[currentActiveSeason].stakedTotal = stakingSeasons[
            currentActiveSeason
        ]
            .stakedTotal
            .add(remaining);
        stakes[currentActiveSeason][staker] = stakes[currentActiveSeason][
            staker
        ]
            .add(remaining);
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
        ERC20Interface = ERC20(
            stakingSeasons[currentActiveSeason].tokenAddress
        );
        return ERC20Interface.transferFrom(allower, receiver, amount);
    }

    function _payDirect(address to, uint256 amount)
        private
        _positive(amount)
        returns (bool)
    {
        ERC20Interface = ERC20(
            stakingSeasons[currentActiveSeason].tokenAddress
        );
        return ERC20Interface.transfer(to, amount);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Cestaking: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount >= 0, "Cestaking: negative amount");
        _;
    }

    modifier _after(uint256 eventTime) {
        require(
            block.timestamp >= eventTime,
            "Cestaking: bad timing for the request"
        );
        _;
    }

    modifier _before(uint256 eventTime) {
        require(
            block.timestamp < eventTime,
            "Cestaking: bad timing for the request"
        );
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = ERC20(
            stakingSeasons[currentActiveSeason].tokenAddress
        );
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(
            amount <= ourAllowance,
            "Cestaking: Make sure to add enough allowance"
        );
        _;
    }

    modifier _checkSeasonUpdate() {
        if (
            block.timestamp >
            stakingSeasons[currentActiveSeason].withdrawEnds &&
            stakingSeasons.length - 1 > currentActiveSeason
        ) {
            currentActiveSeason += 1;
        }
        _;
    }
}