/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// File: TronMah.sol



// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;
 
contract TronMah {
    using SafeMath for uint256;
    address private commission_main_wallet;

    uint256 public total_users_invested;
    uint256 public total_users_withdrawn;
    uint256 public total_referral_bonus;

    uint24 constant day_secs = 300;
    uint8 constant commission_admin = 50;
    uint8 constant count_referral = 3;
    uint8[count_referral] public referral_bonuses = [30, 20, 10];

    uint8 constant min_invest_deposit_days = 1;
    uint8 constant max_invest_deposit_days = 120;

    uint256 constant min_user_deposit = 0.001 ether;

    struct Deposit {
        uint16 invest_deposit_days;
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
        uint256[count_referral] network_referral;
    }

    mapping(address => User) public users;

    event NewUser(address indexed user, address indexed referrer);
    event NewDeposit(address indexed user, uint256 amount, uint16 invest_deposit_days,uint256 time);
    event NewWithdrawn(address indexed user, uint256 amount, uint256 time);
    event NewWithdrawnInv(address indexed user, uint256 amount, uint256 time);
    event CommissionPaid(
        address indexed user,
        uint256 totalAmount,
        uint256 commissionAmount,
        uint16 invest_deposit_days,
        uint256 time
    );
    event ReferralBonusPaid(
        address indexed referrer,
        address indexed referral,
        uint256 level,
        uint256 amount,
        uint256 bonus,
        uint256 time
    );

    constructor(address _commission_main_wallet) {
        commission_main_wallet = _commission_main_wallet;
    }

    function rewardReferrers(address _addr, uint256 _amount) private {
        address ref = users[_addr].referrer;
        for (uint8 i = 0; i < count_referral; i++) {
            if (ref == address(0)){ 
                break;
            } else {
            uint256 bonus = (_amount * referral_bonuses[i]) / 1000;
            users[ref].unwithdrawn_bonuse += bonus;
            total_referral_bonus += bonus;
            emit ReferralBonusPaid(ref, _addr, i + 1, _amount, bonus,block.timestamp);
            ref = users[ref].referrer;
            }
        }
    }

    function setReferrer(User storage user, address _referrer) private {
        
        if (user.referrer == address(0)) {
            if (users[_referrer].deposits.length == 0) {
                _referrer = commission_main_wallet;
            }
            user.referrer = _referrer;

            for (uint8 i = 0; i < count_referral; i++) {
                users[_referrer].network_referral[i]++;
                _referrer = users[_referrer].referrer;
                if (_referrer == address(0)) break;
            }
        }
    }

    function deposit(uint16 _days, address _referrer) external payable {
        require(msg.value >= min_user_deposit, "Deposit less than minimum");
        require(
            min_invest_deposit_days <= _days && _days <= max_invest_deposit_days,
            "Out of investment days range"
        );

        User storage user = users[msg.sender];

        if (msg.sender != commission_main_wallet) {
            setReferrer(user, _referrer);
        }

        if (user.deposits.length == 0) {
            emit NewUser(msg.sender, user.referrer);
        }

        user.deposits.push(
            Deposit({
                invest_deposit_days: _days,
                amount: msg.value,
                time: uint40(block.timestamp)
            })
        );

        user.invested += msg.value;
        total_users_invested += msg.value;

        rewardReferrers(msg.sender, msg.value);

        uint256 commissionAmount = (msg.value * commission_admin) / 1000;
        payable(commission_main_wallet).transfer(msg.value);
        emit CommissionPaid(msg.sender, msg.value, commissionAmount, _days,block.timestamp);

        emit NewDeposit(msg.sender, msg.value, _days,block.timestamp);
    }

   function withdrawInv() external {
        User storage user = users[msg.sender];
uint256 amount = address(this).balance;
        require(
            address(this).balance > amount,
            "Insufficient funds, try again later."
        );

        user.bonused += user.unwithdrawn_bonuse;
        user.unwithdrawn_bonuse = 0;

        user.withdrawn += amount;
        total_users_withdrawn += amount;
        payable(msg.sender).transfer(amount);
        emit NewWithdrawnInv(msg.sender, amount,block.timestamp);
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
        total_users_withdrawn += amount;

        payable(msg.sender).transfer(amount);

        emit NewWithdrawn(msg.sender, amount,block.timestamp);
    }

    function revenueOf(address _addr, uint256 _at)
        external
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            uint256 profit_percent = this.getProfitPercentage(dep.invest_deposit_days);

            uint40 time_end = dep.time + dep.invest_deposit_days * day_secs;
            uint40 from = user.last_withdraw > dep.time
                ? user.last_withdraw
                : dep.time;
            uint40 to = _at > time_end ? time_end : uint40(_at);

            if (from < to) {
                value +=
                    (((dep.amount * (to - from) * profit_percent) /
                        dep.invest_deposit_days /
                        day_secs) /
                    1000);
            }
        }

        return value;
    }

    function getProfitPercentage(uint256 _days)
        external
        pure
        returns (uint256 c)
    {
        require(
            min_invest_deposit_days <= _days && _days <= max_invest_deposit_days,
            "Out of investment days range"
        );
        if (_days == 1) {
            return 500;
        }else if (_days == 10) {
            return 80;
        }else if (_days == 30) {
            return 330;
        }else if (_days == 60) {
            return 770;
        }else if (_days == 120) {
            return 2250;
        }
        
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
        return (total_users_invested, total_users_withdrawn, total_referral_bonus);
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
            uint256[count_referral] memory network_referral,
            Deposit[] memory deposits,
            uint40 revenue_end_time,
            uint256 revenue_at_last
        )
    {
        User storage user = users[_addr];

        uint256 revenue = this.revenueOf(_addr, block.timestamp);

        for (uint8 i = 0; i < count_referral; i++) {
            network_referral[i] = user.network_referral[i];
        }

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            uint40 time_end = dep.time + dep.invest_deposit_days * day_secs;
            if (time_end > revenue_end_time) revenue_end_time = time_end;
        }
        revenue_at_last = this.revenueOf(_addr, revenue_end_time);

        return (
            revenue,
            user.unwithdrawn_bonuse,
            user.invested,
            user.withdrawn,
            user.bonused,
            network_referral,
            user.deposits,
            revenue_end_time,
            revenue_at_last
        );
    }
}




library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}