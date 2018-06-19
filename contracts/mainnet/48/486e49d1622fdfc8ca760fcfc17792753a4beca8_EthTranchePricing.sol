pragma solidity ^0.4.11;



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



contract EthTranchePricing is PricingStrategy, Ownable, SafeMathLib {

  uint public constant MAX_TRANCHES = 10;
  mapping (address => uint) public preicoAddresses;

  struct Tranche {
      uint amount;
      uint price;
  }
  Tranche[10] public tranches;
  uint public trancheCount;
  function EthTranchePricing(uint[] _tranches) {
    if(_tranches.length % 2 == 1 || _tranches.length >= MAX_TRANCHES*2) {
      throw;
    }

    trancheCount = _tranches.length / 2;

    uint highestAmount = 0;

    for(uint i=0; i<_tranches.length/2; i++) {
      tranches[i].amount = _tranches[i*2];
      tranches[i].price = _tranches[i*2+1];
      if((highestAmount != 0) && (tranches[i].amount <= highestAmount)) {
        throw;
      }

      highestAmount = tranches[i].amount;
    }
    if(tranches[0].amount != 0) {
      throw;
    }
    if(tranches[trancheCount-1].price != 0) {
      throw;
    }
  }
  function setPreicoAddress(address preicoAddress, uint pricePerToken)
    public
    onlyOwner
  {
    preicoAddresses[preicoAddress] = pricePerToken;
  }
  function getTranche(uint n) public constant returns (uint, uint) {
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

  function isSane(address _crowdsale) public constant returns(bool) {
    return true;
  }
  function getCurrentTranche(uint weiRaised) private constant returns (Tranche) {
    uint i;

    for(i=0; i < tranches.length; i++) {
      if(weiRaised < tranches[i].amount) {
        return tranches[i-1];
      }
    }
  }
  function getCurrentPrice(uint weiRaised) public constant returns (uint result) {
    return getCurrentTranche(weiRaised).price;
  }
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {

    uint multiplier = 10 ** decimals;
    if(preicoAddresses[msgSender] > 0) {
      return safeMul(value,multiplier) / preicoAddresses[msgSender];
    }

    uint price = getCurrentPrice(weiRaised);
    return safeMul(value,multiplier) / price;
  }

  function() payable {
    throw;
  }

}