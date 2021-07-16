//SourceUnit: Tron_Flame.sol

pragma solidity 0.5.8;

/* ---> (www.tronflame.com)  | (c) 2020 Developed by TRX-ON-TOP TEAM Tron_Flame.sol | La Habana - Cuba <------ */

contract Tron_Flame {

    struct Deposit {
      uint256 amount;
      uint256 depTime;
      uint256 payout;
    }    
    
    struct Player {
        address upline;
        uint256 id;
        Deposit[] deposits;
        uint256 last_payout;
        uint256 last_withdraw;
        uint256 last_reinvest;
        uint256 depositCount;
        uint256 reinvestCount;
        uint256 dividends;
        uint256 tarifN;
        uint256 refer_bonus;
        uint256 cback_bonus;
        uint256 reinvest_bonus;
        uint256 total_deposited;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_refer_bonus;
        mapping(uint8 => uint256) structure;
    }

    address payable private dev;
    address payable private adv;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint256 private invested;
	uint256 private investors;
    uint256 private totalWithdrawn;
    uint256 private total_refer_bonus;
    uint256 private depositCount;
    
    uint256 private balance_bonus;
    uint256 private last_balance;
    uint256 private last_read_balance;
    uint256 private withdrawn_today;
  
    // Const
    uint256 private constant ADV_FEE              = 2;
    uint256 private constant MTN_FEE              = 4;
    uint256 private constant DAILY_HOLDBONUS      = 0.05E9;
    uint256 private constant MAX_HOLDBONUS        = 5E9;
    uint256 private constant UNI_POPBONUS         = 0.0005E9;
    uint256 private constant MAX_POPBONUS         = 5E9;
    uint256 private constant UNI_REINVESTBONUS    = 0.1E9;
    uint256 private constant DAILY_BALANCEBONUS   = 0.01E9;
    uint256 private constant DEFAULT_PLANBONUS    = 2E9;
    uint256 private constant MIN_PLANBONUS        = 0.4E9;
    uint256 private constant PENALTY_PLANBONUS    = 0.4E9;
    uint256 private constant MIN_INVEST           = 200E6; 
    uint256 private constant MIN_REINVEST         = 100E6; 
    uint256 private constant MIN_REINVEST_UPG     = 1000E6; 
    uint256 private constant MIN_WITHDRAW         = 100E6;
    uint256 private constant MAX_DAILY_WITHDRAW   = 200000E6;
    uint256 private constant MAX_DEPOSITS         = 100;
    uint256 private constant MAX_PLANPROFIT       = 150;
    uint256 private constant WAIT_FOR_REINVEST    = 24 * 60 * 60;
    uint256 private constant WAIT_FOR_CONF        = 24 * 60 * 60;
    uint256 private constant CONTRACT_TIMETOSTART = 24 * 60 * 60;
    uint256[] private REF_BONUSES = [4, 1, 1];
    
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event NewReinvest(address indexed addr, uint256 amount);
    event RefPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address payable _adv) public {
        adv = _adv;
        dev = msg.sender;
        contract_CreateTime = now;
        contract_StartTime = contract_CreateTime + CONTRACT_TIMETOSTART;
        last_balance = getContractBalance();
        last_read_balance = contract_StartTime;
    }

    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * REF_BONUSES[i] / 100;
            
            players[up].refer_bonus += bonus;
            players[up].total_refer_bonus += bonus;

            total_refer_bonus += bonus;

            emit RefPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != dev) {
             if(players[_upline].depositCount == 0) {
                 _upline = dev;
             }
             else {
                 players[_addr].cback_bonus += _amount * 1 / 100;
                 players[_addr].total_refer_bonus += _amount * 1 / 100;
                 total_refer_bonus += _amount * 1 / 100;
             }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount * 1 / 100);
            
            for(uint8 i = 0; i < REF_BONUSES.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }  
    
    function deposit(address _upline) external payable {
        updateDailyConf();
        Player storage player = players[msg.sender];
        
        require(player.depositCount <= MAX_DEPOSITS, "Maximum 100 deposits");
        require(msg.value >= MIN_INVEST, "Minimum deposit is 200 TRX");
    
        setUpline(msg.sender, _upline, msg.value);
        
        if (player.depositCount == 0) {
            player.last_payout = maxVal(now, contract_StartTime);
            player.last_withdraw = maxVal(now, contract_StartTime);
            player.last_reinvest = maxVal(now, contract_StartTime);
            player.tarifN = DEFAULT_PLANBONUS;
            investors++;
            player.id = investors;
        }
        
        player.deposits.push(Deposit(msg.value, maxVal(now, contract_StartTime), 0));
        
        player.depositCount++;
        player.total_deposited += msg.value;
       
        depositCount ++;
        invested += msg.value;

        payAdvFee(msg.value);
        payMtnFee(msg.value);
       
        refPayout(msg.sender, msg.value);
        
        emit NewDeposit(msg.sender, msg.value);
    }  
 
    function withdraw() external {
        updateDailyConf();
        Player storage player = players[msg.sender];
        require(now >= contract_StartTime, "Withdraw are not available yet");
        player.dividends = getTotal_InterestProfit(msg.sender);
        require(player.dividends + player.refer_bonus + player.cback_bonus >= MIN_WITHDRAW, "Minimum amount to withdraw is 100 TRX");
        require(getContractBalance() >= player.dividends + player.refer_bonus + player.cback_bonus, "Contract balance < Interest Profit");
        require(minZero(MAX_DAILY_WITHDRAW, withdrawn_today) >= player.dividends + player.refer_bonus + player.cback_bonus, "Amount exceeds daily limit");
        
        uint256 val;
		uint256 amount = player.refer_bonus + player.cback_bonus;
		
		for (uint256 i = 0; i < player.deposits.length; i++) {
		   val = getPlan_InterestProfit(msg.sender, i); 
		   player.deposits[i].payout += val;
		   amount += val;
		} 
		
		payMtnFee(amount);
		player.last_payout = now;
        player.last_withdraw = now;
		 
		uint256 cTarif = player.tarifN;
        player.tarifN = maxVal(MIN_PLANBONUS, minZero(cTarif, PENALTY_PLANBONUS));  
        
        player.dividends = 0;
        player.refer_bonus = 0; 
        player.cback_bonus = 0;
        player.reinvest_bonus = 0;
        
        player.total_withdrawn += amount;
        totalWithdrawn += amount;
        withdrawn_today += amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
    
    function reinvest() external {
        updateDailyConf();
        Player storage player = players[msg.sender];
        require(now >= contract_StartTime, "Reinvest are not available yet");
        require(player.last_reinvest + WAIT_FOR_REINVEST < now, "Reinvest are not available yet"); 
        player.dividends = getTotal_InterestProfit(msg.sender);
        require(player.dividends + player.refer_bonus + player.cback_bonus >= MIN_REINVEST, "Minimum amount to reinvest is 100 TRX");
       
        uint256 val;
		uint256 reinvestAmount = player.refer_bonus + player.cback_bonus;
		
		for (uint256 i = 0; i < player.deposits.length; i++) { 
		   val = getPlan_InterestProfit(msg.sender, i); 
		   player.deposits[i].payout += val;
		   reinvestAmount += val;
		}
		
		player.last_payout = now;
		player.last_reinvest = now;
		
        player.dividends = 0; 
        player.refer_bonus = 0; 
        player.cback_bonus = 0; 
        if (reinvestAmount >= MIN_REINVEST_UPG) {
          player.reinvest_bonus += UNI_REINVESTBONUS;  
        }
        player.deposits.push(Deposit(reinvestAmount, now, 0));
        player.reinvestCount++;
        player.total_reinvested += reinvestAmount;
        emit NewReinvest(msg.sender, reinvestAmount);
    }
    
    function updateDailyConf() internal {
        if (now > last_read_balance + WAIT_FOR_CONF) {
           uint currentBalance = getContractBalance();
           uint currenBalanceBonus = balance_bonus;
           if (currentBalance > last_balance) {
                balance_bonus = currenBalanceBonus + DAILY_BALANCEBONUS;
           } else {
                balance_bonus = minZero(currenBalanceBonus, DAILY_BALANCEBONUS);
           }
           last_read_balance += WAIT_FOR_CONF;
           last_balance = currentBalance;
           withdrawn_today = 0;
        }
    }    
    
    function getHoldBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 elapsed_time;
        if (player.depositCount > 0) {
            elapsed_time = minZero(now, player.last_withdraw);   
        } else {
            elapsed_time = 0;
        }
        return minVal(MAX_HOLDBONUS, DAILY_HOLDBONUS / 86400 * elapsed_time);
    }
    
    function getPopBonus() internal view returns(uint256) { 
        return minVal(MAX_POPBONUS, UNI_POPBONUS * investors);
    }    
    
    function getReinvestBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        return player.reinvest_bonus;
    } 
    
    function getBalanceBonus() internal view returns(uint256) { 
        return balance_bonus;
    } 
    
    function getTarif(address _addr) internal view returns(uint256) {
        Player storage player = players[_addr];
        uint256 tN = player.tarifN;
        uint256 tH = getHoldBonus(_addr);
        uint256 tP = getPopBonus();
        uint256 tR = getReinvestBonus(_addr);
        uint256 tB = getBalanceBonus();
        return tN + tH + tP + tR + tB;
    }
    
    function getPlan_InterestProfit(address _addr, uint256 plan) view private returns(uint256) {
        Player storage player = players[_addr];
		uint256 div;
		uint256 tarif = getTarif(_addr);
		   
	    uint256 fr = maxVal(player.last_payout, player.deposits[plan].depTime);  
	    uint256 to = now;
		   
        if(fr < to) {
           div = minVal(
                   minZero(player.deposits[plan].amount * MAX_PLANPROFIT / 100, player.deposits[plan].payout), 
                   player.deposits[plan].amount * (to - fr) * tarif / 86400 / 100E9
                  );
        } else {
           div = 0;
        }
		return div;
    }
    
    function getTotal_InterestProfit(address _addr) view private returns(uint256) {
        Player storage player = players[_addr];
		uint256 total_div;
		for (uint256 i = 0; i < player.deposits.length; i++) { 
		   total_div += getPlan_InterestProfit(_addr, i); 
		}
		return total_div;
    }  
    
    function getActiveDeposits(address _addr) view private returns(uint256) {
        Player storage player = players[_addr];
		uint256 amount;
		for (uint256 i = 0; i < player.deposits.length; i++) { 
		   if ( (getPlan_InterestProfit(_addr, i) > 0) || ((now < contract_StartTime) && (getPlan_InterestProfit(_addr, i) == 0)) ) {
		      amount += player.deposits[i].amount;  
		   }
		}
		return amount;        
    }

    function payAdvFee(uint256 val) private {
        uint256 amount = (val * ADV_FEE) / 100;
        adv.transfer(amount);
    }
    
    function payMtnFee(uint256 val) private {
        uint256 amount = (val * MTN_FEE) / 100;
        dev.transfer(amount);
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

    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _referBonus, uint256 _withdrawn, uint256 _withdrawnToday, uint256 _depositCount,
                                                  uint256 _contractStartTime, uint256 _contractIniTime) {
        return (
            invested,
            investors,
            total_refer_bonus,
            totalWithdrawn,
            withdrawn_today,
            depositCount,
            contract_StartTime,
            minZero(contract_StartTime, now)
        );
    } 

    function userGeneralInfo(address _addr) view external returns(address _upline, uint256 _id, uint256 _referBonus, uint256 _cbackBonus,
                                                                  uint256 _totalDeposited, uint256 _totalWithdrawn, uint256 _totalReinvested, uint256 _totalReferBonus,
                                                                  uint256[3] memory _structure) {
        Player storage player = players[_addr];
      
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.upline,
            player.id,
            player.refer_bonus,
            player.cback_bonus,
            player.total_deposited,
            player.total_withdrawn,
            player.total_reinvested,
            player.total_refer_bonus,
            _structure
        );    
    }  
    
    function userPlanInfo(address _addr) view external returns(uint256 _depositCount, uint256 _activeDeposit, uint256 _reinvestCount, uint256 _dividends, uint256 _nextReinvest, uint256 _nextResetWithdraw) {
        Player storage player = players[_addr];
        uint256 nr;
        uint256 nrw;
        if (now < contract_StartTime) {
            nr = 0;
            nrw = 0;
        } else {
            nr = minZero(player.last_reinvest + WAIT_FOR_REINVEST, now);
            nrw = minZero(last_read_balance + WAIT_FOR_CONF, now);
        }
      
        return (
            player.depositCount,
            getActiveDeposits(_addr),
            player.reinvestCount,
            getTotal_InterestProfit(_addr) + player.refer_bonus + player.cback_bonus,
            nr,
            nrw
        );    
    }  
    
    function userTarifInfo(address _addr) view external returns(uint256 _tarifN, uint256 _holdBonus, uint256 _popBonus, uint256 _reinvestBonus, uint256 _balanceBonus) {
        Player storage player = players[_addr];
        return (
            player.tarifN,
            getHoldBonus(_addr),
            getPopBonus(),
            getReinvestBonus(_addr),
            getBalanceBonus()
        );    
    }  
    
}