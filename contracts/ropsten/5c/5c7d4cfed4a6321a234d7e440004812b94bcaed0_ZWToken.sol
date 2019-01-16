pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

  /**
  * @dev b percent of a, throws on overflow.
  */
  function percent(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    uint256 ab = mul(a, b);
    c = div(ab, 100);
    return c;
  }
}


contract DateTime {
    using SafeMath for uint256;

    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
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

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
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
        uint8 i;

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

    function getDeltaMonth(uint timestamp_now, uint timestamp_base) public pure returns (uint) {
        uint year_now = getYear(timestamp_now);
        uint year_base = getYear(timestamp_base);

        uint month_now = getMonth(timestamp_now);
        uint month_base = getMonth(timestamp_base);

        uint delta_month = year_now.mul(12).add(month_now).sub(year_base.mul(12).add(month_base));
        return delta_month;
    }

    function getYear(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
                if (isLeapYear(uint16(year - 1))) {
                        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                }
                else {
                        secondsAccountedFor -= YEAR_IN_SECONDS;
                }
                year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second)
        public pure returns (uint timestamp)
    {
        uint16 i;

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
        uint8[12] memory monthDayCounts;
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  /**
   * modifier
   */
  modifier notNullAddress(address _address) {
      require(_address != 0);
      _;
  }

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount)
      onlyOwner
      canMint
      notNullAddress(_to)
      public
      returns (bool)
  {
      totalSupply_ = totalSupply_.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Mint(_to, _amount);
      emit Transfer(address(0), _to, _amount);
      return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract ZWToken is CappedToken, PausableToken, DateTime {
    /*
     *  event
     */
    event UpdateHolderShareInfo(uint256 _name,
                                address _holderAddr,
                                uint256 _toBalanceAmount,
                                bool    _isAllSendToBalance,
                                uint256 _curr_send_amount,
                                uint256 _balances);
    /*
     *  Constants
     */
    string public constant name = "ZWToken";        // solium-disable-line uppercase
    string public constant symbol = "ZWT";          // solium-disable-line uppercase
    uint8 public constant decimals = 18;            // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 0;
    uint256 public constant MAX_SUPPLY = 2718281828 * (10 ** uint256(decimals));    // e

    uint256 public constant FOUNDATION = 0;           //基金会
    uint256 public constant FOUNDING_TEAM = 1;        //创世团队
    uint256 public constant COMMUNITY = 2;            //社区
    uint256 public constant DAPP_INCUBATION = 3;      //dapp孵化
    uint256 public constant PROMOTION_PARTNER = 4;    //推广合伙人
    uint256 public constant USER_INCENTIVE = 5;       //用户激励
    uint256 public constant MAX_NAME_DEF = 6;         //名称最大值定义

    /*
     *  Storage
     */
    // 创建时间
    uint256 public createTime;

    // <持有者地址, 名称>
    mapping (address => uint256) public holderNames;

    // <持有者名称, 持有者数据>
    mapping (uint256 => HolderInfo) public holderInfos;

    // 持有者数据
    struct HolderInfo {
        // 静态配置
        uint256   holderName;         //持有者名称
        uint256   initRatio;          //初始比例
        uint256   maxRatio;           //最大比例
        uint256   releaseRatio;       //锁仓释放比例(每月)

        // 动态数据
        address   holderAddr;         //持有者地址
        uint256   toBalanceAmount;    //已发放至账户余额的数量
        bool      isAllSendToBalance;    //是否已经全部发放到余额

        bool      isUsed;             // 用于判断key是否存在
    }

    /*
     *  Modifiers
     */
    //holder name 是否存在
    modifier holderNameValid(uint256 _name) {
        require(holderInfos[_name].isUsed);
        _;
    }

    //调用者是否是holder本人
    modifier isHolder(uint256 _name) {
        require(holderInfos[_name].holderAddr == msg.sender);
        _;
    }

    modifier holderAddrNoSet(uint256 _name) {
        require(holderInfos[_name].holderAddr == 0);
        _;
    }

    /**
    * @dev Constructor
    */
    constructor() CappedToken(MAX_SUPPLY) public {
        createTime           = now;
        totalSupply_         = INITIAL_SUPPLY;

        // 初始化添加持有者配置
        initHolderConfig();
    }

    function initHolderConfig() onlyOwner internal {
        // 添加持有者配置
        holderInfos[FOUNDATION] = HolderInfo({
            holderName:       FOUNDATION,
            initRatio:   5,
            maxRatio:    20,
            releaseRatio: 5,
            holderAddr:       0,
            toBalanceAmount:  0,
            isAllSendToBalance:  false,
            isUsed:           true
        });

        holderInfos[FOUNDING_TEAM] = HolderInfo({
            holderName:       FOUNDING_TEAM,
            initRatio:   5,
            maxRatio:    15,
            releaseRatio: 5,
            holderAddr:       0,
            toBalanceAmount:  0,
            isAllSendToBalance:  false,
            isUsed:           true
        });

        holderInfos[COMMUNITY] = HolderInfo({
            holderName:       COMMUNITY,
            initRatio:   30,
            maxRatio:    30,
            releaseRatio: 0,
            holderAddr:       0,
            toBalanceAmount:  0,
            isAllSendToBalance:  false,
            isUsed:           true
        });

        holderInfos[DAPP_INCUBATION] = HolderInfo({
            holderName:       DAPP_INCUBATION,
            initRatio:   10,
            maxRatio:    10,
            releaseRatio: 0,
            holderAddr:       0,
            toBalanceAmount:  0,
            isAllSendToBalance:  false,
            isUsed:           true
        });

        holderInfos[PROMOTION_PARTNER] = HolderInfo({
            holderName:       PROMOTION_PARTNER,
            initRatio:   10,
            maxRatio:    10,
            releaseRatio: 0,
            holderAddr:       0,
            toBalanceAmount:  0,
            isAllSendToBalance:  false,
            isUsed:           true
        });

        holderInfos[USER_INCENTIVE] = HolderInfo({
            holderName:       USER_INCENTIVE,
            initRatio:   15,
            maxRatio:    15,
            releaseRatio: 0,
            holderAddr:       0,
            toBalanceAmount:  0,
            isAllSendToBalance:  false,
            isUsed:           true
        });
    }

    function setHolderAddress(address _addr, uint256 _name)
        onlyOwner
        notNullAddress(_addr)
        holderNameValid(_name)
        holderAddrNoSet(_name)
        public
        returns (bool)
    {
        //设置持有者地址
        holderInfos[_name].holderAddr = _addr;
        holderNames[_addr] = _name;

        // 更新持有者数据
        return updateHolderShareInfo(_name);
    }

    function updateHolderShareInfo(uint256 _name)
        internal
        returns (bool)
    {
        // 份额已经全部发放完毕
        if (holderInfos[_name].isAllSendToBalance)
            return true;

        // 该账户应得的最大数量
        uint256 max_amount = MAX_SUPPLY.percent(holderInfos[_name].maxRatio);

        // 检查份额是否已经全部发放完毕
        if (holderInfos[_name].toBalanceAmount >= max_amount)
        {
            holderInfos[_name].isAllSendToBalance = true;
            return true;
        }

        uint256 should_send_amount = 0;

        // 如果是需要分批释放的账户
        if(holderInfos[_name].releaseRatio > 0)
        {
            // 根据锁仓已释放的月数 和 已经发放到余额的数量 计算本次需要发放到余额的数量
            // 并更新已经发放到余额的数量

            // 距离合约创建已经过去多少个月
            uint256 delta_month = getDeltaMonth(now, createTime);

            // 计算截止目前, 总共应发放的数量
            uint256 total_should_send_percent = holderInfos[_name].initRatio.add(delta_month.mul(holderInfos[_name].releaseRatio));
            should_send_amount = max_amount.percent(total_should_send_percent);
        }
        // 如果是一次性发放的账户
        else
        {
            // 根据已经发放到余额的数量 计算本次需要发放到余额的数量
            // 并更新已经发放到余额的数量
            should_send_amount = max_amount;
        }

        // 本次应发放的数量
        uint256 curr_send_amount = should_send_amount.sub(holderInfos[_name].toBalanceAmount);
        if (curr_send_amount == 0)
        {
            return true;
        }

        // 更新持有者余额
        address holderAddr = holderInfos[_name].holderAddr;
        if (mint(holderAddr, curr_send_amount))
        {
            // mint成功后更新
            holderInfos[_name].toBalanceAmount = holderInfos[_name].toBalanceAmount.add(curr_send_amount);
            if (holderInfos[_name].toBalanceAmount >= max_amount)
            {
                holderInfos[_name].isAllSendToBalance = true;
            }

            emit UpdateHolderShareInfo(_name,
                                      holderAddr,
                                      holderInfos[_name].toBalanceAmount,
                                      holderInfos[_name].isAllSendToBalance,
                                      curr_send_amount,
                                      balances[holderAddr]);
            return true;
        }
        return false;
    }

    function updateAllHoldersShareInfo()
        onlyOwner
        public
    {
        for (uint256 i = 0; i < MAX_NAME_DEF; i++)
        {
            updateHolderShareInfo(i);
        }
    }

    function claim(uint256 _name)
        public
        holderNameValid(_name)
        isHolder(_name)
        returns (bool)
    {
        return updateHolderShareInfo(_name);
    }

    // 查询holder的名称和地址
    function getHoldersNameAddr()
        public
        view
        returns(uint256[] _names, address[] _addresss)
    {
        _names = new uint256[](MAX_NAME_DEF);
        _addresss = new address[](MAX_NAME_DEF);

        for (uint256 i = 0; i < MAX_NAME_DEF; i++)
        {
            _names[i] = holderInfos[i].holderName;
            _addresss[i] = holderInfos[i].holderAddr;
        }
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
        return super.mint(_to, _amount);
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint whenNotPaused public returns (bool) {
        return super.finishMinting();
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner whenNotPaused public {
        super.transferOwnership(newOwner);
    }

    /**
    * The fallback function.
    */
    function() payable public {
        revert();
    }
}