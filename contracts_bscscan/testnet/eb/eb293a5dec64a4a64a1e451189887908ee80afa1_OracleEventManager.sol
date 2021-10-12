/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/OracleEventManager.sol



pragma solidity ^0.8.0;



interface IEventLifeCycle {
    function addNewEvent(
        uint256 priceChangePart_,
        uint eventStartTimeExpected_,
        uint eventEndTimeExpected_,
        string calldata blackTeam_,
        string calldata whiteTeam_,
        string calldata eventType_,
        string calldata eventSeries_,
        string calldata eventName_,
        uint eventId_) external;
    function startEvent() external returns (uint);
    function endEvent(int8 _result) external;
}

contract OracleEventManager is Ownable {
    uint256 public _priceChangePart;
    string public _eventName;
    string public _blackTeam;
    string public _whiteTeam;
    string public _eventType;
    string public _eventSeries;
    uint256 public _eventStartTimeOutExpected;
    uint256 public _eventEndTimeOutExpected;

    address public _eventLifeCycleAddress;

    AggregatorV3Interface internal _priceFeed;

    event EventLifeCycleAddressChanged(address);

    event PrepareEvent(
        uint256 createdAt,
        uint256 priceChangePercent,
        uint256 eventStartTimeExpected,
        uint256 eventEndTimeExpected,
        string blackTeam,
        string whiteTeam,
        string eventType,
        string eventSeries,
        string eventName,
        uint256 eventid
    );

    event AppStarted(uint256 nowTime, uint256 eventStartTimeExpected, uint80 roundID, uint256 startedAt);
    event AppEnded(uint256 nowTime, uint256 eventEndTimeExpected, uint80 roundID, int8 result);

    event LatestRound(uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound);
    event HistoryRound(uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound);


    uint public _lastEventId = 0;
    uint public _checkPeriod = 60;      // in seconds

    GameEvent public _gameEvent;

    RoundData public _startRoundData;
    RoundData public _endRoundData;

    // ===================== FIX: Позже можно удалить ================================
    struct GameEvent {
        uint256 createdAt;
        uint256 startedAt;
        uint256 endedAt;
        uint256 priceChangePart;        // in percent
        uint eventStartTimeExpected;    // in seconds since 1970
        uint eventEndTimeExpected;      // in seconds since 1970
        string blackTeam;
        string whiteTeam;
        string eventType;
        string eventSeries;
        string eventName;
        uint eventid;
    }
    // ===================== FIX: Позже можно удалить ================================

    struct RoundData {
        uint80 roundID;
        int price;
        uint startedAt;
        uint timeStamp;
        uint80 answeredInRound;
    }

    constructor(
        address eventLifeCycleAddress,
        address priceFeedAddress,
        uint256 priceChangePart,
        string memory eventName,
        string memory blackTeam,
        string memory whiteTeam,
        string memory eventType,
        string memory eventSeries,
        uint256 eventStartTimeOutExpected,
        uint256 eventEndTimeOutExpected,
        uint256 checkPeriod
    ) {
        _eventLifeCycleAddress = eventLifeCycleAddress;
        _eventName = eventName;
        _blackTeam = blackTeam;
        _whiteTeam = whiteTeam;
        _eventType = eventType;
        _eventSeries = eventSeries;
        _eventStartTimeOutExpected = eventStartTimeOutExpected;
        _eventEndTimeOutExpected = eventEndTimeOutExpected;
        _priceChangePart = priceChangePart;
        _priceFeed = AggregatorV3Interface(priceFeedAddress);
        _lastEventId = 0;
        _checkPeriod = checkPeriod;
    }

    function prepareEvent() external {
        require(_gameEvent.createdAt == 0, "Already prepared event");

        uint256 eventStartTimeExpected = block.timestamp + _eventStartTimeOutExpected;
        uint256 eventEndTimeExpected = block.timestamp + _eventStartTimeOutExpected + _eventEndTimeOutExpected;

        _lastEventId = _lastEventId + 1;

        IEventLifeCycle(_eventLifeCycleAddress).addNewEvent(
            _priceChangePart,           // uint256 priceChangePart_
            eventStartTimeExpected,     // uint eventStartTimeExpected_
            eventEndTimeExpected,       // uint eventEndTimeExpected_
            _blackTeam,                 // string calldata blackTeam_
            _whiteTeam,                 // string calldata whiteTeam_
            _eventType,                 // string calldata eventType_
            _eventSeries,               // string calldata eventSeries_
            _eventName,                 // string calldata eventName_
            _lastEventId
        );

        _gameEvent = GameEvent({
            createdAt: block.timestamp,
            startedAt: 0,
            endedAt: 0,
            priceChangePart: _priceChangePart,                  // timestamp
            eventStartTimeExpected: eventStartTimeExpected,     // in seconds since 1970
            eventEndTimeExpected: eventEndTimeExpected,         // in seconds since 1970
            blackTeam: _blackTeam,
            whiteTeam: _whiteTeam,
            eventType: _eventType,
            eventSeries: _eventSeries,
            eventName: _eventName,
            eventid: _lastEventId
        });
        // ===================== FIX: Позже можно удалить, добавлено для тестов ================================
        emit PrepareEvent(
            _gameEvent.createdAt,
            _gameEvent.priceChangePart,
            _gameEvent.eventStartTimeExpected,
            _gameEvent.eventEndTimeExpected,
            _gameEvent.blackTeam,
            _gameEvent.whiteTeam,
            _gameEvent.eventType,
            _gameEvent.eventSeries,
            _gameEvent.eventName,
            _gameEvent.eventid
        );
        // ===================== FIX: Позже можно удалить, добавлено для тестов ================================
    }

    function startEvent() external {
        require(_gameEvent.createdAt != 0, "Not prepared event");
        require(_gameEvent.startedAt == 0, "Event already started");

        require(block.timestamp > _gameEvent.eventStartTimeExpected - (_checkPeriod / 2), "Too early start");
        require(block.timestamp < _gameEvent.eventStartTimeExpected + (_checkPeriod / 2), "It's too late to start");

        (
            _startRoundData.roundID, 
            _startRoundData.price,
            _startRoundData.startedAt,
            _startRoundData.timeStamp,
            _startRoundData.answeredInRound
        ) = _priceFeed.latestRoundData();

        emit LatestRound(_startRoundData.roundID,
            _startRoundData.price,
            _startRoundData.startedAt,
            _startRoundData.timeStamp,
            _startRoundData.answeredInRound
        );

        IEventLifeCycle(_eventLifeCycleAddress).startEvent();
        _gameEvent.startedAt = block.timestamp;

        emit AppStarted(block.timestamp, _gameEvent.eventStartTimeExpected, _startRoundData.roundID, _gameEvent.startedAt);

        // ===================== TODO: Дополнительная проверка событий от ELC ================================

    }

    function endEventStartTooLate() public onlyOwner {
        require(_gameEvent.createdAt != 0, "Not prepared event");
        require(_gameEvent.startedAt == 0, "Event already started");
        if (block.timestamp < _gameEvent.eventStartTimeExpected + (_checkPeriod / 2)) {
            // Send 0 means draw. 
            int8 gameResult = 0;
            // IEventLifeCycle(_eventLifeCycleAddress).endEvent(gameResult);

            _gameEvent.endedAt = block.timestamp;
            
            emit AppEnded(_gameEvent.endedAt, _gameEvent.eventEndTimeExpected, _endRoundData.roundID, gameResult);

            delete _gameEvent;
            delete _startRoundData;
            delete _endRoundData;
        }
    }

    function checkEvent() internal view {
        require(_gameEvent.createdAt != 0, "Not prepared event");
        require(_gameEvent.startedAt != 0, "Event not started");
        require(block.timestamp >= _gameEvent.eventEndTimeExpected, "Too early end");
        require(_gameEvent.endedAt == 0, "Event already finalazed");
    }

    function findRoundId() internal pure returns (uint80 roundID) {
        // Заглушка для вызова внешнего адаптера
        // _gameEvent.eventEndTimeExpected
        roundID = 18446744073709762708;
    }

    function finalizeEventWithRoundId(uint80 roundID) public {
        checkEvent();
        (
            _endRoundData.roundID, 
            _endRoundData.price,
            _endRoundData.startedAt,
            _endRoundData.timeStamp,
            _endRoundData.answeredInRound
        ) = _priceFeed.getRoundData(roundID);

        emit HistoryRound(
            _endRoundData.roundID,
            _endRoundData.price,
            _endRoundData.startedAt,
            _endRoundData.timeStamp,
            _endRoundData.answeredInRound
        );

        require(_endRoundData.timeStamp > 0, "Round not complete");
        require(_endRoundData.price != 0, "History price is NULL");

        // ===================== TODO: Дополнительная проверка на совпадение времени ================================

        // ===================== TODO: Дополнительная проверка на совпадение времени ================================

        // Black won -1, 1 means white-won, 0 means draw. 
        int8 gameResult = 0;
        if (_startRoundData.price > _endRoundData.price) {
            gameResult = -1;
        }
        if (_startRoundData.price < _endRoundData.price) {
            gameResult = 1;
        }
        IEventLifeCycle(_eventLifeCycleAddress).endEvent(gameResult);

        _gameEvent.endedAt = block.timestamp;
        
        emit AppEnded(_gameEvent.endedAt, _gameEvent.eventEndTimeExpected, _endRoundData.roundID, gameResult);

        delete _gameEvent;
        delete _startRoundData;
        delete _endRoundData;
    }
    
    event Some(uint256 eventEndTimeExpected, uint256 localTimeStamp, uint256 roundTimeStamp);

    function finalizeEvent() public {
        checkEvent();
        uint80 roundID = 0;
        int price = 0;
        uint startedAt = 0;
        uint timeStamp = 0;
        uint80 answeredInRound = 0;
        // bool autoFindRoundId = false;
        (
            roundID,
            price,
            startedAt,
            timeStamp,
            answeredInRound
        ) = _priceFeed.latestRoundData();

        emit LatestRound(
            roundID,
            price,
            startedAt,
            timeStamp,
            answeredInRound
        );

        uint diff = 0;
        if (_gameEvent.eventEndTimeExpected > timeStamp) {
            diff = _gameEvent.eventEndTimeExpected - timeStamp;
        }
        if (timeStamp > _gameEvent.eventEndTimeExpected) {
            diff = timeStamp - _gameEvent.eventEndTimeExpected;
        }
        
        emit Some(_gameEvent.eventEndTimeExpected, block.timestamp, timeStamp);
        // TODO: надо понять есть ли смысл небольшую погрешность тут разрешать или абсолютное равенство
        // require((diff < _checkPeriod / 2) && (diff >= 0), "TimeStamp is not equal eventEndTimeExpected");
        require(timeStamp == _gameEvent.eventEndTimeExpected, "TimeStamp is not equal eventEndTimeExpected");
        require(price != 0, "Price is NULL");

        // TODO: in future can get roundId from adapter 
        // roundID = findRoundId();
        

        // Check roundId
        // 
        // Check roundId

        finalizeEventWithRoundId(roundID);
    }

    function changeEventLifeCycleAddress(address eventLifeCycleAddress) public onlyOwner {
        require (eventLifeCycleAddress != address(0), "New event lifecycle address should be not null");
        require (_eventLifeCycleAddress != eventLifeCycleAddress, "New event lifecycle address should not be equal old address");
        _eventLifeCycleAddress = eventLifeCycleAddress;
        emit EventLifeCycleAddressChanged(eventLifeCycleAddress);
    }
}