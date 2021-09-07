pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

import "./Eventable.sol";

contract EventLifeCycle {
    
    address public _governanceAddress;
    address public _secondaryPoolAddress;
    address public _oracleAddress;
    uint public _lastEventId;
    GameEvent public _queuedEvent;
    GameEvent public _ongoingEvent;
    bool eventIsInProgress = false;
    
    event GovernanceAddressChanged(address);
    event OracleAddressChanged(address);
    event SecondaryPoolAddressChanged(address);
    event GameEventStarted(uint time, uint eventId);
    event GameEventEnded(int8 result, uint eventId);
    event NewGameEventAdded(uint256 priceChangePercent, uint eventStartTimeExpected, uint eventEndTimeExpected,
        string blackTeam, string whiteTeam, string eventType, string eventSeries, string eventName, uint eventid);
        
    Eventable _secondaryPool;
    
    constructor(
        address governanceAddress,
        address oracleAddress,
        address secondarypoolAddress
        ) {
            _governanceAddress = governanceAddress;
            _oracleAddress = oracleAddress;
            _secondaryPoolAddress = secondarypoolAddress;
            _secondaryPool = Eventable(_secondaryPoolAddress);
        }
        
    modifier onlyGovernance () {
        require (_governanceAddress == msg.sender, "Caller should be Governance");
        _;
    }
    
    modifier onlyOracle () {
        require (_oracleAddress == msg.sender, "Caller should be Oracle");
        _;
    }
    
    struct GameEvent {
        uint256 priceChangePart;       // in percent
        uint eventStartTimeExpected; // in seconds since 1970
        uint eventEndTimeExpected;   // in seconds since 1970
        string blackTeam;
        string whiteTeam;
        string eventType;
        string eventSeries;
        string eventName;
        uint eventid;
    }
    
    function addNewEvent(
        uint256 priceChangePart_,   
        uint eventStartTimeExpected_,
        uint eventEndTimeExpected_,
        string calldata blackTeam_,
        string calldata whiteTeam_,
        string calldata eventType_,
        string calldata eventSeries_,
        string calldata eventName_) 
        external 
        onlyOracle
        returns (uint) {
            
            _lastEventId = _lastEventId +1;
            
            _queuedEvent = GameEvent({
                priceChangePart: priceChangePart_,
                eventStartTimeExpected: eventStartTimeExpected_, // in seconds since 1970
                eventEndTimeExpected: eventEndTimeExpected_,      // in seconds since 1970
                blackTeam: blackTeam_,
                whiteTeam: whiteTeam_,
                eventType: eventType_,
                eventSeries: eventSeries_,
                eventName: eventName_,
                eventid: _lastEventId
                });
            
        emit NewGameEventAdded(
            _queuedEvent.priceChangePart, 
            _queuedEvent.eventStartTimeExpected, 
            _queuedEvent.eventEndTimeExpected,
            _queuedEvent.blackTeam, 
            _queuedEvent.whiteTeam, 
            _queuedEvent.eventType, 
            _queuedEvent.eventSeries, 
            _queuedEvent.eventName, 
            _queuedEvent.eventid
            );
            
        return _lastEventId;
        }
        
    function startEvent() external onlyOracle {
        require(eventIsInProgress == false, "Finish previous event to start new event");
        _ongoingEvent = _queuedEvent;
        _secondaryPool.submitEventStarted(_ongoingEvent.priceChangePart);
        eventIsInProgress = true;
        emit GameEventStarted(block.timestamp, _ongoingEvent.eventid);
    }
    
    /**
     * Receive event results. Receives result of an event in value between -1 and 1. -1 means 
     * Black won,1 means white-won, 0 means draw. 
     */
    function endEvent(int8 _result) external onlyOracle {
    require(eventIsInProgress == true, "There is no ongoing event to finish");
     _secondaryPool.submitEventResult(_result);
     emit GameEventEnded(_result, _ongoingEvent.eventid);
     eventIsInProgress = false;
    }
    
    function changeGovernanceAddress(
        address governanceAddress) 
    public 
    onlyGovernance {
        require (governanceAddress != address(0), "New governance address should be not null");
        _governanceAddress = governanceAddress;
        emit GovernanceAddressChanged(governanceAddress);
    }
    
    function changeOracleAddress(
        address oracleAddress) 
    public 
    onlyGovernance {
        require (oracleAddress != address(0), "New oracle address should be not null");
        _oracleAddress = oracleAddress;
        emit OracleAddressChanged(oracleAddress);
    }
    
    function changeSecondaryPoolAddress(
        address poolAddress) 
    public 
    onlyGovernance {
        require (poolAddress != address(0), "New pool address should be not null");
        _secondaryPoolAddress = poolAddress;
        emit SecondaryPoolAddressChanged(poolAddress);
    }
        
}