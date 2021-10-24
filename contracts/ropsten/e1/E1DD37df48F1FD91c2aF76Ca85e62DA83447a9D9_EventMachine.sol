//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EventMachine {
    event CreateEvent(
        address indexed creator,
        uint256 eventId,
        uint256 eventPrice,
        uint256 eventDate
    );
    event CancelEvent(address indexed creator, uint256 eventId);
    event BuyTicket(address indexed buyer, uint256 eventId);
    event CancelTicket(address indexed buyer, uint256 eventId);
    event UseTicket(address indexed buyer, uint256 eventId);

    enum EventAudienceState {
        empty,
        bought,
        canceled,
        redeemed
    }

    mapping(uint256 => mapping(address => EventAudienceState))
        private eventAudience;
    mapping(uint256 => uint256) private eventPrices;
    mapping(uint256 => address) private eventOwners;
    mapping(uint256 => bool) private canceledEvents;
    mapping(uint256 => uint256) private eventDates;
    mapping(address => mapping(uint256 => uint256)) private balanceSheet;
    uint256 private currentEventId;

    function createEvent(uint256 ticketPrice, uint256 eventDate) public {
        currentEventId += 1;
        eventOwners[currentEventId] = msg.sender;
        eventPrices[currentEventId] = ticketPrice;
        eventDates[currentEventId] = eventDate;

        emit CreateEvent(msg.sender, currentEventId, ticketPrice, eventDate);
    }

    function cancelEvent(uint256 eventId) public {
        require(eventOwners[eventId] == msg.sender, "must be owner of event");
        require(canceledEvents[eventId] == false, "event already cancelled");

        canceledEvents[eventId] = true;

        emit CancelEvent(msg.sender, currentEventId);
    }

    function buyTicket(uint256 eventId) public payable {
        require(eventId <= currentEventId, "event must exist");
        require(canceledEvents[eventId] == false, "event must not be canceled");
        require(msg.value == eventPrices[eventId], "ticket price not matching");
        require(block.timestamp < eventDates[eventId], "event is in the past");
        require(
            eventAudience[eventId][msg.sender] == EventAudienceState.empty,
            "already bought ticket once"
        );

        eventAudience[eventId][msg.sender] = EventAudienceState.bought;
        balanceSheet[eventOwners[eventId]][eventId] += msg.value;
        emit BuyTicket(msg.sender, eventId);
    }

    function cancelTicket(uint256 eventId) public {
        require(eventId <= currentEventId, "event must exist");
        require(block.timestamp < eventDates[eventId], "event is in the past");
        require(
            eventAudience[eventId][msg.sender] == EventAudienceState.bought,
            "ticket needs to be bought"
        );

        eventAudience[eventId][msg.sender] = EventAudienceState.canceled;

        if (canceledEvents[eventId] == false) {
            uint256 refund = (eventPrices[eventId] * 75) / 100;
            // refund 75% of the ticket price to the msg sender
            balanceSheet[eventOwners[eventId]][eventId] -= refund;

            payable(msg.sender).transfer(refund);
        } else {
            // refund 100% of the ticket price to the msg sender
            balanceSheet[eventOwners[eventId]][eventId] -= eventPrices[eventId];

            payable(msg.sender).transfer(eventPrices[eventId]);
        }

        emit CancelTicket(msg.sender, eventId);
    }

    function useTicket(uint256 eventId) public {
        require(eventId <= currentEventId, "event must exist");
        require(canceledEvents[eventId] == false, "event must not be canceled");
        require(block.timestamp >= eventDates[eventId], "event not started");

        eventAudience[eventId][msg.sender] = EventAudienceState.redeemed;

        emit UseTicket(msg.sender, eventId);
    }

    function getBalance(address addr, uint256 eventId) public view returns (uint256) {
        return balanceSheet[addr][eventId];
    }

    function isRedeemed(uint256 eventId, address addr) public view returns (bool) {
        return eventAudience[eventId][addr] == EventAudienceState.redeemed;
    }

    function withdrawFunds(uint256 eventId) public {
        require(msg.sender == eventOwners[eventId], "must own event");
        //this can lead to stuck funds if a user cancelled the ticket before the event was cancelled
        //maybe this could be a revenue source but for now we are leaving the funds stuck
        require(canceledEvents[eventId] == false, "event must not be canceled");

        uint256 funds = balanceSheet[msg.sender][eventId];
        require(funds > 0, "need to have funds");
        require(block.timestamp >= eventDates[eventId], "event is in the past");

        balanceSheet[msg.sender][eventId] = 0;

        payable(msg.sender).transfer(funds);
    }
}