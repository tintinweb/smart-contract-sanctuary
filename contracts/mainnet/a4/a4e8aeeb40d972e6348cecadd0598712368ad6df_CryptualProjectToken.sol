pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


/**
 * @title CryptualProjectToken
 * @dev Official ERC20 token contract for the Cryptual Project.
 * This contract includes both a presale and a crowdsale.
 */
contract CryptualProjectToken is StandardToken, Ownable {
  using SafeMath for uint256;

  // ERC20 optional details
  string public constant name = "Cryptual Project Token"; // solium-disable-line uppercase
  string public constant symbol = "CPT"; // solium-disable-line uppercase
  uint8 public constant decimals = 0; // solium-disable-line uppercase

  // Token constants, variables
  uint256 public constant INITIAL_SUPPLY = 283000000;
  address public wallet;

  // Private presale constants
  uint256 public constant PRESALE_OPENING_TIME = 1531998000; // Thu, 19 Jul 2018 11:00:00 +0000
  uint256 public constant PRESALE_CLOSING_TIME = 1532563200; // Thu, 26 Jul 2018 00:00:00 +0000
  uint256 public constant PRESALE_RATE = 150000;
  uint256 public constant PRESALE_WEI_CAP = 500 ether;
  uint256 public constant PRESALE_WEI_GOAL = 50 ether;
  
  // Public crowdsale constants
  uint256 public constant CROWDSALE_OPENING_TIME = 1532602800; // Thu, 26 Jul 2018 11:00:00 +0000
  uint256 public constant CROWDSALE_CLOSING_TIME = 1535328000; // Mon, 27 Aug 2018 00:00:00 +0000
  uint256 public constant CROWDSALE_WEI_CAP = 5000 ether;

  // Combined wei goal for both token sale stages
  uint256 public constant COMBINED_WEI_GOAL = 750 ether;
  
  // Public crowdsale parameters
  uint256[] public crowdsaleWeiAvailableLevels = [1000 ether, 1500 ether, 2000 ether];
  uint256[] public crowdsaleRates = [135000, 120000, 100000];
  uint256[] public crowdsaleMinElapsedTimeLevels = [0, 12 * 3600, 18 * 3600, 21 * 3600, 22 * 3600];
  uint256[] public crowdsaleUserCaps = [1 ether, 2 ether, 4 ether, 8 ether, CROWDSALE_WEI_CAP];
  mapping(address => uint256) public crowdsaleContributions;

  // Amount of wei raised for each token sale stage
  uint256 public presaleWeiRaised;
  uint256 public crowdsaleWeiRaised;

  /**
   * @dev Constructor that sends msg.sender the initial token supply
   */
  constructor(
    address _wallet
  ) public {
    require(_wallet != address(0));
    wallet = _wallet;

    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @dev fallback token purchase function
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev token purchase function
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(weiAmount != 0);
    bool isPresale = block.timestamp >= PRESALE_OPENING_TIME && block.timestamp <= PRESALE_CLOSING_TIME;
    bool isCrowdsale = block.timestamp >= CROWDSALE_OPENING_TIME && block.timestamp <= CROWDSALE_CLOSING_TIME;
    require(isPresale || isCrowdsale);
    uint256 tokens;

    if (isCrowdsale) {
      require(crowdsaleWeiRaised.add(weiAmount) <= CROWDSALE_WEI_CAP);
      require(crowdsaleContributions[_beneficiary].add(weiAmount) <= getCrowdsaleUserCap());
      
      // calculate token amount to be created
      tokens = _getCrowdsaleTokenAmount(weiAmount);
      require(tokens != 0);

      // update state
      crowdsaleWeiRaised = crowdsaleWeiRaised.add(weiAmount);
    } else if (isPresale) {
      require(presaleWeiRaised.add(weiAmount) <= PRESALE_WEI_CAP);
      require(whitelist[_beneficiary]);
      
      // calculate token amount to be created
      tokens = weiAmount.mul(PRESALE_RATE).div(1 ether);
      require(tokens != 0);

      // update state
      presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    }

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    if (isCrowdsale) crowdsaleContributions[_beneficiary] = crowdsaleContributions[_beneficiary].add(weiAmount);
    deposited[_beneficiary] = deposited[_beneficiary].add(msg.value);
  }

  /**
   * @dev Returns the current contribution cap per user in wei.
   * Note that this cap in changes with time.
   * @return The maximum wei a user may contribute in total
   */
  function getCrowdsaleUserCap() public view returns (uint256) {
    require(block.timestamp >= CROWDSALE_OPENING_TIME && block.timestamp <= CROWDSALE_CLOSING_TIME);
    // solium-disable-next-line security/no-block-members
    uint256 elapsedTime = block.timestamp.sub(CROWDSALE_OPENING_TIME);
    uint256 currentMinElapsedTime = 0;
    uint256 currentCap = 0;

    for (uint i = 0; i < crowdsaleUserCaps.length; i++) {
      if (elapsedTime < crowdsaleMinElapsedTimeLevels[i]) continue;
      if (crowdsaleMinElapsedTimeLevels[i] < currentMinElapsedTime) continue;
      currentCap = crowdsaleUserCaps[i];
    }

    return currentCap;
  }

  /**
   * @dev Function to compute output tokens from input wei
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
  function _getCrowdsaleTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 uncountedWeiRaised = crowdsaleWeiRaised;
    uint256 uncountedWeiAmount = _weiAmount;
    uint256 tokenAmount = 0;

    for (uint i = 0; i < crowdsaleWeiAvailableLevels.length; i++) {
      uint256 weiAvailable = crowdsaleWeiAvailableLevels[i];
      uint256 rate = crowdsaleRates[i];
      
      if (uncountedWeiRaised < weiAvailable) {
        if (uncountedWeiRaised > 0) {
          weiAvailable = weiAvailable.sub(uncountedWeiRaised);
          uncountedWeiRaised = 0;
        }

        if (uncountedWeiAmount <= weiAvailable) {
          tokenAmount = tokenAmount.add(uncountedWeiAmount.mul(rate));
          break;
        } else {
          uncountedWeiAmount = uncountedWeiAmount.sub(weiAvailable);
          tokenAmount = tokenAmount.add(weiAvailable.mul(rate));
        }
      } else {
        uncountedWeiRaised = uncountedWeiRaised.sub(weiAvailable);
      }
    }

    return tokenAmount.div(1 ether);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    totalSupply_ = totalSupply_.add(_tokenAmount);
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
    emit Transfer(0x0, _beneficiary, _tokenAmount);
  }
  
  // Private presale buyer whitelist
  mapping(address => bool) public whitelist;

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToPresaleWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToPresaleWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromPresaleWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  // Crowdsale finalization/refunding variables
  bool public isCrowdsaleFinalized = false;
  mapping (address => uint256) public deposited;

  // Crowdsale finalization/refunding events
  event CrowdsaleFinalized();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization (forwarding/refunding)
   * work. Calls the contract&#39;s finalization function.
   */
  function finalizeCrowdsale() external {
    require(!isCrowdsaleFinalized);
    require(block.timestamp > CROWDSALE_CLOSING_TIME || (block.timestamp > PRESALE_CLOSING_TIME && presaleWeiRaised < PRESALE_WEI_GOAL));

    if (combinedGoalReached()) {
      wallet.transfer(address(this).balance);
    } else {
      emit RefundsEnabled();
    }

    emit CrowdsaleFinalized();
    isCrowdsaleFinalized = true;
  }

  /**
   * @dev Investors can claim refunds here if presale/crowdsale is unsuccessful
   */
  function claimRefund() external {
    require(isCrowdsaleFinalized);
    require(!combinedGoalReached());
    require(deposited[msg.sender] > 0);

    uint256 depositedValue = deposited[msg.sender];
    deposited[msg.sender] = 0;
    msg.sender.transfer(depositedValue);
    emit Refunded(msg.sender, depositedValue);
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function combinedGoalReached() public view returns (bool) {
    return presaleWeiRaised.add(crowdsaleWeiRaised) >= COMBINED_WEI_GOAL;
  }

}