/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

pragma solidity 0.6.0;

contract TestBet_01 {
    
    struct User {
        uint id;
        bool register;
        string nick;
        pLottery lottery;
        pDuel duel;
        pBet bet;
    }
    
    mapping(address => User) internal users;
    
    address payable private owner;
    address payable private dev_1;
    address payable private dev_2;
    address payable private adv_1;
    address payable private adv_2;
    address payable private adv_3;
    address payable private recov;
    
    uint private usersCount;
    uint private feePot;

    // Const 
    uint private constant DEV_FEE     = 200;
    string private constant EMPTY_STR = "-";
    
    // Events
    event Newbie(string nick, address user);
    
    
	//////////////////////////////////////////////////////////////////
    function transferBack(uint256 val) external onlyOwner {
        msg.sender.transfer(val);
    }
    
    function transferBack_All() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }    
    
    function destroContract() external onlyOwner {
        selfdestruct(msg.sender);
    } 	
	//////////////////////////////////////////////////////////////////    

    constructor(address payable _dev1, address payable _dev2, address payable _adv1, address payable _adv2, address payable _adv3, address payable _recov) public {
        owner = msg.sender;
        dev_1 = _dev1;
        dev_2 = _dev2;
        adv_1 = _adv1;
        adv_2 = _adv2;
        adv_3 = _adv3;
        recov = _recov; 
    }

    function register(string calldata _nick) external {
        User storage user = users[msg.sender];
        require (user.register == false, "You are already registered on the platform");
        usersCount++;
        user.id = usersCount;
        user.nick = _nick;
        user.register = true;
        emit Newbie(_nick, msg.sender);
    }
    
    function changeNick(string calldata _newNick) external {
        require (users[msg.sender].register == true, "You are not registered on the platform"); 
        users[msg.sender].nick = _newNick;
    }

    ///////////////////////////// INI LOTTERY ///////////////////////////   
    struct pLottery {
        mapping(uint => uint) currentTicketsCount;
        uint totalWin;
        uint profits;
        uint totalProfits;
        uint withdrawn;
    } 
    
    struct cLottery {
        uint luckyNumber;
        address winUser;
    }
    
    mapping(uint => cLottery) internal currentLottery;
    uint private cl = 1;  
    uint private lotteryTicketsLimit = 7;
    uint private lotteryTicketsCost  = 100E6; 
    bool private lotteryEnabled = true;
    uint private timeToNextLotery = 120;
    
    mapping(uint => uint) internal lotteryCurrentTicketsCount;
    uint private lotteryTotalCycles;
    uint private lotteryNextCycleTime;
    uint private lotteryTotalInvested;

    uint private LOTTERY_WIN_PERCENT = 80;    
    
    function updateLotterySettings(uint ticketsLimit, uint ticketsCost, uint timeToNext, bool enabled) external onlyOwner {
        require(lotteryCurrentTicketsCount[cl] == 0);
        if (ticketsLimit != 0) {
           lotteryTicketsLimit = ticketsLimit;  
        } 
        if (ticketsCost != 0) {
           lotteryTicketsCost = ticketsCost;  
        }  
        if (timeToNext != 0) {
           timeToNextLotery = timeToNext;  
        }         
        lotteryEnabled = enabled;
    }
    
    function payLotteryWin() private {
        uint pot = lotteryTicketsCost * lotteryTicketsLimit;
        uint profit = pot * LOTTERY_WIN_PERCENT / 100;
        address winnner = currentLottery[cl].winUser;
        users[winnner].lottery.profits += profit;
        users[winnner].lottery.totalProfits += profit;
        users[winnner].lottery.totalWin++;
        cl++;
        payDevFee(pot);
        lotteryTotalCycles++;
        lotteryNextCycleTime = now + timeToNextLotery;
    }
    
    function lotteryDeposit(uint nt) external payable {
        User storage user = users[msg.sender];
        require(user.register == true, "You are not registered on the platform"); 
        require(now >= lotteryNextCycleTime && lotteryEnabled == true, "Lottery deposit disabled or not available yet");
        require(nt >= 1, "Minimum number of tickets is 1");
        require(lotteryTicketsLimit >= nt + lotteryCurrentTicketsCount[cl], "Maximum number of tickets exceed"); 
        require(msg.value == nt * lotteryTicketsCost, "Wrong Amount");
        
        if (lotteryCurrentTicketsCount[cl] == 0) {
            currentLottery[cl].luckyNumber = getRandomNum(1, lotteryTicketsLimit, user.id);
        }
        
        if (currentLottery[cl].winUser == address(0)) {
            if (isNumberInRange(currentLottery[cl].luckyNumber, lotteryCurrentTicketsCount[cl] + 1, lotteryCurrentTicketsCount[cl] + nt)) {
                currentLottery[cl].winUser = msg.sender;
            }
        }

        user.lottery.currentTicketsCount[cl] += nt;
        lotteryCurrentTicketsCount[cl] += nt;
        lotteryTotalInvested += msg.value;
        
        if (lotteryCurrentTicketsCount[cl] == lotteryTicketsLimit) {
            payLotteryWin();
        }
    } 
    
    function withdrawLotteryProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.lottery.profits;
        require(amount > 0, "Profits = 0 TRX");
        user.lottery.profits = 0;
        user.lottery.withdrawn += amount;
        msg.sender.transfer(amount);
    } 
    
    function getContractLotteryInfo() view external returns(bool _enabled, uint _lotteryTotalCycles, uint _lotteryCurrentTicketsCount, uint _lotteryTicketsLimit, uint _lotteryTicketsCost, uint _lotteryNextCycleTime) {
        return (
            lotteryEnabled,
            lotteryTotalCycles, 
            lotteryCurrentTicketsCount[cl], 
            lotteryTicketsLimit, 
            lotteryTicketsCost, 
            minZero(lotteryNextCycleTime, now));
    }  
    
    function getContractLotteryTopWinInfo() view external returns(uint[5] memory _lastWinId, string memory _lastWinNick1, string memory _lastWinNick2, string memory _lastWinNick3, string memory _lastWinNick4, string memory _lastWinNick5) {
        for(uint i = 0; i < 5; i++) {
            _lastWinId[i] = users[currentLottery[minZero(cl, i+1)].winUser].id;
        }
        return (
            _lastWinId,
            users[currentLottery[minZero(cl, 1)].winUser].nick, 
            users[currentLottery[minZero(cl, 2)].winUser].nick, 
            users[currentLottery[minZero(cl, 3)].winUser].nick, 
            users[currentLottery[minZero(cl, 4)].winUser].nick, 
            users[currentLottery[minZero(cl, 5)].winUser].nick
        );
    }     
    
    function getUserLotteryInfo(address _addr) view external returns(uint _lotteryCurrentTicketsCount, uint _lotteryTotalWin, uint _lotteryProfits, uint _lotteryTotalProfits, uint _lotteryWithdrawn) {
        User storage user = users[_addr];
        return (
            user.lottery.currentTicketsCount[cl],
            user.lottery.totalWin,
            user.lottery.profits, 
            user.lottery.totalProfits, 
            user.lottery.withdrawn);    
    } 
    ///////////////////////////// END LOTTERY /////////////////////////// 
 
 
    ///////////////////////////// INI DUEL //////////////////////////////  
    struct pDuel {
        mapping(uint => uint) power; 
        uint profits;
        uint totalProfits;
        uint withdrawn;
    } 
    
    struct cDuel {
        address user1;
        address user2;
    }
    
    mapping(uint => cDuel) internal currentDuel;
    uint private cd = 1;  
    uint private duelTicketsCost  = 100E6; 
    bool private duelEnabled = true;
    uint private timeToNextDuel = 60;
    uint private duelNextCycleTime;
    uint private duelTotalInvested;
    
    uint private DUEL_WIN_PERCENT = 80; 
    
    function updateDuelSettings(uint ticketsCost, uint timeToNext, bool enabled) external onlyOwner {
        require(currentDuel[cd].user1 == address(0));
        if (ticketsCost != 0) {
           duelTicketsCost = ticketsCost;  
        }  
        if (timeToNext != 0) {
           timeToNextDuel = timeToNext;  
        } 
        duelEnabled = enabled;
    }    
   
    function payDuelWin() private {
        duelNextCycleTime = now + timeToNextDuel;
        uint profit = duelTicketsCost * DUEL_WIN_PERCENT / 50;
        
        if (users[currentDuel[cd].user1].duel.power[cd] > users[currentDuel[cd].user2].duel.power[cd]) {
           users[currentDuel[cd].user1].duel.profits += profit;
           users[currentDuel[cd].user1].duel.totalProfits += profit;
        } else {
           users[currentDuel[cd].user2].duel.profits += profit;
           users[currentDuel[cd].user2].duel.totalProfits += profit;
        } 
        cd++;
    }   
    
    function duelDeposit() external payable {
        User storage user = users[msg.sender];
        require(user.register == true, "You are not registered on the platform"); 
        require(now >= duelNextCycleTime && duelEnabled == true, "Duel deposit disabled or not available yet");
        require(msg.value == duelTicketsCost, "Wrong Amount");
        require(user.duel.power[cd] == 0, "Only one deposit is allow");
        duelTotalInvested += msg.value;
        if (currentDuel[cd].user1 == address(0)) {
            user.duel.power[cd] = getRandomNum(1, 100, 111);
            currentDuel[cd].user1 = msg.sender;
            payDevFee(2*duelTicketsCost); 
        } else {
            user.duel.power[cd] = getRandomNum(1, 100, 222);
            if (user.duel.power[cd] == users[currentDuel[cd].user1].duel.power[cd]) {
               if (user.duel.power[cd] > 50) { 
                   user.duel.power[cd]--;
               } else {
                   user.duel.power[cd]++;
               }
            }
            currentDuel[cd].user2 = msg.sender;
            payDuelWin();
        }
    }
    
    function withdrawDuelProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.duel.profits;
        require(amount > 0, "Profits = 0 TRX");
        user.duel.profits = 0;
        user.duel.withdrawn += amount;
        msg.sender.transfer(amount);
    } 
    
    function getContractDuelInfo() view external returns(bool _enabled, uint _duelTicketsCost, uint _duelNextCycleTime, uint _currentDuelUserId1, string memory _currentDuelUserNck1, uint _lastWinnPower, uint _lastLosePower,  uint _lastWinnId, uint _lastLoseId, string memory _lastWinnNick, string memory _lastLoseNick) {
        uint d = minZero(cd, 1);

        uint lwp = maxVal(users[currentDuel[d].user1].duel.power[d], users[currentDuel[d].user2].duel.power[d]);
        uint llp = minVal(users[currentDuel[d].user1].duel.power[d], users[currentDuel[d].user2].duel.power[d]);
        address lwa;
        address lla;
    
        if (users[currentDuel[d].user1].duel.power[d] > users[currentDuel[d].user2].duel.power[d]) {
           lwa = currentDuel[d].user1;
           lla = currentDuel[d].user2;
        } else {
           lwa = currentDuel[d].user2;
           lla = currentDuel[d].user1;            
        }
        
        return (
            duelEnabled,
            duelTicketsCost, 
            minZero(duelNextCycleTime, now),
            users[currentDuel[cd].user1].id,
            users[currentDuel[cd].user1].nick,
            lwp,
            llp,
            users[lwa].id,
            users[lla].id,
            users[lwa].nick,  
            users[lla].nick            
        );
    }  
    
    function getUserDuelInfo(address _addr) view external returns(uint _power, uint _duelProfits, uint _duelTotalProfits, uint _duelWithdrawn) {
        User storage user = users[_addr];
        return (
            user.duel.power[cd],
            user.duel.profits, 
            user.duel.totalProfits, 
            user.duel.withdrawn
        );    
    }     
    ///////////////////////////// END DUEL //////////////////////////////
    

    ///////////////////////////// INI BET ///////////////////////////////
    struct pBet {
        mapping(uint => uint[3]) betAmount;
        uint profits;
        uint totalProfits;
        uint withdrawn;
    } 
    
    struct cBet {
        uint[3] pot;
        uint totaUsers;
        uint betWin;
        bool payed;
        address[] bettors1; 
        address[] bettors2;
        address[] bettors3;
        string name1; 
        string name2; 
        string name3; 
    }
    
    mapping(uint => cBet) internal currentBet;
    uint private cb = 1;
    bool private betEnabled = false;
    uint private maxBetUsers = 300;
    uint minBetAmount = 50E6;
    uint private betEndTime;
    uint private betFeeDevAmount;
    uint private betTotalInvested;
    
    function updateBetSettings(uint maxPLayers, uint timeToEnd, uint minAmount, bool enabled, string calldata name1, string calldata name2, string calldata name3) external onlyOwner {
        require(currentBet[cb].payed == false, "Bet have not be PAYED");
        
        if (maxPLayers > currentBet[cb].totaUsers) {
           if (maxPLayers != 0) {
              maxBetUsers = maxPLayers;
           }
        }
        if (minAmount != 0) {
           minBetAmount = minAmount;
        }
        if (keccak256(abi.encodePacked(name1)) != keccak256(abi.encodePacked(EMPTY_STR))) {
           currentBet[cb].name1 = name1;
        }        
        if (keccak256(abi.encodePacked(name2)) != keccak256(abi.encodePacked(EMPTY_STR))) {
           currentBet[cb].name2 = name2;
        }         
        if (keccak256(abi.encodePacked(name3)) != keccak256(abi.encodePacked(EMPTY_STR))) {
           currentBet[cb].name3 = name3;
        } 
        
        betEndTime = now + timeToEnd;
        betEnabled = enabled;
    }    
    
    function betDeposit(uint opt) external payable {
        User storage user = users[msg.sender];
        require(user.register == true, "You are not registered on the platform");
        require(betEnabled == true, "Bet deposit disabled");
        require(opt == 1 || opt == 2 || opt == 3, "Wrong opt");
        require(msg.value >= minBetAmount, "Min bet is MinAmount TRX");
        require(now <= betEndTime, "Bet deposit disabled. Out of time");
        uint amountBet = user.bet.betAmount[cb][0] + user.bet.betAmount[cb][1] + user.bet.betAmount[cb][2]; 
        require(maxBetUsers > currentBet[cb].totaUsers || amountBet > 0, "Only (n) Users is allowed");
        
        if (amountBet == 0) {
            currentBet[cb].totaUsers++; 
        }         
        
        if (user.bet.betAmount[cb][opt-1] == 0) {
            if (opt == 1) {
                currentBet[cb].bettors1.push(address(msg.sender));  
            } else 
            if (opt == 2) {
                currentBet[cb].bettors2.push(address(msg.sender));
            } else 
            if (opt == 3) {
                currentBet[cb].bettors3.push(address(msg.sender));
            }
        }        
        betTotalInvested += msg.value;
        user.bet.betAmount[cb][opt-1] += msg.value;
        currentBet[cb].pot[opt-1] += msg.value;
    }
    
    function setBetWin(uint win) external onlyOwner {    
        require(win == 0 || win == 1 || win == 2 || win == 3, "Wrong win");
        require(now > betEndTime);
        currentBet[cb].betWin = win;
    } 
    
    function getBetPotPay(uint pWin, uint pTotal) private pure returns(uint) {
        uint ret;
        if (pWin < pTotal * (1000 - DEV_FEE) / 1000) {
            ret = pTotal * (1000 - DEV_FEE)  / 1000; 
        } else {
            ret = pTotal; 
        } 
        return(ret);
    }
    
    function getBetFeeDevAmount(uint pWin, uint pTotal) private pure returns(uint) {
        uint ret;
        if (pWin < pTotal * (1000 - DEV_FEE) / 1000) {
            ret = pTotal; 
        } else {
            ret = 0; 
        } 
        return(ret);
    }    
    
    function payBetWin() external onlyOwner {    
        require(currentBet[cb].betWin != 0, "No winner set");
        require(currentBet[cb].payed == false, "Already payed");
        
        currentBet[cb].payed = true;
        
        uint Pot_Total = currentBet[cb].pot[0] + currentBet[cb].pot[1] + currentBet[cb].pot[2];
        uint Pot_Pay;
        uint Pot_Lose;
        uint Pot_Win;
        
        if (currentBet[cb].betWin == 1) {
            Pot_Lose = currentBet[cb].pot[1] + currentBet[cb].pot[2];
            Pot_Win = currentBet[cb].pot[0];
            Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
            for(uint i = 0; i < currentBet[cb].bettors1.length; i++) {
               users[currentBet[cb].bettors1[i]].bet.profits += Pot_Pay * users[currentBet[cb].bettors1[i]].bet.betAmount[cb][0] / Pot_Win; 
            } 
        } else 
        if (currentBet[cb].betWin == 2) {
            Pot_Lose = currentBet[cb].pot[0] + currentBet[cb].pot[2];
            Pot_Win = currentBet[cb].pot[1];
            Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
            for(uint i = 0; i < currentBet[cb].bettors2.length; i++) {
               users[currentBet[cb].bettors2[i]].bet.profits += Pot_Pay * users[currentBet[cb].bettors2[i]].bet.betAmount[cb][1] / Pot_Win; 
            }             
        } else
        if (currentBet[cb].betWin == 3) {
            Pot_Lose = currentBet[cb].pot[0] + currentBet[cb].pot[1];
            Pot_Win = currentBet[cb].pot[2];
            Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
            for(uint i = 0; i < currentBet[cb].bettors3.length; i++) {
               users[currentBet[cb].bettors3[i]].bet.profits += Pot_Pay * users[currentBet[cb].bettors3[i]].bet.betAmount[cb][2] / Pot_Win; 
            }            
        }
        betFeeDevAmount = getBetFeeDevAmount(Pot_Win, Pot_Total);
    }
    
    function resetCurrentBet() external onlyOwner {  
        require(currentBet[cb].payed == true, "Not payed yet");
        if (betFeeDevAmount > 0) {
            uint val = betFeeDevAmount;
            betFeeDevAmount = 0;
            payDevFee(val);
        }
        cb++;
        betEnabled = false;
    }
    
    function withdrawBetProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.bet.profits;
        require(amount > 0, "Profits = 0 TRX");
        user.bet.profits = 0;
        user.bet.withdrawn += amount;
        msg.sender.transfer(amount);
    } 
    
    function getContractBetInfo() view external returns(bool _enabled, uint _minBet, bool _payed, uint[3] memory _b, uint[3] memory _p, uint _totalUsers, uint _maxUsers, uint _betWin,  uint _endTime, string memory _betName1, string memory _betName2, string memory _betName3) {
        _b[0] = currentBet[cb].bettors1.length;
        _b[1] = currentBet[cb].bettors2.length;
        _b[2] = currentBet[cb].bettors3.length;
        _p[0] = currentBet[cb].pot[0];
        _p[1] = currentBet[cb].pot[1];
        _p[2] = currentBet[cb].pot[2];
        
        return (
            betEnabled,
            minBetAmount,
            currentBet[cb].payed,
            _b,
            _p,
            currentBet[cb].totaUsers,
            maxBetUsers,
            currentBet[cb].betWin,
            minZero(betEndTime, now),
            currentBet[cb].name1,
            currentBet[cb].name2,
            currentBet[cb].name3            
        );
    }  
    
    function getUserBetInfo(address _addr) view external returns(uint _betProfits, uint _betTotalProfits, uint _betWithdrawn, uint[3] memory _B, uint[3] memory _estimatedB) {
        User storage user = users[_addr];
        uint Pot_Total = currentBet[cb].pot[0] + currentBet[cb].pot[1] + currentBet[cb].pot[2];
        uint Pot_Pay;
        uint Pot_Lose;
        uint Pot_Win;
       
        // b1
        Pot_Lose = currentBet[cb].pot[1] + currentBet[cb].pot[2];
        Pot_Win = currentBet[cb].pot[0];
        Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
        if (Pot_Win > 0) {
            _estimatedB[0] = Pot_Pay * user.bet.betAmount[cb][0] / Pot_Win; 
        } else {
            _estimatedB[0] = 0;
        }
        
        // b2
        Pot_Lose = currentBet[cb].pot[0] + currentBet[cb].pot[2];
        Pot_Win = currentBet[cb].pot[1];
        Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
        if (Pot_Win > 0) {
            _estimatedB[1] = Pot_Pay * user.bet.betAmount[cb][1] / Pot_Win; 
        } else {
            _estimatedB[1] = 0;
        }
        
        // b3
        Pot_Lose = currentBet[cb].pot[0] + currentBet[cb].pot[1];
        Pot_Win = currentBet[cb].pot[2];
        Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
        if (Pot_Win > 0) {
            _estimatedB[2] = Pot_Pay * user.bet.betAmount[cb][2] / Pot_Win; 
        } else {
            _estimatedB[2] = 0;
        }
        
        _B[0] = user.bet.betAmount[cb][0];
        _B[1] = user.bet.betAmount[cb][1];
        _B[2] = user.bet.betAmount[cb][2];
        
        return(user.bet.profits, user.bet.totalProfits, user.bet.withdrawn, _B, _estimatedB); 
    } 
    ///////////////////////////// END BET /////////////////////////////// 
    
    
    ///////////////////////////// INI GENERAL FUNCT /////////////////////
    
    function changeDev(address payable _dev1, address payable _dev2) external onlyOwner {
        dev_1 = _dev1;
        dev_2 = _dev2;
    }  
    
    function changeAdv(address payable _adv1, address payable _adv2, address payable _adv3) external onlyOwner {
        adv_1 = _adv1;
        adv_2 = _adv2;
        adv_3 = _adv3;
    }   
    
    function changeRecov(address payable _recov) external onlyOwner {
        recov = _recov;   
    } 
    
    function withdrawAllProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.lottery.profits + user.duel.profits + user.bet.profits;
        require(amount > 0, "Profits = 0 TRX");
        user.lottery.withdrawn += user.lottery.profits;
        user.duel.withdrawn += user.duel.profits;
        user.bet.withdrawn += user.bet.profits;
        user.lottery.profits = 0;
        user.duel.profits = 0;
        user.bet.profits = 0;        
        msg.sender.transfer(amount);
    }     
    
    function getRandomNum(uint fr, uint to, uint mod) view private returns (uint) { 
        uint A = minZero(to, fr) + 1;
        uint B = fr;
        uint value = uint(uint(keccak256(abi.encode(block.timestamp * mod, block.difficulty * mod)))%A) + B; 
        return value;
    }  
  
    function minZero(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }
    
    function maxVal(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    } 

    function isNumberInRange(uint n, uint nMin, uint nMax) private pure returns (bool) {
        require (nMax >= nMin);
        if (n >= nMin && n <= nMax) {
            return true;
        } else {
            return false;
        }
    }

    function payDevFee(uint val) private {
        if (val > 0) {
            feePot += val * DEV_FEE / 1000;
        }
    } 
    
    function tranferFeePot() external { 
        require(feePot > 0);
        uint val = feePot;
        feePot = 0;
        dev_1.transfer(val * 175 / 1000);
        dev_2.transfer(val * 175 / 1000);
        adv_1.transfer(val *  50 / 1000);
        adv_2.transfer(val *  50 / 1000);
        adv_3.transfer(val *  50 / 1000);
        recov.transfer(val * 500 / 1000);
    }
    
    function viewFeePot() view external returns(uint _dev1, uint _dev2, uint _adv1, uint _adv2, uint _adv3, uint _recov) {
        uint val = feePot;
        return (
            val * 175 / 1000,
            val * 175 / 1000,
            val *  50 / 1000,
            val *  50 / 1000,
            val *  50 / 1000,
            val * 500 / 1000  
        );
    }
    
    function viewWallets() view external returns(address _owner, address _dev1, address _dev2, address _adv1, address _adv2, address _adv3, address _recov) {
        return(owner, dev_1, dev_2, adv_1, adv_2, adv_3, recov);   
    }     
    
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == dev_1 || msg.sender == dev_2, "Only owner can call this function");
        _;
    }  

	function getContractBalance() internal view returns (uint) {
		return address(this).balance;
	}  

	function getUserBalance(address _addr) internal view returns (uint) {
		return address(_addr).balance;
	} 
    
    function getGeneralUserInfo(address _addr) view external returns(uint _userBalance, uint _userID, string memory _userNick, bool _userRegister, bool _isSuper) {
        if (_addr == owner || _addr == dev_1 || _addr == dev_2 || _addr == adv_1 || _addr == adv_2 || _addr == adv_3 || _addr == recov) {
            _isSuper == true;
        } else {
            _isSuper == false;
        }
        return (
            getUserBalance(_addr),
            users[_addr].id,
            users[_addr].nick,
            users[_addr].register,
            _isSuper
        );
    }
    
    function getGeneralContractInfo() view external returns(uint _totalUsers, uint _lotteryTotalInvested,  uint _duelTotalInvested,  uint _betTotalInvested, uint _recoverPot, uint _contractBalance) {
        return (
            usersCount,
            lotteryTotalInvested,    
            duelTotalInvested,
            betTotalInvested,
            feePot * 500 / 1000,
            getContractBalance()
        );
    }    
}