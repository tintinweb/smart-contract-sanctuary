pragma solidity ^0.4.23;

contract BookingFactory {
    address public owner;

    mapping(uint128 => bool) private bookingIds;

    uint32 private feePpm; // PPM = parts per million
    address private feeBeneficiary;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function createBooking(
        uint128 _listingId,
        uint128 _bookingId,
        uint32 _dateFrom,
        uint32 _dateTo,
        uint256 _price,
        address _host
    ) public payable returns (Booking booking) {
        require(!bookingIds[_bookingId]);

        bookingIds[_bookingId] = true;
        
        uint payment = msg.value;
        uint change = 0;
        if(msg.value > 0) {
            change = msg.value > _price ? msg.value - _price : msg.value;
            payment -= change;
        }
        
        booking = (new Booking).value(payment)(_listingId, _bookingId, _dateFrom, _dateTo, _price, _host, msg.sender, feePpm, feeBeneficiary);
        
        emit BookingCreated(booking, _listingId, _bookingId);

        if(change > 0)
            msg.sender.transfer(change);
        
        return booking;
    }

    function setFee(uint32 _feePpm, address _feeBeneficiary) public onlyOwner {
        feePpm = _feePpm;
        feeBeneficiary = _feeBeneficiary;
    }

    event BookingCreated (
        address indexed bookingContractAddress,
        uint128 indexed listingId,
        uint128 indexed bookingId
    );
}

contract Booking {

    uint128 public listingId;
    uint128 public bookingId;
    uint32 public dateFrom;
    uint32 public dateTo;
    uint256 public price;
    address public host;
    address public guest;
    uint32 private feePpm; // PPM = parts per million
    address private feeBeneficiary;
    address public creator;
    Status public status;

    uint paid;

    bool private occupancyConfirmedByGuest = false;
    bool private occupancyConfirmedByHost = false;
    bool private ejectmentConfirmedByGuest = false;
    bool private ejectmentConfirmedByHost = false;

    enum Status {New, Requested, Confirmed, Rejected, Cancelled, Booked, Started, Finished}

    event StatusChanged (
        Status indexed _from,
        Status indexed _to
    );

    modifier onlyGuest {
        require(msg.sender == guest);
        _;
    }

    modifier onlyHost {
        require(msg.sender == host);
        _;
    }

    modifier onlyParticipant {
        require(msg.sender == guest || msg.sender == host);
        _;
    }

    constructor(uint128 _listingId,
                uint128 _bookingId,
                uint32 _dateFrom,
                uint32 _dateTo,
                uint256 _price,
                address _host,
                address _guest,
                uint32 _feePpm,
                address _feeBeneficiary
    ) public payable {
        require(_dateFrom < _dateTo);
        require(_host != _guest);

        listingId = _listingId;
        bookingId = _bookingId;

        dateFrom = _dateFrom;
        dateTo = _dateTo;
        price = _price;
        host = _host;
        guest = _guest;
        feePpm = _feePpm;
        feeBeneficiary = _feeBeneficiary;

        paid = msg.value;

        creator = msg.sender;
        status = Status.New;

        setStatus(Status.Confirmed);
    }

    function setStatus(Status newStatus) private {
        emit StatusChanged(status, newStatus);
        status = newStatus;
    }

    function confirm() onlyHost public {
        setStatus(Status.Confirmed);
    }

    function reject() onlyHost public {
        setStatus(Status.Rejected);
    }

    function () onlyGuest payable public {
        require(status == Status.Confirmed || status == Status.Requested);
        if (address(this).balance >= price && status == Status.Confirmed) {
            setStatus(Status.Booked);
        }
    }

    function cancel() onlyParticipant public  {
        require(status == Status.Requested || status == Status.Confirmed || status == Status.Booked);
        require(now <= dateFrom);
        if (address(this).balance > 0) {
            guest.transfer(address(this).balance);
        }
        setStatus(Status.Cancelled);
    }

    function confirmOccupancy() onlyParticipant public {
        if (msg.sender == guest) {
            require(!occupancyConfirmedByGuest);
            occupancyConfirmedByGuest = true;
        }
        if (msg.sender == host) {
            require(!occupancyConfirmedByHost);
            occupancyConfirmedByHost = true;
        }
        if (occupancyConfirmedByGuest && occupancyConfirmedByHost) {
            setStatus(Status.Started);
        }
    }

    function confirmEjectment() onlyParticipant public {
        if (msg.sender == guest) {
            require(occupancyConfirmedByGuest);
            require(!ejectmentConfirmedByGuest);
            ejectmentConfirmedByGuest = true;
        }
        if (msg.sender == host) {
            require(occupancyConfirmedByHost);
            require(!ejectmentConfirmedByHost);
            ejectmentConfirmedByHost = true;
        }
        if (ejectmentConfirmedByGuest && ejectmentConfirmedByHost) {
            setStatus(Status.Finished);
        }
    }
    
    function currentStatus() external view returns(string) {
        if(status == Status.New)
            return &quot;New&quot;;
            
        if(status == Status.Requested)
            return &quot;Requested&quot;;
            
        if(status == Status.Confirmed)
            return &quot;Confirmed&quot;;

        if(status == Status.Rejected)
            return &quot;Rejected&quot;;
            
        if(status == Status.Cancelled)
            return &quot;Cancelled&quot;;
            
        if(status == Status.Booked)
            return &quot;Booked&quot;;
            
        if(status == Status.Started)
            return &quot;Started&quot;;
            
        if(status == Status.Finished)
            return &quot;Finished&quot;;
    }
}