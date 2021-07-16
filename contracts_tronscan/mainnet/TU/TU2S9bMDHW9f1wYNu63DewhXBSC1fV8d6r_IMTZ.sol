//SourceUnit: 1.sol

pragma solidity ^0.5.8;

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

contract TRC20 {
    function distribute(address reciever, uint value) public returns(bool);
}

contract IMTZ {

    struct UserStruct {
        bool isExist;
        bool blocked;
        uint id;
        uint referrerID;
        uint8 currentLevel;
        uint totalEarningTrx;
        address[] referral;
        mapping (uint8 => bool) levelStatus;
    }
    
    struct AutoPoolUserStruct {
        bool isExist;
        bool blocked;
        address userAddress;
        uint uniqueId;
        uint referrerID;
        uint8 currentLevel;
        uint totalEarningTrx;
        mapping (uint8 => uint[]) referral;
        mapping (uint8 => bool) levelStatus;
        mapping (uint8 => uint) reInvestCount;
    }
    
    using SafeMath for uint256;
    address public passup; 
    address public rebirth;
    uint public userCurrentId = 0;
    TRC20 Token;
    
    mapping (uint8 => uint) public autoPoolcurrentId;
    mapping (uint8 => uint) public APId;
    mapping (uint => address) public userList;
    mapping (address => uint) public autoPoolId;
    mapping (address => UserStruct) public users;
    mapping (uint8 => uint) public levelPrice;
    mapping (uint8 => uint) public tokensForLevel;
    mapping (uint8 => mapping (uint => address)) public autoPoolUserList;
    mapping (uint => AutoPoolUserStruct) public autoPoolUniqueUsers;
    mapping (uint8 => mapping (uint => AutoPoolUserStruct)) public autoPoolUsers;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public EarnedTrx;
    
    modifier onlyOwner() {
        require(msg.sender == passup, "Only Owner");
        _;
    }
    
    event regLevelEvent(uint8 indexed Matrix, address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Time);
    event buyLevelEvent(uint8 indexed Matrix, address indexed UserAddress, uint UserId, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint LevelPrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress, uint UserId,  address indexed Caller, uint CallerId, uint8 Levelno, uint ReInvestCount, uint Time);
    event sponsorEarnedEvent(address indexed UserAddress, uint UserId, address indexed Caller, uint CallerId, uint8 Level, uint EarnAmount, uint Time);
    
    constructor(address _rebirth, address _tokenAddress) public {
        passup = msg.sender;
        rebirth = _rebirth;
        Token = TRC20(_tokenAddress);
        
        // LevelPrice
        levelPrice[1] = 300 trx;
        levelPrice[2] = 600 trx;
        levelPrice[3] = 1500 trx;
        levelPrice[4] = 2400 trx;
        levelPrice[5] = 4200 trx;
        levelPrice[6] = 6000 trx;
        levelPrice[7] = 12000 trx;
        levelPrice[8] = 24000 trx;
        levelPrice[9] = 60000 trx;
        levelPrice[10] = 150000 trx;
        levelPrice[11] = 279000 trx;
        levelPrice[12] = 450000 trx;
        
        tokensForLevel[1] = 100*(10**18);
        
        UserStruct memory userStruct;
        userCurrentId = 1;

        userStruct = UserStruct({
            isExist: true,
            blocked: false,
            id: userCurrentId,
            referrerID: 0,
            currentLevel:1,
            totalEarningTrx:0,
            referral: new address[](0)
        });
        users[passup] = userStruct;
        userList[userCurrentId] = passup;
        
        AutoPoolUserStruct memory autoPoolStruct;
        
        autoPoolStruct = AutoPoolUserStruct({
            isExist: true,
            blocked: false,
            userAddress: passup,
            uniqueId: userCurrentId,
            referrerID: 0,
            currentLevel: 1,
            totalEarningTrx:0
        });     
        
        autoPoolUniqueUsers[userCurrentId] = autoPoolStruct;
        autoPoolId[passup] = userCurrentId;
        autoPoolUniqueUsers[userCurrentId].currentLevel = 12;
        users[passup].currentLevel = 12;
        
        for(uint8 i = 1; i <= 12; i++) {   
            users[passup].levelStatus[i] = true;
            autoPoolcurrentId[i] = 1;
            autoPoolUsers[i][autoPoolcurrentId[i]].levelStatus[i] = true;
            autoPoolUserList[i][autoPoolcurrentId[i]] = passup;
            autoPoolUsers[i][autoPoolcurrentId[i]] = autoPoolStruct;
            autoPoolUniqueUsers[userCurrentId].levelStatus[i] = true;
            APId[i] = 1;
            tokensForLevel[i] = i*tokensForLevel[1];
        }
        
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function pair(uint _referrerID) external payable {
        
        uint _userId = autoPoolId[msg.sender];  
        require(users[msg.sender].isExist == false && autoPoolUniqueUsers[_userId].isExist ==  false, "User Exist");
        require(msg.value == levelPrice[1], "Incorrect Value");
        require(_referrerID > 0 && _referrerID <= userCurrentId, "Incorrect referrerID");
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract");
        
        userCurrentId = userCurrentId.add(1);
        userList[userCurrentId] = msg.sender;
        
        _workPlanReg(_referrerID);
        _autoPoolReg();
    }
    
    function liquidity(uint8 _level) external payable {
        uint _userId = autoPoolId[msg.sender];
        
        require(users[msg.sender].isExist && autoPoolUniqueUsers[_userId].isExist, "User not exist"); 
        require(users[msg.sender].levelStatus[_level] ==  false && autoPoolUniqueUsers[_userId].levelStatus[_level] == false, "Already Active in this level");
        require(_level > 0 && _level <= 12, "Incorrect level");
        require(msg.value == levelPrice[_level], "Incorrect Value");
         
        if(_level != 1)  
        {
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].levelStatus[l] == true && autoPoolUniqueUsers[_userId].levelStatus[l] == true, "Buy the previous level");
        }    
        
        _workPlanBuy(_level);
        _autoPoolBuy(_userId,_level);
    }
    
   
    function updateLevelToken(uint8 _level, uint _token) onlyOwner external returns (bool) {
        tokensForLevel[_level] = _token;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function updateBlockStatus(address _user, bool _status) onlyOwner external returns(bool) {
        users[_user].blocked = _status;
        autoPoolUniqueUsers[autoPoolId[_user]].blocked = _status;
        
        return true;
    }
    
    function viewWPUserReferral(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].referral;
    }
    
    function viewAPUserReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
        return (autoPoolUniqueUsers[_userId].referral[_level]);
    }
    
    function viewAPInternalUserReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
        return (autoPoolUsers[_level][_userId].referral[_level]);
    }
    
    function viewUserLevelStatus(address _userAddress, uint8 _matrix, uint8 _level) public view returns(bool) {
        
        if(_matrix == 1)        
            return users[_userAddress].levelStatus[_level];
            
        if(_matrix == 2) {
            uint256 _userId = autoPoolId[_userAddress];        
            return autoPoolUniqueUsers[_userId].levelStatus[_level];
        }
        
    }
    
    function viewAPUserReInvestCount(uint _userId, uint8 _level) public view returns(uint) {
        return autoPoolUniqueUsers[_userId].reInvestCount[_level];
    }
   
    function getTotalEarnedTrx(uint8 _matrix) public view returns(uint) {
        uint totalTrx;
        if(_matrix == 1)
        {
            for( uint i=1;i<=userCurrentId;i++) {
                totalTrx = totalTrx.add(users[userList[i]].totalEarningTrx);
            }
        }
        else if(_matrix == 2)
        {
            for( uint i = 1; i <= userCurrentId; i++) {
                totalTrx = totalTrx.add(autoPoolUniqueUsers[i].totalEarningTrx);
            }
            
        }
        
        return totalTrx;
    }
   
    function _workPlanReg(uint _referrerID) internal  {
        
        address referer = userList[_referrerID];
        
        UserStruct memory userStruct;
        
        userStruct = UserStruct({
            isExist: true,
            blocked: false,
            id: userCurrentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningTrx:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        users[msg.sender].levelStatus[1] = true;
        users[referer].referral.push(msg.sender);

        _workPlanPay(0,1, msg.sender);
        emit regLevelEvent(1, msg.sender, userCurrentId, userList[_referrerID], _referrerID, now);
    }
    
    function _autoPoolReg() internal  {
        
        uint _referrerID;
        
        for(uint i = APId[1]; i <= autoPoolcurrentId[1]; i++) {
            if(autoPoolUsers[1][i].referral[1].length < 4) {
                _referrerID = i; 
                break;
            }
            else if(autoPoolUsers[1][i].referral[1].length == 4) {
                APId[1] = i;
                continue;
            }
        }
        
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[1] = autoPoolcurrentId[1].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            blocked: false,
            userAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningTrx:0
        });

        autoPoolUsers[1][autoPoolcurrentId[1]] = nonWorkUserStruct;
        autoPoolUserList[1][autoPoolcurrentId[1]] = msg.sender;
        autoPoolUsers[1][autoPoolcurrentId[1]].levelStatus[1] = true;
        autoPoolUsers[1][autoPoolcurrentId[1]].reInvestCount[1] = 0;
        
        autoPoolUniqueUsers[userCurrentId] = nonWorkUserStruct;
        autoPoolId[msg.sender] = userCurrentId;
        autoPoolUniqueUsers[userCurrentId].referral[1] = new uint[](0);
        autoPoolUniqueUsers[userCurrentId].levelStatus[1] = true;
        autoPoolUniqueUsers[userCurrentId].reInvestCount[1] = 0;
        
        autoPoolUsers[1][_referrerID].referral[1].push(autoPoolcurrentId[1]);
        autoPoolUniqueUsers[autoPoolId[autoPoolUsers[1][_referrerID].userAddress]].referral[1].push(userCurrentId);
        
        _updateNWDetails(_referrerID,1);
        emit regLevelEvent(2, msg.sender, userCurrentId, autoPoolUserList[1][_referrerID], _referrerID, now);
    }
    
    function _workPlanBuy(uint8 _level) internal  {
       
        users[msg.sender].levelStatus[_level] = true;
        users[msg.sender].currentLevel = _level;
       
        _workPlanPay(0,_level, msg.sender);
        emit buyLevelEvent(1, msg.sender, users[msg.sender].id, _level, now);
    }
    
    function _autoPoolBuy(uint _userId, uint8 _level) internal  {
        
        uint _referrerID;
        
        for(uint i = APId[_level]; i <= autoPoolcurrentId[_level]; i++) {
            if(autoPoolUsers[_level][i].referral[_level].length < 4) {
                _referrerID = i; 
                break;
            }
            else if(autoPoolUsers[_level][i].referral[_level].length == 4) {
                APId[_level] = i;
                continue;
            }
        }
        
        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[_level] = autoPoolcurrentId[_level].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            blocked: false,
            userAddress: msg.sender,
            uniqueId: _userId,
            referrerID: _referrerID,
            currentLevel: _level,
            totalEarningTrx:0
        });
            
        autoPoolUsers[_level][autoPoolcurrentId[_level]] = nonWorkUserStruct;
        autoPoolUserList[_level][autoPoolcurrentId[_level]] = msg.sender;
        autoPoolUsers[_level][autoPoolcurrentId[_level]].levelStatus[_level] = true;
        
        autoPoolUniqueUsers[_userId].levelStatus[_level] = true;
        autoPoolUniqueUsers[_userId].currentLevel = _level;
        autoPoolUniqueUsers[_userId].referral[_level] = new uint[](0);
        autoPoolUniqueUsers[_userId].reInvestCount[_level] = 0;
        
        autoPoolUsers[_level][_referrerID].referral[_level].push(autoPoolcurrentId[_level]);
        autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].referral[_level].push(autoPoolId[autoPoolUsers[_level][autoPoolcurrentId[_level]].userAddress]);
        
        _updateNWDetails(_referrerID,_level);
        emit buyLevelEvent(2, msg.sender, _userId, _level, now);
    }
    
    function _updateNWDetails(uint _referrerID, uint8 _level) internal {
        
        autoPoolUsers[_level][autoPoolcurrentId[_level]].referral[_level] = new uint[](0);
        
        if(autoPoolUsers[_level][_referrerID].referral[_level].length == 3) {
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
              
            if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].levelStatus[_level] = true 
                && autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level] < 14) {
                _reInvest(_referrerID,_level);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].referral[_level] = new uint[](0);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level] =  autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level].add(1);
                
                emit reInvestEvent(2, autoPoolUserList[_level][_referrerID], autoPoolId[autoPoolUserList[_level][_referrerID]],  msg.sender,
               autoPoolId[msg.sender], _level, autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level], now);
            }
            else if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].reInvestCount[_level] == 14) {
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_referrerID].userAddress]].levelStatus[_level] = false;
                users[autoPoolUsers[_level][_referrerID].userAddress].levelStatus[_level] = false;
            }
            
        }
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 1) 
            _autoPoolPay(1,_level,autoPoolcurrentId[_level]);
        else if(autoPoolUsers[_level][_referrerID].referral[_level].length == 2) 
            _autoPoolPay(0,_level,autoPoolcurrentId[_level]);
        
    }
     
    function _reInvest(uint _refId, uint8 _level) internal  {
        
        uint _reInvestId;
       
        for(uint i = APId[_level]; i <= autoPoolcurrentId[_level]; i++) {
            
            if(autoPoolUsers[_level][i].referral[_level].length < 4) {
                _reInvestId = i; 
                break;
            }
            else if(autoPoolUsers[_level][i].referral[_level].length == 4) {
                APId[_level] = i;
                continue;
            }
            
        }

        AutoPoolUserStruct memory nonWorkUserStruct;
        autoPoolcurrentId[_level] = autoPoolcurrentId[_level].add(1);
        
        nonWorkUserStruct = AutoPoolUserStruct({
            isExist: true,
            blocked: false,
            userAddress: autoPoolUserList[_level][_refId],
            uniqueId: autoPoolUsers[_level][_refId].uniqueId,
            referrerID: _reInvestId,
            currentLevel: _level,
            totalEarningTrx:0
        });
            
        autoPoolUsers[_level][autoPoolcurrentId[_level]] = nonWorkUserStruct;
        autoPoolUserList[_level][autoPoolcurrentId[_level]] = autoPoolUserList[_level][_refId];
        autoPoolUsers[_level][autoPoolcurrentId[_level]].levelStatus[_level] = true;
        
        autoPoolUsers[_level][_reInvestId].referral[_level].push(autoPoolcurrentId[_level]);
        autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].referral[_level].push(autoPoolId[autoPoolUsers[_level][autoPoolcurrentId[_level]].userAddress]);
        
        autoPoolUsers[_level][autoPoolcurrentId[_level]].referral[_level] = new uint[](0);
        
        if(autoPoolUsers[_level][_reInvestId].referral[_level].length == 3) {
            
            if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].levelStatus[_level] = true 
                && autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level] < 14) {
                _reInvest(_reInvestId,_level);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].referral[_level] = new uint[](0);
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level] =  autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level].add(1);
                emit reInvestEvent(2, autoPoolUsers[_level][_reInvestId].userAddress , autoPoolId[autoPoolUserList[_level][_reInvestId]], msg.sender, autoPoolId[msg.sender], _level, 
                    autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level], now);
            }
            else if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].reInvestCount[_level] == 14) {
                autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][_reInvestId].userAddress]].levelStatus[_level] = false;
                users[autoPoolUsers[_level][_reInvestId].userAddress].levelStatus[_level] = false;
            }
            
        }
       
    }
    
    function _getReferrer(uint8 _level, address _user) internal returns (address) {
        if (_level == 0 || _user == address(0)) {
            return _user;
        }
        
        return _getReferrer( _level - 1,userList[users[_user].referrerID]);
    }

    function _workPlanPay(uint8 _flag, uint8 _level, address _userAddress) internal {
        
        address referer;
        
        if(_flag == 0)
            referer = _getReferrer(_level,_userAddress);
        
        else if(_flag == 1) 
             referer = passup;

        if(users[referer].isExist == false) 
            referer = passup;
        
        if(users[referer].levelStatus[_level] == true && users[referer].blocked ==false) {
            uint _share = (levelPrice[_level]).div(3);
            
            require((address(uint160(referer)).send(_share)), "Transaction Failure");
            users[referer].totalEarningTrx = users[referer].totalEarningTrx.add(_share);
            EarnedTrx[referer][1][_level] =  EarnedTrx[referer][1][_level].add(_share);
            emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, referer, users[referer].id, _level, _share, now);
            
            address sponsor = userList[users[msg.sender].referrerID];
            if(users[sponsor].levelStatus[_level] == true) {   
                require((address(uint160(sponsor)).send(_share)), "Transaction Failure");
                emit sponsorEarnedEvent(sponsor, users[sponsor].id, msg.sender, users[msg.sender].id, _level, _share, now);
            }
            else {
                require((address(uint160(passup)).send(_share)), "Transaction Failure");
                emit sponsorEarnedEvent(passup, users[passup].id, msg.sender, users[msg.sender].id, _level, _share, now);
            }
        }
        
        else {
            
            uint _share = (levelPrice[_level]).div(3);
             
            emit lostMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, referer, users[referer].id, _level, _share, now);
            _workPlanPay(1, _level, referer);
        }
    }
    
    function _autoPoolPay(uint8 _flag, uint8 _level, uint _userId) internal {
        
        uint refId;
        address refererAddress;
        
        if(_flag == 0)
          refId = autoPoolUsers[_level][_userId].referrerID;
        
        if(autoPoolUniqueUsers[autoPoolId[autoPoolUsers[_level][refId].userAddress]].levelStatus[_level] = true|| _flag == 1) {
            
            uint tobeminted = tokensForLevel[_level];
            uint _share = (levelPrice[_level]).div(3);
            
            if(_flag == 1 || autoPoolUniqueUsers[autoPoolId[autoPoolUserList[_level][refId]]].blocked == true)
                refererAddress = rebirth;
            else
                refererAddress = autoPoolUserList[_level][refId];
                
            require((address(uint160(refererAddress)).send(_share)) && (Token.distribute(msg.sender, tobeminted)), "Transaction Failure");
            autoPoolUniqueUsers[autoPoolId[refererAddress]].totalEarningTrx = autoPoolUniqueUsers[autoPoolId[refererAddress]].totalEarningTrx.add(_share);
            EarnedTrx[refererAddress][2][_level] =  EarnedTrx[refererAddress][2][_level].add(_share);
            emit getMoneyForLevelEvent(2, msg.sender, autoPoolId[msg.sender], refererAddress, autoPoolId[refererAddress], _level, _share, now);
        }
        else {
            
            uint _share = (levelPrice[_level]).div(3);
            refId = autoPoolUsers[_level][_userId].referrerID;
            refererAddress = autoPoolUserList[_level][refId];
            
            emit lostMoneyForLevelEvent(2, msg.sender, autoPoolId[msg.sender], refererAddress, autoPoolId[refererAddress], _level, _share, now);
            _autoPoolPay(1, _level, refId);
            
        }
        
    }
}