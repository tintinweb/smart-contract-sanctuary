//SourceUnit: tron8city.sol

pragma solidity 0.5.8;


contract tron8city {

    struct Deposit {
      uint256 amount;
      uint256 depTime;
      uint256 payout;
    }    
    
    struct Player {
        address upline;
        Deposit[] deposits;
        uint256 id;
        bool imlucky; 
        uint256 last_payout;
        uint256 last_withdraw;
        uint256 last_reinvest;
        uint256 reinvest_active;
        uint256 depositCount;
        uint256 reinvestCount;
        uint256 dividends;
        uint256 tarifN;
        uint256 oldRef;
        uint256 refer_bonus;
        uint256 cback_bonus;
        uint256 lucky_bonus;
        uint256 total_deposited;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_refer_bonus;
        mapping(uint8 => uint256) structure;
    }

    address payable private dev;
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
    
    uint256[10] private luckyNumbers; 
    uint8[] private ref_bonuses;
  
    // Const
    uint256 private constant ADVERTISING_FEE      = 10;
    uint256 private constant MAINTENANCE_FEE      = 5; 
    uint256 private constant DAILY_HOLDBONUS      = 0.2E9;
    uint256 private constant MAX_HOLDBONUS        = 5E9;
    uint256 private constant UNI_TEAMBONUS        = 0.1E9;
    uint256 private constant MAX_TEAMBONUS        = 10E9;
    uint256 private constant UNI_REINVESTBONUS    = 0.3E9;
    uint256 private constant DAILY_BALACEBONUS    = 0.2E9;
    uint256 private constant DEFAULT_PLANBONUS    = 8E9;
    uint256 private constant MIN_PLANBONUS        = 1E9;
    uint256 private constant PENALTY_PLANBONUS    = 1E9;
    uint256 private constant DEFAULT_LUCKY_BONUS  = 100E6;
    uint256 private constant MIN_INVEST           = 20E6;         
    uint256 private constant MAX_PLANPROFIT       = 320;
    uint256 private constant WAIT_FOR_REINVEST    = 24 * 60 * 60;
    uint256 private constant WAIT_FOR_BALANCE     = 24 * 60 * 60;
    uint256 private constant CONTRACT_TIMETOSTART = 0 * 24 * 60 * 60;
    
    mapping(address => Player) private players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        dev = msg.sender;
        ref_bonuses.push(10);
        contract_CreateTime = now;
        contract_StartTime = contract_CreateTime + CONTRACT_TIMETOSTART;
        last_balance = getContractBalance();
        last_read_balance = contract_StartTime;        
        for (uint256 i = 0; i < luckyNumbers.length; i++) { 
           luckyNumbers[i] = getLuckyNumber(i*i); 
        } 
    }

    function getLuckyNumber(uint256 param) view private returns (uint256) { 
        uint8 value = uint8(uint256(keccak256(abi.encode(block.timestamp + param, block.difficulty + param)))%300) + 1; 
        return value;
    }	

    function refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            players[up].refer_bonus += bonus;
            players[up].total_refer_bonus += bonus;

            total_refer_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

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
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }  
    
    function deposit(address _upline) external payable {
        updateBalanceBonus();
        Player storage player = players[msg.sender];
        
        require(now >= contract_StartTime, "Deposits are not available yet");
        require(msg.value >= MIN_INVEST, "Minimum deposit is 20 TRX");
    
        setUpline(msg.sender, _upline, msg.value);
        
        if (player.depositCount == 0) {
            player.last_payout = now;
            player.last_withdraw = now;
            player.last_reinvest = now;
            player.tarifN = DEFAULT_PLANBONUS;
            investors+=2;
            player.id = investors;
            player.imlucky = false;
            for (uint256 i = 0; i < luckyNumbers.length; i++) { 
              if (player.id == luckyNumbers[i]) {
                 player.imlucky = true; 
                 player.lucky_bonus = DEFAULT_LUCKY_BONUS;
                 break;
              }  
            }    
        }
        
        player.deposits.push(Deposit(msg.value, now, 0));
        
        player.depositCount++;
        player.total_deposited += msg.value;
       
        depositCount ++;
        invested += msg.value;

        payAdvFee(msg.value);
       
        refPayout(msg.sender, msg.value);
        
        emit NewDeposit(msg.sender, msg.value);
    }    
 
    function withdraw() external {
        updateBalanceBonus();
        Player storage player = players[msg.sender];
        player.dividends = getTotal_InterestProfit(msg.sender);
        require(getContractBalance() >= player.dividends + player.refer_bonus + player.cback_bonus + player.lucky_bonus, "Contract balance < Interest Profit");
       
        uint256 val;
		uint256 amount = player.refer_bonus + player.cback_bonus + player.lucky_bonus;
		
		for (uint256 i = 0; i < player.deposits.length; i++) {
		   val = getPlan_InterestProfit(msg.sender, i); 
		   player.deposits[i].payout += val;
		   amount += val;
		} 
		
		payMtcFee(amount);
		player.oldRef = player.structure[0];
		player.last_payout = now;
        player.last_withdraw = now;
		 
		uint256 cTarif = player.tarifN;
        player.tarifN = maxVal(MIN_PLANBONUS, minZero(cTarif, PENALTY_PLANBONUS));  
        
        player.dividends = 0;
        player.refer_bonus = 0; 
        player.cback_bonus = 0;
        player.lucky_bonus = 0;
        player.reinvest_active = 0;
        
        player.total_withdrawn += amount;
        totalWithdrawn += amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
    
    function reinvest() external {
        updateBalanceBonus();
        Player storage player = players[msg.sender];
        require(player.last_reinvest + WAIT_FOR_REINVEST < now, "Reinvest is not available yet"); 
        uint256 val;
		uint256 reinvestAmount = player.refer_bonus + player.cback_bonus + player.lucky_bonus;
		
		for (uint256 i = 0; i < player.deposits.length; i++) { 
		   val = getPlan_InterestProfit(msg.sender, i); 
		   player.deposits[i].payout += val;
		   reinvestAmount += val;
		} 
		
		player.last_payout = now;
		player.last_reinvest = now;
		player.reinvest_active++;
		
        player.dividends = 0; 
        player.refer_bonus = 0; 
        player.cback_bonus = 0; 
        player.lucky_bonus = 0;
        player.deposits.push(Deposit(reinvestAmount, now, 0));
        player.reinvestCount++;
        player.total_reinvested += reinvestAmount;
        emit NewDeposit(msg.sender, reinvestAmount);
    }
    
    function updateBalanceBonus() internal {
        if (now > last_read_balance + WAIT_FOR_BALANCE) {
           uint currentBalance = getContractBalance();
           uint currenBalanceBonus = balance_bonus;
           if (currentBalance > last_balance) {
                balance_bonus = currenBalanceBonus + DAILY_BALACEBONUS;
           } else {
                balance_bonus = minZero(currenBalanceBonus, DAILY_BALACEBONUS);
           }
           last_read_balance = now;
           last_balance = currentBalance;
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
    
    function getTeamBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 newRef = minZero(player.structure[0], player.oldRef);
        return minVal(UNI_TEAMBONUS * newRef, MAX_TEAMBONUS);
    }    
    
    function getReinvestBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        return UNI_REINVESTBONUS * player.reinvest_active;
    }      
    
    function getLuckyBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        return player.lucky_bonus;
    }    
    
    function getBalanceBonus() internal view returns(uint256) { 
        return balance_bonus;
    } 
    
    function getTarif(address _addr) internal view returns(uint256) {
        Player storage player = players[_addr];
        uint256 tN = player.tarifN;
        uint256 tH = getHoldBonus(_addr);
        uint256 tT = getTeamBonus(_addr);
        uint256 tR = getReinvestBonus(_addr);
        uint256 tB = getBalanceBonus();
        return tN + tH + tT + tR + tB;
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
		   if (getPlan_InterestProfit(_addr, i) > 0) {
		      amount += player.deposits[i].amount;  
		   }
		}
		return amount;        
    }

    function payAdvFee(uint256 val) private {
        uint256 amount = (val * ADVERTISING_FEE) / 100;
        dev.transfer(amount);
    }
    
    function payMtcFee(uint256 val) private {
        uint256 amount = (val * MAINTENANCE_FEE) / 100;
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

    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _referBonus, uint256 _withdrawn, uint256 _depositCount,
                                                  uint256 _contractStartTime, uint256 _contractIniTime) {
        return (
            invested,
            investors,
            total_refer_bonus,
            totalWithdrawn,
            depositCount,
            contract_StartTime,
            minZero(contract_StartTime, now)
        );
    } 

    function userGeneralInfo(address _addr) view external returns(address _upline, uint256 _id,  bool _imLucky, uint256 _referBonus, uint256 _cbackBonus,
                                                                  uint256 _totalDeposited, uint256 _totalWithdrawn, uint256 _totalReinvested, uint256 _totalReferBonus,
                                                                  uint256 _refLevel1, uint256[3] memory _structure) {
        Player storage player = players[_addr];
      
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
        }
        return (
            player.upline,
            player.id,
            player.imlucky,
            player.refer_bonus,
            player.cback_bonus,
            player.total_deposited,
            player.total_withdrawn,
            player.total_reinvested,
            player.total_refer_bonus,
            player.structure[0],
            _structure
        );    
    }  
    
    function userPlanInfo(address _addr) view external returns(uint256 _depositCount, uint256 _activeDeposit, uint256 _reinvestCount, uint256 _dividends, uint256 _nextReinvest) {
        Player storage player = players[_addr];
        return (
            player.depositCount,
            getActiveDeposits(_addr),
            player.reinvestCount,
            getTotal_InterestProfit(_addr) + player.refer_bonus + player.cback_bonus + player.lucky_bonus,
            minZero(player.last_reinvest + WAIT_FOR_REINVEST, now)
        );    
    }  
    
    function userTarifInfo(address _addr) view external returns(uint256 _tarifN, uint256 _holdBonus, uint256 _teamBonus, uint256 _reinvestBonus, uint256 _balanceBonus, uint256 _giftBonus) {
        Player storage player = players[_addr];
        return (
            player.tarifN,
            getHoldBonus(_addr),
            getTeamBonus(_addr),
            getReinvestBonus(_addr),
            getBalanceBonus(),
            player.lucky_bonus
        );    
    }  
    
}