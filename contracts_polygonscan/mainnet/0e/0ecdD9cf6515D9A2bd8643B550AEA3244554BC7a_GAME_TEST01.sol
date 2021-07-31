/**
 *Submitted for verification at polygonscan.com on 2021-07-31
*/

pragma solidity 0.5.8;


contract GAME_TEST01 {
    
    struct User {
        uint id;
        bool register;
        string nick;
        pLottery lottery;
        pDuel duel;
    }
    
    mapping(address => User) internal users;
    
    address payable private owner;
    address payable private prj_1;
    address payable private adv_1;
    address payable private adv_2;
    
    uint public usersCount;

    // Const 
    string private constant EMPTY_STR = "-";
    uint private WIN_PERCENT = 88;  
    uint private PRJ1_PERCENT = 4; 
    uint private ADV1_PERCENT = 4; 
    uint private ADV2_PERCENT = 4; 
    
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
	

    constructor(address payable _prj1, address payable _adv1, address payable _adv2) public {
        owner = msg.sender;
        prj_1 = _prj1;
        adv_1 = _adv1;
        adv_2 = _adv2;
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
    uint public cl = 1;  
    uint public lotteryTicketsLimit = 7;
    uint public lotteryTicketsCost  = 1 ether; 
    bool public lotteryEnabled = true;
    uint public timeToNextLotery = 120;
    
    mapping(uint => uint) internal lotteryCurrentTicketsCount;
    uint public lotteryTotalCycles;
    uint public lotteryNextCycleTime;
    uint public lotteryTotalInvested;
    
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
        uint profit = pot * WIN_PERCENT / 100;
        address winnner = currentLottery[cl].winUser;
        users[winnner].lottery.profits += profit;
        users[winnner].lottery.totalProfits += profit;
        users[winnner].lottery.totalWin++;
        cl++;
        payFee(pot);
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
        require(amount > 0, "Profits = 0");
        user.lottery.profits = 0;
        user.lottery.withdrawn += amount;
        msg.sender.transfer(amount);
    } 
    
    function getContractLotteryInfo() view external returns(uint _lotteryCurrentTicketsCount, uint _lotteryNextCycleTime) {
        return (
            lotteryCurrentTicketsCount[cl], 
            minZero(lotteryNextCycleTime, now)
        );
    }  
    
    function getContractLotteryTopWinInfo() view external returns(uint _lastWinId1, uint _lastWinId2, uint _lastWinId3, uint _lastWinId4, uint _lastWinId5, string memory _lastWinNick1, string memory _lastWinNick2, string memory _lastWinNick3, string memory _lastWinNick4, string memory _lastWinNick5) {
        return (
            users[currentLottery[minZero(cl, 1)].winUser].id, 
            users[currentLottery[minZero(cl, 2)].winUser].id, 
            users[currentLottery[minZero(cl, 3)].winUser].id, 
            users[currentLottery[minZero(cl, 4)].winUser].id, 
            users[currentLottery[minZero(cl, 5)].winUser].id, 
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
    uint public cd = 1;  
    uint public duelTicketsCost = 1 ether; 
    bool public duelEnabled = true;
    uint public timeToNextDuel = 60;
    uint public duelNextCycleTime;
    uint public duelTotalInvested;
    
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
        uint profit = (2*duelTicketsCost) * WIN_PERCENT / 100;
        
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
            payFee(2*duelTicketsCost); 
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
        require(amount > 0, "Profits = 0");
        user.duel.profits = 0;
        user.duel.withdrawn += amount;
        msg.sender.transfer(amount);
    } 
    
    function getContractDuelInfo() view external returns(uint _duelNextCycleTime, uint _currentDuelUserId1, string memory _currentDuelUserNck1, uint _lastWinnPower, uint _lastLosePower,  uint _lastWinnId, uint _lastLoseId, string memory _lastWinnNick, string memory _lastLoseNick) {
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
    
    
    ///////////////////////////// INI GENERAL FUNCT /////////////////////
    
    function withdrawAllProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.lottery.profits + user.duel.profits;
        require(amount > 0, "Profits = 0");
        user.lottery.withdrawn += user.lottery.profits;
        user.duel.withdrawn += user.duel.profits;
        user.lottery.profits = 0;
        user.duel.profits = 0;
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

    function payFee(uint val) private {
        prj_1.transfer(val * PRJ1_PERCENT / 100); 
        adv_1.transfer(val * ADV1_PERCENT / 100);
        adv_2.transfer(val * ADV2_PERCENT / 100);
    } 

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }  

	function getContractBalance() public view returns (uint) {
		return address(this).balance;
	}  

	function getUserBalance(address _addr) public view returns (uint) {
		return address(_addr).balance;
	} 
    
    function getGeneralUserInfo(address _addr) view external returns(uint _userID, string memory _userNick, bool _userRegister, bool _isSuper) {
        if (_addr == owner || _addr == prj_1 || _addr == adv_1 || _addr == adv_2) {
            _isSuper == true;
        } else {
            _isSuper == false;
        }
        return (
            users[_addr].id,
            users[_addr].nick,
            users[_addr].register,
            _isSuper
        );
    }
   
}