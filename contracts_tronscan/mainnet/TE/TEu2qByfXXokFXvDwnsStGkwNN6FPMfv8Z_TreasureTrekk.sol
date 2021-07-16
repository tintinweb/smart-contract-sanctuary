//SourceUnit: TresureTrekk_Live.sol

pragma solidity 0.5.14;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
} //ok

contract TreasureTrekk {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address referrer;
        uint regTime;
        bool lockedStatus;
        uint partnersCount;
        mapping (uint8 => LeisureStruct) leisureMatrix;
        mapping (uint8 => WorkingStruct) workingMatrix;
        mapping (uint8 => uint8) currentLevel;
    }
    
     struct WorkingStruct{  // 2
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] firstLineRef;
        bool levelStatus;
    }
    
    struct LeisureStruct{  // 1
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] firstLineRef;
        uint[] secondLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
   
    
    using SafeMath for uint256;
    address public ownerAddress; 
    uint public userCurrentId = 1;
    uint8 public LP_LASTLEVEL = 12;
    uint8 public WP_LASTLEVEL = 12;
    uint public workPlanAdminFee = 5 trx;
    uint public withdrawAdminFee = 2 trx;
    bool public lockStatus;
    
    mapping (uint => uint) public workingSharePercentage;
    mapping (uint => address) public userList;
    mapping (address => UserStruct) public users;
    mapping (address => uint) public availHoldingBalance;
    mapping (address => uint) public lockedBalance;
    mapping (address => uint) public availEarningBalance;
    mapping (address => mapping(uint8 => uint8)) public workingPlanLoopCheck;
    mapping (address => mapping (uint8 => mapping(uint8 => uint))) public earnedTrx;
    mapping (address => mapping (uint8 => uint)) public totalEarnedTrx;
    mapping (address => mapping (uint8 => uint)) public virtualEarnings;
    mapping (uint8 => mapping (uint8 => uint)) public levelPrice;
    mapping (uint8 => uint) public workingVirtualLimit;
    
    event userDepositEvent(address UserAddress, uint DepositedAmount, uint Time);
    event regLevelEvent(uint8 indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(uint8 indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, uint8 Levelno, uint Time);
    event getMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event lostMoneyForLevelEvent(uint8 indexed Matrix, address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event reInvestEvent(uint8 indexed Matrix, address indexed UserAddress,address indexed CallerAddress, uint8 Levelno, uint ReInvestCount, uint Time); 
    event adminEarningsEvent(uint8 _flag, address indexed CallerAddress,uint CallerId, uint earnedPrice,  uint Time);
    event userWithdrawEvent(uint8 _flag, address indexed CallerAddress,uint CallerId, uint earnedPrice,  uint Time);
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    } 
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    constructor() public {
        ownerAddress = msg.sender;
        
        users[ownerAddress].isExist = true;
        users[ownerAddress].id = userCurrentId;
        users[ownerAddress].referrer = address(0);
        userList[userCurrentId] = ownerAddress;
        
        LeisureStruct memory leisureUserDetails;
    
        leisureUserDetails = LeisureStruct({
            UserAddress: ownerAddress,
            uniqueId: userCurrentId,
            referrerID: 0,
            firstLineRef: new uint[] (0),
            secondLineRef: new uint[] (0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[ownerAddress].currentLevel[1] = LP_LASTLEVEL;
        users[ownerAddress].currentLevel[2] = WP_LASTLEVEL;
        
        workingSharePercentage[1] = 15 trx;
        workingSharePercentage[2] = 7.5 trx;
        workingSharePercentage[3] = 10 trx;
        workingSharePercentage[4] = 11.25 trx;
        workingSharePercentage[5] = 12.5 trx;
        workingSharePercentage[6] = 13.75 trx;
        workingSharePercentage[7] = 25 trx; 
        
        
        levelPrice[1][1] = 100 trx;
        levelPrice[2][1] = 500 trx; 
        
        workingVirtualLimit[1] = levelPrice[2][1] * 5;
        
        users[ownerAddress].leisureMatrix[1] = leisureUserDetails;
        users[ownerAddress].workingMatrix[1].levelStatus = true;
        users[ownerAddress].workingMatrix[1].UserAddress  = ownerAddress;
        users[ownerAddress].workingMatrix[1].uniqueId = userCurrentId;
        
        
        for(uint8 i = 2; i <= LP_LASTLEVEL; i++) {
            levelPrice[1][i] = levelPrice[1][i-1] * 2;
            users[ownerAddress].leisureMatrix[i] = leisureUserDetails;
            
            
        
            levelPrice[2][i] = levelPrice[2][i-1] * 2;
            users[ownerAddress].workingMatrix[i].levelStatus = true;
            users[ownerAddress].workingMatrix[i].UserAddress  = ownerAddress;
            users[ownerAddress].workingMatrix[i].uniqueId = userCurrentId;
            
            workingVirtualLimit[i] = levelPrice[2][i] * 5;
        }
        
     }
     
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function updateLevelPrice(uint8 _matrix, uint8 _level, uint _price) onlyOwner external returns(bool) {
       levelPrice[_matrix][_level] = _price;
        return true;
    }

    function updateWorkingSharePercentage(uint _upline, uint _percentage) onlyOwner external returns(bool) {
       workingSharePercentage[_upline] = _percentage;
       return true;
    }
    
    function updateWithdrawFeePercentage(uint _percentage) onlyOwner external returns(bool) {
       withdrawAdminFee = _percentage;
       return true;
    }
    
    function updateAdminFeePercentage(uint _percentage) onlyOwner external returns(bool) {
       workPlanAdminFee = _percentage;
       return true;
    }
    
    function updateWorkPlanWithdrawLimit(uint8 _level,uint _limit) onlyOwner external returns(bool) {
       workingVirtualLimit[_level] = _limit;
       return true;
    }
    
    function userDeposit() isLock external payable {
        require(users[msg.sender].isExist == true, "User Not Exist");
        
        availHoldingBalance[msg.sender] = availHoldingBalance[msg.sender].add(msg.value);
        emit userDepositEvent(msg.sender, msg.value, now); 
    }
    
    function userHoldBalWithdraw(uint _amount) external returns(bool) {
        require(availHoldingBalance[msg.sender] >= _amount, "Insufficient Deposit Balance");
        
        uint adminShare = (_amount.mul(withdrawAdminFee)).div(100 trx);
        uint balAmount = _amount.sub(adminShare);
        
        availHoldingBalance[msg.sender] = availHoldingBalance[msg.sender].sub(_amount);
        require(msg.sender.send(balAmount) && address(uint160(ownerAddress)).send(adminShare) , "Transaction Failure");
        
        emit adminEarningsEvent(1, msg.sender, users[msg.sender].id, adminShare, now);
        emit userWithdrawEvent(1, msg.sender, users[msg.sender].id, balAmount, now);
        return true;
    } 
    
    function adminLockedBalWithdraw(uint _amount) external onlyOwner returns(bool) {
        require(lockedBalance[msg.sender] >= _amount, "Insufficient Locked Balance");
        
        lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(_amount);
        require(msg.sender.send(_amount), "Transaction Failure");
        
        emit adminEarningsEvent(3, msg.sender, users[msg.sender].id, _amount, now);
        return true;
    }
    
    function userEarningBalWithdraw(uint _amount) external returns(bool) {
        require(availEarningBalance[msg.sender] >= _amount, "Insufficient Earning Balance");
        
        uint adminShare = (_amount.mul(withdrawAdminFee)).div(100 trx);
        uint balAmount = _amount.sub(adminShare);
        
        availEarningBalance[msg.sender] = availEarningBalance[msg.sender].sub(_amount);
        require(msg.sender.send(balAmount) && address(uint160(ownerAddress)).send(adminShare) , "Transaction Failure");
        
        emit adminEarningsEvent(2, msg.sender, users[msg.sender].id, adminShare, now);
        emit userWithdrawEvent(2, msg.sender, users[msg.sender].id, balAmount, now);
        return true;
    } 

    function registration(uint _referrerID) isLock external payable {
        require(users[msg.sender].isExist == false, "User Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id"); 
        require(msg.value == levelPrice[1][1].add(levelPrice[2][1]), "Price Invalid");
        
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
            regTime: now,
            lockedStatus: true,
            referrer: userList[_referrerID],
            partnersCount: 0
        });
        
        users[msg.sender]= userData;
        userList[userCurrentId] = msg.sender;
        users[userList[_referrerID]].partnersCount = users[userList[_referrerID]].partnersCount.add(1);
        
       _leisureRegistration(_referrerID);
       _workingRegistration(_referrerID);
    } 
     
    function _leisureRegistration(uint _referrerID) internal  {
    
        uint firstLineId;
        uint secondLineId;
        
        if(users[userList[_referrerID]].leisureMatrix[1].firstLineRef.length < 3) {
            firstLineId = _referrerID;
            secondLineId = users[userList[firstLineId]].leisureMatrix[1].referrerID;
        }
        
        else if(users[userList[_referrerID]].leisureMatrix[1].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findleisureReferrer(1,_referrerID);
        }
        
        
        LeisureStruct memory leisureUserDetails;
        
        leisureUserDetails = LeisureStruct({
            UserAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].leisureMatrix[1] = leisureUserDetails;
        users[msg.sender].currentLevel[1]  = 1;
      
        users[userList[firstLineId]].leisureMatrix[1].firstLineRef.push(userCurrentId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].leisureMatrix[1].secondLineRef.push(userCurrentId);
        
        _updateLeisureDetails(secondLineId,1);
        emit regLevelEvent(1, msg.sender, userList[firstLineId], now);
    }  
    
    function _workingRegistration(uint _referrerID) internal  {     //     
        
        WorkingStruct memory x5UserDetails;
        
        x5UserDetails = WorkingStruct({
            UserAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: _referrerID,
            firstLineRef: new uint[](0),
            levelStatus: true
        });
        
        users[msg.sender].workingMatrix[1] = x5UserDetails;
        users[msg.sender].currentLevel[2]  = 1; 
    
        users[userList[_referrerID]].workingMatrix[1].firstLineRef.push(userCurrentId);
       
         workingPlanLoopCheck[msg.sender][1] = 0;
        _payWorkingTrx(1, msg.sender, levelPrice[2][1]); 
        emit regLevelEvent(2, msg.sender, userList[_referrerID], now); 
    } 
    
    function _updateLeisureDetails(uint secondLineId, uint8 _level) internal {
        
        if(secondLineId == 0)
            secondLineId = 1;
        
        if(users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 9) {
            
            if(userList[secondLineId] != ownerAddress) { // reinvest and place
                _leisureReInvest(userList[secondLineId],_level);
            }
            else { 
                  _payLeisureTrx(1,_level, ownerAddress, levelPrice[1][_level]);
            }
                
            users[userList[secondLineId]].leisureMatrix[_level].secondLineRef = new uint[](0);
            users[userList[secondLineId]].leisureMatrix[_level].firstLineRef = new uint[](0);
            users[userList[secondLineId]].leisureMatrix[_level].reInvestCount =  users[userList[secondLineId]].leisureMatrix[_level].reInvestCount.add(1);
            emit reInvestEvent(1, userList[secondLineId], msg.sender, _level, users[userList[secondLineId]].leisureMatrix[_level].reInvestCount, now); 
           
        }
        else if(users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length < 9) {
            
            
            if(users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 1 || users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 2) {
               
                if(users[userList[secondLineId]].leisureMatrix[_level].reInvestCount < 1) {
                    if(userList[secondLineId] != ownerAddress) {
                        
                            if(_level != LP_LASTLEVEL) {
                                
                                if(users[userList[secondLineId]].leisureMatrix[_level+1].levelStatus == false) {
                                    
                                    availHoldingBalance[userList[secondLineId]] = availHoldingBalance[userList[secondLineId]].add(levelPrice[1][_level]);
                                    
                                    if(availHoldingBalance[userList[secondLineId]]  >= levelPrice[1][_level+1]) {
                                        _leisureBuyLevel(userList[secondLineId],_level+1);
                                    }
                                }
                                else {
                                    
                                    _payLeisureTrx(1,_level, userList[secondLineId], levelPrice[1][_level]);
                                }
                            }
                            
                            else {
                                
                                _payLeisureTrx(1,_level, userList[secondLineId], levelPrice[1][_level]);
                                
                            }
                    }
                    else {
                              _payLeisureTrx(1,_level, ownerAddress, levelPrice[1][_level]);
                        }
                }
                
                else {
                    _payLeisureTrx(1,_level, userList[secondLineId], levelPrice[1][_level]); // -->
                    
                }
            }
            
            else if (users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 3 || users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 4 
            || users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 5 || users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 6) {
                 _payLeisureTrx(1,_level, userList[secondLineId], levelPrice[1][_level]); // --> user Address
            }
            
            
            else if(users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 7 || users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length == 8) {
                 _payLeisureTrx(0, _level, userList[secondLineId], levelPrice[1][_level]); //  --> second upline
            }
            
            else {
            
             _payLeisureTrx(1,_level, ownerAddress, levelPrice[1][_level]);
            
            }
            
        } 
        
    } 
    
    function leisureManualBuy(uint8 _level) isLock external payable {
        require(users[msg.sender].leisureMatrix[_level].levelStatus == false, "Already Active in this level");
        availHoldingBalance[msg.sender] = availHoldingBalance[msg.sender].add(msg.value);
        
        _leisureBuyLevel(msg.sender, _level);
    }
    
    function _leisureBuyLevel(address _user, uint8 _level) internal  {
        
        require(availHoldingBalance[_user] >= levelPrice[1][_level], "Insufficient Balance for Buy the level");
        
        availHoldingBalance[_user] = availHoldingBalance[_user].sub(levelPrice[1][_level]);
       
        uint firstLineId;
        uint secondLineId = _getleisureReferrer(_user, _level);
        
       if(users[userList[secondLineId]].leisureMatrix[_level].firstLineRef.length < 3) {
            firstLineId = secondLineId;
            secondLineId = users[userList[firstLineId]].leisureMatrix[_level].referrerID;
        }
        
        else if(users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findleisureReferrer(_level,secondLineId);
        }
        
        LeisureStruct memory leisureUserDetails;
        
        leisureUserDetails = LeisureStruct({
            UserAddress: _user,
            uniqueId: users[_user].id,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[_user].leisureMatrix[_level] = leisureUserDetails;
        users[_user].currentLevel[1]  = _level;
        
        users[userList[firstLineId]].leisureMatrix[_level].firstLineRef.push(users[_user].id);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.push(users[_user].id);
        
        _updateLeisureDetails(secondLineId,_level);
        
        emit buyLevelEvent(1,_user,userList[firstLineId], _level, now);
    } 
    
    function _findleisureReferrer(uint8 _level,  uint _refId) internal view returns(uint,uint) {
        
        if(users[userList[_refId]].leisureMatrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].leisureMatrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].leisureMatrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].leisureMatrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].leisureMatrix[_level].firstLineRef[2]; 
            
            for(uint8 r=0; r<3; r++) {
                    if(users[userList[referrals[r]]].leisureMatrix[_level].firstLineRef.length < 3) 
                         return (_refId, referrals[r]);
            }
            
        }
        
    }
    
    function _getleisureReferrer(address _userAddress, uint8 _level) internal returns(uint) {
        while (true) {
            
            uint referrerID =  users[_userAddress].leisureMatrix[1].referrerID;
            if (users[userList[referrerID]].leisureMatrix[_level].levelStatus == true) {
                return referrerID;
            }
            
            _userAddress = userList[referrerID];
            emit lostMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,userList[referrerID],referrerID, _level, levelPrice[1][_level],now);
        }
        
    }
       
    function _leisureReInvest(address _reInvest,  uint8 _level) internal {
        uint userUniqueId = users[_reInvest].id;
        address _referrer = users[_reInvest].referrer;
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[_referrer].leisureMatrix[_level].firstLineRef.length < 3) {
            firstLineId = users[_referrer].id;
            secondLineId = users[userList[firstLineId]].leisureMatrix[_level].referrerID;
        }
        
        else if(users[_referrer].leisureMatrix[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findLeisureReInvestReferrer(_level, users[_reInvest].id, users[_referrer].id);
        }
        
        users[_reInvest].leisureMatrix[_level].UserAddress = _reInvest;
        users[_reInvest].leisureMatrix[_level].uniqueId = userUniqueId;
        users[_reInvest].leisureMatrix[_level].referrerID = firstLineId;
        users[_reInvest].leisureMatrix[_level].levelStatus = true;
        
        users[userList[firstLineId]].leisureMatrix[_level].firstLineRef.push(userUniqueId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].leisureMatrix[_level].secondLineRef.push(userUniqueId);
        
        if(secondLineId == 0)
            secondLineId = 1;
        
        
        _updateLeisureDetails(secondLineId, _level);
        
    } 
    
    function _findLeisureReInvestReferrer(uint8 _level,uint _reInvestId, uint _refId) internal view returns(uint,uint) {
        
        if(users[userList[_refId]].leisureMatrix[_level].firstLineRef.length <3)
            return(users[userList[_refId]].leisureMatrix[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].leisureMatrix[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].leisureMatrix[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].leisureMatrix[_level].firstLineRef[2];
            
            
            for(uint8 r=0; r<3; r++) {
                if(users[userList[referrals[r]]].leisureMatrix[_level].firstLineRef.length < 3) {
                    if(referrals[r] != _reInvestId)
                        return (_refId, referrals[r]);
                }
                
                if(users[userList[referrals[r]]].leisureMatrix[_level].firstLineRef.length < 3) {
                        return (_refId, referrals[r]);
                }
            }
            
        }
        
    } 
    
    function _payLeisureTrx(uint8 _flag, uint8 _level, address _userAddress, uint256 _amt) internal {
        
        uint[3] memory referer;
        
        referer[0] = users[_userAddress].leisureMatrix[_level].referrerID;
        referer[1] = users[userList[referer[0]]].leisureMatrix[_level].referrerID;
        referer[2] = users[userList[referer[1]]].leisureMatrix[_level].referrerID; 
        
        if(_flag == 0) { // second upline 
         
            if(users[userList[referer[1]]].isExist == false) 
                referer[1] = 1;
            
            availEarningBalance[userList[referer[1]]] = availEarningBalance[userList[referer[1]]].add(_amt);
            totalEarnedTrx[userList[referer[1]]][1] = totalEarnedTrx[userList[referer[1]]][1].add(_amt);
            earnedTrx[userList[referer[1]]][1][_level] =  earnedTrx[userList[referer[1]]][1][_level].add(_amt); 
            emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, userList[referer[1]], referer[1], _level, _amt, now);
        }
        
        else if(_flag == 1)   { // userAddress
            
            if(users[_userAddress].isExist == false) 
                _userAddress = ownerAddress;
            
            availEarningBalance[_userAddress] = availEarningBalance[_userAddress].add(_amt);
            totalEarnedTrx[_userAddress][1] = totalEarnedTrx[_userAddress][1].add(_amt);
            earnedTrx[_userAddress][1][_level] =  earnedTrx[_userAddress][1][_level].add(_amt);
            emit getMoneyForLevelEvent(1, msg.sender, users[msg.sender].id, _userAddress, users[_userAddress].id, _level, _amt, now);
        }
        
    } 
    
    function _payWorkingTrx(uint8 _level, address _userAddress, uint256 _amt) internal {
        
        uint refererID;
        uint _shareFee;
        
        refererID = users[_userAddress].workingMatrix[_level].referrerID;
       
        if(workingPlanLoopCheck[msg.sender][_level] == 0) {
            uint adminFees = (_amt.mul(workPlanAdminFee)).div(100 trx);
            require((address(uint160(userList[1])).send(adminFees)) , "Transaction Failure"); 
            emit adminEarningsEvent(1, msg.sender, users[msg.sender].id, adminFees, now);
            workingPlanLoopCheck[msg.sender][_level]= workingPlanLoopCheck[msg.sender][_level] + 1;     
        } // ok
        
        
        if(users[userList[refererID]].isExist == false) //ok
            refererID = 1;
            
        if(workingPlanLoopCheck[msg.sender][_level] > 7) //ok
            refererID = 1;
        
        
        if(users[userList[refererID]].workingMatrix[_level].levelStatus == true) {
       
            if(workingPlanLoopCheck[msg.sender][_level] <= 7) {
                
                _shareFee = (_amt.mul(workingSharePercentage[workingPlanLoopCheck[msg.sender][_level]])).div(100 trx);
                    
                        
                if(userList[refererID] != ownerAddress) { 
                
                    if(users[userList[refererID]].lockedStatus == false || workingPlanLoopCheck[msg.sender][_level] == 1) {                       
                       
                        if(virtualEarnings[userList[refererID]][2] < (workingVirtualLimit[users[userList[refererID]].currentLevel[2]]))  {
                            virtualEarnings[userList[refererID]][2] = virtualEarnings[userList[refererID]][2].add(_shareFee); 
                            
                            availEarningBalance[userList[refererID]] = availEarningBalance[userList[refererID]].add(_shareFee);
                            totalEarnedTrx[userList[refererID]][2] = totalEarnedTrx[userList[refererID]][2].add(_shareFee);
                            earnedTrx[userList[refererID]][2][_level] =  earnedTrx[userList[refererID]][2][_level].add(_shareFee);
                            emit getMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, userList[refererID], refererID, _level, _shareFee, now);                                 
                        }
                            
                        else {
                            uint8 _currentLevel = users[userList[refererID]].currentLevel[2];
                            availHoldingBalance[userList[refererID]] = availHoldingBalance[userList[refererID]].add(_shareFee);
                            
                            if(availHoldingBalance[userList[refererID]] >= levelPrice[2][_currentLevel+1]) 
                                virtualEarnings[userList[refererID]][2] = 0;
                        } 
                    }
                        
                    else if(users[userList[refererID]].lockedStatus == true && workingPlanLoopCheck[msg.sender][_level] > 1) {                       
                        lockedBalance[userList[refererID]] = lockedBalance[userList[refererID]].add(_shareFee);                       
                    }
                        
                        
                    if(users[userList[refererID]].workingMatrix[1].firstLineRef.length >= 5) {
                        users[userList[refererID]].lockedStatus = false;
                        availEarningBalance[userList[refererID]] = availEarningBalance[userList[refererID]].add(lockedBalance[userList[refererID]]);
                        virtualEarnings[userList[refererID]][2] = virtualEarnings[userList[refererID]][2].add(lockedBalance[userList[refererID]]);
                        lockedBalance[userList[refererID]] = 0; 
                    }
                    
                }
                        
                else if(userList[refererID] == ownerAddress) {
                    availEarningBalance[userList[refererID]] = availEarningBalance[userList[refererID]].add(_shareFee);
                    totalEarnedTrx[userList[refererID]][2] = totalEarnedTrx[userList[refererID]][2].add(_shareFee);
                    earnedTrx[userList[refererID]][2][_level] =  earnedTrx[userList[refererID]][2][_level].add(_shareFee);
                    emit getMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, userList[refererID], refererID, _level, _shareFee, now);
                    
                }
                
                workingPlanLoopCheck[msg.sender][_level]= workingPlanLoopCheck[msg.sender][_level] + 1;    
                _payWorkingTrx(_level, userList[refererID], _amt); 
                   
            }
        }
        
        else {
            
            if(workingPlanLoopCheck[msg.sender][_level] <= 7) {
                _shareFee = (_amt.mul(workingSharePercentage[workingPlanLoopCheck[msg.sender][_level]])).div(100 trx);
                _payWorkingTrx( _level, userList[refererID], _amt); 
                emit lostMoneyForLevelEvent(2, msg.sender, users[msg.sender].id, userList[refererID], refererID, _level, _shareFee, now);
            }
        }
          
       
    } 
    
    function workingBuyLevel(uint8 _level) isLock external payable  {
        
        availHoldingBalance[msg.sender] = availHoldingBalance[msg.sender].add(msg.value);
            
        require(availHoldingBalance[msg.sender] >= levelPrice[2][_level], "Insufficient Balance for Buy the level");
        
        availHoldingBalance[msg.sender] = availHoldingBalance[msg.sender].sub(levelPrice[2][_level]);
        address ref = findFreeWorkingReferrer(msg.sender,_level);
        
        WorkingStruct memory workingUserDetails;
        
        workingUserDetails = WorkingStruct({
            UserAddress: msg.sender,
            uniqueId: users[msg.sender].id,
            referrerID: users[ref].id,
            firstLineRef: new uint[](0),
            levelStatus: true
        });
        
        users[msg.sender].workingMatrix[_level] = workingUserDetails;
        users[msg.sender].currentLevel[2]  = _level; 
        
        users[ref].workingMatrix[_level].firstLineRef.push(userCurrentId);
    
        workingPlanLoopCheck[msg.sender][_level] = 0;
        _payWorkingTrx(_level, msg.sender, levelPrice[2][_level]); 
        emit buyLevelEvent(2, msg.sender, ref, _level, now);
    } 
    
    function findFreeWorkingReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].workingMatrix[level].levelStatus == true) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer; 
        }
    } //ok
    
    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    } 
    
    function contractLock(bool _lockStatus) onlyOwner external returns(bool) {
        lockStatus = _lockStatus;
        return true;
    } 
    
    function viewLeisureReferral(address userAddress, uint8 _level) public view returns(uint[] memory, uint[] memory) {
        return (users[userAddress].leisureMatrix[_level].firstLineRef,users[userAddress].leisureMatrix[_level].secondLineRef);
    }
    
    function viewWorkingReferral(address userAddress, uint8 _level) public view returns(uint[] memory) {
        return (users[userAddress].workingMatrix[_level].firstLineRef);
    } 
    
    function viewUserLevelStaus(uint8 _matrix, address _userAddress, uint8 _level) public view returns(bool) {
        if(_matrix == 1)        
            return (users[_userAddress].leisureMatrix[_level].levelStatus);
        else if(_matrix == 2)        
            return (users[_userAddress].workingMatrix[_level].levelStatus);
    }
    
    function viewUserReInvestCount(address _userAddress, uint8 _level) public view returns(uint) {
         return (users[_userAddress].leisureMatrix[_level].reInvestCount);
       
    }
    
    function viewUserCurrentLevel(uint8 _matrix, address _userAddress) public view returns(uint8) {
            return (users[_userAddress].currentLevel[_matrix]);
    } 
    
    function viewWorkingUsers(address user,uint8 level)public view returns(uint,uint,bool){
        return (users[user].workingMatrix[level].uniqueId,
                users[user].workingMatrix[level].referrerID,
                users[user].workingMatrix[level].levelStatus);
    }
    
}