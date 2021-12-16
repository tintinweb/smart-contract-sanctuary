/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-18
*/

// SPDX-License-Identifier: --🤴--

pragma solidity ^0.7.4;

/*
 ______      _______   ____    ____
|   __  \   |    ___|  \   \  /   /
|  |__|  |  |   |___    \   \/   /
|       /   |   |___    /   /\   \
|__|\ ___\  |_______|  /___/  \___\

Latin: king, ruler, monarch

Name      :: XEN
Ticker    :: XEN
Decimals  :: 18

Website   :: https://www.XEN-token.com
Telegram  :: https://t.me/eth_rex
Twitter   :: https://twitter.com/rex_token
Discord   :: https://discord.gg/YYy4K3pTye

Concept   :: HYBRID-INTEREST TIME DEPOSITS
Special   :: RANDOM PERSONAL Big Pay Days
Category  :: Passive Income


XEN
Cryptocurrency & Certificate of Deposit
The world's most flexible token.

XEN is a cryptocurrency token for storing and transfering value.
In addition, XEN has built-in functions to deposit XEN tokens in
order to gain interest. In this manner, XEN may be regarded as a
Certificate of Deposit (CD).

XEN is the world's only CD token that lets you create time deposits,
name them, scrape off interest before maturity, split them and even
transfer them to other addresses. This makes XEN a most flexible and
powerful ecosystem for decentralized value transfers.

✓  XEN is an immutable smart contract.
✓  XEN provides its own BEP-20 / ERC-20 token, called $XEN.
✓  XEN has no owner, no admin and cannot be switched off.
✓  XEN provides daily auctions for transforming $BNB to $XEN.
✓  XEN provides brand new functions for time deposits of $XEN.
✓  XEN provides new hybrid-interest time deposits.
✓  XEN time deposits ("staking") gain more $XEN.
✓  XEN auction participants may get $XEN and $BNB.
✓  XEN has no fixed BigPayDays to avoid price dumps.
✓  XEN introduces “random personal BigPayDays”.
✓  XEN allows scraping off interest from immature deposits.
✓  XEN allows moving deposits to other addresses.
✓  XEN allows splitting deposits into two.
✓  XEN lets referrers claim 10% $XEN rewards.
✓  XEN lets referrers claim 4%-6% $BNB rewards in addition.
✓  XEN tokens are free for the first 8,000 holders.

Use XEN-token.com for interacting with this contract.
Find the ::REXpaper:: for more information.

*/
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
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
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

library SafeMath32 {

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a);
        uint32 c = a - b;
        return c;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {

        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0);
        uint32 c = a / b;
        return c;
    }

    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b != 0);
        return a % b;
    }
}

contract BEP20Token is Context {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply = 0;
  uint8 private _decimals = 18;
  string private _symbol;
  string private _name;

  event Transfer(
      address indexed from,
      address indexed to,
      uint256 value
  );

  event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
  );

  constructor (string memory tokenName, string memory tokenSymbol) {
    _name = tokenName;
    _symbol = tokenSymbol;
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
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
  function balanceOf(address account) external view returns (uint256) {
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
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
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
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
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
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
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

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}

contract Events {

    event StakeStarted(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint32 startDay,
        uint32 stakingDays
    );

    event StakeEnded(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint256 rewardAmount,
        uint32 closeDay,
        uint256 penaltyAmount
    );

    event InterestScraped(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 scrapeAmount,
        uint32 scrapeDay,
        uint256 stakersPenalty,
        uint32 currentRexDay
    );

    event TokensClaimed(
        address indexed claimer,
        uint256 claimAmount,
        uint32 day
    );

    event NewGlobals(
        uint256 totalShares,
        uint256 totalStaked,
        uint256 totalClaimed,
        uint256 shareRate,
        uint32 indexed currentRexDay
    );

    event NewSharePrice(
        uint256 newSharePrice,
        uint256 oldSharePrice,
        uint32 currentRexDay
    );

}

abstract contract Global is BEP20Token, Events {

    using SafeMath for uint256;

    struct Globals {
        uint256 totalStaked;
        uint256 totalShares;
        uint256 totalClaimed;
        uint256 sharePrice;
        uint32 currentRexDay;
    }

    Globals public globals;

    constructor() {
        globals.sharePrice = 1E17;   // = 0.1 BNB
    }

    function _increaseClaimedAmount(uint256 _claimedTokens) internal {
        globals.totalClaimed = globals.totalClaimed.add(_claimedTokens);
    }

    function _increaseGlobals(
        uint256 _staked,
        uint256 _shares
    )
        internal
    {
        globals.totalStaked = globals.totalStaked.add(_staked);
        globals.totalShares = globals.totalShares.add(_shares);
        _logGlobals();
    }

    function _decreaseGlobals(
        uint256 _staked,
        uint256 _shares
    )
        internal
    {
        globals.totalStaked =
        globals.totalStaked > _staked ?
        globals.totalStaked - _staked : 0;

        globals.totalShares =
        globals.totalShares > _shares ?
        globals.totalShares - _shares : 0;

        _logGlobals();
    }

    function _logGlobals()
        private
    {
        emit NewGlobals(
            globals.totalShares,
            globals.totalStaked,
            globals.totalClaimed,
            globals.sharePrice,
            globals.currentRexDay
        );
    }
}

abstract contract Declaration is Global {

    uint256 public LAUNCH_TIME;
    uint256 constant SECONDS_IN_DAY = 86400 seconds;
    uint256 constant CLUB_STAKE_TRESHOLD = 1E5;
    uint256 constant BONUS_PRECISION = 1E8;
    uint256 constant SHARES_PRECISION = 1E10;
    uint256 constant TENTH_OF_BNB = 1E17;
    uint256 constant REWARD_PRECISION = 1E20;
    uint256 constant SXEN_PER_REX = 1E18;
    uint256 constant PRECISION_RATE = 1E18;
    uint256 constant INITIAL_SHARE_PRICE = TENTH_OF_BNB;
    uint32 constant INFLATION_RATE = 116800000; // 3.000%
    uint32 constant INFLATION_DIVISOR = 10000; // 3.000%

      // XEN POOL distributed daily to stakers (XEN-BigPayDay)
      // gets filled daily by unclaimed XEN and added to penalties on dailyShapshot
    uint256 public unclaimedRexPOOL; // unclaimed XEN from FREE CLAIMS get summed up, max. 1M/day are given to stakers
    uint256 DAILY_TRANSFER_CAP = 100000 * SXEN_PER_REX; // if noone claims, unclaimed will be distributed later

    uint32 constant MIN_STAKING_DAYS = 1;
    uint32 constant MAX_STAKING_DAYS = 5555;
    uint32 constant MIN_STAKE_AMOUNT = 1000000; // equals 0.000000000001 XEN

    uint32 constant CLAIM_PHASE_START_DAY = 1;  // not before the 1st day, checked by _currentRexDay
    uint32 constant CLAIM_PHASE_END_DAY = 365;
    uint32 constant CLAIMABLE_ETH_ADDRESSES = uint32(8000);
    uint256 constant SXEN_PER_CLAIM_DAY = 10 * SXEN_PER_REX;  //10 XEN
    uint32 public claimCount;

    address public RDA_CONTRACT;            // defined later via init after deployment
    BEP20Token public TREX_CONTRACT;            // defined later via init after deployment
    BEP20Token public MREX_CONTRACT;            // defined later via init after deployment

    constructor() {
        LAUNCH_TIME = 1624096800;        //  Sat Jun 19 2021 10:00:00 GMT+0000
    }

    struct Stake {
        uint256 stakesShares;
        uint256 stakedAmount;
        uint256 rewardAmount;
        uint256 penaltyAmount;
        uint32 startDay;
        uint32 stakingDays;
        uint32 finalDay;
        uint32 closeDay;
        uint32 scrapeDay;
        bool isActive;
        bool isSplit;
        string description;
    }

    mapping(address => bool) public addressHasClaimed;
    mapping(address => uint256) public stakeCount;
    mapping(address => uint256) public totalREXinActiveStakes;
    mapping(address => bool) public ultraRexican;
    mapping(address => bool) public clubFive;
    mapping(address => mapping(bytes16 => Stake)) public stakes;
    mapping(address => mapping(bytes16 => uint256)) public scrapes;

    mapping(uint32 => uint256) public scheduledToEnd;
    mapping(uint32 => uint256) public totalPenalties;
}

abstract contract Timing is Declaration {

    function currentRexDay() public view returns (uint32) {
        return _getNow() >= LAUNCH_TIME ? _currentRexDay() : 0;
    }

    function _currentRexDay() internal view returns (uint32) {
        return _rexDayFromStamp(_getNow());
    }

    function _nextRexDay() internal view returns (uint32) {
        return _currentRexDay() + 1;
    }

    function _previousRexDay() internal view returns (uint32) {
        return _currentRexDay() - 1;
    }

    function _rexDayFromStamp(uint256 _timestamp) internal view returns (uint32) {
        return uint32((_timestamp - LAUNCH_TIME) / SECONDS_IN_DAY);
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }
}

abstract contract Helper is Timing {

    using SafeMath for uint256;
    using SafeMath32 for uint32;

    function _notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

    function _toBytes16(uint256 x) internal pure returns (bytes16 b) {
       return bytes16(bytes32(x));
    }

    function generateID(address x, uint256 y, bytes1 z) public pure returns (bytes16 b) {
        b = _toBytes16(
            uint256(
                keccak256(
                    abi.encodePacked(x, y, z)
                )
            )
        );
    }

    function _generateStakeID(address _staker) internal view returns (bytes16 stakeID) {
        return generateID(_staker, stakeCount[_staker], 0x01);
    }

    function stakesPagination(
        address _staker,
        uint256 _offset,
        uint256 _length
    )
        external
        view
        returns (bytes16[] memory _stakes)
    {
        uint256 start = _offset > 0 &&
            stakeCount[_staker] > _offset ?
            stakeCount[_staker] - _offset : stakeCount[_staker];

        uint256 finish = _length > 0 &&
            start > _length ?
            start - _length : 0;

        uint256 i;

        _stakes = new bytes16[](start - finish);

        for (uint256 _stakeIndex = start; _stakeIndex > finish; _stakeIndex--) {
            bytes16 _stakeID = generateID(_staker, _stakeIndex - 1, 0x01);
            if (stakes[_staker][_stakeID].stakedAmount > 0) {
                _stakes[i] = _stakeID; i++;
            }
        }
    }

    function unclaimedAddresses() public view returns (uint32) {
        return CLAIMABLE_ETH_ADDRESSES - claimCount;
    }

    function isUltraRexican(address addr) public view returns (bool) {
        return ultraRexican[addr];
    }

    function latestStakeID(address _staker) external view returns (bytes16) {
        return stakeCount[_staker] == 0 ? bytes16(0) : generateID(_staker, stakeCount[_staker].sub(1), 0x01);
    }

    function _increaseStakeCount(address _staker) internal {
        stakeCount[_staker] = stakeCount[_staker] + 1;
    }

    function _isMatureStake(Stake memory _stake) internal view returns (bool) {
        return _stake.closeDay > 0
            ? _stake.finalDay <= _stake.closeDay
            : _stake.finalDay <= _currentRexDay();
    }

    function _stakeNotStarted(Stake memory _stake) internal view returns (bool) {
        return _stake.closeDay > 0
            ? _stake.startDay > _stake.closeDay
            : _stake.startDay > _currentRexDay();
    }

    function _stakeEnded(Stake memory _stake) internal view returns (bool) {
        return _stake.isActive == false || _isMatureStake(_stake);
    }

    function _daysDiff(uint32 _startDate, uint32 _endDate) internal pure returns (uint32) {
        return _startDate > _endDate ? 0 : _endDate.sub(_startDate);
    }

    function _daysLeft(Stake memory _stake) internal view returns (uint32) {
        return _stake.isActive == false
            ? _daysDiff(_stake.closeDay, _stake.finalDay)
            : _daysDiff(_currentRexDay(), _stake.finalDay);
    }

    function _calculationDay(Stake memory _stake) internal view returns (uint32) {
        return _stake.finalDay > globals.currentRexDay ? globals.currentRexDay : _stake.finalDay;
    }

    function _startingDay(Stake memory _stake) internal pure returns (uint32) {
        return _stake.scrapeDay == 0 ? _stake.startDay : _stake.scrapeDay;
    }

    function _notPast(uint32 _day) internal view returns (bool) {
        return _day >= _currentRexDay();
    }

    function _notFuture(uint32 _day) internal view returns (bool) {
        return _day <= _currentRexDay();
    }

    function _nonZeroAddress(address _address) internal pure returns (bool) {
        return _address != address(0x0);
    }

    function _getStakingDays(Stake memory _stake) internal pure returns (uint32) {
        return
            _stake.stakingDays > 1 ?
            _stake.stakingDays - 1 : 1;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    )
        internal
    {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                0xa9059cbb,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool)))
            // 'XEN: transfer failed'
        );
    }
}

abstract contract Snapshot is Helper {

    using SafeMath for uint256;
    using SafeMath32 for uint32;

    // normal shares
    struct SnapShot {
        uint256 totalShares;
        uint256 inflationAmount;
        uint256 scheduledToEnd;
    }

    mapping(uint32 => SnapShot) public snapshots;

    modifier snapshotTrigger() {
        _dailySnapshotPoint(_currentRexDay());
        _;
    }

    /**
     * @notice allows volunteer to offload snapshots
     * to save on gas during next start/end stake
     */
    function manualDailySnapshot()
        external
    {
        _dailySnapshotPoint(_currentRexDay());
    }

    /**
     * @notice allows to offload snapshots
     */
    function manualDailySnapshotPoint(
        uint32 _updateDay
    )
        external
    {
        require(
            _updateDay > 0 &&
            _updateDay < _currentRexDay(),
            'XEN: Day does not exist yet.'
        );

        require(
            _updateDay > globals.currentRexDay,
            'XEN: snapshot already taken for that day'
        );

        _dailySnapshotPoint(_updateDay);
    }

    /**
     * @notice internal function that offloads global values to daily snapshots
     * updates globals.currentRexDay
     */
    function _dailySnapshotPoint(
        uint32 _updateDay
    )
        private
    {
        uint256 totalStakedToday = globals.totalStaked;
        uint256 scheduledToEndToday;

        for (uint32 _day = globals.currentRexDay; _day < _updateDay; _day++) {

            scheduledToEndToday = scheduledToEnd[_day] + snapshots[_day - 1].scheduledToEnd;
            SnapShot memory snapshot = snapshots[_day];
            snapshot.scheduledToEnd = scheduledToEndToday;

            snapshot.totalShares =
                globals.totalShares > scheduledToEndToday ?
                globals.totalShares - scheduledToEndToday : 0;

            _transferUnclaimedRexToStakers(_day);   // add unclaimed XEN to "totalPenalties" (increases interest for stakers)

            snapshot.inflationAmount =  snapshot.totalShares
                .mul(PRECISION_RATE)
                .div(
                    _inflationAmount(
                        totalStakedToday,
                        totalSupply(),
                        totalPenalties[_day]
                    )
                );

            snapshots[_day] = snapshot;

            globals.currentRexDay++;

        }
    }

    /**
     * @notice internal function that transfers daily unclaimed XEN to penalties (therefore to stakers)
     */
    function _transferUnclaimedRexToStakers(uint32 _day) private {
        if (_day <= CLAIM_PHASE_END_DAY)  // collect unclaimed XEN in claim phase and add to pool
        {
            uint256 _unclaimedAddresses = uint256(CLAIMABLE_ETH_ADDRESSES - claimCount); // get number of unclaimed XEN addresses
            unclaimedRexPOOL = unclaimedRexPOOL.add(_unclaimedAddresses.mul(SXEN_PER_CLAIM_DAY)); // add XEN to POOL
        }
        if (unclaimedRexPOOL > 0) // transfer capped amount to penalties, subtract from POOL
        {
            uint256 unclaimedGoToStakers = unclaimedRexPOOL > DAILY_TRANSFER_CAP
                ? DAILY_TRANSFER_CAP
                : unclaimedRexPOOL;
            totalPenalties[_day] = totalPenalties[_day].add(unclaimedGoToStakers);
            unclaimedRexPOOL = unclaimedRexPOOL.sub(unclaimedGoToStakers);
        }
    }

    function _inflationAmount(uint256 _totalStaked, uint256 _totalSupply, uint256 _totalPenalties) private pure returns (uint256) {
        return (_totalStaked + _totalSupply) * INFLATION_DIVISOR / INFLATION_RATE + _totalPenalties;
    }
}

abstract contract StakingToken is Snapshot {

    using SafeMath for uint256;
    using SafeMath32 for uint32;

    /**
     * @notice A function for a staker to create a stake
     * @param _stakedAmount amount of XEN staked
     * @param _stakingDays amount of days it is locked
     */
    function createStake(
        uint256 _stakedAmount,
        uint32 _stakingDays,
        string calldata _description
    )
        snapshotTrigger
        public
        returns (bytes16, uint32)
    {
        require(_stakingDays >= MIN_STAKING_DAYS && _stakingDays <= MAX_STAKING_DAYS, 'XEN: Stake duration not in range.');
        require(_stakedAmount >= MIN_STAKE_AMOUNT, 'XEN: Stake too small.');

        (
            Stake memory newStake,
            bytes16 stakeID,
            uint32 _startDay
        ) =

        _createStake(msg.sender, _stakedAmount, _stakingDays, _description);

        stakes[msg.sender][stakeID] = newStake;
        _increaseStakeCount(msg.sender);
        _increaseGlobals(newStake.stakedAmount, newStake.stakesShares);
        _addScheduledShares(newStake.finalDay, newStake.stakesShares);
        if (_stakingDays == 5555 && newStake.stakedAmount >= CLUB_STAKE_TRESHOLD) { clubFive[msg.sender] = true; }

        emit StakeStarted(
            stakeID,
            msg.sender,
            newStake.stakedAmount,
            newStake.stakesShares,
            newStake.startDay,
            newStake.stakingDays
        );

        return (stakeID, _startDay);
    }

    /**
    * @notice Internal function to create a stake
    */
    function _createStake(
        address _staker,
        uint256 _stakedAmount,
        uint32 _stakingDays,
        string memory _description
    )
        private
        returns (
            Stake memory _newStake,
            bytes16 _stakeID,
            uint32 _startDay
        )
    {
        _burn(_staker, _stakedAmount);
        totalREXinActiveStakes[_staker] = totalREXinActiveStakes[_staker].add(_stakedAmount);

        _startDay = _nextRexDay();
        _stakeID = _generateStakeID(_staker);
        _newStake.stakingDays = _stakingDays;
        _newStake.startDay = _startDay;
        _newStake.finalDay = _startDay + _stakingDays;
        _newStake.description = _description;
        _newStake.isActive = true;
        _newStake.stakedAmount = _stakedAmount;

        _newStake.stakesShares = (TREX_CONTRACT.balanceOf(msg.sender) > 0)
            ? _stakesShares(_stakedAmount, _stakingDays, INITIAL_SHARE_PRICE)
            : _stakesShares(_stakedAmount, _stakingDays, globals.sharePrice);
    }

    /**
    * @notice Internal function to create an "auto-stake" for addresses that have free claimed XEN
    * Auto-stakes don't count for the randomEBNB calculation, so "totalREXinActiveStakes" are not added
    */
    function _createAutoStake(
        address _staker,
        uint256 _stakedAmount,
        uint32 _stakingDays
    )
        internal
    {
        uint32 _startDay = _nextRexDay();
        bytes16 _stakeID = _generateStakeID(_staker);

        Stake memory _newStake;
        _newStake.stakingDays = _stakingDays;
        _newStake.startDay = _startDay;
        _newStake.finalDay = _startDay + _stakingDays;
        _newStake.description = unicode'🤴 free-claim auto-stake';
        _newStake.isActive = true;
        _newStake.stakedAmount = _stakedAmount;

        _newStake.stakesShares = (TREX_CONTRACT.balanceOf(msg.sender) > 0)
            ? _stakesShares(_stakedAmount, _stakingDays, INITIAL_SHARE_PRICE)
            : _stakesShares(_stakedAmount, _stakingDays, globals.sharePrice);

        stakes[_staker][_stakeID] = _newStake;
        _increaseStakeCount(_staker);
        _increaseGlobals(_newStake.stakedAmount, _newStake.stakesShares);
        _addScheduledShares(_newStake.finalDay, _newStake.stakesShares);

        emit StakeStarted(
            _stakeID,
            _staker,
            _newStake.stakedAmount,
            _newStake.stakesShares,
            _newStake.startDay,
            _newStake.stakingDays
        );

    }

    /**
    * @notice A function for a staker to end a stake
    * belonging to their address by providing the stake ID.
    * @param _stakeID unique bytes sequence reference to the stake
    */
    function endStake(
        bytes16 _stakeID
    )
        snapshotTrigger
        external
        returns (uint256)
    {
        (Stake memory endedStake, uint256 penaltyAmount) = _endStake(msg.sender, _stakeID);
        _decreaseGlobals(endedStake.stakedAmount, endedStake.stakesShares);
        _removeScheduledShares(endedStake.finalDay, endedStake.stakesShares);
        if (penaltyAmount > 0) {
            totalPenalties[endedStake.closeDay] = totalPenalties[endedStake.closeDay].add(penaltyAmount);
        }
        _sharePriceUpdate(
            endedStake.stakedAmount > penaltyAmount ?
            endedStake.stakedAmount - penaltyAmount : 0,
            endedStake.rewardAmount + scrapes[msg.sender][_stakeID],
            endedStake.stakingDays,
            endedStake.stakesShares
        );

        emit StakeEnded(
            _stakeID,
            msg.sender,
            endedStake.stakedAmount,
            endedStake.stakesShares,
            endedStake.rewardAmount,
            endedStake.closeDay,
            penaltyAmount
        );

        return endedStake.rewardAmount;
    }

    function _endStake(
        address _staker,
        bytes16 _stakeID
    )
        private
        returns (
            Stake storage _stake,
            uint256 _penalty
        )
    {
        require(stakes[_staker][_stakeID].isActive, 'XEN: not an active stake');        // only active stakes can be ended
        string memory _desc = unicode'🤴 free-claim auto-stake';                        // declare string for auto-stake
        bool _autostake = compareStrings(stakes[_staker][_stakeID].description, _desc); // check if stake is auto-stake
        if (_autostake)                                                                 // auto-stake can not be ended before maturity
        {
            require(stakes[_staker][_stakeID].finalDay <= _currentRexDay(), 'XEN: Auto-stake not mature.');
        }

        _stake = stakes[_staker][_stakeID];                       // get stake
        _stake.closeDay = _currentRexDay();                       // set closeDay
        _stake.rewardAmount = _calculateRewardAmount(_stake);     // loop calculates rewards/day (=INTEREST), reduced if early or late claim
        _penalty = _calculatePenaltyAmount(_stake);               // penalty reduces the payout from principal (stakedAmount), if ended before half of maturity
        _stake.penaltyAmount = _penalty;
        _stake.isActive = false;

          // big long stakes make the staker be in Club5555, ending a big immature stake revokes the status
        if (_stake.stakingDays == 5555 && _stake.stakedAmount >= CLUB_STAKE_TRESHOLD && _isMatureStake(_stake) == false) { clubFive[_staker] = false; }

          // keep track of the user's XEN in active stakes, for calculating BigPayDays in RexDailyAuction contract
        totalREXinActiveStakes[_staker] =
            totalREXinActiveStakes[_staker] >= (_stake.stakedAmount) ?
            totalREXinActiveStakes[_staker].sub(_stake.stakedAmount) : 0;

          // mint back the principal minus penalties
        _mint(
            _staker,
            _stake.stakedAmount > _penalty ?
            _stake.stakedAmount - _penalty : 0
        );

          // mint the rewards
        _mint(
            _staker,
            _stake.rewardAmount
        );
    }

    /**
    * @notice A function for a staker to move an active stake
    * belonging to his address by providing the stake ID, to another address.
    * Not possible if interest has been scraped before.
    * @param _stakeID unique bytes sequence reference to the stake
    * @param _toAddress Receiver of the stake
    */
    function moveStake(
        bytes16 _stakeID,
        address _toAddress
    )
        snapshotTrigger
        external
    {
        require(MREX_CONTRACT.balanceOf(msg.sender) > 0, 'XEN: Hodl MREX to be allowed!');
        require(stakes[msg.sender][_stakeID].isActive, 'XEN: Not an active stake.');
        require(stakes[msg.sender][_stakeID].scrapeDay == 0, 'XEN: No. Already scraped interest.');
        require(_notContract(_toAddress), 'XEN: Receiver not an address');
        require(_toAddress != msg.sender, 'XEN: Sender equals receiver');

        Stake memory _temp = stakes[msg.sender][_stakeID];
        Stake memory _newStake;

        _newStake.stakesShares = _temp.stakesShares;
        _newStake.stakedAmount = _temp.stakedAmount;
        _newStake.startDay = _temp.startDay;
        _newStake.stakingDays = _temp.stakingDays;
        _newStake.finalDay = _temp.finalDay;
        _newStake.closeDay = _temp.closeDay;
        _newStake.scrapeDay = _temp.scrapeDay;
        _newStake.isActive = _temp.isActive;
        _newStake.isSplit = _temp.isSplit;
        _newStake.description = _temp.description;

        Stake storage _stake = stakes[msg.sender][_stakeID];
        _stake.closeDay = _currentRexDay();
        _stake.description = unicode'MOVED AWAY';
        _stake.isActive = false;

          // transfer staked amount to the new staker (sub and add)
        totalREXinActiveStakes[msg.sender] = totalREXinActiveStakes[msg.sender] > _temp.stakedAmount ?
            totalREXinActiveStakes[msg.sender].sub(_temp.stakedAmount) : 0;
        totalREXinActiveStakes[_toAddress] = totalREXinActiveStakes[_toAddress].add(_temp.stakedAmount);

          // big long stakes make the staker be in Club5555, moving a big immature stake revokes the status
        if (_newStake.stakingDays == 5555 && _newStake.stakedAmount >= CLUB_STAKE_TRESHOLD) { clubFive[msg.sender] = false; }

          // save the new stake for the new staker (toAddress)
        bytes16 _newReceiverStakeID = _generateStakeID(_toAddress);
        stakes[_toAddress][_newReceiverStakeID] = _newStake;
        _increaseStakeCount(_toAddress);
    }

    /**
    * @notice A function for a staker to rename a stake
    * belonging to his address by providing the stake ID
    * @param _stakeID unique bytes sequence reference to the stake
    * @param _description New description
    */
    function renameStake(
        bytes16 _stakeID,
        string calldata _description
    )
        snapshotTrigger
        external
    {
        require(stakes[msg.sender][_stakeID].isActive, 'XEN: Not an active stake');
        require(MREX_CONTRACT.balanceOf(msg.sender) > 0, 'XEN: Hodl MREX to be allowed!');
        Stake storage _stake = stakes[msg.sender][_stakeID];                              // get the stake
        string memory _desc = unicode'🤴 free-claim auto-stake';                          // define autostake string
        bool _autostake = compareStrings(_stake.description, _desc); // compare strings   // compare to description, create bool
        require(!_autostake, 'XEN: Cannot rename auto-stake.');                           // require not autostake
        _stake.description = _description;                                                // change description
    }

    function splitStake(
        bytes16 _stakeID
    )
        snapshotTrigger
        external
    {
        require(MREX_CONTRACT.balanceOf(msg.sender) > 0, 'XEN: Hodl MREX to be allowed!');
        require(stakes[msg.sender][_stakeID].isActive, 'XEN: Not an active stake.');
        require(stakes[msg.sender][_stakeID].isSplit == false, 'XEN: Already split.');
        require(stakes[msg.sender][_stakeID].scrapeDay == 0, 'XEN: No. Already scraped interest.');
        require(stakes[msg.sender][_stakeID].stakedAmount >= 2*MIN_STAKE_AMOUNT, 'XEN: Too small to split.');

        Stake memory _temp = stakes[msg.sender][_stakeID];
        Stake memory _newStake;

        _newStake.stakesShares = _temp.stakesShares / 2;
        _newStake.stakedAmount = _temp.stakedAmount / 2;
        _newStake.startDay = _temp.startDay;
        _newStake.stakingDays = _temp.stakingDays;
        _newStake.finalDay = _temp.finalDay;
        _newStake.closeDay = _temp.closeDay;
        _newStake.isActive = true;
        _newStake.isSplit = true;
        _newStake.description = _temp.description;

        Stake storage _stake = stakes[msg.sender][_stakeID];
        _stake.isSplit = true;
        _stake.stakesShares = _stake.stakesShares - _newStake.stakesShares;
        _stake.stakedAmount = _stake.stakedAmount - _newStake.stakedAmount;

          // save the new stake
        bytes16 _newStakeID = _generateStakeID(msg.sender);
        stakes[msg.sender][_newStakeID] = _newStake;
        _increaseStakeCount(msg.sender);
    }

    /**
    * @notice allows to scrape interest from active stake
    * @param _stakeID unique bytes sequence reference to the stake
    * @param _scrapeDays amount of days to process, all = 0
    */
    function scrapeInterest(
        bytes16 _stakeID,
        uint32 _scrapeDays
    )
        external
        snapshotTrigger
        returns (
            uint32 scrapeDay,
            uint256 scrapeAmount,
            uint32 remainingDays,
            uint256 stakersPenalty
        )
    {
        require(stakes[msg.sender][_stakeID].isActive, 'XEN: Not an active stake');
        require(stakes[msg.sender][_stakeID].finalDay > _currentRexDay(), 'XEN: Stake mature. Close it!');
        require(stakes[msg.sender][_stakeID].stakingDays > 2, 'XEN: Stake too short to scrape interest.');
        require(MREX_CONTRACT.balanceOf(msg.sender) > 0, 'XEN: Hodl MREX to be allowed.');

        Stake memory stake = stakes[msg.sender][_stakeID];      // get stake

        scrapeDay = _scrapeDays > 0                             // startingDay returns stake.startDay OR stake.scrapeDay (if scraped already)
            ? _startingDay(stake).add(_scrapeDays)              // if not all days are wished to scrape, add desired days to startingDay, see comment above
            : _calculationDay(stake);                           // calculationDay returns endDay OR currentDay, if currentDay is later than endDay

        scrapeDay = scrapeDay > _currentRexDay()                // if scrape day exceeds currrentDay, limit to currentDay
            ? _calculationDay(stake)
            : scrapeDay;

        scrapeAmount = _loopRewardAmount(                       // startingDay returns stake.startDay OR stake.scrapeDay (if scraped before)
            stake.stakesShares,
            _startingDay(stake),
            scrapeDay
        );

        remainingDays = _daysLeft(stake);

          // the penalty is the amount, that a new stake till the end would cost, cheaper if holds TXEN
        stakersPenalty = _stakesShares(
            scrapeAmount,
            remainingDays,
            TREX_CONTRACT.balanceOf(msg.sender) > 0 ? INITIAL_SHARE_PRICE : globals.sharePrice
        );

        uint256 _sharesTemp = stake.stakesShares;

          // deduct penalty from SHARES
        stake.stakesShares =
        stake.stakesShares > stakersPenalty ?
        stake.stakesShares.sub(stakersPenalty) : 0;

            // keep track of the scheduled shares: deduct from final day
        _removeScheduledShares(
            stake.finalDay,
            _sharesTemp > stakersPenalty ? stakersPenalty : _sharesTemp
        );

          // log globals
        _decreaseGlobals(0, _sharesTemp > stakersPenalty ? stakersPenalty : _sharesTemp);

        _sharePriceUpdate(
            stake.stakedAmount,
            scrapeAmount,
            stake.stakingDays,
            stake.stakesShares
        );

          // keep track of scrapes for sharePriceUpdate when calling _endStake
        scrapes[msg.sender][_stakeID] = scrapes[msg.sender][_stakeID].add(scrapeAmount);

        stake.scrapeDay = scrapeDay;
        stakes[msg.sender][_stakeID] = stake;

        _mint(msg.sender, scrapeAmount);

        emit InterestScraped(
            _stakeID,
            msg.sender,
            scrapeAmount,
            scrapeDay,
            stakersPenalty,
            _currentRexDay()
        );
    }

    function _addScheduledShares(
        uint32 _finalDay,
        uint256 _shares
    )
        internal
    {
        scheduledToEnd[_finalDay] =
        scheduledToEnd[_finalDay].add(_shares);
    }

    function _removeScheduledShares(
        uint32 _finalDay,
        uint256 _shares
    )
        internal
    {
        if (_notPast(_finalDay)) {

            scheduledToEnd[_finalDay] =
            scheduledToEnd[_finalDay] > _shares ?
            scheduledToEnd[_finalDay] - _shares : 0;

        } else {

            uint32 _day = _previousRexDay();
            snapshots[_day].scheduledToEnd =
            snapshots[_day].scheduledToEnd > _shares ?
            snapshots[_day].scheduledToEnd - _shares : 0;
        }
    }

    function _sharePriceUpdate(
        uint256 _stakedAmount,
        uint256 _rewardAmount,
        uint32 _stakingDays,
        uint256 _stakeShares
    )
        private
    {
        if (_stakeShares > 0 && _currentRexDay() > 1) {

            uint256 newSharePrice = _getNewSharePrice(
                _stakedAmount,
                _rewardAmount,
                _stakeShares,
                _stakingDays
            );

            if (newSharePrice > globals.sharePrice) {

                newSharePrice =
                    newSharePrice < globals.sharePrice.mul(110).div(100) ?
                    newSharePrice : globals.sharePrice.mul(110).div(100);

                emit NewSharePrice(
                    newSharePrice,
                    globals.sharePrice,
                    _currentRexDay()
                );

                globals.sharePrice = newSharePrice;
            }

            return;
        }
    }

    function _getNewSharePrice(
        uint256 _stakedAmount,
        uint256 _rewardAmount,
        uint256 _stakeShares,
        uint32 _stakingDays
    )
        private
        pure
        returns (uint256)
    {

        uint256 _bonusAmount = _getBonus(_stakingDays);
        return
            _stakedAmount
                .add(_rewardAmount)
                .mul(_bonusAmount)
                .mul(BONUS_PRECISION)
                .div(_stakeShares);
    }

    function _stakesShares(
        uint256 _stakedAmount,
        uint32 _stakingDays,
        uint256 _sharePrice
    )
        private
        pure
        returns (uint256)
    {
        return _sharesAmount(_stakedAmount, _stakingDays, _sharePrice);
    }

    function _sharesAmount(
        uint256 _stakedAmount,
        uint32 _stakingDays,
        uint256 _sharePrice
    )
        private
        pure
        returns (uint256)
    {
        return _baseAmount(_stakedAmount, _sharePrice)
            .mul(SHARES_PRECISION + _getBonus(_stakingDays))
            .div(SHARES_PRECISION);
    }

    function _getBonus(
        uint32 _stakingDays
    )
        private
        pure
        returns (uint256)
    {
        return _calcBonusDays(_stakingDays).mul(SHARES_PRECISION).div(7300);
    }

    function _calcBonusDays(
        uint32 _stakingDays
    )
        private
        pure
        returns (uint256)
    {
        return
            _stakingDays.div(365) == 0
            ? _stakingDays
            : getHigherDays(_stakingDays);
    }

    function getHigherDays(
        uint32 _stakingDays
    )
        private
        pure
        returns (uint256 _days)
    {
        for (uint32 i = 0; i < _stakingDays.div(365); i++) {
            _days += _stakingDays-(i*365);
        }
        _days += _stakingDays - (_stakingDays.div(365) * 365);
        return uint256(_days);
    }

    function _baseAmount(
        uint256 _stakedAmount,
        uint256 _sharePrice
    )
        private
        pure
        returns (uint256)
    {
        return
            _stakedAmount
                .mul(PRECISION_RATE)
                .div(_sharePrice);
    }


    function _checkRewardAmountbyID(address _staker, bytes16 _stakeID) public view returns (uint256 rewardAmount) {
        Stake memory stake = stakes[_staker][_stakeID];
        return stake.isActive ? _detectReward(stake) : stake.rewardAmount;
    }

    function _checkPenaltyAmountbyID(address _staker, bytes16 _stakeID) public view returns (uint256 penaltyAmount) {
        Stake memory stake = stakes[_staker][_stakeID];
        return stake.isActive ? _calculatePenaltyAmount(stake) : stake.penaltyAmount;
    }

    function _detectReward(Stake memory _stake) private view returns (uint256) {
        return _stakeNotStarted(_stake) ? 0 : _calculateRewardAmount(_stake);
    }

    function _calculatePenaltyAmount(
        Stake memory _stake
    )
        private
        view
        returns (uint256)
    {
        return _stakeNotStarted(_stake) || _isMatureStake(_stake) ? 0 : _getPenalty(_stake);
    }

    /**
    * @notice If stake is served 50%: no penalty, otherwise linear from 100% (day 1) to 0% (day x/2 of x)
    */
    function _getPenalty(Stake memory _stake)
        private
        view
        returns (uint256)
    {
        return ((_stake.stakingDays - _daysLeft(_stake)) >= (_stake.stakingDays / 2))
          ? 0
          : ( _stake.stakedAmount - ( ( _stake.stakedAmount * (_stake.stakingDays - _daysLeft(_stake)) ) / (_stake.stakingDays / 2) ) );
    }

    function _calculateRewardAmount(
        Stake memory _stake
    )
        private
        view
        returns (uint256)
    {
        return _loopRewardAmount(
            _stake.stakesShares,
            _startingDay(_stake),
            _calculationDay(_stake)
        );
    }

    function _loopRewardAmount(
        uint256 _stakeShares,
        uint32 _startDay,
        uint32 _finalDay
    )
        private
        view
        returns (uint256 _rewardAmount)
    {
          // calculate rewards / day
        for (uint32 _day = _startDay; _day < _finalDay; _day++) {
            _rewardAmount += _stakeShares * PRECISION_RATE / snapshots[_day].inflationAmount;
        }

          // deduct penalty if late claim, more than 14 days after finalDay, 1%/week
        if (_currentRexDay() > (_finalDay + uint32(14)) && _rewardAmount > 0) {
            uint256 _reductionPercent = ((uint256(_currentRexDay()) - uint256(_finalDay) - uint256(14)) / uint256(7)) + uint256(1);
            if (_reductionPercent > 100) { _reductionPercent = 100; }
            _rewardAmount = _rewardAmount
                .mul(uint256(100).sub(_reductionPercent))
                .div(100);
        }

          // deduct penalty if early claim, 100-0% from statingDay till finalDay
        if (_currentRexDay() < _finalDay && _rewardAmount > 0) {
            if (_finalDay != _startDay) {
                _rewardAmount = _rewardAmount * REWARD_PRECISION * (uint256(_currentRexDay()) - uint256(_startDay) ) / ( uint256(_finalDay) - uint256(_startDay) ) / REWARD_PRECISION;
            }
        }
    }

    function compareStrings(
        string memory a,
        string memory b
    )
        private pure returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

abstract contract ClaimableToken is StakingToken {

    using SafeMath for uint256;
    using SafeMath32 for uint32;

    /**
     * @notice A function to claim XEN and auto-stake them
     * //  param _stakeDays MIN_AUTOSTAKE_DAYS at minimum, MAX_AUTOSTAKE_DAYS at maximum
     */
    function claimRexAndStake(
    )
        snapshotTrigger
        external
    {
        require(!addressHasClaimed[msg.sender], 'XEN: Address has claimed already.');
        require(msg.sender.balance > TENTH_OF_BNB, 'XEN: BNB Balance must be >0.1');
        require(_currentRexDay() != 0, 'XEN: Too early. Wait till day 1.');
        require(_currentRexDay() <= CLAIM_PHASE_END_DAY, 'XEN: Claiming has ended already.');
        require(claimCount <= CLAIMABLE_ETH_ADDRESSES, 'XEN: Too many claims.');             // sanity check

        addressHasClaimed[msg.sender] = true;                                                // re-entry protection
        claimCount++;

        uint32 _validClaimDays = CLAIM_PHASE_END_DAY.add(1).sub(_currentRexDay());           // => (1 <= # <= 365 days)
        uint256 _claimTokens = uint256(_validClaimDays).mul(SXEN_PER_CLAIM_DAY);          // => (10 XEN <= # <= 3,650 XEN)

          // first 50 addresses get 525 staking_days, then decreasing by 1 every 50 claims, down to 365 days
        uint32 _stakingDays = uint32( uint256(525).sub( claimCount.div(50) ) );

        _createAutoStake(msg.sender, _claimTokens, _stakingDays);
        _increaseClaimedAmount(_claimTokens);

        emit TokensClaimed(msg.sender, _claimTokens, _currentRexDay());
    }

    function claimableRex() external view returns (uint256) {
        if (addressHasClaimed[msg.sender]) { return 0; }
        if (_currentRexDay() == 0) { return 0; }
        if (_currentRexDay() > CLAIM_PHASE_END_DAY) { return 0; }
        if (claimCount > CLAIMABLE_ETH_ADDRESSES) { return 0; }
        return (uint256(CLAIM_PHASE_END_DAY).add(1).sub(uint256(_currentRexDay())).mul(SXEN_PER_CLAIM_DAY));
    }
}

contract RexToken is ClaimableToken {

    address public TOKEN_DEFINER;

    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'XEN: Wrong sender.'
        );
        _;
    }

    constructor() BEP20Token("XEN", "XEN") {
        TOKEN_DEFINER = msg.sender;
    }

    receive() external payable { revert(); }
    fallback() external payable { revert(); }

    /**
     * @notice Set up the contract's XEN interface
     * @dev revoke TOKEN_DEFINER access afterwards
     * @param _RDA Contract address of Daily Auctions
     * @param _TREX Contract address of TXEN token
     * @param _MREX Contract address of MREX token
     */
    function __initRexContracts(address _RDA, address _TREX, address _MREX) external onlyTokenDefiner {
        RDA_CONTRACT = _RDA;
        TREX_CONTRACT = BEP20Token(_TREX);
        MREX_CONTRACT = BEP20Token(_MREX);
    }

    function __revokeAccess() external onlyTokenDefiner
    {
        TOKEN_DEFINER = address(0x0);
    }

    /**
     * @notice Allows RexDailyAuction Contract to mint XEN tokens
     * @dev executed from RDA_CONTRACT when claiming XEN after donations and referrals
     * @param _donatorAddress to mint XEN for
     * @param _amount of tokens to mint for _donatorAddress
     */
    function mintSupply(
        address _donatorAddress,
        uint256 _amount
    )
        external
    {
        require(msg.sender == RDA_CONTRACT, 'XEN: No rights to mint.');
        _mint(_donatorAddress, _amount);
    }

    /**
     * @dev totalSupply() is the circulating supply, doesn't include STAKED XEN. allocatedSupply() includes both.
     * @return Allocated Supply in XEN
     */
    function allocatedSupply() external view returns (uint256)
    {
        return totalSupply() + globals.totalStaked;
    }

    /**
     * @notice Allows externals (RDA) and others to check staked amounts
     * @dev executed from RexDailyAuction, ONLY counts normal stakes, NOT from free claims
     * @param _staker Address to check
     * @return Number of staked XEN
     */
     function getTokensStaked(
         address _staker
     )
        external
        view
        returns (uint256)
     {
        return totalREXinActiveStakes[_staker];
     }

    /**
     * @notice Makes a referrer an ULTRA_REXICAN
     * @dev called from RexDailyAuction
     * @param _referrer Address that becomes an ULTRA_REXICAN
     */
    function setUltraRexican(
        address _referrer
    )
        external
    {
        require(msg.sender == RDA_CONTRACT, 'XEN: Can only be called by RDA contract.');
            ultraRexican[_referrer] = true;
    }

}