pragma solidity ^0.4.13;

contract BookingTimeUtils {
    DateTime private dateTime;

    function BookingTimeUtils(address ethereum_datetime) public {
        dateTime = DateTime(ethereum_datetime);
    }

    function areWeekdaysOpen(uint[] _startTimes, uint[] _endTimes, uint _rangeStart, uint _rangeEnd)
        public
        view
        returns (bool)
    {
        require(_startTimes.length == 7 && _endTimes.length == 7);
        for (uint i = 0; i < 7; i++) {
            require(_startTimes[i] < 1440 && _endTimes[i] < 1440);
            if (_startTimes[i] == 0 && _endTimes[i] == 0) {
                if (isWeekdayInsideTimestamps(i, _rangeStart, _rangeEnd))
                    return false;
            }
        }
        return true;
    }

    function isStartTimeCorrect(uint _start, uint[] _startTimes) public view returns (bool) {
        uint startWeekday = dateTime.getWeekday(_start);
        uint startTimeInSchedule = _startTimes[startWeekday];
        if (_start - (startTimeInSchedule * 60) != getTimestampOfDayStart(_start))
            return false;
        return true;
    }

    function getEndTimeOfSession(uint _start, uint[] _endTimes, uint _nbrOfSession) public view returns (uint) {
        uint dayOfStart = dateTime.getWeekday(_start);
        uint dayOfEnd = dayOfStart + _nbrOfSession - 1;
        uint endTimeForDay = _endTimes[dayOfEnd];
        uint endTime = getTimestampOfDayStart(_start) + (_nbrOfSession - 1 * 1 days) + endTimeForDay * 60;
        return (endTime);
    }

    function testingForFun(uint[] _times) public pure returns (uint) {
        for (uint i = 1; i < _times.length; i++) {
            if (getTimestampOfDayStart(_times[i]) != getTimestampOfDayStart(_times[i - 1]) +  1 days)
                return (getTimestampOfDayStart(_times[i - 1]) +  1 days);
        }
        return 1;
    }

    function doDaysFollowEachOther(uint[] _times) public pure returns (bool) {
        for (uint i = 1; i < _times.length; i++) {
            if (getTimestampOfDayStart(_times[i]) != getTimestampOfDayStart(_times[i - 1]) +  86400)
                return false;
        }
        return true;
    }

    function getTimestampOfDayStart(uint _timestamp) public pure returns (uint) {
        return (_timestamp - (_timestamp % (60 * 60 * 24)));
    }

    function getTimestampOfDayEnd(uint _timestamp) public pure returns (uint) {
        return (getTimestampOfDayStart(_timestamp + 1 days - 1));
    }

    function isWeekdayInsideTimestamps(uint weekday, uint start, uint end) internal view returns (bool) {
        require(end > start);
        uint dayStart = dateTime.getWeekday(start);
        uint dayEnd = dateTime.getWeekday(end);
        if (end - start > dateTime.toTimestamp(1970, 1, 7)) {
            return true;
        }
        if (weekday == dayStart || weekday == dayEnd) {
            return true;
        }
        if (dayEnd < dayStart) {
            if (weekday > dayStart)
                return true;
        }
        if (dayEnd >= dayStart) {
            if (weekday < dayEnd && weekday > dayStart)
                return true;
        }
        return false;
    }

    function isTimestampInsideRange(uint target, uint start, uint end) public pure returns (bool){
        return (target >= start && target <= end);
    }

    function isRangeInsideRange(uint targetStart, uint targetEnd, uint start, uint end) public pure returns (bool) {
        if (targetStart <= end && targetEnd >= start) {
            return true;
        }
    }
}

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

contract DelegateResolver {
    mapping(address => bool) private delegates;
    address public owner = msg.sender;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function addDelegate(address addr) public ownerOnly() {
        delegates[addr] = true;
    }

    function removeDelegate(address addr) public ownerOnly() {
        delegates[addr] = false;
    }

    function isDelegate(address addr) public view returns (bool) {
        return delegates[addr];
    }
}

contract EventHub {

    ServiceContractResolver private scr;

    modifier serviceContractOnly(address addr) {
        require (scr.isServiceContract(addr));
        _;
    }

    function EventHub(address scrAddr) {
        scr = ServiceContractResolver(scrAddr);
    }

    function newBookingfc(uint ID, address user, uint start, uint nbrOfSession, uint slots) serviceContractOnly(msg.sender) {
        newBooking(msg.sender, user, ID, start, nbrOfSession, slots);
    }

    function canceledBookingfc(uint ID) serviceContractOnly(msg.sender) {
        canceledBooking(msg.sender, ID);
    }

    function acceptedBookingfc(uint ID) serviceContractOnly(msg.sender) {
        acceptedBooking(msg.sender, ID);
    }

    function rejectedBookingfc(uint ID) serviceContractOnly(msg.sender) {
        rejectedBooking(msg.sender, ID);
    }

    event newBooking(address ct, address user, uint ID, uint start, uint nbrOfSession, uint slots);
    event canceledBooking(address ct, uint ID);
    event acceptedBooking(address ct, uint ID);
    event rejectedBooking(address ct, uint ID);
}

contract RatingsContract {

    struct Average {
        uint16 average;
        uint nbrOfRatings;
    }

    mapping(address => mapping(uint => uint8)) private addressRatings;
    mapping(address => Average) public addressAverage;
    address public owner = msg.sender;
    ServiceContractResolver private scr;
    DelegateResolver private dr;

    modifier ownerOnly() {
        require (msg.sender == owner);
        _;
    }

    modifier serviceContractOnly(address addr) {
        require (scr.isServiceContract(addr));
        _;
    }

    modifier delegateOnly() {
        require (dr.isDelegate(msg.sender));
        _;
    }

    function RatingsContract(address serviceContractResolver, address delegateResolver) {
        scr = ServiceContractResolver(serviceContractResolver);
        dr = DelegateResolver(delegateResolver);
    }

    function rateAddress(address rated, uint rating) public serviceContractOnly(msg.sender) {
        require(rating >= 0 && rating <= 10);
        if (addressAverage[rated].nbrOfRatings == 0) {
            Average memory average = Average(uint16(rating * 100), 1);
            addressAverage[rated] = average;
            addressRatings[rated][1] = uint8(rating);
        }
        else {
            Average memory currentAverage;
            currentAverage = addressAverage[rated];
            Average memory newAverage = Average(uint16(((currentAverage.average * currentAverage.nbrOfRatings) + (rating * 100)) / (currentAverage.nbrOfRatings + 1)),
            currentAverage.nbrOfRatings + 1);
            addressAverage[rated] = newAverage;
            addressRatings[rated][newAverage.nbrOfRatings] = uint8(rating);
        }
    }


    function getRatingsForAddress(address _addr) public view returns (uint[]) {
        uint nbrOfRatings = getNumberOfRatingForAddress(_addr);
        require(nbrOfRatings > 0);
        uint[] memory ratings = new uint[](nbrOfRatings);
        for (uint i = 1; i <= nbrOfRatings; i++) {
            ratings[i] = addressRatings[_addr][i - 1];
        }
        return (ratings);
    }


    function getNumberOfRatingForAddress(address _addr) internal view returns (uint) {
        Average memory currentAverage;
        currentAverage = addressAverage[_addr];
        return (currentAverage.nbrOfRatings);
    }
}

contract ServiceContract {
    enum Stages {
        PendingAccept,
        Booked,
        Rejected,
        Canceled,
        Finalized
    }

    struct RefundConfig {
        mapping (uint => uint) indexes;
        mapping (uint => uint) values;
    }

    struct Reservation {
        bool isOwner;
        address client;
        uint startTime;
        uint numberOfSessions;
        uint totalPrice;
        uint numberOfGuests;
        bool hasOwnerVoted;
        bool hasClientVoted;
        uint ownerRating;
        uint clientRating;
        uint creationTime;
        Stages stage;
    }

    address public owner = msg.sender;
    uint public serviceDuration;
    uint[] public startTimes;
    uint[] public endTimes;
    string public IPFSHash;
    uint public price;
    uint public maxAvailableSpots;
    mapping(uint => Reservation) public reservations;
    uint private nbrReservation;
    mapping(uint => uint) public availableSpots;
    BookingTimeUtils private btu;
    RefundConfig refundPolicy;
    address private pleaseAddress = 0xb0e49d91c41C577Ed90E2fC65CA766EB518682D2;
    //address private ratingContract = 0x1132c82b2b69dba473280379b1ebd69af0bdd044;
    //RatingsContract private rc = RatingsContract(ratingContract);
    RatingsContract private rc;
    TokenRate private tr;
    DelegateResolver private dr;
    EventHub private eh;
    //TokenRate private tr = TokenRate(tokenRate);
    //address private delegateResolver = 0x2c56aae7f84600bc539706ca9acbe748ab87dc07;
    //DelegateResolver private dr = DelegateResolver(delegateResolver);
    bool public isFrozen = false;

    function ServiceContract(
        uint _serviceDuration,
        uint[] start,
        uint[] end,
        string _IPFSHash,
        uint _price,
        uint _maxAvailableSpots,
        uint[] daysBefore,
        uint[] percentage,
        address rcAddr,
        address trAddr,
        address drAddr,
        address btuAddr,
        address ehAddr
        )
        public
        {
            serviceDuration = _serviceDuration;
            //Address btuAddress = 0x8ed82a28f41ee25e00b91fa7f4c5c63236d3492a; // ROPSTEN ADDRESS
            btu = BookingTimeUtils(btuAddr);
            rc = RatingsContract(rcAddr);
            tr = TokenRate(trAddr);
            dr = DelegateResolver(drAddr);
            eh = EventHub(ehAddr);
            startTimes = start;
            endTimes = end;
            IPFSHash = _IPFSHash;
            price = _price;
            maxAvailableSpots = _maxAvailableSpots;

            for (uint i = 0; i <= 1; i++) {
                require(percentage[i] >= 0 &&  percentage[i] <= 100);
                refundPolicy.indexes[i] = daysBefore[i];
                refundPolicy.values[refundPolicy.indexes[i]] = percentage[i];
            }
        }

        /*function ServiceContract() public
        serviceDuration = 1;
        address btuAddress = 0x8ed82a28f41ee25e00b91fa7f4c5c63236d3492a; // ROPSTEN ADDRESS
        btu = BookingTimeUtils(btuAddress);
        startTimes = [120, 120, 120, 120, 120, 120, 120];
        endTimes = [1300, 1300, 1300, 1300, 1300, 1300, 1300];
        price = 150;
        maxAvailableSpots = 3;
        refundPolicy.indexes = [5, 10];
        refundPolicy.values = [60, 100];
        }*/

        modifier unfrozenOnly() {
            require (isFrozen == false);
            _;
        }

        modifier delegateOnly() {
            require (dr.isDelegate(msg.sender));
            _;
        }

        modifier ownerOnly() {
            require(msg.sender == owner);
            _;
        }

        function setServiceDuration(uint _duration) public ownerOnly() {
            serviceDuration = _duration;
        }

        function setTimes(uint[] _start, uint[] _end) public ownerOnly() {
            require(_start.length == 7 && _end.length == 7);
            startTimes = _start;
            endTimes = _end;
        }

        function setPrice(uint _price) public ownerOnly() {
            price = _price;
        }

        function setIPFSHash(string _IPFSHash) public ownerOnly() {
            IPFSHash = _IPFSHash;
        }

        function setMaxAvailableSpot(uint _maxAvailableSpots) public ownerOnly() {
            maxAvailableSpots = _maxAvailableSpots;
        }

        function isFree(uint[] _startDates, uint _numberOfSlots) internal view returns (bool) {
            for (uint i = 0; i < _startDates.length; i++) {
                if(availableSpots[btu.getTimestampOfDayStart(_startDates[i])] +  _numberOfSlots > maxAvailableSpots)
                return false;
            }
            return true;
        }

        function removeAvailability(uint[] _startDates, uint _numberOfGuests) internal {
            for (uint i = 0; i < _startDates.length; i++) {
                availableSpots[btu.getTimestampOfDayStart(_startDates[i])] = availableSpots[btu.getTimestampOfDayStart(_startDates[i])] + _numberOfGuests;
            }
        }

        function book(uint[] _startDates, uint _numberOfSlots) public unfrozenOnly() payable {
            require(_numberOfSlots > 0);
            require(_startDates.length > 0);
            require(btu.doDaysFollowEachOther(_startDates));
            require(_startDates[0] > now);
            require(btu.areWeekdaysOpen(startTimes, endTimes, _startDates[0], _startDates[_startDates.length - 1]));
            require(isFree(_startDates, _numberOfSlots));
            if (msg.sender == owner || dr.isDelegate(msg.sender))
                ethPrice = 0;
            else {
                uint ethPrice = (1 ether * price * 100 / tr.USDValue()) * _startDates.length;
                require (msg.value >= ethPrice * 110 / 100);
            }
            reservations[nbrReservation++] = Reservation(false, msg.sender, _startDates[0], _startDates.length, ethPrice, _numberOfSlots, false, false, 0, 0, now, Stages.PendingAccept);
            removeAvailability(_startDates, _numberOfSlots);
            //eh.newBookingfc(nbrReservation - 1, msg.sender, _startDates[0], _startDates.length, _numberOfSlots);
            msg.sender.transfer(msg.value - (ethPrice * 110 / 100));
        }

        function accept(uint reservationID) public ownerOnly() {
            Reservation storage r = reservations[reservationID];
            require(r.stage == Stages.PendingAccept);
            r.stage = Stages.Booked;
            eh.acceptedBookingfc(reservationID);
        }

        function reject(uint reservationID)public ownerOnly() {
            Reservation storage r = reservations[reservationID];
            require(r.stage == Stages.PendingAccept);
            r.stage = Stages.Rejected;
            for (uint i = 0; i < r.numberOfSessions; i++) {
                availableSpots[btu.getTimestampOfDayStart(r.startTime + i * 1 days)] = availableSpots[btu.getTimestampOfDayStart(r.startTime + i * 1 days)] - r.numberOfGuests;
            }
            r.client.transfer(r.totalPrice * 110 / 100);
            eh.rejectedBookingfc(reservationID);
        }

        function freeze() public ownerOnly() {
            isFrozen = true;
        }

        function unFreeze() public ownerOnly() {
            isFrozen = false;
        }

        function finalizeRent(uint reservationID, uint rating) public
        {
            Reservation storage r = reservations[reservationID];
            address client = r.client;
            require(r.stage == Stages.Booked);
            require(msg.sender == owner || msg.sender == client);
            require(rating >= 0 && rating <= 10);
            uint endDate = r.startTime + r.numberOfSessions * 1 days;
            require(now >= endDate);
            if (msg.sender == owner) {
                require(r.hasOwnerVoted == false);
                r.hasOwnerVoted = true;
                r.ownerRating = rating;
                rc.rateAddress(client, rating);
            }
            else if (msg.sender == client) {
                require(r.hasClientVoted == false);
                r.hasClientVoted = true;
                r.clientRating = rating;
                rc.rateAddress(owner, rating);
            }
            if (r.hasOwnerVoted == true && r.hasClientVoted == true) {
                r.stage = Stages.Finalized;
                owner.transfer(r.totalPrice);
                pleaseAddress.transfer(r.totalPrice / 10);
            }
        }

        function cancelReservation(uint reservationID) {
            Reservation storage r = reservations[reservationID];
            address client = r.client;
            require(msg.sender == owner || msg.sender == client);
            require(now < r.startTime);
            if (r.stage == Stages.PendingAccept) {
                r.client.transfer(r.totalPrice * 110 / 100);
                r.stage = Stages.Canceled;
                for (uint d = 0; d < r.numberOfSessions; d++) {
                    availableSpots[btu.getTimestampOfDayStart(r.startTime + d * 1 days)] = availableSpots[btu.getTimestampOfDayStart(r.startTime + d * 1 days)] - r.numberOfGuests;
                }
                eh.canceledBookingfc(reservationID);
            }
            if (r.stage == Stages.Booked) {
                if (msg.sender == owner) {
                    r.client.transfer(r.totalPrice * 110 / 100);
                }
                else {
                    uint dayNow = btu.getTimestampOfDayStart(now);
                    uint dayStart = btu.getTimestampOfDayStart(r.startTime);
                    uint dayDifference = (dayStart - dayNow) / 86400;
                    for (uint i = 0; i <= 2; i++) {
                        if (i == 2) {
                            r.client.transfer(r.totalPrice * 110 / 100);
                            break;
                        }
                        if (refundPolicy.indexes[i] > dayDifference) {
                            r.client.transfer((r.totalPrice * 110 / 100) * refundPolicy.values[refundPolicy.indexes[i]] / 100);
                            owner.transfer(r.totalPrice * (100 - refundPolicy.values[refundPolicy.indexes[i]]) / 100);
                            pleaseAddress.transfer(r.totalPrice * (100 - refundPolicy.values[refundPolicy.indexes[i]]) / 1000);
                            break;
                        }
                    }
                }
                r.stage = Stages.Canceled;
                for (var j = 0; j < r.numberOfSessions; j++) {
                    availableSpots[btu.getTimestampOfDayStart(r.startTime + j * 1 days)] = availableSpots[btu.getTimestampOfDayStart(r.startTime + j * 1 days)] - r.numberOfGuests;
                }
                eh.canceledBookingfc(reservationID);
            }
        }

        function getPercentage(uint rating) pure internal returns(uint) {
            if (rating <= 4)
            return 0;
            else
            return rating;
        }
    }

contract ServiceContractResolver {

    mapping(address => bool) private contracts;
    mapping(uint => address) public contractsIndex;
    uint public contractNbr = 0;
    address public owner = msg.sender;
    DelegateResolver private dr;


    modifier ownerOnly() {
        require (msg.sender == owner);
        _;
    }

    modifier delegateOnly() {
        require (dr.isDelegate(msg.sender));
        _;
    }

    function ServiceContractResolver(address delegateResolver) {
        dr = DelegateResolver(delegateResolver);
    }

    function addAddress(address addr) public delegateOnly() {
        contracts[addr] = true;
        contractsIndex[contractNbr] = addr;
        contractNbr++;
    }

    function getAllAddresses() public view returns (address[]) {
        address[] memory addrs = new address[](contractNbr);
        for (uint i = 0; i < contractNbr; i++) {
            addrs[i] = contractsIndex[i];
        }
        return addrs;
    }

    function isServiceContract(address addr) public view returns (bool) {
        return contracts[addr];
    }
}

contract TokenRate {
    uint public USDValue;
    uint public EURValue;
    uint public GBPValue;
    uint public BTCValue;
    address public owner = msg.sender;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function setValues(uint USD, uint EUR, uint GBP, uint BTC) ownerOnly public {
        USDValue = USD;
        EURValue = EUR;
        GBPValue = GBP;
        BTCValue = BTC;
    }
}