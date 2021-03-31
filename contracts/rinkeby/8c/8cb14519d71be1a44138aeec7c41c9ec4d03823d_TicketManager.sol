pragma solidity ^0.8.0;

import "ERC20.sol";

contract TicketManager is ERC20
{
    TicketedEvent[] _ticketedEventArr;
    Ticket[] _ticketsArr;

    struct TicketedEvent{
        uint eventID;
        string eventName;
        uint eventUnixTime;
        uint totalTicketSupply;
        uint totalTicketsPurchased;
        uint openDate;
        uint closeDate;
        uint ticketPrice;
        address eventManagerAddress;
        address receivablePaymentAddress;
        bool ticketsTransferable;
        bool cancelled;
    }
    struct Ticket
    {
        uint eventID;
        uint ticketID;
        address currentOwner;
        bool used;
        bool transferable;
        bool refunded;
    }
    constructor() ERC20("TicketToken", "TKT", 1000000, 0x38565513e78dBBb06614268cF3837032822120F2, 5) public { }
    
    function createTicketedEvent(string memory _eventName, uint _eventTime, uint _totalTicketSupply, uint _totalTicketsPurchased, uint _openDate, uint _closeDate, uint _ticketPrice, address _eventManagerAddress, address _receivablePaymentAddress, bool _ticketsTransferable) public virtual returns (bool)
    {
        uint eventID = getTicketedEventLength();
        TicketedEvent memory tEvent = TicketedEvent({ eventID:eventID, 
                                                    eventName:_eventName, 
                                                    eventUnixTime:_eventTime, 
                                                    totalTicketSupply:_totalTicketSupply, 
                                                    totalTicketsPurchased:_totalTicketsPurchased,
                                                    openDate:_openDate, 
                                                    closeDate:_closeDate,
                                                    ticketPrice:_ticketPrice,
                                                    eventManagerAddress:_eventManagerAddress,
                                                    receivablePaymentAddress:_receivablePaymentAddress,
                                                    ticketsTransferable:_ticketsTransferable,
                                                    cancelled:false
                                                    });
                                                    
        _ticketedEventArr.push(tEvent);
        
        //broadcast that event was created
        emit EventCreated(_msgSender(), eventID);
                                                    
        return true;
    }

    function buyTicket(address purchaseForAddr, uint eventID) public virtual returns(bool)
    {
            require(balanceOf(_msgSender()) >=  _ticketedEventArr[eventID].ticketPrice, 
                    "TicketManager: Insufficient funds to purchase ticket.");
            require(_ticketedEventArr[eventID].totalTicketsPurchased < _ticketedEventArr[eventID].totalTicketSupply,
                    "TicketManager: No tickets remaining.");
            require(!getEventCancelledStatus(eventID),
                    "TicketManager: Event has been cancelled and tickets are no longer available");

            //subtract balance from sender, however, allow them to buy ticket for any address
          //  balanceOf(_msgSender()) -= _ticketedEventArr[eventID].ticketPrice;
            _transfer(_msgSender(), _ticketedEventArr[eventID].receivablePaymentAddress, _ticketedEventArr[eventID].ticketPrice);
            uint ticketID = _ticketsArr.length;
            _ticketsArr.push(Ticket(eventID, ticketID, purchaseForAddr, false, _ticketedEventArr[eventID].ticketsTransferable, false));
            
            //ticket purchased event broadcast:
            emit TicketPurchased(purchaseForAddr, ticketID, eventID, getEventTicketsRemaining(eventID));
            return true;

    }
    function transferTicket(address to, uint ticketID) public virtual returns (bool)
    {
        require(_ticketsArr[ticketID].currentOwner == _msgSender(),
                "TicketManager: You must own this ticket to be able to transfer it.");
        require(_ticketsArr[ticketID].transferable,
                "TicketManager: Ticket is not transferable.");
        _ticketsArr[ticketID].currentOwner = to;
        return true;
    }
    function setTicketedEventCancelStatus(uint eventID, bool cancelled) public virtual returns(bool)
    {
        require(_msgSender() == _ticketedEventArr[eventID].eventManagerAddress,
                "TicketManager: Only the event manager may cancel the event");
        _ticketedEventArr[eventID].cancelled = cancelled;
        return true;
    }
    function refundTicket(uint ticketID, uint refundAmount) public virtual returns(bool)
    {
        uint eventID = getTicketEventID(ticketID);
        require(balanceOf(getReceivablePaymentAddress(eventID)) >= refundAmount,
                "TicketManager: Event payment address insufficient funds. Please contact the event manager.");
        require(_msgSender() == getEventManagerAddress(eventID),
                "TicketManager: Only the event manager may issue a refund.");
        _transfer(getTicketOwner(ticketID), _msgSender(), refundAmount);
        setTicketAsRefunded(ticketID);
        emit TicketRefunded(_msgSender(), ticketID);
        return true;
    }
    function getTicketedEventLength() public view virtual returns(uint count)
    {
        return _ticketedEventArr.length;
    }
    function getTicketEventID(uint ticketID) public view virtual returns (uint )
    {
        return _ticketsArr[ticketID].eventID;
    }
    function getTicketOwner(uint ticketID) public view virtual returns (address )
    {
        return _ticketsArr[ticketID].currentOwner;
    }
    function getTicketRefundedStatus(uint ticketID) public view virtual returns(bool)
    {
        return _ticketsArr[ticketID].refunded;
    }
    function isTicketUsed(uint ticketID) public view virtual returns (bool)
    {
        return _ticketsArr[ticketID].used;
    }
    function getIsTicketTransferable(uint ticketID) public view virtual returns(bool)
    {
        return _ticketsArr[ticketID].transferable;
    }
    function useTicket(uint ticketID) public virtual returns (bool)
    {
       _ticketsArr[ticketID].used = true;
       return true;
    }
    function setTicketAsRefunded(uint ticketID) public virtual returns (bool)
    {
        _ticketsArr[ticketID].refunded = true;
        return true;
    }
    function getEventName(uint eventID) public view virtual returns(string memory)
    {
        return _ticketedEventArr[eventID].eventName;
    }
    function getEventDate(uint eventID) public view virtual returns(uint)
    {
        return _ticketedEventArr[eventID].eventUnixTime;
    }
    function getEventOpenDate(uint eventID) public view virtual returns(uint)
    {
        return _ticketedEventArr[eventID].openDate;
    }
    function getEventCloseDate(uint eventID) public view virtual returns(uint)
    {
       return _ticketedEventArr[eventID].closeDate; 
    }
    function getEventTotalTicketSupply(uint eventID) public view virtual returns(uint)
    {
        return _ticketedEventArr[eventID].totalTicketSupply;
    }
    function getEventTicketsRemaining(uint eventID) public view virtual returns(uint)
    {
        return _ticketedEventArr[eventID].totalTicketsPurchased;
    }
    function getEventPrice(uint eventID) public view virtual returns(uint)
    {
        return _ticketedEventArr[eventID].ticketPrice;
    }
    function getEventManagerAddress(uint eventID) public view virtual returns(address)
    {
        return _ticketedEventArr[eventID].eventManagerAddress;
    }
    function getReceivablePaymentAddress(uint eventID) public view virtual returns(address)
    {
        return _ticketedEventArr[eventID].receivablePaymentAddress;
    }
    function getEventTicketsTransferable(uint eventID) public view virtual returns(bool)
    {
        return _ticketedEventArr[eventID].ticketsTransferable;
    }
    function getEventCancelledStatus(uint eventID) public view virtual returns(bool)
    {
        return _ticketedEventArr[eventID].cancelled;
    }
    event TicketPurchased(address indexed purchaser, uint ticketID, uint eventID, uint ticketsRemaining);
    event EventCreated(address indexed createdBy, uint eventID);
    event TicketRefunded(address indexed refundedBy, uint ticketID);
}