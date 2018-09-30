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

  uint public ticketPrice = 100000000000000000;

  uint public PERCENT_RATE = 100;

  uint public index;

  uint public start;

  uint public period;

  uint public feePercent;

  uint public summaryNumbers;
  
  uint public summaryInvested;
 
  address public feeWallet;

  mapping(address => uint) public invested;

  address[] investors;

  mapping(address => uint) public numbers;

  mapping(address => uint) public winBalances;

  mapping(address => uint) public toPayBalances;

  enum LotteryState { Init, Accepting, Processing, Rewarding, Finished }

  LotteryState public state;

  modifier notContract(address to) {
    uint codeLength;
    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(to)
    }
    require(codeLength == 0, "Contracts can not participate!");
    _;
  }

  modifier investPeriodFininshed() {
    require(start + period < now, "Lottery invest period finished!");
    _;
  }

  modifier initState() {
    require(state == LotteryState.Init, "Lottery should be on Init state!");
    _;
  }

  modifier acceptingState() {
    require(state == LotteryState.Accepting, "Lottery should be on Accepting state!");
    _;
  }

  modifier investTime() {
    require(now >= start && now <= start + period, "Wrong time to invest!");
    _;
  }

  function setTicketPrice(uint newTicketPrice) public onlyOwner initState {
    ticketPrice = newTicketPrice;
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

  function () public payable investTime acceptingState notContract(msg.sender) {
    require(msg.value >= ticketPrice, "Not enough funds to buy ticket!");
    require(RANGE.mul(RANGE) > investors.length, "Player number error!");
    require(RANGE.mul(RANGE).mul(address(this).balance.add(msg.value)) > 0, "Limit error!");
    uint invest = invested[msg.sender];
    require(invest == 0, "Already invested!");
    //if(invest == 0) {
    investors.push(msg.sender);
    //}
    invested[msg.sender] = invest.add(ticketPrice);
    summaryInvested = summaryInvested.add(ticketPrice);
    uint diff = msg.value - ticketPrice;
    if(diff > 0) {
      msg.sender.transfer(diff);
    }
  }

  function prepareToRewardProcess() public investPeriodFininshed onlyOwner {
    if(state == LotteryState.Accepting) {
      state = LotteryState.Processing;
    } 

    require(state == LotteryState.Processing, "Lottery state should be Processing!");

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
    require(state == LotteryState.Rewarding, "Lottery state should be Rewarding!");

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
        investor.transfer(winBalances[investor]);
      }
    }

    if(index == investors.length) {
      state = LotteryState.Finished;
    }
   
  }

}

// File: contracts/LotteryController.sol

contract LotteryController is Ownable {

  using SafeMath for uint;

  uint public PERCENT_RATE = 100;

  address[] public lotteries;

  address[] public finishedLotteries;

  address public feeWallet = address(this);

  uint public feePercent = 5;

  event LotteryCreated(address newAddress);

  function setFeeWallet(address newFeeWallet) public onlyOwner {
    feeWallet = newFeeWallet;
  }

  function setFeePercent(uint newFeePercent) public onlyOwner {
    feePercent = newFeePercent;
  }

  function newLottery(uint period, uint ticketPrice) public onlyOwner returns(address) {
    return newFutureLottery(now, period, ticketPrice);
  } 

  function newFutureLottery(uint start, uint period, uint ticketPrice) public onlyOwner returns(address) {
    return newCustomFutureLottery(start, period, ticketPrice, feeWallet, feePercent);
  } 

  function newCustomFutureLottery(uint start, uint period, uint ticketPrice, address cFeeWallet, uint cFeePercent) public onlyOwner returns(address) {
    require(start + period > now && feePercent < PERCENT_RATE);
    Lottery lottery = new Lottery();
    emit LotteryCreated(lottery);
    lottery.setStart(start);
    lottery.setPeriod(period);
    lottery.setFeeWallet(cFeeWallet);
    lottery.setFeePercent(cFeePercent);
    lottery.setTicketPrice(ticketPrice);
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
  
  function () public payable {
  }

  function retrieveEth() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

}