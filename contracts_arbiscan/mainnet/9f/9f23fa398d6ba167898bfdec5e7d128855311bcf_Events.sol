/**
 *Submitted for verification at arbiscan.io on 2021-10-12
*/

// Events contract for deployment on optimism
// Audit report available at https://www.tkd-coop.com/files/audit.pdf

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;
    mapping(address => bool) public admins;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, "Only Creator May Call");
        _;
    }

    modifier onlyADMINS() {
        require(admins[msg.sender] == true);
        _;
    }

    //Admins are contracts or addresses that have write access
    function addAdmin(address _newAdmin) public onlyCREATOR {
        if (admins[_newAdmin] == false) {
            admins[_newAdmin] = true;
        }
    }

    function removeAdmin(address _oldAdmin) public onlyCREATOR {
        if (admins[_oldAdmin] == true) {
            admins[_oldAdmin] = false;
        }
    }

    // Constructor
    constructor() {
        creatorAddress = payable(msg.sender);
    }
}

//Interface to TAC Contract
abstract contract ITAC {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);

    function balanceOf(address account) external view virtual returns (uint256);
}

abstract contract ICoopData {
    function recordEventMatch(
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        address _referee
    ) public virtual returns (uint64);
}

contract Events is AccessControl {
    /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////

    uint16 public numEvents = 0; //number of events created
    uint256 public eventHostingCost = 100000000000000000000; //cost to host an event in Hwangs.

    //Main data structure to hold info about an event
    struct Event {
        address promoter; //the person who holds the tournament
        string eventName;
        uint64 time;
        uint64 eventId;
        uint16 allowedMatches;
        uint64[] matches;
    }

    Event[] allEvents;

    // Mapping storing which users are authorized to act as staff for which event.
    // A user can only be authorized for one event at a time
    mapping(address => uint64) public tournamentStaff;

    address public TACContract = 0xABa8ace37f301E7a3A3FaD44682C8Ec8DC2BD18A;
    address public CoopDataContract =
        0xABa8ace37f301E7a3A3FaD44682C8Ec8DC2BD18A;

    /////////////////////////////////////////////////////////CONTRACT CONTROL FUNCTIONS //////////////////////////////////////////////////

    function changeParameters(
        uint256 _eventHostingCost,
        address _TACContract,
        address _CoopDataContract
    ) external onlyCREATOR {
        eventHostingCost = _eventHostingCost;
        TACContract = _TACContract;
        CoopDataContract = _CoopDataContract;
    }

    function getParameters() external view returns (uint256 _eventHostingCost) {
        _eventHostingCost = eventHostingCost;
    }

    /////////////////////////////////////////////////////////EVENT FUNCTIONS  //////////////////////////////////////////////////

    function hostEvent(uint64 startTime, string memory eventName) public {
        Event memory newEvent;

        ITAC TAC = ITAC(TACContract);
        require(
            TAC.balanceOf(msg.sender) >= eventHostingCost,
            "You need to have more TAC to open an event. "
        );
        TAC.transferFrom(msg.sender, creatorAddress, eventHostingCost);
        newEvent.promoter = msg.sender;
        newEvent.eventName = eventName;
        newEvent.time = startTime;
        newEvent.eventId = numEvents;
        newEvent.allowedMatches = 0;
        allEvents.push(newEvent);
        numEvents += 1;
    }

    function getEvent(uint64 _eventId)
        public
        view
        returns (
            address promoter,
            uint64 time,
            uint64 eventId,
            string memory eventName,
            uint16 allowedMatches
        )
    {
        Event memory eventToGet = allEvents[_eventId];
        promoter = eventToGet.promoter;
        time = eventToGet.time;
        eventName = eventToGet.eventName;
        eventId = eventToGet.eventId;
        allowedMatches = eventToGet.allowedMatches;
    }

    function approveEvent(uint64 _eventId, uint16 _numMatches)
        public
        onlyADMINS
    {
        // Function to allow an event host to approve a specified number of matches.
        allEvents[_eventId].allowedMatches = _numMatches;
    }

    //Function a tournament promoter can call to delegate staff to record matches.
    function addStaff(uint64 _eventId, address _newStaff) public {
        //Check that the tournament promoter is the caller
        require(
            msg.sender == allEvents[_eventId].promoter,
            "Only the promoter can add staff"
        );
        tournamentStaff[_newStaff] = _eventId;
    }

    function decrementAllowedMatches(uint64 _eventId) public {
        require(msg.sender == CoopDataContract, "Only Coop data can call");
        allEvents[_eventId].allowedMatches -= 1;
    }

    function recordEventMatch(
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        address _referee,
        uint64 _eventId
    ) public {
        require(
            allEvents[_eventId].promoter == msg.sender ||
                tournamentStaff[msg.sender] == _eventId,
            "Only the promoter or staff may record"
        );

        ICoopData coopData = ICoopData(CoopDataContract);

        uint64 matchId;
        (matchId) = coopData.recordEventMatch(
            _winner,
            _winnerPoints,
            _loser,
            _loserPoints,
            _referee
        );

        if (matchId > 0) {
            allEvents[_eventId].matches.push(matchId);
        }
    }
}