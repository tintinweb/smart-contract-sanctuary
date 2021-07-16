//SourceUnit: Ultroniq.sol

pragma solidity 0.5.14;

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

contract Ultroniq {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        mapping (uint8 => X4Struct) X4Matrix;
        mapping (uint8 => X3Struct) X3Matrix;
        mapping (uint8 => uint8) currentLevel;
    }
    
    struct X4Struct{
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] firstLineRef;
        uint[] secondLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
    
    struct X3Struct{
        address UserAddress;
        uint uniqueId;
        uint currentReferrerId;
        uint[] referralsList;
        uint currentLineRefferal;
        bool levelStatus;
        uint reInvestCount;
    }
    
    using SafeMath for uint256;
    address public ownerAddress; 
    uint public userCurrentId = 1;
    uint8 public constant LAST_LEVEL = 12;
    bool public lockStatus;
    
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint8 => uint) public levelPrice;
    mapping (uint8 => uint) public X3CurrentId;
    mapping (uint8 => uint) public X3DId;
    mapping (uint8 => mapping (uint => X3Struct)) public X3Internal;
    mapping (uint8 => mapping (uint => address)) public X3InternalUserList;
    mapping (address => mapping (uint8 => uint)) public totalEarnedTrx;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public earnedTrx;
    
    event regLevelEvent(uint8 indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(uint8 indexed Matrix, address indexed UserAddress, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress,address indexed CallerAddress, uint8 Levelno, uint ReInvestCount, uint Time);
    
    constructor() public {
        ownerAddress = msg.sender;
        
        // levelPrice
        levelPrice[1] = 100 trx;
        levelPrice[2] = 200 trx;
        levelPrice[3] = 400 trx;
        levelPrice[4] = 800  trx;
        levelPrice[5] = 1600 trx;
        levelPrice[6] = 3200 trx;
        levelPrice[7] = 6400 trx;
        levelPrice[8] = 19200 trx;
        levelPrice[9] = 57600 trx;
        levelPrice[10] = 172800 trx;
        levelPrice[11] = 518400 trx;
        levelPrice[12] = 155520 trx;
            
        users[ownerAddress].isExist = true;
        users[ownerAddress].id = userCurrentId;
        users[ownerAddress].referrer = address(0);
        userList[userCurrentId] = ownerAddress;
        
        X4Struct memory X4UserDetails;
    
        X4UserDetails = X4Struct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            referrerID: 0,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        
        X3Struct memory X3UserDetails;
    
        X3UserDetails = X3Struct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            currentReferrerId: 0,
            referralsList: new uint[](0),
            currentLineRefferal: 0,
            levelStatus: true,
            reInvestCount:0
        });
        
        users[ownerAddress].currentLevel[1] = LAST_LEVEL;
        users[ownerAddress].currentLevel[2] = LAST_LEVEL;
            
        for(uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].X4Matrix[i] = X4UserDetails;
            users[ownerAddress].X3Matrix[i] = X3UserDetails;
            
            X3CurrentId[i] = X3CurrentId[i].add(1);
            X3InternalUserList[i][X3CurrentId[i]] = ownerAddress;
            X3Internal[i][X3CurrentId[i]] = X3UserDetails;
            X3DId[i] = 1;
        }
        
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function registration(uint _referrerID) external payable{
        require(lockStatus == false,"Contract Locked");
        require(users[msg.sender].isExist == false, "User Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == levelPrice[1].mul(2),"Incorrect Value");
        
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
        
        _X4Registration(_referrerID);
        _X3Registration();
    }
    
    function X4BuyLevel(uint8 _level) external payable {
        require(lockStatus == false,"Contract Locked");
        require(_level > 0 && _level <= LAST_LEVEL, "Incorrect level");
        require(users[msg.sender].isExist ==  true, "User not exist");
        require(users[msg.sender].X4Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[_level], "Incorrect Value");
        
        if(_level != 1) {   
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].X4Matrix[l].levelStatus == true, "Buy the previous level");
        }
       
        uint firstLineId;
        uint secondLineId = _getX4Referrer(msg.sender,_level);
        
       if(users[userList[secondLineId]].X4Matrix[_level].firstLineRef.length < 3) {
            firstLineId = secondLineId;
            secondLineId = users[userList[firstLineId]].X4Matrix[_level].referrerID;
        }
        
        else if(users[userList[secondLineId]].X4Matrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findX4Referrer(_level,secondLineId);
        }
        
        X4Struct memory X4UserDetails;
        
        X4UserDetails = X4Struct({
            UserAddress: msg.sender,
            uniqueId: users[msg.sender].id,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].X4Matrix[_level] = X4UserDetails;
        users[msg.sender].currentLevel[1]  = _level;
        
        users[userList[firstLineId]].X4Matrix[_level].firstLineRef.push(users[msg.sender].id);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].X4Matrix[_level].secondLineRef.push(users[msg.sender].id);
        
        _updateX4Details(secondLineId,msg.sender,_level);
        
        emit buyLevelEvent(1,msg.sender, _level, now);
    }
    
    function X3BuyLevel(uint8 _level) external payable {
        require(lockStatus == false,"Contract Locked");
        require(_level > 0 && _level <= LAST_LEVEL, "Incorrect level");
        require(users[msg.sender].isExist ==  true, "User not exist");
        require(users[msg.sender].X3Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[_level], "Incorrect Value");
        
        if(_level != 1) {   
            for(uint8 l =_level - 1; l > 0; l--) 
                require(users[msg.sender].X3Matrix[l].levelStatus == true, "Buy the previous level");
        }
      
        uint userUniqueId = users[msg.sender].id;
        uint _referrerID;
        
        for(uint i = X3DId[_level]; i <= X3CurrentId[_level]; i++) {
            if(X3Internal[_level][i].referralsList.length < 5) {
                _referrerID = i; 
                break;
            }
            else if(X3Internal[_level][i].referralsList.length == 5) {
                X3DId[_level] = i;
                continue;
            }
        }
       
        X3CurrentId[_level] = X3CurrentId[_level].add(1);
        
        X3Struct memory X3UserDetails;
        
        X3UserDetails = X3Struct({
            UserAddress: msg.sender,
            uniqueId: userUniqueId,
            currentReferrerId: _referrerID,
            referralsList: new uint[](0),
            currentLineRefferal: 0,
            levelStatus: true,
            reInvestCount:0
        });

        X3Internal[_level][X3CurrentId[_level]] = X3UserDetails;
        X3InternalUserList[_level][X3CurrentId[_level]] = msg.sender;
        
        users[msg.sender].X3Matrix[_level] = X3UserDetails;
        users[msg.sender].currentLevel[2]  = _level;
         
        X3Internal[_level][X3CurrentId[_level].sub(1)].currentLineRefferal =  X3CurrentId[_level]; 
        users[X3InternalUserList[_level][X3CurrentId[_level].sub(1)]].X3Matrix[_level].currentLineRefferal = userUniqueId;
        
        if(_referrerID != 0) {
            X3Internal[_level][_referrerID].referralsList.push(X3CurrentId[_level]);
            users[X3InternalUserList[_level][_referrerID]].X3Matrix[_level].referralsList.push(userUniqueId);
        }
        
        _updateX3Details(_referrerID,X3CurrentId[_level],_level);
       
        emit buyLevelEvent(2,msg.sender, _level, now);
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
    
    function updateLevelPrice(uint8 _level, uint _price) external returns(bool) {
        require(msg.sender == ownerAddress, "Only Owner");
        levelPrice[_level] = _price;
        return true;
    }
    
    function getTotalEarnedTrx(uint8 _matrix) public view returns(uint) {
         uint totalTrx;
        
        for( uint i=1;i<=userCurrentId;i++) {
            totalTrx = totalTrx.add(totalEarnedTrx[userList[i]][_matrix]);
        }
        
        return totalTrx;
    }
    
    function viewX4Referral(address userAddress, uint8 _level) public view returns(uint[] memory, uint[] memory) {
        return (users[userAddress].X4Matrix[_level].firstLineRef,users[userAddress].X4Matrix[_level].secondLineRef);
    }
    
    function viewX3Referral(address userAddress , uint8 _level) public view returns(uint[] memory) {
        return (users[userAddress].X3Matrix[_level].referralsList);
    }
    
    function viewX3InternalReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
            return (X3Internal[_level][_userId].referralsList);
    }
    
    function viewUserLevelStaus(uint8 _matrix, address _userAddress, uint8 _level) public view returns(bool) {
        if(_matrix == 1)        
            return (users[_userAddress].X4Matrix[_level].levelStatus);
        else if(_matrix == 2)        
            return (users[_userAddress].X3Matrix[_level].levelStatus);
    }
    
    function viewUserReInvestCount(uint8 _matrix, address _userAddress, uint8 _level) public view returns(uint) {
         if(_matrix == 1)        
            return (users[_userAddress].X4Matrix[_level].reInvestCount);
        else if(_matrix == 2)        
            return (users[_userAddress].X3Matrix[_level].reInvestCount);
    }
    
    function viewUserCurrentLevel(uint8 _matrix, address _userAddress) public view returns(uint8) {
            return (users[_userAddress].currentLevel[_matrix]);
    }
    
    function viewX3UserDetails(address _userAddress, uint8 _level) public view returns(uint uniqueId, uint currentReferrerId, uint[] memory referralsList, uint currentLineRefferal, bool levelStatus, uint reInvestCount) {
        uniqueId = users[_userAddress].X3Matrix[_level].uniqueId;
        currentReferrerId = users[_userAddress].X3Matrix[_level].currentReferrerId;
        referralsList = users[_userAddress].X3Matrix[_level].referralsList;
        currentLineRefferal = users[_userAddress].X3Matrix[_level].currentLineRefferal;
        levelStatus = users[_userAddress].X3Matrix[_level].levelStatus;
        reInvestCount = users[_userAddress].X3Matrix[_level].reInvestCount;
    }
    
    function viewX4UserDetails(address _userAddress, uint8 _level) public view returns(uint uniqueId, uint currentReferrerId, uint[] memory firstLineReferrals, uint[] memory secondLineReferrals,bool levelStatus, uint reInvestCount) {
        uniqueId = users[_userAddress].X4Matrix[_level].uniqueId;
        currentReferrerId = users[_userAddress].X4Matrix[_level].referrerID;
        firstLineReferrals = users[_userAddress].X4Matrix[_level].firstLineRef;
        secondLineReferrals = users[_userAddress].X4Matrix[_level].secondLineRef;
        levelStatus = users[_userAddress].X4Matrix[_level].levelStatus;
        reInvestCount = users[_userAddress].X4Matrix[_level].reInvestCount;
    }
    
    function _X4Registration(uint _referrerID) internal  {
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[userList[_referrerID]].X4Matrix[1].firstLineRef.length < 3) {
            firstLineId = _referrerID;
            secondLineId = users[userList[firstLineId]].X4Matrix[1].referrerID;
        }
        
        else if(users[userList[_referrerID]].X4Matrix[1].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findX4Referrer(1,_referrerID);
        }
        
        
        X4Struct memory X4MatrixUserDetails;
        
        X4MatrixUserDetails = X4Struct({
            UserAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].X4Matrix[1] = X4MatrixUserDetails;
        users[msg.sender].currentLevel[1]  = 1;
      
        users[userList[firstLineId]].X4Matrix[1].firstLineRef.push(userCurrentId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].X4Matrix[1].secondLineRef.push(userCurrentId);
        
        _updateX4Details(secondLineId,msg.sender,1);
        emit regLevelEvent(1, msg.sender, userList[firstLineId], now);
    }
    
    function _X3Registration() internal  {
        uint userUniqueId = users[msg.sender].id;  
        
        uint _referrerID;
        
        for(uint i = X3DId[1]; i <= X3CurrentId[1]; i++) {
            if(X3Internal[1][i].referralsList.length < 5) {
                _referrerID = i; 
                break;
            }
            else if(X3Internal[1][i].referralsList.length == 5) {
                X3DId[1] = i;
                continue;
            }
        }
       
        X3CurrentId[1] = X3CurrentId[1].add(1);
        
        X3Struct memory X3UserDetails;
        
        X3UserDetails = X3Struct({
            UserAddress: msg.sender,
            uniqueId: userUniqueId,
            currentReferrerId: _referrerID,
            referralsList: new uint[](0),
            currentLineRefferal: 0,
            levelStatus: true,
            reInvestCount:0
        });

        X3Internal[1][X3CurrentId[1]] = X3UserDetails;
        X3InternalUserList[1][X3CurrentId[1]] = msg.sender;
        
        users[msg.sender].X3Matrix[1] = X3UserDetails;
        users[msg.sender].currentLevel[2]  = 1;
        
        X3Internal[1][X3CurrentId[1].sub(1)].currentLineRefferal =  X3CurrentId[1]; 
        users[X3InternalUserList[1][X3CurrentId[1].sub(1)]].X3Matrix[1].currentLineRefferal = userUniqueId;
        
        if(_referrerID != 0) {
            X3Internal[1][_referrerID].referralsList.push(X3CurrentId[1]);
            users[X3InternalUserList[1][_referrerID]].X3Matrix[1].referralsList.push(userUniqueId);
        }
        
        _updateX3Details(_referrerID,X3CurrentId[1],1);
        emit regLevelEvent(2, msg.sender, X3InternalUserList[1][_referrerID], now);
    }
    
    function _updateX4Details(uint secondLineId, address _userAddress, uint8 _level) internal {
        
        if(secondLineId == 0)
            secondLineId = 1;
        
        if(users[userList[secondLineId]].X4Matrix[_level].secondLineRef.length == 9) {
            
            if(userList[secondLineId] != ownerAddress) { // reinvest and place
                uint payId = _X4ReInvest(userList[secondLineId],_level);
                _payX4Trx(2, _level, _userAddress, payId, levelPrice[_level]);
            }
            else { 
                 _payX4Trx(2, _level, _userAddress, 1, levelPrice[_level]);
            }
                
            users[userList[secondLineId]].X4Matrix[_level].secondLineRef = new uint[](0);
            users[userList[secondLineId]].X4Matrix[_level].firstLineRef = new uint[](0);
            users[userList[secondLineId]].X4Matrix[_level].reInvestCount =  users[userList[secondLineId]].X4Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(1, userList[secondLineId], msg.sender, _level, users[userList[secondLineId]].X4Matrix[_level].reInvestCount, now); 
           
        }
        else if(users[userList[secondLineId]].X4Matrix[_level].secondLineRef.length < 9) {
            
            if(users[userList[secondLineId]].X4Matrix[_level].secondLineRef.length == 8)
                _payX4Trx(1,_level, _userAddress, 0, levelPrice[_level]);
                
            else if(users[userList[secondLineId]].X4Matrix[_level].secondLineRef.length < 8)
                _payX4Trx(0, _level, _userAddress, 0, levelPrice[_level]);
        }
        
    }
    
    function _updateX3Details(uint referrerID, uint _userId, uint8 _level) internal {
        
        if(X3Internal[_level][referrerID].referralsList.length == 5) {
            _payX3Trx(_level,_userId,levelPrice[_level]);
            _X3ReInvest(referrerID,_level);
            
            users[X3InternalUserList[_level][referrerID]].X3Matrix[_level].referralsList = new uint[](0);
            users[X3InternalUserList[_level][referrerID]].X3Matrix[_level].reInvestCount =  users[X3InternalUserList[_level][referrerID]].X3Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(2, X3InternalUserList[_level][referrerID], msg.sender, _level, users[X3InternalUserList[_level][referrerID]].X3Matrix[_level].reInvestCount, now);
            
        }
        else if(X3Internal[_level][referrerID].referralsList.length <= 4) 
            _payX3Trx(_level,_userId,levelPrice[_level]);
    }
    
    function _getX4Referrer(address _userAddress, uint8 _level) internal returns(uint) {
        while (true) {
            
            uint referrerID =  users[_userAddress].X4Matrix[1].referrerID;
            if (users[userList[referrerID]].X4Matrix[_level].levelStatus == true) {
                return referrerID;
            }
            
            _userAddress = userList[referrerID];
            emit lostMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,userList[referrerID],referrerID, _level, levelPrice[_level],now);
        }
        
    }
    
    function _X4ReInvest(address _reInvest,  uint8 _level) internal returns(uint){
        uint userUniqueId = users[_reInvest].id;
        address _referrer = users[_reInvest].referrer;
        uint shareId;
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[_referrer].X4Matrix[_level].firstLineRef.length < 3) {
            firstLineId = users[_referrer].id;
            secondLineId = users[userList[firstLineId]].X4Matrix[_level].referrerID;
            shareId = secondLineId;
        }
        
        else if(users[_referrer].X4Matrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findX4ReInvestReferrer(_level, users[_reInvest].id, users[_referrer].id);
            shareId = firstLineId;
        }
        
        users[_reInvest].X4Matrix[_level].UserAddress = _reInvest;
        users[_reInvest].X4Matrix[_level].uniqueId = userUniqueId;
        users[_reInvest].X4Matrix[_level].referrerID = firstLineId;
        users[_reInvest].X4Matrix[_level].levelStatus = true;
        
        users[userList[firstLineId]].X4Matrix[_level].firstLineRef.push(userUniqueId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].X4Matrix[_level].secondLineRef.push(userUniqueId);
        
         if(secondLineId == 0)
            secondLineId = 1;
        
        if(users[userList[secondLineId]].X4Matrix[_level].secondLineRef.length == 9) {
        
            if(userList[secondLineId] != ownerAddress)
                _X4ReInvest(userList[secondLineId],_level);
                
            users[userList[secondLineId]].X4Matrix[_level].secondLineRef = new uint[](0);
            users[userList[secondLineId]].X4Matrix[_level].firstLineRef = new uint[](0);
            users[userList[secondLineId]].X4Matrix[_level].reInvestCount =  users[userList[secondLineId]].X4Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(1, userList[secondLineId], msg.sender, _level, users[userList[secondLineId]].X4Matrix[_level].reInvestCount, now); 
            
        }
        
        if(shareId != 0)
            return shareId;
        else
            return 1;
        
    }
    
    function _X3ReInvest(uint _reInvestId,  uint8 _level) internal  returns(bool) {
        uint userUniqueId = users[X3InternalUserList[_level][_reInvestId]].id;
        uint _referrerID;
        
        for(uint i = X3DId[_level]; i <= X3CurrentId[_level]; i++) {
            if(X3Internal[_level][i].referralsList.length < 5) {
                _referrerID = i; 
                break;
            }
            else if(X3Internal[_level][i].referralsList.length == 5) {
                X3DId[_level] = i;
                continue;
            }
        }
        
        X3CurrentId[_level] = X3CurrentId[_level].add(1);
        
        X3Struct memory X3UserDetails;
        
        X3UserDetails = X3Struct({
            UserAddress: X3InternalUserList[_level][_reInvestId],
            uniqueId: userUniqueId,
            currentReferrerId: _referrerID,
            referralsList: new uint[](0),
            currentLineRefferal: 0,
            levelStatus: true,
            reInvestCount:0
        });

        X3Internal[_level][X3CurrentId[_level]] = X3UserDetails;
        X3InternalUserList[_level][X3CurrentId[_level]] = X3InternalUserList[_level][_reInvestId];
        
        users[X3InternalUserList[_level][_reInvestId]].X3Matrix[_level].UserAddress = X3InternalUserList[_level][_reInvestId];
        users[X3InternalUserList[_level][_reInvestId]].X3Matrix[_level].uniqueId = userUniqueId;
        users[X3InternalUserList[_level][_reInvestId]].X3Matrix[_level].currentReferrerId = _referrerID;
        users[X3InternalUserList[_level][_reInvestId]].X3Matrix[_level].levelStatus = true;
        
        users[X3InternalUserList[_level][_reInvestId]].currentLevel[2]  = _level;
        
        X3Internal[_level][X3CurrentId[_level].sub(1)].currentLineRefferal =  X3CurrentId[_level]; 
        users[X3InternalUserList[_level][X3CurrentId[_level].sub(1)]].X3Matrix[_level].currentLineRefferal = userUniqueId;
        
        if(_referrerID != 0) {
            X3Internal[_level][_referrerID].referralsList.push(X3CurrentId[_level]);
            users[X3InternalUserList[_level][_referrerID]].X3Matrix[_level].referralsList.push(userUniqueId);
        }
        
        if(X3Internal[_level][_referrerID].referralsList.length == 5) {
            _X3ReInvest(_referrerID,_level);
            users[X3InternalUserList[_level][_referrerID]].X3Matrix[_level].referralsList = new uint[](0);
            users[X3InternalUserList[_level][_referrerID]].X3Matrix[_level].reInvestCount =  users[X3InternalUserList[_level][_referrerID]].X3Matrix[_level].reInvestCount.add(1);
            emit reInvestEvent(2, X3InternalUserList[_level][_referrerID], msg.sender, _level, users[X3InternalUserList[_level][_referrerID]].X3Matrix[_level].reInvestCount, now);
        }
       
        return true;
    }
    
    function _payX4Trx(uint8 _flag, uint8 _level, address _userAddress, uint _paymentId, uint256 _amt) internal {
        
        uint[3] memory referer;
        
        referer[0] = users[_userAddress].X4Matrix[_level].referrerID;
        referer[1] = users[userList[referer[0]]].X4Matrix[_level].referrerID;
        referer[2] = users[userList[referer[1]]].X4Matrix[_level].referrerID;
          
        
        if(_flag == 0) {
         
            if(users[userList[referer[1]]].X4Matrix[_level].levelStatus == false) 
                referer[1] = 1;
            
            require((address(uint160(userList[referer[1]])).send(_amt.div(2))) , "Transaction Failure");
            
            totalEarnedTrx[userList[referer[1]]][1] = totalEarnedTrx[userList[referer[1]]][1].add(_amt.div(2));
            earnedTrx[userList[referer[1]]][1][_level] =  earnedTrx[userList[referer[1]]][1][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referer[1]],referer[1],_level,_amt.div(2),now);
        
        }
        
        else if(_flag == 1)   {
            
            if(users[userList[referer[2]]].X4Matrix[_level].levelStatus == false) 
                referer[2] = 1;
            
            require((address(uint160(userList[referer[2]])).send(_amt.div(2))), "Transaction Failure");
            
            totalEarnedTrx[userList[referer[2]]][1] = totalEarnedTrx[userList[referer[2]]][1].add(_amt.div(2));
            earnedTrx[userList[referer[2]]][1][_level] =  earnedTrx[userList[referer[2]]][1][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referer[2]],referer[2],_level,_amt.div(2),now);
           
        }
        
        else if(_flag == 2)   {
           
            if(users[userList[_paymentId]].X4Matrix[_level].levelStatus == false) 
                _paymentId = 1;
            
            require((address(uint160(userList[_paymentId])).send(_amt.div(2))) , "Transaction Failure");
            
            totalEarnedTrx[userList[_paymentId]][1] = totalEarnedTrx[userList[_paymentId]][1].add(_amt.div(2));
            earnedTrx[userList[_paymentId]][1][_level] =  earnedTrx[userList[_paymentId]][1][_level].add(_amt.div(2));
            emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[_paymentId],_paymentId,_level,_amt.div(2),now);
           
        }
        
        if(users[userList[referer[0]]].X4Matrix[_level].levelStatus == false) 
            referer[0] = 1;
            
        require(address(uint160(userList[referer[0]])).send(_amt.div(2)) , "Transaction Failure");
        
        totalEarnedTrx[userList[referer[0]]][1] = totalEarnedTrx[userList[referer[0]]][1].add(_amt.div(2));
        earnedTrx[userList[referer[0]]][1][_level] =  earnedTrx[userList[referer[0]]][1][_level].add(_amt.div(2));
        emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,userList[referer[0]],referer[0],_level,_amt.div(2),now);
        
    }
    
    function _payX3Trx(uint8 _level, uint _userId, uint256 _amt) internal {
        
        uint  referer;
        
        referer = X3Internal[_level][_userId].currentReferrerId;
    
        if(X3Internal[_level][referer].levelStatus == false) 
            referer = 1;
        
        require((address(uint160(X3InternalUserList[_level][referer])).send(_amt)) , "Transaction Failure");
        
        totalEarnedTrx[X3InternalUserList[_level][referer]][2] = totalEarnedTrx[X3InternalUserList[_level][referer]][2].add(_amt);
        earnedTrx[X3InternalUserList[_level][referer]][2][_level] =  earnedTrx[X3InternalUserList[_level][referer]][2][_level].add(_amt);
        emit getMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,X3InternalUserList[_level][referer],X3Internal[_level][referer].uniqueId,_level,_amt,now);
        
    }
    
    function _findX4Referrer(uint8 _level, uint _refId) internal view returns(uint,uint) {
        
        if(users[userList[_refId]].X4Matrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].X4Matrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].X4Matrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].X4Matrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].X4Matrix[_level].firstLineRef[2];
            
            for(uint8 r=0; r<3; r++) {
                if(users[userList[referrals[r]]].X4Matrix[_level].firstLineRef.length < 3) 
                     return (_refId, referrals[r]);
            }
            
        }
        
    }
    
    function _findX4ReInvestReferrer(uint8 _level,uint _reInvestId, uint _refId) internal view returns(uint,uint) {
        
        if(users[userList[_refId]].X4Matrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].X4Matrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].X4Matrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].X4Matrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].X4Matrix[_level].firstLineRef[2];
            
            for(uint8 r=0; r<3; r++) {
                if(users[userList[referrals[r]]].X4Matrix[_level].firstLineRef.length < 3) {
                    if(referrals[r] != _reInvestId)
                        return (_refId, referrals[r]);
                }
                
                if(users[userList[referrals[r]]].X4Matrix[_level].firstLineRef.length < 3) {
                        return (_refId, referrals[r]);
                }
            }
            
        }
        
    }
}