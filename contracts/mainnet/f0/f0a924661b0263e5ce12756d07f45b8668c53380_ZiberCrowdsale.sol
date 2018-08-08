pragma solidity ^0.4.13;

 /// @title SafeMath contract - math operations with safety checks
 /// @author <span class="__cf_email__" data-cfemail="385c5d4e784b55594a4c5b57564c4a595b4c5d5955165b5755">[email&#160;protected]</span>
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    require(assertion);  
  }
}

 /// @title Ownable contract - base contract with an owner
 /// @author <span class="__cf_email__" data-cfemail="d4b0b1a294a7b9b5a6a0b7bbbaa0a6b5b7a0b1b5b9fab7bbb9">[email&#160;protected]</span>
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);  
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


/// @title Haltable contract - abstract contract that allows children to implement an emergency stop mechanism.
/// @author <span class="__cf_email__" data-cfemail="f1959487b1829c908385929e9f858390928594909cdf929e9c">[email&#160;protected]</span>
/// Originally envisioned in FirstBlood ICO contract.
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

  /// called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  /// called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }
}

 /// @title Killable contract - base contract that can be killed by owner. All funds in contract will be sent to the owner.
 /// @author <span class="__cf_email__" data-cfemail="05616073457668647771666a6b71776466716064682b666a68">[email&#160;protected]</span>
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}


 /// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
 /// @author <span class="__cf_email__" data-cfemail="5c38392a1c2f313d2e283f3332282e3d3f28393d31723f3331">[email&#160;protected]</span>
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function mint(address receiver, uint amount);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/// @title ZiberToken contract - standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
/// @author <span class="__cf_email__" data-cfemail="b7d3d2c1f7c4dad6c5c3d4d8d9c3c5d6d4c3d2d6da99d4d8da">[email&#160;protected]</span>
contract ZiberToken is SafeMath, ERC20, Ownable {
 string public name = "Ziber Token";
 string public symbol = "ZBR";
 uint public decimals = 8;
 uint public constant FROZEN_TOKENS = 1e7;
 uint public constant FREEZE_PERIOD = 1 years;
 uint public crowdSaleOverTimestamp;

 /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
 address public crowdsaleAgent;
 /// A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.
 bool public released = false;
 /// approve() allowances
 mapping (address => mapping (address => uint)) allowed;
 /// holder balances
 mapping(address => uint) balances;

 /// @dev Limit token transfer until the crowdsale is over.
 modifier canTransfer() {
   if(!released) {
     require(msg.sender == crowdsaleAgent);
   }
   _;
 }

 modifier checkFrozenAmount(address source, uint amount) {
   if (source == owner && now < crowdSaleOverTimestamp + FREEZE_PERIOD) {
     var frozenTokens = 10 ** decimals * FROZEN_TOKENS;
     require(safeSub(balances[owner], amount) > frozenTokens);
   }
   _;
 }

 /// @dev The function can be called only before or after the tokens have been releasesd
 /// @param _released token transfer and mint state
 modifier inReleaseState(bool _released) {
   require(_released == released);
   _;
 }

 /// @dev The function can be called only by release agent.
 modifier onlyCrowdsaleAgent() {
   require(msg.sender == crowdsaleAgent);
   _;
 }

 /// @dev Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
 /// @param size payload size
 modifier onlyPayloadSize(uint size) {
   require(msg.data.length >= size + 4);
    _;
 }

 /// @dev Make sure we are not done yet.
 modifier canMint() {
   require(!released);
    _;
  }

 /// @dev Constructor
 function ZiberToken() {
   owner = msg.sender;
 }

 /// Fallback method will buyout tokens
 function() payable {
   revert();
 }
 /// @dev Create new tokens and allocate them to an address. Only callably by a crowdsale contract
 /// @param receiver Address of receiver
 /// @param amount  Number of tokens to issue.
 function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);
    Transfer(0, receiver, amount);
 }

 /// @dev Set the contract that can call release and make the token transferable.
 /// @param _crowdsaleAgent crowdsale contract address
 function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
   crowdsaleAgent = _crowdsaleAgent;
 }
 /// @dev One way function to release the tokens to the wild. Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
 function releaseTokenTransfer() public onlyCrowdsaleAgent {
   crowdSaleOverTimestamp = now;
   released = true;
 }
 /// @dev Tranfer tokens to address
 /// @param _to dest address
 /// @param _value tokens amount
 /// @return transfer result
 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer checkFrozenAmount(msg.sender, _value) returns (bool success) {
   balances[msg.sender] = safeSub(balances[msg.sender], _value);
   balances[_to] = safeAdd(balances[_to], _value);

   Transfer(msg.sender, _to, _value);
   return true;
 }

 /// @dev Tranfer tokens from one address to other
 /// @param _from source address
 /// @param _to dest address
 /// @param _value tokens amount
 /// @return transfer result
 function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer checkFrozenAmount(_from, _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
 }
 /// @dev Tokens balance
 /// @param _owner holder address
 /// @return balance amount
 function balanceOf(address _owner) constant returns (uint balance) {
   return balances[_owner];
 }

 /// @dev Approve transfer
 /// @param _spender holder address
 /// @param _value tokens amount
 /// @return result
 function approve(address _spender, uint _value) returns (bool success) {
   // To change the approve amount you first have to reduce the addresses`
   //  allowance to zero by calling `approve(_spender, 0)` if it is not
   //  already 0 to mitigate the race condition described here:
   //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

   allowed[msg.sender][_spender] = _value;
   Approval(msg.sender, _spender, _value);
   return true;
 }

 /// @dev Token allowance
 /// @param _owner holder address
 /// @param _spender spender address
 /// @return remain amount
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
   return allowed[_owner][_spender];
 }
}


/// @title ZiberCrowdsale contract - contract for token sales.
/// @author <span class="__cf_email__" data-cfemail="b6d2d3c0f6c5dbd7c4c2d5d9d8c2c4d7d5c2d3d7db98d5d9db">[email&#160;protected]</span>
contract ZiberCrowdsale is Haltable, Killable, SafeMath {

  /// Total count of tokens distributed via ICO
  uint public constant TOTAL_ICO_TOKENS = 100000000;

  /// Miminal tokens funding goal in Wei, if this goal isn&#39;t reached during ICO, refund will begin
  uint public constant MIN_ICO_GOAL = 5000 ether;

  /// Maximal tokens funding goal in Wei
  uint public constant MAX_ICO_GOAL = 50000 ether;
  
  /// the UNIX timestamp 5e4 ether funded
  uint public maxGoalReachedAt = 0;

  /// The duration of ICO
  uint public constant ICO_DURATION = 10 days;

  /// The duration of ICO
  uint public constant AFTER_MAX_GOAL_DURATION = 24 hours;

  /// The token we are selling
  ZiberToken public token;

  /// the UNIX timestamp start date of the crowdsale
  uint public startsAt;

  /// How many wei of funding we have raised
  uint public weiRaised = 0;

  /// How much wei we have returned back to the contract after a failed crowdfund.
  uint public loadedRefund = 0;

  /// How much wei we have given back to investors.
  uint public weiRefunded = 0;

  /// Has this crowdsale been finalized
  bool public finalized;

  /// How much ETH each address has invested to this crowdsale
  mapping (address => uint256) public investedAmountOf;

  /// How much tokens this crowdsale has credited for each investor address
  mapping (address => uint256) public tokenAmountOf;

  /// Define a structure for one investment event occurrence
  struct Investment {
      /// Who invested
      address source;
      /// Amount invested
      uint weiValue;
  }

  Investment[] public investments;

  /// State machine
  /// Preparing: All contract initialization calls and variables have not been set yet
  /// Prefunding: We have not passed start time yet
  /// Funding: Active crowdsale
  /// Success: Minimum funding goal reached
  /// Failure: Minimum funding goal not reached before ending time
  /// Finalized: The finalized has been called and succesfully executed\
  /// Refunding: Refunds are loaded on the contract for reclaim.
  enum State {Unknown, Preparing, Funding, Success, Failure, Finalized, Refunding}

  /// A new investment was made
  event Invested(address investor, uint weiAmount);
  /// Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  /// @dev Modified allowing execution only if the crowdsale is currently running
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  /// @dev Constructor
  /// @param _token Pay Fair token address
  /// @param _start token ICO start date
  function Crowdsale(address _token, uint _start) {
    require(_token != 0);
    require(_start != 0);

    owner = msg.sender;
    token = ZiberToken(_token);
    startsAt = _start;
  }

  ///  Don&#39;t expect to just send in money and get tokens.
  function() payable {
    buy();
  }

   /// @dev Make an investment. Crowdsale must be running for one to invest.
   /// @param receiver The Ethereum address who receives the tokens
  function investInternal(address receiver) stopInEmergency private {
    var state = getState();
    require(state == State.Funding);
    require(msg.value > 0);

    // Add investment record
    var weiAmount = msg.value;
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
    investments.push(Investment(receiver, weiAmount));

    // Update totals
    weiRaised = safeAdd(weiRaised, weiAmount);
    // Max ICO goal reached at
    if(maxGoalReachedAt == 0 && weiRaised >= MAX_ICO_GOAL)
      maxGoalReachedAt = now;
    // Tell us invest was success
    Invested(receiver, weiAmount);
  }

  /// @dev Allow anonymous contributions to this crowdsale.
  /// @param receiver The Ethereum address who receives the tokens
  function invest(address receiver) public payable {
    investInternal(receiver);
  }

  /// @dev The basic entry point to participate the crowdsale process.
  function buy() public payable {
    invest(msg.sender);
  }

  /// @dev Finalize a succcesful crowdsale.
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    require(!finalized);

    finalized = true;
    finalizeCrowdsale();
  }

  /// @dev Owner can withdraw contract funds
  function withdraw() public onlyOwner {
    // Transfer funds to the team wallet
    owner.transfer(this.balance);
  }

  /// @dev Finalize a succcesful crowdsale.
  function finalizeCrowdsale() internal {
    // Calculate divisor of the total token count
    uint divisor;
    for (uint i = 0; i < investments.length; i++)
       divisor = safeAdd(divisor, investments[i].weiValue);

    var multiplier = 10 ** token.decimals();
    // Get unit price
    uint unitPrice = safeDiv(safeMul(TOTAL_ICO_TOKENS, multiplier), divisor);

    // Distribute tokens among investors
    for (i = 0; i < investments.length; i++) {
        var tokenAmount = safeMul(unitPrice, investments[i].weiValue);
        tokenAmountOf[investments[i].source] += tokenAmount;
        assignTokens(investments[i].source, tokenAmount);
    }
    assignTokens(owner, 2e7);
    token.releaseTokenTransfer();
  }

  /// @dev Allow load refunds back on the contract for the refunding.
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value > 0);
    loadedRefund = safeAdd(loadedRefund, msg.value);
  }

  /// @dev Investors can claim refund.
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0)
      return;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded, weiValue);
    Refund(msg.sender, weiValue);
    msg.sender.transfer(weiValue);
  }

  /// @dev Minimum goal was reached
  /// @return true if the crowdsale has raised enough money to not initiate the refunding
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= MIN_ICO_GOAL;
  }

  /// @dev Check if the ICO goal was reached.
  /// @return true if the crowdsale has raised enough money to be a success
  function isCrowdsaleFull() public constant returns (bool) {
    return weiRaised >= MAX_ICO_GOAL && now > maxGoalReachedAt + AFTER_MAX_GOAL_DURATION;
  }

  /// @dev Crowdfund state machine management.
  /// @return State current state
  function getState() public constant returns (State) {
    if (finalized)
      return State.Finalized;
    if (address(token) == 0)
      return State.Preparing;
    if (now >= startsAt && now < startsAt + ICO_DURATION && !isCrowdsaleFull())
      return State.Funding;
    if (isCrowdsaleFull())
      return State.Success;
    if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
      return State.Refunding;
    return State.Failure;
  }

   /// @dev Dynamically create tokens and assign them to the investor.
   /// @param receiver investor address
   /// @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
   function assignTokens(address receiver, uint tokenAmount) private {
     token.mint(receiver, tokenAmount);
   }
}