// SPDX-License-Identifier: GNU General Public License v3.0 or later

pragma solidity ^0.8.0;

import "./OracleEventManager.sol";

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract OraclePancakeEventManager is OracleEventManager {
    
    address public _pairAddress;

    event PairAddressChanged(address);

    constructor(
        address eventLifeCycleAddress,
        address bettingPoolAddress,
        address pairAddress,
        uint256 priceChangePart,
        string memory eventName,
        string memory blackTeam,
        string memory whiteTeam,
        string memory eventType,
        string memory eventSeries,
        uint256 eventStartTimeOutExpected,
        uint256 eventEndTimeOutExpected
    ) OracleEventManager(
        eventLifeCycleAddress,
        bettingPoolAddress,
        priceChangePart,
        eventName,
        blackTeam,
        whiteTeam,
        eventType,
        eventSeries,
        eventStartTimeOutExpected,
        eventEndTimeOutExpected
    ) {
        // _pairAddress = IPancakeFactory(pancakeFactoryAddress).getPair(baseTokenAddress, quoteTokenAddress);
        _pairAddress = pairAddress;
    }    

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint BONE = 10**18;
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    function getCurrentPrice() override internal view returns (int256 price, uint256 providerTimeStamp) {
        (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        ) = IPancakePair(_pairAddress).getReserves();

        price = int256(bdiv(_reserve0, _reserve1));
        providerTimeStamp = _blockTimestampLast;
    }

    function changePairAddress(address pairAddress) public onlyOwner {
        require (pairAddress != address(0), "New pair address should be not null");
        require (_pairAddress != pairAddress, "New pair address should not be equal old address");
        _pairAddress = pairAddress;
        emit PairAddressChanged(pairAddress);
    }
}

// SPDX-License-Identifier: GNU General Public License v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
interface IBettingPool {
    function _eventStarted() external returns (bool);
}

contract OracleEventManager is Ownable {
    constructor(
        address eventLifeCycleAddress,
        address bettingPoolAddress,
        uint256 priceChangePart,
        string memory eventName,
        string memory blackTeam,
        string memory whiteTeam,
        string memory eventType,
        string memory eventSeries,
        uint256 eventStartTimeOutExpected,
        uint256 eventEndTimeOutExpected
    ) {
        _eventLifeCycleAddress = eventLifeCycleAddress;
        _bettingPoolAddress = bettingPoolAddress;
        _eventName = eventName;
        _blackTeam = blackTeam;
        _whiteTeam = whiteTeam;
        _eventType = eventType;
        _eventSeries = eventSeries;
        _eventStartTimeOutExpected = eventStartTimeOutExpected;
        _eventEndTimeOutExpected = eventEndTimeOutExpected;
        _priceChangePart = priceChangePart;
        _lastEventId = 0;
    }

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

    struct RoundData {
        int price;
        uint providerTimeStamp;
    }

    uint256 public _priceChangePart;
    string public _eventName;
    string public _blackTeam;
    string public _whiteTeam;
    string public _eventType;
    string public _eventSeries;
    uint256 public _eventStartTimeOutExpected;
    uint256 public _eventEndTimeOutExpected;

    address public _eventLifeCycleAddress;
    address public _bettingPoolAddress;

    uint public _lastEventId = 0;
    uint public _checkPeriod = 60;      // in seconds
    uint public _deviation = 60;      // in seconds

    GameEvent public _gameEvent;

    RoundData public _startRoundData;
    RoundData public _endRoundData;


    event EventLifeCycleAddressChanged(address);
    event BettingPoolAddressChanged(address);
    event CheckPeriodChanged(uint256);

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

    event AppStarted(uint256 nowTime, uint256 eventStartTimeExpected, uint256 startedAt);
    event AppEnded(uint256 nowTime, uint256 eventEndTimeExpected, int8 result, bool error);

    event LatestRound(int256 price, uint256 timeStamp);
    event HistoryRound(int256 price, uint256 timeStamp);


    function prepareEvent() external {
        require(IBettingPool(_bettingPoolAddress)._eventStarted() == false, "BettingPool now closed");
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

    function getCurrentPrice() virtual internal view returns (int256 price, uint256 providerTimeStamp) {
        price = 0;
        providerTimeStamp = block.timestamp;
    }

    function startEvent() external {
        require(_gameEvent.createdAt != 0, "Not prepared event");
        require(_gameEvent.startedAt == 0, "Event already started");

        require(block.timestamp > _gameEvent.eventStartTimeExpected - (_checkPeriod / 2), "Too early start");
        // require(block.timestamp < _gameEvent.eventStartTimeExpected + (_checkPeriod / 2), "It's too late to start");

        if (block.timestamp < _gameEvent.eventStartTimeExpected + (_checkPeriod / 2)) {
            (
                _startRoundData.price,
                _startRoundData.providerTimeStamp
            ) = getCurrentPrice();

            emit LatestRound(
                _startRoundData.price,
                _startRoundData.providerTimeStamp
            );

            IEventLifeCycle(_eventLifeCycleAddress).startEvent();
            _gameEvent.startedAt = block.timestamp;

            emit AppStarted(block.timestamp, _gameEvent.eventStartTimeExpected, _gameEvent.startedAt);
        } else {
            // Black won -1, 1 means white-won, 0 means draw. 
            int8 gameResult = 0;
            _gameEvent.endedAt = block.timestamp;

            bool error = true;

            emit AppEnded(_gameEvent.endedAt, _gameEvent.eventEndTimeExpected, gameResult, error);

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
    
    event Some(uint256 eventEndTimeExpected, uint256 localTimeStamp, uint256 roundTimeStamp);

    function finalizeEvent() public {

        checkEvent();

        (
            _endRoundData.price,
            _endRoundData.providerTimeStamp
        ) = getCurrentPrice();

        emit LatestRound(
            _endRoundData.price,
            _endRoundData.providerTimeStamp
        );

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

        bool error = false;
        emit AppEnded(_gameEvent.endedAt, _gameEvent.eventEndTimeExpected, gameResult, error);

        delete _gameEvent;
        delete _startRoundData;
        delete _endRoundData;
    }

    function changeDeviation(uint deviation) public onlyOwner {
        require (_deviation != deviation, "New deviation value should not be equal old value");
        _deviation = deviation;
    }

    function changeEventLifeCycleAddress(address eventLifeCycleAddress) public onlyOwner {
        require (eventLifeCycleAddress != address(0), "New event lifecycle address should be not null");
        require (_eventLifeCycleAddress != eventLifeCycleAddress, "New event lifecycle address should not be equal old address");
        _eventLifeCycleAddress = eventLifeCycleAddress;
        emit EventLifeCycleAddressChanged(eventLifeCycleAddress);
    }

    function changeBettingPoolAddress(address bettingPoolAddress) public onlyOwner {
        require (bettingPoolAddress != address(0), "New betting pool address should be not null");
        require (_bettingPoolAddress != bettingPoolAddress, "New betting pool address should not be equal old address");
        _bettingPoolAddress = bettingPoolAddress;
        emit BettingPoolAddressChanged(bettingPoolAddress);
    }

    function changeCheckPeriod(uint256 checkPeriod) public onlyOwner {
        require (checkPeriod != 0, "New check period should be not null");
        require (_checkPeriod != checkPeriod, "New check period should not be equal old address");
        _checkPeriod = checkPeriod;
        emit CheckPeriodChanged(checkPeriod);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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