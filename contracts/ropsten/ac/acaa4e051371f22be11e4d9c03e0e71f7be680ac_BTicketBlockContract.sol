pragma solidity ^0.4.24;

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

library TBdatasets {
    struct BusinessEvent {
        uint256 buEventId;
        uint256 businessId;
        address businessAddress;
        string buEventName;
        string buEventDescription;
        uint256 sellStart;
        uint256 sellEnd;
        uint256 buEventStart;
        uint256 buEventEnd;
        bool isEventFinished;
        bool isBuEvent;
    }
    
    struct Ticket {
        uint256 ticketId;
        uint256 buEventId;
        bytes32 ticketType;
        uint256 ticketPrice;
        uint256 minResell;
        uint256 maxResell;
        bytes32 seatPosition;
        string seatMap;
        //uint256 holderId;
        bool isSold;
        bool isTicket;
    }
    struct Holder {
        uint256 holderId;
        uint256 ticketId;
        bytes32 holderEthAddress;
        bytes32 holderName;
        bytes32 holderPhone;
        bool isHolder;
    }
}

contract BTicketBlockContract {
    enum PaymentType {CASH, CREDIT_OR_DEBIT, CRYPTOCURRENCY_ETH, CRYPTOCURRENCY_TOMO}
    address masterAddress;
    mapping(uint256 => TBdatasets.BusinessEvent) buEventMap;
    uint256 buEventMapSize;
    mapping(uint256 => TBdatasets.Ticket) ticketMap;
    uint256 ticketMapSize;
    mapping(uint256 => TBdatasets.Holder) holderMap;
    uint256 holderMapSize;

    constructor() public {
        masterAddress = msg.sender;
        buEventMapSize = 0;
        ticketMapSize = 0;
        holderMapSize = 0;
    }

    function addNewEventToBusiness(
        uint256 businessId,
        address businessAddress,
        string buEventName,
        string buEventDescription,
        uint256 sellStart,
        uint256 sellEnd,
        uint256 buEventStart,
        uint256 buEventEnd
        ) 
        public 
        returns(uint256) 
    {
        require(masterAddress == msg.sender, "Sender address not equals master address.");
        uint256 buEventId = buEventMapSize + 1;
        buEventMap[buEventId] = TBdatasets.BusinessEvent(buEventId, businessId, businessAddress, buEventName, buEventDescription,
                                                        sellStart, sellEnd, buEventStart, buEventEnd, false, true);
        buEventMapSize = buEventMapSize + 1;
        return buEventId;
    }

    function addNewTicket(
        uint256 buEventId,
        bytes32 ticketType,
        uint256 ticketPrice,
        uint256 minResell,
        uint256 maxResell,
        bytes32 seatPosition,
        string seatMap
        )
        public
        returns(uint256) 
    {
        TBdatasets.BusinessEvent memory currentBuEvent = buEventMap[buEventId];
        require(currentBuEvent.isBuEvent == false, "Current event is invalid.");
        require(currentBuEvent.isEventFinished, "Event is finished.");
        require(currentBuEvent.businessAddress == msg.sender, "Sender address not equals business address.");
        uint256 ticketId = ticketMapSize + 1;
        ticketMap[ticketId] = TBdatasets.Ticket(ticketId, buEventId, ticketType, ticketPrice, minResell, 
                                                maxResell, seatPosition, seatMap, false, true);
        ticketMapSize = ticketMapSize + 1;
        return ticketId;
    }

    function addNewOrUpdateHolder(
        uint256 ticketId,
        bytes32 holderEthAddress,
        bytes32 holderName,
        bytes32 holderPhone
        )
        private
        returns(uint256) 
    {
        TBdatasets.Ticket memory currentTicket = ticketMap[ticketId];
        require(currentTicket.isTicket == false, "Current ticket is invalid.");
        TBdatasets.BusinessEvent memory currentBuEvent = buEventMap[currentTicket.buEventId];
        require(currentBuEvent.isBuEvent == false, "Current event is invalid.");
        require(currentBuEvent.isEventFinished, "Event is finished.");

        if(currentTicket.isSold) {

        }
        uint256 holderId = holderMapSize + 1;
        holderMap[holderId] = TBdatasets.Holder(holderId, ticketId, holderEthAddress, holderName, holderPhone, true);

        return holderId;
    }

    function buyTicketByEth(
        uint256 ticketId,
        bytes32 holderEthAddress,
        bytes32 holderName,
        bytes32 holderPhone
        ) 
        public
        payable
    {
        TBdatasets.Ticket memory currentTicket = ticketMap[ticketId];
        require(currentTicket.isTicket == false, "Current ticket is invalid.");
        TBdatasets.BusinessEvent memory currentBuEvent = buEventMap[currentTicket.buEventId];
        require(currentBuEvent.isBuEvent == false, "Current event is invalid.");
        require(currentBuEvent.isEventFinished, "Event is finished.");
        require(currentTicket.ticketPrice == SafeMath.div(msg.value, 1000000000000000000), "Ether value is not equal ticket price.");

        addNewOrUpdateHolder(ticketId, holderEthAddress, holderName, holderPhone);
    }

    function buyTicketByOther(
        uint256 ticketId,
        bytes32 holderEthAddress,
        bytes32 holderName,
        bytes32 holderPhone
        ) 
        public
    {
        TBdatasets.Ticket memory currentTicket = ticketMap[ticketId];
        require(currentTicket.isTicket == false, "Current ticket is invalid.");
        TBdatasets.BusinessEvent memory currentBuEvent = buEventMap[currentTicket.buEventId];
        require(currentBuEvent.isBuEvent == false, "Current event is invalid.");
        require(currentBuEvent.isEventFinished, "Event is finished.");
        addNewOrUpdateHolder(ticketId, holderEthAddress, holderName, holderPhone);
    }
}