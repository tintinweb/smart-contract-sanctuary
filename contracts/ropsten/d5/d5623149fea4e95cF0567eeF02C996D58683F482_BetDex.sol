pragma solidity 0.4.25;

contract BetDex {
  using SafeMath for uint256;

  address public owner;
  address public houseFeeAddress;
  uint public houseFeePercent = 3;
  uint public minimumBetAmount = 0.01 ether;
  string public version = &#39;1.1.5&#39;;

  struct Event {
    bytes32 eventId;
    bytes32 category;
    bytes32 winningScenarioId;
    bytes32 firstScenarioName;
    bytes32 secondScenarioName;
    uint index;
    uint totalReward;
    uint totalNumOfBets;
    uint totalBettors;
    uint winnerPoolTotal;
    bool eventHasEnded;
    bool houseFeePaid;
    bool eventCancelled;
    bool resultIsATie;
    uint bettingOpensTime;
    uint eventStartsTime;
    mapping(bytes32 => Scenario) scenarios;
    mapping(address => bettorInfo) bettorsIndex;
  }

  struct Scenario {
    bytes32 scenarioId;
    uint totalBet;
    uint numOfBets;
  }

  struct bettorInfo {
    bool rewarded;
    bool refunded;
    uint totalBet;
    mapping(bytes32 => uint) bets;
  }

  mapping (bytes32 => Event) events;
  bytes32[] eventsIndex;

  //events
  event EventCreated(bytes32 indexed eventId, uint bettingOpensTime, uint eventStartsTime);
  event BetPlaced(bytes32 indexed eventId, bytes32 scenarioBetOn, address indexed from, uint betValue, uint timestamp, bytes32 firstScenarioName, bytes32 secondScenarioName, bytes32 category);
  event WinnerSet(bytes32 indexed eventId, bytes32 winningScenarioName, uint timestamp);
  event HouseFeePaid(address houseFeeAddress, uint houseFeeAmount);
  event Withdrawal(bytes32 indexed eventId, bytes32 category, address indexed userAddress, bytes32 withdrawalType, uint amount, bytes32 firstScenarioName, bytes32 secondScenarioName, uint timestamp);
  event HouseFeePercentChanged(uint oldFee, uint newFee);
  event HouseFeeAddressChanged(address oldAddress, address newAddress);
  event OwnershipTransferred(address owner, address newOwner);
  event EventCancelled(bytes32 indexed eventId, uint timestamp);
  event TieResultSet(bytes32 indexed _eventId, uint timestamp);
  event UpdateEventStartsTime(bytes32 indexed eventId, uint _newEventStartsTime, uint timestamp);
  event UpdateBettingOpensTime(bytes32 indexed eventId, uint _newBettingOpensTime, uint timestamp);

  constructor() public {
    houseFeeAddress = msg.sender;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function createNewEvent(bytes32 _eventId, string _category, uint _bettingOpensTime, uint _eventStartsTime, string _firstScenarioName, string _secondScenarioName) external onlyOwner {
    require(!internalDoesEventExist(_eventId), "Event with that ID already exists");
    require(_eventStartsTime > _bettingOpensTime, "Event start time does not exceed betting opens time");
    require(stringToBytes32(_firstScenarioName) != stringToBytes32(_secondScenarioName), "Scenario names should not be duplicates");

    events[_eventId].eventId = _eventId;
    events[_eventId].index = eventsIndex.push(_eventId)-1;
    events[_eventId].category = stringToBytes32(_category);
    events[_eventId].bettingOpensTime = _bettingOpensTime;
    events[_eventId].eventStartsTime = _eventStartsTime;
    events[_eventId].firstScenarioName = stringToBytes32(_firstScenarioName);
    events[_eventId].secondScenarioName = stringToBytes32(_secondScenarioName);

    events[_eventId].scenarios[stringToBytes32(_firstScenarioName)].scenarioId = stringToBytes32(_firstScenarioName); //first team
    events[_eventId].scenarios[stringToBytes32(_secondScenarioName)].scenarioId = stringToBytes32(_secondScenarioName); //second team

    emit EventCreated(_eventId, _bettingOpensTime, _eventStartsTime);
  }

  function placeBet(bytes32 _eventId, string _scenarioBetOn) external payable {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(msg.value >= minimumBetAmount, "Bet amount does not exceed minimum");
    require(!events[_eventId].eventHasEnded, "Event has ended");
    require(events[_eventId].bettingOpensTime < now && events[_eventId].eventStartsTime > now, "Betting is not open");
    require(stringToBytes32(_scenarioBetOn) == events[_eventId].firstScenarioName || stringToBytes32(_scenarioBetOn) == events[_eventId].secondScenarioName, "Scenario name does not exist in event");

    if (events[_eventId].bettorsIndex[msg.sender].totalBet == 0) {
      events[_eventId].totalBettors += 1;
    }

    events[_eventId].bettorsIndex[msg.sender].bets[stringToBytes32(_scenarioBetOn)] = (events[_eventId].bettorsIndex[msg.sender].bets[stringToBytes32(_scenarioBetOn)]).add(msg.value);
    events[_eventId].bettorsIndex[msg.sender].totalBet = (events[_eventId].bettorsIndex[msg.sender].totalBet).add(msg.value);

    events[_eventId].totalNumOfBets = (events[_eventId].totalNumOfBets).add(1);
    events[_eventId].totalReward = (events[_eventId].totalReward).add(msg.value);
    events[_eventId].scenarios[stringToBytes32(_scenarioBetOn)].numOfBets = (events[_eventId].scenarios[stringToBytes32(_scenarioBetOn)].numOfBets).add(1);
    events[_eventId].scenarios[stringToBytes32(_scenarioBetOn)].totalBet = (events[_eventId].scenarios[stringToBytes32(_scenarioBetOn)].totalBet).add(msg.value);

    emit BetPlaced(_eventId, stringToBytes32(_scenarioBetOn), msg.sender, msg.value, now, events[_eventId].firstScenarioName, events[_eventId].secondScenarioName, events[_eventId].category);
  }

  function updateEventStartsTime(bytes32 _eventId, uint _newEventStartsTime) external onlyOwner {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(!events[_eventId].eventHasEnded, "Event has ended");

    events[_eventId].eventStartsTime = _newEventStartsTime;
    emit UpdateEventStartsTime(_eventId, _newEventStartsTime, now);
  }

  function updateBettingOpensTime(bytes32 _eventId, uint _newBettingOpensTime) external onlyOwner {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(!events[_eventId].eventHasEnded, "Event has ended");

    events[_eventId].bettingOpensTime = _newBettingOpensTime;
    emit UpdateBettingOpensTime(_eventId, _newBettingOpensTime, now);
  }

  function setWinnerAndEndEvent(bytes32 _eventId, bool _resultIsATie, string _winningScenarioName) external onlyOwner {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(!events[_eventId].eventHasEnded, "Event has already ended");
    require(events[_eventId].bettingOpensTime < now && events[_eventId].eventStartsTime < now, "Betting has not closed");
    if (!_resultIsATie) {
      require(events[_eventId].firstScenarioName == stringToBytes32(_winningScenarioName) || events[_eventId].secondScenarioName == stringToBytes32(_winningScenarioName));
    }

    events[_eventId].eventHasEnded = true;

    if (_resultIsATie) { //end event and allow users to claim refunds (no house fee taken)
      events[_eventId].resultIsATie = true;
      emit TieResultSet(_eventId, now);
    } else if (events[_eventId].scenarios[events[_eventId].firstScenarioName].totalBet == 0 || events[_eventId].scenarios[events[_eventId].secondScenarioName].totalBet == 0) {
      events[_eventId].eventCancelled = true;
      events[_eventId].eventHasEnded = true;
      emit EventCancelled(_eventId, now);
    } else { //end event, send house fee address, and allow users to claim winnings
      uint houseFeeAmount = (events[_eventId].totalReward).mul(houseFeePercent).div(100);
      events[_eventId].totalReward = (events[_eventId].totalReward).sub(houseFeeAmount);
      events[_eventId].winningScenarioId = stringToBytes32(_winningScenarioName);
      events[_eventId].winnerPoolTotal = events[_eventId].scenarios[events[_eventId].winningScenarioId].totalBet;
      if (!events[_eventId].houseFeePaid) {
        events[_eventId].houseFeePaid = true;
        emit HouseFeePaid(houseFeeAddress, houseFeeAmount);
        houseFeeAddress.transfer(houseFeeAmount);
      }
      emit WinnerSet(_eventId, stringToBytes32(_winningScenarioName), now);
    }
  }

  function cancelAndEndEvent(bytes32 _eventId) external onlyOwner {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(!events[_eventId].eventHasEnded, "Event has already ended");

    events[_eventId].eventCancelled = true;
    events[_eventId].eventHasEnded = true;
    emit EventCancelled(_eventId, now);
  }

  function claimWinnings(bytes32 _eventId) external {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(!events[_eventId].bettorsIndex[msg.sender].rewarded, "Address already rewarded for this event");
    require(!events[_eventId].bettorsIndex[msg.sender].refunded, "Address already refunded for this event");
    require(!events[_eventId].eventCancelled, "Event has been cancelled, address refund instead");
    require(!events[_eventId].resultIsATie, "Result was a tie, address refund instead");
    require(events[_eventId].bettorsIndex[msg.sender].totalBet > 0, "Address did not place a bet on this event");

    uint transferAmount = calculateWinnings(_eventId, msg.sender);
    if (transferAmount > 0) {
      events[_eventId].bettorsIndex[msg.sender].rewarded = true;
      emit Withdrawal(_eventId, events[_eventId].category, msg.sender, stringToBytes32(&#39;winnings&#39;), transferAmount, events[_eventId].firstScenarioName, events[_eventId].secondScenarioName, now);
      msg.sender.transfer(transferAmount);
    }
  }

  function claimRefund(bytes32 _eventId) external {
    require(internalDoesEventExist(_eventId), "Event with that ID does not exist");
    require(!events[_eventId].bettorsIndex[msg.sender].rewarded, "Address already rewarded for this event");
    require(!events[_eventId].bettorsIndex[msg.sender].refunded, "Address already refunded for this event");
    require(events[_eventId].eventCancelled || events[_eventId].resultIsATie, "Event was not cancelled or result a tie"); //make sure event was cancelled or result is a tie
    require(events[_eventId].bettorsIndex[msg.sender].totalBet > 0, "Address did not place a bet on this event");

    events[_eventId].bettorsIndex[msg.sender].refunded = true;
    emit Withdrawal(_eventId, events[_eventId].category, msg.sender, stringToBytes32(&#39;refund&#39;), events[_eventId].bettorsIndex[msg.sender].totalBet, events[_eventId].firstScenarioName, events[_eventId].secondScenarioName, now);
    msg.sender.transfer(events[_eventId].bettorsIndex[msg.sender].totalBet);
  }

  function calculateWinnings(bytes32 _eventId, address _userAddress) internal constant returns (uint winnerReward) {
    winnerReward = (((events[_eventId].totalReward.mul(10000000))
    .div(events[_eventId].winnerPoolTotal))
    .mul(events[_eventId].bettorsIndex[_userAddress].bets[events[_eventId].winningScenarioId]))
    .div(10000000);
  }

  function changeHouseFeePercent(uint _newFeePercent) external onlyOwner {
    require(_newFeePercent < houseFeePercent, "New fee percent must be smaller than current house fee percent");
    emit HouseFeePercentChanged(houseFeePercent, _newFeePercent);
    houseFeePercent = _newFeePercent;
  }

  function changeHouseFeeAddress(address _newAddress) external onlyOwner {
    emit HouseFeeAddressChanged(houseFeeAddress, _newAddress);
    houseFeeAddress = _newAddress;
  }

  function internalDoesEventExist(bytes32 _eventId) internal constant returns (bool) {
    if (eventsIndex.length > 0) {
      return (eventsIndex[events[_eventId].index] == _eventId);
    } else {
      return (false);
    }
  }

  function doesEventExist(bytes32 _eventId) public constant returns (bool) {
    if (eventsIndex.length > 0) {
      return (eventsIndex[events[_eventId].index] == _eventId);
    } else {
      return (false);
    }
  }

  function getScenarioNamesAndEventStatus(bytes32 _eventId) public constant returns (bytes32, bytes32, bool, bool, bool, bytes32) {
    return (
      events[_eventId].firstScenarioName,
      events[_eventId].secondScenarioName,
      events[_eventId].eventHasEnded,
      events[_eventId].eventCancelled,
      events[_eventId].resultIsATie,
      events[_eventId].winningScenarioId
    );
  }

  function getEventInfo(bytes32 _eventId) public constant returns (uint, bytes32, uint, uint) {
    return (
      events[_eventId].totalNumOfBets,
      events[_eventId].category,
      events[_eventId].bettingOpensTime,
      events[_eventId].eventStartsTime
    );
  }

  function getScenariosInfo(bytes32 _eventId, string _firstScenarioName, string _secondScenarioName) public constant returns (uint, uint, uint, uint) {
    return (
      events[_eventId].scenarios[stringToBytes32(_firstScenarioName)].totalBet,
      events[_eventId].scenarios[stringToBytes32(_firstScenarioName)].numOfBets,
      events[_eventId].scenarios[stringToBytes32(_secondScenarioName)].totalBet,
      events[_eventId].scenarios[stringToBytes32(_secondScenarioName)].numOfBets
    );
  }

  function getAddressBetsForEvent(bytes32 _eventId, address _userAddress, string _firstScenarioName, string _secondScenarioName) public constant returns (uint, bool, bool, uint, uint) {
    return (
        events[_eventId].bettorsIndex[_userAddress].totalBet,
        events[_eventId].bettorsIndex[_userAddress].rewarded,
        events[_eventId].bettorsIndex[_userAddress].refunded,
        events[_eventId].bettorsIndex[_userAddress].bets[stringToBytes32(_firstScenarioName)],
        events[_eventId].bettorsIndex[_userAddress].bets[stringToBytes32(_secondScenarioName)]
    );
  }

  function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}