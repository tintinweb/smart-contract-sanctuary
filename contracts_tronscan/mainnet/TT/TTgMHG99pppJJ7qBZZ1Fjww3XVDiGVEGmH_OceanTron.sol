//SourceUnit: OceanTron.sol

pragma solidity 0.5.10;

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

contract OceanTron {
    
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint8 currentLevel;
        address[] referral;
        mapping(uint8 => bool) levelStatus;
    }
    
    using SafeMath for uint256;
    bool public lockStatus;
    address public ownerAddress;
    address public commissionAddress;
    uint8 public constant REFLIMIT  = 10;
    uint8 public constant LASTLEVEL  = 24;
    uint public userCurrentId = 1;
    uint public adminPercentage = 10 trx;
   
    mapping (uint8 => uint) public levelPrice;
    mapping (uint8 => uint) public uplinePercentage;
    mapping (uint => address) public userList;
    mapping (address => uint) public totalEarnedtrx;
    mapping (address => UserStruct) public users;
    mapping (address => uint8) public loopCheck;
    mapping (address => mapping (uint8 => uint)) public earnedtrx;
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    
    constructor(address _commissionAddress) public {
        ownerAddress = msg.sender;
        commissionAddress = _commissionAddress;
        
        // levelPrice
        levelPrice[1] = 500 trx;
        levelPrice[2] = 1000 trx;
        levelPrice[3] = 2000 trx;
        levelPrice[4] = 3000 trx;
        levelPrice[5] = 4000 trx;
        levelPrice[6] = 5000 trx;
        levelPrice[7] = 10000 trx;
        levelPrice[8] = 20000 trx;
        levelPrice[9] = 30000 trx;
        levelPrice[10] = 40000 trx;
        levelPrice[11] = 50000 trx;
        levelPrice[12] = 100000 trx;
        levelPrice[13] = 200000 trx;
        levelPrice[14] = 300000 trx;
        levelPrice[15] = 400000 trx;
        levelPrice[16] = 500000 trx;
        levelPrice[17] = 600000 trx;
        levelPrice[18] = 700000 trx;
        levelPrice[19] = 800000 trx;
        levelPrice[20] = 900000 trx;
        levelPrice[21] = 1000000 trx;
        levelPrice[22] = 2500000 trx;
        levelPrice[23] = 5000000 trx;
        levelPrice[24] = 10000000 trx;
        
        uplinePercentage[1] = 25 trx;
        uplinePercentage[2] = 10 trx;
        uplinePercentage[3] = 10 trx;
        uplinePercentage[4] = 10 trx;
        uplinePercentage[5] = 15 trx;
        uplinePercentage[6] = 20 trx;
        
        UserStruct memory userDetails;
        
        userDetails = UserStruct({
            isExist: true,
            id: userCurrentId,
            referrerID: 0,
            currentLevel: 1,
            referral: new address[](0)
        });

        users[msg.sender] = userDetails;
        userList[userCurrentId] = msg.sender;
        
        users[ownerAddress].currentLevel = LASTLEVEL;
            
        for(uint8 i = 1; i <= LASTLEVEL; i++) {
            users[ownerAddress].levelStatus[i] = true;
        }
        
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function contractLock(bool _lockStatus) onlyOwner external returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function updateAdminFee(uint _percentage) onlyOwner external returns(bool) {
       adminPercentage = _percentage;
       return true;
    }
    
    function updateCommissionAddress(address _commisionAddr) onlyOwner external returns(bool) {
       commissionAddress = _commisionAddr;
       return true;
    }
    
    function updatePrice(uint8 _level, uint _price) onlyOwner external returns(bool) {
        levelPrice[_level] = _price;
        return true;
    }
    
    function updateUplinePercentage(uint8 _upline, uint _percentage) onlyOwner external returns(bool) {
       require(_upline>0 && _upline<=6, "Invalid Upline");
       uplinePercentage[_upline] = _percentage;
        return true;
    }
   
    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function pair(uint _referrerID) isLock public payable {
        require(users[msg.sender].isExist == false, "User Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == levelPrice[1],"Incorrect Value");
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract");
        
        if (users[userList[_referrerID]].referral.length >= REFLIMIT) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        
        UserStruct memory userDetails;
        userCurrentId = userCurrentId.add(1);
        
        userDetails = UserStruct({
            isExist: true,
            id: userCurrentId,
            referrerID: _referrerID,
            currentLevel: 1,
            referral: new address[](0)
        });

        users[msg.sender] = userDetails;
        users[msg.sender].levelStatus[1] = true;
        userList[userCurrentId] = msg.sender;
        
        users[userList[_referrerID]].referral.push(msg.sender);
        
        loopCheck[msg.sender] = 0;
        uint adminCommission = ((levelPrice[1]).mul(adminPercentage)).div(100 trx);
        payForLevel(0,1, msg.sender,adminCommission);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
    
    function liquidity(uint8 _level) isLock external payable {
        require(users[msg.sender].isExist, "User not exist"); 
        require(msg.value == levelPrice[_level], "Incorrect Value");
        require(_level > 0 && _level <= LASTLEVEL, "Incorrect level");
        require(users[msg.sender].levelStatus[_level] == false, "Already Active");

        if (_level != 1) {
            
            for (uint8 i = _level - 1; i > 0; i--) 
                require(users[msg.sender].levelStatus[i] == true, "Buy the previous level");
        }
            
        if(users[msg.sender].levelStatus[_level] == false) 
            users[msg.sender].currentLevel = _level;
        
        users[msg.sender].levelStatus[_level] = true;
        
        loopCheck[msg.sender] = 0;
        uint adminCommission = ((levelPrice[_level]).mul(adminPercentage)).div(100 trx);
        payForLevel(0,_level, msg.sender, adminCommission);
        emit buyLevelEvent(msg.sender, _level, now);
    }
    
    function getReferrer(uint _level,address _user) internal returns (address) {
      if (_level == 0 || _user == address(0)) {
        return _user;
      }
      return getReferrer( _level - 1,userList[users[_user].referrerID]);
    }
    
    function payForLevel(uint8 _flag,uint8 _level, address _userAddress, uint _adminPrice) internal {
        
        address referer;
        
        if(_flag == 0)
            referer = getReferrer(_level,_userAddress);
            
        else if(_flag == 1)
            referer = userList[users[_userAddress].referrerID];

        if (users[referer].isExist == false) 
            referer = userList[1];

        if (loopCheck[msg.sender] > 6) 
            referer = userList[1];

        if (loopCheck[msg.sender] == 0) {
            require((address(uint160(commissionAddress)).send(_adminPrice)), "Transaction Failure 1");
            loopCheck[msg.sender] += 1;
            earnedtrx[commissionAddress][_level] =  earnedtrx[commissionAddress][_level].add(_adminPrice);
            totalEarnedtrx[commissionAddress] = totalEarnedtrx[commissionAddress].add(_adminPrice);
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, commissionAddress, users[commissionAddress].id, _level, _adminPrice, now);
        }


        if (users[referer].levelStatus[_level] == true) {

            if (loopCheck[msg.sender] <= 6) {
                
                if(referer == ownerAddress) {
                    uint bal = address(this).balance;
                    require((address(uint160(referer)).send(bal)),"Transaction Failure 2");
                    earnedtrx[referer][_level] =  earnedtrx[referer][_level].add(bal);
                    totalEarnedtrx[referer] = totalEarnedtrx[referer].add(bal);
                    loopCheck[msg.sender] += 1;
                    emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, bal, now);
                }
                
                else {
                    uint8 loopCount = loopCheck[msg.sender];
                    uint uplinePrice = levelPrice[_level].mul(uplinePercentage[loopCount]).div(100 trx);
                    require((address(uint160(referer)).send(uplinePrice)),"Transaction Failure 3");
                    earnedtrx[referer][_level] =  earnedtrx[referer][_level].add(uplinePrice);
                    totalEarnedtrx[referer] = totalEarnedtrx[referer].add(uplinePrice);
                    loopCheck[msg.sender] += 1;
                    
                    emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, uplinePrice, now);
                    payForLevel(1,_level, referer, _adminPrice);
                }
            }
        } else {
            if (loopCheck[msg.sender] <= 6 ) {
                uint8 loopCount = loopCheck[msg.sender];
                uint uplinePrice = levelPrice[_level].mul(uplinePercentage[loopCount]).div(100 trx);
                emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer,users[referer].id, _level, uplinePrice, now);
                payForLevel(1,_level, referer, _adminPrice);
            }
        }
    }
   
    function findFreeReferrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].referral.length < REFLIMIT) 
            return _userAddress;

        address[] memory referrals = new address[](1110);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];
        referrals[2] = users[_userAddress].referral[2];
        referrals[3] = users[_userAddress].referral[3];
        referrals[4] = users[_userAddress].referral[4];
        referrals[5] = users[_userAddress].referral[5];
        referrals[6] = users[_userAddress].referral[6];
        referrals[7] = users[_userAddress].referral[7];
        referrals[8] = users[_userAddress].referral[8];
        referrals[9] = users[_userAddress].referral[9];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 1110; i++) { 
            if (users[referrals[i]].referral.length == REFLIMIT) {
                 
            
                if (i < 110) {
                    referrals[(i+1)*10] = users[referrals[i]].referral[0];
                    referrals[(i+1)*10+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*10+2] = users[referrals[i]].referral[2];
                    referrals[(i+1)*10+3] = users[referrals[i]].referral[3];
                    referrals[(i+1)*10+4] = users[referrals[i]].referral[4];
                    referrals[(i+1)*10+5] = users[referrals[i]].referral[5];
                    referrals[(i+1)*10+6] = users[referrals[i]].referral[6];
                    referrals[(i+1)*10+7] = users[referrals[i]].referral[7];
                    referrals[(i+1)*10+8] = users[referrals[i]].referral[8];
                    referrals[(i+1)*10+9] = users[referrals[i]].referral[9];
                }
           }  else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                 
                break;
            }
        }
        
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }
    
    function viewUserReferral(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].referral;
    }
    
    function viewUserLevelStatus(address _userAddress, uint8 _level) public view returns(bool) {
       return users[_userAddress].levelStatus[_level];
    }
   
    function getTotalEarnedtrx() public view returns(uint) {
        uint totaltrx;
       
        for( uint i = 1; i <= userCurrentId; i++) {
            totaltrx = totaltrx.add(totalEarnedtrx[userList[i]]);
        }
        
        return totaltrx;
    } 
}