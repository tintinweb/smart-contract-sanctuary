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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is Ownable {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function transfer(address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is StandardToken {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is ReleasableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
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
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {

  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint256 public totalUpgraded;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
   * - WaitingForAgent: Token allows upgrade, but we don&#39;t have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        // Called in a bad state
        throw;
      }

      // Validate input value.
      if (value == 0) throw;

      balances[msg.sender] = balances[msg.sender].sub(value);

      // Take tokens out from circulation
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

      // Upgrade agent reissues the tokens
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {

      if (agent == 0x0) throw;
      // Only a master can designate the next agent
      if (msg.sender != upgradeMaster) throw;
      // Upgrade has already begun for an agent
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

      // Bad interface
      if(!upgradeAgent.isUpgradeAgent()) throw;
      // Make sure that token supplies match in source and target
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }


}

/**
 * Matryx Ethereum token.
 */
contract MatryxToken is MintableToken, UpgradeableToken{

  string public name = "MatryxToken";
  string public symbol = "MTX";
  uint public decimals = 18;

  // supply upgrade owner as the contract creation account
  function MatryxToken() UpgradeableToken(msg.sender) {

  }
}

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    //if (halted) throw;
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    //if (!halted) throw;
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


/**
 * @title Crowdsale
 * Matryx crowdsale contract based on Open Zeppelin and TokenMarket
 * This crowdsale is modified to have a presale time period
 * A whitelist function is added to allow discounts. There are
 * three tiers of tokens purchased per wei based on msg value.
 * A finalization function can be called by the owner to issue 
 * Matryx reserves, close minting, and transfer token ownership 
 * away from the crowdsale and back to the owner.
 */
contract Crowdsale is Ownable, Haltable {
  using SafeMath for uint256;

  // The token being sold
  MatryxToken public token;

  // presale, start and end timestamps where investments are allowed
  uint256 public presaleStartTime;
  uint256 public startTime;
  uint256 public endTime;

  // How many distinct addresses have purchased
  uint public purchaserCount = 0;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per ether
  uint256 public baseRate = 1164;

  // how many token units a buyer gets per ether with tier 2 10% discount
  uint256 public tierTwoRate = 1294;

  // how many token units a buyer gets per ether with tier 3 15% discount
  uint256 public tierThreeRate = 1371;

  // how many token units a buyer gets per ether with a whitelisted 20% discount
  uint256 public whitelistRate = 1456;

  // the minimimum presale purchase amount in ether
  uint256 public tierOnePurchase = 75 * 10**18;

  // the second tier discount presale purchase amount in ether
  uint256 public tierTwoPurchase = 150 * 10**18;

  // the second tier discount presale purchase amount in ether
  uint256 public tierThreePurchase = 300 * 10**18;

  // amount of raised money in wei
  uint256 public weiRaised;

  // Total amount to be sold in ether
  uint256 public cap = 161803 * 10**18;

  // Total amount to be sold in the presale in. cap/2
  uint256 public presaleCap = 809015 * 10**17;

  // Is the contract finalized
  bool public isFinalized = false;

  // How much ETH each address has invested to this crowdsale
  mapping (address => uint256) public purchasedAmountOf;

  // How many tokens this crowdsale has credited for each investor address
  mapping (address => uint256) public tokenAmountOf;

  // Addresses of whitelisted presale investors.
  mapping (address => bool) public whitelist;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint newEndsAt);

  event Finalized();

  function Crowdsale(uint256 _presaleStartTime, uint256 _startTime, uint256 _endTime, address _wallet, address _token) {
    require(_startTime >= now);
    require(_presaleStartTime >= now && _presaleStartTime < _startTime);
    require(_endTime >= _startTime);
    require(_wallet != 0x0);
    require(_token != 0x0);

    token = MatryxToken(_token);
    wallet = _wallet;
    presaleStartTime = _presaleStartTime;
    startTime = _startTime;
    endTime = _endTime;
  }

  // fallback function can&#39;t accept ether
  function () {
    throw;
  }

  // default buy function
  function buy() public payable {
    buyTokens(msg.sender);
  }
  
  // low level token purchase function
  // owner may halt payments here
  function buyTokens(address beneficiary) stopInEmergency payable {
    require(beneficiary != 0x0);
    require(msg.value != 0);
    
    if(isPresale()) {
      require(validPrePurchase());
      buyPresale(beneficiary);
    } else {
      require(validPurchase());
      buySale(beneficiary);
    }
  }

  function buyPresale(address beneficiary) internal {
    uint256 weiAmount = msg.value;
    uint256 tokens = 0;
    
    // calculate discount
    if(whitelist[msg.sender]) {
      tokens = weiAmount.mul(whitelistRate);
    } else if(weiAmount < tierTwoPurchase) {
      // Not whitelisted so they must have sent over 75 ether 
      tokens = weiAmount.mul(baseRate);
    } else if(weiAmount < tierThreePurchase) {
      // Over 150 ether was sent
      tokens = weiAmount.mul(tierTwoRate);
    } else {
      // Over 300 ether was sent
      tokens = weiAmount.mul(tierThreeRate);
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // Update purchaser
    if(purchasedAmountOf[msg.sender] == 0) purchaserCount++;
    purchasedAmountOf[msg.sender] = purchasedAmountOf[msg.sender].add(msg.value);
    tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);

    token.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function buySale(address beneficiary) internal {
    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(baseRate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // Update purchaser
    if(purchasedAmountOf[msg.sender] == 0) purchaserCount++;
    purchasedAmountOf[msg.sender] = purchasedAmountOf[msg.sender].add(msg.value);
    tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);

    token.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();
    
    isFinalized = true;
  }

  /**
   * @dev Finalization logic. We take the expected sale cap of 314159265
   * ether and find the difference from the actual minted tokens.
   * The remaining balance and 40% of total supply are minted 
   * to the Matryx team multisig wallet.
   */
  function finalization() internal {
    // calculate token amount to be created
    // expected tokens sold
    uint256 piTokens = 314159265*10**18;
    // get the difference of sold and expected
    uint256 tokens = piTokens.sub(token.totalSupply());
    // issue tokens to the multisig wallet
    token.mint(wallet, tokens);
    token.finishMinting();
    token.transferOwnership(msg.sender);
    token.releaseTokenTransfer();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // Allow the owner to update the presale whitelist
  function updateWhitelist(address _purchaser, bool _listed) onlyOwner {
    whitelist[_purchaser] = _listed;
    Whitelisted(_purchaser, _listed);
  }

  /**
   * Allow crowdsale owner to close early or extend the crowdsale.
   *
   * This is useful e.g. for a manual soft cap implementation:
   * - after X amount is reached determine manual closing
   *
   * This may put the crowdsale to an invalid state,
   * but we trust owners know what they are doing.
   *
   */
  function setEndsAt(uint time) onlyOwner {
    require(now < time);

    endTime = time;
    EndsAtChanged(endTime);
  }


  // @return true if the presale transaction can buy tokens
  function validPrePurchase() internal constant returns (bool) {
    // this asserts that the value is at least the lowest tier 
    // or the address has been whitelisted to purchase with less
    bool canPrePurchase = tierOnePurchase <= msg.value || whitelist[msg.sender];
    bool withinCap = weiRaised.add(msg.value) <= presaleCap;
    return canPrePurchase && withinCap;
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinPeriod && withinCap;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return now > endTime || capReached;
  }

  // @return true if within presale time
  function isPresale() public constant returns (bool) {
    bool withinPresale = now >= presaleStartTime && now < startTime;
    return withinPresale;
  }

}