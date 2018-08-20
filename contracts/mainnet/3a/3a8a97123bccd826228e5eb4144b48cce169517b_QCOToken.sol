pragma solidity ^0.4.11;

// File: zeppelin/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/QravityTeamTimelock.sol

contract QravityTeamTimelock {
    using SafeMath for uint256;

    uint16 constant ORIGIN_YEAR = 1970;

    // Account that can release tokens
    address public controller;

    uint256 public releasedAmount;

    ERC20Basic token;

    function QravityTeamTimelock(ERC20Basic _token, address _controller)
    public
    {
        require(address(_token) != 0x0);
        require(_controller != 0x0);
        token = _token;
        controller = _controller;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release(address _beneficiary, uint256 _amount)
    public
    {
        require(msg.sender == controller);
        require(_amount > 0);
        require(_amount <= availableAmount(now));
        token.transfer(_beneficiary, _amount);
        releasedAmount = releasedAmount.add(_amount);
    }

    function availableAmount(uint256 timestamp)
    public view
    returns (uint256 amount)
    {
        uint256 totalWalletAmount = releasedAmount.add(token.balanceOf(this));
        uint256 canBeReleasedAmount = totalWalletAmount.mul(availablePercent(timestamp)).div(100);
        return canBeReleasedAmount.sub(releasedAmount);
    }

    function availablePercent(uint256 timestamp)
    public view
    returns (uint256 factor)
    {
       uint256[10] memory releasePercent = [uint256(0), 20, 30, 40, 50, 60, 70, 80, 90, 100];
       uint[10] memory releaseTimes = [
           toTimestamp(2020, 4, 1),
           toTimestamp(2020, 7, 1),
           toTimestamp(2020, 10, 1),
           toTimestamp(2021, 1, 1),
           toTimestamp(2021, 4, 1),
           toTimestamp(2021, 7, 1),
           toTimestamp(2021, 10, 1),
           toTimestamp(2022, 1, 1),
           toTimestamp(2022, 4, 1),
           0
        ];

        // Set default to the 0% bonus.
        uint256 timeIndex = 0;

        for (uint256 i = 0; i < releaseTimes.length; i++) {
            if (timestamp < releaseTimes[i] || releaseTimes[i] == 0) {
                timeIndex = i;
                break;
            }
        }
        return releasePercent[timeIndex];
    }

    // Timestamp functions based on
    // https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
    function toTimestamp(uint16 year, uint8 month, uint8 day)
    internal pure returns (uint timestamp) {
        uint16 i;

        // Year
        timestamp += (year - ORIGIN_YEAR) * 1 years;
        timestamp += (leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR)) * 1 days;

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
            timestamp += monthDayCounts[i - 1] * 1 days;
        }

        // Day
        timestamp += (day - 1) * 1 days;

        // Hour, Minute, and Second are assumed as 0 (we calculate in GMT)

        return timestamp;
    }

    function leapYearsBefore(uint year)
    internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function isLeapYear(uint16 year)
    internal pure returns (bool) {
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
}

// File: contracts/Bonus.sol

library Bonus {
    uint16 constant ORIGIN_YEAR = 1970;
    struct BonusData {
        uint[7] factors; // aditional entry for 0% bonus
        uint[6] cutofftimes;
    }

    // Use storage keyword so that we write this to persistent storage.
    function initBonus(BonusData storage data)
    internal
    {
        data.factors = [uint256(300), 250, 200, 150, 100, 50, 0];
        data.cutofftimes = [toTimestamp(2018, 9, 1),
                            toTimestamp(2018, 9, 8),
                            toTimestamp(2018, 9, 15),
                            toTimestamp(2018, 9, 22),
                            toTimestamp(2018, 9, 29),
                            toTimestamp(2018, 10, 8)];
    }

    function getBonusFactor(uint timestamp, BonusData storage data)
    internal view returns (uint256 factor)
    {
        uint256 countcutoffs = data.cutofftimes.length;
        // Set default to the 0% bonus.
        uint256 timeIndex = countcutoffs;

        for (uint256 i = 0; i < countcutoffs; i++) {
            if (timestamp < data.cutofftimes[i]) {
                timeIndex = i;
                break;
            }
        }

        return data.factors[timeIndex];
    }

    function getFollowingCutoffTime(uint timestamp, BonusData storage data)
    internal view returns (uint nextTime)
    {
        uint256 countcutoffs = data.cutofftimes.length;
        // Set default to 0 meaning "no cutoff any more".
        nextTime = 0;

        for (uint256 i = 0; i < countcutoffs; i++) {
            if (timestamp < data.cutofftimes[i]) {
                nextTime = data.cutofftimes[i];
                break;
            }
        }

        return nextTime;
    }

    // Timestamp functions based on
    // https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
    function toTimestamp(uint16 year, uint8 month, uint8 day)
    internal pure returns (uint timestamp) {
        uint16 i;

        // Year
        timestamp += (year - ORIGIN_YEAR) * 1 years;
        timestamp += (leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR)) * 1 days;

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
            timestamp += monthDayCounts[i - 1] * 1 days;
        }

        // Day
        timestamp += (day - 1) * 1 days;

        // Hour, Minute, and Second are assumed as 0 (we calculate in GMT)

        return timestamp;
    }

    function leapYearsBefore(uint year)
    internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function isLeapYear(uint16 year)
    internal pure returns (bool) {
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
}

// File: contracts/QCOToken.sol

/*
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20.
*/
pragma solidity ^0.4.11;




contract QCOToken is StandardToken {

    // data structures
    enum States {
        Initial, // deployment time
        ValuationSet,
        Ico, // whitelist addresses, accept funds, update balances
        Aborted, // ICO aborted
        Operational, // production phase
        Paused         // for contract upgrades
    }

    mapping(address => uint256) public ethPossibleRefunds;

    uint256 public soldTokens;

    string public constant name = "Qravity Coin Token";

    string public constant symbol = "QCO";

    uint8 public constant decimals = 18;

    mapping(address => bool) public whitelist;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    address public tokenAssignmentControl;

    address public teamWallet;

    address public reserves;

    States public state;

    uint256 public endBlock;

    uint256 public ETH_QCO; //number of tokens per ETH

    uint256 constant pointMultiplier = 1e18; //100% = 1*10^18 points

    uint256 public constant maxTotalSupply = 1000000000 * pointMultiplier; //1B tokens

    uint256 public constant percentForSale = 50;

    Bonus.BonusData bonusData;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    //pausing the contract should extend the ico dates into the future.
    uint256 public pauseOffset = 0;

    uint256 public pauseLastStart = 0;


    //this creates the contract and stores the owner. it also passes in 3 addresses to be used later during the lifetime of the contract.
    function QCOToken(
        address _stateControl
    , address _whitelistControl
    , address _withdrawControl
    , address _tokenAssignmentControl
    , address _teamControl
    , address _reserves)
    public
    {
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdrawControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        moveToState(States.Initial);
        endBlock = 0;
        ETH_QCO = 0;
        totalSupply = maxTotalSupply;
        soldTokens = 0;
        Bonus.initBonus(bonusData);
        teamWallet = address(new QravityTeamTimelock(this, _teamControl));

        reserves = _reserves;
        balances[reserves] = totalSupply;
        Mint(reserves, totalSupply);
        Transfer(0x0, reserves, totalSupply);
    }

    event Whitelisted(address addr);

    event StateTransition(States oldState, States newState);

    modifier onlyWhitelist() {
        require(msg.sender == whitelistControl);
        _;
    }

    modifier onlyStateControl() {
        require(msg.sender == stateControl);
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl);
        _;
    }

    modifier onlyWithdraw() {
        require(msg.sender == withdrawControl);
        _;
    }

    modifier requireState(States _requiredState) {
        require(state == _requiredState);
        _;
    }

    /**
    BEGIN ICO functions
    */

    //this is the main funding function, it updates the balances of tokens during the ICO.
    //no particular incentive schemes have been implemented here
    //it is only accessible during the "ICO" phase.
    function() payable
    public
    requireState(States.Ico)
    {
        require(whitelist[msg.sender] == true);
        require(msg.value > 0);
        // We have reports that some wallet contracts may end up sending a single null-byte.
        // Still reject calls of unknown functions, which are always at least 4 bytes of data.
        require(msg.data.length < 4);
        require(block.number < endBlock);

        uint256 soldToTuserWithBonus = calcBonus(msg.value);

        issueTokensToUser(msg.sender, soldToTuserWithBonus);
        ethPossibleRefunds[msg.sender] = ethPossibleRefunds[msg.sender].add(msg.value);
    }

    function issueTokensToUser(address beneficiary, uint256 amount)
    internal
    {
        uint256 soldTokensAfterInvestment = soldTokens.add(amount);
        require(soldTokensAfterInvestment <= maxTotalSupply.mul(percentForSale).div(100));

        balances[beneficiary] = balances[beneficiary].add(amount);
        balances[reserves] = balances[reserves].sub(amount);
        soldTokens = soldTokensAfterInvestment;
        Transfer(reserves, beneficiary, amount);
    }

    function getCurrentBonusFactor()
    public view
    returns (uint256 factor)
    {
        //we pass in  now-pauseOffset as the "now time" for purposes of calculating the bonus factor
        return Bonus.getBonusFactor(now - pauseOffset, bonusData);
    }

    function getNextCutoffTime()
    public view returns (uint timestamp)
    {
        return Bonus.getFollowingCutoffTime(now - pauseOffset, bonusData);
    }

    function calcBonus(uint256 weiAmount)
    constant
    public
    returns (uint256 resultingTokens)
    {
        uint256 basisTokens = weiAmount.mul(ETH_QCO);
        //percentages are integer numbers as per mill (promille) so we can accurately calculate 0.5% = 5. 100% = 1000
        uint256 perMillBonus = getCurrentBonusFactor();
        //100% + bonus % times original amount divided by 100%.
        return basisTokens.mul(per_mill + perMillBonus).div(per_mill);
    }

    uint256 constant per_mill = 1000;


    function moveToState(States _newState)
    internal
    {
        StateTransition(state, _newState);
        state = _newState;
    }
    // ICO contract configuration function
    // new_ETH_QCO is the new rate of ETH in QCO to use when no bonus applies
    // newEndBlock is the absolute block number at which the ICO must stop. It must be set after now + silence period.
    function updateEthICOVariables(uint256 _new_ETH_QCO, uint256 _newEndBlock)
    public
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet);
        require(_new_ETH_QCO > 0);
        require(block.number < _newEndBlock);
        endBlock = _newEndBlock;
        // initial conversion rate of ETH_QCO set now, this is used during the Ico phase.
        ETH_QCO = _new_ETH_QCO;
        moveToState(States.ValuationSet);
    }

    function startICO()
    public
    onlyStateControl
    requireState(States.ValuationSet)
    {
        require(block.number < endBlock);
        moveToState(States.Ico);
    }

    function addPresaleAmount(address beneficiary, uint256 amount)
    public
    onlyTokenAssignmentControl
    {
        require(state == States.ValuationSet || state == States.Ico);
        issueTokensToUser(beneficiary, amount);
    }


    function endICO()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        burnAndFinish();
        moveToState(States.Operational);
    }

    function anyoneEndICO()
    public
    requireState(States.Ico)
    {
        require(block.number > endBlock);
        burnAndFinish();
        moveToState(States.Operational);
    }

    function burnAndFinish()
    internal
    {
        totalSupply = soldTokens.mul(100).div(percentForSale);

        uint256 teamAmount = totalSupply.mul(22).div(100);
        balances[teamWallet] = teamAmount;
        Transfer(reserves, teamWallet, teamAmount);

        uint256 reservesAmount = totalSupply.sub(soldTokens).sub(teamAmount);
        // Burn all tokens over the target amount.
        Transfer(reserves, 0x0, balances[reserves].sub(reservesAmount).sub(teamAmount));
        balances[reserves] = reservesAmount;

        mintingFinished = true;
        MintFinished();
    }

    function addToWhitelist(address _whitelisted)
    public
    onlyWhitelist
        //    requireState(States.Ico)
    {
        whitelist[_whitelisted] = true;
        Whitelisted(_whitelisted);
    }


    //emergency pause for the ICO
    function pause()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        moveToState(States.Paused);
        pauseLastStart = now;
    }

    //in case we want to completely abort
    function abort()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Aborted);
    }

    //un-pause
    function resumeICO()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Ico);
        //increase pauseOffset by the time it was paused
        pauseOffset = pauseOffset + (now - pauseLastStart);
    }

    //in case of a failed/aborted ICO every investor can get back their money
    function requestRefund()
    public
    requireState(States.Aborted)
    {
        require(ethPossibleRefunds[msg.sender] > 0);
        //there is no need for updateAccount(msg.sender) since the token never became active.
        uint256 payout = ethPossibleRefunds[msg.sender];
        //reverse calculate the amount to pay out
        ethPossibleRefunds[msg.sender] = 0;
        msg.sender.transfer(payout);
    }

    //after the ICO has run its course, the withdraw account can drain funds bit-by-bit as needed.
    function requestPayout(uint _amount)
    public
    onlyWithdraw //very important!
    requireState(States.Operational)
    {
        msg.sender.transfer(_amount);
    }

    //if this contract gets a balance in some other ERC20 contract - or even iself - then we can rescue it.
    function rescueToken(ERC20Basic _foreignToken, address _to)
    public
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(this));
    }
    /**
    END ICO functions
    */

    /**
    BEGIN ERC20 functions
    */
    function transfer(address _to, uint256 _value)
    public
    requireState(States.Operational)
    returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    requireState(States.Operational)
    returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    END ERC20 functions
    */
}