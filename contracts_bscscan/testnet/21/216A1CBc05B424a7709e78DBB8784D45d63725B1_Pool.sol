/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Vesting {
  struct VestingStages {
    uint256 date;
    uint256 percentage;
  }
  uint256 public claimTime;

  constructor(uint256 _claimTime) {
    claimTime = _claimTime;
    initVestingStages();
  }

  VestingStages[] public stages;

  function initVestingStages() internal {
    uint256 vestingPeriod = 2 minutes;

    stages.push(VestingStages(claimTime, 1000));
    stages.push(VestingStages(claimTime + vestingPeriod, 2500));
    stages.push(VestingStages(claimTime + 2 * vestingPeriod, 3000));
    stages.push(VestingStages(claimTime + 3 * vestingPeriod, 4500));
    stages.push(VestingStages(claimTime + 4 * vestingPeriod, 6000));
  }

  function _getUnlockedPercentage() internal view returns (uint256) {
    if (block.timestamp < claimTime) {
      return 0;
    }

    uint256 allowedPercent;

    for (uint8 i = 0; i < stages.length; i++) {
      if (block.timestamp >= stages[i].date) {
        allowedPercent = stages[i].percentage;
      }
    }
    return allowedPercent;
  }

  function _getClaimableAsset(
    uint256 claimedStage,
    uint256 assignedAsset,
    uint256 claimedAsset
  ) internal view returns (uint256) {
    if (stages[claimedStage].date >= block.timestamp) {
      return 0;
    }

    uint256 unlockedAsset = ((assignedAsset * _getUnlockedPercentage())) /
      10000;
    return unlockedAsset - claimedAsset;
  }

  function getNextClaimTime() public view returns (uint256) {
    for (uint256 i = 0; i < stages.length; i++) {
      if (block.timestamp < stages[i].date) {
        return stages[i].date;
      }
    }

    return 0;
  }

  function getNextStage() public view returns (VestingStages memory) {
    for (uint256 i = 0; i < stages.length; i++) {
      if (block.timestamp < stages[i].date) {
        return stages[i];
      }
    }

    return VestingStages(0, 0);
  }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

// File: XP.sol


pragma solidity 0.8.7;



contract XpToken is ERC20, Ownable {
  constructor() ERC20("XP", "XP") {}

  function mint(address _recipient, uint256 _amount) public onlyOwner {
    _mint(_recipient, _amount);
  }

  function burn(address _account, uint256 _amount) public {
    _burn(_account, _amount);
  }

  function passMinterRole(address _minter) public onlyOwner {
    require(isContract(_minter), "minter should be a contract");
    transferOwnership(_minter);
  }

  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

// File: Pool.sol


pragma solidity ^0.8.7;





interface IWhitelistRegistry {
  function IsWhitelisted(address _addr) external view returns (bool);
}

contract Pool is Ownable, Vesting {
  /*
    Variables common to the pool
  */

  enum PoolStatus {
    UPCOMING,
    ONGOING,
    FINISHED
  }

  uint256 public maxCap;
  uint256 public saleStartTime;
  uint256 public saleEndTime;

  uint256 public maxAllocationPerUser;

  address private gameTokenAddress;
  uint256 public valueOfGameToken; // 1 BUSD equivalent

  XpToken private XPToken = XpToken(0xd587Da5e56EC51430443387611d99338663F1A45);
  IERC20 private BUSD = IERC20(0x27F4b42B1476650e54e65bBF02AaEA3798744D26);
  address private projectOwner;

  IWhitelistRegistry private whitelistRegistry;

  /*
  GUARANTEED ALLOCATION variables
 */
  // values in BUSD
  uint256 public maxCapForGuaranteedTier;
  uint256 public allocationLeftInGuaranteedTier;

  // price to buy tier in BUSD
  uint256[4] public priceForTierInBUSD;

  // price to buy tier in XP
  uint256[4] public priceForTierInXP;

  // number of slots in Guaranteed Tiers
  uint256[4] public slotsInTier;

  address[] private Investors;
  mapping(address => bool) hasInvested;

  struct OverallInvestorInfo {
    uint256 totalAllocation;
    uint256 assignedGameTokens;
    uint256 claimedGameTokens;
    uint256 lastStage;
    bool isInLottery;
    uint256 ticketCount;
    bool lotteryWon;
    uint256 allocationLost;
  }
  mapping(address => OverallInvestorInfo) public investorsInfo;

  /*
    LOTTERY ALLOCATION variables
  */

  uint256 public maxCapForLotteryTier; // max cap in BUSD
  uint256 public allocationLeftInLotteryTier;
  uint256 public winningTicketAllocation; // in BUSD

  uint256 numberOfWinnersRequired;

  struct TicketBracket {
    uint8 numberOfTickets;
    uint256 priceInXP;
  }
  TicketBracket[3] public ticketBrackets;

  struct TicketInfo {
    address owner;
    uint256 ticketId;
  }
  TicketInfo[] private tickets;
  uint256 private ticketCount;

  event TokensClaimed(address indexed _investor, uint256 _amount);
  event BoughtGuaranteedTier(address indexed _investor, uint256 _tierType);

  /**
   * @param _maxCap maximum capital to be raised by this pool (BUSD)
   * @param _saleStartTime start time of the sale in epoch (seconds)
   * @param _saleEndTime end time of the sale in epoch (seconds)
   * @param _maxAllocationPerUser maximum allocation that user can get (BUSD)
   * @param _gameTokenAddress address of the game token that IGO is giving
   * @param _projectOwner address where we will send the BUSD amount
   * @param _valueOfGameToken 1 BUSD equivalent of the game token
   * @param _whitelistRegistry address of contract that maintains whitelisted address
   * @param _maxCapForGuaranteedTier maximum capital to be raised from guaranteed tiers (BUSD)
   * @param _priceForTierInBUSD an array containing prices to buy each of the Guaranteed tiers in BUSD
   * @param _priceForTierInXP an array containing prices to buy each of the Guaranteed tiers in XP
   */
  constructor(
    /* Pool Variables */
    uint256 _maxCap,
    uint256 _saleStartTime,
    uint256 _saleEndTime,
    uint256 _maxAllocationPerUser,
    address _gameTokenAddress,
    address _projectOwner,
    uint256 _valueOfGameToken,
    IWhitelistRegistry _whitelistRegistry,
    /* Guaranteed Allocation Variables */
    uint256 _maxCapForGuaranteedTier,
    uint256[4] memory _priceForTierInBUSD,
    uint256[4] memory _priceForTierInXP
  ) Ownable() Vesting(_saleEndTime) {
    /* Pool Variables Initialization */
    maxCap = _maxCap * 1e18;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;

    maxAllocationPerUser = _maxAllocationPerUser * 1e18;

    // provide value of game token with decimal
    // ex: 2000000000000000000 ("decimal number of zeroes")
    valueOfGameToken = _valueOfGameToken;
    gameTokenAddress = _gameTokenAddress;

    projectOwner = _projectOwner;

    whitelistRegistry = _whitelistRegistry;

    /* Guaranteed Allocation variables Initialization */
    maxCapForGuaranteedTier = _maxCapForGuaranteedTier * 1e18;

    require(maxCapForGuaranteedTier <= maxCap);
    allocationLeftInGuaranteedTier = maxCapForGuaranteedTier;

    for (uint256 i = 0; i < 4; i++) {
      priceForTierInBUSD[i] = _priceForTierInBUSD[i] * 1e18;
      priceForTierInXP[i] = _priceForTierInXP[i] * 1e18;
    }

    /* Lottery Allocation variables Initialization */
    maxCapForLotteryTier = maxCap - maxCapForGuaranteedTier;
    allocationLeftInLotteryTier = maxCapForLotteryTier;

    _rebalanceTierSlots();
  }

  /*
    modifiers for check
  */

  modifier _isWhitelisted(address _investor) {
    require(
      whitelistRegistry.IsWhitelisted(_investor),
      "investor not whitelisted"
    );
    _;
  }

  modifier _hasAllowance(address allower, uint256 amount) {
    uint256 ourAllowance = BUSD.allowance(allower, address(this));
    require(amount <= ourAllowance, "Make sure to add enough allowance");
    _;
  }

  modifier _isPoolActive() {
    require(getPoolStatus() == PoolStatus.ONGOING, "pool is not active");
    _;
  }

  /*
    GUARANTEED ALLOCATION - Start
  */

  /**
    @notice function to buy a single slot from one of the four Guaranteed tiers.
    @param _tierNumber which of the four tiers to buy (0, 1, 2, 3)
  */
  function buyFromTier(uint256 _tierNumber)
    public
    _hasAllowance(msg.sender, priceForTierInBUSD[_tierNumber])
    _isPoolActive
    _isWhitelisted(msg.sender)
  {
    require(_tierNumber >= 0, "invalid tier selected");
    require(_tierNumber < 4, "invalid tier selected");
    require(
      allocationLeftInGuaranteedTier > priceForTierInBUSD[_tierNumber],
      "no slots left"
    );

    require(
      investorsInfo[msg.sender].totalAllocation +
        priceForTierInBUSD[_tierNumber] <=
        maxAllocationPerUser,
      "max allocation reached"
    );

    // burn XP
    XPToken.burn(msg.sender, priceForTierInXP[_tierNumber]);

    // transfer BUSD to project owner
    BUSD.transferFrom(
      msg.sender,
      projectOwner,
      priceForTierInBUSD[_tierNumber]
    );

    allocationLeftInGuaranteedTier -= priceForTierInBUSD[_tierNumber];

    investorsInfo[msg.sender].totalAllocation += priceForTierInBUSD[
      _tierNumber
    ];

    investorsInfo[msg.sender].assignedGameTokens =
      (investorsInfo[msg.sender].totalAllocation / 1000000000000000000) *
      valueOfGameToken;

    if (!hasInvested[msg.sender]) {
      Investors.push(msg.sender);
      hasInvested[msg.sender] = true;
    }

    _rebalanceTierSlots();
  }

  function claimGameTokens() public {
    require(block.timestamp > saleEndTime, "sale has not ended");
    require(block.timestamp >= claimTime, "claim period not started");
    require(hasInvested[msg.sender], "not an investor");

    uint256 claimableAmount = getUnlockedTokens(msg.sender);
    IERC20(gameTokenAddress).transfer(msg.sender, claimableAmount);

    investorsInfo[msg.sender].claimedGameTokens += claimableAmount;

    emit TokensClaimed(msg.sender, claimableAmount);
  }

  function getUnlockedTokens(address _investor) public view returns (uint256) {
    uint256 claimedStage = investorsInfo[_investor].lastStage;
    uint256 assignedTokens = investorsInfo[_investor].assignedGameTokens;
    uint256 claimedTokens = investorsInfo[_investor].claimedGameTokens;
    return _getClaimableAsset(claimedStage, assignedTokens, claimedTokens);
  }

  function getSlotsInEachTier() public view returns (uint256[4] memory) {
    return slotsInTier;
  }

  function getPoolStatus() public view returns (PoolStatus) {
    if (block.timestamp < saleStartTime) {
      return PoolStatus.UPCOMING;
    }

    if (block.timestamp > saleEndTime) {
      return PoolStatus.FINISHED;
    }

    return PoolStatus.ONGOING;
  }

  function _rebalanceTierSlots() internal {
    for (uint256 i = 0; i < 4; i++) {
      slotsInTier[i] = allocationLeftInGuaranteedTier / priceForTierInBUSD[i];
    }
  }

  /*
    GUARANTEED ALLOCATION - End
  */

  /* 
    LOTTERY ALLOCATION - Start
  */

  /**
    @notice function to create lottery (call this after deploying the pool)
    @param _numberOfTicketsInEachBracket amount of tickets in each bracket
    @param _priceInXPForEachBracket XP that will be burned in each bracket
    @param _winningTicketAllocation price of each ticket (BUSD)
  */
  function createLottery(
    uint8[3] memory _numberOfTicketsInEachBracket,
    uint256[3] memory _priceInXPForEachBracket,
    uint256 _winningTicketAllocation
  ) public onlyOwner {
    for (uint8 i = 0; i < 3; i++) {
      ticketBrackets[i].numberOfTickets = _numberOfTicketsInEachBracket[i];
      ticketBrackets[i].priceInXP = _priceInXPForEachBracket[i] * 1e18;
    }

    winningTicketAllocation = _winningTicketAllocation * 1e18;
    numberOfWinnersRequired = maxCapForLotteryTier / winningTicketAllocation;
  }

  /**
    @notice function to buy lottery tickets
    @param _bracketNumber number of bracket to buy ticket from
  */
  function buyTickets(uint256 _bracketNumber)
    public
    _isWhitelisted(msg.sender)
    _hasAllowance(
      msg.sender,
      winningTicketAllocation * ticketBrackets[_bracketNumber].numberOfTickets
    )
    _isPoolActive
  {
    XPToken.burn(msg.sender, ticketBrackets[_bracketNumber].priceInXP);

    BUSD.transferFrom(
      msg.sender,
      address(this),
      winningTicketAllocation * ticketBrackets[_bracketNumber].numberOfTickets
    );

    hasInvested[msg.sender] = true;
    investorsInfo[msg.sender].isInLottery = true;

    for (uint8 i = 0; i < ticketBrackets[_bracketNumber].numberOfTickets; i++) {
      TicketInfo memory newTicket = TicketInfo(msg.sender, tickets.length);
      investorsInfo[msg.sender].ticketCount++;

      investorsInfo[msg.sender].allocationLost += winningTicketAllocation;
      tickets.push(newTicket);
    }
  }

  function drawWinners(string memory _seed) public onlyOwner {
    require(getPoolStatus() == PoolStatus.FINISHED, "pool has not ended yet");
    if (tickets.length <= numberOfWinnersRequired) {
      for (uint256 i = 0; i < tickets.length; i++) {
        TicketInfo storage ticket = tickets[i];
        rewardWinner(ticket.owner);
      }
    } else {
      for (uint256 i = 0; i < numberOfWinnersRequired; i++) {
        uint256 winningIndex = getWinningIndex(_seed, i);
        TicketInfo memory ticket = tickets[winningIndex];
        tickets[winningIndex] = tickets[tickets.length - 1];
        tickets.pop();

        rewardWinner(ticket.owner);
      }
    }
  }

  function rewardWinner(address _owner) internal {
    investorsInfo[_owner].totalAllocation += winningTicketAllocation;

    investorsInfo[_owner].assignedGameTokens =
      (investorsInfo[_owner].totalAllocation / 1000000000000000000) *
      valueOfGameToken;

    investorsInfo[_owner].lotteryWon = true;

    investorsInfo[_owner].allocationLost -= winningTicketAllocation;
  }

  function getWinningIndex(string memory _seed, uint256 i)
    internal
    view
    returns (uint256)
  {
    return uint256(keccak256(abi.encode(_seed, i))) % tickets.length;
  }

  function claimBackBUSD() public {
    require(
      investorsInfo[msg.sender].isInLottery,
      "did not participate in lottery"
    );
    require(
      investorsInfo[msg.sender].allocationLost > 0,
      "lottery won, nothing to claim"
    );
    require(getPoolStatus() == PoolStatus.FINISHED, "pool has not ended");

    BUSD.transfer(msg.sender, investorsInfo[msg.sender].allocationLost);
  }

  function transferLotteryEarnings() public onlyOwner {
    BUSD.transfer(projectOwner, BUSD.balanceOf(address(this)));
  }

  /* 
    LOTTERY ALLOCATION - End
  */

  /**
    @notice function to update the start of claiming time
    @param _claimTime new claim time in epoch timestamp
  */
  function updateClaimTime(uint256 _claimTime) public onlyOwner {
    require(block.timestamp < claimTime);
    claimTime = _claimTime;
  }

  /**
    @notice function to give back the tokens sent directly to this contract
  */
  function emergencyWithdraw(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) public onlyOwner {
    _token.transfer(_to, _amount);
  }
}

// BUSD: https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56#code