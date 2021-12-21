/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: BNBPool.sol

contract BNBPool {
    // BNB Pool of Farmset.io

    address private commission_wallet;

    uint256 public total_invested;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;

    uint16 constant percent_divide_by = 1000;

    uint24 constant day_secs = 86400;
    uint8 constant commission = 100;
    uint8 constant ref_lines = 5;
    uint8[ref_lines] public ref_bonuses = [50, 30, 20, 10, 5];

    uint8 constant min_investment_days = 7;
    uint8 constant max_investment_days = 30;
    uint16 constant initial_profit_percent = 1200;
    uint8 constant profit_percent_step = 50;

    uint256 constant min_deposit = 0.01 ether;

    struct Deposit {
        uint16 invest_days;
        uint256 amount;
        uint40 time;
    }

    struct User {
        address referrer;
        uint256 invested;
        uint256 withdrawn;
        uint256 bonused;
        uint256 unwithdrawn_bonuse;
        Deposit[] deposits;
        uint40 last_withdraw;
        uint256[ref_lines] network;
    }

    mapping(address => User) public users;

    event NewUser(address indexed user, address indexed referrer);
    event NewDeposit(address indexed user, uint256 amount, uint16 invest_days);
    event NewWithdrawn(address indexed user, uint256 amount);
    event CommissionPaid(
        address indexed user,
        uint256 totalAmount,
        uint256 commissionAmount
    );
    event ReferralBonusPaid(
        address indexed referrer,
        address indexed referral,
        uint256 level,
        uint256 amount
    );

    constructor(address _commission_wallet) {
        commission_wallet = _commission_wallet;
    }

    function rewardReferrers(address _addr, uint256 _amount) private {
        address ref = users[_addr].referrer;

        for (uint8 i = 0; i < ref_lines; i++) {
            if (ref == address(0)) break;

            uint256 bonus = (_amount * ref_bonuses[i]) / percent_divide_by;

            users[ref].unwithdrawn_bonuse += bonus;

            total_referral_bonus += bonus;

            emit ReferralBonusPaid(ref, _addr, i + 1, _amount);

            ref = users[ref].referrer;
        }
    }

    function setReferrer(User storage user, address _referrer) private {
        if (user.referrer == address(0)) {
            if (users[_referrer].deposits.length == 0) {
                _referrer = commission_wallet;
            }
            user.referrer = _referrer;

            for (uint8 i = 0; i < ref_lines; i++) {
                users[_referrer].network[i]++;
                _referrer = users[_referrer].referrer;
                if (_referrer == address(0)) break;
            }
        }
    }

    function deposit(uint16 _days, address _referrer) external payable {
        require(
            min_investment_days <= _days && _days <= max_investment_days,
            "Out of investment days range"
        );
        require(msg.value >= min_deposit, "Deposit less than minimum");

        User storage user = users[msg.sender];

        if (msg.sender != commission_wallet) {
            setReferrer(user, _referrer);
        }

        if (user.deposits.length == 0) {
            emit NewUser(msg.sender, user.referrer);
        }

        user.deposits.push(
            Deposit({
                invest_days: _days,
                amount: msg.value,
                time: uint40(block.timestamp)
            })
        );

        user.invested += msg.value;
        total_invested += msg.value;

        rewardReferrers(msg.sender, msg.value);

        uint256 commissionAmount = (msg.value * commission) / percent_divide_by;
        payable(commission_wallet).transfer(commissionAmount);
        emit CommissionPaid(msg.sender, msg.value, commissionAmount);

        emit NewDeposit(msg.sender, msg.value, _days);
    }

    function withdraw() external {
        User storage user = users[msg.sender];

        uint256 revenue = this.revenueOf(msg.sender, block.timestamp);

        require(revenue > 0 || user.unwithdrawn_bonuse > 0, "Zero amount");

        if (revenue > 0) {
            user.last_withdraw = uint40(block.timestamp);
        }

        uint256 amount = revenue + user.unwithdrawn_bonuse;
        require(
            address(this).balance > amount,
            "Insufficient funds, try again later."
        );

        user.bonused += user.unwithdrawn_bonuse;
        user.unwithdrawn_bonuse = 0;

        user.withdrawn += amount;
        total_withdrawn += amount;

        payable(msg.sender).transfer(amount);

        emit NewWithdrawn(msg.sender, amount);
    }

    function revenueOf(address _addr, uint256 _at)
        external
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            uint256 profit_percent = this.getProfitPercentage(dep.invest_days);

            uint40 time_end = dep.time + dep.invest_days * day_secs;
            uint40 from = user.last_withdraw > dep.time
                ? user.last_withdraw
                : dep.time;
            uint40 to = _at > time_end ? time_end : uint40(_at);

            if (from < to) {
                value =
                    ((dep.amount * (to - from) * profit_percent) /
                        dep.invest_days /
                        day_secs) /
                    percent_divide_by;
            }
        }

        return value;
    }

    function getProfitPercentage(uint256 _days)
        external
        view
        returns (uint256 percent)
    {
        require(
            min_investment_days <= _days && _days <= max_investment_days,
            "Out of investment days range"
        );
        return (initial_profit_percent +
            (_days - min_investment_days) *
            profit_percent_step);
    }

    function getContractInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _referral_bonus
        )
    {
        return (total_invested, total_withdrawn, total_referral_bonus);
    }

    function getUserInfo(address _addr)
        external
        view
        returns (
            uint256 revenue_for_withdraw,
            uint256 bonus_for_withdraw,
            uint256 invested,
            uint256 withdrawn,
            uint256 bonused,
            uint256[ref_lines] memory network,
            Deposit[] memory deposits,
            uint40 revenue_end_time,
            uint256 revenue_at_last
        )
    {
        User storage user = users[_addr];

        uint256 revenue = this.revenueOf(_addr, block.timestamp);

        for (uint8 i = 0; i < ref_lines; i++) {
            network[i] = user.network[i];
        }

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            uint40 time_end = dep.time + dep.invest_days * day_secs;
            if (time_end > revenue_end_time) revenue_end_time = time_end;
        }
        revenue_at_last = this.revenueOf(_addr, revenue_end_time);

        return (
            revenue,
            user.unwithdrawn_bonuse,
            user.invested,
            user.withdrawn,
            user.bonused,
            network,
            user.deposits,
            revenue_end_time,
            revenue_at_last
        );
    }
}