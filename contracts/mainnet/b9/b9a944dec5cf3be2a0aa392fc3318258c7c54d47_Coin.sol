pragma solidity ^0.4.4;

/**
 * @title ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20 {

  uint public totalSupply;
  uint public decimals;

  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

}


/**
 * @title Ownable
 * The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  /* Current Owner */
  address public owner;

  /* New owner which can be set in future */
  address public newOwner;

  /* event to indicate finally ownership has been succesfully transferred and accepted */
  event OwnershipTransferred(address indexed _from, address indexed _to);

  /**
   * The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * Throws if called by any account other than the owner.
   */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  /**
   * Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  /**
   * Allows the new owner toaccept ownership
   */
  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/*
*This library is used to do mathematics safely
*/
contract SafeMathLib {
  function safeMul(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}


/**
 * Upgrade agent interface inspired by Lunyr.
 * Taken and inspired from https://tokenmarket.net
 *
 * Upgrade agent transfers tokens to a new version of a token contract.
 * Upgrade agent can be set on a token by the upgrade master.
 *
 * Steps are
 * - Upgradeabletoken.upgradeMaster calls UpgradeableToken.setUpgradeAgent()
 * - Individual token holders can now call UpgradeableToken.upgrade()
 *   -> This results to call UpgradeAgent.upgradeFrom() that issues new tokens
 *   -> UpgradeableToken.upgrade() reduces the original total supply based on amount of upgraded tokens
 *
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  /**
   * Upgrade amount of tokens to a new version.
   *
   * Only callable by UpgradeableToken.
   *
   * @param _tokenHolder Address that wants to upgrade its tokens
   * @param _amount Number of tokens to upgrade. The address may consider to hold back some amount of tokens in the old version.
   */
  function upgradeFrom(address _tokenHolder, uint256 _amount) external;
}


/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMathLib {

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {

      // SafMaths will automatically handle the overflow checks
      balances[msg.sender] = safeSub(balances[msg.sender],_value);
      balances[_to] = safeAdd(balances[_to],_value);
      Transfer(msg.sender, _to, _value);
      return true;

  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {

    uint _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;

  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 * First envisioned by Golem and Lunyr projects.
 * Taken and inspired from https://tokenmarket.net
 */
contract CMBUpgradeableToken is StandardToken {

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
  function CMBUpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

      // Validate input value.
      require(value != 0);

      balances[msg.sender] = safeSub(balances[msg.sender], value);

      // Take tokens out from circulation
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

      // Upgrade agent reissues the tokens
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {


      // The token is not yet in a state that we could think upgrading
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
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 * Taken and inspired from https://tokenmarket.net
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


  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferFrom()
    return super.transferFrom(_from, _to, _value);
  }

}


contract Coin is CMBUpgradeableToken, ReleasableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  /* name of the token */
  string public name = "Creatium";

  /* symbol of the token */
  string public symbol = "CMB";

  /* token decimals to handle fractions */
  uint public decimals = 18;

/* initial token supply */
  uint public totalSupply = 2000000000 * (10 ** decimals);
  uint public onSaleTokens = 30000000 * (10 ** decimals);

  uint256 pricePerToken = 295898260100000; //1 Eth = 276014352700000 CMB (0.2 USD = 1 CMB)


  uint minETH = 0 * 10**decimals;
  uint maxETH = 500 * 10**decimals; 


  //Crowdsale running
  bool public isCrowdsaleOpen=false;
  

  uint tokensForPublicSale = 0;

  address contractAddress;

  

  function Coin() CMBUpgradeableToken(msg.sender) {

    owner = msg.sender;
    contractAddress = address(this);
    //tokens are kept in contract address rather than owner
    balances[contractAddress] = totalSupply;
  }

  /* function to update token name and symbol */
  function updateTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;
    UpdatedTokenInformation(name, symbol);
  }


  function sendTokensToOwner(uint _tokens) onlyOwner returns (bool ok){
      require(balances[contractAddress] >= _tokens);
      balances[contractAddress] = safeSub(balances[contractAddress],_tokens);
      balances[owner] = safeAdd(balances[owner],_tokens);
      return true;
  }


  /* single address */
  function sendTokensToInvestors(address _investor, uint _tokens) onlyOwner returns (bool ok){
      require(balances[contractAddress] >= _tokens);
      onSaleTokens = safeSub(onSaleTokens, _tokens);
      balances[contractAddress] = safeSub(balances[contractAddress],_tokens);
      balances[_investor] = safeAdd(balances[_investor],_tokens);
      return true;
  }



  /* A dispense feature to allocate some addresses with CMB tokens
  * calculation done using token count
  *  Can be called only by owner
  */
  function dispenseTokensToInvestorAddressesByValue(address[] _addresses, uint[] _value) onlyOwner returns (bool ok){
     require(_addresses.length == _value.length);
     for(uint256 i=0; i<_addresses.length; i++){
        onSaleTokens = safeSub(onSaleTokens, _value[i]);
        balances[_addresses[i]] = safeAdd(balances[_addresses[i]], _value[i]);
        balances[contractAddress] = safeSub(balances[contractAddress], _value[i]);
     }
     return true;
  }


  function startCrowdSale() onlyOwner {
     isCrowdsaleOpen=true;
  }

   function stopCrowdSale() onlyOwner {
     isCrowdsaleOpen=false;
  }


 function setPublicSaleParams(uint _tokensForPublicSale, uint _min, uint _max, bool _crowdsaleStatus ) onlyOwner {
    require(_tokensForPublicSale != 0);
    require(_tokensForPublicSale <= onSaleTokens);
    tokensForPublicSale = _tokensForPublicSale;
    isCrowdsaleOpen=_crowdsaleStatus;
    require(_min >= 0);
    require(_max > _min+1);
    minETH = _min;
    maxETH = _max;
 }


 function setTotalTokensForPublicSale(uint _value) onlyOwner{
      require(_value != 0);
      tokensForPublicSale = _value;
  }

  function setMinAndMaxEthersForPublicSale(uint _min, uint _max) onlyOwner{
      require(_min >= 0);
      require(_max > _min+1);
      minETH = _min;
      maxETH = _max;
  }

  function updateTokenPrice(uint _value) onlyOwner{
      require(_value != 0);
      pricePerToken = _value;
  }


  function updateOnSaleSupply(uint _newSupply) onlyOwner{
      require(_newSupply != 0);
      onSaleTokens = _newSupply;
  }


  function buyTokens() public payable returns(uint tokenAmount) {

    uint _tokenAmount;
    uint multiplier = (10 ** decimals);
    uint weiAmount = msg.value;

    require(isCrowdsaleOpen);
    //require(whitelistedAddress[msg.sender]);

    require(weiAmount >= minETH);
    require(weiAmount <= maxETH);

    _tokenAmount =  safeMul(weiAmount,multiplier) / pricePerToken;

    require(_tokenAmount > 0);

    //safe sub will automatically handle overflows
    tokensForPublicSale = safeSub(tokensForPublicSale, _tokenAmount);
    onSaleTokens = safeSub(onSaleTokens, _tokenAmount);
    balances[contractAddress] = safeSub(balances[contractAddress],_tokenAmount);
    //assign tokens
    balances[msg.sender] = safeAdd(balances[msg.sender], _tokenAmount);

    //send money to the owner
    require(owner.send(weiAmount));

    return _tokenAmount;

  }

  // There is no need for vesting. It will be done manually by manually releasing tokens to certain addresses

  function() payable {
      buyTokens();
  }

  function destroyToken() public onlyOwner {
      selfdestruct(msg.sender);
  }

}