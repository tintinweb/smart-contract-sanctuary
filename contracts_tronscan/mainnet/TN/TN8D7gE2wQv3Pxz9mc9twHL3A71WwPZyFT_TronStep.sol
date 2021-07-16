//SourceUnit: TronStep.sol

pragma solidity 0.5.10;

/* ---> (www.trxstep.com)  | (c) 2020 Developed by TRX-ON-TOP TEAM TronStep.sol | La Habana - Cuba <------ */

contract TronStep {

    struct Deposit {
      uint256 amount;
      uint256 depTime;
      uint256 payout;
    } 
    
    struct cLottery {
      uint256 userId;
      uint256 ticketNumber;
    }   
    
    struct pLottery {
      uint256 currentTicketsCount;
      uint256 totalTicketsCount;
      uint256 totalCycles;
      uint256 profits;
      uint256 totalProfits;
      uint256 withdrawn;
    }      
    
    struct Player {
        address upline;
        uint256 id;
        Deposit[] deposits;
        pLottery lottery;
        uint256 last_deposit;
        uint256 last_payout;
        uint256 last_withdraw;
        uint256 deposit_count;
        uint256 refer_bonus;
        uint256 total_deposited;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_refer_bonus;
        uint256 deposited_in_current_halfday;
        uint256 last_current_halfday;
        mapping(uint8 => uint256) structure;
    }
    
    address payable private owner;
    address payable private dev_1;
    address payable private dev_2;
    address payable private adv_1;
    uint256 private contract_CreateTime;
    uint256 private contract_StartTime;
    uint256 private invested;
	uint256 private investors;
    uint256 private total_withdrawn;
    uint256 private total_refer_bonus;
    uint256 private max_reached_balance;
    
    // Lottery
    cLottery[] currentLottery;
    uint256 lotteryCurrentTicketsCount;
    uint256 lotteryCurrentPot;
    uint256 lotteryAmountAcum;
    uint256 lotteryLastTicket;
    uint256 lotteryTotalTicketsCount;
    uint256 lotteryTotalCycles;
    uint256 lotteryNextCycleTime;
    address lotteryLastWin1a;
    address lotteryLastWin2a;
    address lotteryLastWin3a;
    uint256 lotteryLastWin1n;
    uint256 lotteryLastWin2n;
    uint256 lotteryLastWin3n;    
    
    // Const
    uint256 private constant ADV_FEE               = 40;
    uint256 private constant DEV_FEE               = 30;
    uint256 private constant BASIC_PROFIT          = 1E9;
    uint256 private constant MAX_DEPOSITS_COUNT    = 200;
    uint256 private constant MAX_PLANPROFIT        = 200; 
    uint256 private constant AUTO_REINVEST_PERCENT = 10;
    uint256 private constant MIN_INVEST            = 200E6; 
    uint256 private constant MIN_WITHDRAW          = 100E6;
    uint256 private constant TIME_TO_NEXT_LOTTERY  = 10 * 60;
    uint256 private constant WAIT_FOR_WITHDRAW     = 24 * 60 * 60; 
    uint256 private constant WAIT_FOR_INVEST       = 24 * 60 * 60;
    uint256 private constant LOTTERY_TICKETS_LIMIT = 50;
    uint256 private constant LOTTERY_TICKETS_COST  = 50E6;
    uint256[] private LOTTERY_WIN_PERCENT          = [30, 20, 10];
    uint256 private constant CONTRACT_TIMETOSTART  = 3 * 60 * 60;
    uint256[] private REF_BONUSES                  = [4, 2, 1];
    
    mapping(address => Player) internal players;
    mapping(uint => uint) internal deposited;       
    mapping(uint => uint) internal withdrawn;         
    mapping(uint256 => address) internal idToAddress;  
   
    event NewDepositPlan(address indexed addr, uint256 amount);
    event NewReinvest(address indexed addr, uint256 amount);
    event RefPayout(address indexed addr, address indexed from, uint256 amount);
    event WithdrawPlan(address indexed addr, uint256 amount);
    event NewDepositLottery(address indexed addr, uint256 amount, uint256 tickets);
    event WithdrawLottery(address indexed addr, uint256 amount);

    constructor(address payable adv1, address payable dev1, address payable dev2) public {
        adv_1 = adv1;    
        dev_1 = dev1;   
        dev_2 = dev2;   
        owner = msg.sender;
        contract_CreateTime = now;
        contract_StartTime = contract_CreateTime + CONTRACT_TIMETOSTART;
        lotteryNextCycleTime = contract_StartTime;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    } 
    
    function getCurrentHalfDayPublicLimit() internal view returns (uint) {
        uint256 limit;
        uint256 CHD = minZero(now, contract_StartTime) / 43200 + 1;
        
        if (CHD >= 0  && CHD < 5) {
               limit = 50000E6 * CHD;
        } else if
           (CHD >= 5  && CHD < 9) {
               limit = 200000E6 + 100000E6 * minZero(CHD, 4);
        } else if
           (CHD >= 9  && CHD < 21) {
               limit = 600000E6 + 150000E6 * minZero(CHD, 8);
        } else if
           (CHD >= 21 && CHD < 41) {
               limit = 2400000E6 + 200000E6 * minZero(CHD, 20);
        } else if
           (CHD >= 41) {
               limit = 6400000E6 + 250000E6 * minZero(CHD, 40);
        }
        return limit;
    }    
    
    function getCurrentHalfDayPersonalLimit() internal view returns (uint256) {
        uint256 limit;
        if (invested <= 150000E6) {
            limit = 200E6;
        } else {
            limit = invested * 10 / 100;
        }
        return limit;
    }

    function getCurrentDay() public view returns (uint256) {
        return minZero(now, contract_StartTime) / 86400;
    }    

    function getCurrentHalfDay() public view returns (uint256) {
        return minZero(now, contract_StartTime) / 43200;
    }    

    function getCurrentHalfDayInvested() public view returns (uint256) {
        return deposited[getCurrentHalfDay()];
    }
    
    function getCurrentHalfDayPublicAvailable() public view returns (uint256) {
        return minZero(getCurrentHalfDayPublicLimit(), getCurrentHalfDayInvested());
    }    
    
    function getCurrentHalfDayPersonalAvailable(address _addr) public view returns (uint256) {
        Player storage player = players[_addr];
        return minZero(getCurrentHalfDayPersonalLimit(), player.deposited_in_current_halfday);
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

    function setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
             if(players[_upline].deposit_count == 0) {
                 _upline = owner;
             }

            players[_addr].upline = _upline;
            
            for(uint8 i = 0; i < REF_BONUSES.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }  
    
    function lotteryDeposit(uint nt) external payable {
        Player storage player = players[msg.sender];
        require(now >= lotteryNextCycleTime, "Lottery deposit not available yet");
        require(player.deposit_count > 0, "Main deposit is require first");
        require(nt >= 1, "Minimum number of tickets is 1");
        require(LOTTERY_TICKETS_LIMIT >= nt + lotteryCurrentTicketsCount, "Maximum number of tickets exceed"); 
        require(msg.value == nt * LOTTERY_TICKETS_COST, "Wrong Amount");
        
        if (lotteryCurrentTicketsCount == 0) {
            lotteryTotalCycles++;
        }
        
        if (player.lottery.currentTicketsCount == 0) {
            player.lottery.totalCycles++;
        }        
        
        player.lottery.totalTicketsCount += nt;
        player.lottery.currentTicketsCount += nt;
        lotteryTotalTicketsCount += nt;
        lotteryCurrentTicketsCount += nt;
        
        payDevFee(msg.value);
        payAdvFee(msg.value); 
        
        lotteryCurrentPot += msg.value; 
        for(uint256 i = 1; i <= nt; i++) {
            currentLottery.push(cLottery(player.id, lotteryLastTicket + 1));
            lotteryLastTicket++;
        } 
        
        if (lotteryCurrentTicketsCount == LOTTERY_TICKETS_LIMIT) {
            payLotteryWin();
        }
        
        emit NewDepositLottery(msg.sender, msg.value, nt);
    }
    
    function getLotteryWin(uint256 fr, uint256 to, uint256 mod) view private returns (uint256) { 
        uint256 A = minZero(to, fr) + 1;
        uint256 B = fr;
        uint256 value = uint256(uint256(keccak256(abi.encode(block.timestamp * mod, block.difficulty * mod)))%A) + B; 
        return value;
    }      
    
    function payLotteryWin() private {
        uint256 win1 = getLotteryWin(1, LOTTERY_TICKETS_LIMIT, 1);
        uint256 win2 = getLotteryWin(1, LOTTERY_TICKETS_LIMIT, 2);
        uint256 win3 = getLotteryWin(1, LOTTERY_TICKETS_LIMIT, 3);
        uint256 idWin;
        uint256 profit;
        
        uint256 amount = lotteryCurrentPot + lotteryAmountAcum;
        lotteryAmountAcum = amount * 10 / 100; 
        lotteryCurrentPot = 0;
         
        lotteryNextCycleTime = now + TIME_TO_NEXT_LOTTERY;
        
        for(uint256 i = 0; i < currentLottery.length; i++) {
           if (currentLottery[i].ticketNumber == win1) {
               idWin = currentLottery[i].userId;
               profit = amount * LOTTERY_WIN_PERCENT[0] / 100;
               players[idToAddress[idWin]].lottery.profits += profit;
               players[idToAddress[idWin]].lottery.totalProfits += profit;
               lotteryLastWin1a = idToAddress[idWin];
               lotteryLastWin1n = idWin;
           }
           if (currentLottery[i].ticketNumber == win2) {
               idWin = currentLottery[i].userId;
               profit = amount * LOTTERY_WIN_PERCENT[1] / 100;
               players[idToAddress[idWin]].lottery.profits += profit;
               players[idToAddress[idWin]].lottery.totalProfits += profit;
               lotteryLastWin2a = idToAddress[idWin];
               lotteryLastWin2n = idWin;
           }
           if (currentLottery[i].ticketNumber == win3) {
               idWin = currentLottery[i].userId;
               profit = amount * LOTTERY_WIN_PERCENT[2] / 100;
               players[idToAddress[idWin]].lottery.profits += profit;
               players[idToAddress[idWin]].lottery.totalProfits += profit;
               lotteryLastWin3a = idToAddress[idWin];
               lotteryLastWin3n = idWin;
           }  
        }
        
        for(uint256 i = 0; i < currentLottery.length; i++) {
            Player storage player = players[idToAddress[currentLottery[i].userId]];
            player.lottery.currentTicketsCount = 0;
            currentLottery[i].userId = 0;
            currentLottery[i].ticketNumber = 0;
        }   
        
        lotteryCurrentTicketsCount = 0;
        lotteryLastTicket = 0;
        currentLottery.length = 0;
    } 
    
    function withdrawLotteryProfits() external {
        Player storage player = players[msg.sender];
        uint amount = player.lottery.profits;
        require(amount > 0, "Profits = 0 TRX");
        require(getContractBalance() >= amount, "Contract balance < Amount");
        player.lottery.profits = 0;
        player.lottery.withdrawn += amount;
        msg.sender.transfer(amount);
        emit WithdrawLottery(msg.sender, amount);
    }
    
    function deposit(address _upline) external payable {
        Player storage player = players[msg.sender];
        if (getCurrentHalfDay() > player.last_current_halfday) {
             player.last_current_halfday = getCurrentHalfDay();
             player.deposited_in_current_halfday = 0;  
        }
        require(now >= player.last_deposit + WAIT_FOR_INVEST, "Only 1 Deposit chance every 24 hours");
        require(player.deposit_count <= MAX_DEPOSITS_COUNT, "Maximum 200 deposits");
        require(msg.value >= MIN_INVEST, "Minimum deposit is 200 TRX");
    
        uint256 leftOverValue = 0;
        uint msgValue = msg.value;
        
        uint currentHalfDayPersonalAvailable = getCurrentHalfDayPersonalAvailable(msg.sender); 
        require(currentHalfDayPersonalAvailable > 0, "Personal deposit limit exceed");
        if (msgValue > currentHalfDayPersonalAvailable) {
            leftOverValue += minZero(msgValue, currentHalfDayPersonalAvailable); 
            msgValue = currentHalfDayPersonalAvailable;
        }     
    
        uint currentHalfDayPublicAvailable = getCurrentHalfDayPublicAvailable();
        require(currentHalfDayPublicAvailable > 0, "Public deposit limit exceed");
        if (msgValue > currentHalfDayPublicAvailable) {
            leftOverValue += minZero(msgValue, currentHalfDayPublicAvailable); 
            msgValue = currentHalfDayPublicAvailable;
        }        
    
        if (leftOverValue > 0) {
             msg.sender.transfer(leftOverValue);
             leftOverValue = 0;
        }

        player.deposited_in_current_halfday += msgValue;
        
        uint currentHalfDayInvested = getCurrentHalfDayInvested() ;
        uint currentHalfDayPublicLimit = getCurrentHalfDayPublicLimit();
       if (currentHalfDayPublicAvailable >= msgValue) {
            deposited[getCurrentHalfDay()] = currentHalfDayInvested + msgValue;
        } else {
            deposited[getCurrentHalfDay()] = currentHalfDayPublicLimit;
        }

        setUpline(msg.sender, _upline);
        
        if (player.deposit_count == 0) {
            player.last_payout = now;
            player.last_withdraw = now;
            investors++;
            player.id = investors;
            idToAddress[player.id] = msg.sender;
        }
        
        player.deposits.push(Deposit(msgValue, maxVal(now, contract_StartTime), 0));
        
        player.last_deposit = now;
        
        player.deposit_count++;
        player.total_deposited += msgValue;
       
        invested += msgValue;

        payDevFee(msgValue);
        payAdvFee(msgValue);
        max_reached_balance = maxVal(max_reached_balance, getContractBalance());
      
        refPayout(msg.sender, msgValue);
        
        emit NewDepositPlan(msg.sender, msgValue);
    }  
 
    function withdraw() external {
        Player storage player = players[msg.sender];
        require(now >= contract_StartTime, "Withdraw are not available yet");
        require(now >= player.last_withdraw + WAIT_FOR_WITHDRAW, "Only 1 Withdraw chance every 24 hours");
        uint256 availableDividends = getAvailableDividends(msg.sender);
        uint256 availableToWithdraw = availableDividends * (100 - AUTO_REINVEST_PERCENT) / 100;
        uint256 availableToReinvest = availableDividends * AUTO_REINVEST_PERCENT / 100;
        
        require(availableDividends >= MIN_WITHDRAW, "Minimum amount to withdraw is 100 TRX");
        require(getContractBalance() >= availableToWithdraw, "Contract balance < Interest Profit");
        require(minZero(getMaxDailyWithdraw(), withdrawn[getCurrentDay()]) >= availableToWithdraw, "Amount exceeds daily limit");
        
        uint256 val;
		for (uint256 i = 0; i < player.deposits.length; i++) {
		   val = getPlan_InterestProfit(msg.sender, i); 
		   player.deposits[i].payout += val;
		}
		
		player.last_payout = now;
        player.last_withdraw = now;

        player.refer_bonus = 0; 
        
        player.total_withdrawn += availableDividends;
        player.total_reinvested += availableToReinvest;
        total_withdrawn += availableToWithdraw;
        withdrawn[getCurrentDay()] += availableToWithdraw;
        msg.sender.transfer(availableToWithdraw);
        player.deposits.push(Deposit(availableToReinvest, maxVal(now, contract_StartTime), 0));
        player.total_deposited += availableToReinvest; 
        emit WithdrawPlan(msg.sender, availableToWithdraw);
        emit NewReinvest(msg.sender, availableToReinvest);
    }
   
    function getHoldBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 BON = 0.05E9;
        uint256 elapsed_time;
        if (player.deposit_count > 0) {
            elapsed_time = minZero(now, player.last_withdraw);   
        } else {
            elapsed_time = 0;
        }
        return BON / 86400 * elapsed_time;
    }
    
    function getPopularBonus() internal view returns(uint256) {
        uint256 BON = 0.1E9;
        uint256 STP = 500;
        uint256 MLT = investors / STP;
        return BON * MLT;
    }    
    
    function getContractBonus() internal view returns(uint256) { 
        uint256 BON = 0.05E9;
        uint256 MAX = 15E9;
        uint256 STP = 1000000E6; 
        uint256 MLT = max_reached_balance / STP;
        return minVal(BON * MLT, MAX);
    } 
    
    function getTeamBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 BON = 0.01E9;
        uint256 STP = 10; 
        uint256 MLT = player.structure[0] / STP;
        return BON * MLT;
    }  
    
    function getLotteryBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 BON = 0.001E9;
        uint256 STP = 1; 
        uint256 MLT = player.lottery.totalTicketsCount / STP;
        return BON * MLT;
    }    
    
    function getDepositBonus(address _addr) internal view returns(uint256) { 
        Player storage player = players[_addr]; 
        uint256 BON = 0.025E9;
        uint256 STP = 10000E6; 
        uint256 MLT = player.total_deposited / STP;
        return BON * MLT;
    }
    
    function getTarif(address _addr) internal view returns(uint256) {
        return BASIC_PROFIT + getHoldBonus(_addr) + getPopularBonus() + getContractBonus() + getTeamBonus(_addr) + getLotteryBonus(_addr) + getDepositBonus(_addr);
    }
    
    function getDividends(address _addr) view private returns(uint256) {
        Player storage player = players[_addr];
        return getTotal_InterestProfit(_addr) + player.refer_bonus;
    }
    
    function getAvailableDividends(address _addr) view private returns(uint256) {
        Player storage player = players[_addr];
        return minVal(minZero(player.total_deposited * MAX_PLANPROFIT / 100, player.total_withdrawn), getDividends(_addr));
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
    
    function getMaxDailyWithdraw() view private returns(uint256) {
        return invested * 10 / 100;
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
    
    function getContractDividends() view external onlyOwner returns (uint256) {
		uint256 amount;
		for (uint256 i = 1; i <= investors; i++) { 
		     amount += getDividends(idToAddress[i]);
		} 
		return amount;
    }      
    
    function getContractAvailableDividends() view external onlyOwner returns (uint256) {
		uint256 amount;
		for (uint256 i = 1; i <= investors; i++) { 
		     amount += getAvailableDividends(idToAddress[i]);
		} 
		return amount;
    }  
    
    function getAddressById(uint256 id) view external onlyOwner returns (address) {
		return idToAddress[id];
    }     

    function payAdvFee(uint256 val) private {
        uint256 amount = (val * ADV_FEE) / 1000;
        adv_1.transfer(amount);
    }
    
    function payDevFee(uint256 val) private {
        uint256 amount = (val * DEV_FEE) / 1000;
        dev_1.transfer(amount);
        dev_2.transfer(amount);
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

    function contractMainInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _referBonus, uint256 _totalWithdrawn, uint256 _withdrawnToday, uint256 _nextWithdrawQuota, uint256 _investedInCurrentHalfDay, uint256 _currentHalfDayPublicInvestLimit, uint256 _nextInvestQuota, uint256 _contractIniTime, uint256 _maxDailyWithdraw, uint256 _currentDay, uint256 _currentHalfDay) {
        uint256 next_reset_withdraw;
        uint256 next_reset_invest;
        if (now < contract_StartTime) {
            next_reset_withdraw = 0;
        } else {
            next_reset_withdraw = minZero(contract_StartTime + (getCurrentDay() + 1) * 86400, now);
        } 
        if (now < contract_StartTime) {
            next_reset_invest = 0;
        } else {
            next_reset_invest = minZero(contract_StartTime + (getCurrentHalfDay() + 1) * 43200, now);
        } 
        return (invested, investors, total_refer_bonus, total_withdrawn, withdrawn[getCurrentDay()], next_reset_withdraw, getCurrentHalfDayInvested(), getCurrentHalfDayPublicLimit(), next_reset_invest, minZero(contract_StartTime, now), getMaxDailyWithdraw(), getCurrentDay(), getCurrentHalfDay());
    } 

    function userMainInfo(address _addr) view external returns(address _upline, uint256 _id, uint256 _referBonus, uint256 _totalReferBonus, uint256 _totalDeposited, uint256 _totalWithdrawn,  uint256[3] memory _structure, uint256 _nextWithdraw, uint256 _nextDeposit) {
        Player storage player = players[_addr];
        for(uint8 i = 0; i < REF_BONUSES.length; i++) {
            _structure[i] = player.structure[i];
        }
        uint256 nw;
        uint256 nd;
        if (now < contract_StartTime || player.deposit_count == 0) {
            nw = 0;
            nd = 0;
        } else {
            nw = minZero(player.last_withdraw + WAIT_FOR_WITHDRAW, now);
            nd = minZero(player.last_deposit + WAIT_FOR_INVEST, now);
        }
        return (player.upline, player.id, player.refer_bonus, player.total_refer_bonus, player.total_deposited, player.total_withdrawn, _structure, nw, nd);
    }  
    
    function userPlanInfo(address _addr) view external returns(uint256 _activeDeposited, uint256 _depositCount, uint256 _generatedDividends, uint256 _availableDividends, uint256 _investedInCurrentHalfDay, uint256 _currentHalfDayPersonalInvestLimit) {
        Player storage player = players[_addr];
        uint256 deposited_in_current_halfday;
        if (getCurrentHalfDay() > player.last_current_halfday) {
             deposited_in_current_halfday = 0;  
        } else {
             deposited_in_current_halfday = player.deposited_in_current_halfday;
        } 
        return (getActiveDeposits(_addr), player.deposit_count, getDividends(_addr), getAvailableDividends(_addr), deposited_in_current_halfday, getCurrentHalfDayPersonalLimit());
    }      
    
    function userTarifInfo(address _addr) view external returns(uint256 _basicProfit, uint256 _holdBonus, uint256 _popBonus, uint256 _contractBonus, uint256 _teamBonus, uint256 _lotteryBonus, uint256 _depositBonus) {
        return (BASIC_PROFIT, getHoldBonus(_addr), getPopularBonus(), getContractBonus(), getTeamBonus(_addr), getLotteryBonus(_addr), getDepositBonus(_addr));    
    }  
    
    function contractLotteryInfo() view external returns(uint256 _lotteryTotalCycles, uint256 _lotteryCurrentTicketsCount, uint256 _lotteryTotalTicketsCount, uint256 _lotteryTicketsLimit, uint256 _lotteryTicketsCost, uint256 _lotteryAmountAcum, uint256 _lotteryNextCycleTime, address _lotteryLastWin1a, address _lotteryLastWin2a, address _lotteryLastWin3a, uint256 _lotteryLastWin1n, uint256 _lotteryLastWin2n, uint256 _lotteryLastWin3n) {
        return (lotteryTotalCycles, lotteryCurrentTicketsCount, lotteryTotalTicketsCount, LOTTERY_TICKETS_LIMIT, LOTTERY_TICKETS_COST, lotteryAmountAcum, minZero(lotteryNextCycleTime, now), lotteryLastWin1a, lotteryLastWin2a, lotteryLastWin3a, lotteryLastWin1n, lotteryLastWin2n, lotteryLastWin3n);
    }  
    
    function userLotteryInfo(address _addr) view external returns(uint256 _lotteryCurrentTicketsCount, uint256 _lotteryTotalTicketsCount, uint256 _lotteryTotalCycles, uint256 _lotteryProfits, uint256 _lotteryTotalProfits, uint256 _lotteryWithdrawn) {
        Player storage player = players[_addr]; 
        return (player.lottery.currentTicketsCount, player.lottery.totalTicketsCount, player.lottery.totalCycles, player.lottery.profits, player.lottery.totalProfits, player.lottery.withdrawn);    
    } 
}