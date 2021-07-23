/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.3;
contract TurboSTAKE {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256[] public REFERRAL_PERCENTS = [50e2, 25e2, 5e2];
	uint256 constant public PROJECT_FEE = 30e2;
	uint256 constant public MARKETING_FEE = 70e2;
	uint256 constant public PERCENT_STEP = 3e2;
	uint256 constant public PERCENTS_DIVIDER = 1000e2;
	uint256 constant public DECREASE_DAY_STEP = 0.25 days; //0.25 days
	uint256 constant public TIME_STEP = 1 days; //1 days
	uint256 internal constant LOTTOBONUS = 2;
    uint256 internal constant LOTTOTICKET = 0.01 ether;
    uint256[] internal LOTTO_WIN_PERCENT = [25, 15, 10, 5, 2];
    uint256 constant internal LOTTO_TICKET_LIMIT = 50; // 50 Entrys Lotto
    uint256 constant internal LOTTO_USER_LIMIT = 10; // 10 Entrys Lotto per user
    uint256 constant internal REF_STEP = 10; // 10 Refs level 1
    

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	
	uint256 public startUNIX;
	address payable public marketingAddress;
    address payable public projectAddress;
	
	uint256 lottoBag;
    uint256 lottoCurrentPot;
    uint256 lottoCycles;
    uint256 lottoCurrentTicketsCount;
    uint256 lottoLastTicket;
    uint256 lottoTotalTicketsCount;
    address lottoLastWin1a;
    address lottoLastWin2a;
    address lottoLastWin3a;
    address lottoLastWin4a;
    address lottoLastWin5a;
    uint256 PLastWin1;
    uint256 PLastWin2;
    uint256 PLastWin3;
    uint256 PLastWin4;
    uint256 PLastWin5;


    struct cLotto {
      address lottoId;
      uint256 ticketNumber;
    }
    struct nLotto {
      cLotto[] currentLotto;
    }

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;
	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		bool force;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 lottobonus;
        uint256 lottoparticipations;
        uint256 lottolimit;
	}

	mapping (address => User) internal users;
	mapping (uint256 => nLotto) internal nlottos;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event NewParticipantLotto(address indexed user, uint256 amount, uint256 pt);

	constructor(address payable marketingAddr,uint256 startDate) {
        require(!isContract(marketingAddr), "!marketingAddr");
		require(startDate > 0);
		marketingAddress = marketingAddr;
        projectAddress = payable(msg.sender);
		startUNIX = startDate;

        plans.push(Plan(14, 75e2));
        plans.push(Plan(21, 55e2));
        plans.push(Plan(28, 45e2));
        plans.push(Plan(14, 75e2));
        plans.push(Plan(21, 55e2));
        plans.push(Plan(28, 45e2));
	}
    
    function FeePayout(uint256 msgValue) internal{
    marketingAddress.transfer(msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
    projectAddress.transfer(msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
    emit FeePayed(msg.sender,msgValue.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));
    }

	function invest(address referrer, uint8 plan) public payable {
	    require(block.timestamp >= startUNIX ,"Not Launch");
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");

		FeePayout(msg.value);

		User storage user = users[msg.sender];
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}
		
		(uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish, true));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	
	function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }
        require(totalAmount > 0, "User has no dividends");
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        user.checkpoint = block.timestamp;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    user.deposits[i].force = false;
                } else if (block.timestamp > user.deposits[i].finish) {
                    user.deposits[i].force = false;
                }
            }
        }
        payable(msg.sender).transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }
	
	function lottoDeposit(uint256 nt) external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        User storage user = users[msg.sender];
        require(user.deposits.length > 0 ,"Deposit is require first");
        require(nt >= 1, "Minimum number of tickets is 1");
        require(LOTTO_TICKET_LIMIT >= nt.add(lottoCurrentTicketsCount) && LOTTO_USER_LIMIT >= nt.add(user.lottolimit), "Maximum number of tickets exceed"); 
        require(msg.value == nt.mul(LOTTOTICKET), "Wrong Amount");
        nLotto storage nlotto = nlottos[lottoCycles];
        
        lottoTotalTicketsCount = lottoTotalTicketsCount.add(nt);
        lottoCurrentTicketsCount = lottoCurrentTicketsCount.add(nt);
        user.lottoparticipations = user.lottoparticipations.add(nt);
        user.lottolimit = user.lottolimit.add(nt);
        
        lottoCurrentPot = lottoCurrentPot.add(msg.value); 
        
        
        for(uint256 i = 1; i <= nt; i++) {
            nlotto.currentLotto.push(cLotto(msg.sender, lottoLastTicket.add(1)));
            lottoLastTicket++;
        } 
            emit NewParticipantLotto(msg.sender, msg.value, lottoLastTicket);
            
        if (lottoCurrentTicketsCount == LOTTO_TICKET_LIMIT) {
            payLottoWin();
            
            lottoCurrentPot = 0;
            lottoCurrentTicketsCount = 0;
            lottoLastTicket = 0;
            lottoCycles++;
        }
    }
    
    function getRaceWin(uint256 fr, uint256 to, uint256 mud) view internal returns (uint256) { 
        uint256 A = (minZero(to, fr)).add(1);
        uint256 B = fr;
        uint256 value = uint256(uint256(keccak256(abi.encode(block.timestamp.mul(mud), block.difficulty.mul(mud)))).mod(A)).add(B); 
        return value;
    }
    
        function payLottoWin() internal {
         nLotto storage nlotto = nlottos[lottoCycles];   
            
        uint256 win1 = getRaceWin(1, LOTTO_TICKET_LIMIT, 1);
        uint256 win2 = getRaceWin(1, LOTTO_TICKET_LIMIT, 2);
        uint256 win3 = getRaceWin(1, LOTTO_TICKET_LIMIT, 3);
        uint256 win4 = getRaceWin(1, LOTTO_TICKET_LIMIT, 4);
        uint256 win5 = getRaceWin(1, LOTTO_TICKET_LIMIT, 5);
        uint256 profit;
       
        FeePayout(lottoCurrentPot);
        
        uint256 da = lottoCurrentPot; 
        if (lottoBag > 0){
            uint256 LBM = lottoBag.div(20);    
            lottoCurrentPot = lottoCurrentPot.add(LBM);
            lottoBag = lottoBag.sub(LBM);
            }
        
        lottoBag = lottoBag.add(da.mul(12).div(100));
        
        for(uint256 i = 0; i < LOTTO_TICKET_LIMIT; i++) {
            
            if (users[nlotto.currentLotto[i].lottoId].lottolimit != 0) {
                users[nlotto.currentLotto[i].lottoId].lottolimit = 0;
           }
            
           if (nlotto.currentLotto[i].ticketNumber == win1) {
               profit = (lottoCurrentPot.mul(LOTTO_WIN_PERCENT[0])).div(100);
               payable(address(uint160(nlotto.currentLotto[i].lottoId))).transfer(profit);
               users[nlotto.currentLotto[i].lottoId].lottobonus = (users[nlotto.currentLotto[i].lottoId].lottobonus).add(profit);
               lottoLastWin1a = nlotto.currentLotto[i].lottoId;
               PLastWin1 = profit;
           }
           if (nlotto.currentLotto[i].ticketNumber == win2) {
               profit = (lottoCurrentPot.mul(LOTTO_WIN_PERCENT[1])).div(100);
               payable(address(uint160(nlotto.currentLotto[i].lottoId))).transfer(profit);
               users[nlotto.currentLotto[i].lottoId].lottobonus = (users[nlotto.currentLotto[i].lottoId].lottobonus).add(profit);
               lottoLastWin2a = nlotto.currentLotto[i].lottoId;
               PLastWin2 = profit;
           }
           if (nlotto.currentLotto[i].ticketNumber == win3) {
              profit = (lottoCurrentPot.mul(LOTTO_WIN_PERCENT[2])).div(100);
              payable(address(uint160(nlotto.currentLotto[i].lottoId))).transfer(profit);
              users[nlotto.currentLotto[i].lottoId].lottobonus = (users[nlotto.currentLotto[i].lottoId].lottobonus).add(profit);
              lottoLastWin3a = nlotto.currentLotto[i].lottoId;
              PLastWin3 = profit;
           }
           if (nlotto.currentLotto[i].ticketNumber == win4) {
              profit = (lottoCurrentPot.mul(LOTTO_WIN_PERCENT[3])).div(100);
              payable(address(uint160(nlotto.currentLotto[i].lottoId))).transfer(profit);
              users[nlotto.currentLotto[i].lottoId].lottobonus = (users[nlotto.currentLotto[i].lottoId].lottobonus).add(profit);
              lottoLastWin4a = nlotto.currentLotto[i].lottoId;
              PLastWin4 = profit;
           }
           if (nlotto.currentLotto[i].ticketNumber == win5) {
               profit = (lottoCurrentPot.mul(LOTTO_WIN_PERCENT[4])).div(100);
               payable(address(uint160(nlotto.currentLotto[i].lottoId))).transfer(profit);
              users[nlotto.currentLotto[i].lottoId].lottobonus = (users[nlotto.currentLotto[i].lottoId].lottobonus).add(profit);
              lottoLastWin5a = nlotto.currentLotto[i].lottoId;
              PLastWin5 = profit;
           }
        }
    } 

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
	    uint256 userLottoRate = getUserLottoRate(msg.sender);
	    uint256 userRefRate = getUserRefRate(msg.sender);
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP)).add(userLottoRate).add(userRefRate);
		} else {
			return plans[plan].percent;
		}
    }
	
	function getResult(uint8 plan, uint256 deposit) public view returns ( uint256 percent, uint256 profit, uint256 current, uint256 finish){
        percent = getPercent(plan);
        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
            }
        }
        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }
	
	function getUserDividends(address userAddress) public view returns (uint256){
        User memory user = users[userAddress];

        uint256 totalAmount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                    if (from < to) {
                        uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress = planTime.div(getDecreaseDays(plans[user.deposits[i].plan].time));
                        totalAmount = totalAmount.add(share.mul(to.sub(from)).mul(redress).div(TIME_STEP));
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }
        return totalAmount;
    }
	
	function getDecreaseDays(uint256 planTime) public view returns (uint256) {
        uint256 limitDays = TIME_STEP.mul(4);
        uint256 pastDays = block.timestamp.sub(startUNIX).div(TIME_STEP);
        uint256 decreaseDays = pastDays.mul(DECREASE_DAY_STEP);
        if (decreaseDays > limitDays){
        decreaseDays = limitDays;
        }
        uint256 minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);
        
        return minimumDays;  
        
    }
    
    function getUserRefRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 refsbonus = user.levels[0];
        uint256 RMultiplier = (refsbonus.div(REF_STEP)).mul(100);
            return RMultiplier;
    }
    
    function getUserLottoRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 lottoparticipations = user.lottoparticipations;
        uint256 LMultiplier = LOTTOBONUS.mul(lottoparticipations);
            return LMultiplier;
    }

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, bool force){
        User memory user = users[userAddress];
        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }
	
	function getlottoStats() public view returns (address, address, address, address, address,uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (lottoLastWin1a, lottoLastWin2a, lottoLastWin3a, lottoLastWin4a, lottoLastWin5a ,lottoCycles, lottoCurrentTicketsCount, lottoTotalTicketsCount, 
        LOTTO_TICKET_LIMIT, LOTTOTICKET, lottoCurrentPot, lottoBag);
    }
    
    function getlottoLastPrizes() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (PLastWin1, PLastWin2, PLastWin3, PLastWin4, PLastWin5);
    }

    function getUserlottoStats(address userAddress) public view returns (uint256, uint256, uint256) {
    User memory user = users[userAddress];
        return (user.lottobonus,user.lottoparticipations,user.lottolimit);
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function minZero(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    function maxVal(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    function minVal(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
}