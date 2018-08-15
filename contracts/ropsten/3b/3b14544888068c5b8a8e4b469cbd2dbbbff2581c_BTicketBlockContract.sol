pragma solidity ^0.4.24;

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
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
        uint256[] ticketIdList;
        TicketStructureElement[] ticketStructure;
    }

    struct TicketStructureElement {
        bytes32 ticketType;
        uint256 quantity;
        uint256 maxQuantityPerOne;
        uint256 ticketPrice;
        uint256 minResell;
        uint256 maxResell;
    }
    
    struct Ticket {
        uint256 ticketId;
        uint256 buEventId;
        bytes32 ticketType;
        uint256 ticketPrice;
        uint256 minResell;
        uint256 maxResell;
        bytes32 seatPosition;
        bytes32 holderId;
        bytes32 holderEthAddress;
        bytes32 holderName;
        bytes32 holderPhone;
        bool isSold;
        bool isTicket;
    }
}

contract BTicketBlockContract {
    enum PaymentType {CASH, CREDIT_OR_DEBIT, CRYPTOCURRENCY_ETH, CRYPTOCURRENCY_TOMO}
    address masterAddress;
    mapping(uint256 => TBdatasets.BusinessEvent) buEventMap;
    uint256 buEventMapSize;
    mapping(uint256 => TBdatasets.Ticket) ticketMap;
    uint256 ticketMapSize;

    constructor() public {
        masterAddress = msg.sender;
        buEventMapSize = 0;
        ticketMapSize = 0;
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

        buEventMap[buEventId].buEventId = buEventId;
        buEventMap[buEventId].businessId = businessId;
        buEventMap[buEventId].businessAddress = businessAddress;
        buEventMap[buEventId].buEventName = buEventName;
        buEventMap[buEventId].buEventDescription = buEventDescription;
        buEventMap[buEventId].sellStart = sellStart;
        buEventMap[buEventId].sellEnd = sellEnd;
        buEventMap[buEventId].buEventStart = buEventStart;
        buEventMap[buEventId].buEventEnd = buEventEnd;
        buEventMap[buEventId].isEventFinished = false;
        buEventMap[buEventId].isBuEvent = true;
        buEventMap[buEventId].ticketIdList = new uint256[](0);

        buEventMapSize = buEventMapSize + 1;
        return buEventId;
    }

    function updateTicketStructure(
        uint256 buEventId,
        bytes32[] ticketTypeList,
        uint256[] ticketTypeQuantityList,
        uint256[] maxQuantityPerOneList,
        uint256[] ticketPriceList,
        uint256[] minResellList,
        uint256[] maxResellList
        )
        public 
        returns(uint256)
    {
        require(masterAddress == msg.sender, "Sender address not equals master address.");
        require(ticketTypeList.length > 0, "Size of ticket type must greater than 0.");
        require(ticketTypeList.length == ticketTypeQuantityList.length, "Each list must have same size.");
        require(ticketTypeList.length == maxQuantityPerOneList.length, "Each list must have same size.");
        require(ticketTypeList.length == ticketPriceList.length, "Each list must have same size.");
        require(ticketTypeList.length == minResellList.length, "Each list must have same size.");
        require(ticketTypeList.length == maxResellList.length, "Each list must have same size.");

        for(uint32 i = 0; i < ticketTypeList.length; i++) {
            bytes32 tmpTicketType = ticketTypeList[i];
            buEventMap[buEventId].ticketStructure.push(TBdatasets.TicketStructureElement(tmpTicketType, ticketTypeQuantityList[i], maxQuantityPerOneList[i], 
                                                                                        ticketPriceList[i], minResellList[i], maxResellList[i]));
        }
        return buEventId;
    }

    function addNewTicket(
        uint256 buEventId,
        bytes32 ticketType,
        uint256 ticketPrice,
        uint256 minResell,
        uint256 maxResell
        )
        private
        returns(uint256) 
    {
        TBdatasets.BusinessEvent memory currentBuEvent = buEventMap[buEventId];
        require(currentBuEvent.isBuEvent == false, "Current event is invalid.");
        require(currentBuEvent.isEventFinished, "Event is finished.");
        require(currentBuEvent.businessAddress == msg.sender, "Sender address not equals business address.");

        uint256 ticketId = ticketMapSize + 1;
        ticketMap[ticketId] = TBdatasets.Ticket(ticketId, buEventId, ticketType, ticketPrice, minResell, 
                                                maxResell, "", "", "", "", "", false, true);
        ticketMapSize = ticketMapSize + 1;
        buEventMap[buEventId].ticketIdList.push(ticketId);
        return ticketId;
    }

    function addAllNewTicket(
        uint256 buEventId,
        bytes32[] ticketType,
        uint256[] ticketPrice,
        uint256[] minResell,
        uint256[] maxResell
        )
        public
        returns(uint256)
    {
        return 0;
    }

    function updateHolder(
        uint256 ticketId,
        bytes32 holderId,
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

        currentTicket.holderEthAddress = holderEthAddress;
        currentTicket.holderName = holderName;
        currentTicket.holderPhone = holderPhone;
        currentTicket.holderId = holderId;
        currentTicket.isSold = true;

        ticketMap[ticketId] = currentTicket;

        return currentTicket.ticketId;
    }

    function buyTicketByEth(
        uint256 ticketId,
        bytes32 holderId,
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

        updateHolder(ticketId, holderId, holderEthAddress, holderName, holderPhone);
    }

    function buyTicketByOther(
        uint256 ticketId,
        bytes32 holderId,
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
        updateHolder(ticketId, holderId, holderEthAddress, holderName, holderPhone);
    }

    function getTicketByHolderId(bytes32 holderId) 
        public 
        returns(uint256, uint256, bytes32, uint256, uint256, uint256, bytes32, bytes32, bytes32, bytes32)
    {
        return (0, 0, "", 0, 0, 0, "", "", "", "");
    }
}