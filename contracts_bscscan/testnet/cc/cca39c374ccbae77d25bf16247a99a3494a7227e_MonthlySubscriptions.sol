/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity ^0.4.16;

/*  Copyright 2017 Mike Shultz

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// from: https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
// Address: 0x1a6184cd4c5bea62b0116de7962ee7315b7bcbce as of 2017-09-08

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct DateTime {
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

        function isLeapYear(uint16 year) constant returns (bool) {
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

        function leapYearsBefore(uint year) constant returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) constant returns (uint8) {
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

        function parseTimestamp(uint timestamp) internal returns (DateTime dt) {
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

        function getYear(uint timestamp) constant returns (uint16) {
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

        function getMonth(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) constant returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) constant returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) constant returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) constant returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp) {
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
/** MonthlySubscriptions

    Contract that takes payment for monthly subscriptions
 */
contract MonthlySubscriptions {

    struct Subscriber {
        bool exists;
        mapping (uint32 => uint) paid;
    }

    bool internal alive;
    address internal manager;
    DateTime internal datetime;
    mapping (address => Subscriber) subscribers;

    /* Payment event
     *
     * @dev Signals a payment has been made for a specific month.
     * @param by  Who sent the payment
     * @param amount  The amount paid in Wei
     * @param formonth  The integer representation of the month(YYYYMM)
     */
    event Payment(
        address by,
        uint amount,
        uint formonth
    );

    /**
     * Only a certain address can use this modified method
     * @param by The address that can use the method
     */
    modifier onlyBy(address by) { 
        require(msg.sender == by);
        _; 
    }

    /**
     * Method can only be used when contract is "alive"
     */
    modifier requireAlive() { 
        require(alive == true);
        _; 
    }

    /* Constructor
     * @param _manager  The account that has full control over this contract 
     */
    function MonthlySubscriptions(address _manager, address _datetime) {
        manager = _manager;
        datetime = DateTime(_datetime);
        alive = true;
    }

    /* isAlive
     * @dev Get the "alive" status for this contract
     */
    function isAlive() constant returns (bool) {
        // Send all value to the manager
        return alive;
    }

    /* makePayment
     * @dev Take payment for a subscriber.  This method uses `tx.origin` since 
     * we want to authenticate against an account, not a contract.  This also 
     * allows the user to setup whatever kind of payment contract they want.
     */
    function makePayment(uint16 year, uint8 month) public payable requireAlive {
        require(msg.value > 0);

        // Do we not know about this account?
        if (subscribers[tx.origin].exists != true) {

            // Save new Subscriber object 
            subscribers[tx.origin] = Subscriber(true);

        }

        // Set paid date
        subscribers[tx.origin].paid[year * 100 + month] = msg.value;

    }

    /* isPaid
     * @dev Has the account paid for the month?
     */
    function paidUp(address who) constant returns (uint) {
        // Send all value to the manager
        return subscribers[who].paid[uint32(datetime.getYear(now) * 100 + datetime.getMonth(now))];
    }

    /* getPayment
     * @dev Has the account paid for the specific month?
     */
    function getPayment(address who, uint16 year, uint8 month) constant returns (uint) {
        // Send all value to the manager
        return subscribers[who].paid[uint32(year * 100 + month)];
    }

    /* getManager
     * @dev Get the managing account for this contract
     */
    function getManager() constant returns (address) {
        // Send all value to the manager
        return manager;
    }

    /* setManager
     * @dev Change the managing account for this contract
     */
    function setManager(address newManager) external onlyBy(manager) requireAlive {
        // Send all value to the manager
        manager = newManager;
    }

    /* withdraw
     * @dev Drain all value from this contract
     */
    function withdraw() external onlyBy(manager) {
        // Send all value to the manager
        manager.transfer(this.balance);
    }

    /* escape
     * @dev Drain all value from this contract and disable it
     */
    function escape() external onlyBy(manager) {
        // Disable ourselves
        alive = false;
        // Send all value to the manager
        manager.transfer(this.balance);
    }

    /* Default Function 
     * @dev Handle any raw payment to this contract
     */
    function () payable requireAlive {

        // Assume they're a subscriber making a payment
        if (msg.value > 0) {

            makePayment(datetime.getYear(now), datetime.getMonth(now));

        }
    }

}