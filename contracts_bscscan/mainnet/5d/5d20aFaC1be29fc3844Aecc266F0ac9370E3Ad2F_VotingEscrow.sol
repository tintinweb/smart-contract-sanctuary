// SPDX-License-Identifier: GPL-2.0
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;
/*

    :::     :::::::::  :::::::::: :::::::::   ::::::::   ::::::::  :::    ::: :::::::::: ::::::::::: 
  :+: :+:   :+:    :+: :+:        :+:    :+: :+:    :+: :+:    :+: :+:   :+:  :+:            :+:     
 +:+   +:+  +:+    +:+ +:+        +:+    +:+ +:+    +:+ +:+        +:+  +:+   +:+            +:+     
+#++:++#++: +#++:++#+  +#++:++#   +#++:++#:  +#+    +:+ +#+        +#++:++    +#++:++#       +#+     
+#+     +#+ +#+        +#+        +#+    +#+ +#+    +#+ +#+        +#+  +#+   +#+            +#+     
#+#     #+# #+#        #+#        #+#    #+# #+#    #+# #+#    #+# #+#   #+#  #+#            #+#     
###     ### ###        ########## ###    ###  ########   ########  ###    ### ##########     ### 

* App:             https://aperocket.finance
* Medium:          https://aperocket.medium.com/
* Twitter:         https://twitter.com/aperocketfi
* Telegram:        https://t.me/aperocket
* GitHub:          https://github.com/aperocket-labs

 */

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable, SafeMathUpgradeable, IERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IMultiRewardsDistributionPool.sol";

/// @notice xSPACE
/// Rewrite of https://etherscan.io/address/0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2#code veCRV with multiple locks
contract VotingEscrow is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Flags
    uint256 private _unlocked;

    /// @notice Minimum lock duration (7 days)
    uint256 public constant MIN_DAYS = 7;

    /// @notice Maximum lock duration (100 weeks)
    uint256 public constant MAX_DAYS = 7 * 100;

    /// @notice Default duration
    uint256 public constant VESTING_DAYS = 91;

    /// @notice Convert days to time
    uint256 public constant MAX_TIME = MAX_DAYS * 1 days; // 4 years

    /// @notice 50 % of max withdrawal penalty (if you unlock before the end of the lock duration)
    uint256 public constant MAX_WITHDRAWAL_PENALTY = 5000; // 50%

    /// @notice Global variable used for mathematical rounding
    uint256 public constant PRECISION = 10000;

    /// @notice List of xSPACE minters
    mapping(address => bool) public minters;

    /// @notice Contracts allowed to deposit to
    mapping(address => bool) public whitelist;

    /// @notice Address of the locked token
    address public lockedToken;

    /// @notice Address of the reward distribution contract
    address public multiRewardsDistributionPool;

    /// @notice Address of the reward distribution contract
    uint256 public minLockedAmount;

    /// @notice Amount of the penalty fee
    /// In case of an emergency withdraw before the locked time
    uint256 public earlyWithdrawPenaltyRate;

    /// @param amount Amount of locked xSPACE
    /// @param end Locked ending
    /// @param vp Voting power
    struct LockedBalance {
        uint256 amount;
        uint256 end;
        uint256 vp;
    }

    /// @notice List of locked SPACE per address
    mapping(address => LockedBalance) public locked;

    /// @notice List of vested xSPACE per address
    mapping(address => LockedBalance[]) public vested;

    /// @notice xSPACE to be minted for Lock
    mapping(address => uint256) public mintedForLock;

    /// @notice xSPACE to be minted for Vest
    mapping(address => uint256) public mintedForVest;

    // Gap is left to avoid storage collisions.
    uint256[20] private ____gap;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier lock() {
        require(_unlocked == 1, "LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    modifier onlyWhitelisted() {
        _onlyWhitelisted();
        _;
    }

    modifier onlyWhitelistedOrEOA() {
        _onlyWhitelistedOrEOA();
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "only allowed minters");
        _;
    }

    /// @param _lockedToken Token locked (SPACE)
    /// @param _minLockedAmount Minimum amount of SPACE to lock
    function initialize(address _lockedToken, uint256 _minLockedAmount) external initializer {
        __ERC20_init("ApeRocket Locked SPACE", "xSPACE");
        __ReentrancyGuard_init();
        __Ownable_init();
        lockedToken = _lockedToken;
        earlyWithdrawPenaltyRate = 5000; // 50%
        minLockedAmount = _minLockedAmount;
        _unlocked = 1;
    }

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the SPACE locked
    /// @param _addr User address
    function lockedOf(address _addr) external view returns (LockedBalance memory) {
        return locked[_addr];
    }

    /// @notice Returns the end of the locking period
    /// @param _addr User address
    function lockedEnd(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    /// @notice Returns the current vested xSPACE
    /// @param _addr User address
    function vestedOf(address _addr) external view returns (LockedBalance[] memory) {
        return vested[_addr];
    }

    /// @notice Returns the total vested xSPACE
    /// @param _addr User address
    function totalVested(address _addr) public view returns (uint256 total) {
        uint256 length = vested[_addr].length;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = vested[_addr][i].amount;
            if (amount == 0) continue;
            total = total.add(amount);
        }
    }

    /// @notice Returns the SPACE that can be withdrawn
    /// @param _addr User address
    function withdrawableBalance(address _addr) public view returns (uint256 amount, uint256 penalty) {
        uint256 length = vested[_addr].length;
        for (uint256 i = 0; i < length; i++) {
            uint256 vestedAmount = vested[_addr][i].amount;
            if (vestedAmount == 0) continue;
            if (vested[_addr][i].end > block.timestamp) {
                break;
            }
            amount = amount.add(vestedAmount);
        }
        penalty = amount.div(2);
        return (amount, penalty);
    }

    /// @notice returns the voting power accumulated up to the unlock time
    /// VP = value * seconds left before the unlock
    /// @param _value Value of xSPACE
    /// @param _unlock_time Unlock time block (timestamp)
    function votingPowerUnlockTime(uint256 _value, uint256 _unlock_time) public view returns (uint256) {
        uint256 _now = block.timestamp;
        if (_unlock_time <= _now) return 0;
        uint256 _lockedSeconds = _unlock_time - _now;
        if (_lockedSeconds >= MAX_TIME) {
            return _value;
        }
        return (_value * _lockedSeconds) / MAX_TIME;
    }

    /// @notice  Returns voting power based on value and number of blocked days.
    /// @param _value Value of xSPACE
    /// @param _days Number of days
    function votingPowerLockedDays(uint256 _value, uint256 _days) public pure returns (uint256) {
        if (_days >= MAX_DAYS) {
            return _value;
        }
        return (_value * _days) / MAX_DAYS;
    }

    /*///////////////////////////////////////////////////////////////
                        WHITELISTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit SPACE into the xSPACE contract
    /// Using internal _deposit function
    /// The locked period are retrieved in the _depositTo function, and are set by createLock in this case
    /// @param _addr User address
    /// @param _value Amount of SPACE to deposit
    function depositTo(address _addr, uint256 _value) external onlyWhitelisted {
        require(_value >= minLockedAmount, "less than min amount");
        _depositTo(_addr, _value, 0);
    }

    /// @notice Mint SPACE based on voting power
    /// Using internal _mint function
    /// Retrieving the vested balance
    /// @param _addr User address
    /// @param _value Amount of SPACE to deposit
    function mintTo(address _addr, uint256 _value) external onlyMinter {
        LockedBalance[] storage _vested = vested[_addr];
        uint256 i = _vested.length;
        uint256 end = block.timestamp.div(604800).mul(604800).add(VESTING_DAYS * 1 days); // Rounded down to weeks
        uint256 _vp = votingPowerLockedDays(_value, VESTING_DAYS);

        if (i == 0 || _vested[i - 1].end < end) {
            _vested.push(LockedBalance({amount: _value, end: end, vp: _vp}));
        } else {
            _vested[i - 1].amount = _vested[i - 1].amount.add(_value);
            _vested[i - 1].vp = _vested[i - 1].vp.add(_vp);
        }

        require(_vp > 0, "No benefit to lock");

        if (_value > 0) {
            IERC20Upgradeable(lockedToken).safeTransferFrom(msg.sender, address(this), _value);
            _mint(_addr, _vp);
            mintedForVest[_addr] = mintedForVest[_addr].add(_vp);
            emit Deposit(_addr, _value, end, block.timestamp);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Lock an amount of SPACE for a specified amount of days
    /// The lock function is handled separetely of the deposit and mint function
    /// @param _value Amount of space to lock
    /// @param _days Number of locked days
    function createLock(uint256 _value, uint256 _days) external onlyWhitelistedOrEOA {
        require(_value >= minLockedAmount, "less than min amount");
        require(locked[msg.sender].amount == 0, "Withdraw old tokens first");
        require(_days >= MIN_DAYS, "Voting lock can be 7 days min");
        require(_days <= MAX_DAYS, "Voting lock can be 100 weeks max");
        _depositTo(msg.sender, _value, _days);
    }

    /// @notice Add a specified amount of SPACE to an existant balance
    /// In case the user want to increase his balance
    /// This deposit is not locked
    /// @param _value Value of SPACE to add
    function increaseAmountLocked(uint256 _value) external onlyWhitelistedOrEOA {
        require(_value >= minLockedAmount, "less than min amount");
        _depositTo(msg.sender, _value, 0);
    }

    /// @notice Increase the caller's balance locking time
    /// Using the internal _depositTo function
    /// @param _days Number of days to add
    function increaseUnlockTime(uint256 _days) external onlyWhitelistedOrEOA {
        require(_days >= MIN_DAYS, "Voting lock can be 7 days min");
        require(_days <= MAX_DAYS, "Voting lock can be 100 weeks max");
        _depositTo(msg.sender, 0, _days);
    }

    /// @notice The withdraw function, can be used by any user
    /// Impossible to withdraw before the end of the locking time
    function withdraw() external nonReentrant lock {
        LockedBalance storage _locked = locked[msg.sender];
        uint256 _now = block.timestamp;
        require(_locked.amount > 0, "Nothing to withdraw");
        require(_now >= _locked.end, "The lock didn't expire");
        uint256 _amount = _locked.amount;
        _locked.end = 0;
        _locked.amount = 0;
        _locked.vp = 0;
        _burn(msg.sender, mintedForLock[msg.sender]);
        mintedForLock[msg.sender] = 0;
        IERC20Upgradeable(lockedToken).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount, _now);
    }

    /// @notice Emergency Withdraw function
    /// Can be used to withdraw locked tokens, but with penalties applied.
    /// Penalty retained = Amount of SPACE * penalty rate (defined in the constructor , base = 50 %)
    function emergencyWithdraw() external nonReentrant lock {
        LockedBalance storage _locked = locked[msg.sender];
        uint256 _now = block.timestamp;
        require(_locked.amount > 0, "Nothing to withdraw");
        uint256 _amount = _locked.amount;
        if (_now < _locked.end) {
            uint256 _fee = (_amount.mul(earlyWithdrawPenaltyRate)).div(PRECISION);
            _penalize(_fee);
            _amount = _amount.sub(_fee);
        }
        _locked.end = 0;
        _locked.amount = 0;
        _locked.vp = 0;
        _burn(msg.sender, mintedForLock[msg.sender]);
        mintedForLock[msg.sender] = 0;

        IERC20Upgradeable(lockedToken).safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount, _now);
    }

    /// @notice  Used to unlock the vested SPACE tokens
    ///  If the period is over, all vested SPACE are unlocked
    function unlock() external nonReentrant lock {
        LockedBalance[] storage _vested = vested[msg.sender];
        uint256 toUnlock;
        uint256 vp;
        uint256 length = _vested.length;
        uint256 _now = block.timestamp;

        if (_vested[length - 1].end <= _now) {
            toUnlock = totalVested(msg.sender);
            vp = mintedForVest[msg.sender];
            mintedForVest[msg.sender] = 0;
            delete vested[msg.sender];
        } else {
            for (uint256 i = 0; i < length; i++) {
                if (_vested[i].end > _now) break;
                toUnlock = toUnlock.add(_vested[i].amount);
                vp = vp.add(_vested[i].vp);
                delete _vested[i];
            }
            mintedForVest[msg.sender] = mintedForVest[msg.sender].sub(vp);
        }

        require(toUnlock > 0, "nothing to unlock");

        _burn(msg.sender, vp);
        IERC20Upgradeable(lockedToken).safeTransfer(msg.sender, toUnlock);
        emit Unlocked(msg.sender, toUnlock, _now);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Implementation of _depositTo
    /// @param _addr User address
    /// @param _value Amount of SPACE to deposit
    /// @param _days Number of days to lock
    function _depositTo(
        address _addr,
        uint256 _value,
        uint256 _days
    ) internal nonReentrant lock {
        LockedBalance storage _locked = locked[_addr];
        uint256 _now = block.timestamp;
        uint256 _amount = _locked.amount;
        uint256 _end = _locked.end;
        uint256 _vp;
        if (_amount == 0) {
            _vp = votingPowerLockedDays(_value, _days);
            _locked.amount = _value;
            _locked.end = block.timestamp.div(604800).mul(604800).add(_days * 1 days);
        } else if (_days == 0) {
            _vp = votingPowerUnlockTime(_value, _end);
            _locked.amount = _amount + _value;
        } else {
            require(_value == 0, "Cannot increase amount and extend lock in the same time");
            _vp = votingPowerLockedDays(_amount, _days);
            _locked.end = _end + _days * 1 days;
            require(_locked.end - _now <= MAX_TIME, "Cannot extend lock to more than 100 weeks");
        }
        require(_vp > 0, "No benefit to lock");
        if (_value > 0) {
            IERC20Upgradeable(lockedToken).safeTransferFrom(msg.sender, address(this), _value);
        }

        _locked.vp = _vp;
        _mint(_addr, _vp);
        mintedForLock[_addr] += _vp;

        emit Deposit(_addr, _locked.amount, _locked.end, _now);
    }

    function _penalize(uint256 _amount) internal {
        if (multiRewardsDistributionPool != address(0)) {
            // send to multirewards contracts
            IMultiRewardsDistributionPool(multiRewardsDistributionPool).notifyRewardAmount(lockedToken, _amount);
        }
    }

    function _onlyWhitelisted() internal view {
        require(whitelist[msg.sender], "not whitelist");
    }

    function _onlyWhitelistedOrEOA() internal view {
        require(whitelist[msg.sender] || msg.sender == tx.origin, "only eoa or whitelisted contract");
    }

    /*///////////////////////////////////////////////////////////////
                        RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setMinLockedAmount(uint256 _minLockedAmount) external onlyOwner {
        minLockedAmount = _minLockedAmount;
        emit MinLockedAmountSet(_minLockedAmount);
    }

    function setAccessToMint(address _contract) external onlyOwner {
        minters[_contract] = true;
    }

    function revokeAccessToMint(address _contract) external onlyOwner {
        minters[_contract] = false;
    }

    function setEarlyWithdrawPenaltyRate(uint256 _earlyWithdrawPenaltyRate) external onlyOwner {
        require(_earlyWithdrawPenaltyRate <= MAX_WITHDRAWAL_PENALTY, "withdrawal penalty is too high"); // <= 50%
        earlyWithdrawPenaltyRate = _earlyWithdrawPenaltyRate;
        emit EarlyWithdrawPenaltySet(_earlyWithdrawPenaltyRate);
    }

    function setMultiRewardsDistributionPool(address _addr) external onlyOwner {
        multiRewardsDistributionPool = _addr;
        IERC20Upgradeable(lockedToken).safeApprove(_addr, type(uint256).max);
        emit multiRewardsDistributionPoolSet(_addr);
    }

    function whitelistAddress(address _addr) external onlyOwner {
        whitelist[_addr] = true;
    }

    function blacklistAddress(address _addr) external onlyOwner {
        whitelist[_addr] = false;
    }

    /*///////////////////////////////////////////////////////////////
                            EVENTS 
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed provider, uint256 value, uint256 locktime, uint256 timestamp);
    event Withdraw(address indexed provider, uint256 value, uint256 timestamp);
    event Unlocked(address indexed provider, uint256 value, uint256 timestamp);
    event multiRewardsDistributionPoolSet(address indexed addr);
    event EarlyWithdrawPenaltySet(uint256 indexed penalty);
    event MinLockedAmountSet(uint256 indexed amount);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity =0.7.6;

interface IMultiRewardsDistributionPool {
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external;

    function rewardPerToken(address _rewardsToken) external view returns (uint256);

    function getRewardForDuration(address _rewardsToken) external view returns (uint256);

    function lastTimeRewardApplicable(address _rewardsToken) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rewardData(address token)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function balanceOf(address account) external view returns (uint256);

    function earned(address account, address _rewardsToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.7.0;

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
library SafeMathUpgradeable {
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

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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