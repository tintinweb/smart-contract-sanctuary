pragma solidity ^0.4.18;

contract SafeMathLib {
  
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
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
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner =  newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
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
 * A token that defines fractional units as decimals.
 */
contract FractionalERC20 is ERC20 {
  uint8 public decimals;
}



/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMathLib {
  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint256 amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint256)) allowed;

  function transfer(address _to, uint256 _value)
  public
  returns (bool) 
  { 
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = safeSub(balances[msg.sender],_value);
    balances[_to] = safeAdd(balances[_to],_value);
    Transfer(msg.sender, _to, _value);
    return true;
    
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint _allowance = allowed[_from][msg.sender];
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= _allowance);
    require(balances[_to] + _value > balances[_to]);

    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
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
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender],_addedValue);
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
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = safeSub(oldValue,_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner],_value);
    totalSupply = safeSub(totalSupply,_value);
    Burn(burner, _value);
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
  function isUpgradeAgent() public pure returns (bool) {
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
  function UpgradeableToken(address _upgradeMaster) public {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {
    UpgradeState state = getUpgradeState();
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));

    // Validate input value.
    require (value != 0);

    balances[msg.sender] = safeSub(balances[msg.sender],value);

    // Take tokens out from circulation
    totalSupply = safeSub(totalSupply,value);
    totalUpgraded = safeAdd(totalUpgraded,value);

    // Upgrade agent reissues the tokens
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {
    require(canUpgrade());

    require(agent != 0x0);
    // Only a master can designate the next agent
    require(msg.sender == upgradeMaster);
    // Upgrade has already begun for an agent
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    require(upgradeAgent.isUpgradeAgent());
    // Make sure that token supplies match in source and target
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function setUpgradeMaster(address master) public {
    require(master != 0x0);
    require(msg.sender == upgradeMaster);
    upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public view returns(bool) {
     return true;
  }

}

/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

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

    if(!released) {
        require(transferAgents[_sender]);
    }

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

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);
  event Mint(address indexed to, uint256 amount);

  /**
   * Create new tokens and allocate them to an address..
   *
   * Only callably by a crowdsale contract (mint agent).
   */
  function mint(address receiver, uint256 amount) onlyMintAgent canMint public returns(bool){
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    Mint(receiver, amount);
    Transfer(0, receiver, amount);
    return true;
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    require(mintAgents[msg.sender]);
    _;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}

/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, BurnableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint8 public decimals;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param _name Token name
   * @param _symbol Token symbol - should be all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
   */
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable)
    public
    UpgradeableToken(msg.sender) 
  {

    // Create any address, can be transferred
    // to team multisig via changeOwner(),
    // also remember to call setUpgradeMaster()
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

    // Create initially all balance on the team multisig
    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

    // No more new supply allowed after the token creation
    if(!_mintable) {
      mintingFinished = true;
      require(totalSupply != 0);
    }
  }

  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

  /**
   * Allow upgrade agent functionality kick in only if the crowdsale was success.
   */
  function canUpgrade() public view returns(bool) {
    return released && super.canUpgrade();
  }

  /**
   * Owner can update token information here
   */
  function setTokenInformation(string _name, string _symbol) onlyOwner public {
    name = _name;
    symbol = _symbol;
    UpdatedTokenInformation(name, symbol);
  }

}

/**
 * Finalize agent defines what happens at the end of succeseful crowdsale.
 *
 * - Allocate tokens for founders, bounties and community
 * - Make tokens transferable
 * - etc.
 */
contract FinalizeAgent {

  function isFinalizeAgent() public pure returns(bool) {
    return true;
  }

  /** Return true if we can run finalizeCrowdsale() properly.
   *
   * This is a safety check function that doesn&#39;t allow crowdsale to begin
   * unless the finalizer has been set up properly.
   */
  function isSane() public view returns (bool);

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() public ;

}

/**
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy {

  /** Interface declaration. */
  function isPricingStrategy() public pure returns (bool) {
    return true;
  }

  /** Self check if all references are correctly set.
   *
   * Checks that pricing strategy matches crowdsale parameters.
   */
  function isSane(address crowdsale) public view returns (bool) {
    return true;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction send in as wei
   * @param tokensSold - how much tokens have been sold this far
   * @param weiRaised - how much money has been raised this far
   * @param msgSender - who is the investor of this transaction
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint256 value, uint256 weiRaised, uint256 tokensSold, address msgSender, uint256 decimals) public constant returns (uint256 tokenAmount);
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
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
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
contract Allocatable is Ownable {

  /** List of agents that are allowed to allocate new tokens */
  mapping (address => bool) public allocateAgents;

  event AllocateAgentChanged(address addr, bool state  );

  /**
   * Owner can allow a crowdsale contract to allocate new tokens.
   */
  function setAllocateAgent(address addr, bool state) onlyOwner public {
    allocateAgents[addr] = state;
    AllocateAgentChanged(addr, state);
  }

  modifier onlyAllocateAgent() {
    // Only crowdsale contracts are allowed to allocate new tokens
    require(allocateAgents[msg.sender]);
    _;
  }
}

/**
 * Abstract base contract for token sales.
 *
 * Handle
 * - start and end dates
 * - accepting investments
 * - minimum funding goal and refund
 * - various statistics during the crowdfund
 * - different pricing strategies
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */
contract Crowdsale is Allocatable, Haltable, SafeMathLib {

  /* Max investment count when we are still allowed to change the multisig address */
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  /* The token we are selling */
  FractionalERC20 public token;

  /* Token Vesting Contract */
  address public tokenVestingAddress;

  /* How we are going to price our offering */
  PricingStrategy public pricingStrategy;

  /* Post-success callback */
  FinalizeAgent public finalizeAgent;

  /* tokens will be transfered from this address */
  address public multisigWallet;

  /* if the funding goal is not reached, investors may withdraw their funds */
  uint256 public minimumFundingGoal;

  /* the UNIX timestamp start date of the crowdsale */
  uint256 public startsAt;

  /* the UNIX timestamp end date of the crowdsale */
  uint256 public endsAt;

  /* the number of tokens already sold through this contract*/
  uint256 public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint256 public weiRaised = 0;

  /* How many distinct addresses have invested */
  uint256 public investorCount = 0;

  /* How much wei we have returned back to the contract after a failed crowdfund. */
  uint256 public loadedRefund = 0;

  /* How much wei we have given back to investors.*/
  uint256 public weiRefunded = 0;

  /* Has this crowdsale been finalized */
  bool public finalized;

  /* Do we need to have unique contributor id for each customer */
  bool public requireCustomerId;

  /**
    * Do we verify that contributor has been cleared on the server side (accredited investors only).
    * This method was first used in FirstBlood crowdsale to ensure all contributors have accepted terms on sale (on the web).
    */
  bool public requiredSignedAddress;

  /* Server side address that signed allowed contributors (Ethereum addresses) that can participate the crowdsale */
  address public signerAddress;

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public earlyParticipantWhitelist;

  /** This is for manul testing for the interaction from owner wallet. You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
  uint256 public ownerTestValue;

  uint256 public earlyPariticipantWeiPrice =82815734989648;

  uint256 public whitelistBonusPercentage = 15;
  uint256 public whitelistPrincipleLockPercentage = 50;
  uint256 public whitelistBonusLockPeriod = 7776000;
  uint256 public whitelistPrincipleLockPeriod = 7776000;

  /** State machine
   *
   * - Preparing: All contract initialization calls and variables have not been set yet
   * - Prefunding: We have not passed start time yet
   * - Funding: Active crowdsale
   * - Success: Minimum funding goal reached
   * - Failure: Minimum funding goal not reached before ending time
   * - Finalized: The finalized has been called and succesfully executed
   * - Refunding: Refunds are loaded on the contract for reclaim.
   */
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

  // A new investment was made
  event Invested(address investor, uint256 weiAmount, uint256 tokenAmount, uint128 customerId);

  // Refund was processed for a contributor
  event Refund(address investor, uint256 weiAmount);

  // The rules were changed what kind of investments we accept
  event InvestmentPolicyChanged(bool requireCustId, bool requiredSignedAddr, address signerAddr);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint256 endAt);

  // Crowdsale start time has been changed
  event StartAtChanged(uint256 endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, 
  uint256 _start, uint256 _end, uint256 _minimumFundingGoal, address _tokenVestingAddress) public 
  {

    owner = msg.sender;

    token = FractionalERC20(_token);

    tokenVestingAddress = _tokenVestingAddress;

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    require(multisigWallet != 0);

    require(_start != 0);

    startsAt = _start;

    require(_end != 0);

    endsAt = _end;

    // Don&#39;t mess the dates
    require(startsAt < endsAt);

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;

  }

  /**
   * Don&#39;t expect to just send in money and get tokens.
   */
  function() payable public {
    invest(msg.sender);
  }

  /** Function to set default vesting schedule parameters. */
    function setDefaultWhitelistVestingParameters(uint256 _bonusPercentage, uint256 _principleLockPercentage, uint256 _bonusLockPeriod, uint256 _principleLockPeriod, uint256 _earlyPariticipantWeiPrice) onlyAllocateAgent public {

        whitelistBonusPercentage = _bonusPercentage;
        whitelistPrincipleLockPercentage = _principleLockPercentage;
        whitelistBonusLockPeriod = _bonusLockPeriod;
        whitelistPrincipleLockPeriod = _principleLockPeriod;
        earlyPariticipantWeiPrice = _earlyPariticipantWeiPrice;
    }

  /**
   * Make an investment.
   *
   * Crowdsale must be running for one to invest.
   * We must have not pressed the emergency brake.
   *
   * @param receiver The Ethereum address who receives the tokens
   * @param customerId (optional) UUID v4 to track the successful payments on the server side
   *
   */
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

    uint256 tokenAmount;
    uint256 weiAmount = msg.value;
    // Determine if it&#39;s a good time to accept investment from this participant
    if (getState() == State.PreFunding) {
        // Are we whitelisted for early deposit
        require(earlyParticipantWhitelist[receiver]);
        require(weiAmount >= safeMul(15, uint(10 ** 18)));
        require(weiAmount <= safeMul(50, uint(10 ** 18)));
        tokenAmount = safeDiv(safeMul(weiAmount, uint(10) ** token.decimals()), earlyPariticipantWeiPrice);
        
        if (investedAmountOf[receiver] == 0) {
          // A new investor
          investorCount++;
        }

        // Update investor
        investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
        tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

        // Update totals
        weiRaised = safeAdd(weiRaised,weiAmount);
        tokensSold = safeAdd(tokensSold,tokenAmount);

        // Check that we did not bust the cap
        require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

        if (safeAdd(whitelistPrincipleLockPercentage,whitelistBonusPercentage) > 0) {

            uint256 principleAmount = safeDiv(safeMul(tokenAmount, 100), safeAdd(whitelistBonusPercentage, 100));
            uint256 bonusLockAmount = safeDiv(safeMul(whitelistBonusPercentage, principleAmount), 100);
            uint256 principleLockAmount = safeDiv(safeMul(whitelistPrincipleLockPercentage, principleAmount), 100);

            uint256 totalLockAmount = safeAdd(principleLockAmount, bonusLockAmount);
            TokenVesting tokenVesting = TokenVesting(tokenVestingAddress);
            
            // to prevent minting of tokens which will be useless as vesting amount cannot be updated
            require(!tokenVesting.isVestingSet(receiver));
            require(totalLockAmount <= tokenAmount);
            assignTokens(tokenVestingAddress,totalLockAmount);
            
            // set vesting with default schedule
            tokenVesting.setVesting(receiver, principleLockAmount, whitelistPrincipleLockPeriod, bonusLockAmount, whitelistBonusLockPeriod); 
        }

        // assign remaining tokens to contributor
        if (tokenAmount - totalLockAmount > 0) {
            assignTokens(receiver, tokenAmount - totalLockAmount);
        }

        // Pocket the money
        require(multisigWallet.send(weiAmount));

        // Tell us invest was success
        Invested(receiver, weiAmount, tokenAmount, customerId);       

    
    } else if(getState() == State.Funding) {
        // Retail participants can only come in when the crowdsale is running
        tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());
        require(tokenAmount != 0);


        if(investedAmountOf[receiver] == 0) {
          // A new investor
          investorCount++;
        }

        // Update investor
        investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
        tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

        // Update totals
        weiRaised = safeAdd(weiRaised,weiAmount);
        tokensSold = safeAdd(tokensSold,tokenAmount);

        // Check that we did not bust the cap
        require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

        assignTokens(receiver, tokenAmount);

        // Pocket the money
        require(multisigWallet.send(weiAmount));

        // Tell us invest was success
        Invested(receiver, weiAmount, tokenAmount, customerId);

    } else {
      // Unwanted state
      require(false);
    }
  }

  /**
   * allocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * Investor count is not handled; it is assumed this goes for multiple investors
   * and the token distribution happens outside the smart contract flow.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param weiPrice Price of a single full token in wei
   *
   */
  function preallocate(address receiver, uint256 tokenAmount, uint256 weiPrice, uint256 principleLockAmount, uint256 principleLockPeriod, uint256 bonusLockAmount, uint256 bonusLockPeriod) public onlyAllocateAgent {


    uint256 weiAmount = (weiPrice * tokenAmount)/10**uint256(token.decimals()); // This can be also 0, we give out tokens for free
    uint256 totalLockAmount = 0;
    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);

    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    // cannot lock more than total tokens
    totalLockAmount = safeAdd(principleLockAmount, bonusLockAmount);
    require(totalLockAmount <= tokenAmount);

    // assign locked token to Vesting contract
    if (totalLockAmount > 0) {

      TokenVesting tokenVesting = TokenVesting(tokenVestingAddress);
      
      // to prevent minting of tokens which will be useless as vesting amount cannot be updated
      require(!tokenVesting.isVestingSet(receiver));
      assignTokens(tokenVestingAddress,totalLockAmount);
      
      // set vesting with default schedule
      tokenVesting.setVesting(receiver, principleLockAmount, principleLockPeriod, bonusLockAmount, bonusLockPeriod); 
    }

    // assign remaining tokens to contributor
    if (tokenAmount - totalLockAmount > 0) {
      assignTokens(receiver, tokenAmount - totalLockAmount);
    }

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

  /**
   * Track who is the customer making the payment so we can send thank you email.
   */
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    require(!requiredSignedAddress);
    require(customerId != 0);
    investInternal(addr, customerId);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function invest(address addr) public payable {
    require(!requireCustomerId);
    
    require(!requiredSignedAddress);
    investInternal(addr, 0);
  }

  /**
   * Invest to tokens, recognize the payer and clear his address.
   *
   */
  
  // function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
  //   investWithSignedAddress(msg.sender, customerId, v, r, s);
  // }

  /**
   * Invest to tokens, recognize the payer.
   *
   */
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    invest(msg.sender);
  }

  /**
   * Finalize a succcesful crowdsale.
   *
   * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

    // Already finalized
    require(!finalized);

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

  /**
   * Allow to (re)set finalize agent.
   *
   * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
   */
  function setFinalizeAgent(FinalizeAgent addr) public onlyOwner {
    finalizeAgent = addr;

    // Don&#39;t allow setting bad agent
    require(finalizeAgent.isFinalizeAgent());
  }

  /**
   * Set policy do we need to have server-side customer ids for the investments.
   *
   */
  function setRequireCustomerId(bool value) public onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

  /**
   * Allow addresses to do early participation.
   *
   * TODO: Fix spelling error in the name
   */
  function setEarlyParicipantWhitelist(address addr, bool status) public onlyAllocateAgent {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

  function setWhiteList(address[] _participants) public onlyAllocateAgent {
      
      require(_participants.length > 0);
      uint256 participants = _participants.length;

      for (uint256 j=0; j<participants; j++) {
      require(_participants[j] != 0);
      earlyParticipantWhitelist[_participants[j]] = true;
      Whitelisted(_participants[j], true);
    }

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
  function setEndsAt(uint time) public onlyOwner {

    require(now <= time);

    endsAt = time;
    EndsAtChanged(endsAt);
  }

  /**
   * Allow crowdsale owner to begin early or extend the crowdsale.
   *
   * This is useful e.g. for a manual soft cap implementation:
   * - after X amount is reached determine manual closing
   *
   * This may put the crowdsale to an invalid state,
   * but we trust owners know what they are doing.
   *
   */
  function setStartAt(uint time) public onlyOwner {

    startsAt = time;
    StartAtChanged(endsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   *
   * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
   */
  function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
    pricingStrategy = _pricingStrategy;

    // Don&#39;t allow setting bad agent
    require(pricingStrategy.isPricingStrategy());
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  function setMultisig(address addr) public onlyOwner {

    // Change
    require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);

    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value != 0);
    loadedRefund = safeAdd(loadedRefund,msg.value);
  }

  /**
   * Investors can claim refund.
   */
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    require(weiValue != 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded,weiValue);
    Refund(msg.sender, weiValue);
    require(msg.sender.send(weiValue));
  }

  /**
   * @return true if the crowdsale has raised enough money to be a succes
   */
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

  /**
   * Crowdfund state machine management.
   *
   * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
   */
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

  /** This is for manual testing of multisig wallet interaction */
  function setOwnerTestValue(uint val) public onlyOwner {
    ownerTestValue = val;
  }

  /** Interface marker. */
  function isCrowdsale() public pure returns (bool) {
    return true;
  }

  //
  // Modifiers
  //

  /** Modified allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    require(getState() == state);
    _;
  }


  //
  // Abstract functions
  //

  /**
   * Check if the current invested breaks our cap rules.
   *
   *
   * The child contract must define their own cap setting rules.
   * We allow a lot of flexibility through different capping strategies (ETH, token count)
   * Called from invest().
   *
   * @param weiAmount The amount of wei the investor tries to invest in the current transaction
   * @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
   * @param weiRaisedTotal What would be our total raised balance after this transaction
   * @param tokensSoldTotal What would be our total sold tokens count after this transaction
   *
   * @return true if taking this investment would break our cap rules
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) public constant returns (bool limitBroken);
  /**
   * Check if the current crowdsale is full and we can no longer sell any tokens.
   */
  function isCrowdsaleFull() public constant returns (bool);

  /**
   * Create new tokens or transfer issued tokens to the investor depending on the cap model.
   */
  function assignTokens(address receiver, uint tokenAmount) private;
}

/**
 * At the end of the successful crowdsale allocate % bonus of tokens to the team.
 *
 * Unlock tokens.
 *
 * BonusAllocationFinal must be set as the minting agent for the MintableToken.
 *
 */
contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib {

  CrowdsaleToken public token;
  Crowdsale public crowdsale;
  uint256 public allocatedTokens;
  uint256 tokenCap;
  address walletAddress;


  function BonusFinalizeAgent(CrowdsaleToken _token, Crowdsale _crowdsale, uint256 _tokenCap, address _walletAddress) public {
    token = _token;
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    require(address(crowdsale) != 0);

    tokenCap = _tokenCap;
    walletAddress = _walletAddress;
  }

  /* Can we run finalize properly */
  function isSane() public view returns (bool) {
    return (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
  }

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() public {

    // if finalized is not being called from the crowdsale 
    // contract then throw
    require (msg.sender == address(crowdsale));

    // get the total sold tokens count.
    uint256 tokenSupply = token.totalSupply();

    allocatedTokens = safeSub(tokenCap,tokenSupply);
    
    if ( allocatedTokens > 0) {
      token.mint(walletAddress, allocatedTokens);
    }

    token.releaseTokenTransfer();
  }

}

/**
 * ICO crowdsale contract that is capped by amout of ETH.
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
contract MintedEthCappedCrowdsale is Crowdsale {

  /* Maximum amount of wei this crowdsale can raise. */
  uint public weiCap;

  function MintedEthCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
    address _multisigWallet, uint256 _start, uint256 _end, uint256 _minimumFundingGoal, uint256 _weiCap, address _tokenVestingAddress) 
    Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal,_tokenVestingAddress) public
    { 
      weiCap = _weiCap;
    }

  /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint256 weiAmount, uint256 tokenAmount, uint256 weiRaisedTotal, uint256 tokensSoldTotal) public constant returns (bool limitBroken) {
    return weiRaisedTotal > weiCap;
  }

  function isCrowdsaleFull() public constant returns (bool) {
    return weiRaised >= weiCap;
  }

  /**
   * Dynamically create tokens and assign them to the investor.
   */
  function assignTokens(address receiver, uint256 tokenAmount) private {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }
}


/// @dev Tranche based pricing with special support for pre-ico deals.
///      Implementing "first price" tranches, meaning, that if byers order is
///      covering more than one tranche, the price of the lowest tranche will apply
///      to the whole order.
contract EthTranchePricing is PricingStrategy, Ownable, SafeMathLib {

  uint public constant MAX_TRANCHES = 10;
 
 
  // This contains all pre-ICO addresses, and their prices (weis per token)
  mapping (address => uint256) public preicoAddresses;

  /**
  * Define pricing schedule using tranches.
  */

  struct Tranche {
      // Amount in weis when this tranche becomes active
      uint amount;
      // How many tokens per wei you will get while this tranche is active
      uint price;
  }

  // Store tranches in a fixed array, so that it can be seen in a blockchain explorer
  // Tranche 0 is always (0, 0)
  // (TODO: change this when we confirm dynamic arrays are explorable)
  Tranche[10] public tranches;

  // How many active tranches we have
  uint public trancheCount;

  /// @dev Contruction, creating a list of tranches
  /// @param _tranches uint[] tranches Pairs of (start amount, price)
  function EthTranchePricing(uint[] _tranches) public {

    // Need to have tuples, length check
    require(!(_tranches.length % 2 == 1 || _tranches.length >= MAX_TRANCHES*2));
    trancheCount = _tranches.length / 2;
    uint256 highestAmount = 0;
    for(uint256 i=0; i<_tranches.length/2; i++) {
      tranches[i].amount = _tranches[i*2];
      tranches[i].price = _tranches[i*2+1];
      // No invalid steps
      require(!((highestAmount != 0) && (tranches[i].amount <= highestAmount)));
      highestAmount = tranches[i].amount;
    }

    // We need to start from zero, otherwise we blow up our deployment
    require(tranches[0].amount == 0);

    // Last tranche price must be zero, terminating the crowdale
    require(tranches[trancheCount-1].price == 0);
  }

  /// @dev This is invoked once for every pre-ICO address, set pricePerToken
  ///      to 0 to disable
  /// @param preicoAddress PresaleFundCollector address
  /// @param pricePerToken How many weis one token cost for pre-ico investors
  function setPreicoAddress(address preicoAddress, uint pricePerToken)
    public
    onlyOwner
  {
    preicoAddresses[preicoAddress] = pricePerToken;
  }

  /// @dev Iterate through tranches. You reach end of tranches when price = 0
  /// @return tuple (time, price)
  function getTranche(uint256 n) public constant returns (uint, uint) {
    return (tranches[n].amount, tranches[n].price);
  }

  function getFirstTranche() private constant returns (Tranche) {
    return tranches[0];
  }

  function getLastTranche() private constant returns (Tranche) {
    return tranches[trancheCount-1];
  }

  function getPricingStartsAt() public constant returns (uint) {
    return getFirstTranche().amount;
  }

  function getPricingEndsAt() public constant returns (uint) {
    return getLastTranche().amount;
  }

  function isSane(address _crowdsale) public view returns(bool) {
    // Our tranches are not bound by time, so we can&#39;t really check are we sane
    // so we presume we are ;)
    // In the future we could save and track raised tokens, and compare it to
    // the Crowdsale contract.
    return true;
  }

  /// @dev Get the current tranche or bail out if we are not in the tranche periods.
  /// @param weiRaised total amount of weis raised, for calculating the current tranche
  /// @return {[type]} [description]
  function getCurrentTranche(uint256 weiRaised) private constant returns (Tranche) {
    uint i;
    for(i=0; i < tranches.length; i++) {
      if(weiRaised < tranches[i].amount) {
        return tranches[i-1];
      }
    }
  }

  /// @dev Get the current price.
  /// @param weiRaised total amount of weis raised, for calculating the current tranche
  /// @return The current price or 0 if we are outside trache ranges
  function getCurrentPrice(uint256 weiRaised) public constant returns (uint256 result) {
    return getCurrentTranche(weiRaised).price;
  }

  /// @dev Calculate the current price for buy in amount.
  function calculatePrice(uint256 value, uint256 weiRaised, uint256 tokensSold, address msgSender, uint256 decimals) public constant returns (uint256) {

    uint256 multiplier = 10 ** decimals;

    // This investor is coming through pre-ico
    if(preicoAddresses[msgSender] > 0) {
      return safeMul(value, multiplier) / preicoAddresses[msgSender];
    }

    uint256 price = getCurrentPrice(weiRaised);
    
    return safeMul(value, multiplier) / price;
  }

  function() payable public {
    revert(); // No money on this contract
  }

}

/**
 * Contract to enforce Token Vesting
 */
contract TokenVesting is Allocatable, SafeMathLib {

    address public TokenAddress;

    /** keep track of total tokens yet to be released, 
     * this should be less than or equal to tokens held by this contract. 
     */
    uint256 public totalUnreleasedTokens;


    struct VestingSchedule {
        uint256 startAt;
        uint256 principleLockAmount;
        uint256 principleLockPeriod;
        uint256 bonusLockAmount;
        uint256 bonusLockPeriod;
        uint256 amountReleased;
        bool isPrincipleReleased;
        bool isBonusReleased;
    }

    mapping (address => VestingSchedule) public vestingMap;

    event VestedTokensReleased(address _adr, uint256 _amount);


    function TokenVesting(address _TokenAddress) public {
        TokenAddress = _TokenAddress;
    }



    /** Function to set/update vesting schedule. PS - Amount cannot be changed once set */
    function setVesting(address _adr, uint256 _principleLockAmount, uint256 _principleLockPeriod, uint256 _bonusLockAmount, uint256 _bonuslockPeriod) public onlyAllocateAgent {

        VestingSchedule storage vestingSchedule = vestingMap[_adr];

        // data validation
        require(safeAdd(_principleLockAmount, _bonusLockAmount) > 0);

        //startAt is set current time as start time.

        vestingSchedule.startAt = block.timestamp;
        vestingSchedule.bonusLockPeriod = safeAdd(block.timestamp,_bonuslockPeriod);
        vestingSchedule.principleLockPeriod = safeAdd(block.timestamp,_principleLockPeriod);

        // check if enough tokens are held by this contract
        ERC20 token = ERC20(TokenAddress);
        uint256 _totalAmount = safeAdd(_principleLockAmount, _bonusLockAmount);
        require(token.balanceOf(this) >= safeAdd(totalUnreleasedTokens, _totalAmount));
        vestingSchedule.principleLockAmount = _principleLockAmount;
        vestingSchedule.bonusLockAmount = _bonusLockAmount;
        vestingSchedule.isPrincipleReleased = false;
        vestingSchedule.isBonusReleased = false;
        totalUnreleasedTokens = safeAdd(totalUnreleasedTokens, _totalAmount);
        vestingSchedule.amountReleased = 0;
    }

    function isVestingSet(address adr) public constant returns (bool isSet) {
        return vestingMap[adr].principleLockAmount != 0 || vestingMap[adr].bonusLockAmount != 0;
    }


    /** Release tokens as per vesting schedule, called by contributor  */
    function releaseMyVestedTokens() public {
        releaseVestedTokens(msg.sender);
    }

    /** Release tokens as per vesting schedule, called by anyone  */
    function releaseVestedTokens(address _adr) public {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
        uint256 _totalTokens = safeAdd(vestingSchedule.principleLockAmount, vestingSchedule.bonusLockAmount);
        // check if all tokens are not vested
        require(safeSub(_totalTokens, vestingSchedule.amountReleased) > 0);
        
        // calculate total vested tokens till now        
        uint256 amountToRelease = 0;

        if (block.timestamp >= vestingSchedule.principleLockPeriod && !vestingSchedule.isPrincipleReleased) {
            amountToRelease = safeAdd(amountToRelease,vestingSchedule.principleLockAmount);
            vestingSchedule.amountReleased = safeAdd(vestingSchedule.amountReleased, amountToRelease);
            vestingSchedule.isPrincipleReleased = true;
        }
        if (block.timestamp >= vestingSchedule.bonusLockPeriod && !vestingSchedule.isBonusReleased) {
            amountToRelease = safeAdd(amountToRelease,vestingSchedule.bonusLockAmount);
            vestingSchedule.amountReleased = safeAdd(vestingSchedule.amountReleased, amountToRelease);
            vestingSchedule.isBonusReleased = true;
        }

        // transfer vested tokens
        require(amountToRelease > 0);
        ERC20 token = ERC20(TokenAddress);
        token.transfer(_adr, amountToRelease);
        // decrement overall unreleased token count
        totalUnreleasedTokens = safeSub(totalUnreleasedTokens, amountToRelease);
        VestedTokensReleased(_adr, amountToRelease);
    }

}