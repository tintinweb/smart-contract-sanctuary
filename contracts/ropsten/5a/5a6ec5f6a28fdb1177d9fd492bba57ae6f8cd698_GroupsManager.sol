pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/DateTime.sol

contract DateTime {
    // Date and Time utilities for ethereum contracts
    struct _DateTime {
        uint year;
        uint month;
        uint day;
        uint hour;
        uint minute;
        uint second;
        uint weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint year) public pure returns (bool) {
        if (year % 4 != 0) {
                return false;
        }
        if (year % 100 != 0) {
                return true;
        }
        if (year % 400 != 0) {
                return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint month, uint year) public pure returns (uint) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
                return 30;
        }
        else if (isLeapYear(year)) {
                return 29;
        }
        else {
                return 28;
        }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
                secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                if (secondsInMonth + secondsAccountedFor > timestamp) {
                        dt.month = i;
                        break;
                }
                secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                        dt.day = i;
                        break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint) {
        uint secondsAccountedFor = 0;
        uint year;
        uint numLeapYears;

        // Year
        year = uint(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
                if (isLeapYear(uint(year - 1))) {
                        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                }
                else {
                        secondsAccountedFor -= YEAR_IN_SECONDS;
                }
                year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) public pure returns (uint) {
        return uint((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint) {
        return uint((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint) {
        return uint(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint) {
        return uint((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint year, uint month, uint day) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint year, uint month, uint day, uint hour) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint year, uint month, uint day, uint hour, uint minute) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        uint i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
                if (isLeapYear(i)) {
                        timestamp += LEAP_YEAR_IN_SECONDS;
                }
                else {
                        timestamp += YEAR_IN_SECONDS;
                }
        }

        // Month
        uint[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
                monthDayCounts[1] = 29;
        }
        else {
                monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
                timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {

  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

// File: node_modules/openzeppelin-solidity/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: node_modules/openzeppelin-solidity/contracts/access/roles/MinterRole.sol

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

// File: contracts/NGT.sol

contract NGT is ERC20Mintable, ERC20Burnable, Ownable {
    using SafeMath for uint;

    string public name = "NemoGrid Token";
    string public symbol = "NGT";
    uint8 public decimals = 18;
}

// File: contracts/MarketsManager.sol

/// @title A manager to handle energy markets
contract MarketsManager is Ownable, DateTime {
    using SafeMath for uint;

    // Enum definitions

    // Type of the market
    enum MarketType {
                        Monthly,
                        Daily,
                        Hourly
                    }

    // State of the market
    enum MarketState {
                        None,
                        NotRunning,             // Market not running
                        WaitingConfirmToStart,  // Waiting for player confirm to start
                        Running,                // Market running
                        WaitingConfirmToEnd,    // Waiting for player confirm to end the market and assign the tokens
                        WaitingForTheReferee,   // Waiting for the referee decision
                        Closed,                 // Market closed
                        ClosedAfterJudgement,   // Market closed after referee judgement
                        ClosedNotPlayed         // Market closed because not played by the player
                     }

    // Result of the market
    enum MarketResult {
                        None,
                        NotDecided,         // The market is not ended
                        NotPlayed,          // The market is not played by the player
                        Prize,              // The player takes all the NGTs staked by the DSO
                        Revenue,            // The player takes a part of the NGTs staked by the DSO
                        Penalty,            // The DSO takes a part of the NGTs staked by the player
                        Crash,              // The DSO takes all the NGTs staked by the player
                        DSOCheating,        // The referee assigns the NGT staked by the player to the DSO
                        PlayerCheating,     // The referee assigns the NGT staked by the DSO to the player
                        Cheaters            // The referee decides that both DSO and the player will be refunded
                      }

    // Struct data

    // Market data
    struct MarketData {
        // Address of the player
        address player;

        // Address of a trusted referee, which decides the market if dso and player do not agree
        address referee;

        // Starting time of the market (timestamp)
        uint startTime;

        // Ending time of the market (timestamp)
        uint endTime;

        // Market type
        MarketType marketType;

        // Lower maximum power threshold (W)
        uint maxPowerLower;

        // Upper maximum power threshold (W)
        uint maxPowerUpper;

        // Revenue factor for the player (max_power_lower < max(P) < max_power_upper) (NGT/kW)
        uint revenueFactor;

        // Penalty factor for the player (max(P) > max_power_upper) (NGT/kW)
        uint penaltyFactor;

        // Amount staked by the DSO
        uint dsoStaking;

        // Amount staked by the player
        uint playerStaking;

        // Token released to the DSO after the market ending
        uint tknReleasedToDso;

        // Token released to the player after the market ending
        uint tknReleasedToPlayer;

        // Power peak declared by the DSO
        uint powerPeakDeclaredByDso;

        // Power peak declared by the player
        uint powerPeakDeclaredByPlayer;

        // Revenue token for the referee
        uint revPercReferee;

        // State of the market
        MarketState state;

        // Result of the market
        MarketResult result;
    }

    // Variables declaration

    /// Nemogrid token (NGT) used in the markets
    NGT public ngt;

    /// DSO related to the markets
    address public dso;

    /// Mapping related to markets data
    mapping (uint => MarketData) marketsData;

    /// Mapping related to markets existence
    mapping (uint => bool) marketsFlag;

    // Events

    /// Market opened by DSO
    /// @param player player address
    /// @param startTime timestamp of the market starting time
    /// @param idx market identifier
    event Opened(address player, uint startTime, uint idx);

    /// Market opening confirmed by the player
    /// @param player player address
    /// @param startTime timestamp of the market starting time
    /// @param idx market identifier
    event ConfirmedOpening(address player, uint startTime, uint idx);

    /// DSO has been refunded
    /// @param dso dso address
    /// @param idx market identifier
    event RefundedDSO(address dso, uint idx);

    /// Market settled by DSO
    /// @param player player address
    /// @param startTime timestamp of the market starting time
    /// @param idx market identifier
    /// @param powerPeak maximum power consumed by player during the market
    event Settled(address player, uint startTime, uint idx, uint powerPeak);

    /// Market settlement confirmed by player
    /// @param player player address
    /// @param startTime timestamp of the market starting time
    /// @param idx market identifier
    /// @param powerPeak maximum power consumed by player during the market
    event ConfirmedSettlement(address player, uint startTime, uint idx, uint powerPeak);

    /// Successful settlement, player and DSO agree on the declared power peaks
    event SuccessfulSettlement();

    /// Unsuccessful settlement, player and DSO do not agree on the declared power peaks
    /// @param powerPeakDSO maximum power declared by dso
    /// @param powerPeakPlayer maximum power declared by player
    event UnsuccessfulSettlement(uint powerPeakDSO, uint powerPeakPlayer);

    /// Market result is Prize
    /// @param tokensForDso NGTs amount for the DSO
    /// @param tokensForPlayer NGTs amount for the player
    event Prize(uint tokensForDso, uint tokensForPlayer);

    /// Market result is Revenue
    /// @param tokensForDso NGTs amount for the DSO
    /// @param tokensForPlayer NGTs amount for the player
    event Revenue(uint tokensForDso, uint tokensForPlayer);

    /// Market result is Penalty
    /// @param tokensForDso NGTs amount for the DSO
    /// @param tokensForPlayer NGTs amount for the player
    event Penalty(uint tokensForDso, uint tokensForPlayer);

    /// Market result is Crash
    /// @param tokensForDso NGTs amount for the DSO
    /// @param tokensForPlayer NGTs amount for the player
    event Crash(uint tokensForDso, uint tokensForPlayer);

    /// Market has been closed
    /// @param marketResult market final result
    event Closed(MarketResult marketResult);

    /// Intervention of the referee to decide the market
    /// @param player player address
    /// @param startTime timestamp of the market starting time
    /// @param idx market identifier
    event RefereeIntervention(address player, uint startTime, uint idx);

    /// Player cheated
    event PlayerCheated();

    /// DSO cheated
    event DSOCheated();

    /// Both DSO and player cheated
    event DSOAndPlayerCheated();

    /// Burnt NGTs tokens for the cheatings
    /// @param burntTokens burnt tokens
    event BurntTokens(uint burntTokens);

    /// Market closed after judge intervention
    /// @param marketResult market final result
    event ClosedAfterJudgement(MarketResult marketResult);

    // Functions

    /// Constructor
    /// @param _dso DSO wallet
    /// @param _token NGT token address
    constructor(address _dso, address _token) public {
        dso = _dso;
        ngt = NGT(_token);
    }

    /// Open a new market defined by the couple (player, startTime)
    /// @param _player player wallet
    /// @param _startTime initial timestamp of the market
    /// @param _type market type (0: monthly, 1: daily, 2: hourly)
    /// @param _referee referee wallet
    /// @param _maxLow lower limit of the maximum power consumed by player
    /// @param _maxUp upper limit of the maximum power consumed by player
    /// @param _revFactor revenue factor [NGT/kW]
    /// @param _penFactor penalty factor [NGT/kW]
    /// @param _stakedNGTs DSO staking of NGTs token
    /// @param _playerNGTs NGT amount that player will have to stake in order to successfully confirm the opening
    /// @param _revPercReferee referee revenue percentage
    function open(address _player,
                  uint _startTime,
                  MarketType _type,
                  address _referee,
                  uint _maxLow,
                  uint _maxUp,
                  uint _revFactor,
                  uint _penFactor,
                  uint _stakedNGTs,
                  uint _playerNGTs,
                  uint _revPercReferee) public {

        // create the idx hashing player, startTime and market type
        uint idx = calcIdx(_player, _startTime, _type);

        // only the dso is allowed to open a market
        require(msg.sender == dso);

        // check the market existence
        require(marketsFlag[idx] == false);

        // check the startTime timestamp
        require(now < _startTime);
        require(_checkStartTime(_startTime, _type));

        // check the referee address
        require(_referee != address(0));
        require(_referee != dso);
        require(_referee != _player);

        // check the maximum limits
        require(_maxLow < _maxUp);

        // check the revenue factor
        require(_checkRevenueFactor(_maxUp, _maxLow, _revFactor, _stakedNGTs) == true);

        // check the dso tokens allowance
        require(_stakedNGTs <= ngt.allowance(dso, address(this)));

        // The market can try to start: its data are saved in the mapping
        marketsData[idx].startTime = _startTime;
        marketsData[idx].endTime = _calcEndTime(_startTime, _type);
        marketsData[idx].marketType = _type;
        marketsData[idx].referee = _referee;
        marketsData[idx].player = _player;
        marketsData[idx].maxPowerLower = _maxLow;
        marketsData[idx].maxPowerUpper = _maxUp;
        marketsData[idx].revenueFactor = _revFactor;
        marketsData[idx].penaltyFactor = _penFactor;
        marketsData[idx].dsoStaking = _stakedNGTs;
        marketsData[idx].playerStaking = _playerNGTs;
        marketsData[idx].tknReleasedToDso = 0;
        marketsData[idx].tknReleasedToPlayer = 0;
        marketsData[idx].revPercReferee = _revPercReferee;
        marketsData[idx].state = MarketState.WaitingConfirmToStart;
        marketsData[idx].result = MarketResult.NotDecided;
        marketsFlag[idx] = true;

        // DSO staking: allowed tokens are transferred from dso wallet to this smart contract
        ngt.transferFrom(dso, address(this), marketsData[idx].dsoStaking);

        emit Opened(_player, _startTime, idx);
    }

    /// Confirm to play the market opening, performed by the player
    /// @param idx market identifier
    /// @param stakedNGTs DSO staking of NGTs token
    function confirmOpening(uint idx, uint stakedNGTs) public {

        // check if the player is the sender
        require(msg.sender == marketsData[idx].player);

        // check if the market exists
        require(marketsFlag[idx] == true);

        // check if the NGTs amount declared by dso that has to be staked by the player is correct
        require(marketsData[idx].playerStaking == stakedNGTs);

        // check if the market is waiting for the player starting confirm
        require(marketsData[idx].state == MarketState.WaitingConfirmToStart);

        // check the player tokens allowance
        require(stakedNGTs <= ngt.allowance(marketsData[idx].player, address(this)));

        // check if it is not too late to confirm
        require(now <= marketsData[idx].startTime);

        // Player staking: allowed tokens are transferred from player wallet to this smart contract
        ngt.transferFrom(marketsData[idx].player, address(this), marketsData[idx].playerStaking);

        // The market is allowed to start
        marketsData[idx].state = MarketState.Running;

        emit ConfirmedOpening(marketsData[idx].player, marketsData[idx].startTime, idx);
    }

    /// Refund requested by the DSO (i.e. the player has not confirmed the market opening)
    /// @param idx market identifier
    function refund(uint idx) public {
        // only the DSO is allowed to request a refund
        require(msg.sender == dso);

        // check if the market exists
        require(marketsFlag[idx] == true);

        // the market has to be in WaitingConfirmToStart state
        require(marketsData[idx].state == MarketState.WaitingConfirmToStart);

        // check if the market startTime is passed
        require(marketsData[idx].startTime < now);

        // refund the DSO staking
        ngt.transfer(dso, marketsData[idx].dsoStaking);

        // Set the market result
        marketsData[idx].result = MarketResult.NotPlayed;

        // Set the market state
        marketsData[idx].state = MarketState.ClosedNotPlayed;

        emit RefundedDSO(dso, idx);
    }

    /// Settle the market, performed by dso
    /// @param idx market identifier
    /// @param powerPeak maximum power consumed by the player during the market
    function settle(uint idx, uint powerPeak) public {

        // check if the dso is the sender
        require(msg.sender == dso);

        // check if the market exists
        require(marketsFlag[idx] == true);

        // check if the market is running
        require(marketsData[idx].state == MarketState.Running);

        // check if the market period is already ended
        require(now >= marketsData[idx].endTime);

        marketsData[idx].powerPeakDeclaredByDso = powerPeak;
        marketsData[idx].state = MarketState.WaitingConfirmToEnd;

        emit Settled(marketsData[idx].player, marketsData[idx].startTime, idx, powerPeak);
    }

    /// Confirm the market settlement, performed by the player
    /// @param idx market identifier
    /// @param powerPeak maximum power consumed by the player during the market
    function confirmSettlement(uint idx, uint powerPeak) public {

        // check if the player is the sender
        require(msg.sender == marketsData[idx].player);

        // check if the market exists
        require(marketsFlag[idx] == true);

        // check if the market is waiting for the player ending confirm
        require(marketsData[idx].state == MarketState.WaitingConfirmToEnd);

        marketsData[idx].powerPeakDeclaredByPlayer = powerPeak;

        emit ConfirmedSettlement(marketsData[idx].player, marketsData[idx].startTime, idx, powerPeak);

        // check if the two peak declarations (DSO and player) are equal
        if(marketsData[idx].powerPeakDeclaredByDso == marketsData[idx].powerPeakDeclaredByPlayer) {

            // Finish the market sending the tokens to DSO and player according to the measured peak
            _decideMarket(idx);

            emit SuccessfulSettlement();
        }
        else {
            // The referee decision is requested
            marketsData[idx].state = MarketState.WaitingForTheReferee;

            emit UnsuccessfulSettlement(marketsData[idx].powerPeakDeclaredByDso, marketsData[idx].powerPeakDeclaredByPlayer);
        }
    }

    /// Decide the market final result
    /// @param idx market identifier
    function _decideMarket(uint idx) private {
        uint peak = marketsData[idx].powerPeakDeclaredByDso;
        uint tokensForDso;
        uint tokensForPlayer;
        uint peakDiff;

        // measured peak < lowerMax => PRIZE: the player takes all the DSO staking
        if(peak <= marketsData[idx].maxPowerLower) {
            tokensForDso = 0;
            tokensForPlayer = marketsData[idx].dsoStaking.add(marketsData[idx].playerStaking);

            // Set the market result as a player prize
            marketsData[idx].result = MarketResult.Prize;

            emit Prize(tokensForDso, tokensForPlayer);
        }
        // lowerMax <= measured peak <= upperMax => REVENUE: the player takes a part of the DSO staking
        else if(peak > marketsData[idx].maxPowerLower && peak <= marketsData[idx].maxPowerUpper) {
            // Calculate the revenue amount
            peakDiff = peak.sub(marketsData[idx].maxPowerLower);

            tokensForDso = peakDiff.mul(marketsData[idx].revenueFactor);

            tokensForPlayer = marketsData[idx].dsoStaking.sub(tokensForDso);

            tokensForPlayer = tokensForPlayer.add(marketsData[idx].playerStaking);

            // Set the market result as a player revenue
            marketsData[idx].result = MarketResult.Revenue;

            emit Revenue(tokensForDso, tokensForPlayer);
        }
        // measured peak > upperMax => PENALTY/CRASH: the DSO takes a part of/all the revenue staking
        else {
            // Calculate the penalty amount
            peakDiff = peak.sub(marketsData[idx].maxPowerUpper);

            tokensForDso = peakDiff.mul(marketsData[idx].penaltyFactor);

            // If the penalty exceeds the staking => the DSO takes it all
            if(tokensForDso >= marketsData[idx].playerStaking) {
                tokensForPlayer = 0;
                tokensForDso = marketsData[idx].dsoStaking.add(marketsData[idx].playerStaking);

                // Set the market result as a player penalty
                marketsData[idx].result = MarketResult.Crash;

                emit Crash(tokensForDso, tokensForPlayer);
            }
            else {
                tokensForPlayer = marketsData[idx].playerStaking.sub(tokensForDso);
                tokensForDso = tokensForDso.add(marketsData[idx].dsoStaking);

                // Set the market result as a player penalty
                marketsData[idx].result = MarketResult.Penalty;

                emit Penalty(tokensForDso, tokensForPlayer);
            }
        }

        _saveAndTransfer(idx, tokensForDso, tokensForPlayer);
    }

    /// Save the final result and transfer the tokens
    /// @param idx market identifier
    /// @param _tokensForDso NGTSs to send to DSO
    /// @param _tokensForPlayer NGTSs to send to player
    function _saveAndTransfer(uint idx, uint _tokensForDso, uint _tokensForPlayer) private {
        // save the amounts to send
        marketsData[idx].tknReleasedToDso = _tokensForDso;
        marketsData[idx].tknReleasedToPlayer = _tokensForPlayer;

        // Send tokens to dso
        if(marketsData[idx].result != MarketResult.Prize) {
            ngt.transfer(dso, marketsData[idx].tknReleasedToDso);
        }

        // Send tokens to player
        if(marketsData[idx].result != MarketResult.Crash) {
            ngt.transfer(marketsData[idx].player, marketsData[idx].tknReleasedToPlayer);
        }

        // Close the market
        marketsData[idx].state = MarketState.Closed;
        emit Closed(marketsData[idx].result);
    }

    /// Takes the final decision to close the market whene player and DSO do not agree about the settlement, performed by the referee
    /// @param idx market identifier
    /// @param _powerPeak maximum power consumed by the player during the market
    function performRefereeDecision(uint idx, uint _powerPeak) public {

        // the sender has to be the referee
        require(msg.sender == marketsData[idx].referee);

        // the market is waiting for the referee decision
        require(marketsData[idx].state == MarketState.WaitingForTheReferee);

        // Calculate the total staking
        uint tokensStaked = marketsData[idx].dsoStaking.add(marketsData[idx].playerStaking);

        // Calculate the tokens for the referee
        uint tokensForReferee = tokensStaked.div(uint(100).div(marketsData[idx].revPercReferee));

        // Calculate the tokens amount for the honest actor
        uint tokensForHonest = tokensStaked.sub(tokensForReferee);

        emit RefereeIntervention(marketsData[idx].player, marketsData[idx].startTime, idx);

        // Check if the DSO declared the truth (i.e. player cheated)
        if(marketsData[idx].powerPeakDeclaredByDso == _powerPeak)
        {
            marketsData[idx].result = MarketResult.PlayerCheating;

            // Send tokens to the honest DSO
            ngt.transfer(dso, tokensForHonest);

            emit PlayerCheated();
        }
        // Check if the player declared the truth (i.e. DSO cheated)
        else if(marketsData[idx].powerPeakDeclaredByPlayer == _powerPeak)
        {
            marketsData[idx].result = MarketResult.DSOCheating;

            // Send tokens to the honest player
            ngt.transfer(marketsData[idx].player, tokensForHonest);

            emit DSOCheated();
        }
        // Both dso and player are cheating, the token are sent to address(0) :D
        else {
            marketsData[idx].result = MarketResult.Cheaters;

            // There are no honest, the related tokens are burnt
            ngt.burn(tokensForHonest);

            emit DSOAndPlayerCheated();
            emit BurntTokens(tokensForHonest);
        }

        // Send tokens to referee
        ngt.transfer(marketsData[idx].referee, tokensForReferee);

        // Close the market
        marketsData[idx].state = MarketState.ClosedAfterJudgement;
        emit ClosedAfterJudgement(marketsData[idx].result);
    }

    /// Check the revenue factor
    /// @param _maxLow lower limit of the maximum power consumed by player
    /// @param _maxUp upper limit of the maximum power consumed by player
    /// @param _revFactor revenue factor [NGT/kW]
    /// @param _stakedNGTs DSO staking of NGTs token
    /// @return TRUE if the the checking is passed, FALSE otherwise
    function _checkRevenueFactor(uint _maxUp, uint _maxLow, uint _revFactor, uint _stakedNGTs) pure private returns(bool) {
        uint calcNGTs = _maxUp.sub(_maxLow);
        calcNGTs = calcNGTs.mul(_revFactor);

        // (_maxUp - _maxLow)*_revFactor == _stakedNGTs
        return calcNGTs == _stakedNGTs;
    }

    /// Check the startTime
    /// @param _ts timestamp
    /// @param _type market type (0: monthly, 1: daily, 2: hourly)
    /// @return TRUE if timestamp is correct (i.e. YYYY-MM-01 00:00:00: monthly, YYYY-MM-DD 00:00:00: daily, YYYY-MM-DD HH:00:00: hourly), FALSE otherwise
    function _checkStartTime(uint _ts, MarketType _type) pure private returns(bool) {

        // Monthly market type
        if(_type == MarketType.Monthly) {
            return (getDay(_ts) == 1) && (getHour(_ts) == 0) && (getMinute(_ts) == 0) && (getSecond(_ts) == 0);
        }
        // Daily market type
        else if(_type == MarketType.Daily) {
            return (getHour(_ts) == 0) && (getMinute(_ts) == 0) && (getSecond(_ts) == 0);
        }
        // Hourly market type
        else if(_type == MarketType.Hourly) {
            return (getMinute(_ts) == 0) && (getSecond(_ts) == 0);
        }
        // Wrong market type
        else {
            return false;
        }
    }

    /// Calculate the endTime timestamp
    /// @param _ts starting market timestamp
    /// @param _type market type (0: monthly, 1: daily, 2: hourly)
    /// @return ending startime
    function _calcEndTime(uint _ts, MarketType _type) pure private returns(uint) {
        // Monthly market type
        if(_type == MarketType.Monthly) {
            return toTimestamp(getYear(_ts), getMonth(_ts), getDaysInMonth(getMonth(_ts), getYear(_ts)), 23, 59, 59);
        }
        // Daily market type
        else if(_type == MarketType.Daily) {
            return toTimestamp(getYear(_ts), getMonth(_ts), getDay(_ts), 23, 59, 59);
        }
        // Hourly market type
        else if(_type == MarketType.Hourly) {
            return toTimestamp(getYear(_ts), getMonth(_ts), getDay(_ts), getHour(_ts), 59, 59);
        }
        // Wrong market type
        else {
            return 0;
        }
    }

    /// Calculate the idx of market hashing an address (the player) and a timestamp (the market starting time)
    /// @param _addr address wallet
    /// @param _ts timestamp
    /// @param _type market type (0: monthly, 1: daily, 2: hourly)
    /// @return hash of the two inputs
    function calcIdx(address _addr, uint _ts, MarketType _type) pure public returns(uint) {
        return uint(keccak256(abi.encodePacked(_addr, _ts, _type)));
    }

    // Getters

    /// @param _idx market identifier
    /// @return market state (0: None, 1: NotRunning, 2: WaitingConfirmToStart, 3: Running, 4: WaitingConfirmToEnd, 5: WaitingForTheReferee, 6: Closed, 7: ClosedAfterJudgement, 8: ClosedNotPlayed)
    function getState(uint _idx) view public returns(MarketState)       { return marketsData[_idx].state; }

    /// @param _idx market identifier
    /// @return market final result (0: None, 1: NotDecided, 2: NotPlayed, 3: Prize, 4: Revenue, 5: Penalty, 6: Crash, 7: DSOCheating, 8: PlayerCheating, 9: Cheaters)
    function getResult(uint _idx) view public returns(MarketResult)     { return marketsData[_idx].result; }

    /// @param _idx market identifier
    /// @return the player address
    function getPlayer(uint _idx) view public returns(address)          { return marketsData[_idx].player; }

    /// @param _idx market identifier
    /// @return the referee address
    function getReferee(uint _idx) view public returns(address)         { return marketsData[_idx].referee; }

    /// @param _idx market identifier
    /// @return the market starting timestamp
    function getStartTime(uint _idx) view public returns(uint)          { return marketsData[_idx].startTime; }

    /// @param _idx market identifier
    /// @return the market ending timestamp
    function getEndTime(uint _idx) view public returns(uint)            { return marketsData[_idx].endTime; }

    /// @param _idx market identifier
    /// @return the lower maximum limit
    function getLowerMaximum(uint _idx) view public returns(uint)       { return marketsData[_idx].maxPowerLower; }

    /// @param _idx market identifier
    /// @return the upper maximum limit
    function getUpperMaximum(uint _idx) view public returns(uint)       { return marketsData[_idx].maxPowerUpper; }

    /// @param _idx market identifier
    /// @return the revenue factor
    function getRevenueFactor(uint _idx) view public returns(uint)      { return marketsData[_idx].revenueFactor; }

    /// @param _idx market identifier
    /// @return the penalty factor
    function getPenaltyFactor(uint _idx) view public returns(uint)      { return marketsData[_idx].penaltyFactor; }

    /// @param _idx market identifier
    /// @return the DSO staked amount
    function getDsoStake(uint _idx) view public returns(uint)           { return marketsData[_idx].dsoStaking; }

    /// @param _idx market identifier
    /// @return the player staked amount
    function getPlayerStake(uint _idx) view public returns(uint)        { return marketsData[_idx].playerStaking; }

    /// @param _idx market identifier
    /// @return TRUE if the market exists, FALSE otherwise
    function getFlag(uint _idx) view public returns(bool)                { return marketsFlag[_idx];}
}

// File: contracts/GroupsManager.sol

/// Manager of markets groups
contract GroupsManager is Ownable{

    /// Address of the token
    address public token;

    /// Mapping containing the managers of the market groups
    mapping (address => MarketsManager) groups;

    /// Mapping to check the group existence
    mapping (address => bool) groupsFlags;

    // Events

    /// A group has been added
    /// @param dso The DSO wallet
    /// @param token The NemoGrid token address
    event AddedGroup(address dso, address token);

    /// Constructor
    /// @param _token The NemoGrid token address
    constructor(address _token) public {
        token = _token;
    }

    /// Add a markets group, defined by the couple (dso, token)
    /// @param _dso The DSO wallet
    function addGroup(address _dso) onlyOwner public {

        // The dso cannot be also the owner
        require(owner() != _dso);

        // Check if this markets set already exists
        require(groupsFlags[_dso] == false);

        // a set of markets is defined by the triple (dso, player, token)
        groups[_dso] = new MarketsManager(_dso, token);
        groupsFlags[_dso] = true;

        emit AddedGroup(_dso, token);
    }

    // View functions

    /// @param _dso The DSO wallet
    /// @return TRUE if the group exists, FALSE otherwise
    function getFlag(address _dso) view public returns(bool)         { return groupsFlags[_dso]; }

    /// @param _dso The DSO wallet
    /// @return the group address
    function getAddress(address _dso) view public returns(address)   { return address(groups[_dso]); }
}