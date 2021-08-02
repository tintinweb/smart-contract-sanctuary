/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

pragma solidity 0.5.8;

contract POLYSTAKE_LOTTERY {
    using SafeMath for uint256;
    
    struct User {
        uint id;
        bool register;
        string nick;
        pLottery lottery;
    }
    
    mapping(address => User) internal users;
    
    address payable private owner;
    address payable private prj_1;
    address payable private adv_1;
    address payable private adv_2;
    
    uint public usersCount;
    
    bool public payCntrFee = true;
   
    string private constant EMPTY_STR = "-";
    uint private constant WINN_PERCENT = 80;  
    uint private constant CNTR_PERCENT = 11;
    uint private constant PRJ1_PERCENT = 3;
    uint private constant ADV1_PERCENT = 3; 
    uint private constant ADV2_PERCENT = 3; 
    
    event Newbie(string nick, address user);

    constructor(address payable _prj1, address payable _adv1, address payable _adv2) public {
        owner = msg.sender;
        prj_1 = _prj1;
        adv_1 = _adv1;
        adv_2 = _adv2;
    }

    function changeNick(string calldata _newNick) external {
        User storage user = users[msg.sender];
        if (user.register == false) {
           usersCount = usersCount.add(1);
           user.id = usersCount;
           user.register = true;
           emit Newbie(_newNick, msg.sender);
        }
        user.nick = _newNick;
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
    uint public timeToNextLotery = 1;
    
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
        uint pot = lotteryTicketsCost.mul(lotteryTicketsLimit);
        uint profit = pot.mul(getWinnPercent()).div(100);
        address winnner = currentLottery[cl].winUser;
        users[winnner].lottery.profits = users[winnner].lottery.profits.add(profit);
        users[winnner].lottery.totalProfits = users[winnner].lottery.totalProfits.add(profit);
        users[winnner].lottery.totalWin = users[winnner].lottery.totalWin.add(1);
        cl = cl.add(1);
        payFee(pot);
        lotteryTotalCycles = lotteryTotalCycles.add(1);
        lotteryNextCycleTime = now.add(timeToNextLotery);
    }
    
    function lotteryDeposit(uint nt) external payable {
        User storage user = users[msg.sender];
       
        require(now >= lotteryNextCycleTime && lotteryEnabled == true, "Lottery deposit disabled or not available yet");
        require(nt >= 1, "Minimum number of tickets is 1");
        require(lotteryTicketsLimit >= nt + lotteryCurrentTicketsCount[cl], "Maximum number of tickets exceed"); 
        require(msg.value == nt.mul(lotteryTicketsCost), "Wrong Amount");
        
        if (user.register == false) {
           usersCount = usersCount.add(1);
           user.id = usersCount;
           user.register = true;
           user.nick = "New User";
           emit Newbie(user.nick, msg.sender);
        }        
        
        if (lotteryCurrentTicketsCount[cl] == 0) {
            currentLottery[cl].luckyNumber = getRandomNum(1, lotteryTicketsLimit, user.id);
        }
        
        if (currentLottery[cl].winUser == address(0)) {
            if (isNumberInRange(currentLottery[cl].luckyNumber, lotteryCurrentTicketsCount[cl].add(1), lotteryCurrentTicketsCount[cl].add(nt))) {
                currentLottery[cl].winUser = msg.sender;
            }
        }

        user.lottery.currentTicketsCount[cl] = user.lottery.currentTicketsCount[cl].add(nt);
        lotteryCurrentTicketsCount[cl] = lotteryCurrentTicketsCount[cl].add(nt);
        lotteryTotalInvested = lotteryTotalInvested.add(msg.value);
        
        if (lotteryCurrentTicketsCount[cl] == lotteryTicketsLimit) {
            payLotteryWin();
        }
    } 
    
    function withdrawLotteryProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.lottery.profits;
        require(amount > 0, "Profits = 0");
        user.lottery.profits = 0;
        user.lottery.withdrawn = user.lottery.withdrawn.add(amount);
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

    
    ///////////////////////////// INI GENERAL FUNCT /////////////////////
    
    function getWinnPercent() public view returns(uint) {
        if (payCntrFee) {
           return WINN_PERCENT;  
        } else {
           return WINN_PERCENT.add(CNTR_PERCENT);
        }
    }
    
    function getRandomNum(uint fr, uint to, uint mod) view private returns (uint) { 
        uint A = minZero(to, fr).add(1);
        uint B = fr;
        uint value = uint(uint(keccak256(abi.encode(block.timestamp.mul(mod), block.difficulty.mul(mod))))%A).add(B); 
        return value;
    }  
  
    function minZero(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return a.sub(b); 
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
        prj_1.transfer(val.mul(PRJ1_PERCENT).div(100)); 
        adv_1.transfer(val.mul(ADV1_PERCENT).div(100));
        adv_2.transfer(val.mul(ADV2_PERCENT).div(100));
        if (payCntrFee) {
            owner.transfer(val.mul(CNTR_PERCENT).div(100));
        }
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
}