pragma solidity ^0.4.24;

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: contracts/Lottery.sol

contract Lottery is Ownable {

  using SafeMath for uint;

  uint public LIMIT = 100;

  uint public RANGE = 1000000000;

  uint public MIN_INVEST_LIMIT = 100000000000000000;

  uint public PERCENT_RATE = 100;

  uint public index;

  uint public start;

  uint public period;

  uint public feePercent;

  uint public summaryNumbers;
 
  address public feeWallet;

  mapping(address => uint) public invested;

  address[] investors;

  mapping(address => uint) public numbers;

  mapping(address => uint) public winBalances;

  enum LotteryState { Init, Accepting, Processing, Rewarding, Finished }

  LotteryState public state;

  modifier investPeriodFininshed() {
    require(start + period < now);
    _;
  }

  modifier initState() {
    require(state == LotteryState.Init);
    _;
  }

  modifier acceptingState() {
    require(state == LotteryState.Accepting);
    _;
  }

  modifier investTime() {
    require(now >= start && now <= start + period);
    _;
  }

  function setFeeWallet(address newFeeWallet) public onlyOwner initState {
    feeWallet = newFeeWallet;
  }

  function setStart(uint newStart) public onlyOwner initState {
    start = newStart;
  }

  function setPeriod(uint newPeriod) public onlyOwner initState {
    period = newPeriod;
  }

  function setFeePercent(uint newFeePercent) public onlyOwner initState {
    require(newFeePercent < PERCENT_RATE);
    feePercent = newFeePercent;
  }

  function startLottery() public onlyOwner {
    require(state == LotteryState.Init);
    state = LotteryState.Accepting;
  }

  function () public payable investTime acceptingState {
    require(msg.value >= MIN_INVEST_LIMIT);
    require(RANGE.mul(RANGE) > investors.length);
    require(RANGE.mul(RANGE).mul(address(this).balance.add(msg.value)) > 0);
    uint invest = invested[msg.sender];
    if(invest == 0) {
      investors.push(msg.sender);
    }
    invested[msg.sender] = invest.add(msg.value);
  }

  function prepareToRewardProcess() public investPeriodFininshed onlyOwner {
    if(state == LotteryState.Accepting) {
      state = LotteryState.Processing;
    } 

    require(state == LotteryState.Processing);

    uint limit = investors.length - index;
    if(limit > LIMIT) {
      limit = LIMIT;
    }

    uint number = block.number;

    limit += index;

    for(; index < limit; index++) {
      number = uint(keccak256(abi.encodePacked(number)))%RANGE;
      numbers[investors[index]] = number;
      summaryNumbers = summaryNumbers.add(number);
    }

    if(index == investors.length) {
      feeWallet.transfer(address(this).balance.mul(feePercent).div(PERCENT_RATE));
      state = LotteryState.Rewarding;
      index = 0;
    }

  }

  function processReward() public onlyOwner {    
    require(state == LotteryState.Rewarding);

    uint limit = investors.length - index;
    if(limit > LIMIT) {
      limit = LIMIT;
    }

    limit += index;

    for(; index < limit; index++) {
      address investor = investors[index];
      uint number = numbers[investor];
      if(number > 0) {
        winBalances[investor] = address(this).balance.mul(number).div(summaryNumbers);
      }
    }

    if(index == investors.length) {
      state = LotteryState.Finished;
    }
   
  }

  function reward() public {
    require(state == LotteryState.Finished);
    uint winBalance = winBalances[msg.sender];
    winBalances[msg.sender] = 0;
    msg.sender.transfer(winBalance);
  }

}

// File: contracts/LotteryController.sol

contract LotteryController is Ownable {

  using SafeMath for uint;

  uint public PERCENT_RATE = 100;

  address[] public lotteries;

  address[] public finishedLotteries;

  address public feeWallet;

  uint public feePercent;

  event LotteryCreated(address newAddress);

  function setFeeWallet(address newFeeWallet) public onlyOwner {
    feeWallet = newFeeWallet;
  }

  function setFeePercent(uint newFeePercent) public onlyOwner {
    feePercent = newFeePercent;
  }

  function newLottery(uint period) public onlyOwner returns(address) {
    return newFutureLottery(now, period);
  } 

  function newFutureLottery(uint start, uint period) public onlyOwner returns(address) {
    return newCustomFutureLottery(start, period, feeWallet, feePercent);
  } 

  function newCustomFutureLottery(uint start, uint period, address cFeeWallet, uint cFeePercent) public onlyOwner returns(address) {
    require(start + period > now && feePercent < PERCENT_RATE);
    Lottery lottery = new Lottery();
    LotteryCreated(lottery);
    lottery.setStart(start);
    lottery.setPeriod(period);
    lottery.setFeeWallet(cFeeWallet);
    lottery.setFeePercent(cFeePercent);
    lottery.startLottery();
    lotteries.push(lottery);
  }

  function processFinishLottery(address lotAddr) public onlyOwner returns(bool) {
    Lottery lot = Lottery(lotAddr);
    if(lot.state() == Lottery.LotteryState.Accepting ||
         lot.state() == Lottery.LotteryState.Processing) {
      lot.prepareToRewardProcess();
    } else if(lot.state() == Lottery.LotteryState.Rewarding) {
      lot.processReward(); 
      if(lot.state() == Lottery.LotteryState.Finished) {
        finishedLotteries.push(lotAddr);
        return true;
      }
    } else {
      revert();
    }
    return false;
  }

}