/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        uint256 year;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        uint256 year;
        uint256 month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _years)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _months)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _hours)
    {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


contract peopleFutures {

    address payable public prompti;
 
    struct EscrowContract  {
        address payable sponsor;
        address payable prospect;
        address payable prompti;
        uint256 totalPayment;
        uint256 escrowPercent;
        uint256 feePercent;
        uint256 numberOfYears;
        uint256 firstYear;
        uint256[] projectedEarnings;
        uint256[] projectedPayout;
        uint256[] actualPayout;
        uint256[] baseEscrowBalances;
        uint256 balance;
    }
    
    struct PaymentBrackets {
        uint256 tierOnePercent;
        uint256 tierTwoPercent;
        uint256 tierThreePercent;
        uint256 tierTwoMinimum;
        uint256 tierThreeMinimum;
        uint256 minimumPayout;
    }
    struct EarningReports {
        uint256 mostRecentEarningsReportYear;
        uint256 mostRecentEarningsReportReceivedYear;
        uint256 numberOfEarningsReports;
        uint256 earnings;
        uint256 payout;
        uint256 cumulativePayout;
        uint256 cumulativeExcessPayout;
        uint256 excessProfitsEscrowReleaseRate;
        uint256 escrowAmount;
        bool paymentMade;
    }

    mapping(string => EscrowContract) public escrows;
    mapping(string => PaymentBrackets) public paymentBrackets;
    mapping(string => EarningReports) public earningReports;
    
    
    
    mapping(address => uint) public balances;
    mapping(address => uint) public availableBalances; //take into consideration pending trades
    mapping(address => bool) public members;
    
    // ------------------------------------------------------------------------
    // Events for Escrow
    // ------------------------------------------------------------------------
    
    event EscrowCreated(string escrowId);
    event InitialPaymentMade(string escrowId, address prospect, uint256 amount);
    event FeePaymentMade(string escrowId, address prompti, uint256 amount);

    // ------------------------------------------------------------------------
    // Events for earning Reports
    // ------------------------------------------------------------------------

    event ProspectReportedEarnings(string escrowId, uint256 earnings);
    event SponsorVerifiedEarnings(string escrowId, uint256 earnings, uint256 sponsorPayout);
    event ProspectPaidSponsor(string escrowId, uint256 payout);
    event EscrowReleased(string escrowId, uint256 amountReleased);
    
    constructor() public {
        prompti = payable(msg.sender);
    }

    // ------------------------------------------------------------------------
    // initialize new Escrow
    // Initialize a new Escrow Contract
    // ------------------------------------------------------------------------

    function initializeNewContract(
        string memory _contractId,
        address payable _sponsor,
        address payable _prospect,
        address payable _prompti,
        uint256 _totalPayment,
        uint256 _escrowPercent,
        uint256 _feePercent,
        uint256 _numberOfYears,
        uint256 _firstYear,
        uint256[] memory _projectedEarnings,
        uint256[] memory _baseEscrowbalances
    ) public {
        escrows[_contractId].sponsor = _sponsor;
        escrows[_contractId].prospect = _prospect;
        escrows[_contractId].prompti = _prompti;
        escrows[_contractId].totalPayment = _totalPayment;
        escrows[_contractId].escrowPercent = _escrowPercent;
        escrows[_contractId].feePercent = _feePercent;
        escrows[_contractId].numberOfYears = _numberOfYears;
        escrows[_contractId].firstYear = _firstYear;
        escrows[_contractId].projectedEarnings = _projectedEarnings;
        escrows[_contractId].baseEscrowBalances = _baseEscrowbalances;
        emit EscrowCreated(_contractId);
    }

    // ------------------------------------------------------------------------
    // Initialize Value
    // Initialize Payment Brackets
    // ------------------------------------------------------------------------
    
    function initializeValues(
        string memory _contractId,
        uint256 _tierOnePercent,
        uint256 _tierTwoPercent,
        uint256 _tierThreePercent,
        uint256 _tierTwoMinimum,
        uint256 _tierThreeMinimum,
        uint256 _minimumPayout
        ) public {
            paymentBrackets[_contractId].tierOnePercent = _tierOnePercent;
            paymentBrackets[_contractId].tierTwoPercent = _tierTwoPercent;
            paymentBrackets[_contractId].tierThreePercent = _tierThreePercent;
            paymentBrackets[_contractId].tierTwoMinimum = _tierTwoMinimum;
            paymentBrackets[_contractId].tierThreeMinimum = _tierThreeMinimum;
            paymentBrackets[_contractId].minimumPayout = _minimumPayout;
            earningReports[_contractId].excessProfitsEscrowReleaseRate = 50;
            calculateProjectedPayout(_contractId);
    }

    // ------------------------------------------------------------------------
    // Calculate Projected Payout
    // calculates the projected payout based on projected earnings and pay brackets
    // ------------------------------------------------------------------------

    
    function calculateProjectedPayout(string memory _contractId) private {
        uint numberOfYears = escrows[_contractId].numberOfYears;
        uint256[] memory projectedEarnings =  escrows[_contractId].projectedEarnings;
        uint256 tierOnePercent = paymentBrackets[_contractId].tierOnePercent;
        uint256 tierTwoPercent = paymentBrackets[_contractId].tierTwoPercent;
        uint256 tierThreePercent = paymentBrackets[_contractId].tierThreePercent;
        uint256 tierTwoMinimum = paymentBrackets[_contractId].tierTwoMinimum;
        uint256 tierThreeMinimum = paymentBrackets[_contractId].tierThreeMinimum;
        for (uint8 i = 0; i < numberOfYears; i++) {
            if (projectedEarnings[i] < tierTwoMinimum) {
                escrows[_contractId].projectedPayout.push(projectedEarnings[i] * tierOnePercent / 100);
            } else if (projectedEarnings[i] < tierThreeMinimum) {
                escrows[_contractId].projectedPayout.push((tierTwoMinimum * tierOnePercent / 100) + ((projectedEarnings[i] - tierTwoMinimum) * tierTwoPercent / 100));
            } else {
                escrows[_contractId].projectedPayout.push(tierTwoMinimum * tierOnePercent / 100);
                escrows[_contractId].projectedPayout[i] += (tierThreeMinimum - tierTwoMinimum) * tierTwoPercent / 100;
                escrows[_contractId].projectedPayout[i] += (projectedEarnings[i] - tierThreeMinimum) * tierThreePercent / 100;
            }
            escrows[_contractId].actualPayout.push(0);
        }
    }    

    // ------------------------------------------------------------------------
    // Calculate Projected Payout
    // Sponsor makes initial payment, fee paid out to Prompti
    // ------------------------------------------------------------------------
    
    
    function initialPayment(string memory _contractId) public payable {
        require(msg.sender == escrows[_contractId].sponsor, "You are not sponsor");
        require(msg.value == escrows[_contractId].totalPayment, "Value is not equal total Payment");
        require(earningReports[_contractId].paymentMade, "Payment Already Made");

        earningReports[_contractId].paymentMade = true;

        uint256 fee = (escrows[_contractId].totalPayment * escrows[_contractId].feePercent) / 100;
        uint256 initialPayout = escrows[_contractId].totalPayment - fee - escrows[_contractId].baseEscrowBalances[0];
        
        escrows[_contractId].balance = msg.value - initialPayout - fee;

        emit InitialPaymentMade(_contractId, escrows[_contractId].prospect,initialPayout);
        emit FeePaymentMade(_contractId,escrows[_contractId].prompti, fee);

        escrows[_contractId].prospect.transfer(initialPayout);
        prompti.transfer(fee);
    }

    // ------------------------------------------------------------------------
    // Report Earnings
    // Prospect reports earnings
    // ------------------------------------------------------------------------
    
    function reportEarnings(string memory _contractId,uint256 _earnings) public {
        uint256 currentYear = DateTime.getYear(block.timestamp);
        require(currentYear == escrows[_contractId].firstYear + earningReports[_contractId].numberOfEarningsReports, "Current year not matched");
        require(block.timestamp < DateTime.timestampFromDate(currentYear, 2, 8), "time not matched");
        require(earningReports[_contractId].mostRecentEarningsReportYear != currentYear, "error----3");

        emit ProspectReportedEarnings(_contractId,_earnings);

        earningReports[_contractId].earnings = _earnings;
        earningReports[_contractId].mostRecentEarningsReportYear = currentYear;
        earningReports[_contractId].numberOfEarningsReports++;
    }


    // ------------------------------------------------------------------------
    // Verify Earning reports
    // Sponsor verifies that reported earnings are correct
    // ------------------------------------------------------------------------

    
    function verifyEarningsReport(string memory _contractId,uint256 _earnings) public {
        uint256 currentYear = DateTime.getYear(block.timestamp);
        require(earningReports[_contractId].mostRecentEarningsReportYear == currentYear);
        if (earningReports[_contractId].earnings != _earnings) {
            // Don't agree on earnings - need to handle this
            revert();
        }

        earningReports[_contractId].payout = 0;
        if (earningReports[_contractId].earnings < paymentBrackets[_contractId].tierTwoMinimum) {
            earningReports[_contractId].payout = earningReports[_contractId].earnings * paymentBrackets[_contractId].tierOnePercent / 100;
        } else if (earningReports[_contractId].earnings < paymentBrackets[_contractId].tierThreeMinimum) {
            earningReports[_contractId].payout = (paymentBrackets[_contractId].tierTwoMinimum * paymentBrackets[_contractId].tierOnePercent / 100) + ((earningReports[_contractId].earnings - paymentBrackets[_contractId].tierTwoMinimum) * paymentBrackets[_contractId].tierTwoPercent / 100);
        } else {
            earningReports[_contractId].payout = paymentBrackets[_contractId].tierTwoMinimum * paymentBrackets[_contractId].tierOnePercent / 100;
            earningReports[_contractId].payout += (paymentBrackets[_contractId].tierThreeMinimum - paymentBrackets[_contractId].tierTwoMinimum) * paymentBrackets[_contractId].tierTwoPercent / 100;
            earningReports[_contractId].payout += (earningReports[_contractId].earnings - paymentBrackets[_contractId].tierThreeMinimum) * paymentBrackets[_contractId].tierThreePercent / 100;
        }
        earningReports[_contractId].cumulativePayout += earningReports[_contractId].payout;
        escrows[_contractId].actualPayout[currentYear - escrows[_contractId].firstYear] = earningReports[_contractId].payout;
        if (earningReports[_contractId].payout > escrows[_contractId].projectedPayout[currentYear-escrows[_contractId].firstYear]) {
            earningReports[_contractId].cumulativeExcessPayout += earningReports[_contractId].payout - escrows[_contractId].projectedPayout[currentYear-escrows[_contractId].firstYear];
        }

        emit SponsorVerifiedEarnings(_contractId,_earnings, earningReports[_contractId].payout);

        earningReports[_contractId].mostRecentEarningsReportReceivedYear = currentYear;
    }


    // ------------------------------------------------------------------------
    // Pay porton of Earning
    // Yearly payout based on reported earnings
    // ------------------------------------------------------------------------


    
    function payPortionOfEarnings(string memory _contractId) public payable {
        uint256 currentYear = DateTime.getYear(block.timestamp);
        require(msg.sender == escrows[_contractId].prospect, "You are not prospect");
        require(msg.value == earningReports[_contractId].payout, "Value is not equal to payout");
        require(earningReports[_contractId].mostRecentEarningsReportReceivedYear == currentYear, "Earning not reported this year");
        require(block.timestamp < DateTime.timestampFromDate(currentYear, 2, 16), "time error");
        
        if (earningReports[_contractId].cumulativePayout < paymentBrackets[_contractId].minimumPayout) {
            earningReports[_contractId].escrowAmount = escrows[_contractId].baseEscrowBalances[0];
        } else {
            uint256 potentialEscrow = escrows[_contractId].baseEscrowBalances[currentYear-escrows[_contractId].firstYear] - 
                    (earningReports[_contractId].cumulativeExcessPayout * earningReports[_contractId].excessProfitsEscrowReleaseRate / 100);
            if (potentialEscrow < 0) {
                earningReports[_contractId].escrowAmount = 0;
            } else {
                earningReports[_contractId].escrowAmount = potentialEscrow;
            }
        }
        
        //  Need to fix this lines
        
        escrows[_contractId].balance += msg.value;

        emit ProspectPaidSponsor(_contractId,earningReports[_contractId].payout);
        emit EscrowReleased(_contractId,escrows[_contractId].balance - earningReports[_contractId].escrowAmount);

        escrows[_contractId].prospect.transfer(escrows[_contractId].balance - earningReports[_contractId].escrowAmount);
        escrows[_contractId].sponsor.transfer(earningReports[_contractId].payout);
        escrows[_contractId].balance -= earningReports[_contractId].escrowAmount;
        escrows[_contractId].balance -= earningReports[_contractId].payout;
        
        // Need to fix
    }
    
    
    // ------------------------------------------------------------------------
    // Getters for Testing
    // ------------------------------------------------------------------------

    function getTotalPayment(string memory _contractId) public view returns(uint256) {
        return escrows[_contractId].totalPayment;
    }

    function getEscrowPercent(string memory _contractId) public view returns(uint256) {
        return escrows[_contractId].escrowPercent;
    }

    function getProjectedEarnings(string memory _contractId) public view returns(uint256[] memory) {
        return escrows[_contractId].projectedEarnings;
    }

    function getSponsor(string memory _contractId) public view returns(address) {
        return escrows[_contractId].sponsor;
    }

    function getBaseEscrow(string memory _contractId) public view returns(uint256[] memory) {
        return escrows[_contractId].baseEscrowBalances;
    }

    function getProjectedPayout(string memory _contractId) public view returns(uint256[] memory) {
        return escrows[_contractId].projectedPayout;
    }

    function getEscrowBalance(string memory _contractId) public view returns(uint256) {
        return escrows[_contractId].balance;
    }

    function register(address member) 
        external 
        onlyMember(member, false)
        onlyAdmin() {
        members[member] = true;
        balances[member] += 500;
        availableBalances[member] += 500;
    }
    
    function unregister(address member) 
        external 
        onlyMember(member, true)
        onlyAdmin() {
        uint memberBalance = balances[member];
        members[member] = false;
        _transfer(member, address(this), memberBalance);
    }

    function _transfer(address from, address to, uint amount) internal {
        require(balances[from] >= amount, 'cannot transfer more than current balance');
        balances[from] -= amount;
        availableBalances[from] -= amount;
        balances[to] += amount;
        availableBalances[to] += amount;
    }


    function deposit() 
        external
        payable 
        onlyMember(msg.sender, true) {
        balances[msg.sender] += msg.value;
        availableBalances[msg.sender] += msg.value;
    }

    function withdraw(
        uint amount)
        external 
        payable 
        onlyMember(msg.sender, true){
        require(availableBalances[msg.sender] >= amount,'balance too low'); 
        balances[msg.sender] -= amount;
         _transfer(address(this), msg.sender, amount);
    }

    modifier onlyMember(address member, bool registered) {
        if(registered) {
            require(members[member] == true, 'must be registered');
        } else {
            require(members[member] == false, 'must NOT be registered');
        }
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == prompti, 'only admin');
        _;
    }

}