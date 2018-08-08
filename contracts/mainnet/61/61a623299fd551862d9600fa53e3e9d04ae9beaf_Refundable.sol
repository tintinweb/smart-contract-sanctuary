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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract KYCCrowdsale is Ownable{

    bool public isKYCRequired = false;

    mapping (bytes32 => address) public whiteListed;

    function enableKYC() external onlyOwner {
        require(!isKYCRequired); // kyc is not enabled
        isKYCRequired = true;
    }

    function disableKYC() external onlyOwner {
        require(isKYCRequired); // kyc is enabled
        isKYCRequired = false;
    }

    //TODO: handle single address can be whiteListed multiple time using unique signed hashes
    function isWhitelistedAddress(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        assert( whiteListed[hash] == address(0x0)); // verify hash is unique
        require(address(0x20D73ef8eBF344b2930d242DA5DeC79d9dD9A92a) == ecrecover(hash, v, r, s));
        whiteListed[hash] = msg.sender;
        return true;
    }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Pausable, KYCCrowdsale{
  using SafeMath for uint256;
    
  // The token interface
  ERC20 public token;

  // The address of token holder that allowed allowance to contract
  address public tokenWallet;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // token rate in wei
  uint256 public rate;
  
  uint256 private roundOneRate;
  uint256 private roundTwoRate;
  uint256 private defaultBonussRate;

  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 public tokensSold;

  uint256 public constant forSale = 16250000;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   * @param releaseTime tokens unlock time
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 releaseTime);

  /**
   * event upon endTime updated
   */
  event EndTimeUpdated();

  /**
   * EQUI token price updated
   */
  event EQUIPriceUpdated(uint256 oldPrice, uint256 newPrice);

  /**
   * event for token releasing
   * @param holder who is releasing his tokens
   */
  event TokenReleased(address indexed holder, uint256 amount);

  constructor() public
   {
    owner = 0xe46d0049D4a4642bC875164bd9293a05dBa523f1;
    startTime = now;
    endTime = 1527811199; //GMT: Thursday, May 31, 2018 11:59:59 PM
    rate = 500000000000000;                     // 1 Token price: 0.0005 Ether == $0.35 @ Ether prie $700
    roundOneRate = (rate.mul(6)).div(10);       // price at 40% discount
    roundTwoRate = (rate.mul(75)).div(100);     // price at 35% discount
    defaultBonussRate = (rate.mul(8)).div(10);  // price at 20% discount
    
    wallet =  0xccB84A750f386bf5A4FC8C29611ad59057968605;
    token = ERC20(0x1b0cD7c0DC07418296585313a816e0Cb953DEa96);
    tokenWallet =  0xccB84A750f386bf5A4FC8C29611ad59057968605;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));

    validPurchase();

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokens);
    deposited[msg.sender] = deposited[msg.sender].add(weiAmount);
    // updateRoundLimits(tokens);
   
    uint256 lockedFor = assignTokens(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, lockedFor);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
  
   uint256 public roundOneLimit = 9500000 ether;
   uint256 public roundTwoLimit = 6750000 ether;
   
  function updateRoundLimits(uint256 _amount) private {
      if (roundOneLimit > 0){
          if(roundOneLimit > _amount){
                roundOneLimit = roundOneLimit.sub(_amount);
                return;
          } else {
              _amount = _amount.sub(roundOneLimit);
              roundOneLimit = 0;
          }
      }
      roundTwoLimit = roundTwoLimit.sub(_amount);
  }

  function getTokenAmount(uint256 weiAmount) private view returns(uint256) {
  
      uint256 buffer = 0;
      uint256 tokens = 0;
      if(weiAmount < 1 ether)
      
        // 20% disount = $0.28 EQUI Price , default category
        // 1 ETH = 2400 EQUI
        return (weiAmount.div(defaultBonussRate)).mul(1 ether);

      else if(weiAmount >= 1 ether) {
          
          
          if(roundOneLimit > 0){
              
              uint256 amount = roundOneRate * roundOneLimit;
              
              if (weiAmount > amount){
                  buffer = weiAmount - amount;
                  tokens =  (amount.div(roundOneRate)).mul(1 ether);
              }else{
                  // 40% disount = $0.21 EQUI Price , round one bonuss category
                  // 1 ETH = 3333
                  return (weiAmount.div(roundOneRate)).mul(1 ether);
              }
        
          }
          
          if(buffer > 0){
              
              return (buffer.div(roundTwoRate)).mul(1 ether);
          }
          
          return (weiAmount.div(roundTwoRate)).mul(1 ether);
      }
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view {
    require(msg.value != 0);
    require(remainingTokens() > 0,"contract doesn&#39;t have tokens");
    require(now >= startTime && now <= endTime);
  }

  function updateEndTime(uint256 newTime) onlyOwner external {
    require(newTime > startTime);
    endTime = newTime;
    emit EndTimeUpdated();
  }

  function updateEQUIPrice(uint256 weiAmount) onlyOwner external {
    require(weiAmount > 0);
    assert((1 ether) % weiAmount == 0);
    emit EQUIPriceUpdated(rate, weiAmount);
    rate = weiAmount;
    roundOneRate = (rate.mul(6)).div(10);       // price at 40% discount
    roundTwoRate = (rate.mul(75)).div(100);     // price at 35% discount
    defaultBonussRate = (rate.mul(8)).div(10);    // price at 20% discount
  }

  mapping(address => uint256) balances;
  mapping(address => uint256) internal deposited;

  struct account{
      uint256[] releaseTime;
      mapping(uint256 => uint256) balance;
  }
  mapping(address => account) ledger;


  function assignTokens(address beneficiary, uint256 amount) private returns(uint256 lockedFor){
      lockedFor = 1526278800; //September 30, 2018 11:59:59 PM

      balances[beneficiary] = balances[beneficiary].add(amount);

      ledger[beneficiary].releaseTime.push(lockedFor);
      ledger[beneficiary].balance[lockedFor] = amount;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function unlockedBalance(address _owner) public view returns (uint256 amount) {
    for(uint256 i = 0 ; i < ledger[_owner].releaseTime.length; i++){
        uint256 time = ledger[_owner].releaseTime[i];
        if(now >= time) amount +=  ledger[_owner].balance[time];
    }
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function releaseEQUITokens(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {
    require(balances[msg.sender] > 0);

    uint256 amount = 0;
    for(uint8 i = 0 ; i < ledger[msg.sender].releaseTime.length; i++){
        uint256 time = ledger[msg.sender].releaseTime[i];
        if(now >= time && ledger[msg.sender].balance[time] > 0){
            amount = ledger[msg.sender].balance[time];
            ledger[msg.sender].balance[time] = 0;
            continue;
        }
    }

    if(amount <= 0 || balances[msg.sender] < amount){
        revert();
    }

    if(isKYCRequired){
        require(isWhitelistedAddress(hash, v, r, s));
        balances[msg.sender] = balances[msg.sender].sub(amount);
        if(!token.transferFrom(tokenWallet,msg.sender,amount)){
            revert();
        }
        emit TokenReleased(msg.sender,amount);
    } else {

        balances[msg.sender] = balances[msg.sender].sub(amount);
        if(!token.transferFrom(tokenWallet,msg.sender,amount)){
            revert();
        }
        emit TokenReleased(msg.sender,amount);
    }
  }

   /**
   * @dev Checks the amount of tokens left in the allowance.
   * @return Amount of tokens left in the allowance
   */
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract Refundable is Crowdsale {

  uint256 public available; 
  bool public refunding = false;

  event RefundStatusUpdated();
  event Deposited();
  event Withdraw(uint256 _amount);
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  
  function deposit() onlyOwner public payable {
    available.add(msg.value);
    emit Deposited();
  }

  function tweakRefundStatus() onlyOwner public {
    refunding = !refunding;
    emit RefundStatusUpdated();
  }

  
  function refund() public {
    require(refunding);
    uint256 depositedValue = deposited[msg.sender];
    deposited[msg.sender] = 0;
    msg.sender.transfer(depositedValue);
    emit Refunded(msg.sender, depositedValue);
  }
  
  function withDrawBack() onlyOwner public{
      owner.transfer(this.balance);
  }
  
  function Contractbalance() view external returns( uint256){
      return this.balance;
  }
}