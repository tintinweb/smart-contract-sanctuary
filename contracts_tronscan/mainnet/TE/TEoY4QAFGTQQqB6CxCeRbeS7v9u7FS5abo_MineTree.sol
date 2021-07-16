//SourceUnit: MineTreeTRX.sol

pragma solidity 0.5.9;

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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract MineTree {

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint totalEarning;
        address[] referral;
        uint8 currentLevel;
        mapping(uint => uint) levelExpired;
    }
    
    struct NonWorkingUserStruct {
        bool isExist;
        uint id;
        uint currentReferrer;
        mapping(uint8 => address[]) firstLine;
        mapping(uint8 => address[]) SecondLine;
        uint totalEarningTrx;
        uint8 currentLevel;
        mapping(uint8 => bool) levelStatus;
        mapping(uint8 => uint) reInvestCount;
    }
    
    using SafeMath for uint256;
    address public Wallet;
    address public usirs;
    uint public NWcurrUserID = 0;
    uint public currUserID = 0;
    bool public lockStatus;

    uint8 public WORKPLANLIMIT = 3;
    uint public PERIOD_LENGTH = 33 days;
    uint public GRACE_PERIOD = 3 days;

    mapping (uint8 => uint) public LEVEL_PRICE;
    mapping (uint8 => uint) public NONWORKING_PLAN;
    mapping (address  => uint) public NWTotalEarned;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping(uint8 => mapping (uint8 => uint))) public levelEarned;
    mapping (address => uint) public loopCheck;
    mapping (address => NonWorkingUserStruct) public NWUsers;
    mapping (uint => address) public NWUserList;
    
    event regLevelEvent(uint _matrix,address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(uint _matrix,address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(uint _matrix,address indexed _user, address indexed _referrer, uint _level, uint _time);
    event lostMoneyForLevelEvent(uint _matrix,address indexed _user, address indexed _referrer, uint _level, uint _time);
    
    constructor(address _usirsAddress) public {
        Wallet = msg.sender;
        lockStatus = true;
        usirs = _usirsAddress;
        
        //FOUNDATION
        LEVEL_PRICE[1] = 500 trx;
        LEVEL_PRICE[2] = 1000 trx;
        LEVEL_PRICE[3] = 3000 trx;
        LEVEL_PRICE[4] = 9000 trx;
        
        //PREMIUM
        LEVEL_PRICE[5] = 2500 trx;
        LEVEL_PRICE[6] = 5000 trx;
        LEVEL_PRICE[7] = 15000 trx;
        LEVEL_PRICE[8] = 45000 trx;
        
        //ELITE
        LEVEL_PRICE[9] = 10000 trx;
        LEVEL_PRICE[10] = 20000 trx;
        LEVEL_PRICE[11] = 60000 trx;
        LEVEL_PRICE[12] = 180000 trx;
        
        
        NONWORKING_PLAN[1] = 500 trx;
        NONWORKING_PLAN[2] = 1000 trx;
        NONWORKING_PLAN[3] = 2000 trx;
        NONWORKING_PLAN[4] = 4000 trx;
        NONWORKING_PLAN[5] = 8000 trx;
        NONWORKING_PLAN[6] = 16000 trx;
        NONWORKING_PLAN[7] = 32000 trx;
        NONWORKING_PLAN[8] = 64000 trx;
        NONWORKING_PLAN[9] = 128000 trx;
        NONWORKING_PLAN[10] = 256000 trx;
        NONWORKING_PLAN[11] = 512000 trx;
        NONWORKING_PLAN[12] = 1024000 trx;

        UserStruct memory userStruct;
        currUserID = currUserID.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            totalEarning:0,
            referrerID: 0,
            currentLevel: 1,
            referral: new address[](0)
        });
        users[Wallet] = userStruct;
        userList[currUserID] = Wallet;
        users[Wallet].currentLevel = 12;

        NonWorkingUserStruct memory NWStruct;
        NWcurrUserID = NWcurrUserID.add(1);
        
        NWStruct = NonWorkingUserStruct({
            isExist: true,
            id: NWcurrUserID,
            currentReferrer: 0,
            currentLevel: 1,
            totalEarningTrx: 0
        });
        
        NWUsers[Wallet] = NWStruct;
        NWUserList[NWcurrUserID] = Wallet;
        NWUsers[Wallet].currentLevel = 12;
        
        for(uint8 i = 1; i <= 12; i++) {
            users[Wallet].levelExpired[i] = 55555555555;
            NWUsers[Wallet].levelStatus[i] = true;
            NWUsers[Wallet].firstLine[i] = new address[](0);
            NWUsers[Wallet].SecondLine[i] = new address[](0);
        }
    }
    
    modifier isUnlock(){
        require(lockStatus == true,"Contract is locked");
        _;
    }

    function () external payable  {
        
        revert("Invalid Transaction");
        
    }
    
    function register(uint _referrerID) public payable isUnlock {
        require(msg.value == LEVEL_PRICE[1].add(NONWORKING_PLAN[1]), "Incorrect Value");

        regUser(_referrerID);
        NWRegistration();
        
    }

    function regUser(uint _referrerID) internal {
        require(!users[msg.sender].isExist, "User exist");
        require(_referrerID > 0 && _referrerID <= currUserID, "Incorrect referrer Id");

        if(users[userList[_referrerID]].referral.length >= WORKPLANLIMIT) 
        _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID = currUserID.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            totalEarning:0,
            referrerID: _referrerID,
            referral: new address[](0),
            currentLevel : 1
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);

        users[userList[_referrerID]].referral.push(msg.sender);
        loopCheck[msg.sender] = 0;

        payForLevel(1, msg.sender);

        emit regLevelEvent(1,msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint8 _level) external payable isUnlock {
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 12, "Incorrect level");

        if(_level == 1) {
            require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
            users[msg.sender].levelExpired[1] = users[msg.sender].levelExpired[1].add(PERIOD_LENGTH);
        }
        else {
            require(msg.value == LEVEL_PRICE[_level], "Incorrect Value");

            for(uint l =_level - 1; l > 0; l--) 
                require(users[msg.sender].levelExpired[l].add(GRACE_PERIOD) >= now, "Buy the previous level");

            if(users[msg.sender].levelExpired[_level] == 0) {
                users[msg.sender].currentLevel = _level;
                users[msg.sender].levelExpired[_level] = now.add(PERIOD_LENGTH);
            }
            else 
                users[msg.sender].levelExpired[_level] = users[msg.sender].levelExpired[_level].add(PERIOD_LENGTH);
        }
        
        loopCheck[msg.sender] = 0;
        payForLevel(_level, msg.sender);

        emit buyLevelEvent(1,msg.sender, _level, now);
    }

    function payForLevel(uint8 _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        
        if(_level == 1 || _level == 5 || _level == 9) {
            referer = userList[users[_user].referrerID];
        }
        else if(_level == 2 || _level == 6 || _level == 10) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        }
        else if(_level == 3 || _level == 7 || _level == 11) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        }
        else if(_level == 4 || _level == 8 || _level == 12) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if(!users[referer].isExist) 
            referer = userList[1];

        if (loopCheck[msg.sender] >= 9) 
            referer = userList[1];
        
        
        if(users[referer].levelExpired[_level] >= now) {
            
            if(referer == Wallet) {
                require(address(uint160(usirs)).send(LEVEL_PRICE[_level]), "Transfer failed");
                emit getMoneyForLevelEvent(1,usirs, msg.sender, _level, now);
            }    
            else{    
                require(address(uint160(referer)).send(LEVEL_PRICE[_level]), "Referrer transfer failed");
                emit getMoneyForLevelEvent(1,referer, msg.sender, _level, now);
            }
            users[referer].totalEarning = users[referer].totalEarning.add(LEVEL_PRICE[_level]);
            levelEarned[referer][1][_level] =  levelEarned[referer][1][_level].add(LEVEL_PRICE[_level]);
                
        }
        else {
            
            if (loopCheck[msg.sender] < 9) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                emit lostMoneyForLevelEvent(1,referer, msg.sender, _level, now);
                payForLevel(_level, referer);
            }
        }
    }
    
    function NWRegistration() internal {
        require(!NWUsers[msg.sender].isExist, "User exist");
        
        address firstLineAddress;
        address secondLineAddress;
         
        for(uint i = 1; i <= NWcurrUserID; i++) {
            if(NWUsers[NWUserList[i]].SecondLine[1].length < 16) {
                (secondLineAddress,firstLineAddress) = findAPReferrer(NWUserList[i]); 
                break;
            }
            else if(NWUsers[NWUserList[i]].SecondLine[1].length == 16) {
                continue;
            }
        }
        
        NonWorkingUserStruct memory NWStruct;
        NWcurrUserID = NWcurrUserID.add(1);
        
        NWStruct = NonWorkingUserStruct({
            isExist: true,
            id: NWcurrUserID,
            currentReferrer: NWUsers[firstLineAddress].id,
            currentLevel: 1,
            totalEarningTrx: 0
        });

        NWUsers[msg.sender] = NWStruct;
        NWUsers[msg.sender].levelStatus[1] = true;
        NWUsers[msg.sender].firstLine[1] = new address[](0);
        NWUsers[msg.sender].SecondLine[1] = new address[](0);
        NWUserList[NWcurrUserID] = msg.sender; 
        
        updateNWDetails(1,msg.sender,firstLineAddress,secondLineAddress);
        emit regLevelEvent(2,msg.sender, firstLineAddress, now);
    }
    
    function NWBuyLevel(uint8 _level) external payable isUnlock {
        require(NWUsers[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 12, "Incorrect level");
        require(NWUsers[msg.sender].levelStatus[_level] == false, "Already Active");
        require(msg.value == NONWORKING_PLAN[_level], "Incorrect Value");

        for(uint8 l =_level - 1; l > 0; l--) 
           require(NWUsers[msg.sender].levelStatus[l]== true, "Buy the previous level");

        NWUsers[msg.sender].currentLevel = _level;
        NWUsers[msg.sender].levelStatus[_level] = true;
        
        address firstLineAddress;
        address secondLineAddress;
        
        firstLineAddress = NWUserList[NWUsers[msg.sender].currentReferrer];
        secondLineAddress = NWUserList[NWUsers[firstLineAddress].currentReferrer];
        
        loopCheck[msg.sender] = 0;
        updateNWDetails(_level,msg.sender,firstLineAddress,secondLineAddress);
        emit buyLevelEvent(2,msg.sender, _level, now);
    }
    
    function findAPReferrer(address _firstLine) internal view returns(address,address) {
        
        if(NWUsers[_firstLine].firstLine[1].length < 4)
            return(NWUserList[NWUsers[_firstLine].currentReferrer],_firstLine);
            
        else {
            
            for(uint8 i=0; i<4; i++) 
            {
                address referrals;
                referrals = NWUsers[_firstLine].firstLine[1][i];
                
                if(NWUsers[referrals].firstLine[1].length  < 4) {
                        return (_firstLine, referrals);
                }
            }
            
        }
    }
    
    function updateNWDetails(uint8 _level, address _user, address _firstLine, address _secondLine) internal {
       
        NWUsers[_firstLine].firstLine[_level].push(_user);
        
        if(_secondLine != address(0))
            NWUsers[_secondLine].SecondLine[_level].push(_user);
    
        if(NWUsers[_firstLine].firstLine[_level].length == 1 ||  NWUsers[_firstLine].firstLine[_level].length == 4) {
            
            if(NWUsers[_secondLine].SecondLine[_level].length == 1 || NWUsers[_secondLine].SecondLine[_level].length == 16) {   
                
                if(NWUsers[_secondLine].SecondLine[_level].length == 16)
                    NWUsers[_secondLine].reInvestCount[_level] = NWUsers[_secondLine].reInvestCount[_level].add(1);
                
                 if(NWUsers[_firstLine].firstLine[_level].length == 4 )
                    NWUsers[_firstLine].reInvestCount[_level] = NWUsers[_firstLine].reInvestCount[_level].add(1);
                
                return payForNW(3, _level, _user);
            }
            else {
                
                if(NWUsers[_firstLine].firstLine[_level].length == 4 )
                    NWUsers[_firstLine].reInvestCount[_level] = NWUsers[_firstLine].reInvestCount[_level].add(1);
                
                return payForNW(2, _level, _user);
            }
        }
        
        if(NWUsers[_firstLine].firstLine[_level].length == 2 || NWUsers[_firstLine].firstLine[_level].length ==3) 
            return payForNW(1, _level, _user);

    }
    
    function payForNW(uint8 flag, uint8 _level, address _user) internal {
        address[4] memory uplines;
        
        if(flag == 1) {
            uplines[0] = NWUserList[NWUsers[_user].currentReferrer];
        }
        else if(flag == 2) {
            uplines[1] = NWUserList[NWUsers[_user].currentReferrer];
            uplines[0] = NWUserList[NWUsers[uplines[1]].currentReferrer];
        }
        else if(flag == 3) {
            uplines[2] = NWUserList[NWUsers[_user].currentReferrer];
            uplines[1] = NWUserList[NWUsers[uplines[2]].currentReferrer];
            uplines[0] = NWUserList[NWUsers[uplines[1]].currentReferrer];
        }
        
        
        if(loopCheck[msg.sender] >= 3) 
            uplines[0] = Wallet;
        
        
        if(!NWUsers[uplines[0]].isExist) 
            uplines[0] = Wallet;
            
            
        if(NWUsers[uplines[0]].levelStatus[_level] == true) {
            require((address(uint160(uplines[0])).send(NONWORKING_PLAN[_level])), "Transaction Failure");
            NWUsers[uplines[0]].totalEarningTrx = NWUsers[uplines[0]].totalEarningTrx.add(NONWORKING_PLAN[_level]);
            NWTotalEarned[uplines[0]] = NWTotalEarned[uplines[0]].add(NONWORKING_PLAN[_level]);
            emit getMoneyForLevelEvent(2,uplines[0], msg.sender, _level, now);
        }
        else {
            
            if (loopCheck[msg.sender] < 3) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                emit lostMoneyForLevelEvent(2,uplines[0], msg.sender, _level, now);
                payForNW(flag,_level, uplines[0]);
            }
        }
    
    }
    
    function updateUsirs(address _usirsAddress) public returns (bool) {
       require(msg.sender == Wallet, "Only Wallet");
       
       usirs = _usirsAddress;
       return true;
    }
    
    function updatePrice(uint8 _matrix,uint8 _level, uint _price) public returns (bool) {
        require(msg.sender == Wallet, "Only Wallet");
        if(_matrix == 1)
            LEVEL_PRICE[_level] = _price;
            
        else if(_matrix == 2)
            NONWORKING_PLAN[_level] = _price;
            
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == Wallet, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == Wallet, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    }
    
    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < WORKPLANLIMIT) return _user;

        address[] memory referrals = new address[](364);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 364; i++) {
            if(users[referrals[i]].referral.length == WORKPLANLIMIT) {
                if(i < 126) {
                    referrals[(i+1)*3] = users[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = users[referrals[i]].referral[2];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, "No Free Referrer");

        return freeReferrer;
    }
    
    function viewWPUserReferral(address _user) public view returns(address[] memory) {
            return users[_user].referral;
    }  
    
    function viewNWUserReferral(address _user,uint8 _level) public view returns(address[] memory, address[]  memory) {
            return (NWUsers[_user].firstLine[_level],NWUsers[_user].SecondLine[_level]);
    }

    function viewWPUserLevelExpired(address _user, uint8 _level) public view returns(uint) {
       return users[_user].levelExpired[_level];
    }
    
    function viewNWUserLevelStatus(address _user, uint8 _level) public view returns(bool) {
       return NWUsers[_user].levelStatus[_level];
    }
    
     function viewNWReInvestCount(address _user, uint8 _level) public view returns(uint) {
       return NWUsers[_user].reInvestCount[_level];
    }
    
    function getTotalEarnedtrx(uint _matrix) public view returns(uint) {
        uint totalTrx;
        
        if(_matrix == 1)
        {
            for( uint i=1;i<=currUserID;i++) {
                totalTrx = totalTrx.add(users[userList[i]].totalEarning);
            }
        
            return totalTrx;
        }
        else if(_matrix == 2) {
            
            for( uint i=1;i<=NWcurrUserID;i++) {
                totalTrx = totalTrx.add(NWUsers[NWUserList[i]].totalEarningTrx);
            }
        
            return totalTrx;
            
        }
    }
    
}