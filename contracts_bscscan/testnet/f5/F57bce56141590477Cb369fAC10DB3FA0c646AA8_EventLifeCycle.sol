/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// File: BWT/Eventable.sol

pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

interface Eventable {
    
    function submitEventStarted(uint256 currentEventPriceChangePercent) external; 
    function submitEventResult(int8 _result) external;
    
}
// File: BWT/EventLifeCycle.sol

pragma solidity ^0.7.4;


contract EventLifeCycle {
    
    address public _governanceAddress;
    address public _secondaryPoolAddress;
    address public _oracleAddress;
    GameEvent public _queuedEvent = GameEvent(0,0,0,"q","q","q","q","q",0);
    GameEvent public _ongoingEvent = GameEvent(0,0,0,"q","q","q","q","q",0);
    bool eventIsInProgress = false;
    
    event GovernanceAddressChanged(address);
    event OracleAddressChanged(address);
    event SecondaryPoolAddressChanged(address);
    event GameEventStarted(uint time, uint eventId);
    event GameEventEnded(int8 result, uint eventId);
        
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
        uint eventId;
    }
    
    function addNewEvent(
        uint256 priceChangePart_,
        uint eventStartTimeExpected_,
        uint eventEndTimeExpected_,
        string calldata blackTeam_,
        string calldata whiteTeam_,
        string calldata eventType_,
        string calldata eventSeries_,
        string calldata eventName_,
        uint eventId_) public onlyOracle {
            
        _queuedEvent.priceChangePart = priceChangePart_;
        _queuedEvent.eventStartTimeExpected = eventStartTimeExpected_;
        _queuedEvent.eventEndTimeExpected = eventEndTimeExpected_;
        _queuedEvent.blackTeam = blackTeam_;
        _queuedEvent.whiteTeam = whiteTeam_;
        _queuedEvent.eventType = eventType_;
        _queuedEvent.eventSeries = eventSeries_;
        _queuedEvent.eventName = eventName_;
        _queuedEvent.eventId = eventId_;

    }
        
    function startEvent() public onlyOracle returns (uint) {
        require(
            eventIsInProgress == false,
            "FINISH PREVIOUS EVENT TO START NEW EVENT"
        );
        _ongoingEvent = _queuedEvent;
        _secondaryPool.submitEventStarted(_ongoingEvent.priceChangePart);
        eventIsInProgress = true;
        emit GameEventStarted(block.timestamp, _ongoingEvent.eventId);
        return _ongoingEvent.eventId;
    }
    
    function addAndStartEvent(
        uint256 priceChangePart_, // in 0.0001 parts percent of a percent dose
        uint eventStartTimeExpected_,
        uint eventEndTimeExpected_,
        string calldata blackTeam_,
        string calldata whiteTeam_,
        string calldata eventType_,
        string calldata eventSeries_,
        string calldata eventName_,
        uint eventId_
    ) external onlyOracle returns(uint) {        
        require(
            eventIsInProgress == false,
            "FINISH PREVIOUS EVENT TO START NEW EVENT"
        );
        addNewEvent(
        priceChangePart_,
        eventStartTimeExpected_,
        eventEndTimeExpected_,
        blackTeam_,
        whiteTeam_,
        eventType_,
        eventSeries_,
        eventName_,
        eventId_);
        
        startEvent();
        
        return eventId_;
    }
    
    /**
     * Receive event results. Receives result of an event in value between -1 and 1. -1 means 
     * Black won,1 means white-won, 0 means draw. 
     */
    function endEvent(int8 _result) external onlyOracle {
        require(eventIsInProgress == true, "There is no ongoing event to finish");
        _secondaryPool.submitEventResult(_result);
        emit GameEventEnded(_result, _ongoingEvent.eventId);
        eventIsInProgress = false;
    }
    
    function changeGovernanceAddress(address governanceAddress) public onlyGovernance {
        require (governanceAddress != address(0), "New governance address should be not null");
        _governanceAddress = governanceAddress;
        emit GovernanceAddressChanged(governanceAddress);
    }
    
    function changeOracleAddress(address oracleAddress) public onlyGovernance {
        require (oracleAddress != address(0), "New oracle address should be not null");
        _oracleAddress = oracleAddress;
        emit OracleAddressChanged(oracleAddress);
    }
    
    function changeSecondaryPoolAddress(address poolAddress) public onlyGovernance {
        require (poolAddress != address(0), "New pool address should be not null");
        _secondaryPoolAddress = poolAddress;
        emit SecondaryPoolAddressChanged(poolAddress);
    }
        
}