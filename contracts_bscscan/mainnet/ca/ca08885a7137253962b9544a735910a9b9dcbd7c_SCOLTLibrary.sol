// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Variables.sol";
import "./Address.sol";
import "./SafeMath.sol";

library SCOLTLibrary {

    // Contract imports
    using SafeMath for uint256;
    using Address for address;

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

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

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        uint256 localyear = year;
        localyear -= 1;
        return localyear / 4 - localyear / 100 + localyear / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
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
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
        public
        pure
        returns (Variables._DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
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

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
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

    function toTimestampFromDateTime(Variables._DateTime memory date)
        public
        pure
        returns (uint256 timestamp)
    {
        uint16 year = date.year;
        uint8 month = date.month;
        uint8 day = date.day;
        uint8 hour = date.hour;
        uint8 minute = date.minute;
        uint8 second = date.second;
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
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

    function _check_time_condition(
        uint256 current_timestamp,
        uint256 last_timestamp,
        uint256 diff
    ) public pure returns (bool) {
        if ((current_timestamp - last_timestamp) >= ((diff * 24) * 3600)) {
            return true;
        } else {
            return false;
        }
    }

    function _checkrules(
        Variables.wallet_details memory sender_wallet,
        Variables.wallet_details memory recipient_wallet,
        Variables.ctc_approval_details memory transferer_ctc_details,
        Variables.checkrules_additional_var memory variables
    ) public view {
        // Checking if sender requested for any C2C transfer or not
        if (transferer_ctc_details.has_value) {
            if (transferer_ctc_details.allowed_till >= block.timestamp) {
                if (!transferer_ctc_details.used) {
                    revert(
                        "SCOLT : You can not make transfer while applied for C2C transfer."
                    );
                }
            }
        }

        // Inter seller transfer not allowed
        if (variables._sellers_check_recipient) {
            if (variables._sellers_check_sender) {
                revert("SCOLT : Inter seller exchange is not allowed.");
            }
        }

        // Checking if sender or reciver is contract or not and also registered seller or not
        // Only Liquidity Wallet can create new pair in dex. ( Unregister Contract )
        if (
            variables.recipient.isContract()
        ) {
            if (variables._sellers_check_recipient) {
                if (
                    sender_wallet.wallet_type == Variables.type_of_wallet.UndefinedWallet ||
                    sender_wallet.wallet_type == Variables.type_of_wallet.DexPairWallet ||
                    sender_wallet.wallet_type == Variables.type_of_wallet.FutureTeamWallet
                ) {
                    revert(
                        "SCOLT : You are not allowed to send tokens to DexPairWallet"
                    );
                }
            } else {
                if (
                    sender_wallet.wallet_type != Variables.type_of_wallet.LiquidityWallet
                ) {
                    revert(
                        "SCOLT : You are trying to reach unregistered DexPairWallet."
                    );
                }
            }
        }

        if (
            variables.sender.isContract()
        ) {
            if (!variables._sellers_check_sender) {
                if (
                    recipient_wallet.wallet_type != Variables.type_of_wallet.LiquidityWallet
                ) {
                    revert(
                        "SCOLT : Unregistered DexPairWallet are not allowed to send tokens."
                    );
                }
            }
        }

        if (
            sender_wallet.wallet_type != Variables.type_of_wallet.GenesisWallet &&
            sender_wallet.wallet_type != Variables.type_of_wallet.DirectorWallet &&
            sender_wallet.wallet_type != Variables.type_of_wallet.UnsoldTokenWallet &&
            sender_wallet.wallet_type != Variables.type_of_wallet.GeneralWallet &&
            sender_wallet.wallet_type != Variables.type_of_wallet.DexPairWallet &&
            sender_wallet.wallet_type != Variables.type_of_wallet.FutureTeamWallet
        ) {
            if ( sender_wallet.wallet_type != Variables.type_of_wallet.LiquidityWallet ) {
                require(variables._sellers_check_recipient && variables.recipient.isContract(), "SCOLT : This type of wallet is not allowed to do this transaction.");
            } else {
                require(variables.recipient.isContract(), "SCOLT : This type of wallet is not allowed to do this transaction.");
            }
        }

        // Rules for marketing and poolairdrop
        if (
            sender_wallet.wallet_type == Variables.type_of_wallet.MarketingWallet ||
            sender_wallet.wallet_type == Variables.type_of_wallet.PoolOrAirdropWallet
        ) {
            require(
                recipient_wallet.wallet_type == Variables.type_of_wallet.GeneralWallet || variables.recipient.isContract(),
                "SCOLT : This type of wallet is not allowed to do this transaction."
            );
        }

        // FutureTeamWallet Only can send to GeneralWallet and recieve from genesis
        if ( sender_wallet.wallet_type == Variables.type_of_wallet.FutureTeamWallet ) {
            require(
                recipient_wallet.wallet_type == Variables.type_of_wallet.GeneralWallet,
                "SCOLT : You are not allowed to send any tokens other than General Type of Wallet."
            );
        }
        if ( recipient_wallet.wallet_type == Variables.type_of_wallet.FutureTeamWallet ) {
            require(
                sender_wallet.wallet_type == Variables.type_of_wallet.GenesisWallet,
                "SCOLT : You are not allowed to send any tokens to Future Team Wallet."
            );
        }

        // Checking investor block rule, time based
        if (sender_wallet.is_investor) {
            require(
                _check_time_condition(
                    block.timestamp,
                    toTimestampFromDateTime(sender_wallet.joining_date),
                    Variables._investor_swap_lock_days
                ),
                "SCOLT : Investor account can perform any transfer after 180 days only"
            );
        }

        if (variables._sellers_check_recipient && sender_wallet.anti_dump) {
            // This is for anti dump for all wallet

            // Director account restriction check.
            if (sender_wallet.wallet_type == Variables.type_of_wallet.DirectorWallet) {
                if (
                    _check_time_condition(
                        block.timestamp,
                        toTimestampFromDateTime(sender_wallet.last_sale_date),
                        1
                    )
                ) {
                    if (variables.amount > Variables._max_sell_per_director_per_day) {
                        revert(
                            "SCOLT : Director can only send 10000 SCOLT every 24 hours"
                        );
                    }
                } else {
                    if (
                        sender_wallet.lastday_total_sell + variables.amount >
                        Variables._max_sell_per_director_per_day
                    ) {
                        revert(
                            "SCOLT : Director can only send 10000 SCOLT every 24 hours"
                        );
                    }
                }
            }

            // General account restriction check.
            if (sender_wallet.wallet_type == Variables.type_of_wallet.GeneralWallet) {
                if (
                    sender_wallet.concurrent_sale_day_count >=
                    Variables._max_concurrent_sale_day
                ) {
                    if (
                        !_check_time_condition(
                            block.timestamp,
                            toTimestampFromDateTime(
                                sender_wallet.last_sale_date
                            ),
                            1
                        )
                    ) {
                        if (
                            sender_wallet.balance >= Variables._whale_per &&
                            sender_wallet.antiwhale_apply == true
                        ) {
                            if (
                                sender_wallet.lastday_total_sell + variables.amount >
                                Variables._max_sell_amount_whale
                            ) {
                                revert(
                                    "SCOLT : You can not sell more than 5000 SCOLT in past 24 hours."
                                );
                            }
                        } else {
                            if (
                                sender_wallet.lastday_total_sell + variables.amount >
                                Variables._max_sell_amount_normal
                            ) {
                                revert(
                                    "SCOLT : You can not sell more than 2000 SCOLT in past 24 hours."
                                );
                            }
                        }
                    } else {
                        if (
                            !_check_time_condition(
                                block.timestamp,
                                toTimestampFromDateTime(
                                    sender_wallet.last_sale_date
                                ),
                                Variables._cooling_days + 1
                            )
                        ) {
                            revert(
                                "SCOLT : Concurrent sell for more than 6 days not allowed. You can not sell for next 72 Hours"
                            );
                        } else {
                            if (
                                sender_wallet.balance >= Variables._whale_per &&
                                sender_wallet.antiwhale_apply == true
                            ) {
                                if (variables.amount > Variables._max_sell_amount_whale) {
                                    revert(
                                        "SCOLT : You can not sell more than 5000 SCOLT in past 24 hours."
                                    );
                                }
                            } else {
                                if (variables.amount > Variables._max_sell_amount_normal) {
                                    revert(
                                        "SCOLT : You can not sell more than 2000 SCOLT in past 24 hours."
                                    );
                                }
                            }
                        }
                    }
                } else {
                    if (
                        !_check_time_condition(
                            block.timestamp,
                            toTimestampFromDateTime(
                                sender_wallet.last_sale_date
                            ),
                            1
                        )
                    ) {
                        if (
                            sender_wallet.balance >= Variables._whale_per &&
                            sender_wallet.antiwhale_apply == true
                        ) {
                            if (
                                sender_wallet.lastday_total_sell + variables.amount >
                                Variables._max_sell_amount_whale
                            ) {
                                revert(
                                    "SCOLT : You can not sell more than 5000 SCOLT in past 24 hours."
                                );
                            }
                        } else {
                            if (
                                sender_wallet.lastday_total_sell + variables.amount >
                                Variables._max_sell_amount_normal
                            ) {
                                revert(
                                    "SCOLT : You can not sell more than 2000 SCOLT in past 24 hours."
                                );
                            }
                        }
                    } else {
                        if (
                            sender_wallet.balance >= Variables._whale_per &&
                            sender_wallet.antiwhale_apply == true
                        ) {
                            if (variables.amount > Variables._max_sell_amount_whale) {
                                revert(
                                    "SCOLT : You can not sell more than 5000 SCOLT in past 24 hours."
                                );
                            }
                        } else {
                            if (variables.amount > Variables._max_sell_amount_normal) {
                                revert(
                                    "SCOLT : You can not sell more than 2000 SCOLT in past 24 hours."
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    function _after_transfer_updates(
        uint256 amount,
        Variables.wallet_details memory sender_wallet,
        bool _sellers_check_recipient
    ) public view returns (
        Variables.wallet_details memory
    ){
        Variables._DateTime memory tdt = parseTimestamp(block.timestamp);
        Variables._DateTime memory lsd;

        lsd = Variables._DateTime(tdt.year, tdt.month, tdt.day, 0, 0, 0, tdt.weekday);

        // For Antidump rule
        if (_sellers_check_recipient) {
            // General wallet supporting entries
            if (sender_wallet.wallet_type == Variables.type_of_wallet.GeneralWallet) {
                if (
                    _check_time_condition(
                        block.timestamp,
                        toTimestampFromDateTime(sender_wallet.last_sale_date),
                        1
                    )
                ) {
                    sender_wallet.lastday_total_sell = 0; // reseting sale at 24 hours
                    if (
                        _check_time_condition(
                            block.timestamp,
                            toTimestampFromDateTime(
                                sender_wallet.last_sale_date
                            ),
                            2
                        )
                    ) {
                        sender_wallet.concurrent_sale_day_count = 1;
                    } else {
                        sender_wallet.concurrent_sale_day_count = sender_wallet
                            .concurrent_sale_day_count
                            .add(1);
                    }
                    sender_wallet.last_sale_date = lsd;
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                    if (sender_wallet.concurrent_sale_day_count == 0) {
                        sender_wallet.concurrent_sale_day_count = 1;
                        sender_wallet.last_sale_date = lsd;
                    }
                }
            }
            // Director wallet supporting entries
            if (sender_wallet.wallet_type == Variables.type_of_wallet.DirectorWallet) {
                if (
                    _check_time_condition(
                        block.timestamp,
                        toTimestampFromDateTime(sender_wallet.last_sale_date),
                        1
                    )
                ) {
                    sender_wallet.lastday_total_sell = 0; // reseting director sale at 24 hours
                    sender_wallet.last_sale_date = lsd;
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                } else {
                    sender_wallet.lastday_total_sell = sender_wallet
                        .lastday_total_sell
                        .add(amount);
                    if (sender_wallet.concurrent_sale_day_count == 0) {
                        sender_wallet.concurrent_sale_day_count = 1;
                        sender_wallet.last_sale_date = lsd;
                    }
                }
            }
        }
        return sender_wallet;
    }

    function contributionsCalc(
        Variables.wallet_details memory sender_wallet,
        Variables.wallet_details memory recipient_wallet,
        Variables.wallet_details memory marketing_wallet,
        Variables.wallet_details memory development_wallet,
        Variables.function_addresses memory addresses,
        Variables.function_amounts memory amounts
    ) public pure returns (
        Variables.distribution_variables memory,
        bool, // Sender Contribution Deduct ?
        Variables.wallet_details memory, // marketing wallet update
        Variables.wallet_details memory, // development wallet update
        uint256, // pending contribution update
        uint256, // total supply update
        uint256 // burning till now update
    ) {
        Variables.distribution_variables memory dv;

        if (addresses.sender == addresses.owner || addresses.sender == addresses.this_address) {
            return (
                dv,
                true,
                marketing_wallet,
                development_wallet,
                amounts.pending_contribution_to_distribute,
                amounts.total_supply,
                amounts.burning_till_now
            );
        }

        if (sender_wallet.contribution_apply == false) {
            return (
                dv,
                true,
                marketing_wallet,
                development_wallet,
                amounts.pending_contribution_to_distribute,
                amounts.total_supply,
                amounts.burning_till_now
            );
        }

        // Calculate contributions based on whale or not whale
        if (
            sender_wallet.balance >=  Variables._whale_per &&
            sender_wallet.antiwhale_apply == true
        ) {
            dv.total_contributions = ((amounts.amount * Variables._whale_contribution_per) / 100);
            dv.marketing_contributions = ((dv.total_contributions * Variables._whale_marketing_share) / 100);
            dv.development_contributions = ((dv.total_contributions * Variables._whale_development_share) / 100);
            dv.holder_contributions = ((dv.total_contributions * Variables._whale_holder_share) / 100);
            dv.burn_amount = ((dv.total_contributions * Variables._whale_burning_share) / 100);
        } else {
            dv.total_contributions = ((amounts.amount * Variables._normal_contribution_per) / 100);
            dv.marketing_contributions = ((dv.total_contributions * Variables._normal_marketing_share) / 100);
            dv.development_contributions = ((dv.total_contributions * Variables._normal_development_share) / 100);
            dv.holder_contributions = ((dv.total_contributions * Variables._normal_holder_share) / 100);
            dv.burn_amount = ((dv.total_contributions * Variables._normal_burning_share) / 100);
        }

        // add cut to defined acounts
        if (amounts.total_supply < (amounts.initial_total_supply / 2)) {
            dv.total_contributions = dv.total_contributions.sub(dv.burn_amount);
            dv.burn_amount = 0;
        }

        bool sender_contribution_deduct = false;

        // if contract type wallet then following condtion is default false
        if (
            (sender_wallet.balance >= amounts.amount + dv.total_contributions) &&
            (recipient_wallet.wallet_type != Variables.type_of_wallet.DexPairWallet)
        ) {
            if (dv.marketing_contributions > 0) {
                marketing_wallet.balance = marketing_wallet.balance.add(dv.marketing_contributions);
            }

            if (dv.development_contributions > 0) {
                development_wallet.balance = development_wallet.balance.add(dv.development_contributions);
            }

            if (dv.holder_contributions > 0) {
                amounts.pending_contribution_to_distribute = amounts.pending_contribution_to_distribute.add(
                    dv.holder_contributions
                );
            }

            if (dv.burn_amount > 0) {
                amounts.total_supply = amounts.total_supply.sub(dv.burn_amount);
                amounts.burning_till_now = amounts.burning_till_now.add(dv.burn_amount);
            }
            sender_contribution_deduct = true;
        } else {
            if (dv.marketing_contributions > 0) {
                marketing_wallet.balance = marketing_wallet.balance.add(dv.marketing_contributions);
            }

            if (dv.development_contributions > 0) {
                development_wallet.balance = development_wallet.balance.add(dv.development_contributions);
            }

            if (dv.holder_contributions > 0) {
                amounts.pending_contribution_to_distribute = amounts.pending_contribution_to_distribute.add(
                    dv.holder_contributions
                );
            }

            if (dv.burn_amount > 0) {
                amounts.total_supply = amounts.total_supply.sub(dv.burn_amount);
                amounts.burning_till_now = amounts.burning_till_now.add(dv.burn_amount);
            }
        }

        return (
            dv,
            sender_contribution_deduct,
            marketing_wallet,
            development_wallet,
            amounts.pending_contribution_to_distribute,
            amounts.total_supply,
            amounts.burning_till_now
        );
    }
}