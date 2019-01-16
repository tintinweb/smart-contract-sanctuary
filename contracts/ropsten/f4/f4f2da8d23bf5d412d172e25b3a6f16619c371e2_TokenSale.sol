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
    function burn(uint _amount) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/TokenSale.sol

// TODO: add mechanism for situation nobody funds in a day
contract TokenSale {
  using SafeMath for *;

  ERC20Interface mybToken;

  struct Day {
    uint totalWeiContributed;
    mapping (address => uint) weiContributed;
  }


  // Constant variables
  uint constant scalingFactor = 1e32;
  // uint constant decimals = 100000000000000000000;
  uint16 constant numDays = uint16(365);


  address public owner;
  uint public start;      // The timestamp when sale starts
  uint public tokensPerDay;

  mapping (uint16 => Day) public day;

  constructor(address _mybToken)
  public {
    mybToken = ERC20Interface(_mybToken);
    owner = msg.sender;
    tokensPerDay = uint(10e22);   // 100,000 MYB / day
  }

  function startSale()
  external
  onlyOwner
  returns (bool){
    require(msg.sender == owner, "only owner can start sale");
    uint saleAmount = tokensPerDay.mul(numDays);
    require(mybToken.transferFrom(msg.sender, address(this), saleAmount));
    start = now;
    return true;
  }

  function fund(uint16 _day)
  payable
  duringSale
  external
  returns (bool) {
      require(dayFor(now) <= _day);
      Day storage today = day[_day];
      today.totalWeiContributed = today.totalWeiContributed.add(msg.value);
      today.weiContributed[msg.sender] = today.weiContributed[msg.sender].add(msg.value);
      emit LogTokensPurchased(msg.sender, msg.value, _day);
      return true;
  }


  // @notice Updates claimableTokens, sends all wei to the token holder
  function withdraw(uint16 _day)
  public
  returns (bool) {
      require(dayFinished(_day), "day has not finished funding");
      Day storage thisDay = day[_day];
      uint amount = getTokensOwed(msg.sender, _day);
      delete thisDay.weiContributed[msg.sender];
      require(mybToken.transfer(msg.sender, amount), "couldnt transfer MYB to investor");
      emit LogTokensCollected(msg.sender, amount, _day);
      return true;
  }

  // @notice Updates claimableTokens, sends all wei to the token holder
  // @param (uint16[]) _day, list of token sale days msg.sender contributed wei towards
  function batchWithdraw(uint16[] _day)
  external
  returns (bool) {
    uint amount;
    require(_day.length < 50);
      for (uint i = 0; i < _day.length; i++){
        require(dayFinished(_day[i]));
        Day storage thisDay = day[_day[i]];
        uint amountToAdd = getTokensOwed(msg.sender, _day[i]);
        amount = amount.add(amountToAdd);
        delete thisDay.weiContributed[msg.sender];
        emit LogTokensCollected(msg.sender, amountToAdd, _day[i]);
      }
      require(mybToken.transfer(msg.sender, amount));
      return true;
  }

  // @notice MyBitFoundation can withdraw raised Ether here
  // @param (uint) _amount, The amount of wei to withdraw
  // TODO: send 50% to DDF
  function foundationWithdraw(uint _amount)
  external
  onlyOwner
  returns (bool){
    owner.transfer(_amount);
    emit LogFoundationWithdraw(msg.sender, _amount, dayFor(now));
    return true;
  }

  // @notice A function to burn tokens in the event that no wei are contributed that day
  function burnTokens(uint _day)
  external
  onlyOwner {
    uint16 thisDay = dayFor(_day);
    require(dayFinished(thisDay));
    require(day[thisDay].totalWeiContributed == 0);  // No WEI contributed that day
    require(mybToken.burn(tokensPerDay));
  }


  // @notice Calculates how many tokens user is owed. (new income + claimableTokens) / 10**32
  function getTokensOwed(address _user, uint16 _day)
  public
  view
  returns (uint) {
      Day storage thisDay = day[_day];
      uint percentage = thisDay.weiContributed[_user].mul(scalingFactor).div(thisDay.totalWeiContributed);
      return percentage.mul(tokensPerDay).div(scalingFactor);

  }

  function getWeiContributed(uint16 _day, address _investor)
  public
  view
  returns (uint) {
    return day[_day].weiContributed[_investor];
  }

  // @notice return the day associated with this timestamp
  function dayFor(uint _timestamp)
  public
  view
  returns (uint16) {
      return uint16(_timestamp.sub(start).div(24 hours));
  }

  // @notice returns true if _day is finished
  function dayFinished(uint16 _day)
  public
  view
  returns (bool) {
    require(dayFor(now) > _day);
    return true;
  }

  // @notice return the current day
  function currentDay()
  public
  view
  returns (uint16) {
    return dayFor(now);
  }

  // @notice Fallback function: Accepts Ether and updates ledger (issues dividends)
  function ()
  public {
      revert();
  }

  // @notice reverts if the current day is greater than 365
  modifier duringSale() {
    require(dayFor(now) < uint16(365) && start > 0);
    _;
  }

  // @notice only owner address can call
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  event LogFoundationWithdraw(address _mybFoundation, uint _amount, uint16 _day);
  event LogTokensPurchased(address _contributor, uint _amount, uint16 _day);
  event LogTokensCollected(address _contributor, uint _amount, uint16 _day);

}