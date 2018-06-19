pragma solidity ^0.4.11;

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

  function assert(bool assertion) private {
    if (!assertion) throw;
  }
}

contract Ownable {
  address public owner;


  function Ownable() {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address _to, uint _value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract FractionalERC20 is ERC20 {

  uint public decimals;

}

contract StandardToken is ERC20, SafeMathLib{
  
  event Minted(address receiver, uint amount);

  
  mapping(address => uint) balances;

  
  mapping (address => mapping (address => uint)) allowed;

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
   
   
    balances[msg.sender] = safeSub(balances[msg.sender],_value);
    balances[_to] = safeAdd(balances[_to],_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

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

    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

 function addApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = safeAdd(oldValue,_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

  function subApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = safeSub(oldVal,_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

}



contract UpgradeAgent {

  uint public originalSupply;

  
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}



 contract UpgradeableToken is StandardToken {

  
  address public upgradeMaster;

  
  UpgradeAgent public upgradeAgent;

  
  uint256 public totalUpgraded;

  
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  
  event UpgradeAgentSet(address agent);

  
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        
        throw;
      }

      
      if (value == 0) throw;

      balances[msg.sender] = safeSub(balances[msg.sender],value);

      
      totalSupply = safeSub(totalSupply,value);
      totalUpgraded = safeAdd(totalUpgraded,value);

      
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

 
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
        
        throw;
      }

      if (agent == 0x0) throw;
      
      if (msg.sender != upgradeMaster) throw;
      
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

      
      if(!upgradeAgent.isUpgradeAgent()) throw;
      
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }

  
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


contract ReleasableToken is ERC20, Ownable {

  
  address public releaseAgent;

  
  bool public released = false;

  
  mapping (address => bool) public transferAgents;


  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }


  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    releaseAgent = addr;
  }


  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }


  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

  
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    
    return super.transferFrom(_from, _to, _value);
  }

}

contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

  
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );


  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = safeAdd(totalSupply,amount);
    balances[receiver] = safeAdd(balances[receiver],amount);


    Transfer(0, receiver, amount);
  }


  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    
    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  }

  
  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }
}


contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable)
    UpgradeableToken(msg.sender) {

    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

    
    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

    
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        throw; 
      }
    }
  }


  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }


  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }


  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}


contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }
  function isSane() public constant returns (bool);
  function finalizeCrowdsale();

}





 contract PricingStrategy {
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}





 contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }
  function halt() external onlyOwner {
    halted = true;
  }
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}



contract Crowdsale is Haltable, SafeMathLib {
  FractionalERC20 public token;
  PricingStrategy public pricingStrategy;
  FinalizeAgent public finalizeAgent;
  address public multisigWallet;
  uint public minimumFundingGoal;
  uint public startsAt;
  uint public endsAt;
  uint public tokensSold = 0;
  uint public weiRaised = 0;
  uint public investorCount = 0;
  uint public loadedRefund = 0;
  uint public weiRefunded = 0;
  bool public finalized;
  bool public requireCustomerId;
  bool public requiredSignedAddress;
  address public signerAddress;
  mapping (address => uint256) public investedAmountOf;
  mapping (address => uint256) public tokenAmountOf;
  mapping (address => bool) public earlyParticipantWhitelist;
  uint public ownerTestValue;
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);
  event Refund(address investor, uint weiAmount);
  event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);
  event Whitelisted(address addr, bool status);
  event EndsAtChanged(uint endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {

    owner = msg.sender;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;
    if(startsAt >= endsAt) {
        throw;
    }
    minimumFundingGoal = _minimumFundingGoal;
  }
  function() payable {
    throw;
  }
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {
    if(getState() == State.PreFunding) {
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
    } else {
      throw;
    }

    uint weiAmount = msg.value;
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
      throw;
    }

    if(investedAmountOf[receiver] == 0) {
       investorCount++;
    }
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);
    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);
    if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);
    if(!multisigWallet.send(weiAmount)) throw;
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10**token.decimals();
    uint weiAmount = weiPrice * fullTokens;

    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);

    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    assignTokens(receiver, tokenAmount);
    Invested(receiver, weiAmount, tokenAmount, 0);
  }
  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress) throw;
     if(customerId == 0) throw;
     investInternal(addr, customerId);
  }
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if(requiredSignedAddress) throw;
    if(customerId == 0) throw;
    investInternal(addr, customerId);
  }
  function invest(address addr) public payable {
    if(requireCustomerId) throw;
    if(requiredSignedAddress) throw;
    investInternal(addr, 0);
  }
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    investWithSignedAddress(msg.sender, customerId, v, r, s);
  }
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }
  function buy() public payable {
    invest(msg.sender);
  }
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    if(finalized) {
      throw;
    }
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }
  function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
    requiredSignedAddress = value;
    signerAddress = _signerAddress;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }
  function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }
  function setEndsAt(uint time) onlyOwner {

    if(now > time) {
      throw;
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) throw;
    loadedRefund = safeAdd(loadedRefund,msg.value);
  }
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded,weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }
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
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }
  function isCrowdsale() public constant returns (bool) {
    return true;
  }
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);
  function isCrowdsaleFull() public constant returns (bool);
  function assignTokens(address receiver, uint tokenAmount) private;
}


contract BonusFinalizeAgent is FinalizeAgent,SafeMathLib {

  CrowdsaleToken public token;
  Crowdsale public crowdsale;
  uint public totalMembers;
  uint public allocatedBonus;
  mapping (address=>uint) bonusOf;
  address[] public teamAddresses;


  function BonusFinalizeAgent(CrowdsaleToken _token, Crowdsale _crowdsale, uint[] _bonusBasePoints, address[] _teamAddresses) {
    token = _token;
    crowdsale = _crowdsale;
    if(address(crowdsale) == 0) {
      throw;
    }
    if(_bonusBasePoints.length != _teamAddresses.length){
      throw;
    }

    totalMembers = _teamAddresses.length;
    teamAddresses = _teamAddresses;
    for (uint i=0;i<totalMembers;i++){
      if(_bonusBasePoints[i] == 0) throw;
    }
    for (uint j=0;j<totalMembers;j++){
      if(_teamAddresses[j] == 0) throw;
      bonusOf[_teamAddresses[j]] = _bonusBasePoints[j];
    }
  }
  function isSane() public constant returns (bool) {
    return (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
  }
  function finalizeCrowdsale() {
    if(msg.sender != address(crowdsale)) {
      throw;
    }
    uint tokensSold = crowdsale.tokensSold();

    for (uint i=0;i<totalMembers;i++){
      allocatedBonus = safeMul(tokensSold,bonusOf[teamAddresses[i]]) / 10000;
      token.mint(teamAddresses[i], allocatedBonus);
    }
    token.releaseTokenTransfer();
  }

}