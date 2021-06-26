/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity 0.8.6;
enum EventState  {Active, Hold, Finished, Canceled}
    enum CompareSign {Equal, MoreOrEqual, LessOrEqual, More, Less, NotEqual}
    enum GameState {Active, Deprecated, Expired}
    enum BetState {Done, Canceled, Claimed}
    enum BetResult {Undefined, Win, Lose}
    
    //Game that available in GamePool
    struct Game {
        address eventContract;
        string name;
        address rewardModelContract;
        GameState state; 

    }

    //Users bet
    struct Bet {
        address eventContract;
        uint256 eventId;
        uint8 eventOutcomeIndex;
        uint256 betAmount;
        uint256 betTimestamp;
        BetState currentState;
        BetResult result;
    }

    //This  structure will used for reflect possible game event result
    // and bets that were made on this outcome
    struct Outcome {
        CompareSign compare;
        int256 expectedValue;
        int256 weiRaised;
        uint256 betCount;
        bool isWin;
    }
    
    struct GamblingEvent {
        address creator;
        EventState state;
        uint256 expirationTime;
        uint256 orderDeadLineTime;
        string  eventAssetSymbol;
        Outcome[2] outcome;
        int256 oraclePrice;
    }

    struct EventSettle {
        uint256 fundReward;
        uint256 creatorReward;
    }
/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// Part: IBetPriceProvider

interface IBetPriceProvider {
    function getLastPrice(address _amulet) external view returns (uint256);
    function getLastPriceByPairName(bytes32 _nameHash) external view returns (int256); 
}

// File: BinaryEvents.sol

contract BinaryEvents is  Ownable {
    
    uint256 constant public WIN_DISTRIB_PERCENT = 80;
    bool public is_valid = true;

    address public pool;
    address public oracle;

    GamblingEvent[] eventRegistry;

    event NewEvent(uint256 indexed eventId, address source);

    constructor (address _pool) {
        pool = _pool;
    }

    /// @dev Create new binary gambling event 
    /// @param _expire Event expiration unix datetime
    /// @param _orderDeadLine No more bets after this, unix datetime
    /// @param _assetSymbol pair symbol for bet i.e. `BTS/USD` that may be used
    /// with chain link oracles
    function createEvent(
        uint256 _expire, 
        uint256 _orderDeadLine, 
        string  memory _assetSymbol,
        Outcome[2] memory _outcomes
    ) 
       external 
    {
        //TODO  Add integrety and logic checks(etc _assetSymbol existence)
        //TODO Check _orderDeadLine  diff from e3xpirationbrownie test
        require(msg.sender == pool, "Only pool can call it");
        require(_outcomes.length == 2, "Only 2 outcomes for this event type");
        require(
            _outcomes[0].compare == CompareSign.MoreOrEqual && _outcomes[1].compare == CompareSign.Less || 
            _outcomes[1].compare == CompareSign.MoreOrEqual && _outcomes[0].compare == CompareSign.Less 
            ,"Only binary outcome for this contract"
        );
        require(
            _outcomes[0].expectedValue == _outcomes[1].expectedValue
            ,"Only binary outcome for this contract - one expectedValue"
        );
        GamblingEvent storage e = eventRegistry.push();
        e.outcome[0] = _outcomes[0];
        e.outcome[0].isWin = false;
        e.outcome[1] = _outcomes[1];
        e.outcome[0].isWin = false;
        e.creator = msg.sender;
        e.state = EventState.Active;
        e.expirationTime = _expire;
        e.orderDeadLineTime = _orderDeadLine;
        e.eventAssetSymbol = _assetSymbol;

        emit NewEvent(eventRegistry.length - 1, address(this));

    }
    
    //temprory,  for tests.  It cant be call without token transfer
    function incBetCountForOutcome(uint256 _eventId, uint256 _outcomeId, uint256 _amount) external returns(bool) {
        require(msg.sender == pool, "Only pool can call it");
        _updateEventState(_eventId);
        // require(
        //     (eventRegistry[_eventId].state == EventState.Active),
        //     "Sorry, No more bets"
        // );
        if  (eventRegistry[_eventId].state != EventState.Active){
            return false;
        }
        require(
            (_outcomeId == 0 || _outcomeId == 1),
            "Only 2 outcomes for this event type"
        );
        GamblingEvent storage e = eventRegistry[_eventId];
        //One more state check  incase when _updateEventState(_eventId) 
        // have change state
        if  (e.state == EventState.Active) {
            e.outcome[_outcomeId].weiRaised += int256(_amount);
            e.outcome[_outcomeId].betCount  += 1;
            return true;
        }  else {
           return false;  
        } 

    }

    function decBetCountForOutcome(uint256 _eventId, uint256 _outcomeId, uint256 _amount) external returns(bool) {
        require(msg.sender == pool, "Only pool can call it");
        _updateEventState(_eventId);
        // require(
        //     (eventRegistry[_eventId].state == EventState.Active),
        //     "Sorry, No more bets"
        // );
        if  (eventRegistry[_eventId].state != EventState.Active){
            return false;
        }
        require(
            (_outcomeId == 0 || _outcomeId == 1),
            "Only 2 outcomes for this event type"
        );
        GamblingEvent storage e = eventRegistry[_eventId];
        require(e.state == EventState.Active, "No more cancels");
        require(e.outcome[_outcomeId].weiRaised >= int256(_amount), "You are hacker");
        e.outcome[_outcomeId].weiRaised -= int256(_amount);
        e.outcome[_outcomeId].betCount  -= 1;
        return true;

    }

    function checkStateWithSave(uint256 _eventId) external {
        require(
            (
              eventRegistry[_eventId].state == EventState.Hold ||
              eventRegistry[_eventId].state == EventState.Active   
            ),
            "Event state must be Active (0) or Hold (1)"
        );
        _updatePriceFromOracle(_eventId);
        _updateEventState(_eventId);
        
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    
    function isEventExist(uint256 _id) public view returns(bool) {
        if (eventRegistry.length <= _id) {
            return false;
        } else {

          return bool(eventRegistry[_id].expirationTime > 0);    
        }
        
    }
    
    function getEvent(uint256 _id) public view returns(GamblingEvent memory) {
        return eventRegistry[_id];
    }

    function getEventCount() public view returns(uint256) {
        return eventRegistry.length;
    }

    function isWinWithAmount(
        uint256 _eventId, 
        uint8 _outcomeIndex, 
        uint256 _betAmount
    ) 
        external 
        returns (bool, uint256) 
    {
        GamblingEvent memory e = eventRegistry[_eventId];
        require(e.state == EventState.Finished, "Not Finished yet");
        Outcome memory o = e.outcome[_outcomeIndex];
        if (o.isWin) {
            // !!!!!!!!  define loss outcom weiraised
            // formula may differ for difrent GameEventType. For Binary - this is  
            uint256 loss = uint256(e.outcome[_outcomeIndex == 0 ? 1 : 0].weiRaised);
            uint256 winAmount = 
            (loss * WIN_DISTRIB_PERCENT / 100)  //Winners prize share 
            * (_betAmount * 1e6 / uint256(o.weiRaised))  //bet's weight in all from this outcome. 1e6 -scale denominator
            / 1e6; //devide  scale denominator
            //Lets define Win Amount
            return (true, winAmount);
        } else {
            return (false, 0);
        }

    }

    function comparePrice(CompareSign _compareSign, int256 _outcomePrice, int256 _oraclePrice) external pure returns (bool) {
        return  _compare(_compareSign, _outcomePrice, _oraclePrice); 
    }
  
    //////////////////////////////////////////////////////////////
    ////////// Internals                                    //////
    //////////////////////////////////////////////////////////////
    function _updateEventState(uint256 _eventId) internal {
        require(
            eventRegistry[_eventId].state != EventState.Finished,
            "Event is Finished"
        );
        GamblingEvent storage e = eventRegistry[_eventId];
        if  (
              eventRegistry[_eventId].orderDeadLineTime <= block.timestamp &&
              eventRegistry[_eventId].expirationTime > block.timestamp
            ) 
            {
                //Just update eventstate
                if (e.outcome[0].betCount == 0 && e.outcome[1].betCount == 0) {
                    e.state = EventState.Canceled;    
                } else {
                    e.state = EventState.Hold;    
                }
            }  
        else if 
            (
                eventRegistry[_eventId].expirationTime < block.timestamp
            )
            {
                if (e.outcome[0].betCount == 0 && e.outcome[1].betCount == 0) {
                    e.state = EventState.Canceled;    
                } else {
                    _updatePriceFromOracle(_eventId);
                    e.state = EventState.Finished;    
                }

            } 

    }

    function _updatePriceFromOracle(uint256 _eventId) internal {
        if  (
              eventRegistry[_eventId].expirationTime <= block.timestamp &&
              eventRegistry[_eventId].state != EventState.Finished
            ) {
                GamblingEvent storage e = eventRegistry[_eventId];
                int256 price = IBetPriceProvider(oracle).getLastPriceByPairName(
                    keccak256(abi.encodePacked(e.eventAssetSymbol))
                );
                if (e.oraclePrice == 0) { 
                    e.oraclePrice = price;
                    //Lets define which outcome(s) is(are) win
                    //for this w
                    for (uint8 i = 0; i < e.outcome.length; i ++) {
                        if (_compare(e.outcome[i].compare, e.outcome[i].expectedValue, e.oraclePrice) == true) {
                            e.outcome[i].isWin = true;
                        } else {
                            e.outcome[i].isWin = false;
                        }

                    }

                }   
            }

    }


    function _compare(
        CompareSign _compareSign, 
        int256 _outcomePrice, 
        int256 _oraclePrice
    ) 
        internal pure returns (bool) 
    {
        if (_compareSign == CompareSign.Equal) {
            return bool(_outcomePrice == _oraclePrice);
        
        } else if (_compareSign == CompareSign.MoreOrEqual) {
            return bool(_outcomePrice >= _oraclePrice);
        
        } else if (_compareSign == CompareSign.LessOrEqual) {
            return bool(_outcomePrice <= _oraclePrice);
        
        } else if (_compareSign == CompareSign.More) {
            return bool(_outcomePrice > _oraclePrice);
        
        } else if (_compareSign == CompareSign.Less) {
            return bool(_outcomePrice < _oraclePrice);
        
        } else if (_compareSign == CompareSign.NotEqual) {
            return bool(_outcomePrice != _oraclePrice);
        }

    }
}