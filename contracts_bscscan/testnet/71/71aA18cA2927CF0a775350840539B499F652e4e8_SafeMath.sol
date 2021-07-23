/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;

// ----------------------------------------------------------------------------
// 'Dexfolio Token contract
//
// Name : Dexfolio
// Symbol : DEXF
// Total supply: 200,000,000 (200M)
// Decimals : 18
//
// ----------------------------------------------------------------------------

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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the BEP20Interface standard as defined in the EIP.
 */
interface BEP20Interface {
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

interface IPancakeSwapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
}

abstract contract BPContract{
    function protect(
        address sender, 
        address receiver, 
        uint256 amount
    ) external virtual;
}

/**
 * @dev Implementation of the {BEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {BEP20-approve}.
 */
contract DEXF is BEP20Interface, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public constant _treasury = 0xa43439d9Cd5F183dE221cCC0428ae16e87a1CC3a;
    address public constant _team = 0x760EA046e0dA63E20699D592206cF8E33d17Ff50;
    address public constant _stakingPool = 0x31501F2B86cc3485093df368C813be7b8e700b38;
    address public _treasury1 = address(0);

    uint256 public DAILY_RELEASE_AMOUNT_TREASURY;
    uint256 public DAILY_RELEASE_AMOUNT_TEAM;

    uint256 public DAILY_RELEASE_PERCENT_STAKING;
    uint256 public stakingRewardRemaining;

    uint256 public treasuryAvailable;
    uint256 public teamAvailable;
    uint256 public stakingAvailable;

    mapping (uint256 => uint256) public dailyStakingRewards;

    uint256 public _epoch1Start;

    uint256 public _epochDuration;

    uint256 public _lastInitializedEpoch;

    address public stakingContract = address(0);

    address public pancakeswapV2Pair;
    mapping(address => bool) private _isBlacklisted;
    uint256 private deployTimestamp;
    uint256 private constant BLACK_AVAILABLE_PERIOD = 5 hours;

    uint256 public buyLimit;
    uint256 public sellLimit;

    uint256 public taxFee = 3;

    BPContract public BP;
    bool public bpEnabled;

    event ChangedDailyReleaseAmountTreasury(address indexed owner, uint256 amount);
    event ChangedDailyReleasePercentStaking(address indexed owner, uint256 percent);
    event ChangedStakingRewardRemaining(address indexed owner, uint256 amount);
    event ChangedTreasury1Address(address indexed owner, address newAddress);
    event changedAllocation(address indexed owner, uint256 amount, uint8 from, uint8 to);
    event AddedToBlacklist(address account);
    event RemovedFromBlacklist(address account);
    event UpdatedBuyLimit(uint256 limit);
    event UpdatedSellLimit(uint256 limit);
    event ClaimedStakingReward(address recipient, uint256 amount);
    event InitializedEpoch(uint256 epochId);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        _name = "Dexfolio";  //Token Name
        _symbol = "DEXF"; //Token Symbol
        _decimals = 18;  //Decimals

        _mint(address(0xAC6F51379d0212b93b651681528486cD3881aE4c), 40000000E18);
        _mint(_treasury, 72000000E18); // 72M
        _mint(_team, 20000000E18); // 20M
        _mint(_stakingPool, 68000000E18); // 68M

        DAILY_RELEASE_AMOUNT_TREASURY = 72000000E18 / uint256(3647); // 3647 days
        DAILY_RELEASE_AMOUNT_TEAM = 20000000E18 / uint256(104); // 104 days
        DAILY_RELEASE_PERCENT_STAKING = 10;
        stakingRewardRemaining = 68000000E18;

        _epoch1Start = 1627012800;
        _epochDuration = 24 hours;

        buyLimit = 200000E18;
        sellLimit = 200000E18;

        IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory())
            .getPair(address(this), _pancakeswapV2Router.WETH());
        if (pair != address(0)) {
            pancakeswapV2Pair = pair;
        } else {
            pancakeswapV2Pair = address(IPancakeSwapV2Factory(_pancakeswapV2Router.factory())
                .createPair(address(this), _pancakeswapV2Router.WETH()));
        }

        deployTimestamp = block.timestamp;
    }

    /**
     * @dev Sets daily release amount of treasury.
     */
    function setDailyReleaseAmountTreasury(uint256 dailyReleaseAmount) external onlyOwner {
        DAILY_RELEASE_AMOUNT_TREASURY = dailyReleaseAmount;
        emit ChangedDailyReleaseAmountTreasury(_msgSender(), dailyReleaseAmount);
    }

    /**
     * @dev Sets daily release percent for staking reward.
     */
    function setDailyReleasePercentStaking(uint256 percent) external onlyOwner {
        DAILY_RELEASE_PERCENT_STAKING = percent;
        emit ChangedDailyReleasePercentStaking(_msgSender(), percent);
    }

    /**
     * @dev Sets staking contract address.
     */
    function setStakingContract(address stakingContractAddr) external onlyOwner {
        require(stakingContract == address(0), "Dexf: Staking contract already initialized");

        stakingContract = address(stakingContractAddr);
    }

    /**
     * @dev Sets staking contract address.
     */
    function setStakingRewardRemaining(uint256 remainingAmount) external onlyOwner {
        stakingRewardRemaining = remainingAmount;
        emit ChangedStakingRewardRemaining(_msgSender(), remainingAmount);
    }

    /**
     * @dev Sets treasury 1 address.
     */
    function setTreasury1(address newAddress) external onlyOwner {
        _treasury1 = newAddress;
        emit ChangedTreasury1Address(_msgSender(), newAddress);
    }

    /**
     * @dev Set epoch 1 start time. Call by only owner.
     */
    function setEpoch1Start(uint256 epochStartTime) external onlyOwner {
        _epoch1Start = epochStartTime;
    }

    /**
     * @dev Set tax fee percent. Call by only owner.
     */
    function setTaxFee(uint256 fee) external onlyOwner {
        require(fee <= 10, "Dexf: Invalid tax fee");
        taxFee = fee;
    }

    /**
     * @dev Changes allocations.
     */
    function changeAllocation(uint256 amount, uint8 from, uint8 to) external onlyOwner {
        require(from < 4 && to < 4 && from != to, "Dexf: Invalid allocation");
        require(to != 1, "Dexf: Invalid allocation");

        uint256 currentEpochId = getCurrentEpoch();
        if (_lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }

        address fromAddress = _treasury;
        address toAddress = _treasury;

        if (from == 1) {
            fromAddress = _team;    
        } else if (from == 2) {
            fromAddress = _stakingPool;
        } else if (from == 3) {
            fromAddress = _treasury1;
        }

        if (to == 2) {
            toAddress = _stakingPool;
        } else if (to == 3) {
            toAddress = _treasury1;
        }

        uint256 senderBalance = _balances[fromAddress];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[fromAddress] = senderBalance - amount;
        _balances[toAddress] += amount;

        if (fromAddress == _stakingPool) {
            stakingRewardRemaining = stakingRewardRemaining.sub(amount);
        } else if (toAddress == _stakingPool) {
            stakingRewardRemaining = stakingRewardRemaining.add(amount);
        }

        emit changedAllocation(_msgSender(), amount, from, to);
    }

    function setBPAddrss(address _bp) external onlyOwner {
        BP = BPContract(_bp);
    }

    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled;
    }

    function getDailyStakingReward(uint256 day) external view returns (uint256) {
        return dailyStakingRewards[day];
    }

    function getDailyStakingRewardAfterEpochInit(uint256 day) external returns (uint256) {
        uint256 currentEpochId = getCurrentEpoch();
        if (_lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }

        return dailyStakingRewards[day];
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
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
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
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `msg.sender`, reducing the
     * total supply.
     */
    function burn(uint256 amount) external whenNotPaused {
        _burn(_msgSender(), amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(
            !_isBlacklisted[sender] && !_isBlacklisted[recipient],
            "Blacklisted account"
        );
        _validateTransfer(sender, recipient, amount);

        if (bpEnabled) {
            BP.protect(sender, recipient, amount);
        }

        uint256 currentEpochId = getCurrentEpoch();

        if (_lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }

        _changeAvailableAmount(sender, amount); // if sender is team or treasury, try weekly release
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;

        uint256 feeAmount = 0;
        if (taxFee != 0 && sender != owner() && recipient != owner() && sender != address(_stakingPool)) {
            feeAmount = amount.mul(taxFee).div(100);
        }
        _balances[_stakingPool] = _balances[_stakingPool].add(feeAmount);
        stakingRewardRemaining = stakingRewardRemaining.add(feeAmount);
        _balances[recipient] += amount.sub(feeAmount);

        emit Transfer(sender, recipient, amount);
    }

    function _validateTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private view {
        if (sender != owner() && _isBuy(sender)) {
            require(amount <= buyLimit, "Buy amount exceeds limit");
        } else if (sender != owner() && recipient != owner() && _isSell(sender, recipient)) {
            require(amount <= sellLimit, "Sell amount exceeds limit");
        }
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
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Check and set available send amount for team and treasury.
     *
     * sender should be team or treasury
     *
     * if available amount less than sending amount, transaction will be failed
     */
    function _changeAvailableAmount(address sender, uint256 amount) internal {
        if (sender == _treasury || sender == _team || sender == _stakingPool) {
            uint256 currentEpochId = getCurrentEpoch();

            require(currentEpochId > 0, "BEP20: locked yet");

            if (sender == _treasury) {
                treasuryAvailable = treasuryAvailable.sub(amount);
            }
            if (sender == _team) {
                teamAvailable = teamAvailable.sub(amount);
            }
            if (sender == _stakingPool) {
                stakingAvailable = stakingAvailable.sub(amount);
            }
        }
    }

    /**
     * @dev Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < _epoch1Start) {
            return 0;
        }

        return (block.timestamp - _epoch1Start) / _epochDuration + 1;
    }

    function _initEpoch(uint256 epochId) internal {
        require(epochId <= getCurrentEpoch(), "Can't init a future epoch");
        require(epochId > _lastInitializedEpoch, "Already initialized");

        for (uint256 i = _lastInitializedEpoch + 1; i <= epochId; i++) {
            treasuryAvailable = treasuryAvailable.add(DAILY_RELEASE_AMOUNT_TREASURY);
            teamAvailable = teamAvailable.add(DAILY_RELEASE_AMOUNT_TEAM);

            dailyStakingRewards[i] = stakingRewardRemaining.mul(DAILY_RELEASE_PERCENT_STAKING).div(10000);
            stakingAvailable = stakingAvailable.add(dailyStakingRewards[i]);
            stakingRewardRemaining = stakingRewardRemaining.sub(dailyStakingRewards[i]);
        }
        _lastInitializedEpoch = epochId;

        emit InitializedEpoch(epochId);
    }

    function manualEpochInit(uint128 epochId) public {
        _initEpoch(epochId);
    }

    /**
     * @dev Claim reward from staking pool
     */
    function claimStakingReward(address recipient, uint256 amount) external {
        require(_msgSender() == stakingContract, "Dexf: No staking contract");

        _transfer(_stakingPool, recipient, amount);

        emit ClaimedStakingReward(recipient, amount);
    }

    function _isSell(address sender, address recipient) internal view returns (bool) {
        // Transfer to pair from non-router address is a sell swap
        return sender != address(pancakeswapV2Pair) && recipient == address(pancakeswapV2Pair);
    }

    function _isBuy(address sender) internal view returns (bool) {
        // Transfer from pair is a buy swap
        return sender == address(pancakeswapV2Pair);
    }

    function addToBlacklist(address account) external onlyOwner {
        require(block.timestamp <= deployTimestamp + BLACK_AVAILABLE_PERIOD, "Dexf: Invalid call");
        require(account != address(pancakeswapV2Pair), "Dexf: Invalid address");

        _isBlacklisted[account] = true;

        emit AddedToBlacklist(account);
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(block.timestamp <= deployTimestamp + BLACK_AVAILABLE_PERIOD, "Dexf: Invalid call");
        _isBlacklisted[account] = false;

        emit RemovedFromBlacklist(account);
    }

    function updateBuyLimit(uint256 limit) external onlyOwner {
        require(limit >= 7000E18, "Dexf: invalid limit");
        buyLimit = limit;

        emit UpdatedBuyLimit(limit);
    }

    function updateSellLimit(uint256 limit) external onlyOwner {
        require(limit >= 7000E18, "Dexf: invalid limit");
        sellLimit = limit;

        emit UpdatedSellLimit(limit);
    }
}