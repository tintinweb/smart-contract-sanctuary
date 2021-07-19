//SourceUnit: Tronearning.sol

/**
*
* TronEarningClub
*
* https://tronearning.club/
* (make your dreams a reality)
* Crowdfunding And Investment Program: 15% Daily ROI for 12 Days.
*
* A Massive Referral Program
* 1st Level = 5%
* 2nd Level = 5%
* 3rd Level = 5%
* 4th Level = 5%
* 5th Level = 2%
* 6th Level = 2%
* 7th Level = 2%
*
**/

pragma solidity ^0.5.10;

contract Tronearning
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
        uint256 total_reinvested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        uint256 total_profit;
        mapping(uint8 => bool) levels;
        uint256 highest_investment;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) display_referrals_per_level;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable public marketing;
	address payable public development;

    uint256 public constant DEVELOPER_RATE = 50;            // 5% Team, Operation & Development
    uint256 public constant MARKETING_RATE = 50;            // 5% Marketing

    uint8 investment_days;
    uint256 investment_perc;

    uint256 display_investors;
    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint8[] referral_bonuses;

    mapping(address => Player) public players;

    constructor() public {
        marketing = msg.sender;
		development = msg.sender;

        investment_days = 12;
        investment_perc = 180;
    }

    modifier onlyMarketing(){
        require(msg.sender == marketing);
        _;
    }

    modifier onlyDevelopment(){
        require(msg.sender == development);
        _;
    }

    function deposit(address _referral) public payable {
        require(msg.value >= 100000000, "Minimum deposit: 100 TRX"); // Minimum 100 TRX Deposit
        Player storage player = players[msg.sender];
        require(msg.value >= player.highest_investment, "Invest more than or equal to last investment");

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
        }else {
            if(player.highest_investment < msg.value) {
                // Got the new highest investment
                player.highest_investment = msg.value;
            }
        }

        player.total_invested += msg.value;
        player.is_active = true;
        total_invested += msg.value;

        uint256 developerPercentage = (msg.value.mul(DEVELOPER_RATE)).div(1000);
        development.transfer(developerPercentage);
        uint256 marketingPercentage = (msg.value.mul(MARKETING_RATE)).div(1000);
        marketing.transfer(marketingPercentage);

        _referralPayout(msg.sender, msg.value);
    }

    function withdraw() payable public {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus;

        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        uint256 reinvestAmount = (amount.mul(300)).div(1000); // Calculating 30% reinvesting amount
        uint256 remainingAmount = amount - reinvestAmount;

        player.deposits.push(PlayerDeposit({
            amount: reinvestAmount, // 30% Auto Reinvestment
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            isActive: true
        }));
        player.total_reinvested += reinvestAmount;

        uint256 developerPercentage = (amount.mul(DEVELOPER_RATE)).div(1000);
        development.transfer(developerPercentage);
        uint256 marketingPercentage = (amount.mul(MARKETING_RATE)).div(1000);
        marketing.transfer(marketingPercentage);

        msg.sender.transfer(remainingAmount);
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_addr].levels[0] = false;
            players[_addr].levels[1] = false;
            players[_addr].levels[2] = false;
            players[_addr].levels[3] = false;
            players[_addr].levels[4] = false;
            players[_addr].levels[5] = false;
            players[_addr].levels[6] = false;
            
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

            for(uint8 i = 1; i < 7; i++) {
                if(_referral == address(0)) break;
                _checkInvestmentStatus(_referral);

                bool allowed = false;
                if(players[_referral].is_active && players[_referral].total_invested != 0x0) {
                    if(i == 1) {
                        if(players[_referral].levels[1]) {
                            allowed = true;
                        }
                    }else if(i == 2) {
                        if(players[_referral].levels[2]) {
                            allowed = true;
                        }
                    }else if(i == 3) {
                        if(players[_referral].levels[3]) {
                            allowed = true;
                        }
                    }else if(i == 4) {
                        if(players[_referral].levels[4]) {
                            allowed = true;
                        }
                    }else if(i == 5) {
                        if(players[_referral].levels[5]) {
                            allowed = true;
                        }
                    }else if(i == 6) {
                        if(players[_referral].levels[6]) {
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
        if(directReferralsCount == 1 && !players[_addr].levels[0]) {
            players[_addr].levels[0] = true;
        }else if(directReferralsCount == 2 && !players[_addr].levels[1]) {
            players[_addr].levels[1] = true;
        }else if(directReferralsCount == 3 && !players[_addr].levels[2]) {
            players[_addr].levels[2] = true;
        }else if(directReferralsCount == 4 && !players[_addr].levels[3]) {
            players[_addr].levels[3] = true;
        }else if(directReferralsCount == 5 && !players[_addr].levels[4]) {
            players[_addr].levels[4] = true;
        }else if(directReferralsCount == 6 && !players[_addr].levels[5]) {
            players[_addr].levels[5] = true;
        }else if(directReferralsCount == 7 && !players[_addr].levels[6]) {
            players[_addr].levels[6] = true;
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for(uint8 i = 0; i < 7; i++) {
            if(ref == address(0)) break;

            _checkInvestmentStatus(ref);

            bool allowed = false;
            if(players[ref].is_active && players[ref].total_invested != 0x0) {
                if(i == 0) {
                    if(players[ref].levels[0]) {
                        allowed = true;
                    }
                }else if(i == 1) {
                    if(players[ref].levels[1]) {
                        allowed = true;
                    }
                }else if(i == 2) {
                    if(players[ref].levels[2]) {
                        allowed = true;
                    }
                }else if(i == 3) {
                    if(players[ref].levels[3]) {
                        allowed = true;
                    }
                }else if(i == 4) {
                    if(players[ref].levels[4]) {
                        allowed = true;
                    }
                }else if(i == 5) {
                    if(players[ref].levels[5]) {
                        allowed = true;
                    }
                }else if(i == 6) {
                    if(players[ref].levels[6]) {
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

                uint bonusPercentage = 0;
                if(i == 0) {
                    bonusPercentage = 50;
                }else if(i == 1) {
                    bonusPercentage = 50;
                }else if(i == 2) {
                    bonusPercentage = 50;
                }else if(i == 3) {
                    bonusPercentage = 50;
                }else if(i == 4) {
                    bonusPercentage = 20;
                }else if(i == 5) {
                    bonusPercentage = 20;
                }else if(i == 6) {
                    bonusPercentage = 20;
                }
                uint256 bonus = calculation_amount * bonusPercentage / 1000;

                players[ref].referral_bonus += bonus;
                players[ref].total_referral_bonus += bonus;
                total_referral_bonus += bonus;
            }

            ref = players[ref].referral;
        }
    }
    
    function _payout(address _addr) public {
        (uint256 payout, uint256 profit) = this.payoutOf(_addr);

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
                uint256 depositDividendAmount = dep.amount * (to - from) * investment_perc / investment_days / 8640000;
                uint256 dividendProfit =depositDividendAmount - ((depositDividendAmount * 100) / 120);

                player.deposits[i].totalWithdraw += depositDividendAmount;
                player.total_profit += dividendProfit;
            }
        }
    }

    function payoutOf(address _addr) view public returns(uint256 value, uint256 profit) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                uint256 depositDividendAmount = dep.amount * (to - from) * investment_perc / investment_days / 8640000;
                uint256 dividendProfit = depositDividendAmount - ((depositDividendAmount * 100) / 120);

                value += depositDividendAmount;
                profit += dividendProfit;
            }
        }

        return (value, profit);
    }

    function contractInfo() view public returns(uint256 _total_balance, uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus, uint256 _display_investors) {
        return (address(this).balance, total_invested, total_investors, total_withdrawn, total_referral_bonus, display_investors);
    }

    function userInfo(address _addr) view public returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256 reinvested, uint256 withdrawable, uint256[8] memory referrals, bool is_active) {
        bool activeStatus = _userInvestmentStatus(_addr);

        Player storage player = players[_addr];
        (uint256 payout, uint256 profit) = this.payoutOf(_addr);

        for(uint8 i = 0; i < 7; i++) {
            referrals[i] = player.display_referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            player.total_reinvested,
            player.dividends + player.referral_bonus,
            referrals,
            activeStatus
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

    function _userInvestmentStatus(address _addr) view private returns (bool) {
        Player storage player = players[_addr];
        uint256 activeInvestments = player.deposits.length;

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            if(dep.isActive) {
                uint endTime = dep.time + investment_days * 86400;

                if(block.timestamp > endTime) {
                    activeInvestments--;
                }
            }else {
                activeInvestments--;
            }
        }

        if(activeInvestments == 0) {
            return false;
        }

        return true;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function changeMarketing(address payable addr) public onlyMarketing {
        marketing = addr;
    }

    function changeDevelopment(address payable addr) public onlyDevelopment {
        development = addr;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}