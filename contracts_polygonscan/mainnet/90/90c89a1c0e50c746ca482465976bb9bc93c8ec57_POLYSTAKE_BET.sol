/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

pragma solidity 0.5.8;

contract POLYSTAKE_BET{
    using SafeMath for uint256;
    
    struct User {
        uint id;
        bool register;
        string nick;
        pBet bet;
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
        string title;
        string name1; 
        string name2; 
        string name3; 
    }
    
    mapping(uint => cBet) internal currentBet;
    uint public cb = 1;
    bool public betEnabled = false;
    uint public maxBetUsers = 300;
    uint public minBetAmount = 1 ether;
    uint public betEndTime;
    uint private betFeeDevAmount;
    uint public betTotalInvested;
    
    function updateBetSettings(uint maxPLayers, uint endTime, uint timeToEnd, uint minAmount, bool enabled, string calldata title, string calldata name1, string calldata name2, string calldata name3) external onlyOwner {
        require(currentBet[cb].payed == false, "Bet have not be PAYED");
        
        if (maxPLayers > currentBet[cb].totaUsers) {
           if (maxPLayers != 0) {
              maxBetUsers = maxPLayers;
           }
        }
        if (minAmount != 0) {
           minBetAmount = minAmount;
        }
        if (keccak256(abi.encodePacked(title)) != keccak256(abi.encodePacked(EMPTY_STR))) {
           currentBet[cb].title = title;
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
        if (endTime != 0) {
           betEndTime = endTime; 
        } 
        if (timeToEnd != 0) {
           betEndTime = now.add(timeToEnd); 
        }
        betEnabled = enabled;
    }    
    
    function betDeposit(uint opt) external payable {
        User storage user = users[msg.sender];
        require(betEnabled == true, "Bet deposit disabled");
        require(opt == 1 || opt == 2 || opt == 3, "Wrong opt");
        require(msg.value >= minBetAmount, "Min bet is MinAmount TRX");
        require(now <= betEndTime, "Bet deposit disabled. Out of time");
        uint amountBet = (user.bet.betAmount[cb][0]).add(user.bet.betAmount[cb][1]).add(user.bet.betAmount[cb][2]); 
        require(maxBetUsers > currentBet[cb].totaUsers || amountBet > 0, "Only (n) Users is allowed");
        
        if (user.register == false) {
           usersCount = usersCount.add(1);
           user.id = usersCount;
           user.register = true;
           user.nick = "New User";
           emit Newbie(user.nick, msg.sender);
        }
        
        if (amountBet == 0) {
            currentBet[cb].totaUsers = currentBet[cb].totaUsers.add(1); 
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
        betTotalInvested = betTotalInvested.add(msg.value);
        user.bet.betAmount[cb][opt-1] = user.bet.betAmount[cb][opt-1].add(msg.value);
        currentBet[cb].pot[opt-1] = currentBet[cb].pot[opt-1].add(msg.value);
    }
    
    function setBetWin(uint win) external onlyOwner {    
        require(win == 0 || win == 1 || win == 2 || win == 3, "Wrong win");
        require(now > betEndTime);
        currentBet[cb].betWin = win;
    } 
    
    function getBetPotPay(uint pWin, uint pTotal) private view returns(uint) {
        uint ret;
        if (pWin < pTotal.mul(getWinnPercent()).div(100)) {
            ret = pTotal.mul(getWinnPercent()).div(100); 
        } else {
            ret = pTotal; 
        } 
        return(ret);
    }
    
    function getBetFeeDevAmount(uint pWin, uint pTotal) private view returns(uint) {
        uint ret;
        if (pWin < pTotal.mul(getWinnPercent()).div(100)) {
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
        
        uint Pot_Total = (currentBet[cb].pot[0]).add(currentBet[cb].pot[1]).add(currentBet[cb].pot[2]);
        uint Pot_Pay;
        uint Pot_Lose;
        uint Pot_Win;
        
        if (currentBet[cb].betWin == 1) {
            Pot_Lose = currentBet[cb].pot[1].add(currentBet[cb].pot[2]);
            Pot_Win = currentBet[cb].pot[0];
            Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
            if (Pot_Win > 0) {
                for(uint i = 0; i < currentBet[cb].bettors1.length; i++) {
                   users[currentBet[cb].bettors1[i]].bet.profits = users[currentBet[cb].bettors1[i]].bet.profits.add(Pot_Pay.mul(users[currentBet[cb].bettors1[i]].bet.betAmount[cb][0]).div(Pot_Win)); 
                   users[currentBet[cb].bettors1[i]].bet.totalProfits = users[currentBet[cb].bettors1[i]].bet.totalProfits.add(Pot_Pay.mul(users[currentBet[cb].bettors1[i]].bet.betAmount[cb][0]).div(Pot_Win));
                }
            } else owner.transfer(Pot_Pay);
        } else 
        if (currentBet[cb].betWin == 2) {
            Pot_Lose = currentBet[cb].pot[0].add(currentBet[cb].pot[2]);
            Pot_Win = currentBet[cb].pot[1];
            Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
            if (Pot_Win > 0) {
                for(uint i = 0; i < currentBet[cb].bettors2.length; i++) {
                   users[currentBet[cb].bettors2[i]].bet.profits = users[currentBet[cb].bettors2[i]].bet.profits.add(Pot_Pay.mul(users[currentBet[cb].bettors2[i]].bet.betAmount[cb][1]).div(Pot_Win)); 
                   users[currentBet[cb].bettors2[i]].bet.totalProfits = users[currentBet[cb].bettors2[i]].bet.totalProfits.add(Pot_Pay.mul(users[currentBet[cb].bettors2[i]].bet.betAmount[cb][1]).div(Pot_Win));
                } 
            } else owner.transfer(Pot_Pay);
        } else
        if (currentBet[cb].betWin == 3) {
            Pot_Lose = currentBet[cb].pot[0].add(currentBet[cb].pot[1]);
            Pot_Win = currentBet[cb].pot[2];
            Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
            if (Pot_Win > 0) {
                for(uint i = 0; i < currentBet[cb].bettors3.length; i++) {
                   users[currentBet[cb].bettors3[i]].bet.profits = users[currentBet[cb].bettors3[i]].bet.profits.add(Pot_Pay.mul(users[currentBet[cb].bettors3[i]].bet.betAmount[cb][2]).div(Pot_Win)); 
                   users[currentBet[cb].bettors3[i]].bet.totalProfits = users[currentBet[cb].bettors3[i]].bet.totalProfits.add(Pot_Pay.mul(users[currentBet[cb].bettors3[i]].bet.betAmount[cb][2]).div(Pot_Win));
                } 
            } else owner.transfer(Pot_Pay);
        }
        betFeeDevAmount = getBetFeeDevAmount(Pot_Win, Pot_Total);
    }
    
    function resetCurrentBet() external onlyOwner {  
        require(currentBet[cb].payed == true, "Not payed yet");
        if (betFeeDevAmount > 0) {
            uint val = betFeeDevAmount;
            betFeeDevAmount = 0;
            payFee(val);
        }
        cb = cb.add(1);
        betEnabled = false;
    }
    
    function withdrawBetProfits() external {
        User storage user = users[msg.sender];
        uint amount = user.bet.profits;
        require(amount > 0, "Profits = 0");
        user.bet.profits = 0;
        user.bet.withdrawn = user.bet.withdrawn.add(amount);
        msg.sender.transfer(amount);
    }
    
    function getContractBetInfo1() view external returns(bool _payed, uint _b1, uint _b2, uint _b3, uint _p1, uint _p2, uint _p3, uint _totalUsers, uint _betWin) {
        _b1 = currentBet[cb].bettors1.length;
        _b2 = currentBet[cb].bettors2.length;
        _b3 = currentBet[cb].bettors3.length;
        _p1 = currentBet[cb].pot[0];
        _p2 = currentBet[cb].pot[1];
        _p3 = currentBet[cb].pot[2];
        
        return (
            currentBet[cb].payed,
            _b1, _b2, _b3,
            _p1, _p2, _p3,
            currentBet[cb].totaUsers,
            currentBet[cb].betWin
        );
    }  
    
    function getContractBetInfo2() view external returns(uint _endTime, string memory _betName1, string memory _betName2, string memory _betName3, string memory _betTitle) {
        return (
            minZero(betEndTime, now), 
            currentBet[cb].name1,
            currentBet[cb].name2,
            currentBet[cb].name3,
            currentBet[cb].title
        );
    }      
    
    function getUserBetInfo(address _addr) view external returns(uint _betProfits, uint _betTotalProfits, uint _betWithdrawn, uint _B1, uint _B2, uint _B3, uint _estimatedB1, uint _estimatedB2, uint _estimatedB3) {
        User storage user = users[_addr];
        uint Pot_Total = (currentBet[cb].pot[0]).add(currentBet[cb].pot[1]).add(currentBet[cb].pot[2]);
        uint Pot_Pay;
        uint Pot_Lose;
        uint Pot_Win;
       
        // b1
        Pot_Lose = currentBet[cb].pot[1].add(currentBet[cb].pot[2]);
        Pot_Win = currentBet[cb].pot[0];
        Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
        if (Pot_Win > 0) {
            _estimatedB1 = Pot_Pay.mul(user.bet.betAmount[cb][0]).div(Pot_Win); 
        } else {
            _estimatedB1 = 0;
        }
        
        // b2
        Pot_Lose = currentBet[cb].pot[0].add(currentBet[cb].pot[2]);
        Pot_Win = currentBet[cb].pot[1];
        Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
        if (Pot_Win > 0) {
            _estimatedB2 = Pot_Pay.mul(user.bet.betAmount[cb][1]).div(Pot_Win); 
        } else {
            _estimatedB2 = 0;
        }
        
        // b3
        Pot_Lose = currentBet[cb].pot[0].add(currentBet[cb].pot[1]);
        Pot_Win = currentBet[cb].pot[2];
        Pot_Pay = getBetPotPay(Pot_Win, Pot_Total);
        if (Pot_Win > 0) {
            _estimatedB3 = Pot_Pay.mul(user.bet.betAmount[cb][2]).div(Pot_Win); 
        } else {
            _estimatedB3 = 0;
        }
        
        return(
            user.bet.profits, 
            user.bet.totalProfits, 
            user.bet.withdrawn, 
            user.bet.betAmount[cb][0],
            user.bet.betAmount[cb][1],
            user.bet.betAmount[cb][2],
            _estimatedB1,
            _estimatedB2,
            _estimatedB3
        ); 
    } 
    ///////////////////////////// END BET ///////////////////////////////  

    
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