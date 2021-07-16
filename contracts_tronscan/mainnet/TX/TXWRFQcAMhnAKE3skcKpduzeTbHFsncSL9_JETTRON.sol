//SourceUnit: JETTRON.sol

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

contract JETTRON {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        mapping (uint8 => S1Struct) S1Matrix;
        mapping (uint8 => S2Struct) S2Matrix;
        mapping (uint8 => uint8) currentLevel;
    }
    
    struct S1Struct{
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] firstLineRef;
        uint[] secondLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
    
    struct S2Struct{
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] referrals;
        bool levelStatus;
        uint reInvestCount;
    }
    
    using SafeMath for uint256;
    address public ownerAddress; 
    uint public userCurrentId = 1;
    bool public lockStatus;
    
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint8 => uint)) public totalEarnedTrx;
    mapping (uint8 => mapping (uint8 => uint)) public levelPrice;
    mapping (uint8 => uint) public s2CurrentId;
    mapping (uint8 => uint) public s2DId;
    mapping (uint8 => mapping (uint => S2Struct)) public s2Internal;
    mapping (uint8 => mapping (uint => address)) public s2InternalUserList;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public earnedTrx;
    
    event regLevelEvent(uint8 indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(uint8 indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress,address indexed CallerAddress, uint8 Levelno, uint ReInvestCount, uint Time);
    
    constructor() public {
        ownerAddress = msg.sender;
        
        // s1levelPrice
        levelPrice[1][1] = 100 trx;
        levelPrice[1][2] = 200 trx;
        levelPrice[1][3] = 300 trx;
        levelPrice[1][4] = 400  trx;
        levelPrice[1][5] = 500 trx;
        levelPrice[1][6] = 1000 trx;
        levelPrice[1][7] = 1500 trx;
        levelPrice[1][8] = 2500 trx;
        levelPrice[1][9] = 3500 trx;
        levelPrice[1][10] = 4000 trx;
        levelPrice[1][11] = 5000 trx;
        levelPrice[1][12] = 7000 trx;
        levelPrice[1][13] = 9000 trx;
        levelPrice[1][14] = 10000 trx;
        
        // s2levelPrice
        levelPrice[2][1] = 100 trx;
        levelPrice[2][2] = 200 trx;
        levelPrice[2][3] = 300 trx;
        levelPrice[2][4] = 400  trx;
        levelPrice[2][5] = 500 trx;
        levelPrice[2][6] = 1000 trx;
        levelPrice[2][7] = 1500 trx;
        levelPrice[2][8] = 2500 trx;
        levelPrice[2][9] = 3500 trx;
        levelPrice[2][10] = 4000 trx;
        levelPrice[2][11] = 5000 trx;
        levelPrice[2][12] = 7000 trx;
        levelPrice[2][13] = 9000 trx;
        levelPrice[2][14] = 10000 trx;
            
        users[ownerAddress].isExist = true;
        users[ownerAddress].id = userCurrentId;
        users[ownerAddress].referrer = address(0);
        userList[userCurrentId] = ownerAddress;
        
        S1Struct memory s1UserDetails;
    
        s1UserDetails = S1Struct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            referrerID: 0,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        
        S2Struct memory s2UserDetails;
    
        s2UserDetails = S2Struct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            referrerID: 0,
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[ownerAddress].currentLevel[1] = 14;
        users[ownerAddress].currentLevel[2] = 14;
        
            
        for(uint8 i = 1; i <= 14; i++) {
            users[ownerAddress].S1Matrix[i] = s1UserDetails;
            users[ownerAddress].S2Matrix[i] = s2UserDetails;
            
            s2CurrentId[i] = s2CurrentId[i].add(1);
            s2InternalUserList[i][s2CurrentId[i]] = ownerAddress;
            s2Internal[i][s2CurrentId[i]] = s2UserDetails;
            s2DId[i] = 1;
        }
        
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function registration(uint _referrerID) external payable{
        require(lockStatus == false,"Contract Locked");
        require(users[msg.sender].isExist == false, "User Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == levelPrice[1][1].add(levelPrice[2][1]),"Incorrect Value");
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract");
        
        
        UserStruct memory userData;
        userCurrentId = userCurrentId.add(1);
        
        userData = UserStruct ({
            isExist: true,
            id: userCurrentId,
            referrer: userList[_referrerID],
            partnersCount: 0
        });
        
        users[msg.sender]= userData;
        userList[userCurrentId] = msg.sender;
        users[userList[_referrerID]].partnersCount = users[userList[_referrerID]].partnersCount.add(1);
        
        _s1Registration(_referrerID);
        _s2Registration();
    }
    
    function s1BuyLevel(uint8 _level) external payable {
        require(lockStatus == false,"Contract Locked");
        require(_level > 0 && _level <= 14, "Incorrect level");
        require(users[msg.sender].isExist ==  true, "User not exist");
        require(users[msg.sender].S1Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[1][_level], "Incorrect Value");
        
        if(_level != 1) {   
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].S1Matrix[l].levelStatus == true, "Buy the previous level");
        }
       
        uint firstLineId;
        uint secondLineId = _getS1Referrer(msg.sender,_level);
        
       if(users[userList[secondLineId]].S1Matrix[_level].firstLineRef.length < 3) {
            firstLineId = secondLineId;
            secondLineId = users[userList[firstLineId]].S1Matrix[_level].referrerID;
        }
        
        else if(users[userList[secondLineId]].S1Matrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findS1Referrer(_level,secondLineId);
        }
        
        S1Struct memory s1UserDetails;
        
        s1UserDetails = S1Struct({
            UserAddress: msg.sender,
            uniqueId: users[msg.sender].id,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].S1Matrix[_level] = s1UserDetails;
        users[msg.sender].currentLevel[1]  = _level;
        
        users[userList[firstLineId]].S1Matrix[_level].firstLineRef.push(users[msg.sender].id);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].S1Matrix[_level].secondLineRef.push(users[msg.sender].id);
        
        _updateS1Details(secondLineId,msg.sender,_level);
        
        emit buyLevelEvent(1,msg.sender,userList[firstLineId], _level, now);
    }
    
    function s2BuyLevel(uint8 _level) external payable {
        require(lockStatus == false,"Contract Locked");
        require(_level > 0 && _level <= 14, "Incorrect level");
        require(users[msg.sender].isExist ==  true, "User not exist");
        require(users[msg.sender].S2Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[2][_level], "Incorrect Value");
        
        if(_level != 1) {   
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].S2Matrix[l].levelStatus == true, "Buy the previous level");
        }
      
        uint userUniqueId = users[msg.sender].id;
        uint _referrerID;
        
        for(uint i = s2DId[_level]; i <= s2CurrentId[_level]; i++) {
            if(s2Internal[_level][i].referrals.length < 3) {
                _referrerID = i; 
                break;
            }
            else if(s2Internal[_level][i].referrals.length == 3) {
                s2DId[_level] = i;
                continue;
            }
        }
       
        s2CurrentId[_level] = s2CurrentId[_level].add(1);
        
        S2Struct memory s2UserDetails;
        
        s2UserDetails = S2Struct({
            UserAddress: msg.sender,
            uniqueId: userUniqueId,
            referrerID: _referrerID,
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });

        s2Internal[_level][s2CurrentId[_level]] = s2UserDetails;
        s2InternalUserList[_level][s2CurrentId[_level]] = msg.sender;
        
        users[msg.sender].S2Matrix[_level] = s2UserDetails;
        users[msg.sender].currentLevel[2]  = _level;
        
        if(_referrerID != 0) {
            s2Internal[_level][_referrerID].referrals.push(s2CurrentId[_level]);
            users[s2InternalUserList[_level][_referrerID]].S2Matrix[_level].referrals.push(userUniqueId);
        }
        
        _updateS2Details(_referrerID,s2CurrentId[_level],_level);
       
        emit buyLevelEvent(2,msg.sender,s2InternalUserList[_level][_referrerID], _level, now);
    }
    
    function contractLock(bool _lockStatus) external returns(bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        lockStatus = _lockStatus;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) external returns (bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function updateLevelPrice(uint8 _matrix, uint8 _level, uint _price) external returns(bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        levelPrice[_matrix][_level] = _price;
        return true;
    }
    
    function getTotalEarnedTrx(uint8 _matrix) public view returns(uint) {
         uint totalEth;
        
        for( uint i=1;i<=userCurrentId;i++) {
            totalEth = totalEth.add(totalEarnedTrx[userList[i]][_matrix]);
        }
        
        return totalEth;
    }
    
    function viewS1Referral(address userAddress, uint8 _level) public view returns(uint[] memory, uint[] memory) {
        return (users[userAddress].S1Matrix[_level].firstLineRef,users[userAddress].S1Matrix[_level].secondLineRef);
    }
    
    function viewS2Referral(address userAddress , uint8 _level) public view returns(uint[] memory) {
        return (users[userAddress].S2Matrix[_level].referrals);
    }
    
    function views2InternalReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
            return (s2Internal[_level][_userId].referrals);
    }
    
    function viewUserLevelStaus(uint8 _matrix, address _userAddress, uint8 _level) public view returns(bool) {
        if(_matrix == 1)        
            return (users[_userAddress].S1Matrix[_level].levelStatus);
        else if(_matrix == 2)        
            return (users[_userAddress].S2Matrix[_level].levelStatus);
    }
    
    function viewUserReInvestCount(uint8 _matrix, address _userAddress, uint8 _level) public view returns(uint) {
         if(_matrix == 1)        
            return (users[_userAddress].S1Matrix[_level].reInvestCount);
        else if(_matrix == 2)        
            return (users[_userAddress].S2Matrix[_level].reInvestCount);
    }
    
    function viewUserCurrentLevel(uint8 _matrix, address _userAddress) public view returns(uint8) {
            return (users[_userAddress].currentLevel[_matrix]);
    }
    
    function viewS1Details(address _userAddress, uint8 _level) public view returns(uint uniqueId, uint referrer, uint currentFirstUplineId, uint[] memory currentFirstLineRef, uint[] memory currentSecondLineRef, bool levelStatus, uint reInvestCount) {
        uniqueId = users[_userAddress].S1Matrix[_level].uniqueId;
        referrer = users[users[_userAddress].referrer].id;
        currentFirstUplineId = users[_userAddress].S1Matrix[_level].referrerID;
        currentFirstLineRef = users[_userAddress].S1Matrix[_level].firstLineRef;
        currentSecondLineRef =  users[_userAddress].S1Matrix[_level].secondLineRef;
        levelStatus = users[_userAddress].S1Matrix[_level].levelStatus;
        reInvestCount = users[_userAddress].S1Matrix[_level].reInvestCount;
    }
    
    function _s1Registration(uint _referrerID) internal  {
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[userList[_referrerID]].S1Matrix[1].firstLineRef.length < 3) {
            firstLineId = _referrerID;
            secondLineId = users[userList[firstLineId]].S1Matrix[1].referrerID;
        }
        
        else if(users[userList[_referrerID]].S1Matrix[1].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findS1Referrer(1,_referrerID);
        }
        
        
        S1Struct memory s1MatrixUserDetails;
        
        s1MatrixUserDetails = S1Struct({
            UserAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].S1Matrix[1] = s1MatrixUserDetails;
        users[msg.sender].currentLevel[1]  = 1;
      
        users[userList[firstLineId]].S1Matrix[1].firstLineRef.push(userCurrentId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].S1Matrix[1].secondLineRef.push(userCurrentId);
        
        _updateS1Details(secondLineId,msg.sender,1);
        emit regLevelEvent(1, msg.sender, userList[firstLineId], now);
    }
    
    function _s2Registration() internal  {
        uint userUniqueId = users[msg.sender].id;  
        
        uint _referrerID;
        
        for(uint i = s2DId[1]; i <= s2CurrentId[1]; i++) {
            if(s2Internal[1][i].referrals.length < 3) {
                _referrerID = i; 
                break;
            }
            else if(s2Internal[1][i].referrals.length == 3) {
                s2DId[1] = i;
                continue;
            }
        }
       
        s2CurrentId[1] = s2CurrentId[1].add(1);
        
        S2Struct memory s2UserDetails;
        
        s2UserDetails = S2Struct({
            UserAddress: msg.sender,
            uniqueId: userUniqueId,
            referrerID: _referrerID,
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });

        s2Internal[1][s2CurrentId[1]] = s2UserDetails;
        s2InternalUserList[1][s2CurrentId[1]] = msg.sender;
        
        users[msg.sender].S2Matrix[1] = s2UserDetails;
        users[msg.sender].currentLevel[2]  = 1;
        
        if(_referrerID != 0) {
            s2Internal[1][_referrerID].referrals.push(s2CurrentId[1]);
            users[s2InternalUserList[1][_referrerID]].S2Matrix[1].referrals.push(userUniqueId);
        }
        
        _updateS2Details(_referrerID,s2CurrentId[1],1);
        emit regLevelEvent(2, msg.sender, s2InternalUserList[1][_referrerID], now);
    }
    
    function _updateS1Details(uint secondLineId, address _userAddress, uint8 _level) internal {
        
        if(secondLineId == 0)
            secondLineId = 1;
        
        if(users[userList[secondLineId]].S1Matrix[_level].secondLineRef.length == 9) {
            
            if(userList[secondLineId] != ownerAddress) { // reinvest and place
                uint payId = _s1ReInvest(userList[secondLineId],_level);
                _payS1Trx(2, _level, _userAddress, payId, levelPrice[1][_level]);
            }
            else { 
                 _payS1Trx(2, _level, _userAddress, 1, levelPrice[1][_level]);
            }
                
            users[userList[secondLineId]].S1Matrix[_level].secondLineRef = new uint[](0);
            users[userList[secondLineId]].S1Matrix[_level].firstLineRef = new uint[](0);
            users[userList[secondLineId]].S1Matrix[_level].reInvestCount =  users[userList[secondLineId]].S1Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(1, userList[secondLineId], msg.sender, _level, users[userList[secondLineId]].S1Matrix[_level].reInvestCount, now); 
           
        }
        else if(users[userList[secondLineId]].S1Matrix[_level].secondLineRef.length < 9) {
            
            if(users[userList[secondLineId]].S1Matrix[_level].secondLineRef.length == 8)
                _payS1Trx(1,_level, _userAddress,0, levelPrice[1][_level]);
                
            else if(users[userList[secondLineId]].S1Matrix[_level].secondLineRef.length < 8)
                _payS1Trx(0, _level, _userAddress,0, levelPrice[1][_level]);
        }
        
    }
    
    function _updateS2Details(uint referrerID, uint _userId, uint8 _level) internal {
        
        if(s2Internal[_level][referrerID].referrals.length == 2) {
            _payS2Trx(_level,_userId,levelPrice[2][_level]);
            _s2ReInvest(referrerID,_level);
            
            users[s2InternalUserList[_level][referrerID]].S2Matrix[_level].referrals = new uint[](0);
            users[s2InternalUserList[_level][referrerID]].S2Matrix[_level].reInvestCount =  users[s2InternalUserList[_level][referrerID]].S2Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(2, s2InternalUserList[_level][referrerID], msg.sender, _level, users[s2InternalUserList[_level][referrerID]].S2Matrix[_level].reInvestCount, now);
            
        }
        else if(s2Internal[_level][referrerID].referrals.length == 1) 
            _payS2Trx(_level,_userId,levelPrice[2][_level]);
    }
    
    function _getS1Referrer(address _userAddress, uint8 _level) internal returns(uint) {
        while (true) {
            
            uint referrerID =  users[_userAddress].S1Matrix[1].referrerID;
            if (users[userList[referrerID]].S1Matrix[_level].levelStatus == true) {
                return referrerID;
            }
            
            _userAddress = userList[referrerID];
            emit lostMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,userList[referrerID],referrerID, _level, levelPrice[1][_level],now);
        }
        
    }
    
    function _s1ReInvest(address _reInvest,  uint8 _level) internal returns(uint){
        uint userUniqueId = users[_reInvest].id;
        address _referrer = users[_reInvest].referrer;
        uint shareId;
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[_referrer].S1Matrix[_level].firstLineRef.length < 3) {
            firstLineId = users[_referrer].id;
            secondLineId = users[userList[firstLineId]].S1Matrix[_level].referrerID;
            shareId = secondLineId;
        }
        
        else if(users[_referrer].S1Matrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findS1ReInvestReferrer(_level, users[_reInvest].id, users[_referrer].id);
            shareId = firstLineId;
        }
        
        users[_reInvest].S1Matrix[_level].UserAddress = _reInvest;
        users[_reInvest].S1Matrix[_level].uniqueId = userUniqueId;
        users[_reInvest].S1Matrix[_level].referrerID = firstLineId;
        users[_reInvest].S1Matrix[_level].levelStatus = true;
        
        users[userList[firstLineId]].S1Matrix[_level].firstLineRef.push(userUniqueId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].S1Matrix[_level].secondLineRef.push(userUniqueId);
        
         if(secondLineId == 0)
            secondLineId = 1;
        
        if(users[userList[secondLineId]].S1Matrix[_level].secondLineRef.length == 9) {
        
            if(userList[secondLineId] != ownerAddress)
                _s1ReInvest(userList[secondLineId],_level);
                
            users[userList[secondLineId]].S1Matrix[_level].secondLineRef = new uint[](0);
            users[userList[secondLineId]].S1Matrix[_level].firstLineRef = new uint[](0);
            users[userList[secondLineId]].S1Matrix[_level].reInvestCount =  users[userList[secondLineId]].S1Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(1, userList[secondLineId], msg.sender, _level, users[userList[secondLineId]].S1Matrix[_level].reInvestCount, now); 
            
        }
        
        if(shareId != 0)
            return shareId;
        else
            return 1;
        
    }
    
    function _s2ReInvest(uint _reInvestId,  uint8 _level) internal  returns(bool) {
        uint userUniqueId = users[s2InternalUserList[_level][_reInvestId]].id;
        uint _referrerID;
        
        for(uint i = s2DId[_level]; i <= s2CurrentId[_level]; i++) {
            if(s2Internal[_level][i].referrals.length < 3) {
                _referrerID = i; 
                break;
            }
            else if(s2Internal[_level][i].referrals.length == 3) {
                s2DId[_level] = i;
                continue;
            }
        }
        
        s2CurrentId[_level] = s2CurrentId[_level].add(1);
        
        S2Struct memory s2UserDetails;
        
        s2UserDetails = S2Struct({
            UserAddress: s2InternalUserList[_level][_reInvestId],
            uniqueId: userUniqueId,
            referrerID: _referrerID,
            referrals: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });

        s2Internal[_level][s2CurrentId[_level]] = s2UserDetails;
        s2InternalUserList[_level][s2CurrentId[_level]] = s2InternalUserList[_level][_reInvestId];
        
        users[s2InternalUserList[_level][_reInvestId]].S2Matrix[_level].UserAddress = s2InternalUserList[_level][_reInvestId];
        users[s2InternalUserList[_level][_reInvestId]].S2Matrix[_level].uniqueId = userUniqueId;
        users[s2InternalUserList[_level][_reInvestId]].S2Matrix[_level].referrerID = _referrerID;
        users[s2InternalUserList[_level][_reInvestId]].S2Matrix[_level].levelStatus = true;
        
        users[s2InternalUserList[_level][_reInvestId]].currentLevel[2]  = _level;
        
        if(_referrerID != 0) {
            s2Internal[_level][_referrerID].referrals.push(s2CurrentId[_level]);
            users[s2InternalUserList[_level][_referrerID]].S2Matrix[_level].referrals.push(userUniqueId);
        }
        
         if(s2Internal[_level][_referrerID].referrals.length == 2) {
            _s2ReInvest(_referrerID,_level);
            users[s2InternalUserList[_level][_referrerID]].S2Matrix[_level].referrals = new uint[](0);
            users[s2InternalUserList[_level][_referrerID]].S2Matrix[_level].reInvestCount =  users[s2InternalUserList[_level][_referrerID]].S2Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(2, s2InternalUserList[_level][_referrerID], msg.sender, _level, users[s2InternalUserList[_level][_referrerID]].S2Matrix[_level].reInvestCount, now);
        }
       
        return true;
    }
    
    function _payS1Trx(uint8 _flag, uint8 _level, address _userAddress, uint _paymentId, uint256 _amt) internal {
        
        uint[3] memory referer;
        
        referer[0] = users[_userAddress].S1Matrix[_level].referrerID;
        referer[1] = users[userList[referer[0]]].S1Matrix[_level].referrerID;
        referer[2] = users[userList[referer[1]]].S1Matrix[_level].referrerID;
          
        
        if(_flag == 0) {
         
            if(users[userList[referer[1]]].S1Matrix[_level].levelStatus == false) 
                referer[1] = 1;
            
            require((address(uint160(userList[referer[1]])).send(_amt.div(2))) , "Transaction Failure");
            
            totalEarnedTrx[userList[referer[1]]][1] = totalEarnedTrx[userList[referer[1]]][1].add(_amt.div(2));
            earnedTrx[userList[referer[1]]][1][_level] =  earnedTrx[userList[referer[1]]][1][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referer[1]],referer[1],_level,_amt.div(2),now);
        
        }
        
        else if(_flag == 1)   {
            
            if(users[userList[referer[2]]].S1Matrix[_level].levelStatus == false) 
                referer[2] = 1;
            
            require((address(uint160(userList[referer[2]])).send(_amt.div(2))), "Transaction Failure");
            
            totalEarnedTrx[userList[referer[2]]][1] = totalEarnedTrx[userList[referer[2]]][1].add(_amt.div(2));
            earnedTrx[userList[referer[2]]][1][_level] =  earnedTrx[userList[referer[2]]][1][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referer[2]],referer[2],_level,_amt.div(2),now);
           
        }
        
        else if(_flag == 2)   {
           
            if(users[userList[_paymentId]].S1Matrix[_level].levelStatus == false) 
                _paymentId = 1;
            
            require((address(uint160(userList[_paymentId])).send(_amt.div(2))) , "Transaction Failure");
            
            totalEarnedTrx[userList[_paymentId]][1] = totalEarnedTrx[userList[_paymentId]][1].add(_amt.div(2));
            earnedTrx[userList[_paymentId]][1][_level] =  earnedTrx[userList[_paymentId]][1][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[_paymentId],_paymentId,_level,_amt.div(2),now);
           
        }
        
        if(users[userList[referer[0]]].S1Matrix[_level].levelStatus == false) 
            referer[0] = 1;
            
        require( address(uint160(userList[referer[0]])).send(_amt.div(2)) , "Transaction Failure");
        
        totalEarnedTrx[userList[referer[0]]][1] = totalEarnedTrx[userList[referer[0]]][1].add(_amt.div(2));
        earnedTrx[userList[referer[0]]][1][_level] =  earnedTrx[userList[referer[0]]][1][_level].add(_amt.div(2));
        emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referer[0]],referer[0],_level,_amt.div(2),now);
        
    }
    
    function _payS2Trx(uint8 _level, uint _userId, uint256 _amt) internal {
        
        uint  referer;
        
        referer = s2Internal[_level][_userId].referrerID;
    
        if(s2Internal[_level][referer].levelStatus == false) 
            referer = 1;
        
        require((address(uint160(s2InternalUserList[_level][referer])).send(_amt)) , "Transaction Failure");
        
        totalEarnedTrx[s2InternalUserList[_level][referer]][2] = totalEarnedTrx[s2InternalUserList[_level][referer]][2].add(_amt);
        earnedTrx[s2InternalUserList[_level][referer]][2][_level] =  earnedTrx[s2InternalUserList[_level][referer]][2][_level].add(_amt);
        emit getMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,s2InternalUserList[_level][referer],s2Internal[_level][referer].uniqueId,_level,_amt,now);
        
    }
    
    function _findS1Referrer(uint8 _level,  uint _refId) internal returns(uint,uint) {
        
        if(users[userList[_refId]].S1Matrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].S1Matrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].S1Matrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].S1Matrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].S1Matrix[_level].firstLineRef[2];
            
            
            for (uint8 k=0; k<3; k++) {
                if(users[userList[_refId]].S1Matrix[_level].secondLineRef.length == 0+k ||
                users[userList[_refId]].S1Matrix[_level].secondLineRef.length == 3+k ||
                users[userList[_refId]].S1Matrix[_level].secondLineRef.length == 6+k) {
                    if(users[userList[referrals[k]]].S1Matrix[_level].firstLineRef.length < 3) {
                        return (_refId, referrals[k]);
                    }
                }
            }
            
            for(uint8 r=0; r<3; r++) {
                    if(users[userList[referrals[r]]].S1Matrix[_level].firstLineRef.length < 3) 
                         return (_refId, referrals[r]);
            }
            
        }
        
    }
    
    function _findS1ReInvestReferrer(uint8 _level,uint _reInvestId, uint _refId) internal returns(uint,uint) {
        
        if(users[userList[_refId]].S1Matrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].S1Matrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].S1Matrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].S1Matrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].S1Matrix[_level].firstLineRef[2];
            
            
            for (uint8 k=0; k<3; k++) {
                if(users[userList[_refId]].S1Matrix[_level].secondLineRef.length == 0+k ||
                users[userList[_refId]].S1Matrix[_level].secondLineRef.length == 3+k ||
                users[userList[_refId]].S1Matrix[_level].secondLineRef.length == 6+k) {
                    if(users[userList[referrals[k]]].S1Matrix[_level].firstLineRef.length < 3) {
                        if(referrals[k] != _reInvestId)
                            return (_refId, referrals[k]);
                    }
                }
            }
            
            for(uint8 r=0; r<3; r++) {
                if(users[userList[referrals[r]]].S1Matrix[_level].firstLineRef.length < 3) {
                    if(referrals[r] != _reInvestId)
                        return (_refId, referrals[r]);
                }
                
                if(users[userList[referrals[r]]].S1Matrix[_level].firstLineRef.length < 3) {
                        return (_refId, referrals[r]);
                }
            }
            
        }
        
    }
}