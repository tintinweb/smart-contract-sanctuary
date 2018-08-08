pragma solidity 0.4.24;

// File: contracts/tokensale/DipTgeInterface.sol

contract DipTgeInterface {
    function tokenIsLocked(address _contributor) public constant returns (bool);
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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

// File: zeppelin-solidity/contracts/token/MintableToken.sol

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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/token/PausableToken.sol

/**
 * @title Pausable token
 *
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

// File: contracts/token/DipToken.sol

/**
 * @title DIP Token
 * @dev The Decentralized Insurance Platform Token.
 * @author Christoph Mussenbrock
 * @copyright 2017 Etherisc GmbH
 */

pragma solidity 0.4.24;





contract DipToken is PausableToken, MintableToken {

  string public constant name = "Decentralized Insurance Protocol";
  string public constant symbol = "DIP";
  uint256 public constant decimals = 18;
  uint256 public constant MAXIMUM_SUPPLY = 10**9 * 10**18; // 1 Billion 1&#39;000&#39;000&#39;000

  DipTgeInterface public DipTokensale;

  constructor() public {
    DipTokensale = DipTgeInterface(owner);
  }

  modifier shouldNotBeLockedIn(address _contributor) {
    // after LockIntTime2, we don&#39;t need to check anymore, and
    // the DipTokensale contract is no longer required.
    require(DipTokensale.tokenIsLocked(_contributor) == false);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public returns (bool) {
    if (totalSupply.add(_amount) > MAXIMUM_SUPPLY) {
      return false;
    }

    return super.mint(_to, _amount);
  }

  /**
   * Owner can transfer back tokens which have been sent to this contract by mistake.
   * @param  _token address of token contract of the respective tokens
   * @param  _to where to send the tokens
   */
  function salvageTokens(ERC20Basic _token, address _to) onlyOwner public {
    _token.transfer(_to, _token.balanceOf(this));
  }

  function transferFrom(address _from, address _to, uint256 _value) shouldNotBeLockedIn(_from) public returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }

  function transfer(address to, uint256 value) shouldNotBeLockedIn(msg.sender) public returns (bool) {
      return super.transfer(to, value);
  }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

// File: contracts/tokensale/DipWhitelistedCrowdsale.sol

/**
 * @title DIP Token Generating Event
 * @dev The Decentralized Insurance Platform Token.
 * @author Christoph Mussenbrock
 * @copyright 2017 Etherisc GmbH
 */

pragma solidity 0.4.24;





contract DipWhitelistedCrowdsale is Ownable {
  using SafeMath for uint256;

  struct ContributorData {
    uint256 allowance;
    uint256 contributionAmount;
    uint256 tokensIssued;
    bool airdrop;
    uint256 bonus;        // 0 == 0%, 4 == 25%, 10 == 10%
    uint256 lockupPeriod; // 0, 1 or 2 (years)
  }

  mapping (address => ContributorData) public contributorList;

  event Whitelisted(address indexed _contributor, uint256 _allowance, bool _airdrop, uint256 _bonus, uint256 _lockupPeriod);

  /**
   * Push contributor data to the contract before the crowdsale
   */
  function editContributors (
    address[] _contributorAddresses,
    uint256[] _contributorAllowance,
    bool[] _airdrop,
    uint256[] _bonus,
    uint256[] _lockupPeriod
  ) onlyOwner public {
    // Check if input data is consistent
    require(
      _contributorAddresses.length == _contributorAllowance.length &&
      _contributorAddresses.length == _airdrop.length &&
      _contributorAddresses.length == _bonus.length &&
      _contributorAddresses.length == _lockupPeriod.length
    );

    for (uint256 cnt = 0; cnt < _contributorAddresses.length; cnt = cnt.add(1)) {
      require(_bonus[cnt] == 0 || _bonus[cnt] == 4 || _bonus[cnt] == 10);
      require(_lockupPeriod[cnt] <= 2);

      address contributor = _contributorAddresses[cnt];
      contributorList[contributor].allowance = _contributorAllowance[cnt];
      contributorList[contributor].airdrop = _airdrop[cnt];
      contributorList[contributor].bonus = _bonus[cnt];
      contributorList[contributor].lockupPeriod = _lockupPeriod[cnt];

      emit Whitelisted(
        _contributorAddresses[cnt],
        _contributorAllowance[cnt],
        _airdrop[cnt],
        _bonus[cnt],
        _lockupPeriod[cnt]
      );
    }
  }

}

// File: zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}

// File: contracts/tokensale/DipTge.sol

/**
 * @title DIP Token Generating Event
 * @notice The Decentralized Insurance Platform Token.
 * @author Christoph Mussenbrock
 *
 * @copyright 2017 Etherisc GmbH
 */

pragma solidity 0.4.24;







contract DipTge is DipWhitelistedCrowdsale, FinalizableCrowdsale {

  using SafeMath for uint256;

  enum state { pendingStart, priorityPass, crowdsale, crowdsaleEnded }

  uint256 public startOpenPpTime;
  uint256 public hardCap;
  uint256 public lockInTime1; // token lock-in period for team, ECA, US accredited investors
  uint256 public lockInTime2; // token lock-in period for founders
  state public crowdsaleState = state.pendingStart;

  event DipTgeStarted(uint256 _time);
  event CrowdsaleStarted(uint256 _time);
  event HardCapReached(uint256 _time);
  event DipTgeEnded(uint256 _time);
  event TokenAllocated(address _beneficiary, uint256 _amount);

  constructor(
    uint256 _startTime,
    uint256 _startOpenPpTime,
    uint256 _endTime,
    uint256 _lockInTime1,
    uint256 _lockInTime2,
    uint256 _hardCap,
    uint256 _rate,
    address _wallet
  )
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    public
  {
    // Check arguments
    require(_startTime >= block.timestamp);
    require(_startOpenPpTime >= _startTime);
    require(_endTime >= _startOpenPpTime);
    require(_lockInTime1 >= _endTime);
    require(_lockInTime2 > _lockInTime1);
    require(_hardCap > 0);
    require(_rate > 0);
    require(_wallet != 0x0);

    // Set contract fields
    startOpenPpTime = _startOpenPpTime;
    hardCap = _hardCap;
    lockInTime1 = _lockInTime1;
    lockInTime2 = _lockInTime2;
    DipToken(token).pause();
  }

  function setRate(uint256 _rate) onlyOwner public {
    require(crowdsaleState == state.pendingStart);

    rate = _rate;
  }

  function unpauseToken() onlyOwner external {
    DipToken(token).unpause();
  }

  /**
   * Calculate the maximum remaining contribution allowed for an address
   * @param  _contributor the address of the contributor
   * @return maxContribution maximum allowed amount in wei
   */
  function calculateMaxContribution(address _contributor) public constant returns (uint256 _maxContribution) {
    uint256 maxContrib = 0;

    if (crowdsaleState == state.priorityPass) {
      maxContrib = contributorList[_contributor].allowance.sub(contributorList[_contributor].contributionAmount);

      if (maxContrib > hardCap.sub(weiRaised)) {
        maxContrib = hardCap.sub(weiRaised);
      }
    } else if (crowdsaleState == state.crowdsale) {
      if (contributorList[_contributor].allowance > 0) {
        maxContrib = hardCap.sub(weiRaised);
      }
    }

    return maxContrib;
  }

  /**
   * Calculate amount of tokens
   * This is used twice:
   * 1) For calculation of token amount plus optional bonus from wei amount contributed
   * In this case, rate is the defined exchange rate of ETH against DIP.
   * 2) For calculation of token amount plus optional bonus from DIP token amount
   * In the second case, rate == 1 because we have already calculated DIP tokens from RSC amount
   * by applying a factor of 10/32.
   * @param _contributor the address of the contributor
   * @param _amount contribution amount
   * @return _tokens amount of tokens
   */
  function calculateTokens(address _contributor, uint256 _amount, uint256 _rate) public constant returns (uint256 _tokens) {
    uint256 bonus = contributorList[_contributor].bonus;

    assert(bonus == 0 || bonus == 4 || bonus == 10);

    if (bonus > 0) {
      _tokens = _amount.add(_amount.div(bonus)).mul(_rate);
    } else {
      _tokens = _amount.mul(_rate);
    }
  }

  /**
   * Set the current state of the crowdsale.
   */
  function setCrowdsaleState() public {
    if (weiRaised >= hardCap && crowdsaleState != state.crowdsaleEnded) {

      crowdsaleState = state.crowdsaleEnded;
      emit HardCapReached(block.timestamp);
      emit DipTgeEnded(block.timestamp);

    } else if (
      block.timestamp >= startTime &&
      block.timestamp < startOpenPpTime &&
      crowdsaleState != state.priorityPass
    ) {

      crowdsaleState = state.priorityPass;
      emit DipTgeStarted(block.timestamp);

    } else if (
      block.timestamp >= startOpenPpTime &&
      block.timestamp <= endTime &&
      crowdsaleState != state.crowdsale
    ) {

      crowdsaleState = state.crowdsale;
      emit CrowdsaleStarted(block.timestamp);

    } else if (
      crowdsaleState != state.crowdsaleEnded &&
      block.timestamp > endTime
    ) {

      crowdsaleState = state.crowdsaleEnded;
      emit DipTgeEnded(block.timestamp);
    }
  }

  /**
   * The token buying function.
   * @param  _beneficiary  receiver of tokens.
   */
  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != 0x0);
    require(validPurchase());
    require(contributorList[_beneficiary].airdrop == false);

    setCrowdsaleState();

    uint256 weiAmount = msg.value;
    uint256 maxContrib = calculateMaxContribution(_beneficiary);
    uint256 refund;

    if (weiAmount > maxContrib) {
      refund = weiAmount.sub(maxContrib);
      weiAmount = maxContrib;
    }

    // stop here if transaction does not yield tokens
    require(weiAmount > 0);

    // calculate token amount to be created
    uint256 tokens = calculateTokens(_beneficiary, weiAmount, rate);

    assert(tokens > 0);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    require(token.mint(_beneficiary, tokens));
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    contributorList[_beneficiary].contributionAmount = contributorList[_beneficiary].contributionAmount.add(weiAmount);
    contributorList[_beneficiary].tokensIssued = contributorList[_beneficiary].tokensIssued.add(tokens);

    wallet.transfer(weiAmount);

    if (refund != 0) _beneficiary.transfer(refund);
  }

  /**
   * Check if token is locked.
   */
  function tokenIsLocked(address _contributor) public constant returns (bool) {

    if (block.timestamp < lockInTime1 && contributorList[_contributor].lockupPeriod == 1) {
      return true;
    } else if (block.timestamp < lockInTime2 && contributorList[_contributor].lockupPeriod == 2) {
      return true;
    }

    return false;

  }


  /**
   * Distribute tokens to selected team members & founders.
   * Unit of Allowance is ETH and is converted in number of tokens by multiplying with Rate.
   * This can be called by any whitelisted beneficiary.
   */
  function airdrop() public {
    airdropFor(msg.sender);
  }


  /**
   * Alternatively to airdrop(); tokens can be directly sent to beneficiaries by this function
   * This can be called only once.
   */
  function airdropFor(address _beneficiary) public {
    require(_beneficiary != 0x0);
    require(contributorList[_beneficiary].airdrop == true);
    require(contributorList[_beneficiary].tokensIssued == 0);
    require(contributorList[_beneficiary].allowance > 0);

    setCrowdsaleState();

    require(crowdsaleState == state.crowdsaleEnded);

    uint256 amount = contributorList[_beneficiary].allowance.mul(rate);
    require(token.mint(_beneficiary, amount));
    emit TokenAllocated(_beneficiary, amount);

    contributorList[_beneficiary].tokensIssued = contributorList[_beneficiary].tokensIssued.add(amount);
  }

  /**
   * Creates an new ERC20 Token contract for the DIP Token.
   * Overrides Crowdsale function
   * @return the created token
   */
  function createTokenContract() internal returns (MintableToken) {
    return new DipToken();
  }

  /**
   * Finalize sale and perform cleanup actions.
   */
  function finalization() internal {
    uint256 maxSupply = DipToken(token).MAXIMUM_SUPPLY();
    token.mint(wallet, maxSupply.sub(token.totalSupply())); // Alternativly, hardcode remaining token distribution.
    token.finishMinting();
    token.transferOwnership(owner);
  }

  /**
   * Owner can transfer back tokens which have been sent to this contract by mistake.
   * @param  _token address of token contract of the respective tokens
   * @param  _to where to send the tokens
   */
  function salvageTokens(ERC20Basic _token, address _to) onlyOwner external {
    _token.transfer(_to, _token.balanceOf(this));
  }
}

// File: contracts/rscconversion/RSCConversion.sol

/**
 * @title RSC Conversion Contract
 * @dev The Decentralized Insurance Platform Token.
 * @author Christoph Mussenbrock
 * @copyright 2017 Etherisc GmbH
 */

pragma solidity 0.4.24;






contract RSCConversion is Ownable {

  using SafeMath for *;

  ERC20 public DIP;
  DipTge public DIP_TGE;
  ERC20 public RSC;
  address public DIP_Pool;

  uint256 public constant CONVERSION_NUMINATOR = 10;
  uint256 public constant CONVERSION_DENOMINATOR = 32;
  uint256 public constant CONVERSION_DECIMAL_FACTOR = 10 ** (18 - 3);

  event Conversion(uint256 _rscAmount, uint256 _dipAmount, uint256 _bonus);

  constructor (
      address _dipToken,
      address _dipTge,
      address _rscToken,
      address _dipPool) public {
    require(_dipToken != address(0));
    require(_dipTge != address(0));
    require(_rscToken != address(0));
    require(_dipPool != address(0));

    DIP = ERC20(_dipToken);
    DIP_TGE = DipTge(_dipTge);
    RSC = ERC20(_rscToken);
    DIP_Pool = _dipPool;
  }

  /* fallback function converts all RSC */
  function () public {
    convert(RSC.balanceOf(msg.sender));
  }

  function convert(
    uint256 _rscAmount
  ) public {

    uint256 allowance;
    uint256 bonus;
    uint256 lockupPeriod;
    uint256 dipAmount;

    (allowance, /* contributionAmount */, /* tokensIssued */, /* airDrop */, bonus, lockupPeriod) =
      DIP_TGE.contributorList(msg.sender);

    require(allowance > 0);
    require(RSC.transferFrom(msg.sender, DIP_Pool, _rscAmount));
    dipAmount = _rscAmount.mul(CONVERSION_DECIMAL_FACTOR).mul(CONVERSION_NUMINATOR).div(CONVERSION_DENOMINATOR);

    if (bonus > 0) {
      require(lockupPeriod == 1);
      dipAmount = dipAmount.add(dipAmount.div(bonus));
    }
    require(DIP.transferFrom(DIP_Pool, msg.sender, dipAmount));
    emit Conversion(_rscAmount, dipAmount, bonus);
  }

  /**
   * Owner can transfer back tokens which have been sent to this contract by mistake.
   * @param  _token address of token contract of the respective tokens
   * @param  _to where to send the tokens
   */
  function salvageTokens(ERC20 _token, address _to) onlyOwner external {
    _token.transfer(_to, _token.balanceOf(this));
  }

}