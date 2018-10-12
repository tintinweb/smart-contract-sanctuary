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

// File: contracts/token/ERC20Cutted.sol

contract ERC20Cutted {

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

}

// File: contracts/Room1.sol

contract Room1 is Ownable {

  event TicketPurchased(address lotAddr, uint lotIndex, uint ticketNumber, address player, uint ticketPrice);

  event TicketWin(address lotAddr, uint lotIndex, uint ticketNumber, address player, uint win);

  using SafeMath for uint;

  uint public LIMIT = 100;

  uint public RANGE = 1000000000;

  uint public PERCENT_RATE = 100;

  enum LotState { Accepting, Processing, Rewarding, Finished }

  uint public interval;

  uint public duration;

  uint public starts;

  uint ticketPrice;

  uint feePercent;

  uint public lotProcessIndex;

  address public feeWallet;

  struct Ticket {
    address owner;
    uint number;
    uint win;
  }

  struct Lot {
    LotState state;
    uint processIndex;
    uint summaryNumbers;
    uint summaryInvested;
    uint ticketsCount;
    uint playersCount;
    mapping (uint => Ticket) tickets;
    mapping (address => uint) invested;
    address[] players;
  }
  
  mapping(uint => Lot) public lots;

  modifier started() {
    require(now >= starts, "Not started yet!");
    _;
  }

  modifier notContract(address to) {
    uint codeLength;
    assembly {
      codeLength := extcodesize(to)
    }
    require(codeLength == 0, "Contracts not supported!");
    _;
  }

  function getLotInvested(uint lotNumber, address player) view public returns(uint) {
    Lot storage lot = lots[lotNumber];
    return lot.invested[player];
  }

  function getTicketInfo(uint lotNumber, uint ticketNumber) view public returns(address, uint, uint) {
    Ticket storage ticket = lots[lotNumber].tickets[ticketNumber];
    return (ticket.owner, ticket.number, ticket.win);
  }

  function getCurLotIndex() view public returns(uint) {
    uint passed = now.sub(starts);
    if(passed == 0)
      return 0;
    return passed.div(interval+duration);
  }

  constructor() public {
    starts = 1538938800;
    ticketPrice = 100000000000000000;
    feePercent = 5;
    interval = 3600;
    uint fullDuration = 14400;
    duration = fullDuration.sub(interval);
    feeWallet = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770;
  }

  function getNotPayableTime(uint lotIndex) view public returns(uint) {
    return starts.add(interval.add(duration).mul(lotIndex.add(1))).sub(interval);
  }

  function () public payable notContract(msg.sender) started {
    require(RANGE.mul(RANGE).mul(address(this).balance.add(msg.value)) > 0, "Balance limit error!");
    require(msg.value >= ticketPrice, "Not enough funds to buy ticket!");
    uint curLotIndex = getCurLotIndex();
    require(now < getNotPayableTime(curLotIndex), "Game finished!");
    Lot storage lot = lots[curLotIndex];
    require(RANGE.mul(RANGE) > lot.ticketsCount, "Ticket count limit exceeded!");
    
    uint numTicketsToBuy = msg.value.div(ticketPrice);

    uint toInvest = ticketPrice.mul(numTicketsToBuy);

    if(lot.invested[msg.sender] == 0) {
      lot.players.push(msg.sender);
      lot.playersCount = lot.playersCount.add(1);
    }

    lot.invested[msg.sender] = lot.invested[msg.sender].add(toInvest);

    for(uint i = 0; i < numTicketsToBuy; i++) {
      lot.tickets[lot.ticketsCount].owner = msg.sender; 
      emit TicketPurchased(address(this), curLotIndex, lot.ticketsCount, msg.sender, ticketPrice);
      lot.ticketsCount = lot.ticketsCount.add(1);
    }

    lot.summaryInvested = lot.summaryInvested.add(toInvest);

    uint refund = msg.value.sub(toInvest);
    msg.sender.transfer(refund);
  }

  function isProcessNeeds() view public started returns(bool) {
    uint curLotIndex = getCurLotIndex();
    Lot storage lot = lots[curLotIndex];
    return lotProcessIndex < curLotIndex || (now >= getNotPayableTime(lotProcessIndex) && lot.state != LotState.Finished);
  }

  function prepareToRewardProcess() public onlyOwner started {
    Lot storage lot = lots[lotProcessIndex];

    if(lot.state == LotState.Accepting) {
      require(now >= getNotPayableTime(lotProcessIndex), "Lottery stakes accepting time not finished!");
      lot.state = LotState.Processing;
    }

    require(lot.state == LotState.Processing || lot.state == LotState.Rewarding, "State should be Processing or Rewarding!");

    uint index = lot.processIndex;

    uint limit = lot.ticketsCount - index;
    if(limit > LIMIT) {
      limit = LIMIT;
    }

    limit = limit.add(index);

    uint number;

    if(lot.state == LotState.Processing) {

      number = block.number;

      for(; index < limit; index++) {
        number = uint(keccak256(abi.encodePacked(number)))%RANGE;
        lot.tickets[index].number = number;
        lot.summaryNumbers = lot.summaryNumbers.add(number);
      }

      if(index == lot.ticketsCount) {
        if (feeWallet != address(this)) {
        feeWallet.transfer(lot.summaryInvested.mul(feePercent).div(PERCENT_RATE));
        }
        lot.state = LotState.Rewarding;
        index = 0;
      }

    } else {

      for(; index < limit; index++) {
        Ticket storage ticket = lot.tickets[index];
        number = ticket.number;
        if(number > 0) {
          ticket.win = lot.summaryInvested.mul(number).div(lot.summaryNumbers);
          if(ticket.win > 0) {
            ticket.owner.transfer(ticket.win);
            emit TicketWin(address(this), lotProcessIndex, index, ticket.owner, ticket.win);
          }
        }
      }

      if(index == lot.ticketsCount) {
        lot.state = LotState.Finished;
      }

      lotProcessIndex = lotProcessIndex.add(1);
    } 

    lot.processIndex = index;
  }

  function retrieveTokens(address tokenAddr, address to) public onlyOwner {
    ERC20Cutted token = ERC20Cutted(tokenAddr);
    token.transfer(to, token.balanceOf(address(this)));
  }

  function retrieveEth() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

}