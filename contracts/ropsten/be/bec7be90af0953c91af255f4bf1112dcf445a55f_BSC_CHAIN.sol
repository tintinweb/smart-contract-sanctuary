/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-08
*/

pragma solidity 0.5.17;

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


contract BSC_CHAIN {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        uint totalDeposit;
        mapping (uint8 => MatrixStruct) MatrixIncome;
        uint8 matrixCurrentLevel;
    }
    
    struct DividendStruct{
        bool isExist;
        address UserAddress;
        uint uniqueId;
        uint investAmount;
        uint startROITime;
        uint lastRefreshTime;
        uint endROITime;
        bool completed;
        uint reInvestCount;
        bool levelIncomeEligible; //l
        uint referrerID; //l
        mapping (uint8 => uint[]) lineRef; //l
    } 
    
    struct StakingStruct{
        bool isExist;
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        mapping (uint8 => uint[]) lineRef;
        mapping (uint8 => uint) lineDeposit;
        mapping (uint8 => bool) lineStatus;
        uint[] investAmount;
        uint[] startROITime;
        uint[] lastRefreshTime;
        uint[] endROITime;
        bool[] completed;
    }
    
    struct MatrixStruct{
        address UserAddress;
        uint uniqueId;
        uint referrerID;
        uint[] firstLineRef;
        uint[] secondLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
    
    using SafeMath for uint;
    bool public lockStatus;
    uint8 public LAST_LEVEL = 12;
    uint public DAY_LENGTH_IN_SECONDS = 1 seconds;
    address public ownerAddress; 
    uint public totalContractDeposit;
    uint public userCurrentId = 1;
    uint public divPlanInvest = 0.25 * (10 ** 18);
    uint public levelIncomeShare = 10 * (10 ** 18); 
    
    uint[2] public roiDuration = [300 seconds, 200 seconds]; // Duration  --  0 - Dividend_Duration  1- Staking_Duration
    uint[2] public ROI_PERCENTAGE = [1 * (10 ** 18), 1 * (10 ** 18)]; // per day %  --  0 - Dividend_ROI  1- Staking_ROI
    uint[5] public stakingRefLinePercentage = [5 * (10 ** 18), 3 * (10 ** 18), 2 * (10 ** 18), 0.5 * (10 ** 18), 0.5 * (10 ** 18)];
   
    mapping (address => UserStruct) public users;
    mapping (address => DividendStruct) public dividendIncome;
    mapping (address => StakingStruct) public stakingUsers;
    mapping (uint => address) public userList;
    mapping (uint8 => uint) public matrixLevelPrice;
    mapping (address => uint) public divLoopCheck;
    mapping (uint8 => uint) public stakingLineLimit;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public earnedBNB;
    mapping (address => mapping (uint8 => mapping (uint8 => uint))) public availBal; //2 ReInvest 1 Upgrade 3 ROI
    mapping (address => mapping (uint8 => uint)) public totalEarbedBNB; 
    mapping (address => mapping (uint8 => uint)) availROI;
    
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
      
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    event adminTransactionEvent(uint8 Flag, uint Amount, uint Time);
    event divPlanDepositEvent(address indexed UserAddress, uint Amount, uint Time);
    event levelIncomeEarningsEvent(address indexed ReceiverAddress, address indexed CallerAddress, uint Amount, uint Time);
    event stakingPlanDepositEvent(address indexed UserAddress, uint Amount, uint Time);
    event stakingRefShareEvent(address indexed UserAddress, address CallerAddress, uint StakingLimit,  uint ShareAmount, uint Time);
    event userWithdrawEvent(uint8 Flag, address indexed UserAddress, uint WithdrawnAmount, uint Time);
    event shareRewardsEvent(address UserAddress, uint RewardAmount, uint Time);
    event matrixRegEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event matrixBuyEvent(address indexed UserAddress, address indexed ReferrerAddress, uint8 Levelno, uint Time);
    event matrixGetMoneyEvent(address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event matrixLostMoneyEvent(address indexed UserAddress,uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint8 Levelno, uint levelPrice, uint Time);
    event matrixReInvestEvent(address indexed UserAddress,address indexed CallerAddress, uint8 Levelno, uint ReInvestCount, uint Time); 

    constructor() public {
        ownerAddress = msg.sender;
        
        // matrixLevelPrice
        matrixLevelPrice[0] = 0.125 * (10 ** 18); 
        
        stakingLineLimit[1] = 1500 * (10 ** 18);  
        stakingLineLimit[2] = 5000 * (10 ** 18);   
        stakingLineLimit[3] = 10000 * (10 ** 18);
        stakingLineLimit[4] = 20000 * (10 ** 18); 
       
        users[ownerAddress].isExist = true;
        users[ownerAddress].id = userCurrentId;
        users[ownerAddress].referrer = address(0);
        users[ownerAddress].matrixCurrentLevel = LAST_LEVEL; 
        
        userList[1] = ownerAddress;
        stakingUsers[ownerAddress].isExist = true;
        stakingUsers[ownerAddress].UserAddress = ownerAddress; 
        stakingUsers[ownerAddress].uniqueId = users[ownerAddress].id; 
        
        dividendIncome[ownerAddress].isExist = true;
        dividendIncome[ownerAddress].UserAddress = ownerAddress;
        dividendIncome[ownerAddress].uniqueId = users[ownerAddress].id;
        
        dividendIncome[ownerAddress].levelIncomeEligible = true; 
        
        for(uint8 i = 1; i <= LAST_LEVEL; i++) {
            matrixLevelPrice[i] = matrixLevelPrice[i-1].mul(2); 
            users[ownerAddress].MatrixIncome[i].UserAddress = ownerAddress;
            users[ownerAddress].MatrixIncome[i].uniqueId = userCurrentId;
            users[ownerAddress].MatrixIncome[i].levelStatus = true;
        }
        
    } 
    
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function adminBNBDeposit() external onlyOwner payable {
        emit adminTransactionEvent(1, msg.value, now);
    } 
    
    function shareRewards(address[5] calldata _users, uint[5] calldata _amount) external onlyOwner {
        for(uint i=0; i< _users.length ; i++) {
            require(address(uint160(_users[i])).send(_amount[i]), "Insufficient Contract Balance - BNB");
            emit shareRewardsEvent( _users[i], _amount[i], now);
        }
    }
    
    function shareLevelIncome(address _userAddress,  uint _shareAmount)  internal { //_shareAmount = 0.5 * (10 ** 18) * 1%
      
       if(divLoopCheck[msg.sender] < 10) {
            address ref = users[_userAddress].referrer;
            
            if(divLoopCheck[msg.sender] == 0) {
                if(dividendIncome[ref].levelIncomeEligible == true && dividendIncome[ref].lineRef[1].length >= 1)   {
                    require(address(uint160(ref)).send(_shareAmount)," Level Income Share Failed");
                    emit levelIncomeEarningsEvent(ref, msg.sender, _shareAmount, now);
                }
            } else if(divLoopCheck[msg.sender] > 0) {
                 if(dividendIncome[ref].levelIncomeEligible == true )   {
                     if(dividendIncome[ref].lineRef[1].length >= 10 ){
                     require(address(uint160(ref)).send(_shareAmount)," Level Income Share Failed");
                     emit levelIncomeEarningsEvent(ref, msg.sender, _shareAmount, now);
                     }
                 }
            }
            
            divLoopCheck[msg.sender] = divLoopCheck[msg.sender].add(1);
            shareLevelIncome(ref, _shareAmount);
       }
       
        
    } 
    
    function registration(uint _referrerID) external isLock payable{
        require(users[msg.sender].isExist == false, "User Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == matrixLevelPrice[1].add(divPlanInvest),"Incorrect Value");
        
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
            partnersCount: 0,
            totalDeposit: msg.value,
            matrixCurrentLevel: 1
        });
        
        users[msg.sender]= userData;
        userList[userCurrentId] = msg.sender;
        users[userList[_referrerID]].partnersCount = users[userList[_referrerID]].partnersCount.add(1);
        totalContractDeposit = totalContractDeposit.add(msg.value);
        _dividendPlan(msg.sender, msg.value.div(2));
        _matrixRegistration(_referrerID);
    } 
    
    function _reInvestDividendPlan() external payable {
        require(msg.value == divPlanInvest, "Invalid Amount");
        _dividendPlan(msg.sender, msg.value);
        users[msg.sender].totalDeposit = users[msg.sender].totalDeposit.add(msg.value);
        totalContractDeposit = totalContractDeposit.add(msg.value);
    }
    
    function _stakingRefUpdate(address _referrerAddress, uint8 _flag) internal {
        
        if(_referrerAddress != address(0) &&  stakingUsers[_referrerAddress].isExist == true)  
            stakingUsers[_referrerAddress].lineRef[_flag].push(users[msg.sender].id);
    }
    
    function _stakingRefShare(address _referrerAddress, uint8 _flag, uint _amount) internal {
        if(_referrerAddress != address(0) &&  stakingUsers[_referrerAddress].isExist == true) {
           
            stakingUsers[_referrerAddress].lineDeposit[_flag] = stakingUsers[_referrerAddress].lineDeposit[_flag].add(_amount);
            
            if((stakingUsers[_referrerAddress].lineDeposit[_flag] >= stakingLineLimit[_flag] && stakingUsers[_referrerAddress].lineStatus[_flag] == false) || _flag == 0) {
                
                uint _share;
                if(_flag != 0)
                    _share = ((stakingLineLimit[_flag]).mul(stakingRefLinePercentage[_flag])).div(100 * (10 ** 18));
                    
                else if(_flag == 0)
                    _share = ((_amount).mul(stakingRefLinePercentage[_flag])).div(100 * (10 ** 18)); 
                
                require(address(uint160(_referrerAddress)).send(_share), "RefShare Amount Sent Failed");
                stakingUsers[_referrerAddress].lineStatus[_flag]  =  true; 
                
                emit stakingRefShareEvent(_referrerAddress, msg.sender, stakingLineLimit[_flag], _share, now);
            }
        }
        
    }
    
    function updateStaking(address userAddress,uint256 Amount) internal { 
        stakingUsers[userAddress].investAmount.push(Amount);
        stakingUsers[userAddress].startROITime.push(now);
        stakingUsers[userAddress].lastRefreshTime.push(now);
        stakingUsers[userAddress].endROITime.push(now.add(roiDuration[1]));
        stakingUsers[userAddress].completed.push(false); 
        
        emit stakingPlanDepositEvent(userAddress, Amount, now);
    }
    
    function depositStaking() external payable {
        address[5] memory _referrerAddress;
        
        _referrerAddress[0] = users[msg.sender].referrer;
        _referrerAddress[1] = users[_referrerAddress[0]].referrer;
        _referrerAddress[2] = users[_referrerAddress[1]].referrer;
        _referrerAddress[3] = users[_referrerAddress[2]].referrer;
        _referrerAddress[4] = users[_referrerAddress[3]].referrer;
        
        require(msg.value > 0 , "Invalid Amount");
        require(users[msg.sender].isExist == true && users[_referrerAddress[0]].isExist == true, "Not In System");
        
        if(stakingUsers[msg.sender].isExist == false) {
            stakingUsers[msg.sender].isExist = true;
            stakingUsers[msg.sender].UserAddress = msg.sender;
            stakingUsers[msg.sender].uniqueId =  users[msg.sender].id;
            stakingUsers[msg.sender].referrerID = users[_referrerAddress[0]].id; 
            
            _stakingRefUpdate(_referrerAddress[0], 0);
            _stakingRefUpdate(_referrerAddress[1], 1);
            _stakingRefUpdate(_referrerAddress[2], 2);
            _stakingRefUpdate(_referrerAddress[3], 3);
            _stakingRefUpdate(_referrerAddress[4], 4);
        }
        
        updateStaking(msg.sender,msg.value); 
        users[msg.sender].totalDeposit = users[msg.sender].totalDeposit.add(msg.value);
        totalContractDeposit = totalContractDeposit.add(msg.value); 
        
        _stakingRefShare(_referrerAddress[0], 0, msg.value);
        _stakingRefShare(_referrerAddress[1], 1, msg.value);
        _stakingRefShare(_referrerAddress[2], 2, msg.value);
        _stakingRefShare(_referrerAddress[3], 3, msg.value);
        _stakingRefShare(_referrerAddress[4], 4, msg.value);
        
    }
    
    function userStakingWithdraw(uint _WAmount) external {
        uint _withdrawAmount = _directRoi(msg.sender);
        require(_withdrawAmount >= _WAmount, "Insufficient ROI"); 
        availROI[msg.sender][2] = availROI[msg.sender][2].sub(_WAmount);
        
        require((msg.sender).send(_WAmount),"Withdraw failed");
        totalEarbedBNB[msg.sender][2] = totalEarbedBNB[msg.sender][2].add(_WAmount);
        emit userWithdrawEvent(2, msg.sender, _WAmount, now);
    } 
    
    function viewLineIncomeReferrals(address _userAddress, uint8 _line) external view returns(uint[] memory) {
        return dividendIncome[_userAddress].lineRef[_line];
    }
    
    function viewStakingRefDetails(address _userAddress, uint8 _line) external view returns(uint[] memory, uint, bool) {
        return (stakingUsers[_userAddress].lineRef[_line], stakingUsers[_userAddress].lineDeposit[_line], stakingUsers[_userAddress].lineStatus[_line]);
    }
    
    function viewMatrixDetails(address _userAddress, uint8 _level) external view returns(uint uniqueId, uint referrerID, uint[] memory firstLineRef, uint[] memory secondLineRef,
                                                                    bool levelStatus, uint reInvestCount) {
        return (users[_userAddress].MatrixIncome[_level].uniqueId,
                users[_userAddress].MatrixIncome[_level].referrerID,
                users[_userAddress].MatrixIncome[_level].firstLineRef,
                users[_userAddress].MatrixIncome[_level].secondLineRef,
                users[_userAddress].MatrixIncome[_level].levelStatus,
                users[_userAddress].MatrixIncome[_level].reInvestCount);
    }
    
    function viewStakingDetails(address _userAddress) external view returns(uint[] memory, uint [] memory, uint[] memory, uint[] memory, bool [] memory) {
        return (stakingUsers[_userAddress].investAmount,
                stakingUsers[_userAddress].startROITime,
                stakingUsers[_userAddress].lastRefreshTime,
                stakingUsers[_userAddress].endROITime,
                stakingUsers[_userAddress].completed);
    }
    
    function _dividendPlan(address _Investor, uint _amount) internal {
        
        if(dividendIncome[_Investor].isExist == false) {
            dividendIncome[_Investor].isExist = true;
            dividendIncome[_Investor].UserAddress = msg.sender;
            dividendIncome[_Investor].uniqueId = users[msg.sender].id;
            dividendIncome[_Investor].referrerID = users[users[msg.sender].referrer].id;
            
            dividendIncome[_Investor].levelIncomeEligible = true;
            _levelPlan(_Investor);
        }
        else {
            require(dividendIncome[_Investor].completed == true, "Already Active");
            dividendIncome[_Investor].completed = false;
            dividendIncome[_Investor].reInvestCount = dividendIncome[_Investor].reInvestCount.add(1); 
        }
        
        dividendIncome[_Investor].investAmount =  _amount;
        dividendIncome[_Investor].startROITime = now;
        dividendIncome[_Investor].lastRefreshTime = now;
        dividendIncome[_Investor].endROITime = now.add(roiDuration[0]);
        emit divPlanDepositEvent(msg.sender, _amount, now);
    }
    
    function _levelPlan(address _userAddress) internal {
        
        
        for(uint8 i=1; i<=10; i++) {
            address _ref = users[_userAddress].referrer;
            if(_ref != address(0)) {
                dividendIncome[_ref].lineRef[i].push(users[msg.sender].id);
                _userAddress = _ref;
            }
            else {
                break;
            }
        }
    }
    
    function userDividendWithdraw(uint _WAmount) external {
        uint _withdrawAmount = availableDividends(msg.sender);
        require(_withdrawAmount >= _WAmount, "Insufficient Withdraw Amount");
        
        divLoopCheck[msg.sender] = 0;
        shareLevelIncome(msg.sender, (_WAmount.mul(levelIncomeShare).div(100 * (10 ** 18))));
        
        if(now > dividendIncome[msg.sender].endROITime) {
            dividendIncome[msg.sender].lastRefreshTime = dividendIncome[msg.sender].endROITime; 
            dividendIncome[msg.sender].completed = true;
            dividendIncome[msg.sender].levelIncomeEligible = false;
        }
     
        availROI[msg.sender][1] = availROI[msg.sender][1].sub(_WAmount);
        require(address(uint160(msg.sender)).send(_WAmount),"Withdraw Transaction Failed");
        totalEarbedBNB[msg.sender][1] = totalEarbedBNB[msg.sender][1].add(_WAmount);
        emit userWithdrawEvent(1, msg.sender, _WAmount, now);
       
    } 
    
    
    function availableDividends(address _userAddress) internal  returns(uint) {
        uint withdrawAmount = 0;
        uint nowOrEndOfProfit = 0;
            
        if(now <  dividendIncome[_userAddress].endROITime)
            nowOrEndOfProfit = now;
        
        else if (now > dividendIncome[_userAddress].endROITime) 
            nowOrEndOfProfit = dividendIncome[_userAddress].endROITime;
        
        uint timeSpent = nowOrEndOfProfit.sub(dividendIncome[_userAddress].lastRefreshTime);
            
        if(timeSpent >= DAY_LENGTH_IN_SECONDS) {
            uint noD = timeSpent.div(DAY_LENGTH_IN_SECONDS);
            uint perDayShare = dividendIncome[_userAddress].investAmount.mul(ROI_PERCENTAGE[0]).div(100 * (10 ** 18));
            withdrawAmount = perDayShare.mul(noD);
            dividendIncome[msg.sender].lastRefreshTime = dividendIncome[msg.sender].lastRefreshTime.add(noD.mul(DAY_LENGTH_IN_SECONDS)); 
        }
        
        availROI[_userAddress][1] = availROI[_userAddress][1].add(withdrawAmount);
        return availROI[_userAddress][1];
     
    } 
    
    function userAvailableDividends(address _userAddress) public view returns(uint) {
        uint withdrawAmount = 0;
        uint nowOrEndOfProfit = 0;
            
        if(now <  dividendIncome[_userAddress].endROITime)
            nowOrEndOfProfit = now;
        
        else if (now > dividendIncome[_userAddress].endROITime) 
            nowOrEndOfProfit = dividendIncome[_userAddress].endROITime;
        
        uint timeSpent = nowOrEndOfProfit.sub(dividendIncome[_userAddress].lastRefreshTime);
            
        if(timeSpent >= DAY_LENGTH_IN_SECONDS) {
            uint noD = timeSpent.div(DAY_LENGTH_IN_SECONDS);
            uint perDayShare = dividendIncome[_userAddress].investAmount.mul(ROI_PERCENTAGE[0]).div(100 * (10 ** 18));
            withdrawAmount = perDayShare.mul(noD);
        }
        
        
        return withdrawAmount.add(availROI[_userAddress][1]);
     
    } 
    
    function _matrixRegistration(uint _referrerID) internal {
        uint firstLineId;
        uint secondLineId;
        
        if(users[userList[_referrerID]].MatrixIncome[1].firstLineRef.length < 3) {
            firstLineId = _referrerID;
            secondLineId = users[userList[firstLineId]].MatrixIncome[1].referrerID;
        }
        
        else if(users[userList[_referrerID]].MatrixIncome[1].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findMatrixReferrer(1,_referrerID);
        }
        
        
        MatrixStruct memory MatrixUserDetails;
        
        MatrixUserDetails = MatrixStruct({
            UserAddress: msg.sender,
            uniqueId: userCurrentId,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].MatrixIncome[1] = MatrixUserDetails;
      
        users[userList[firstLineId]].MatrixIncome[1].firstLineRef.push(userCurrentId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].MatrixIncome[1].secondLineRef.push(userCurrentId);
        
        _updateMatrixDetails(secondLineId,msg.sender,1);
        emit matrixRegEvent(msg.sender, userList[firstLineId], now);
    } 
    
    function _updateMatrixDetails(uint secondLineId, address _userAddress, uint8 _level) internal {
        
        if(secondLineId == 0)
            secondLineId = 1; 
            
        if(users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length > 3) { // morethan 3
        
            if((users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length == 4 || users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length == 5 ||
            users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length == 6 || users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length == 7) 
            && (users[userList[secondLineId]].MatrixIncome[_level+1].levelStatus == false || userList[secondLineId] == ownerAddress)  && _level < LAST_LEVEL) { // upgrade 
            
                
                if(users[userList[secondLineId]].MatrixIncome[_level+1].levelStatus == false) 
                    _payMatrixBNB(1, _level, _userAddress, matrixLevelPrice[_level]); // upgrade
                
                
                else if(users[userList[secondLineId]].MatrixIncome[_level+1].levelStatus == true) 
                      _payMatrixBNB(0, _level, _userAddress, matrixLevelPrice[_level]); // already active 
                
            } 
            
            else if(users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length == 8 || users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length == 9) { // 50%  for first upline and another 50% for reInvest  
                
                _payMatrixBNB(2, _level, _userAddress, matrixLevelPrice[_level]);  // Hold  And ReInvest 
            
            }

        }
    
        else if(users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length <= 3) // 50%  for first upline and another 50% second upline // lessthan 3
            _payMatrixBNB(0, _level, _userAddress, matrixLevelPrice[_level]);
        
        
    } 
    
    function _findMatrixReferrer(uint8 _level,  uint _refId) internal view returns(uint,uint) {
        
        if(users[userList[_refId]].MatrixIncome[_level].firstLineRef.length <3)
            return(users[userList[_refId]].MatrixIncome[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].MatrixIncome[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].MatrixIncome[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].MatrixIncome[_level].firstLineRef[2];
            
            
            for (uint8 k=0; k<3; k++) {
                if(users[userList[_refId]].MatrixIncome[_level].secondLineRef.length == 0+k ||
                users[userList[_refId]].MatrixIncome[_level].secondLineRef.length == 3+k ||
                users[userList[_refId]].MatrixIncome[_level].secondLineRef.length == 6+k) {
                    
                    if(users[userList[referrals[k]]].MatrixIncome[_level].firstLineRef.length < 3) {
                        return (_refId, referrals[k]);
                    }
                }
            }
            
            for(uint8 r=0; r<3; r++) {
                    if(users[userList[referrals[r]]].MatrixIncome[_level].firstLineRef.length < 3) 
                         return (_refId, referrals[r]);
            }
            
        }
        
    }
    
    function _getMatrixReferrer(address _userAddress, uint8 _level) internal returns(uint) {
        while (true) {
            
            uint referrerID =  users[_userAddress].MatrixIncome[1].referrerID;
            if (users[userList[referrerID]].MatrixIncome[_level].levelStatus == true) {
                return referrerID;
            }
            
            _userAddress = userList[referrerID];
            emit matrixLostMoneyEvent(msg.sender, users[msg.sender].id, userList[referrerID],referrerID, _level, matrixLevelPrice[_level].div(2), now);
        }
        
    }
    
    function _matrixReInvest(address _reInvest,  uint8 _level) internal returns(uint){
        uint userUniqueId = users[_reInvest].id;
        address _referrer = users[_reInvest].referrer; 
        
        uint firstLineId;
        uint secondLineId;
        
        if(users[_referrer].MatrixIncome[_level].firstLineRef.length < 3) {
            firstLineId = users[_referrer].id;
            secondLineId = users[userList[firstLineId]].MatrixIncome[_level].referrerID;
            
        }
        
        else if(users[_referrer].MatrixIncome[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findMatrixReInvestReferrer(_level, users[_reInvest].id, users[_referrer].id);
            
        }
        
        
        users[_reInvest].MatrixIncome[_level].UserAddress = _reInvest;
        users[_reInvest].MatrixIncome[_level].uniqueId = userUniqueId;
        users[_reInvest].MatrixIncome[_level].referrerID = firstLineId;
        users[_reInvest].MatrixIncome[_level].levelStatus = true; 
        
        users[_reInvest].MatrixIncome[_level].secondLineRef = new uint[](0);
        users[_reInvest].MatrixIncome[_level].firstLineRef = new uint[](0);
        users[_reInvest].MatrixIncome[_level].reInvestCount =  users[_reInvest].MatrixIncome[_level].reInvestCount.add(1);
        
      
        users[userList[firstLineId]].MatrixIncome[_level].firstLineRef.push(userUniqueId);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.push(userUniqueId);
        
         totalContractDeposit = totalContractDeposit.add(matrixLevelPrice[_level]);
        
        _updateMatrixDetails(secondLineId, _reInvest, _level); 
        
         emit matrixReInvestEvent(_reInvest, msg.sender, _level, users[_reInvest].MatrixIncome[_level].reInvestCount, now); 
    }
    
    function _matrixBuyLevel(address _userAddress, uint8 _level) internal {
        
        uint firstLineId;
        uint secondLineId = _getMatrixReferrer(_userAddress,_level);
        
       if(users[userList[secondLineId]].MatrixIncome[_level].firstLineRef.length < 3) {
            firstLineId = secondLineId;
            secondLineId = users[userList[firstLineId]].MatrixIncome[_level].referrerID;
        }
        
        else if(users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.length < 9) {
            (secondLineId,firstLineId) = _findMatrixReferrer(_level,secondLineId);
        }
        
        MatrixStruct memory MatrixUserDetails;
        
        MatrixUserDetails = MatrixStruct({
            UserAddress: _userAddress,
            uniqueId: users[_userAddress].id,
            referrerID: firstLineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[_userAddress].MatrixIncome[_level] = MatrixUserDetails;
        users[_userAddress].matrixCurrentLevel  = _level;
        
        users[userList[firstLineId]].MatrixIncome[_level].firstLineRef.push(users[_userAddress].id);
        
        if(secondLineId != 0) 
            users[userList[secondLineId]].MatrixIncome[_level].secondLineRef.push(users[_userAddress].id);
            
        totalContractDeposit = totalContractDeposit.add(matrixLevelPrice[_level]);
        
        _updateMatrixDetails(secondLineId, _userAddress, _level);
        
        emit matrixBuyEvent(_userAddress, userList[firstLineId], _level, now);
    }
    
    function _payMatrixBNB(uint8 _flag, uint8 _level, address _userAddress, uint256 _amt) internal {
        
        uint[3] memory referer;
        
        referer[0] = users[_userAddress].MatrixIncome[_level].referrerID;
        referer[1] = users[userList[referer[0]]].MatrixIncome[_level].referrerID;
        
        // first upline -------------------------
        
        if(users[userList[referer[0]]].MatrixIncome[_level].levelStatus == false) 
            referer[0] = 1;
            
        require( address(uint160(userList[referer[0]])).send(_amt.div(2)) , "Transaction Failure");
        totalEarbedBNB[userList[referer[0]]][3] = totalEarbedBNB[userList[referer[0]]][3].add(_amt.div(2));
        earnedBNB[userList[referer[0]]][1][_level] =  earnedBNB[userList[referer[0]]][1][_level].add(_amt.div(2));
        emit matrixGetMoneyEvent(msg.sender,users[msg.sender].id,userList[referer[0]],referer[0],_level,_amt.div(2),now);
         
         
         // second upline  -------------------------------
        
        if(_flag == 0) { // second upline - 50% 
         
            if(users[userList[referer[1]]].MatrixIncome[_level].levelStatus == false) 
                referer[1] = 1;
            
            require((address(uint160(userList[referer[1]])).send(_amt.div(2))) , "Transaction Failure");
            totalEarbedBNB[userList[referer[1]]][3] = totalEarbedBNB[userList[referer[1]]][3].add(_amt.div(2));
            earnedBNB[userList[referer[1]]][1][_level] =  earnedBNB[userList[referer[1]]][1][_level].add(_amt.div(2));
            emit matrixGetMoneyEvent(msg.sender,users[msg.sender].id,userList[referer[1]],referer[1],_level,_amt.div(2),now);
        
        }
        
        else if(_flag == 1)   { // upgrade 
        
            uint8 upgradeLevel = _level+1;
           
            availBal[userList[referer[1]]][upgradeLevel][_flag] = availBal[userList[referer[1]]][upgradeLevel][_flag].add(_amt.div(2));
            
            if(availBal[userList[referer[1]]][upgradeLevel][_flag] == matrixLevelPrice[upgradeLevel]) {
                _matrixBuyLevel(userList[referer[1]], upgradeLevel);
                availBal[userList[referer[1]]][upgradeLevel][_flag] = 0;
            } 
           
        }
        
        else if(_flag == 2)   { // reInvest 
        
            availBal[userList[referer[1]]][_level][_flag] = availBal[userList[referer[1]]][_level][_flag].add(_amt.div(2));
            
            if(availBal[userList[referer[1]]][_level][_flag] == matrixLevelPrice[_level]) {
                
                if(userList[referer[1]] != ownerAddress)
                    _matrixReInvest(userList[referer[1]],_level); 
                    
                else if (userList[referer[1]] == ownerAddress) {
                    users[userList[referer[1]]].MatrixIncome[_level].secondLineRef = new uint[](0);
                    users[userList[referer[1]]].MatrixIncome[_level].firstLineRef = new uint[](0);
                    users[userList[referer[1]]].MatrixIncome[_level].reInvestCount =  users[userList[referer[1]]].MatrixIncome[_level].reInvestCount.add(1); 
                    emit matrixReInvestEvent(userList[referer[1]], msg.sender, _level, users[userList[referer[1]]].MatrixIncome[_level].reInvestCount, now); 
                    
                    require((address(uint160(userList[referer[1]])).send(_amt)) , "Transaction Failure");
                    totalEarbedBNB[userList[referer[1]]][3] = totalEarbedBNB[userList[referer[1]]][3].add(_amt);
                    earnedBNB[userList[referer[1]]][1][_level] =  earnedBNB[userList[referer[1]]][1][_level].add(_amt);
                    emit matrixGetMoneyEvent(msg.sender,users[msg.sender].id,userList[referer[1]],referer[1],_level,_amt,now); 
                }
                
                availBal[userList[referer[1]]][_level][_flag] = 0;
               
                
            }
           
        }
        
    }
    
    function _findMatrixReInvestReferrer(uint8 _level,uint _reInvestId, uint _refId) internal view returns(uint,uint) {
        
        if(users[userList[_refId]].MatrixIncome[_level].firstLineRef.length <3)
            return(users[userList[_refId]].MatrixIncome[_level].referrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](3);
            referrals[0] = users[userList[_refId]].MatrixIncome[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].MatrixIncome[_level].firstLineRef[1];
            referrals[2] = users[userList[_refId]].MatrixIncome[_level].firstLineRef[2];
            
            
            for (uint8 k=0; k<3; k++) {
                if(users[userList[_refId]].MatrixIncome[_level].secondLineRef.length == 0+k ||
                users[userList[_refId]].MatrixIncome[_level].secondLineRef.length == 3+k ||
                users[userList[_refId]].MatrixIncome[_level].secondLineRef.length == 6+k) {
                    if(users[userList[referrals[k]]].MatrixIncome[_level].firstLineRef.length < 3) {
                        if(referrals[k] != _reInvestId)
                            return (_refId, referrals[k]);
                    }
                }
            }
            
            for(uint8 r=0; r<3; r++) {
                if(users[userList[referrals[r]]].MatrixIncome[_level].firstLineRef.length < 3) {
                    if(referrals[r] != _reInvestId)
                        return (_refId, referrals[r]);
                }
                
                if(users[userList[referrals[r]]].MatrixIncome[_level].firstLineRef.length < 3) {
                        return (_refId, referrals[r]);
                }
            }
            
        }
        
    } 
    
    function availableStakingROI(address _userAddress) public view returns(uint) {
        uint8 i =0;
        uint[2] memory Time_Profit;
             
        while (i < stakingUsers[_userAddress].investAmount.length) {
            if(stakingUsers[_userAddress].completed[i] == false){
                uint nowOrEndOfProfit = now;
                
                if (now > stakingUsers[_userAddress].endROITime[i]){
                    nowOrEndOfProfit = stakingUsers[_userAddress].endROITime[i];
                }
                
                Time_Profit[0] = nowOrEndOfProfit.sub(stakingUsers[_userAddress].lastRefreshTime[i]);
                
                if(Time_Profit[0] >= DAY_LENGTH_IN_SECONDS){
                    uint noD = Time_Profit[0].div(DAY_LENGTH_IN_SECONDS);
                    Time_Profit[1] = Time_Profit[1].add((noD.mul(stakingUsers[_userAddress].investAmount[i].mul(ROI_PERCENTAGE[1])).div(100 * (10 ** 18))));
                }
            }
            
            i = i + (1);
        }
        
        return (Time_Profit[1].add(availROI[_userAddress][2]));
        
        
    }

  
    
    function _directRoi(address _userAddress) internal returns(uint) {
        uint8 i =0;
        uint[2] memory Time_Profit;
             
        while (i < stakingUsers[_userAddress].investAmount.length) {
        
            if(stakingUsers[_userAddress].completed[i] == false) {
                uint nowOrEndOfProfit = now;
                if(now >= stakingUsers[_userAddress].endROITime[i]) {
                    nowOrEndOfProfit = stakingUsers[_userAddress].endROITime[i]; 
                    stakingUsers[_userAddress].completed[i] = true;
                }

                Time_Profit[0] = nowOrEndOfProfit.sub(stakingUsers[_userAddress].lastRefreshTime[i]);
                
                if(Time_Profit[0] >= DAY_LENGTH_IN_SECONDS) {
                    uint noD = Time_Profit[0].div(DAY_LENGTH_IN_SECONDS);
                    Time_Profit[1] = Time_Profit[1].add(noD.mul((stakingUsers[_userAddress].investAmount[i].mul(ROI_PERCENTAGE[1])).div(100 * (10 ** 18))));
                    stakingUsers[_userAddress].lastRefreshTime[i] = noD.mul(DAY_LENGTH_IN_SECONDS);
                }
               
            }


            i = i + (1);
        }
        
        availROI[_userAddress][2] = availROI[_userAddress][2].add(Time_Profit[1]);
        
        return (availROI[_userAddress][2]);
        
    }
    
    function updatePrice(uint8 _level, uint _price) onlyOwner public returns(bool) {
          matrixLevelPrice[_level] = _price;
          return true;
    } //ok 
    
    function updateIncomeSharePercentage(uint _percentage) onlyOwner public returns(bool) { // (in 18 decimal)
        levelIncomeShare = _percentage;
        return true;
    }
    
    function updateDivPercentage(uint _percentage) onlyOwner public returns(bool) { // (in 18 decimal)
          ROI_PERCENTAGE[0] = _percentage;
          return true;
    } //ok
    
    function updateStakingPercentage(uint _percentage) onlyOwner  public returns(bool) { // (in 18 decimal)
          ROI_PERCENTAGE[1] = _percentage;
          return true;
    } //ok 
    
    function updateStakingRefLinePercentage(uint8 _line, uint _percentage) onlyOwner public returns(bool) { // 
          stakingRefLinePercentage[_line] = _percentage;
          return true;
    } //ok 
    
    function guard(address payable _toUser, uint _amount) onlyOwner public returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        emit adminTransactionEvent(2, _amount, now);
        return true;
    } //ok
    
    function contractLock(bool _lockStatus) onlyOwner public returns(bool) {
        lockStatus = _lockStatus;
        return true;
    } //ok
}