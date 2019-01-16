pragma solidity 0.4.24;

// File: contracts/SafeMath.sol

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol

// @title SafeMath: overflow/underflow checks
// @notice Math operations with safety checks that throw on error
library SafeMath {

  // @notice Multiplies two numbers, throws on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  // @notice Integer division of two numbers, truncating the quotient.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  // @notice Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  // @notice Adds two numbers, throws on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  // @notice Returns fractional amount
  function getFractionalAmount(uint256 _amount, uint256 _percentage)
  internal
  pure
  returns (uint256) {
    return div(mul(_amount, _percentage), 100);
  }

}

// File: contracts/ERC20Interface.sol

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/TokenSale.sol

// TODO: add mechanism for situation nobody funds in a day
contract TokenSale {
  using SafeMath for *;


  struct Day {
    uint weiPerToken;       // // amount of wei received per MYB token
    uint dayIncome;
    mapping (address => uint) previousWeiPerToken;
    mapping (address => uint) weiContributed;
    mapping (address => uint) claimableTokens;
  }

  address public owner;
  uint constant scalingFactor = 1e32;
  uint constant decimals = 100000000000000000000;
  uint16 constant numDays = uint16(365);
  ERC20Interface mybToken;

  uint public start;
  uint public tokensPerDay;

  mapping (uint16 => Day) public day;

  constructor(address _mybToken)
  public {
    mybToken = ERC20Interface(_mybToken);
    owner = msg.sender;

  }

  function startSale(uint _totalAmount)
  external
  returns (bool){
    require(msg.sender == owner);
    // uint totalAmount = tokensPerDay.mul(356);
    require(mybToken.transferFrom(msg.sender, address(this), _totalAmount));
    tokensPerDay = _totalAmount.div(numDays);
    start = now;
    return true;
  }

  function fund(uint16 _day)
  payable
  duringSale
  public {
      require(dayFor(now) <= _day);
      require(msg.value > 0);
      Day storage today = day[_day];
      today.dayIncome = today.dayIncome.add(msg.value);
      //today.weiPerToken = today.weiPerToken.add(msg.value.mul(scalingFactor).div(tokensPerDay));
      today.weiPerToken = today.dayIncome.mul(decimals).div(tokensPerDay);
      today.weiContributed[msg.sender] = today.weiContributed[msg.sender].add(msg.value);
      emit LogTokensPurchased(msg.sender, msg.value, _day, today.weiPerToken, today.weiContributed[msg.sender]);
  }


  // @notice Updates claimableTokens, sends all wei to the token holder
  function withdraw(uint16 _day)
  public
  returns (bool) {
      require(dayFinished(_day), &#39;Day not finished&#39;);
      require(updateclaimableTokens(msg.sender, _day), &#39;Cannot update claimable tokens&#39;);
      Day storage thisDay = day[_day];
      uint _amount = thisDay.claimableTokens[msg.sender];
      delete thisDay.claimableTokens[msg.sender];
      require(mybToken.transfer(msg.sender, _amount), &#39;Cannot transfer tokens&#39;);
      emit LogTokensCollected(msg.sender, _amount, _day, thisDay.weiPerToken, thisDay.weiContributed[msg.sender]);
      return true;
  }

  // @notice Updates claimableTokens, sends all wei to the token holder
  function batchWithdraw(uint16[] _day)
  public
  returns (bool) {
    uint amount;
    require(_day.length < 100);
      for (uint i = 0; i < _day.length; i++){
        require(dayFinished(_day[i]), &#39;Day not finished&#39;);
        require(updateclaimableTokens(msg.sender, _day[i]), &#39;Cannot update claimable tokens&#39;);
        Day storage thisDay = day[_day[i]];
        uint amountToAdd = thisDay.claimableTokens[msg.sender];
        amount = amount.add(amountToAdd);
        delete thisDay.claimableTokens[msg.sender];
        emit LogTokensCollected(msg.sender, amountToAdd, _day[i], thisDay.weiPerToken, thisDay.weiContributed[msg.sender]);
      }
      require(mybToken.transfer(msg.sender, amount));
      return true;
  }

  // @notice Calculates how much value _user holds
  function getTokensForContribution(address _user, uint16 _day)
  public
  view
  returns (uint) {
      Day storage thisDay = day[_day];
      uint tokens = thisDay.weiContributed[_user].mul(decimals).div(thisDay.weiPerToken);
      //uint weiPerTokenDifference = thisDay.weiPerToken.sub(thisDay.previousWeiPerToken[_user]);
      //return weiPerTokenDifference.mul(thisDay.weiContributed[_user]);
      return tokens;
  }
/*
  // @notice Calculates how much wei user is owed. (new income + claimableTokens) / 10**32
  function getUnclaimedAmount(address _user, uint16 _day)
  public
  view
  returns (uint) {
      return (getTokensForContribution(_user, _day).add(day[_day].claimableTokens[_user]).div(scalingFactor));
  }
*/
  // @notice update the amount claimable by this user
  function updateclaimableTokens(address _user, uint16 _day)
  internal
  returns (bool) {
      Day storage thisDay = day[_day];
      thisDay.claimableTokens[_user] = thisDay.weiContributed[_user].mul(decimals).div(thisDay.weiPerToken);
      //thisDay.claimableTokens[_user] = thisDay.claimableTokens[_user].add(getTokensForContribution(_user, _day));
      //thisDay.previousWeiPerToken[_user] = thisDay.weiPerToken;
      return true;
  }

  // @notice return the day associated with this timestamp
  function dayFor(uint _timestamp)
  public
  view
  returns (uint16) {
      return uint16(_timestamp.sub(start).div(24 hours));
  }

  // @notice reverts if the current day is greater than 365
  modifier duringSale() {
    require(dayFor(now) < uint16(365) && start > 0);
    _;
  }

  // @notice returns true if _day is finished
  function dayFinished(uint16 _day)
  internal
  view
  returns (bool) {
    require(dayFor(now) > _day);
    return true;
  }

  // @notice Fallback function: Accepts Ether and updates ledger (issues dividends)
  function ()
  public {
      revert();
  }

  event LogTokensPurchased(address _contributor, uint _amount, uint16 _day, uint weiPerToken, uint weiContributed);
  event LogTokensCollected(address _contributor, uint _amount, uint16 _day, uint weiPerToken, uint weiContributed);

}