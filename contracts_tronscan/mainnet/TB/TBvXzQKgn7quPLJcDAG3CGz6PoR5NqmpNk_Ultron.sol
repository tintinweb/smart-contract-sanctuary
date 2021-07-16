//SourceUnit: Ultron.sol

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

contract Ultron {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address userAddress;
        address referrer;
        uint[] referrals;
        uint8 currentPackage;
        uint currentDLimit;
        uint currentWLimit;
        uint partnersCount;
        uint pastRecTime;
        mapping (uint8 => mapping(uint8 => uint)) reInvestCount; // 1=WP 2=NWP
        mapping (uint8 => mapping(uint8 => bool)) levelStatus; // ONLY ACTIVATE IN ONE PACKAGE  IN WORKING PLAN  
        mapping (uint8 => APStruct) APMatrix;
    }
    
    struct APStruct{
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] referrals;
    }
    
    using SafeMath for uint256;
    address public ownerAddress; 
    uint public userCurrentId = 1;
    uint8 public constant LASTPACKAGE = 6;
    uint public DAYSINSECONDS = 1 days;
    uint public adminPercentage = 20 trx;
    uint public WPPercentage = 64 trx;
    uint public APPercentage = 16 trx;
    bool public lockStatus;
    
    mapping (address => UserStruct) public users;   
    mapping (uint => address) public userList;
    mapping (uint8 => uint) public packagePrice;
    mapping (uint8 => uint) public dailyLimitPackage;
    mapping (uint8 => mapping (uint8 => uint)) public uplinePercentage;
    mapping (address => uint) public WPDailyBal;
    mapping (address => mapping (uint8 => mapping(uint8 => uint))) public availReInvestBal;
    mapping (address => mapping (uint8 => uint)) public virtualEarnings;
    mapping (uint8 => uint) public APCurrentId;
    mapping (uint8 => uint) public APDId; 
   
    mapping (uint8 => mapping (uint => APStruct)) public APInternal;
    mapping (uint8 => mapping (uint => address)) public APInternalUserList;
    mapping (address => mapping (uint8 => uint)) public totalEarnedTrx;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public earnedTrx;
    mapping (address => mapping (uint8 => uint8)) public loopCheck;
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint8 PackageNo, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint8 PackageNo, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint packagePrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint packagePrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress,address indexed CallerAddress, uint8 Levelno, uint ReInvestCount, uint Time);
    
    
    constructor() public {
        ownerAddress = msg.sender;
        
        // packagePrice
        packagePrice[1] = 1000  trx;       
        packagePrice[2] = 2000  trx;
        packagePrice[3] = 5000  trx;
        packagePrice[4] = 10000 trx;
        packagePrice[5] = 20000 trx;
        packagePrice[6] = 50000 trx;
        
        // dailyLimitPackage
        dailyLimitPackage[1] = 1000 trx;
        dailyLimitPackage[2] = 2000 trx;
        dailyLimitPackage[3] = 5000 trx;
        dailyLimitPackage[4] = 15000 trx;
        dailyLimitPackage[5] = 30000 trx;
        dailyLimitPackage[6] = 100000 trx;
        
        
        // Working Plan
        uplinePercentage[1][1] = 50 trx;
        uplinePercentage[1][2] = 12.5 trx;
        uplinePercentage[1][3] = 6.25 trx;
        uplinePercentage[1][4] = 6.25 trx; 
        uplinePercentage[1][5] = 6.25 trx;
        uplinePercentage[1][6] = 6.25 trx; 
        uplinePercentage[1][7] = 3.75 trx;
        uplinePercentage[1][8] = 3.75 trx;
        uplinePercentage[1][9] = 2.5 trx;
        uplinePercentage[1][10]= 2.5 trx; 
        
        // Non - Working Plan
        uplinePercentage[2][1]= 50 trx;  
        uplinePercentage[2][2]= 50 trx;
            
            
        users[ownerAddress].isExist = true;
        users[ownerAddress].id = userCurrentId;
        users[ownerAddress].userAddress = ownerAddress;
        users[ownerAddress].referrer = address(0);
        users[ownerAddress].referrals = new uint[](0);
        users[ownerAddress].pastRecTime = 0;
        users[ownerAddress].partnersCount = 0;
        users[ownerAddress].currentWLimit = 0;
        users[ownerAddress].currentDLimit = 0;
        
        
        userList[userCurrentId] = ownerAddress;
        
        APStruct memory APUserDetails;
    
        APUserDetails = APStruct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            referrerID: 0,
            referrals: new uint[](0)
        });
        
      
            
        for(uint8 i = 1; i <= LASTPACKAGE; i++) {
            
            users[ownerAddress].APMatrix[i] = APUserDetails;
            users[ownerAddress].levelStatus[1][i] = true;
            users[ownerAddress].levelStatus[2][i] = true;
            
            APCurrentId[i] = APCurrentId[i].add(1);
            APInternalUserList[i][APCurrentId[i]] = ownerAddress;
            APInternal[i][APCurrentId[i]] = APUserDetails;
            APDId[i] = 1;
        }
        
    }
   
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function contractLock(bool _lockStatus) onlyOwner external returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function updatePackagePrice(uint8 _level, uint _price) onlyOwner external returns(bool) {
        packagePrice[_level] = _price;
        return true;
    }
    
    function updateDuration(uint _duration) onlyOwner external returns(bool) {
        DAYSINSECONDS = _duration;
        return true;
    }

    function updatedailyLimitPackage(uint8 _level, uint _limit) onlyOwner external returns(bool) {
       dailyLimitPackage[_level] = _limit;
        return true;
    }
   
    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    
    function buyPackage(uint _referrerID, uint8 _package) isLock external payable {
        require(msg.value == packagePrice[_package],"Incorrect Value");
        require(_package > 0 && _package <= LASTPACKAGE, "Incorrect Package");
        require(users[msg.sender].levelStatus[1][_package] ==  false, "Already Active");
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract"); 
        
        
        if(users[msg.sender].isExist == false) {
            require(_referrerID > 0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
            _registerUser(msg.sender, _referrerID, _package);
            users[msg.sender].reInvestCount[1][_package] = 0;
            users[msg.sender].reInvestCount[2][_package] = 0;
        }
        
        else {
            require(users[msg.sender].currentPackage <= _package, "Select Higher Package");
            
            for(uint8 i=1; i<= LASTPACKAGE; i++) {
             users[msg.sender].levelStatus[1][i]= false;
            }
        
            users[msg.sender].levelStatus[1][_package]= true;
            users[msg.sender].levelStatus[2][_package]= true;
            users[msg.sender].currentPackage = _package;
            users[msg.sender].currentDLimit = dailyLimitPackage[_package];
            users[msg.sender].currentWLimit = packagePrice[_package].mul(2);
            users[msg.sender].pastRecTime = now;
        }
        
        uint wpShare = ((packagePrice[_package]).mul(WPPercentage)).div(100 trx);
        uint adminCommission = ((packagePrice[_package]).mul(adminPercentage)).div(100 trx);
        
        loopCheck[msg.sender][1] = 0;
        loopCheck[msg.sender][2] = 0;
        
        _WPPay(_package, msg.sender, msg.sender, wpShare, adminCommission);
        _APBuyLevel(_package);
        
        emit buyLevelEvent(msg.sender, _package, now);
    }
    
    function _registerUser(address _userAddress, uint _referrerID, uint8 _package) internal {
        
        userCurrentId = userCurrentId.add(1);
        
        users[_userAddress].isExist = true;
        users[_userAddress].id = userCurrentId;
        users[_userAddress].userAddress = _userAddress;
        users[_userAddress].referrer = userList[_referrerID];
        users[_userAddress].referrals = new uint[](0);
        users[_userAddress].pastRecTime = now;
        users[_userAddress].partnersCount = 0;
        users[_userAddress].currentPackage = _package;
        users[_userAddress].currentDLimit = dailyLimitPackage[_package];
        users[_userAddress].currentWLimit = packagePrice[_package].mul(2);
        users[_userAddress].levelStatus[1][_package]= true;
        users[_userAddress].levelStatus[2][_package]= true;
        
        userList[userCurrentId] = _userAddress;
        users[userList[_referrerID]].partnersCount = users[userList[_referrerID]].partnersCount.add(1);
        users[userList[_referrerID]].referrals.push(userCurrentId);
        
        emit regLevelEvent(_userAddress, userList[_referrerID], _package, now);
    }
    
    
    
    function _sendTRX(address _user, uint8 _level, uint _price) internal {
        require((address(uint160(_user)).send(_price)), "Transaction Failure WP");
        earnedTrx[_user][1][_level] =  earnedTrx[_user][1][_level].add(_price);
        totalEarnedTrx[_user][1] = totalEarnedTrx[_user][1].add(_price);
        emit getMoneyForLevelEvent(1,msg.sender, users[msg.sender].id, _user, users[_user].id, _level, _price, now);
        
        if(_user != ownerAddress)
            virtualEarnings[_user][1] = virtualEarnings[_user][1].add(_price);
    }
    
    function dayCalculation(uint _pastTime, uint _now) public view returns(uint) {
        uint diff = _now.sub(_pastTime);
        uint nOfDays = diff.div(DAYSINSECONDS);
        
        if(nOfDays > 0)
            return _pastTime.add((nOfDays).mul(DAYSINSECONDS));
        else 
            return _pastTime;
    }
    
    function _WPPay(uint8 _package, address _userAddress, address _loopAddress, uint _amt, uint _adminPrice) internal {
        
        address referer;
        uint _flag;
        
        referer = users[_userAddress].referrer;

        if (users[referer].isExist == false) 
            referer = userList[1];

        if (loopCheck[_loopAddress][1] > 10) 
            referer = userList[1];

        if (loopCheck[_loopAddress][1] == 0) { // admin commission 20%
            _sendTRX(ownerAddress, _package, _adminPrice);
            loopCheck[_loopAddress][1] += 1;
        }
        
        
        if(referer != ownerAddress) { // -- A
           
            if (loopCheck[_loopAddress][1] <= 10) { // -- B
                
                uint8 loopCount = loopCheck[_loopAddress][1];
                uint uplinePrice = _amt.mul(uplinePercentage[1][loopCount]).div(100 trx);
                
                
                if(users[referer].pastRecTime.add(DAYSINSECONDS) < now) { // -- C
                    uint _prePastTime = dayCalculation(users[referer].pastRecTime, now);
                    users[referer].pastRecTime = _prePastTime;
                    WPDailyBal[referer] = 0;
                }
                
                if (WPDailyBal[referer] < users[referer].currentDLimit && _flag != 2) { // -- D
                    uint ownerShare;
                    
                    if(users[referer].pastRecTime.add(DAYSINSECONDS) >= now) {
                        
                        if(WPDailyBal[referer].add(uplinePrice) >= users[referer].currentDLimit) {
                            ownerShare = (WPDailyBal[referer].add(uplinePrice)).sub(users[referer].currentDLimit);
                            uplinePrice = uplinePrice.sub(ownerShare);
                        }
                    
                        WPDailyBal[referer] = WPDailyBal[referer].add(uplinePrice);
                    }
                    else { 
                        uint _prePastTime = dayCalculation(users[referer].pastRecTime, now);
                        users[referer].pastRecTime = _prePastTime;
                        users[referer].pastRecTime = now;
                        WPDailyBal[referer] = uplinePrice;
                    }
                    
                    if(virtualEarnings[referer][1] < users[referer].currentWLimit) { // Upline Price send Withdraw Limit Amount
                        _sendTRX(referer, _package, uplinePrice);
                        
                        if(ownerShare > 0)
                            _sendTRX(ownerAddress, _package, ownerShare);
                    }
                        
                    else if(virtualEarnings[referer][1] >= users[referer].currentWLimit){
                        
                        if(availReInvestBal[referer][1][0] < packagePrice[users[referer].currentPackage]) {
                            availReInvestBal[referer][1][0]  = availReInvestBal[referer][1][0].add(uplinePrice);
                        }
                        else if(availReInvestBal[referer][1][0] >= packagePrice[users[referer].currentPackage]) {
                            
                            uint extraAmount = availReInvestBal[referer][1][0].sub(packagePrice[users[referer].currentPackage]);
                            
                            if(extraAmount > 0)
                                _sendTRX(referer, _package, extraAmount);
                            
                            _ReInvest(1, referer, users[referer].currentPackage);
                            _ReInvest(2, referer, users[referer].currentPackage);
                            virtualEarnings[referer][1] = 0;
                            availReInvestBal[referer][1][0] = 0;
                            //users[referer].referrals = new uint[](0);
                            users[referer].reInvestCount[1][0] = users[referer].reInvestCount[1][0].add(1);
                            emit reInvestEvent(1, referer, msg.sender, _package,   users[referer].reInvestCount[1][0], now);
                        }
                        
                    }
                    
                }
                else { // Extra amount in daily goes to admin
                    _sendTRX(ownerAddress, _package, uplinePrice);
                    emit lostMoneyForLevelEvent(1,msg.sender, users[msg.sender].id, referer,users[referer].id, _package, uplinePrice, now);
                }
                
                 loopCheck[_loopAddress][1] += 1;
                _WPPay(_package, referer, _loopAddress, _amt, _adminPrice);
                _flag = 2;
                
            } // -- B
            
        } // -- A
        
        else {
            // ref = owner so -- to owner -  balance upline amount 
           uint totalPrice = 0;
            
           while(loopCheck[_loopAddress][1] <= 10){
                uint8 loopCount = loopCheck[_loopAddress][1];
                uint uplineShare = _amt.mul(uplinePercentage[1][loopCount]).div(100 trx);
                totalPrice = totalPrice.add(uplineShare);
                loopCheck[_loopAddress][1] += 1;
            }
                
            _sendTRX(ownerAddress, _package, totalPrice);
         }
        
        
    }
    
    
    function _ReInvest(uint8 _matrix, address _user, uint8 _package) internal {
        if(_matrix == 1) {
            address _referrer = users[_user].referrer;
            users[_referrer].referrals.push(users[_user].id);
              
            uint wpShare = ((packagePrice[_package]).mul(WPPercentage)).div(100 trx);
            uint adminCommission = ((packagePrice[_package]).mul(adminPercentage)).div(100 trx);
            
            loopCheck[_user][1] = 0;
            
            _WPPay(_package, _user, _user, wpShare, adminCommission);
        }
        
        else if (_matrix == 2) { 
            
            loopCheck[_user][2] = 0;
            _APReInvest(_user,_package);
        }
        
    }
    
    
    function _APBuyLevel(uint8 _level) internal {
      
        uint _referrerID;
        
        for(uint i = APDId[_level]; i <= APCurrentId[_level]; i++) {
            if(APInternal[_level][i].referrals.length < 5) {
                _referrerID = i; 
                break;
            }
            else if(APInternal[_level][i].referrals.length == 5) {
                APDId[_level] = i;
                continue;
            }
        }
       
        APCurrentId[_level] = APCurrentId[_level].add(1);
        
        APStruct memory APUserDetails;
    
        APUserDetails = APStruct({
            UserAddress: msg.sender,
            uniqueId: users[msg.sender].id,
            referrerID: _referrerID,
            referrals: new uint[](0)
        });
        
       

        APInternal[_level][APCurrentId[_level]] = APUserDetails;
        APInternalUserList[_level][APCurrentId[_level]] = msg.sender;
        users[msg.sender].APMatrix[_level] = APUserDetails;
        
        APInternal[_level][_referrerID].referrals.push(APCurrentId[_level]);
        users[APInternalUserList[_level][_referrerID]].APMatrix[_level].referrals.push(users[msg.sender].id);
        
        loopCheck[msg.sender][2] = 0;
        _updateAPDetails(_referrerID, APCurrentId[_level], _level);
    
    }
    
    function _updateAPDetails(uint _referrerID, uint _userId, uint8 _level) internal {
       
        uint apShare = ((packagePrice[_level]).mul(APPercentage)).div(100 trx);
        
        if(APInternal[_level][_referrerID].referrals.length == 5) {
            _APPay(1, _level, _userId, apShare);
            
            users[APInternalUserList[_level][_referrerID]].APMatrix[_level].referrals = new uint[](0);
            users[APInternalUserList[_level][_referrerID]].reInvestCount[2][_level]= users[APInternalUserList[_level][_referrerID]].reInvestCount[2][_level].add(1);
        }
        
        else if(APInternal[_level][_referrerID].referrals.length < 4) 
            _APPay(0, _level, _userId, apShare);
            
        else if(APInternal[_level][_referrerID].referrals.length == 4) 
           _APPay(1, _level, _userId, apShare);
        
    } 
    
    function _APReInvest(address _userAddress, uint8 _level) internal {
         
        uint _referrerID;
        
        for(uint i = APDId[_level]; i <= APCurrentId[_level]; i++) {
            if(APInternal[_level][i].referrals.length < 5) {
                _referrerID = i; 
                break;
            }
            else if(APInternal[_level][i].referrals.length == 5) {
                APDId[_level] = i;
                continue;
            }
        }
       
        APCurrentId[_level] = APCurrentId[_level].add(1);
        
        APStruct memory APUserDetails;
    
        APUserDetails = APStruct({
            UserAddress: _userAddress,
            uniqueId: users[_userAddress].id,
            referrerID: _referrerID,
            referrals: new uint[](0)
        });

        APInternal[_level][APCurrentId[_level]] = APUserDetails;
        APInternalUserList[_level][APCurrentId[_level]] = _userAddress;
       
        users[_userAddress].APMatrix[_level].UserAddress = _userAddress;
        users[_userAddress].APMatrix[_level].uniqueId = users[_userAddress].id;
        users[_userAddress].APMatrix[_level].referrerID  = _referrerID;
        
        APInternal[_level][_referrerID].referrals.push(APCurrentId[_level]);
        users[APInternalUserList[_level][_referrerID]].APMatrix[_level].referrals.push(users[_userAddress].id);
        
        users[_userAddress].reInvestCount[2][users[_userAddress].currentPackage] = users[_userAddress].reInvestCount[2][users[_userAddress].currentPackage].add(1);
        _updateAPDetails(_referrerID, APCurrentId[_level],_level);
        emit reInvestEvent(2, _userAddress, msg.sender, _level,  users[_userAddress].reInvestCount[2][_level], now);
        
    } 
    
    function _APPay(uint8 _flag,uint8 _level, uint _userId, uint256 _amt) internal {
        uint[2] memory referer;
        
        referer[1] =  APInternal[_level][_userId].referrerID;
        referer[0] =  APInternal[_level][referer[1]].referrerID;
        
        if(users[APInternalUserList[_level][referer[0]]].levelStatus[2][_level] == false)
            referer[0] = 1;
        
        if(users[APInternalUserList[_level][referer[1]]].levelStatus[2][_level] == false)
            referer[1] = 1;
        
        if(_flag == 0) {
            require((address(uint160(APInternalUserList[_level][referer[0]]))).send(_amt.div(2)) && (address(uint160(APInternalUserList[_level][referer[1]]))).send(_amt.div(2)),"Transaction Failure AP 1");
            earnedTrx[APInternalUserList[_level][referer[0]]][2][_level] =  earnedTrx[APInternalUserList[_level][referer[0]]][2][_level].add(_amt.div(2));
            totalEarnedTrx[APInternalUserList[_level][referer[0]]][2] = totalEarnedTrx[APInternalUserList[_level][referer[0]]][2].add(_amt.div(2));
            emit getMoneyForLevelEvent(2,APInternalUserList[_level][_userId], users[APInternalUserList[_level][_userId]].id, APInternalUserList[_level][referer[0]], users[APInternalUserList[_level][referer[0]]].id, _level, _amt.div(2), now);
            
            earnedTrx[APInternalUserList[_level][referer[1]]][2][_level] =  earnedTrx[APInternalUserList[_level][referer[1]]][2][_level].add(_amt.div(2));
            totalEarnedTrx[APInternalUserList[_level][referer[1]]][2] = totalEarnedTrx[APInternalUserList[_level][referer[1]]][2].add(_amt.div(2));
            emit getMoneyForLevelEvent(2,APInternalUserList[_level][_userId], users[APInternalUserList[_level][_userId]].id, APInternalUserList[_level][referer[1]], users[APInternalUserList[_level][referer[1]]].id, _level, _amt.div(2), now);
        }
        
        else if(_flag == 1) {
            
            availReInvestBal[APInternalUserList[_level][referer[1]]][2][_level] = availReInvestBal[APInternalUserList[_level][referer[1]]][2][_level].add(_amt.div(2));
            availReInvestBal[APInternalUserList[_level][referer[0]]][2][_level] = availReInvestBal[APInternalUserList[_level][referer[0]]][2][_level].add(_amt.div(2));
            
            if(availReInvestBal[APInternalUserList[_level][referer[1]]][2][_level] == _amt && availReInvestBal[APInternalUserList[_level][referer[0]]][2][_level] == _amt) {
                _APReInvest(APInternalUserList[_level][referer[1]], _level);
                _APReInvest(APInternalUserList[_level][referer[0]], _level);
                availReInvestBal[APInternalUserList[_level][referer[1]]][2][_level] = 0;
                availReInvestBal[APInternalUserList[_level][referer[0]]][2][_level] = 0;
            
            }
        }
        
        
    }
 
    function viewAPUserDetails(address _user, uint8 _level) public view returns(address UserAddress,uint uniqueId, uint referrerID, uint[] memory referrals) {
        return (users[_user].APMatrix[_level].UserAddress, users[_user].APMatrix[_level].uniqueId, 
        users[_user].APMatrix[_level].referrerID, users[_user].APMatrix[_level].referrals);
    }
    
    function viewUserReferral(address _userAddress, uint8 _level, uint8 _matrix) public view returns(uint[] memory) {
        if(_matrix == 2)
            return users[_userAddress].APMatrix[_level].referrals;
        else if(_matrix == 1)
            return users[_userAddress].referrals;
    }
    
    function viewAPInternalUserReferral(uint _userId, uint8 _level) public view returns(uint[] memory) {
        return (APInternal[_level][_userId].referrals);
    }
    
    function viewUserPackageStatus(address _userAddress, uint8 _matrix, uint8 _package) public view returns(bool) {
        return users[_userAddress].levelStatus[_matrix][_package];
        
    }
    
    function viewUserReInvestCount(address _userAddress, uint8 _matrix, uint8 _package) public view returns(uint) {
        return users[_userAddress].reInvestCount[_matrix][_package];
    }
   
    function getTotalEarnedTrx(uint8 _matrix) public view returns(uint) {
        uint totalTrx;
        if(_matrix == 1)
        {
            for( uint i=1; i<=userCurrentId; i++) {
                totalTrx = totalTrx.add(totalEarnedTrx[userList[i]][1]);
            }
        }
        else if(_matrix == 2)
        {
            for( uint i = 1; i <= userCurrentId; i++) {
                totalTrx = totalTrx.add(totalEarnedTrx[userList[i]][2]);
            }
            
        }
        
        return totalTrx;
    } 
}