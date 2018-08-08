pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
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


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

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
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}






/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}


contract SimplePreTGE is Ownable {

  bool public allocationsLocked;

  struct Contribution {
    bool hasVested;
    uint256 weiContributed;
  }
  mapping (address => Contribution)  public contributions;

  function disableAllocationModificationsForEver() external onlyOwner returns(bool) {
    allocationsLocked = true;
  }

  function bulkReserveTokensForAddresses(address[] addrs, uint256[] weiContributions, bool[] _vestingDecisions) onlyOwner external returns(bool) {
    require(!allocationsLocked);
    require((addrs.length == weiContributions.length) && (addrs.length == _vestingDecisions.length));
    for (uint i=0; i<addrs.length; i++) {
      contributions[addrs[i]].weiContributed = weiContributions[i];
      contributions[addrs[i]].hasVested = _vestingDecisions[i];
    }
    return true;
  }

}


contract SimpleTGE is Ownable {
  using SafeMath for uint256;

  // start and end timestamps (both inclusive) when sale is open
  uint256 public publicTGEStartBlockTimeStamp;

  uint256 public publicTGEEndBlockTimeStamp;

  // address where funds are collected
  address public fundsWallet;

  // amount of raised money in wei
  uint256 public weiRaised;

  // sale cap in wei
  uint256 public totalCapInWei;

  // individual cap in wei
  uint256 public individualCapInWei;

  // how long the TRS subscription is open after the TGE.
  uint256 public TRSOffset = 5 days;

  mapping (address => bool) public whitelist;

  address[] public contributors;
  struct Contribution {
    bool hasVested;
    uint256 weiContributed;
  }

  mapping (address => Contribution)  public contributions;

  modifier whilePublicTGEIsActive() {
    require(block.timestamp >= publicTGEStartBlockTimeStamp && block.timestamp <= publicTGEEndBlockTimeStamp);
    _;
  }

  modifier isWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  function blacklistAddresses(address[] addrs) external onlyOwner returns(bool) {
    require(addrs.length <= 100);
    for (uint i = 0; i < addrs.length; i++) {
      require(addrs[i] != address(0));
      whitelist[addrs[i]] = false;
    }
    return true;
  }

  function whitelistAddresses(address[] addrs) external onlyOwner returns(bool) {
    require(addrs.length <= 100);
    for (uint i = 0; i < addrs.length; i++) {
      require(addrs[i] != address(0));
      whitelist[addrs[i]] = true;
    }
    return true;
  }

  /**
   * @dev Transfer all Ether held by the contract to the address specified by owner.
   */
  function reclaimEther(address _beneficiary) external onlyOwner {
    _beneficiary.transfer(this.balance);
  }

  function SimpleTGE (
    address _fundsWallet,
    uint256 _publicTGEStartBlockTimeStamp,
    uint256 _publicTGEEndBlockTimeStamp,
    uint256 _individualCapInWei,
    uint256 _totalCapInWei
  ) public
  {
    require(_publicTGEStartBlockTimeStamp >= block.timestamp);
    require(_publicTGEEndBlockTimeStamp > _publicTGEStartBlockTimeStamp);
    require(_fundsWallet != address(0));
    require(_individualCapInWei > 0);
    require(_individualCapInWei <= _totalCapInWei);
    require(_totalCapInWei > 0);

    fundsWallet = _fundsWallet;
    publicTGEStartBlockTimeStamp = _publicTGEStartBlockTimeStamp;
    publicTGEEndBlockTimeStamp = _publicTGEEndBlockTimeStamp;
    individualCapInWei = _individualCapInWei;
    totalCapInWei = _totalCapInWei;
  }

  // allows changing the individual cap.
  function changeIndividualCapInWei(uint256 _individualCapInWei) onlyOwner external returns(bool) {
      require(_individualCapInWei > 0);
      require(_individualCapInWei < totalCapInWei);
      individualCapInWei = _individualCapInWei;
      return true;
  }

  // low level token purchase function
  function contribute(bool _vestingDecision) internal {
    // validations
    require(msg.sender != address(0));
    require(msg.value != 0);
    require(weiRaised.add(msg.value) <= totalCapInWei);
    require(contributions[msg.sender].weiContributed.add(msg.value) <= individualCapInWei);
    // if we have not received any WEI from this address until now, then we add this address to contributors list.
    if (contributions[msg.sender].weiContributed == 0) {
      contributors.push(msg.sender);
    }
    contributions[msg.sender].weiContributed = contributions[msg.sender].weiContributed.add(msg.value);
    weiRaised = weiRaised.add(msg.value);
    contributions[msg.sender].hasVested = _vestingDecision;
    fundsWallet.transfer(msg.value);
  }

  function contributeAndVest() external whilePublicTGEIsActive isWhitelisted payable {
    contribute(true);
  }

  function contributeWithoutVesting() public whilePublicTGEIsActive isWhitelisted payable {
    contribute(false);
  }

  // fallback function can be used to buy tokens
  function () external payable {
    contributeWithoutVesting();
  }

  // Vesting logic
  // The following cases are checked for _beneficiary&#39;s actions:
  function vest(bool _vestingDecision) external isWhitelisted returns(bool) {
    bool existingDecision = contributions[msg.sender].hasVested;
    require(existingDecision != _vestingDecision);
    require(block.timestamp >= publicTGEStartBlockTimeStamp);
    require(contributions[msg.sender].weiContributed > 0);
    // Ensure vesting cannot be done once TRS starts
    if (block.timestamp > publicTGEEndBlockTimeStamp) {
      require(block.timestamp.sub(publicTGEEndBlockTimeStamp) <= TRSOffset);
    }
    contributions[msg.sender].hasVested = _vestingDecision;
    return true;
  }
}

contract LendroidSupportToken is MintableToken, PausableToken {

  string public constant name = "Lendroid Support Token";
  string public constant symbol = "LST";
  uint256 public constant decimals = 18;
  uint256 public constant MAX_SUPPLY = 12000000000 * (10 ** uint256(decimals));// 12 billion tokens, 18 decimal places

  /**
   * @dev Constructor that pauses tradability of tokens.
   */
  function LendroidSupportToken() public {
    paused = true;
  }


  /**
   * @dev totalSupply is set via the minting process
   */

  function mint(address to, uint256 amount) onlyOwner public returns (bool) {
    require(totalSupply_ + amount <= MAX_SUPPLY);
    return super.mint(to, amount);
  }

}

/**
 * @title SimpleLSTDistribution
 * @dev SimpleLSTDistribution contract provides interface for the contributor to withdraw their allocations / initiate the vesting contract
 */
contract SimpleLSTDistribution is Ownable {
  using SafeMath for uint256;

  SimplePreTGE public SimplePreTGEContract;
  SimpleTGE public SimpleTGEContract;
  LendroidSupportToken public token;
  uint256 public LSTRatePerWEI = 48000;
  //vesting related params
  // bonus multiplied to every vesting contributor&#39;s allocation
  uint256 public vestingBonusMultiplier;
  uint256 public vestingBonusMultiplierPrecision = 1000000;
  uint256 public vestingDuration;
  uint256 public vestingStartTime;

  struct allocation {
    bool shouldVest;
    uint256 weiContributed;
    uint256 LSTAllocated;
    bool hasWithdrawn;
  }
  // maps all allocations claimed by contributors
  mapping (address => allocation)  public allocations;

  // map of address to token vesting contract
  mapping (address => TokenVesting) public vesting;

  /**
   * event for token transfer logging
   * @param beneficiary who is receiving the tokens
   * @param tokens amount of tokens given to the beneficiary
   */
  event LogLSTsWithdrawn(address beneficiary, uint256 tokens);

  /**
   * event for time vested token transfer logging
   * @param beneficiary who is receiving the time vested tokens
   * @param tokens amount of tokens that will be vested to the beneficiary
   * @param start unix timestamp at which the tokens will start vesting
   * @param cliff duration in seconds after start time at which vesting will start
   * @param duration total duration in seconds in which the tokens will be vested
   */
  event LogTimeVestingLSTsWithdrawn(address beneficiary, uint256 tokens, uint256 start, uint256 cliff, uint256 duration);

  function SimpleLSTDistribution(
      address _SimplePreTGEAddress,
      address _SimpleTGEAddress,
      uint256 _vestingBonusMultiplier,
      uint256 _vestingDuration,
      uint256 _vestingStartTime,
      address _LSTAddress
    ) public {

    require(_SimplePreTGEAddress != address(0));
    require(_SimpleTGEAddress != address(0));
    require(_vestingBonusMultiplier >= 1000000);
    require(_vestingBonusMultiplier <= 10000000);
    require(_vestingDuration > 0);
    require(_vestingStartTime > block.timestamp);

    token = LendroidSupportToken(_LSTAddress);
    // token = new LendroidSupportToken();

    SimplePreTGEContract = SimplePreTGE(_SimplePreTGEAddress);
    SimpleTGEContract = SimpleTGE(_SimpleTGEAddress);
    vestingBonusMultiplier = _vestingBonusMultiplier;
    vestingDuration = _vestingDuration;
    vestingStartTime = _vestingStartTime;
  }

  // member function to mint tokens to a beneficiary
  function mintTokens(address beneficiary, uint256 tokens) public onlyOwner {
    require(beneficiary != 0x0);
    require(tokens > 0);
    require(token.mint(beneficiary, tokens));
    LogLSTsWithdrawn(beneficiary, tokens);
  }

  function withdraw() external {
    require(!allocations[msg.sender].hasWithdrawn);
    // make sure simpleTGE is over and the TRS subscription has ended
    require(block.timestamp > SimpleTGEContract.publicTGEEndBlockTimeStamp().add(SimpleTGEContract.TRSOffset()));
    // allocations should be locked in the pre-TGE
    require(SimplePreTGEContract.allocationsLocked());
    // should have participated in the TGE or the pre-TGE
    bool _preTGEHasVested;
    uint256 _preTGEWeiContributed;
    bool _publicTGEHasVested;
    uint256 _publicTGEWeiContributed;
    (_publicTGEHasVested, _publicTGEWeiContributed) = SimpleTGEContract.contributions(msg.sender);
    (_preTGEHasVested, _preTGEWeiContributed) = SimplePreTGEContract.contributions(msg.sender);
    uint256 _totalWeiContribution = _preTGEWeiContributed.add(_publicTGEWeiContributed);
    require(_totalWeiContribution > 0);
    // the same contributor could have contributed in the pre-tge and the tge, so we add the contributions.
    bool _shouldVest = _preTGEHasVested || _publicTGEHasVested;
    allocations[msg.sender].hasWithdrawn = true;
    allocations[msg.sender].shouldVest = _shouldVest;
    allocations[msg.sender].weiContributed = _totalWeiContribution;
    uint256 _lstAllocated;
    if (!_shouldVest) {
      _lstAllocated = LSTRatePerWEI.mul(_totalWeiContribution);
      allocations[msg.sender].LSTAllocated = _lstAllocated;
      require(token.mint(msg.sender, _lstAllocated));
      LogLSTsWithdrawn(msg.sender, _lstAllocated);
    }
    else {
      _lstAllocated = LSTRatePerWEI.mul(_totalWeiContribution).mul(vestingBonusMultiplier).div(vestingBonusMultiplierPrecision);
      allocations[msg.sender].LSTAllocated = _lstAllocated;
      uint256 _withdrawNow = _lstAllocated.div(10);
      uint256 _vestedPortion = _lstAllocated.sub(_withdrawNow);
      vesting[msg.sender] = new TokenVesting(msg.sender, vestingStartTime, 0, vestingDuration, false);
      require(token.mint(msg.sender, _withdrawNow));
      LogLSTsWithdrawn(msg.sender, _withdrawNow);
      require(token.mint(address(vesting[msg.sender]), _vestedPortion));
      LogTimeVestingLSTsWithdrawn(address(vesting[msg.sender]), _vestedPortion, vestingStartTime, 0, vestingDuration);
    }
  }

  // member function that can be called to release vested tokens periodically
  function releaseVestedTokens(address beneficiary) public {
    require(beneficiary != 0x0);

    TokenVesting tokenVesting = vesting[beneficiary];
    tokenVesting.release(token);
  }

  // unpauseToken token for transfers
  function unpauseToken() public onlyOwner {
    token.unpause();
  }

}