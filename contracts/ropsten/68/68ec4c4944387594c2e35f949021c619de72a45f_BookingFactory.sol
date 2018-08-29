pragma solidity ^0.4.24;


contract IBooking {

    /** Misc */

    enum Status {New, Requested, Confirmed, Rejected, Cancelled, Booked, Started, Finished}

    /** Extenral functions */

    function getStatus() external view returns(Status);
    function sendAllFunds() external;
    function reject() external;
    function cancel() external;

    function listingId() external view returns(uint128);
    function bookingId() external view returns(uint128);
    function dateFrom() external view returns(uint32);
    function dateTo() external view returns(uint32);
    function price() external view returns(uint256);
    function host() external view returns(address);
    function guest() external view returns(address);
    function depositPpm() external view returns(uint32);
    function feePpm() external view returns(uint32);
    function feeBeneficiary() external view returns(address);

    function getBalance() external view returns (uint);

    /**
    * @return tuple (bool:allows_to_withdraw_funds, uint:amount_of_funds_to_withdraw). First parameter could be true or false, depending on whether host could withdraw anything at that particular moment. Second is always the amount.
    */
    function getFundsStatus() external view returns(bool, uint);

    function () external payable;

    /** Events */
    event StatusChanged (
        Status indexed _from,
        Status indexed _to
    );
}

contract Booking is IBooking {

    uint128 public listingId;
    uint128 public bookingId;
    uint32 public dateFrom;
    uint32 public dateTo;
    uint256 public price;
    address public host;
    address public guest;
    uint32 public depositPpm;
    uint32 public feePpm;
    address public feeBeneficiary;
    Status public status;

    function listingId() onlyParticipant external view returns(uint128) {
        return listingId;
    }

    function bookingId() onlyParticipant external view returns(uint128) {
        return bookingId;
    }

    function dateFrom() onlyParticipant external view returns(uint32) {
        return dateFrom;
    }

    function dateTo() onlyParticipant external view returns(uint32) {
        return dateTo;
    }

    function price() onlyParticipant external view returns(uint256) {
        return price;
    }

    function host() onlyParticipant external view returns(address) {
        return host;
    }

    function guest() onlyParticipant external view returns(address) {
        return guest;
    }

    function depositPpm() onlyParticipant external view returns(uint32) {
        return depositPpm;
    }

    function feePpm() onlyParticipant external view returns(uint32) {
        return feePpm;
    }

    function feeBeneficiary() onlyParticipant external view returns(address) {
        return feeBeneficiary;
    }

    modifier onlyGuest {
        require(msg.sender == guest);
        _;
    }

    modifier onlyHost {
        require(msg.sender == host);
        _;
    }

    modifier onlyParticipant {
        require(msg.sender == guest || msg.sender == host || msg.sender == feeBeneficiary);
        _;
    }

    constructor(uint128 _listingId,
                uint128 _bookingId,
                uint32 _dateFrom,
                uint32 _dateTo,
                uint256 _price,
                address _host,
                address _guest,
                uint32 _depositPpm,
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
        depositPpm = _depositPpm;
        feePpm = _feePpm;
        feeBeneficiary = _feeBeneficiary;

        status = Status.New;
        setStatus(Status.Confirmed);

        pay(_guest, msg.value);
    }

    function () external onlyGuest payable {
        pay(msg.sender, msg.value);
    }

    function pay(address _sender, uint _value) private {
        uint balanceBeforePay = address(this).balance - _value;
        require(balanceBeforePay == 0); // deny receiving when fully payed
        require(_value == 0 || _value >= price); // deny underpay but allow zero pay (on construction)
        require(status == Status.Confirmed);

        if (_value > price) { // handling overpay & returning the change
            uint change = _value - price;
            _sender.transfer(change);
        }

        if (address(this).balance == price) {
            setStatus(Status.Booked);
        }
    }

    function setStatus(Status newStatus) private {
        emit StatusChanged(status, newStatus);
        status = newStatus;
    }

    function getBalance() onlyParticipant external view returns (uint) {
        return address(this).balance;
    }

    function reject() onlyHost external {
        // TODO: describe & implement
    }

    function cancel() onlyParticipant external {
        require(status == Status.Requested || status == Status.Confirmed || status == Status.Booked);
        require(now <= dateFrom);
        if (address(this).balance > 0) {
            guest.transfer(address(this).balance);
        }
        setStatus(Status.Cancelled);
    }

    function sendAllFunds() onlyParticipant external {
        require(address(this).balance > 0);
        require(now >= dateTo);
        require(status == Status.Booked);

        uint deposit = (address(this).balance * depositPpm) / 1000000;
        guest.transfer(deposit);

        uint fee = (address(this).balance * feePpm) / 1000000;
        feeBeneficiary.transfer(fee);

        host.transfer(address(this).balance);
    }

    function getStatus() external view returns(Status) {
        if (status == Status.Booked) {
            if      (now < dateFrom) { return Status.Booked;   }
            else if (now < dateTo)   { return Status.Started;  }
            else                     { return Status.Finished; }
        } else {
            return status;
        }
    }

    function getFundsStatus() external view returns(bool, uint) {
        revert(); // TODO:
    }
}

contract BookingFactory {
    address public owner;

    mapping(uint128 => bool) private bookingIds;

    uint32 public depositPpm = 100000; // PPM = parts per million, 100000 == 10%
    uint32 public     feePpm =  10000; // PPM = parts per million,  10000 ==  1%
    address private feeBeneficiary;

    constructor() public {
        owner = msg.sender;
        feeBeneficiary = owner;
    }

    modifier onlyOwner() {
        require(msg.sender == msg.sender);
        _;
    }

    function createBooking(
        uint128 _listingId,
        uint128 _bookingId,
        uint32 _dateFrom,
        uint32 _dateTo,
        uint256 _price,
        address _host
    ) public payable returns (IBooking booking) {
        require(!bookingIds[_bookingId]);
        bookingIds[_bookingId] = true;
        booking = (new Booking).value(msg.value)(
            _listingId,
            _bookingId,
            _dateFrom,
            _dateTo,
            _price,
            _host,
            msg.sender,
            depositPpm,
            feePpm,
            feeBeneficiary
        );
        emit BookingCreated(booking, _listingId, _bookingId);
        return booking;
    }

    function setDepositPpm(uint32 _depositPpm) public onlyOwner {
        require(_depositPpm < 1000000);
        depositPpm = _depositPpm;
    }

    function setFee(uint32 _feePpm, address _feeBeneficiary) public onlyOwner {
        require(_feePpm < 1000000);
        feePpm = _feePpm;
        feeBeneficiary = _feeBeneficiary;
    }

    event BookingCreated (
        IBooking indexed bookingContractAddress,
        uint128 indexed listingId,
        uint128 indexed bookingId
    );
}