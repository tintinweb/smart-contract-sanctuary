// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title GreenHouse staking contract
 * @dev A stakable smart contract that stores ERC20 token.
 */
contract GreenHouse is Ownable {
    // Staking ERC20 token
    IERC20 public token;

    // All Users Stakes
    uint256 public allStakes = 0;
    uint256 public everStakedUsersCount = 0;

    // Bonus and Monthly Reward Pools
    uint256 public bonusRewardPool = 0;  // Bonus Reward Pool 
    uint256 public monthlyRewardPool = 0;  // Monthly Reward Pool
    mapping(address => uint256) public referralRewards;

    // Users stakes, withdrawals and users that has staked at least once
    mapping(address => uint256) internal _stakes;
    mapping(address => uint256) internal _withdrawals;
    mapping(address => bool) internal _hasStaked;

    // Reward calculation magic
    uint256 constant internal _magnitude = 2**128;
    uint256 internal _magnifiedRewardPerStake = 0; 
    mapping(address => int256) internal _magnifiedRewardCorrections;

    // Staking and Unstaking fees
    uint256 constant internal _feeAllUsersStakedPermille = 700;
    uint256 constant internal _feeBonusPoolPermille = 100;
    uint256 constant internal _feePlatformWalletPermille = 100;
    uint256 constant internal _feeReferalPermille = 50;
    uint256 constant internal _feePartnerWalletPermille = 50;

    // Monthly Pool distribution and timer
    uint256 constant internal _monthlyPoolDistributeAllUsersPercent = 50;
    uint256 constant internal _monthlyPoolTimer = 2592000; // 30 days
    uint256 internal _monthlyPoolLastDistributedAt;

    // Bonus Pool distribution 
    uint256 constant internal _bonusPoolDistributeAllUsersPercent = 40;
    uint256 constant internal _bonusPoolDistributeLeaderboardPercent = 40;

    // Bonus Pool Leaderboard queue
    mapping(uint256 => address) internal _bonusPoolLeaderboard;
    uint256 internal _bonusPoolLeaderboardFirst = 1;
    uint256 internal _bonusPoolLeaderboardLast = 0;
    uint256 constant internal _bonusPoolLeaderboardMaxUsersCount = 10;
    uint256 constant internal _bonusPoolMinStakeToQualify = 1000;

    // Bonus Timer settings
    uint256 internal _bonusPoolTimer;
    uint256 internal _bonusPoolLastDistributedAt;
    uint256 constant internal _bonusPoolNewStakeholderTimerAddition = 900;   // 15 minutes
    uint256 constant internal _bonusPoolTimerInitial = 21600; // 6 hours

    // Platform Team wallets
    address[] internal _platformWallets;
    // Partner wallet
    address   internal _partnerWallet;

    event Staked(address indexed sender, uint256 amount, address indexed referrer);
    event Unstaked(address indexed sender, uint256 amount);
    event RewardWithdrawn(address indexed sender, uint256 amount);
    event Restaked(address indexed sender, uint256 amount);
    event BonusRewardPoolDistributed(uint256 amountAllUsers, uint256 amountLeaderboard);
    event MonthlyRewardPoolDistributed(uint256 amount);

    /// @param token_ A ERC20 token to use in this contract
    /// @param partnerWallet A Partner's wallet to reward
    /// @param platformWallets List of Platform Team's wallets
    constructor(
        address token_, 
        address partnerWallet, 
        address[] memory platformWallets
    ) Ownable() {
        token = IERC20(token_);

        _platformWallets = platformWallets;
        _partnerWallet = partnerWallet;

        _bonusPoolTimer = _bonusPoolTimerInitial;

        _bonusPoolLastDistributedAt = block.timestamp;
        _monthlyPoolLastDistributedAt = block.timestamp;
    }

    modifier AttemptToDistrubuteBonusPools() {
        _maybeDistributeMonthlyRewardPool();
        _maybeDistributeBonusRewardPool();
        _;
    }

    // External functions 

    function stake(uint256 amount, address referrer) external AttemptToDistrubuteBonusPools {
        require(amount != 0, "GreenHouse: staking amount could not be zero");

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "GreenHouse: staking token transfer failed");

        if (!_hasStaked[msg.sender]) {
            _hasStaked[msg.sender] = true;
            everStakedUsersCount++;
            if (amount >= _bonusPoolMinStakeToQualify) {
                _bonusPoolProcessNewStakeholder(msg.sender);
            }
        }

        _processStake(amount, referrer);
        emit Staked(msg.sender, amount, referrer);
    }

    function unstake(uint256 amount) external AttemptToDistrubuteBonusPools {
        require(amount != 0, "GreenHouse: unstaking amount could not be zero");
        require(_stakes[msg.sender] >= amount, "GreenHouse: insufficient amount to unstake");

        (uint256 net, uint256 fee) = _applyFeesAndDistributeRewards(amount, address(0));
        _stakes[msg.sender] -= amount;

        bool success = token.transfer(msg.sender, net);
        require(success, "GreenHouse: unstaking token transfer failed");

        _magnifiedRewardCorrections[msg.sender] += SafeCast.toInt256(_magnifiedRewardPerStake * amount);
        _rewardAllUsersStaked(fee);
        allStakes -= amount;

        emit Unstaked(msg.sender, amount);
    }

    function restake() external AttemptToDistrubuteBonusPools {
        uint256 withdrawable = withdrawableRewardOf(msg.sender);
        require(withdrawable > 0, "GreenHouse: nothing to restake");
        _withdrawals[msg.sender] += withdrawable;

        _processStake(withdrawable, address(0));
        emit Restaked(msg.sender, withdrawable);
    }

    function withdrawReward() external AttemptToDistrubuteBonusPools {
        uint256 withdrawable = withdrawableRewardOf(msg.sender);
        require(withdrawable > 0, "GreenHouse: nothing to withdraw");
        bool success = token.transfer(msg.sender, withdrawable);
        require(success, "GreenHouse: withdrawal token transfer failed");
        _withdrawals[msg.sender] += withdrawable;

        emit RewardWithdrawn(msg.sender, withdrawable);
    }

    function bonusPoolLeaderboard() external view returns(address[] memory) {
        uint256 leaderboardUsersCount = _bonusPoolLeaderboardUsersCount();
        address[] memory leaderboard = new address[](leaderboardUsersCount);
        for (uint256 i = 0; i < leaderboardUsersCount; ++i) {
            leaderboard[i] = _bonusPoolLeaderboard[i + _bonusPoolLeaderboardFirst];
        }
        return leaderboard;
    }


    // External functions only owner

    function setPartnerWallet(address address_) external onlyOwner {
        _partnerWallet = address_;
    }

    function setPlatformWallets(address[] memory addresses) external onlyOwner {
        _platformWallets = addresses;
    }


    // Public view functions 

    function stakeOf(address stakeholder) public view returns(uint256) {
        return _stakes[stakeholder];
    }

    function accumulativeRewardOf(address stakeholder) public view returns(uint256) {
        return SafeCast.toUint256(SafeCast.toInt256(stakeOf(stakeholder) * _magnifiedRewardPerStake) 
                                  + _magnifiedRewardCorrections[stakeholder]) / _magnitude;
    }

    function withdrawnRewardOf(address stakeholder) public view returns(uint256) {
        return _withdrawals[stakeholder];
    }

    function withdrawableRewardOf(address stakeholder) public view returns(uint256) {
        return accumulativeRewardOf(stakeholder) - withdrawnRewardOf(stakeholder);
    }

    function bonusRewardPoolCountdown() public view returns(uint256) {
        uint256 timeSinceLastDistributed = block.timestamp - _bonusPoolLastDistributedAt;
        if (timeSinceLastDistributed >= _bonusPoolTimer) return 0;
        return _bonusPoolTimer - timeSinceLastDistributed;
    }

    function monthlyRewardPoolCountdown() public view returns(uint256) {
        uint256 timeSinceLastDistributed = block.timestamp - _monthlyPoolLastDistributedAt;
        if (timeSinceLastDistributed >= _monthlyPoolTimer) return 0;
        return _monthlyPoolTimer - timeSinceLastDistributed;
    }

    // internal functions

    /**
     @notice Adds new qualified staker to the Bonus Pool Leaderboard's queue
             and update Bonus Pool Timer
     @param stakeholder The address of a stakeholder
     */
    function _bonusPoolProcessNewStakeholder(address stakeholder) internal {
        _bonusPoolLeaderboardLast += 1;
        _bonusPoolLeaderboard[_bonusPoolLeaderboardLast] = stakeholder;
        _bonusPoolTimer += _bonusPoolNewStakeholderTimerAddition;

        if (_bonusPoolLeaderboardUsersCount() > _bonusPoolLeaderboardMaxUsersCount) {
            delete _bonusPoolLeaderboard[_bonusPoolLeaderboardFirst];
            _bonusPoolLeaderboardFirst += 1;
        }
    }

    function _bonusPoolLeaderboardUsersCount() internal view returns(uint256) {
        return _bonusPoolLeaderboardLast + 1 - _bonusPoolLeaderboardFirst;
    }

    function _transferRewardPartner(uint256 amount) internal {
        bool success = token.transfer(_partnerWallet, amount);
        require(success, "GreenHouse: failed to transfer reward to partner wallet");
    }

    function _transferRewardPlatform(uint256 amount) internal {
        uint256 perWallet = amount / _platformWallets.length;
        for (uint256 i = 0; i != _platformWallets.length; ++i) {
            bool success = token.transfer(_platformWallets[i], perWallet);
            require(success, "GreenHouse: failed to transfer reward to platform wallet");
        }
    }

    function _rewardAllUsersStaked(uint256 amount) internal {
        _magnifiedRewardPerStake += allStakes != 0 ? (_magnitude * amount) / allStakes : 0;
    }

    function _transferRewardReferral(uint256 amount, address referrer) internal {
        bool success = token.transfer(referrer, amount);
        require(success, "GreenHouse: failed to transfer referal reward");
        referralRewards[referrer] += amount;
    }

    function _rewardBonusPool(uint256 amount) internal {
        bonusRewardPool += amount;
    }

    function _rewardMonthlyPool(uint256 amount) internal {
        monthlyRewardPool += amount;
    }

    function _applyFeesAndDistributeRewards(uint256 amount, address referrer) 
        internal
        returns(uint256, uint256) 
    {
        uint256 fee = (amount * _feeAllUsersStakedPermille) / 10000;

        uint256 feeBonusPool = (amount * _feeBonusPoolPermille) / 10000;
        uint256 feePartnerWallet = (amount * _feePartnerWalletPermille) / 10000;
        uint256 feeReferral = (amount * _feeReferalPermille) / 10000;
        uint256 feePlatformWallet = (amount * _feePlatformWalletPermille) / 10000;

        _rewardBonusPool(feeBonusPool);
        _transferRewardPartner(feePartnerWallet);
        _transferRewardPlatform(feePlatformWallet);
        if (referrer == address(0)) _rewardMonthlyPool(feeReferral);
        else _transferRewardReferral(feeReferral, referrer);

        uint256 net = (amount 
                       - fee
                       - feeBonusPool 
                       - feePartnerWallet
                       - feePlatformWallet 
                       - feeReferral);

        return (net, fee);
    }

    function _processStake(uint256 amount, address referrer) internal {
        (uint256 net, uint256 fee) = _applyFeesAndDistributeRewards(amount, referrer);
        _stakes[msg.sender] += net;
        _hasStaked[msg.sender] = true;

        allStakes += net;
        _magnifiedRewardCorrections[msg.sender] -= SafeCast.toInt256(_magnifiedRewardPerStake * net);
        _rewardAllUsersStaked(fee);
    }

    function _maybeDistributeMonthlyRewardPool() internal {
        if (monthlyRewardPoolCountdown() == 0 && monthlyRewardPool != 0) {
            uint256 amountToDistribute = (monthlyRewardPool * _monthlyPoolDistributeAllUsersPercent) / 100;
            _rewardAllUsersStaked(amountToDistribute);
            _monthlyPoolLastDistributedAt = block.timestamp;
            emit MonthlyRewardPoolDistributed(amountToDistribute);
        }
    }

    function _maybeDistributeBonusRewardPool() internal {
        if (bonusRewardPoolCountdown() == 0 && bonusRewardPool != 0) {
            uint256 amountToDistributeAllUsers = (bonusRewardPool * _bonusPoolDistributeAllUsersPercent) / 100;
            _rewardAllUsersStaked(amountToDistributeAllUsers);

            uint256 leaderboardUsersCount = _bonusPoolLeaderboardUsersCount();
            uint256 amountToDistributeLeaderboard = 0;

            if (leaderboardUsersCount != 0) {
                amountToDistributeLeaderboard = (bonusRewardPool * _bonusPoolDistributeLeaderboardPercent) / 100;
                uint256 amountToDistributePerLeader = amountToDistributeLeaderboard / leaderboardUsersCount;

                require(amountToDistributePerLeader > 0, "GreenHouse: nothing to reward leaderboard");
                for (uint256 i = _bonusPoolLeaderboardFirst; i <= _bonusPoolLeaderboardLast; ++i) {
                    bool success = token.transfer(_bonusPoolLeaderboard[i], amountToDistributePerLeader);
                    require(success, "GreenHouse: failed to transfer bonus pool reward");
                }
            }

            _bonusPoolTimer = _bonusPoolTimerInitial;  // reset bonus pool timer
            bonusRewardPool -= amountToDistributeAllUsers + amountToDistributeLeaderboard;
            _bonusPoolLastDistributedAt = block.timestamp;
            emit BonusRewardPoolDistributed(amountToDistributeAllUsers, amountToDistributeLeaderboard);
        }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

