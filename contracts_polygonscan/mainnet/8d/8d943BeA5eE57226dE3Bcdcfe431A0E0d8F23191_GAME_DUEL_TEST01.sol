/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

pragma solidity 0.5.8;

contract GAME_DUEL_TEST01 {
    using SafeMath for uint256;
    
    struct User {
        uint id;
        bool register;
        string nick;
        pDuel duel;
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
        duelNextCycleTime = now.add(timeToNextDuel);
        uint profit = duelTicketsCost.mul(2).mul(getWinnPercent()).div(100);
        
        if (users[currentDuel[cd].user1].duel.power[cd] > users[currentDuel[cd].user2].duel.power[cd]) {
           users[currentDuel[cd].user1].duel.profits = users[currentDuel[cd].user1].duel.profits.add(profit);
           users[currentDuel[cd].user1].duel.totalProfits = users[currentDuel[cd].user1].duel.totalProfits.add(profit);
        } else {
           users[currentDuel[cd].user2].duel.profits = users[currentDuel[cd].user2].duel.profits.add(profit);
           users[currentDuel[cd].user2].duel.totalProfits = users[currentDuel[cd].user2].duel.totalProfits.add(profit);
        } 
        cd = cd.add(1);
    }   
    
    function duelDeposit() external payable {
        User storage user = users[msg.sender];
        require(now >= duelNextCycleTime && duelEnabled == true, "Duel deposit disabled or not available yet");
        require(msg.value == duelTicketsCost, "Wrong Amount");
        require(user.duel.power[cd] == 0, "Only one deposit is allow");
        
        if (user.register == false) {
           usersCount = usersCount.add(1);
           user.id = usersCount;
           user.register = true;
           user.nick = "New User";
           emit Newbie(user.nick, msg.sender);
        } 
        
        duelTotalInvested = duelTotalInvested.add(msg.value);
        if (currentDuel[cd].user1 == address(0)) {
            user.duel.power[cd] = getRandomNum(1, 100, 111);
            currentDuel[cd].user1 = msg.sender;
            payFee(duelTicketsCost.mul(2)); 
        } else {
            user.duel.power[cd] = getRandomNum(1, 100, 222);
            if (user.duel.power[cd] == users[currentDuel[cd].user1].duel.power[cd]) {
               if (user.duel.power[cd] > 50) { 
                   user.duel.power[cd] = user.duel.power[cd].sub(1);
               } else {
                   user.duel.power[cd] = user.duel.power[cd].add(1);
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
        user.duel.withdrawn = user.duel.withdrawn.add(amount);
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
    
    function getContractOldDuelInfo(uint oldId) view external returns(uint _lastWinnPower, uint _lastLosePower,  uint _lastWinnId, uint _lastLoseId, string memory _lastWinnNick, string memory _lastLoseNick) {
        uint d = minZero(cd, oldId);

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