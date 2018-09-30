pragma solidity ^0.4.24;

// can refactor createSchedule to "approveAndCall" instead of having to approve and then call it

pragma solidity ^0.4.11;


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



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}













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







/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



/**
 * @title Element Token
 * @dev ERC20 Element Token)
 *
 * All initial tokens are assigned to the creator of
 * this contract.
 *
 */
contract ElementToken is StandardToken, Pausable {

  string public name = &#39;&#39;;               // Set the token name for display
  string public symbol = &#39;&#39;;             // Set the token symbol for display
  uint8 public decimals = 0;             // Set the token symbol for display

  /**
   * @dev Don&#39;t allow tokens to be sent to the contract
   */
  modifier rejectTokensToContract(address _to) {
    require(_to != address(this));
    _;
  }

  /**
   * @dev ElementToken Constructor
   * Runs only on initial contract creation.
   */
  function ElementToken(string _name, string _symbol, uint256 _tokens, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _tokens * 10**uint256(decimals);          // Set the total supply
    balances[msg.sender] = totalSupply;                      // Creator address is assigned all
    Transfer(0x0, msg.sender, totalSupply);                  // create Transfer event for minting
  }

  /**
   * @dev Transfer token for a specified address when not paused
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) rejectTokensToContract(_to) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another when not paused
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) rejectTokensToContract(_to) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender when not paused.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * Adding whenNotPaused
   */
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  /**
   * Adding whenNotPaused
   */
  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}
/**
 * @title TokenVestingInterface
 * @dev A token vesting interface contract that creates and manages internal token vesting schedules.
 * Vesting schedules are released periodically like a typical vesting scheme. They are set with a
 * periodic vesting interval and duration and optional start time and cliff.
 * Each vesting schedule is revocable by the owner.
 */
contract TokenVestingInterface is Ownable {
  using SafeMath for uint256;

  // Token used for vesting
  ElementToken elementToken;

  event ScheduleCreated(address indexed beneficiary, uint256 initialVestedAmount, uint256 vestingInterval, uint256 startDate, uint256 cliffDate, uint256 endDate, uint256 durationPeriod);
  event ScheduleTerminated(address indexed beneficiary, uint256 tokensReturned, uint256 tokensReleased, uint256 terminationDate);
  event TokensDisbursed(address indexed beneficiary, uint256 tokenAmount, uint256 disbursementDate);

  // mapping of beneficiaries
  mapping (address => VestingSchedule) public beneficiaries;

  struct VestingSchedule {
    address scheduleCreator;
    uint256 initialVestedAmount;
    uint256 durationInterval; // in seconds
    uint256 tokensReleased;
    uint256 startDate; // in seconds
    uint256 cliffDate; // in seconds
    uint256 endDate; // in seconds
    uint256 durationPeriod; // in seconds
    bool exists;
  }

  /**
   * @dev Modifier that checks if token sender can vest tokens
   * from their balance in the elementToken contract to the TokenVestingInterface
   * contract to create a token vesting schedule.
   * @dev This modifier also transfers the tokens. Requires prior approval given.
   * @param _address address to transfer tokens from
   * @param _amount the number of tokens
   */
  modifier canVest(address _address, uint256 _amount) {
    require(
      elementToken.transferFrom(_address, this, _amount),
      "Insufficient token balance of sender");
    _;
  }

    /**
   * @dev Modifier that checks if a vesting schedule doesn&#39;t exist for a
   * given beneficiary. Used to ensure a beneficiary can only have one vesting
   * schedule at a time.
   * @param _beneficiary address to create vesting schedule for
   */
  modifier canCreateSchedule(address _beneficiary) {
      require(!beneficiaries[_beneficiary].exists, "Schedule for beneficiary already exists");
      _;
  }

      /**
   * @dev Modifier that checks if a vesting schedule exists for a
   * given beneficiary. Used to limit calls to TerminateSchedule().
   * @param _beneficiary address to terminate vesting schedule for
   */
  modifier canTerminateSchedule(address _beneficiary) {
      require(beneficiaries[_beneficiary].exists, "Schedule for beneficiary doesn&#39;t exist");
      _;
  }

      /**
   * @dev Modifier that sets a vesting schedule into existence.
   * @param _beneficiary address to create a vesting schedule for
   */
  modifier setSchedule(address _beneficiary) {
      require(beneficiaries[_beneficiary].exists = true);
      _;
  }

    /**
   * @dev Modifier that verifies the amount being vested is more than 0.
   * Used for ensuring a user can only successfully create a vesting schedule
   * if they are vesting actual tokens.
   * @param _amount amount user is attempting to stake.
   */
  modifier checkAmount(uint256 _amount) {
      require(_amount > 0, "User cannot vest a 0 amount");
      _;
  }

  /**
   * @dev Initializes the token vesting interface.
   * @param _elementToken ERC20 The address of the token contract used for vesting.
   */
  constructor(ElementToken _elementToken) public {
      elementToken = _elementToken;
  }

    /**
   * @dev Creates an internal vesting schedule that vests a given amount to a beneficiary,
   * periodically until _startDate + _durationSec. By then all
   * of the balance will have vested.
   * @dev currently only Owner (TokenVestingInterface contract creator) can successfully call.
   * @dev beneficiary must not already have an existing vesting schedule.
   * @dev caller MUST have the given _vestAmount in their token balance.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _vestAmount the number of tokens being vested
   * @param _vestingInterval the intervals in seconds by which a new batch of tokens can be released
   * @param _startDate the date (in Unix time) at which vesting begins
   * @param _cliffSec duration in seconds of the cliff in which tokens will start vesting
   * @param _durationSec duration in seconds of the period in which the tokens will vest
   */
  function createSchedule(address _beneficiary, uint256 _vestAmount, uint256 _vestingInterval, uint256 _startDate, uint256 _cliffSec, uint256 _durationSec) public onlyOwner() canCreateSchedule(_beneficiary) setSchedule(_beneficiary) checkAmount(_vestAmount) canVest(msg.sender, _vestAmount) {
    _createSchedule(_beneficiary, _vestAmount, _vestingInterval, _startDate, _cliffSec, _durationSec);
  }

    /**
   * @dev Helper function that creates an internal vesting schedule.
   * @dev if 0 is given for _startDate, the vesting schedule begins now (block.timestamp).
   * @dev if 0 is given for _cliffSec, there is no cliff.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _vestAmount the number of tokens being vested
   * @param _vestingInterval the intervals in seconds by which a new batch of tokens can be released
   * @param _startDate the date (in Unix time) at which vesting begins
   * @param _cliffSec duration in seconds of the cliff in which tokens will start vesting
   * @param _durationSec duration in seconds of the period in which the tokens will vest
   */
  function _createSchedule(address _beneficiary, uint256 _vestAmount, uint256 _vestingInterval, uint256 _startDate, uint256 _cliffSec, uint256 _durationSec) internal {

    require(_durationSec >= _cliffSec);

    uint256 _now = now;
    if (_startDate == 0) {
      _startDate = _now;
    }

    uint256 _cliffDate = _startDate.add(_cliffSec);
    uint256 _endDate = _startDate.add(_durationSec);

    beneficiaries[_beneficiary] = VestingSchedule(msg.sender, _vestAmount, _vestingInterval, 0, _startDate, _cliffDate, _endDate, _durationSec, true);

    emit ScheduleCreated(_beneficiary, _vestAmount, _vestingInterval, _startDate, _cliffDate, _endDate, _durationSec);

  }

    /**
   * @dev Terminates an existing vesting schedule for a given beneficiary. Tokens already vested
   * according to schedule remain in the contract, the rest are returned to the caller.
   * @dev currently only Owner (TokenVestingInterface contract creator) can successfully call.
   * @dev beneficiary must have an existing vesting schedule to terminate.
   * @param _beneficiary address of beneficiary to terminate a vesting schedule with
   */
  function terminateSchedule(address _beneficiary) public onlyOwner() canTerminateSchedule(_beneficiary) {
    _terminateSchedule(_beneficiary);

  }

   /**
   * @dev Helper function that terminates an existing vesting schedule for a given beneficiary.
   * @param _beneficiary address of beneficiary to terminate a vesting schedule with
   */
  function _terminateSchedule(address _beneficiary) internal {

    VestingSchedule storage beneficiary = beneficiaries[_beneficiary];

    uint256 currentBalance = beneficiary.initialVestedAmount.sub(beneficiary.tokensReleased);

    uint256 unreleased = releasableAmount(_beneficiary);
    uint256 refund = currentBalance.sub(unreleased);

    elementToken.transfer(msg.sender, refund);
    if (unreleased > 0) {
        releaseTokens(_beneficiary);
    }

    beneficiary.exists = false;

    emit ScheduleTerminated(_beneficiary, refund, unreleased, block.timestamp);
  }

    /**
   * @dev Transfers vested tokens to beneficiary. There MUST be tokens ready for release
   * to call successfully.
   * @dev anyone can release tokens for a given beneficiary.
   * @param _beneficiary address of beneficiary to release tokens to
   */
  function releaseTokens(address _beneficiary) public {
    uint256 unreleased = releasableAmount(_beneficiary);

    require(unreleased > 0);

    beneficiaries[_beneficiary].tokensReleased = beneficiaries[_beneficiary].tokensReleased.add(unreleased);

    elementToken.transfer(_beneficiary, unreleased);

    emit TokensDisbursed(_beneficiary, unreleased, block.timestamp);
  }

    /**
   * @dev Calculates the amount that has already vested but has not been released yet.
   * @param _beneficiary address of beneficiary to calculate unreleased tokens for
   */
  function releasableAmount(address _beneficiary) public view returns (uint256) {
    return vestedAmount(_beneficiary).sub(beneficiaries[_beneficiary].tokensReleased);
  }

    /**
   * @dev Calculates the amount that has already been vested. Used to calculate
   * the releasableAmount.
   * @param _beneficiary address of beneficiary to calculate vested tokens for
   */
  function vestedAmount(address _beneficiary) public view returns (uint256) {
    VestingSchedule storage beneficiary = beneficiaries[_beneficiary];

    uint256 _initialVestedAmount = beneficiary.initialVestedAmount;
    uint256 _timePassed = block.timestamp.sub(beneficiary.startDate);
    uint256 _currentInterval = _timePassed.div(beneficiary.durationInterval);
    uint256 _totalIntervals = beneficiary.durationPeriod.div(beneficiary.durationInterval);

    if (block.timestamp < beneficiary.cliffDate) {
      return 0;
    } else if (!beneficiary.exists) {
        return beneficiary.tokensReleased;
    } else if (block.timestamp >= beneficiary.endDate) {
      return _initialVestedAmount;
    } else {
      return _initialVestedAmount.mul(_currentInterval).div(_totalIntervals);
    }
  }
}