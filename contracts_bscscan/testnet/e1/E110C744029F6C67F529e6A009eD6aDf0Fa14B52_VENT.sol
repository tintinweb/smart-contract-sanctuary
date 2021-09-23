/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

pragma solidity 0.5.10;

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {BEP20Detailed}.
 */
interface IBEP20 {
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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
 
contract BEP20 is Context, IBEP20 {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	/// allocating 6.25 Million VENT (day 1 amount) of tokens for dev share. Upon completion of stake 1.25 Million will be
	/// received after burn and fully used for JustSwap liquidity.
	uint256 private _totalSupply = 6250000 * (10**18);

	constructor() public {
		_balances[msg.sender] = _totalSupply;
	}

	/**
	 * @dev See {BEP20-totalSupply}.
	 */
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {BEP20-balanceOf}.
	 */
	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev See {BEP20-transfer}.
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
	 * @dev See {BEP20-allowance}.
	 */
	function allowance(address owner, address spender)
		public
		view
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {BEP20-approve}.
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
	 * @dev See {BEP20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {BEP20};
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for `sender`'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"BEP20: transfer amount exceeds allowance"
			)
		);
		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {BEP20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue)
		public
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {BEP20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue)
		public
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(
				subtractedValue,
				"BEP20: decreased allowance below zero"
			)
		);
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
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal {
		require(sender != address(0), "BEP20: transfer from the zero address");
		require(recipient != address(0), "BEP20: transfer to the zero address");

		_balances[sender] = _balances[sender].sub(
			amount,
			"BEP20: transfer amount exceeds balance"
		);
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
		require(account != address(0), "BEP20: mint to the zero address");

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
		require(account != address(0), "BEP20: burn from the zero address");

		_balances[account] = _balances[account].sub(
			amount,
			"BEP20: burn amount exceeds balance"
		);
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
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

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
		_approve(
			account,
			_msgSender(),
			_allowances[account][_msgSender()].sub(
				amount,
				"BEP20: burn amount exceeds allowance"
			)
		);
	}
}

contract GlobalsAndUtility is BEP20 {

    constructor() public {        
        /* Initialize VentLink Bonuses */
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(1);

		cycles.push(1e11);
		cycles.push(3e11);
		cycles.push(9e11);
		cycles.push(2e12);
	}

	/*  XfLobbyEnter
	 */
	event XfLobbyEnter(
		uint256 timestamp,
		uint256 enterDay,
		uint256 indexed entryIndex,
		uint256 indexed rawAmount
	);

	/*  XfLobbyExit
	 */
	event XfLobbyExit(
		uint256 timestamp,
		uint256 enterDay,
		uint256 indexed entryIndex,
		uint256 indexed xfAmount,
		address indexed referrerAddr
	);

	/*  XfLobbyRefEnter
	 */
	event XfLobbyRefEnter(
		uint256 timestamp,
		uint256 enterDay,
		uint256 indexed entryIndex,
		address indexed referrerAddr
	);

	/*  XfLobbyReferrer
	 */
	event XfLobbyReferrer(
		uint256 timestamp,
		uint256 enterDay,
		uint256 indexed entryIndex,
		uint256 indexed referrerBonusSuns,
		address indexed referrerAddr
	);

	/*  DailyDataUpdate
	 */
	event DailyDataUpdate(
		address indexed updaterAddr,
		uint256 timestamp,
		uint256 beginDay,
		uint256 endDay
	);

	/*  StakeStart
	 */
	event StakeStart(
		uint40 indexed stakeId,
		address indexed stakerAddr,
		uint256 stakedSuns,
		uint256 stakeShares,
		uint256 stakedDays
	);

	/*  StakeGoodAccounting
	 */
	event StakeGoodAccounting(
		uint40 indexed stakeId,
		address indexed stakerAddr,
		address indexed senderAddr,
		uint256 stakedSuns,
		uint256 stakeShares,
		uint256 payout,
		uint256 penalty
	);

	/*  StakeEnd
	 */
	event StakeEnd(
		uint40 indexed stakeId,
		uint40 prevUnlocked,
		address indexed stakerAddr,
		uint256 lockedDay,
		uint256 servedDays,
		uint256 stakedSuns,
		uint256 stakeShares,
		uint256 dividends,
		uint256 payout,
		uint256 penalty,
		uint256 stakeReturn
	);

	/*  ShareRateChange
	 */
	event ShareRateChange(
		uint40 indexed stakeId,
		uint256 timestamp,
		uint256 newShareRate
	);

    /*  User Stuct for VentLink
     */
    struct User {
		uint256 cycle;
		address upline;
		uint256 referrals;
		uint256 payouts;
		uint256 direct_bonus;
		uint256 match_bonus;
		uint256 deposit_amount;
		uint256 deposit_payouts;
		uint40 deposit_time;
		uint256 total_deposits;
		uint256 total_payouts;
		uint256 total_structure;
	}

	mapping(address => User) public users;

	uint256[] public cycles;
	uint8[] public ref_bonuses; // 1 => 1%

  	uint256 public total_users = 1;
	uint256 public total_deposited;
	uint256 public total_withdraw;

	event Upline(address indexed addr, address indexed upline);
	event NewDeposit(address indexed addr, uint256 amount);
	
	event DirectPayout(
		address indexed addr,
		address indexed from,
		uint256 amount
	);
	event MatchPayout(
		address indexed addr,
		address indexed from,
		uint256 amount
	);
    event Withdraw(address indexed addr, uint256 amount);
	event LimitReached(address indexed addr, uint256 amount);

	/* Flush address */
	// address payable internal constant FLUSH_ADDR =
	// 	0x212b6693f5cCDb0d98990b18A15f2d8A867CFa1d; 
    // address payable internal constant FLUSH_ADDR_BUY =
	// 	0xc5BcCd40627DD68Fadf6d832f48b54725f90F975;     
	// address payable internal constant FLUSH_ADDR_MKT =
	// 	0x30002a490E62d78894A3aEBe00360c3916fEb8Db; 
	// address payable internal constant FLUSH_ADDR_FIN1 =
	// 	0x72Fe091f376D88Ba047fe3225FC0CEafbBE94fa1; 
	// address payable internal constant FLUSH_ADDR_FIN2 =
	// 	0x8DdE27f678ABAfBbbbF00b0032857Eddb1fb0FF5; 
	
	address payable internal constant FLUSH_ADDR =
		0x6c6426714689245e03F5e78c8eaA29566Fc39488; //temptest 
    address payable internal constant FLUSH_ADDR_BUY =
		0x6c6426714689245e03F5e78c8eaA29566Fc39488;     
	address payable internal constant FLUSH_ADDR_MKT =
		0x6c6426714689245e03F5e78c8eaA29566Fc39488; 
	address payable internal constant FLUSH_ADDR_FIN1 =
		0x6c6426714689245e03F5e78c8eaA29566Fc39488; 
	address payable internal constant FLUSH_ADDR_FIN2 =
		0x6c6426714689245e03F5e78c8eaA29566Fc39488; 
		
    /* Accounting */
    address payable public deployer = 
        0x6c6426714689245e03F5e78c8eaA29566Fc39488; 

	uint8 internal LAST_FLUSHED_DAY = 1;

	/* BEP20 constants */
	string public constant name = "Venturi";
	string public constant symbol = "VENT";
	uint8 public constant decimals = 18;

	/* Suns per Satoshi = 10,000 * 1e8 / 1e8 = 1e4 */
	uint256 private constant SUNS_PER_DIV = 10**uint256(decimals); // 1e18

	/* Time of contract launch (2021-14-07T00:00:00Z - First Auction 2021-15-07T00:00:00Z */
	// uint256 internal constant LAUNCH_TIME = 1626220800;
	uint256 internal constant LAUNCH_TIME = 1632254441;
	
	/* Start of claim phase */
	uint256 internal constant PRE_CLAIM_DAYS = 1;
	/* reduce amount of tokens to 2500000 */
	uint256 internal constant CLAIM_STARTING_AMOUNT = 2500000 * (10**18);
	/* reduce amount of tokens to 1000000 */
	uint256 internal constant CLAIM_LOWEST_AMOUNT = 1000000 * (10**18);
	uint256 internal constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS;

	/* Number of words to hold 1 bit for each transform lobby day */
	uint256 internal constant XF_LOBBY_DAY_WORDS = ((1 + (50 * 7)) + 255) >> 8;

	/* Stake timing parameters */
	uint256 internal constant MIN_STAKE_DAYS = 1;

	/* Change from 180 */
	uint256 internal constant MAX_STAKE_DAYS = 365; // 365 day Max Stake - was 180

	uint256 internal constant LATE_PENALTY_GRACE_DAYS = 7; // From LATE_PENALTY_GRACE_WEEKS * 7

	/* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusSuns() */
	uint256 private constant LPB_BONUS_PERCENT = 20;
	uint256 private constant LPB_BONUS_MAX_PERCENT = 200;
	uint256 internal constant LPB = (364 * 100) / LPB_BONUS_PERCENT;
	uint256 internal constant LPB_MAX_DAYS = (LPB * LPB_BONUS_MAX_PERCENT) / 100;

	/* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusSuns() */
	uint256 private constant BPB_BONUS_PERCENT = 10;
	uint256 private constant BPB_MAX_DIV = 7 * 1e6;
	uint256 internal constant BPB_MAX_SUNS = BPB_MAX_DIV * SUNS_PER_DIV;
	uint256 internal constant BPB = (BPB_MAX_SUNS * 100) / BPB_BONUS_PERCENT;

	/* Share rate is scaled to increase precision */
	uint256 internal constant SHARE_RATE_SCALE = 1e5;

	/* Share rate max (after scaling) */
	uint256 internal constant SHARE_RATE_UINT_SIZE = 40;
	uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;

	/* weekly staking bonus */
	uint8 internal constant BONUS_DAY_SCALE = 2;

	/* Globals expanded for memory (except _latestStakeId) and compact for storage */
	struct GlobalsCache {
		uint256 _lockedSunsTotal;
		uint256 _nextStakeSharesTotal;
		uint256 _shareRate;
		uint256 _stakePenaltyTotal;
		uint256 _dailyDataCount;
		uint256 _stakeSharesTotal;
		uint40 _latestStakeId;
		uint256 _currentDay;
	}

	struct GlobalsStore {
		uint72 lockedSunsTotal;
		uint72 nextStakeSharesTotal;
		uint40 shareRate;
		uint72 stakePenaltyTotal;
		uint16 dailyDataCount;
		uint72 stakeSharesTotal;
		uint40 latestStakeId;
	}

	GlobalsStore public globals;

	/* Daily data */
	struct DailyDataStore {
		uint72 dayPayoutTotal;
		uint256 dayDividends;
		uint72 dayStakeSharesTotal;
	}

	mapping(uint256 => DailyDataStore) public dailyData;

	/* Stake expanded for memory (except _stakeId) and compact for storage */
	struct StakeCache {
		uint40 _stakeId;
		uint256 _stakedSuns;
		uint256 _stakeShares;
		uint256 _lockedDay;
		uint256 _stakedDays;
		uint256 _unlockedDay;
	}

	struct StakeStore {
		uint40 stakeId;
		uint72 stakedSuns;
		uint72 stakeShares;
		uint16 lockedDay;
		uint16 stakedDays;
		uint16 unlockedDay;
	}

	mapping(address => StakeStore[]) public stakeLists;

	/* Temporary state for calculating daily rounds */
	struct DailyRoundState {
		uint256 _allocSupplyCached;
		uint256 _payoutTotal;
	}

	struct XfLobbyEntryStore {
		uint96 rawAmount;
		address referrerAddr;
	}

	struct XfLobbyQueueStore {
		uint40 headIndex;
		uint40 tailIndex;
		mapping(uint256 => XfLobbyEntryStore) entries;
	}

	mapping(uint256 => uint256) public xfLobby;
	mapping(uint256 => mapping(address => XfLobbyQueueStore))
		public xfLobbyMembers;


	/**
	 * @dev PUBLIC FACING: Optionally update daily data for a smaller
	 * range to reduce gas cost for a subsequent operation
	 * @param beforeDay Only update days before this day number (optional; 0 for current day)
	 */
	function dailyDataUpdate(uint256 beforeDay) external {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		/* Skip pre-claim period */
		require(g._currentDay > CLAIM_PHASE_START_DAY, "VENT: Too early");

		if (beforeDay != 0) {
			require(
				beforeDay <= g._currentDay,
				"VENT: beforeDay cannot be in the future"
			);

			_dailyDataUpdate(g, beforeDay, false);
		} else {
			/* Default to updating before current day */
			_dailyDataUpdate(g, g._currentDay, false);
		}

		_globalsSync(g, gSnapshot);
	}

	/**
	 * @dev PUBLIC FACING: External helper to return multiple values of daily data with
	 * a single call.
	 * @param beginDay First day of data range
	 * @param endDay Last day (non-inclusive) of data range
	 * @return array of day stake shares total
	 * @return array of day payout total
	 */
	function dailyDataRange(uint256 beginDay, uint256 endDay)
		public
		view
		returns (
			uint256[] memory _dayStakeSharesTotal,
			uint256[] memory _dayPayoutTotal,
			uint256[] memory _dayDividends
		)
	{
		require(
			beginDay < endDay && endDay <= globals.dailyDataCount,
			"VENT: range invalid"
		);

		_dayStakeSharesTotal = new uint256[](endDay - beginDay);
		_dayPayoutTotal = new uint256[](endDay - beginDay);
		_dayDividends = new uint256[](endDay - beginDay);

		uint256 src = beginDay;
		uint256 dst = 0;
		do {
			_dayStakeSharesTotal[dst++] = uint256(
				dailyData[src].dayStakeSharesTotal
			);
			_dayPayoutTotal[dst++] = uint256(dailyData[src].dayPayoutTotal);
			_dayDividends[dst++] = dailyData[src].dayDividends;
		} while (++src < endDay);

		return (_dayStakeSharesTotal, _dayPayoutTotal, _dayDividends);
	}

	/**
	 * @dev PUBLIC FACING: External helper to return most global info with a single call.
	 * Ugly implementation due to limitations of the standard ABI encoder.
	 * @return Fixed array of values
	 */
	function globalInfo() external view returns (uint256[10] memory) {
		return [
			globals.lockedSunsTotal,
			globals.nextStakeSharesTotal,
			globals.shareRate,
			globals.stakePenaltyTotal,
			globals.dailyDataCount,
			globals.stakeSharesTotal,
			globals.latestStakeId,
			block.timestamp,
			totalSupply(),
			xfLobby[_currentDay()]
		];
	}

	/**
	 * @dev PUBLIC FACING: BEP20 totalSupply() is the circulating supply and does not include any
	 * staked Suns. allocatedSupply() includes both.
	 * @return Allocated Supply in Suns
	 */
	function allocatedSupply() external view returns (uint256) {
		return totalSupply() + globals.lockedSunsTotal;
	}

	/**
	 * @dev PUBLIC FACING: External helper for the current day number since launch time
	 * @return Current day number (zero-based)
	 */
	function currentDay() external view returns (uint256) {
		return _currentDay();
	}

	function _currentDay() internal view returns (uint256) {
		if (block.timestamp < LAUNCH_TIME) {
			return 0;
		} else {
			return (block.timestamp - LAUNCH_TIME) / 1 days;			
		}
	}

	function _dailyDataUpdateAuto(GlobalsCache memory g) internal {
		_dailyDataUpdate(g, g._currentDay, true);
	}

	function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot)
		internal
		view
	{
		g._lockedSunsTotal = globals.lockedSunsTotal;
		g._nextStakeSharesTotal = globals.nextStakeSharesTotal;
		g._shareRate = globals.shareRate;
		g._stakePenaltyTotal = globals.stakePenaltyTotal;
		g._dailyDataCount = globals.dailyDataCount;
		g._stakeSharesTotal = globals.stakeSharesTotal;
		g._latestStakeId = globals.latestStakeId;
		g._currentDay = _currentDay();

		_globalsCacheSnapshot(g, gSnapshot);
	}

	function _globalsCacheSnapshot(
		GlobalsCache memory g,
		GlobalsCache memory gSnapshot
	) internal pure {
		gSnapshot._lockedSunsTotal = g._lockedSunsTotal;
		gSnapshot._nextStakeSharesTotal = g._nextStakeSharesTotal;
		gSnapshot._shareRate = g._shareRate;
		gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
		gSnapshot._dailyDataCount = g._dailyDataCount;
		gSnapshot._stakeSharesTotal = g._stakeSharesTotal;
		gSnapshot._latestStakeId = g._latestStakeId;
	}

	function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot)
		internal
	{
		if (
			g._lockedSunsTotal != gSnapshot._lockedSunsTotal ||
			g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal ||
			g._shareRate != gSnapshot._shareRate ||
			g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal
		) {
			globals.lockedSunsTotal = uint72(g._lockedSunsTotal);
			globals.nextStakeSharesTotal = uint72(g._nextStakeSharesTotal);
			globals.shareRate = uint40(g._shareRate);
			globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
		}
		if (
			g._dailyDataCount != gSnapshot._dailyDataCount ||
			g._stakeSharesTotal != gSnapshot._stakeSharesTotal ||
			g._latestStakeId != gSnapshot._latestStakeId
		) {
			globals.dailyDataCount = uint16(g._dailyDataCount);
			globals.stakeSharesTotal = uint72(g._stakeSharesTotal);
			globals.latestStakeId = g._latestStakeId;
		}
	}

	function _stakeLoad(
		StakeStore storage stRef,
		uint40 stakeIdParam,
		StakeCache memory st
	) internal view {
		/* Ensure caller's stakeIndex is still current */
		require(
			stakeIdParam == stRef.stakeId,
			"VENT: stakeIdParam not in stake"
		);

		st._stakeId = stRef.stakeId;
		st._stakedSuns = stRef.stakedSuns;
		st._stakeShares = stRef.stakeShares;
		st._lockedDay = stRef.lockedDay;
		st._stakedDays = stRef.stakedDays;
		st._unlockedDay = stRef.unlockedDay;
	}

	function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
		internal
	{
		stRef.stakeId = st._stakeId;
		stRef.stakedSuns = uint72(st._stakedSuns);
		stRef.stakeShares = uint72(st._stakeShares);
		stRef.lockedDay = uint16(st._lockedDay);
		stRef.stakedDays = uint16(st._stakedDays);
		stRef.unlockedDay = uint16(st._unlockedDay);
	}

	function _stakeAdd(
		StakeStore[] storage stakeListRef,
		uint40 newStakeId,
		uint256 newStakedSuns,
		uint256 newStakeShares,
		uint256 newLockedDay,
		uint256 newStakedDays
	) internal {
		stakeListRef.push(
			StakeStore(
				newStakeId,
				uint72(newStakedSuns),
				uint72(newStakeShares),
				uint16(newLockedDay),
				uint16(newStakedDays),
				uint16(0) // unlockedDay
			)
		);
	}

	/**
	 * @dev Efficiently delete from an unordered array by moving the last element
	 * to the "hole" and reducing the array length. Can change the order of the list
	 * and invalidate previously held indexes.
	 * @notice stakeListRef length and stakeIndex are already ensured valid in stakeEnd()
	 * @param stakeListRef Reference to stakeLists[stakerAddr] array in storage
	 * @param stakeIndex Index of the element to delete
	 */
	function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex)
		internal
	{
		uint256 lastIndex = stakeListRef.length - 1;

		/* Skip the copy if element to be removed is already the last element */
		if (stakeIndex != lastIndex) {
			/* Copy last element to the requested element's "hole" */
			stakeListRef[stakeIndex] = stakeListRef[lastIndex];
		}

		/*
			Reduce the array length now that the array is contiguous.
			Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
		*/
		stakeListRef.pop();
	}

	/**
	 * @dev Estimate the stake payout for an incomplete day
	 * @param g Cache of stored globals
	 * @param stakeSharesParam Param from stake to calculate bonuses for
	 * @param day Day to calculate bonuses for
	 * @return Payout in Suns
	 */
	function _estimatePayoutRewardsDay(
		GlobalsCache memory g,
		uint256 stakeSharesParam,
		uint256 day
	) internal view returns (uint256 payout) {
		/* Prevent updating state for this estimation */
		GlobalsCache memory gTmp;
		_globalsCacheSnapshot(g, gTmp);

		DailyRoundState memory rs;
		rs._allocSupplyCached = totalSupply() + g._lockedSunsTotal;

		_dailyRoundCalc(gTmp, rs, day);

		/* Stake is no longer locked so it must be added to total as if it were */
		gTmp._stakeSharesTotal += stakeSharesParam;

		payout = (rs._payoutTotal * stakeSharesParam) / gTmp._stakeSharesTotal;

		return payout;
	}

	function _dailyRoundCalc(
		GlobalsCache memory g,
		DailyRoundState memory rs,
		uint256 day
	) private view {
		/*
			Calculate payout round Corrected and Adjusted

			Inflation of 8% inflation per 364 days             (approx 1 year)
			dailyInterestRate   = exp(ln(1 + 8%)  / 364) - 1
								= exp(ln(1 + 0.08) / 364) - 1
								= exp(ln(1.08) / 364) - 1
								= 0.00021145378          (approx)

			payout  = allocSupply * dailyInterestRate
					= allocSupply / (1 / dailyInterestRate)
					= allocSupply / (1 / 0.00021145378)
					= allocSupply / 4729.16587256            (approx)
					= allocSupply * 50000 / 47291658             (* 50000/50000 for int precision)
		*/
		/* 8 % payout instead of 5.42    */
		rs._payoutTotal = ((rs._allocSupplyCached * 50000) / 47291658);

		if (g._stakePenaltyTotal != 0) {
			rs._payoutTotal += g._stakePenaltyTotal;
			g._stakePenaltyTotal = 0;
		}
	}

	function _dailyRoundCalcAndStore(
		GlobalsCache memory g,
		DailyRoundState memory rs,
		uint256 day
	) private {
		_dailyRoundCalc(g, rs, day);

		dailyData[day].dayPayoutTotal = uint72(rs._payoutTotal);
		dailyData[day].dayDividends = xfLobby[day];
		dailyData[day].dayStakeSharesTotal = uint72(g._stakeSharesTotal);
	}

	function _dailyDataUpdate(
		GlobalsCache memory g,
		uint256 beforeDay,
		bool isAutoUpdate
	) private {
		if (g._dailyDataCount >= beforeDay) {
			/* Already up-to-date */
			return;
		}

		DailyRoundState memory rs;
		rs._allocSupplyCached = totalSupply() + g._lockedSunsTotal;

		uint256 day = g._dailyDataCount;

		_dailyRoundCalcAndStore(g, rs, day);

		/* Stakes started during this day are added to the total the next day */
		if (g._nextStakeSharesTotal != 0) {
			g._stakeSharesTotal += g._nextStakeSharesTotal;
			g._nextStakeSharesTotal = 0;
		}

		while (++day < beforeDay) {
			_dailyRoundCalcAndStore(g, rs, day);
		}
 		 
		emit DailyDataUpdate(
			msg.sender,
			block.timestamp,
			g._dailyDataCount,
			day
		);

		g._dailyDataCount = day;
	}    

}

// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * there is an account (an owner) that can be granted exclusive access to
//  * specific functions.
//  *
//  * By default, the owner account will be the one that deploys the contract. This
//  * can later be changed with {transferOwnership}.
//  *
//  * This module is used through inheritance. It will make available the modifier
//  * `onlyOwner`, which can be applied to your functions to restrict their use to
//  * the owner.
//  */
// contract Ownable {
//   address private _owner;

//   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//   /**
//    * @dev Initializes the contract setting the deployer as the initial owner.
//    */
//   constructor () internal {
//     _owner = msgSender;
//     emit OwnershipTransferred(address(0), msgSender);
//   }

//   /**
//    * @dev Returns the address of the current owner.
//    */
//   function owner() public view returns (address) {
//     return _owner;
//   }

//   /**
//    * @dev Throws if called by any account other than the owner.
//    */
//   modifier onlyOwner() {
//     require(_owner == _msgSender(), "Ownable: caller is not the owner");
//     _;
//   }

//   /**
//    * @dev Leaves the contract without owner. It will not be possible to call
//    * `onlyOwner` functions anymore. Can only be called by the current owner.
//    *
//    * NOTE: Renouncing ownership will leave the contract without an owner,
//    * thereby removing any functionality that is only available to the owner.
//    */
//   function renounceOwnership() public onlyOwner {
//     emit OwnershipTransferred(_owner, address(0));
//     _owner = address(0);
//   }

//   /**
//    * @dev Transfers ownership of the contract to a new account (`newOwner`).
//    * Can only be called by the current owner.
//    */
//   function transferOwnership(address newOwner) public onlyOwner {
//     _transferOwnership(newOwner);
//   }

//   /**
//    * @dev Transfers ownership of the contract to a new account (`newOwner`).
//    */
//   function _transferOwnership(address newOwner) internal {
//     require(newOwner != address(0), "Ownable: new owner is the zero address");
//     emit OwnershipTransferred(_owner, newOwner);
//     _owner = newOwner;
//   }
// }

contract StakeableToken is GlobalsAndUtility {
	/**
	 * @dev PUBLIC FACING: Open a stake.
	 * @param newStakedSuns Number of Suns to stake
	 * @param newStakedDays Number of days to stake
	 */
	function stakeStart(uint256 newStakedSuns, uint256 newStakedDays) external {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		/* Enforce the minimum stake time */
		require(
			newStakedDays >= MIN_STAKE_DAYS,
			"VENT: newStakedDays lower than minimum"
		);

		/* Check if log data needs to be updated */
		_dailyDataUpdateAuto(g);

		_stakeStart(g, newStakedSuns, newStakedDays);

		/* Remove staked Suns from balance of staker */
		_burn(msg.sender, newStakedSuns);

		_globalsSync(g, gSnapshot);
	}

	/**
	 * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
	 * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
	 * @param stakerAddr Address of staker
	 * @param stakeIndex Index of stake within stake list
	 * @param stakeIdParam The stake's id
	 */
	function stakeGoodAccounting(
		address stakerAddr,
		uint256 stakeIndex,
		uint40 stakeIdParam
	) external {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		/* require() is more informative than the default assert() */
		require(stakeLists[stakerAddr].length != 0, "VENT: Empty stake list");
		require(
			stakeIndex < stakeLists[stakerAddr].length,
			"VENT: stakeIndex invalid"
		);

		StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];

		/* Get stake copy */
		StakeCache memory st;
		_stakeLoad(stRef, stakeIdParam, st);

		/* Stake must have served full term */
		require(
			g._currentDay >= st._lockedDay + st._stakedDays,
			"VENT: Stake not fully served"
		);

		/* Stake must still be locked */
		require(st._unlockedDay == 0, "VENT: Stake already unlocked");

		/* Check if log data needs to be updated */
		_dailyDataUpdateAuto(g);

		/* Unlock the completed stake */
		_stakeUnlock(g, st);

		/* stakeReturn & dividends values are unused here */
		(
			,
			uint256 payout,
			uint256 dividends,
			uint256 penalty,
			uint256 cappedPenalty
		) = _stakePerformance(g, st, st._stakedDays);

		emit StakeGoodAccounting(
			stakeIdParam,
			stakerAddr,
			msg.sender,
			st._stakedSuns,
			st._stakeShares,
			payout,
			penalty
		);

		if (cappedPenalty != 0) {
			g._stakePenaltyTotal += cappedPenalty;
		}

		/* st._unlockedDay has changed */
		_stakeUpdate(stRef, st);

		_globalsSync(g, gSnapshot);
	}

	/**
	 * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
	 * a stake id is used to reject stale indexes.
	 * @param stakeIndex Index of stake within stake list
	 * @param stakeIdParam The stake's id
	 */
	function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		StakeStore[] storage stakeListRef = stakeLists[msg.sender];

		/* require() is more informative than the default assert() */
		require(stakeListRef.length != 0, "VENT: Empty stake list");
		require(stakeIndex < stakeListRef.length, "VENT: stakeIndex invalid");

		/* Get stake copy */
		StakeCache memory st;
		_stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

		/* Check if log data needs to be updated */
		_dailyDataUpdateAuto(g);

		uint256 servedDays = 0;

		bool prevUnlocked = (st._unlockedDay != 0);
		uint256 stakeReturn;
		uint256 payout = 0;
		uint256 dividends = 0;
		uint256 penalty = 0;
		uint256 cappedPenalty = 0;

		if (g._currentDay >= st._lockedDay) {
			if (prevUnlocked) {
				/* Previously unlocked in stakeGoodAccounting(), so must have served full term */
				servedDays = st._stakedDays;
			} else {
				_stakeUnlock(g, st);

				servedDays = g._currentDay - st._lockedDay;
				if (servedDays > st._stakedDays) {
					servedDays = st._stakedDays;
				}
			}

			(
				stakeReturn,
				payout,
				dividends,
				penalty,
				cappedPenalty
			) = _stakePerformance(g, st, servedDays);
          
			msg.sender.transfer(dividends);
		} else {
			/* Stake hasn't been added to the total yet, so no penalties or rewards apply */
			g._nextStakeSharesTotal -= st._stakeShares;

			stakeReturn = st._stakedSuns;
		}

		emit StakeEnd(
			stakeIdParam,
			prevUnlocked ? 1 : 0,
			msg.sender,
			st._lockedDay,
			servedDays,
			st._stakedSuns,
			st._stakeShares,
			dividends,
			payout,
			penalty,
			stakeReturn
		);

		if (cappedPenalty != 0 && !prevUnlocked) {
			/* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
			g._stakePenaltyTotal += cappedPenalty;
		}

		/* Pay the stake return, if any, to the staker */
		if (stakeReturn != 0) {
			_mint(msg.sender, stakeReturn);

			/* Update the share rate if necessary */
			_shareRateUpdate(g, st, stakeReturn);
		}
		g._lockedSunsTotal -= st._stakedSuns;

		_stakeRemove(stakeListRef, stakeIndex);

		_globalsSync(g, gSnapshot);
	}

	/**
	 * @dev PUBLIC FACING: Closes a stake by rolling. The order of the stake list can 
	 * change so a stake id is used to reject stale indexes.
	 * @param stakeIndex Index of stake within stake list
	 * @param stakeIdParam The stake's id
	 */
	function rollStake(uint256 stakeIndex, uint40 stakeIdParam) external {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		StakeStore[] storage stakeListRef = stakeLists[msg.sender];

		/* require() is more informative than the default assert() */
		require(stakeListRef.length != 0, "VENT: Empty stake list");
		require(stakeIndex < stakeListRef.length, "VENT: stakeIndex invalid");

		/* Get stake copy */
		StakeCache memory st;
		_stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

		/* Check if log data needs to be updated */
		_dailyDataUpdateAuto(g);

		uint256 servedDays = 0;

		bool prevUnlocked = (st._unlockedDay != 0);
		uint256 stakeReturn;
		uint256 payout = 0;
		uint256 dividends = 0;
		uint256 penalty = 0;
		uint256 cappedPenalty = 0;

		if (g._currentDay >= st._lockedDay) {
			if (prevUnlocked) {
				/* Previously unlocked in stakeGoodAccounting(), so must have served full term */
				servedDays = st._stakedDays;
			} else {
				_stakeUnlock(g, st);

				servedDays = g._currentDay - st._lockedDay;
				if (servedDays > st._stakedDays) {
					servedDays = st._stakedDays;
				}
			}

			(
				stakeReturn,
				payout,
				dividends,
				penalty,
				cappedPenalty
			) = _stakePerformance(g, st, servedDays);


		    /* Instead of transferring dividends to user, roll them to VentLink */
			_deposit(msg.sender, dividends);
		} else {
			/* Stake hasn't been added to the total yet, so no penalties or rewards apply */
			g._nextStakeSharesTotal -= st._stakeShares;

			stakeReturn = st._stakedSuns;
		}

		emit StakeEnd(
			stakeIdParam,
			prevUnlocked ? 1 : 0,
			msg.sender,
			st._lockedDay,
			servedDays,
			st._stakedSuns,
			st._stakeShares,
			dividends,
			payout,
			penalty,
			stakeReturn
		);

		if (cappedPenalty != 0 && !prevUnlocked) {
			/* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
			g._stakePenaltyTotal += cappedPenalty;
		}

		/* Pay the stake return, if any, to the staker */
		if (stakeReturn != 0) {
			_mint(msg.sender, stakeReturn);

			/* Update the share rate if necessary */
			_shareRateUpdate(g, st, stakeReturn);
		}
		g._lockedSunsTotal -= st._stakedSuns;

		_stakeRemove(stakeListRef, stakeIndex);

		_globalsSync(g, gSnapshot);
	}

	/**
	 * @dev PUBLIC FACING: Return the current stake count for a staker address
	 * @param stakerAddr Address of staker
	 */
	function stakeCount(address stakerAddr) external view returns (uint256) {
		return stakeLists[stakerAddr].length;
	}

	/**
	 * @dev Open a stake.
	 * @param g Cache of stored globals
	 * @param newStakedSuns Number of Suns to stake
	 * @param newStakedDays Number of days to stake
	 */
	function _stakeStart(
		GlobalsCache memory g,
		uint256 newStakedSuns,
		uint256 newStakedDays
	) internal {
		/* Enforce the maximum stake time */
		require(
			newStakedDays <= MAX_STAKE_DAYS,
			"VENT: newStakedDays higher than maximum"
		);

		uint256 bonusSuns = _stakeStartBonusSuns(newStakedSuns, newStakedDays);
		uint256 newStakeShares =
			((newStakedSuns + bonusSuns) * SHARE_RATE_SCALE) / g._shareRate;

		/* Ensure newStakedSuns is enough for at least one stake share */
		require(
			newStakeShares != 0,
			"VENT: newStakedSuns must be at least minimum shareRate"
		);

		/*
			The stakeStart timestamp will always be part-way through the current
			day, so it needs to be rounded-up to the next day to ensure all
			stakes align with the same fixed calendar days. The current day is
			already rounded-down, so rounded-up is current day + 1.
		*/
		uint256 newLockedDay = g._currentDay + 1;

		/* Create Stake */
		uint40 newStakeId = ++g._latestStakeId;
		_stakeAdd(
			stakeLists[msg.sender],
			newStakeId,
			newStakedSuns,
			newStakeShares,
			newLockedDay,
			newStakedDays
		);

		emit StakeStart(
			newStakeId,
			msg.sender,
			newStakedSuns,
			newStakeShares,
			newStakedDays
		);

		/* Stake is added to total in the next round, not the current round */
		g._nextStakeSharesTotal += newStakeShares;

		/* Track total staked Suns for inflation calculations */
		g._lockedSunsTotal += newStakedSuns;
	}

	/**
	 * @dev Calculates total stake payout including rewards for a multi-day range
	 * @param g Cache of stored globals
	 * @param stakeSharesParam Param from stake to calculate bonuses for
	 * @param beginDay First day to calculate bonuses for
	 * @param endDay Last day (non-inclusive) of range to calculate bonuses for
	 * @return Payout in Suns
	 */
	function _calcPayoutRewards(
		GlobalsCache memory g,
		uint256 stakeSharesParam,
		uint256 beginDay, 
		uint256 endDay 
	) private view returns (uint256 payout) {
		uint256 counter;

		for (uint256 day = beginDay; day < endDay; day++) {
			uint256 dayPayout;

			dayPayout =
				(dailyData[day].dayPayoutTotal * stakeSharesParam) /
				dailyData[day].dayStakeSharesTotal;

			if (counter < 4) {
				counter++;
			}
			/* Eligible to receive bonus */
			else {
				dayPayout =
					((dailyData[day].dayPayoutTotal * stakeSharesParam) /
						dailyData[day].dayStakeSharesTotal) *
					BONUS_DAY_SCALE;
				counter = 0;
			}

			payout += dayPayout;
		}

		return payout;
	}

	/**
	 * @dev Calculates user dividends
	 * @param g Cache of stored globals
	 * @param stakeSharesParam Param from stake to calculate bonuses for
	 * @param beginDay First day to calculate bonuses for
	 * @param endDay Last day (non-inclusive) of range to calculate bonuses for
	 * @return Payout in Suns
	 */
	function _calcPayoutDividendsReward(
		GlobalsCache memory g,
		uint256 stakeSharesParam,
		uint256 beginDay,
		uint256 endDay,
		uint256 currentDay
	) private view returns (uint256 payout) {
		for (uint256 day = beginDay; day < endDay; day++) {
			uint256 dayPayout;

			/* user's share of 96% of the day's dividends */
			dayPayout +=
				(((dailyData[day].dayDividends * 96) / 100) *
					stakeSharesParam) /
				dailyData[day].dayStakeSharesTotal;

			payout += dayPayout;
		}

		return payout;
	}

	/**
	 * @dev Calculate bonus Suns for a new stake, if any
	 * @param newStakedSuns Number of Suns to stake
	 * @param newStakedDays Number of days to stake
	 */
	function _stakeStartBonusSuns(uint256 newStakedSuns, uint256 newStakedDays)
		private
		view
		returns (uint256 bonusSuns)
	{
		/*
		LONGER PAYS BETTER:

		If longer than 1 day stake is committed to, each extra day
		gives bonus shares of approximately 0.0548%, which is approximately 20%
		extra per year of increased stake length committed to, but capped to a
		maximum of 200% extra.

		extraDays       =  stakedDays - 1

		longerBonus%    = (extraDays / 364) * 20%
						= (extraDays / 364) / 5
						=  extraDays / 1820
						=  extraDays / LPB

		extraDays       =  longerBonus% * 1820
		extraDaysMax    =  longerBonusMax% * 1820
						=  200% * 1820
						=  3640
						=  LPB_MAX_DAYS

		BIGGER PAYS BETTER:

		Bonus percentage scaled 0% to 10% for the first 7M VENT of stake.

		biggerBonus%    = (cappedSuns /  BPB_MAX_SUNS) * 10%
						= (cappedSuns /  BPB_MAX_SUNS) / 10
						=  cappedSuns / (BPB_MAX_SUNS * 10)
						=  cappedSuns /  BPB

		COMBINED:

		combinedBonus%  =            longerBonus%  +  biggerBonus%

								  cappedExtraDays     cappedSuns
						=         ---------------  +  ------------
										LPB               BPB

							cappedExtraDays * BPB     cappedSuns * LPB
						=   ---------------------  +  ------------------
								  LPB * BPB               LPB * BPB

							cappedExtraDays * BPB  +  cappedSuns * LPB
						=   --------------------------------------------
											  LPB  *  BPB

		bonusSuns     = suns * combinedBonus%
						= suns * (cappedExtraDays * BPB  +  cappedSuns * LPB) / (LPB * BPB)
	*/
		uint256 cappedExtraDays = 0;

        /* Must be more than 1 day for Longer-Pays-Better */
        if (newStakedDays > 1) {
            cappedExtraDays = newStakedDays <= LPB_MAX_DAYS ? newStakedDays - 1 : LPB_MAX_DAYS;
        }

        uint256 cappedStakedSuns = newStakedSuns <= BPB_MAX_SUNS
            ? newStakedSuns
            : BPB_MAX_SUNS;

        bonusSuns = cappedExtraDays * BPB + cappedStakedSuns * LPB;
        bonusSuns = newStakedSuns * bonusSuns / (LPB * BPB);

        return bonusSuns;
    }

	function _stakeUnlock(GlobalsCache memory g, StakeCache memory st)
		private
		pure
	{
		g._stakeSharesTotal -= st._stakeShares;
		st._unlockedDay = g._currentDay;
	}

	function _stakePerformance(
		GlobalsCache memory g,
		StakeCache memory st,
		uint256 servedDays
	)
		private
		view
		returns (
			uint256 stakeReturn,
			uint256 payout,
			uint256 dividends,
			uint256 penalty,
			uint256 cappedPenalty
		)
	{
        /*Suicide prevention hotline: 800-273-8255 */
		if (servedDays < st._stakedDays) {
            /*VENT Payouts - Return full amount for now*/
			(payout, penalty) = _calcPayoutAndEarlyPenalty(
				g,
				st._lockedDay,
				st._stakedDays,
				servedDays,
				st._stakeShares
			);
			stakeReturn = st._stakedSuns + payout;
            /* Burn 95% of VENT after calculations for penalty */
            stakeReturn = stakeReturn * 5 / 100;

            /*BNB Payouts - Return full amount for now*/
			dividends = _calcPayoutDividendsReward(
				g,
				st._stakeShares,
				st._lockedDay,
				st._lockedDay + servedDays,
				servedDays
			);
            /* Send 85% of BNB after calculations to VentLink for penalty */
            dividends = dividends * 15 / 100;
              
		} else {
			// servedDays must == stakedDays here
            /*VENT Payouts - Return full amount for now*/
			payout = _calcPayoutRewards(
				g,
				st._stakeShares,
				st._lockedDay,
				st._lockedDay + servedDays
			);    
           
            /*BNB Payouts (Full Amount Gets Paid)*/
			dividends = _calcPayoutDividendsReward(
				g,
				st._stakeShares,
				st._lockedDay,
				st._lockedDay + servedDays,
				servedDays
			);			  
			
			stakeReturn = st._stakedSuns + payout; 
   			/* Burn 80% of VENT after full stake */
            stakeReturn = stakeReturn * 20 / 100;   
			
			/* Check Grace Period For Late Claim */
			penalty = _calcLatePenalty(
				st._lockedDay,
				st._stakedDays,
				st._unlockedDay,
				stakeReturn
			);
        
        }
		if (penalty != 0) {
			if (penalty > stakeReturn) {
				/* Cannot have a negative stake return */
				cappedPenalty = stakeReturn;
				stakeReturn = 0;
			} else {
				/* Remove penalty from the stake return */
				cappedPenalty = penalty;
				stakeReturn -= cappedPenalty;
            }
		}
      		return (stakeReturn, payout, dividends, penalty, cappedPenalty);
	}
    
    /*VENT 96% Payouts and BNB Early Penalty*/
	function _calcPayoutAndEarlyPenalty(
		GlobalsCache memory g,
		uint256 lockedDayParam,
		uint256 stakedDaysParam,
		uint256 servedDays,
		uint256 stakeSharesParam
	) private view returns (uint256 payout, uint256 penalty) {
		uint256 servedEndDay = lockedDayParam + servedDays;

		/* 100% of stakedDays */
		uint256 penaltyDays = (stakedDaysParam + 1);
		

		if (servedDays == 0) {
			/* Fill penalty days with the estimated average payout */
			uint256 expected =
				_estimatePayoutRewardsDay(g, stakeSharesParam, lockedDayParam);
			penalty = expected * penaltyDays;
			return (payout, penalty); // Actual payout was 0
		}

        /* Full amount of VENT penalty applies - Max */
		if (penaltyDays < servedDays) {
			/*
				Simplified explanation of intervals where end-day is non-inclusive:

				penalty:    [lockedDay  ...  penaltyEndDay)
				delta:                      [penaltyEndDay  ...  servedEndDay)
				payout:     [lockedDay  .......................  servedEndDay)
			*/
			uint256 penaltyEndDay = lockedDayParam + penaltyDays;
			penalty = _calcPayoutRewards(
				g,
				stakeSharesParam,
				lockedDayParam,
				penaltyEndDay
			);

			uint256 delta =
				_calcPayoutRewards(
					g,
					stakeSharesParam,
					penaltyEndDay,
					servedEndDay
				);
			payout = penalty + delta;   
			return (payout, penalty);
		}

		/* penaltyDays >= servedDays  */
		payout = _calcPayoutRewards(
			g,
			stakeSharesParam,
			lockedDayParam,
			servedEndDay
		);

		if (penaltyDays == servedDays) {
			penalty = payout;
		} else {
			/*
				(penaltyDays > servedDays) means not enough days served, so fill the
				penalty days with the average payout from only the days that were served.
			*/
			penalty = payout * penaltyDays / servedDays;}
		return (payout, penalty);
	}

	function _calcLatePenalty(
		uint256 lockedDayParam,
		uint256 stakedDaysParam,
		uint256 unlockedDayParam,
		uint256 rawStakeReturn
	) private pure returns (uint256) {
		/* Allow grace time before penalties accrue */
		uint256 maxUnlockedDay =
			lockedDayParam + stakedDaysParam + LATE_PENALTY_GRACE_DAYS;
		if (unlockedDayParam <= maxUnlockedDay) {
			return 0;
		}

        /* If a stake is left open more than the LATE_PENALTY_GRACE_DAYS, apply the same penalty on BNB as early unstakes */
        /* Apply 95% burn rate to VENT dividends for claiming late and return as penalty amount */
        rawStakeReturn = rawStakeReturn * 5 / 100;
        return rawStakeReturn;
	}

	function _shareRateUpdate(
		GlobalsCache memory g,
		StakeCache memory st,
		uint256 stakeReturn
	) private {
		if (stakeReturn > st._stakedSuns) {
			/*
				Calculate the new shareRate that would yield the same number of shares if
				the user re-staked this stakeReturn, factoring in any bonuses they would
				receive in stakeStart().
			*/
			uint256 bonusSuns =
				_stakeStartBonusSuns(stakeReturn, st._stakedDays);
			uint256 newShareRate =
				((stakeReturn + bonusSuns) * SHARE_RATE_SCALE) /
					st._stakeShares;

			if (newShareRate > SHARE_RATE_MAX) {
				/*
					Realistically this can't happen, but there are contrived theoretical
					scenarios that can lead to extreme values of newShareRate, so it is
					capped to prevent them anyway.
				*/
				newShareRate = SHARE_RATE_MAX;
			}

			if (newShareRate > g._shareRate) {
				g._shareRate = newShareRate;

				emit ShareRateChange(
					st._stakeId,
					block.timestamp,
					newShareRate
				);
			}
		}
	}
	
   /**
   * @dev add an address to the user struct
   * @param addr address
   * @return true if the address was added to the user struct, false if the address was already in the struct or failed
   */
  function initializeVentlinkUpline(address addr) public returns(bool success) {
   		users[addr].payouts = 0;
		users[addr].deposit_amount = 0;
		users[addr].deposit_payouts = 0;
		users[addr].deposit_time = uint40(block.timestamp);
		users[addr].total_deposits += 0;

		users[addr].upline = deployer;			
	}

  	/* Handle VentLink Uplines 
    */

    function _setUpline(address _addr, address _upline) internal {
		if (
			users[_addr].upline == address(0) && 
			users[_upline].deposit_amount == 0
		) {
			users[_upline].payouts = 0;
			users[_upline].deposit_amount = 0;
			users[_upline].deposit_payouts = 0;
			users[_upline].deposit_time = uint40(block.timestamp);
			users[_upline].total_deposits += 0;			
		}

		if (
			users[_addr].upline == address(0) &&
			_upline != _addr &&
			_addr != deployer &&
			(users[_upline].deposit_time > 0 || _upline == deployer)
		) {
			users[_addr].upline = _upline;
			users[_upline].referrals++;

			emit Upline(_addr, _upline);

			total_users++;

			for (uint8 i = 0; i < ref_bonuses.length; i++) {
				if (_upline == address(0)) break;

				users[_upline].total_structure++;

				_upline = users[_upline].upline;
			}
		}
	}

 	/* Handle VentLink Functions after rolling a stake
    */

    function _deposit(address _addr, uint256 _amount) internal {
		require(
			users[_addr].upline != address(0) || _addr == deployer,
			"No upline"
		);

		if (users[_addr].deposit_time > 0) {
			users[_addr].cycle++;

			require(
				users[_addr].payouts >=
					this.maxPayoutOf(users[_addr].deposit_amount),
				"Deposit already exists"
			);
			require(
				_amount >= users[_addr].deposit_amount &&
					_amount <=
					cycles[
						users[_addr].cycle > cycles.length - 1
							? cycles.length - 1
							: users[_addr].cycle
					],
				"Bad amount"
			);
		} else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");

		users[_addr].payouts = 0;
		users[_addr].deposit_amount = _amount;
		users[_addr].deposit_payouts = 0;
		users[_addr].deposit_time = uint40(block.timestamp);
		users[_addr].total_deposits += _amount;

		total_deposited += _amount;

		emit NewDeposit(_addr, _amount);

		if (users[_addr].upline != address(0)) {
			users[users[_addr].upline].direct_bonus += _amount / 10;

			emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
		}

	}
 
	function _refPayout(address _addr, uint256 _amount) private {
		address up = users[_addr].upline;

		for (uint8 i = 0; i < ref_bonuses.length; i++) {
			if (up == address(0)) break;

			if (users[up].referrals >= i + 1) {
				uint256 bonus = (_amount * ref_bonuses[i]) / 100;

				users[up].match_bonus += bonus;

				emit MatchPayout(up, _addr, bonus);
			}

			up = users[up].upline;
		}
	}

	function withdraw() external {
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Full payouts");

		// Deposit payout
		if (to_payout > 0) {
			if (users[msg.sender].payouts + to_payout > max_payout) {
				to_payout = max_payout - users[msg.sender].payouts;
			}

			users[msg.sender].deposit_payouts += to_payout;
			users[msg.sender].payouts += to_payout;

			_refPayout(msg.sender, to_payout);
		}

		// Direct payout
		if (
			users[msg.sender].payouts < max_payout &&
			users[msg.sender].direct_bonus > 0
		) {
			uint256 direct_bonus = users[msg.sender].direct_bonus;

			if (users[msg.sender].payouts + direct_bonus > max_payout) {
				direct_bonus = max_payout - users[msg.sender].payouts;
			}

			users[msg.sender].direct_bonus -= direct_bonus;
			users[msg.sender].payouts += direct_bonus;
			to_payout += direct_bonus;
		}

		// Match payout
		if (
			users[msg.sender].payouts < max_payout &&
			users[msg.sender].match_bonus > 0
		) {
			uint256 match_bonus = users[msg.sender].match_bonus;

			if (users[msg.sender].payouts + match_bonus > max_payout) {
				match_bonus = max_payout - users[msg.sender].payouts;
			}

			users[msg.sender].match_bonus -= match_bonus;
			users[msg.sender].payouts += match_bonus;
			to_payout += match_bonus;
		}

		require(to_payout > 0, "Zero payout");

		users[msg.sender].total_payouts += to_payout;
		total_withdraw += to_payout;

		msg.sender.transfer(to_payout);

		emit Withdraw(msg.sender, to_payout);

		if (users[msg.sender].payouts >= max_payout) {
			emit LimitReached(msg.sender, users[msg.sender].payouts);
		}	
	}

	function maxPayoutOf(uint256 _amount) external pure returns (uint256) {
		return (_amount * 31) / 10;
	}

	function payoutOf(address _addr)
		external
		view
		returns (uint256 payout, uint256 max_payout)
	{
		max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

		if (users[_addr].deposit_payouts < max_payout) {
			payout =
				((users[_addr].deposit_amount *
					((block.timestamp - users[_addr].deposit_time) / 1 days)) /
					100) -
				users[_addr].deposit_payouts;

			if (users[_addr].deposit_payouts + payout > max_payout) {
				payout = max_payout - users[_addr].deposit_payouts;
			}
		}
	}

	/*
		Only external call
	*/
	function userInfo(address _addr)
		external
		view
		returns (
			address upline,
			uint40 deposit_time,
			uint256 deposit_amount,
			uint256 payouts,
			uint256 direct_bonus,
			uint256 match_bonus
		)
	{
		return (
			users[_addr].upline,
			users[_addr].deposit_time,
			users[_addr].deposit_amount,
			users[_addr].payouts,
			users[_addr].direct_bonus,
			users[_addr].match_bonus
		);
	}

	function userInfoTotals(address _addr)
		external
		view
		returns (
			uint256 referrals,
			uint256 total_deposits,
			uint256 total_payouts,
			uint256 total_structure
		)
	{
		return (
			users[_addr].referrals,
			users[_addr].total_deposits,
			users[_addr].total_payouts,
			users[_addr].total_structure
		);
	}

	function contractInfo()
		external
		view
		returns (
			uint256 _total_users,
			uint256 _total_deposited,
			uint256 _total_withdraw
		)
	{
		return (
			total_users,
			total_deposited,
			total_withdraw
		);
	}

}

contract TransformableToken is StakeableToken {
  	/**
	 * @dev PUBLIC FACING: Enter the auction lobby for the current round
	 * @param referrerAddr BNB address of referring user (optional; 0x0 for no referrer)
	 */ 
	function xfLobbyEnter(address referrerAddr) public payable {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		require(_currentDay() > 0, "VENT: Auction has not begun yet");
       
		uint256 enterDay = _currentDay();

		uint256 rawAmount = msg.value;
		require(rawAmount != 0, "BNB: Amount required");
		require(rawAmount >= 1 * (10**16), "BNB: Amount must be over 0.01");
		require(referrerAddr != msg.sender, "Self Referral is not allowed");

        if (referrerAddr == address(0)) {
				/* No referrer */
				referrerAddr = FLUSH_ADDR;		 
				XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];
				
				uint256 entryIndex = qRef.tailIndex++;
				uint256 headIndex = qRef.headIndex;

				qRef.entries[entryIndex] = XfLobbyEntryStore(
					uint96(rawAmount),
					referrerAddr
				);

				xfLobby[enterDay] += rawAmount;
				
				_setUpline(msg.sender, referrerAddr);
				_emitXfLobbyEnter(enterDay, entryIndex, rawAmount);
				_emitXfLobbyRefEnter(enterDay, headIndex, referrerAddr);				
		} else {
		XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];
		
		uint256 entryIndex = qRef.tailIndex++;
		uint256 headIndex = qRef.headIndex;

		qRef.entries[entryIndex] = XfLobbyEntryStore(
			uint96(rawAmount),
			referrerAddr
		);

		xfLobby[enterDay] += rawAmount;
		
		_setUpline(msg.sender, referrerAddr);
		_emitXfLobbyEnter(enterDay, entryIndex, rawAmount);
		_emitXfLobbyRefEnter(enterDay, headIndex, referrerAddr);
		}
		
		/* Check if log data needs to be updated */
		_dailyDataUpdateAuto(g);
	}

	/**
	 * @dev PUBLIC FACING: Leave the transform lobby after the round is complete
	 * @param enterDay Day number when the member entered
	 * @param count Number of queued-enters to exit (optional; 0 for all)
	 */
	function xfLobbyExit(uint256 enterDay, uint256 count) public {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		require(enterDay < _currentDay(), "VENT: Round is not complete");

		XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

		uint256 headIndex = qRef.headIndex;
		uint256 endIndex;
 
		if (count != 0) {
			require(count <= qRef.tailIndex - headIndex, "VENT: count invalid");
			endIndex = headIndex + count;
		} else {
			endIndex = qRef.tailIndex;
			require(headIndex < endIndex, "VENT: count invalid");
		}

		uint256 waasLobby = _waasLobby(enterDay);
		uint256 _xfLobby = xfLobby[enterDay];
		uint256 totalXfAmount = 0;

		do {
			uint256 rawAmount = qRef.entries[headIndex].rawAmount;
			address referrerAddr = qRef.entries[headIndex].referrerAddr;

			delete qRef.entries[headIndex];

			uint256 xfAmount = waasLobby * rawAmount / _xfLobby;

			if (referrerAddr == address(0) || referrerAddr == msg.sender) {
				/* No referrer or Self-referred - Shouldn't be able to get here*/
				referrerAddr = FLUSH_ADDR;
				_setUpline(msg.sender, referrerAddr); 
				_emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
				
			} else {
				/* Referral bonus of 10% of xfAmount to member */
				uint256 referralBonusSuns = xfAmount / 10;

				xfAmount += referralBonusSuns;

				/* Then a cumulative referrer bonus of 10% to referrer */
				uint256 referrerBonusSuns = xfAmount / 10;
           
		   		_emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
				_emitXfLobbyReferrer(enterDay, headIndex, referrerBonusSuns, referrerAddr);
				_mint(referrerAddr, referrerBonusSuns);
		      
			}

			totalXfAmount += xfAmount;
		} while (++headIndex < endIndex);

		qRef.headIndex = uint40(headIndex);

		if (totalXfAmount != 0) {
			_mint(msg.sender, totalXfAmount);
		}

		/* Check if log data needs to be updated */
		_dailyDataUpdateAuto(g);
	}

	/**
	 * @dev PUBLIC FACING: External helper to return multiple values of xfLobby[] with
	 * a single call
	 * @param beginDay First day of data range
	 * @param endDay Last day (non-inclusive) of data range
	 * @return Fixed array of values
	 */
	function xfLobbyRange(uint256 beginDay, uint256 endDay)
		external
		view
		returns (uint256[] memory list)
	{
		require(
			beginDay < endDay && endDay <= _currentDay(),
			"VENT: invalid range"
		);

		list = new uint256[](endDay - beginDay);

		uint256 src = beginDay;
		uint256 dst = 0;
		do {
			list[dst++] = uint256(xfLobby[src++]);
		} while (src < endDay);

		return list;
	}

	/**
	 * @dev PUBLIC FACING: Release shares from daily dividends to budget and team and update finished stakes.
	 */
	function xfFlush() external {
		GlobalsCache memory g;
		GlobalsCache memory gSnapshot;
		_globalsLoad(g, gSnapshot);

		require(address(this).balance != 0, "VENT: No value");

		require(LAST_FLUSHED_DAY < _currentDay(), "VENT: Invalid day");

		_dailyDataUpdateAuto(g);

			/* Change to 1% for dev */
		FLUSH_ADDR.transfer(
			(dailyData[LAST_FLUSHED_DAY].dayDividends) / 100
		);
        /* Add Buybacks Budget account at 0.5% */
		FLUSH_ADDR_BUY.transfer(
			(dailyData[LAST_FLUSHED_DAY].dayDividends) / 200
		);
		/* Add Marketing Budget account at 0.5% */
		FLUSH_ADDR_MKT.transfer(
			(dailyData[LAST_FLUSHED_DAY].dayDividends) / 200
		);
		/* Add payouts for financial backers at 1% each */
		FLUSH_ADDR_FIN1.transfer(
			(dailyData[LAST_FLUSHED_DAY].dayDividends) / 100
		);
		FLUSH_ADDR_FIN2.transfer(
			(dailyData[LAST_FLUSHED_DAY].dayDividends) / 100
		);
        
		LAST_FLUSHED_DAY++;

		_globalsSync(g, gSnapshot);
	}

	/**
	 * @dev PUBLIC FACING: Return a current lobby member queue entry.
	 * Only needed due to limitations of the standard ABI encoder.
	 * @param memberAddr BNB address of the lobby member
	 * @param enterDay Day number when the member entered
	 * @param entryIndex Index of the users entry
	 * @return 1: Raw amount that was entered with; 2: Referring BNB addr (optional; 0x0 for no referrer)
	 */
	function xfLobbyEntry(
		address memberAddr,
		uint256 enterDay,
		uint256 entryIndex
	) external view returns (uint256 rawAmount, address referrerAddr) {
		XfLobbyEntryStore storage entry =
			xfLobbyMembers[enterDay][memberAddr].entries[entryIndex];

		require(entry.rawAmount != 0, "VENT: Param invalid");

		return (entry.rawAmount, entry.referrerAddr);
	}

	/**
	 * @dev PUBLIC FACING: Return the lobby days that a user is in with a single call
	 * @param memberAddr BNB address of the user
	 * @return Bit vector of lobby day numbers
	 */
	function xfLobbyPendingDays(address memberAddr)
		external
		view
		returns (uint256[XF_LOBBY_DAY_WORDS] memory words)
	{
		uint256 day = _currentDay() + 1;

		while (day-- != 0) {
			if (
				xfLobbyMembers[day][memberAddr].tailIndex >
				xfLobbyMembers[day][memberAddr].headIndex
			) {
				words[day >> 8] |= 1 << (day & 255);
			}
		}

		return words;
	}

	function _waasLobby(uint256 enterDay) private returns (uint256 waasLobby) {
		/* 410958904109  = ~ 1500000 * SUNS_PER_DIV /365  */
		if (enterDay > 0 && enterDay <= 365) {
			waasLobby = CLAIM_STARTING_AMOUNT - ((enterDay - 1) * 410958904109);
		} else {
			waasLobby = CLAIM_LOWEST_AMOUNT;
		}

		return waasLobby;
	}

    function _emitXfLobbyEnter(
		uint256 enterDay,
		uint256 entryIndex,
		uint256 rawAmount
	) private {
		emit XfLobbyEnter(
			block.timestamp,
			enterDay,
			entryIndex,
			rawAmount
		);
	}		
	

	function _emitXfLobbyExit(
		uint256 enterDay,
		uint256 entryIndex,
		uint256 xfAmount,
		address referrerAddr
	) private {
		emit XfLobbyExit(
			block.timestamp,
			enterDay,
			entryIndex,
			xfAmount,
			referrerAddr
		);
	}

	function _emitXfLobbyRefEnter(
		uint256 enterDay,
		uint256 entryIndex,		
		address referrerAddr
	) private {
		emit XfLobbyRefEnter(
			block.timestamp,
			enterDay,
			entryIndex,			
			referrerAddr
		);
	}

	function _emitXfLobbyReferrer(
		uint256 enterDay,
		uint256 entryIndex,
		uint256 referrerBonusSuns,
		address referrerAddr
	) private {
		emit XfLobbyReferrer(
			block.timestamp,
			enterDay,
			entryIndex,
			referrerBonusSuns,
			referrerAddr
		);
	}

}

contract VENT is TransformableToken {
	constructor() public {        

       	/* Initialize global shareRate to 1 */
		globals.shareRate = uint40(1 * SHARE_RATE_SCALE);

	}

	function() external payable {}
}