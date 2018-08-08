pragma solidity ^0.4.14;

 /// @title SafeMath contract - math operations with safety checks
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
}
/// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
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

/// @title Ownable contract - base contract with an owner
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
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}
 /// @title SilentNotaryToken contract - standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
contract SilentNotaryToken is SafeMath, ERC20, Killable {
  string constant public name = "Silent Notary Token";
  string constant public symbol = "SNTR";
  uint constant public decimals = 4;
  /// Buyout price
  uint constant public buyOutPrice = 200 finney;
  /// Holder list
  address[] public holders;
  /// Balance data
  struct Balance {
    /// Tokens amount
    uint value;
    /// Object exist
    bool exist;
  }
  /// Holder balances
  mapping(address => Balance) public balances;
  /// Contract that is allowed to create new tokens and allows unlift the transfer limits on this token
  address public crowdsaleAgent;
  /// A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.
  bool public released = false;
  /// approve() allowances
  mapping (address => mapping (address => uint)) allowed;

  /// @dev Limit token transfer until the crowdsale is over.
  modifier canTransfer() {
    if(!released)
      require(msg.sender == crowdsaleAgent);
    _;
  }

  /// @dev The function can be called only before or after the tokens have been releasesd
  /// @param _released token transfer and mint state
  modifier inReleaseState(bool _released) {
    require(_released == released);
    _;
  }

  /// @dev If holder does not exist add to array
  /// @param holder Token holder
  modifier addIfNotExist(address holder) {
    if(!balances[holder].exist)
      holders.push(holder);
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

  /// Tokens burn event
  event Burned(address indexed burner, address indexed holder, uint burnedAmount);
  /// Tokens buyout event
  event Pay(address indexed to, uint value);
  /// Wei deposit event
  event Deposit(address indexed from, uint value);

  /// @dev Constructor
  function SilentNotaryToken() {
  }

  /// Fallback method
  function() payable {
    require(msg.value > 0);
    Deposit(msg.sender, msg.value);
  }
  /// @dev Create new tokens and allocate them to an address. Only callably by a crowdsale contract
  /// @param receiver Address of receiver
  /// @param amount  Number of tokens to issue.
  function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint addIfNotExist(receiver) public {
      totalSupply = safeAdd(totalSupply, amount);
      balances[receiver].value = safeAdd(balances[receiver].value, amount);
      balances[receiver].exist = true;
      Transfer(0, receiver, amount);
  }

  /// @dev Set the contract that can call release and make the token transferable.
  /// @param _crowdsaleAgent crowdsale contract address
  function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
    crowdsaleAgent = _crowdsaleAgent;
  }
  /// @dev One way function to release the tokens to the wild. Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
  function releaseTokenTransfer() public onlyCrowdsaleAgent {
    released = true;
  }
  /// @dev Tranfer tokens to address
  /// @param _to dest address
  /// @param _value tokens amount
  /// @return transfer result
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) returns (bool success) {
    balances[msg.sender].value = safeSub(balances[msg.sender].value, _value);
    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_to].exist = true;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /// @dev Tranfer tokens from one address to other
  /// @param _from source address
  /// @param _to dest address
  /// @param _value tokens amount
  /// @return transfer result
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_from].value = safeSub(balances[_from].value, _value);
    balances[_to].exist = true;

    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
  /// @dev Tokens balance
  /// @param _owner holder address
  /// @return balance amount
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner].value;
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
  /// @dev buyout method
  /// @param _holder holder address
  /// @param _amount wei for buyout tokens
  function buyout(address _holder, uint _amount) onlyOwner addIfNotExist(msg.sender) external  {
    require(_holder != msg.sender);
    require(this.balance >= _amount);
    require(buyOutPrice <= _amount);

    uint multiplier = 10 ** decimals;
    uint buyoutTokens = safeDiv(safeMul(_amount, multiplier), buyOutPrice);

    balances[msg.sender].value = safeAdd(balances[msg.sender].value, buyoutTokens);
    balances[_holder].value = safeSub(balances[_holder].value, buyoutTokens);
    balances[msg.sender].exist = true;

    Transfer(_holder, msg.sender, buyoutTokens);

    _holder.transfer(_amount);
    Pay(_holder, _amount);
  }
}

/// @title SilentNotary  сrowdsale contract
contract SilentNotaryCrowdsale is Haltable, Killable, SafeMath {

 /// Period of the ICO stage
 uint constant public DURATION = 14 days;

 /// The duration of ICO
 uint public icoDuration = DURATION;

 //// The token we are selling
 SilentNotaryToken public token;

 /// Escrow wallet
 address public multisigWallet;

 /// Team wallet
 address public teamWallet;

 /// The UNIX timestamp start date of the crowdsale
 uint public startsAt;

 /// the number of tokens already sold through this contract
 uint public tokensSold = 0;

 ///  How many wei of funding we have raised
 uint public weiRaised = 0;

 ///  How many distinct addresses have invested
 uint public investorCount = 0;

 ///  How much wei we have returned back to the contract after a failed crowdfund.
 uint public loadedRefund = 0;

 ///  How much wei we have given back to investors.
 uint public weiRefunded = 0;

 ///  Has this crowdsale been finalized
 bool public finalized;

 ///  How much ETH each address has invested to this crowdsale
 mapping (address => uint256) public investedAmountOf;

 ///  How much tokens this crowdsale has credited for each investor address
 mapping (address => uint256) public tokenAmountOf;

 /// if the funding goal is not reached, investors may withdraw their funds
 uint public constant FUNDING_GOAL = 1000 ether;

 /// topup team wallet after that will topup both - team and multisig wallet by 32% and 68%
 uint constant MULTISIG_WALLET_GOAL = FUNDING_GOAL;

 /// Minimum order quantity 0.1 ether
 uint public constant MIN_INVESTEMENT = 100 finney;

 /// ICO start token price
 uint public constant MIN_PRICE = 10e9;

 /// Maximum token price, if reached ICO will stop
 uint public constant MAX_PRICE = 20e10;

 /// How much ICO tokens to sold
 uint public constant INVESTOR_TOKENS  = 10e11;

 /// Tokens count involved in price calculation
 uint public constant TOTAL_TOKENS_FOR_PRICE = INVESTOR_TOKENS;

 /// last token price
 uint public tokenPrice = MIN_PRICE;

  /// State machine
  /// Preparing: All contract initialization calls and variables have not been set yet
  /// Funding: Active crowdsale
  /// Success: Minimum funding goal reached
  /// Failure: Minimum funding goal not reached before ending time
  /// Finalized: The finalized has been called and succesfully executed
  /// Refunding: Refunds are loaded on the contract for reclaim
 enum State{Unknown, Preparing, Funding, Success, Failure, Finalized, Refunding}

 /// A new investment was made
 event Invested(address investor, uint weiAmount, uint tokenAmount);

 /// Refund was processed for a contributor
 event Refund(address investor, uint weiAmount);

 /// Crowdsale end time has been changed
 event EndsAtChanged(uint endsAt);

 /// New price was calculated
 event PriceChanged(uint oldValue, uint newValue);

 /// Modified allowing execution only if the crowdsale is currently runnin
 modifier inState(State state) {
   require(getState() == state);
   _;
 }

 /// @dev Constructor
 /// @param _token SNTR token address
 /// @param _multisigWallet  multisig wallet address
 /// @param _start  ICO start time
 function SilentNotaryCrowdsale(address _token, address _multisigWallet, address _teamWallet, uint _start) {
   require(_token != 0);
   require(_multisigWallet != 0);
   require(_teamWallet != 0);
   require(_start != 0);

   token = SilentNotaryToken(_token);
   multisigWallet = _multisigWallet;
   teamWallet = _teamWallet;
   startsAt = _start;
 }

 /// @dev Don&#39;t expect to just send in money and get tokens.
 function() payable {
   buy();
 }

  /// @dev Make an investment.
  /// @param receiver The Ethereum address who receives the tokens
 function investInternal(address receiver) stopInEmergency private {
   require(getState() == State.Funding);
   require(msg.value >= MIN_INVESTEMENT);

   uint weiAmount = msg.value;

   var multiplier = 10 ** token.decimals();
   uint tokenAmount = safeDiv(safeMul(weiAmount, multiplier), tokenPrice);
   assert(tokenAmount > 0);

   if(investedAmountOf[receiver] == 0) {
      // A new investor
      investorCount++;
   }
   // Update investor
   investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
   tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);
   // Update totals
   weiRaised = safeAdd(weiRaised, weiAmount);
   tokensSold = safeAdd(tokensSold, tokenAmount);

   var newPrice = calculatePrice(tokensSold);
   PriceChanged(tokenPrice, newPrice);
   tokenPrice = newPrice;

   assignTokens(receiver, tokenAmount);
   if(weiRaised <= MULTISIG_WALLET_GOAL)
     multisigWallet.transfer(weiAmount);
   else {
     int remain = int(weiAmount - weiRaised - MULTISIG_WALLET_GOAL);

     if(remain > 0) {
       multisigWallet.transfer(uint(remain));
       weiAmount = safeSub(weiAmount, uint(remain));
     }

     var distributedAmount = safeDiv(safeMul(weiAmount, 32), 100);
     teamWallet.transfer(distributedAmount);
     multisigWallet.transfer(safeSub(weiAmount, distributedAmount));

   }
   // Tell us invest was success
   Invested(receiver, weiAmount, tokenAmount);
 }

  /// @dev Allow anonymous contributions to this crowdsale.
  /// @param receiver The Ethereum address who receives the tokens
 function invest(address receiver) public payable {
   investInternal(receiver);
 }

  /// @dev Pay for funding, get invested tokens back in the sender address.
 function buy() public payable {
   invest(msg.sender);
 }

 /// @dev Finalize a succcesful crowdsale. The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
 function finalize() public inState(State.Success) onlyOwner stopInEmergency {
   // If not already finalized
   require(!finalized);

   finalized = true;
   finalizeCrowdsale();
 }

 /// @dev Finalize a succcesful crowdsale.
 function finalizeCrowdsale() internal {
   var multiplier = 10 ** token.decimals();
   uint investorTokens = safeMul(INVESTOR_TOKENS, multiplier);
   if(investorTokens > tokensSold)
     assignTokens(teamWallet, safeSub(investorTokens, tokensSold));
   token.releaseTokenTransfer();
 }

  /// @dev  Allow load refunds back on the contract for the refunding. The team can transfer the funds back on the smart contract in the case the minimum goal was not reached.
 function loadRefund() public payable inState(State.Failure) {
   if(msg.value == 0)
     revert();
   loadedRefund = safeAdd(loadedRefund, msg.value);
 }

 /// @dev  Investors can claim refund.
 function refund() public inState(State.Refunding) {
   uint256 weiValue = investedAmountOf[msg.sender];
   if (weiValue == 0)
     revert();
   investedAmountOf[msg.sender] = 0;
   weiRefunded = safeAdd(weiRefunded, weiValue);
   Refund(msg.sender, weiValue);
   if (!msg.sender.send(weiValue))
     revert();
 }

  /// @dev Crowdfund state machine management.
  /// @return State current state
 function getState() public constant returns (State) {
   if (finalized)
     return State.Finalized;
   if (address(token) == 0 || address(multisigWallet) == 0)
     return State.Preparing;
   if (now >= startsAt && now < startsAt + icoDuration && !isCrowdsaleFull())
     return State.Funding;
   if (isMinimumGoalReached())
       return State.Success;
   if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
     return State.Refunding;
   return State.Failure;
 }

 /// @dev Prolongate ICO if owner decide it
 function prolongate() public onlyOwner {
   require(icoDuration < DURATION * 2);
   icoDuration += DURATION;
 }

 /// @dev Calculating price, it is not linear function
 /// @param totalRaisedTokens total raised tokens
 /// @return price in wei
 function calculatePrice(uint totalRaisedTokens) internal returns (uint price) {
   int multiplier = int(10**token.decimals());
   int coefficient = int(safeDiv(totalRaisedTokens, TOTAL_TOKENS_FOR_PRICE)) - multiplier;
   int priceDifference = coefficient * int(MAX_PRICE - MIN_PRICE) / multiplier;
   assert(int(MAX_PRICE) >= -priceDifference);
   return uint(priceDifference + int(MAX_PRICE));
 }

  /// @dev Minimum goal was reached
  /// @return true if the crowdsale has raised enough money to be a succes
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= FUNDING_GOAL;
  }

  /// @dev Check crowdsale limit
  /// @return limit reached result
  function isCrowdsaleFull() public constant returns (bool) {
    return tokenPrice >= MAX_PRICE
      || tokensSold >= safeMul(TOTAL_TOKENS_FOR_PRICE,  10 ** token.decimals())
      || now > startsAt + icoDuration;
  }

   /// @dev Dynamically create tokens and assign them to the investor.
   /// @param receiver address
   /// @param tokenAmount tokens amount
  function assignTokens(address receiver, uint tokenAmount) private {
    token.mint(receiver, tokenAmount);
  }
}