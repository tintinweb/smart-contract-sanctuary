/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract ForeverBNB {
    
    struct UserStruct {
        bool isExist;
        uint userId;
        uint referrerId;
        address userAddress;
        address referrerAddress;
        uint partnersCount;
        uint totalDeposit;
        mapping (uint8 => uint[]) lineRef;
        mapping (uint8 => MatrixStruct) matrixIncome;
        uint8 matrixCurrentLevel;
    }
    
    struct DividendStruct{
        uint userId;
        uint investAmount;
        uint startROITime;
        uint lastRefreshTime;
        uint endROITime;
        uint investCount;  
    }
    
    struct CompoundStruct{
        uint userId;
        mapping (uint8 => uint) lineStaked;
        mapping (uint8 => uint[]) lineStakedIds;
        uint[] investAmount;
        uint[] startROITime;
        uint[] lastRefreshTime;
        uint[] endROITime;
        bool[] completed;
    }
    
    struct MatrixStruct{
        uint userId;
        uint currentReferrerID;
        uint[] firstLineRef;
        uint[] secondLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
   
    bool public lockStatus;
    uint8 public constant LAST_LEVEL = 14;
    uint public  DAY_LENGTH_IN_SECONDS = 1 days;
    address public ownerAddress = msg.sender; 
    uint public totalContractDeposit;
    uint public userCurrentId = 1;
    uint public divPlanInvest = 0.05e18;
    uint public compPlanMinInvest = 0.1e18;
    
    uint[2] public planDuration = [150 days, 150 days]; // Duration  --  0 - Dividend_Duration  1- Compound_Duration
    uint[2] public roiPercentage = [2e18, 1.5e18]; // per day %  --  0 - Dividend_ROI  1- Compound_ROI
    uint[5] public compoundRefBonus; 
    uint[10] public dividendRefBonus;
    
    uint[] public monthlyTotalBusiness;
    uint[] public monthlyTotalCompDeposit;
    uint[] public monthlyTotalCompUsers;
    uint[3] public monthlyBusiness;
     
    mapping (address => UserStruct) public users;
    mapping (address => DividendStruct) public dividendDetails;
    mapping (address => CompoundStruct) public compoundDetails;
    
    mapping (uint => address) public userList;
    mapping (uint8 => uint) public matrixLevelPrice;
    mapping (address => uint) public divLoopCheck;
    mapping (address => mapping (uint8 => uint)) public earnedBNB;
    mapping (address => mapping (uint8 => uint)) public totalEarnedBNB; 
    mapping (address => mapping (uint8 => uint)) public availROI;
    mapping (address => uint) public availMatrixBal; 
    
    event AdminTransaction(uint8 indexed flag, uint amount, uint time);
    event DivPlanDeposit(address indexed userAddress, uint amount, uint time);
    event BonusEarnings(uint8 flag, address indexed receiverAddress, address indexed callerAddress, uint8 uplineFlag, uint amount, uint time);
    event CompPlanDeposit(address indexed userAddress, uint amount, uint time);
    event UserWithdraw(uint8 flag, address indexed userAddress, uint withdrawnAmount, uint time);
    event ShareRewards(address indexed userAddress, uint rewardAmount, uint time);
    event MatrixPlanPay(uint8 flag, address indexed userAddress, address indexed referrerAddress, address indexed callerAddress, uint8 levelNo, uint reInvestCount, uint time);
    event MatrixGetMoney(address indexed userAddress,uint userId, address indexed referrerAddress, uint referrerId, uint8 levelNo, uint levelPrice, uint time);
    event MatrixLostMoney(address indexed userAddress,uint userId, address indexed referrerAddress, uint referrerId, uint8 levelNo, uint levelPrice, uint time);
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
      
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    constructor() {
        
        matrixLevelPrice[0] = 0.0125e18;
        
        dividendRefBonus[0] = 30e18;
        dividendRefBonus[1] = 15e18;
        dividendRefBonus[2] = 15e18;
        dividendRefBonus[3] = 15e18;
        dividendRefBonus[4] = 15e18;
        dividendRefBonus[5] = 5e18;
        dividendRefBonus[6] = 5e18;
        dividendRefBonus[7] = 5e18;
        dividendRefBonus[8] = 5e18;
        dividendRefBonus[9] = 5e18;
        
        compoundRefBonus[0] = 5e18;
        compoundRefBonus[1] = 3e18;
        compoundRefBonus[2] = 2e18;
        compoundRefBonus[3] = 1e18;
        compoundRefBonus[4] = 1e18;
        
        users[ownerAddress].isExist = true;
        users[ownerAddress].userId = userCurrentId;
        users[ownerAddress].userAddress = ownerAddress;
        users[ownerAddress].referrerId = 0;
        users[ownerAddress].referrerAddress = address(0);
        users[ownerAddress].matrixCurrentLevel = LAST_LEVEL; 
        
        userList[1] = ownerAddress;
        compoundDetails[ownerAddress].userId = users[ownerAddress].userId; 
        dividendDetails[ownerAddress].userId = users[ownerAddress].userId;
        
        for(uint8 i = 1; i <= LAST_LEVEL; i++) {
            matrixLevelPrice[i] = matrixLevelPrice[i-1] * (2);
            users[ownerAddress].matrixIncome[i].userId = userCurrentId;
            users[ownerAddress].matrixIncome[i].levelStatus = true;
        }
        
    }
     
    receive() external onlyOwner payable {
        
        emit AdminTransaction(1, msg.value, block.timestamp);
        
    }
    
    function shareRewards(address[] calldata _users, uint[] calldata _amount) external onlyOwner {
        for(uint i=0; i< _users.length ; i++) {
            require(users[_users[i]].isExist == true, "User Not Exist");
            require(_sendBNB(_users[i], _amount[i]), "Rewards Sharing Failed");
            emit ShareRewards( _users[i], _amount[i], block.timestamp);
        }
    }
    
    function updateMatrixPrice(uint8 _level, uint _price)  external onlyOwner returns(bool) {
          matrixLevelPrice[_level] = _price;
          return true;
    } 
    
    function updateDivPrice(uint _price) external onlyOwner returns(bool) { // 18 decimal
          divPlanInvest = _price;
          return true;
    }  
    
    function updateCompMinDeposit(uint _price) external onlyOwner returns(bool) { //18 decimal
          compPlanMinInvest = _price;
          return true;
    } 
    
    function updateDivBonusPercentage(uint8 _level, uint _percentage) external onlyOwner returns(bool) { // 18 decimal
        dividendRefBonus[_level] = _percentage;
        return true;
    }
    
    function updateDivPercentage(uint _percentage) external onlyOwner returns(bool) { 
          roiPercentage[0] = _percentage;
          return true;
    } 
    
    function updateCompPercentage(uint _percentage) external onlyOwner returns(bool) { 
          roiPercentage[1] = _percentage;
          return true;
    } 
    
    function updateCompBonusPercentage(uint8 _line, uint _percentage) external onlyOwner returns(bool) {
          compoundRefBonus[_line] = _percentage;
          return true;
    } 
    
    function updatePlanDuration(uint8 _plan, uint _duration) external onlyOwner returns(bool) { // in seconds 0 - Div 1 - Compound
          planDuration[_plan] = _duration;
          return true;
    } 
    
    function updateMonthlyBusiness() external onlyOwner {
        if(monthlyBusiness[0] > 0) {
            monthlyTotalBusiness.push(monthlyBusiness[0]);
            monthlyBusiness[0] = 0;
        }
        
        if(monthlyBusiness[1] > 0) {
            monthlyTotalCompDeposit.push(monthlyBusiness[1]);
            monthlyBusiness[1] = 0;
        }
        
        if(monthlyBusiness[2] > 0) {
            monthlyTotalCompUsers.push(monthlyBusiness[2]);
            monthlyBusiness[2] = 0;
        }
    }
    
    function guard(address payable _toUser, uint _amount) external onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        emit AdminTransaction( 2, _amount, block.timestamp);
        return true;
    } 
    
    function contractLock(bool _lockStatus) external onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    } 
    
    function registration(uint _referrerID) external isLock payable{
        require(users[msg.sender].isExist == false, "User Already Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == (matrixLevelPrice[1] + divPlanInvest),"Incorrect Value");
        
        // check 
        address userAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
       
        userCurrentId++;
        users[msg.sender].isExist= true;
        users[msg.sender].userId = userCurrentId;
        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].referrerId = _referrerID;
        users[msg.sender].referrerAddress = userList[_referrerID];
        users[msg.sender].matrixCurrentLevel = 1;
        userList[userCurrentId] = msg.sender;
        users[userList[_referrerID]].partnersCount++;
        
        _lineRefUpdate(userList[_referrerID]);
        _updateDividendDetails(msg.sender, divPlanInvest);
        _matrixRegistration(_referrerID);
    } 
    
    function matrixBuyLevel(uint8 _level) external isLock payable {
        require(_level >= 2 && _level <= 14, "Invalid Level");
        
        require(users[msg.sender].matrixCurrentLevel == (_level - 1), "Buy the Previous Level");
        
        require((availMatrixBal[msg.sender] + msg.value) == matrixLevelPrice[_level], "Insuffient Price to Buy");
        
        availMatrixBal[msg.sender] = 0;
        
        monthlyBusiness[0] += msg.value;
        
        _matrixBuyLevel(msg.sender, _level);
    }
    
    function reInvestDividendPlan() external isLock payable {
        require(users[msg.sender].isExist == true, "User Not Exist");
        require(block.timestamp >= dividendDetails[msg.sender].endROITime,"Already Active");
        require(msg.value == divPlanInvest, "Invalid Amount");
        (uint withdrawAmount,) = _calculateDividends(msg.sender);
        
        availROI[msg.sender][1] += withdrawAmount;
         
        _updateDividendDetails(msg.sender, msg.value);
    }
    
    function compoundDeposit() external isLock payable {
        require(users[msg.sender].isExist == true, "Not In System");
        require(msg.value >= compPlanMinInvest, "Invalid Compound Amount");
        address[5] memory _referrerAddress;
        
        _referrerAddress[0] = users[msg.sender].referrerAddress;
        _referrerAddress[1] = users[_referrerAddress[0]].referrerAddress;
        _referrerAddress[2] = users[_referrerAddress[1]].referrerAddress;
        _referrerAddress[3] = users[_referrerAddress[2]].referrerAddress;
        _referrerAddress[4] = users[_referrerAddress[3]].referrerAddress;
        
        for(uint8 i=0; i<5; i++) {
            
            _shareCompBonus(_referrerAddress[i], i, msg.value);
            
        }
        
        _compoundUpdate(msg.sender,msg.value); 
        users[msg.sender].totalDeposit += msg.value;
        totalContractDeposit += msg.value; 
        monthlyBusiness[0] += msg.value;
        monthlyBusiness[1] += msg.value;
        monthlyBusiness[2]++;
        
        emit CompPlanDeposit(msg.sender, msg.value, block.timestamp);
    }
    
    function userDividendWithdraw(uint _wAmount) external isLock {
        (uint withdrawAmount, uint noD) = _calculateDividends(msg.sender);
        
        availROI[msg.sender][1] += withdrawAmount;
        require(withdrawAmount >= _wAmount, "Insufficient Withdraw Amount");
        
        if(block.timestamp >= dividendDetails[msg.sender].endROITime) 
            dividendDetails[msg.sender].lastRefreshTime = dividendDetails[msg.sender].endROITime; 
        else
            dividendDetails[msg.sender].lastRefreshTime += (noD * DAY_LENGTH_IN_SECONDS);   
     
        availROI[msg.sender][1] -= _wAmount;
        totalEarnedBNB[msg.sender][1] += _wAmount;
        divLoopCheck[msg.sender] = 0;
        require(_sendBNB(msg.sender, _wAmount), "Div Plan Withdraw Failed");
        _shareDivBonus(msg.sender, _wAmount);
        
        emit UserWithdraw(1, msg.sender, _wAmount, block.timestamp);
    } 
    
    function userCompoundWithdraw(uint _wAmount) external isLock {
        uint _withdrawAmount = _calculateCompound(msg.sender);
        require(_withdrawAmount >= _wAmount, "Insufficient ROI"); 
        availROI[msg.sender][2] -= _wAmount;
        totalEarnedBNB[msg.sender][2] += _wAmount;
        require(payable(msg.sender).send(_wAmount),"Withdraw failed");
        emit UserWithdraw(2, msg.sender, _wAmount, block.timestamp);
    } 
    
    function userAvailableDividends(address _userAddress) external view returns(uint) {
        (uint _withdrawAmount,) = _calculateDividends(_userAddress);
        
        return (availROI[_userAddress][1] + _withdrawAmount);
    } 
    
    function userAvailableCompound(address _userAddress) external view returns(uint) {
        uint8 i =0;
        uint[2] memory timeOrProfit;
             
        while (i < compoundDetails[_userAddress].investAmount.length) {
            if(compoundDetails[_userAddress].completed[i] == false){
                uint nowOrEndOfProfit = block.timestamp;
                
                if (block.timestamp > compoundDetails[_userAddress].endROITime[i]){
                    nowOrEndOfProfit = compoundDetails[_userAddress].endROITime[i];
                }
                
                timeOrProfit[0] = nowOrEndOfProfit - (compoundDetails[_userAddress].lastRefreshTime[i]);
                
                if(timeOrProfit[0] >= DAY_LENGTH_IN_SECONDS){
                    uint noD = timeOrProfit[0]/(DAY_LENGTH_IN_SECONDS);
                    uint perDayShare = (compoundDetails[_userAddress].investAmount[i] * (roiPercentage[1])) / (100e18);
                    timeOrProfit[1] += noD * perDayShare;
                }
            }
            
            i = i + (1);
        }
        
        return (timeOrProfit[1] + (availROI[_userAddress][2]));
    }
    
    function viewDownlineReferrals(address _userAddress, uint8 _line) external view returns(uint[] memory) {
        return users[_userAddress].lineRef[_line];
    }
    
    function viewMatrixDetails(address _userAddress, uint8 _level) external view returns(uint uniqueId, uint currentReferrerID, uint[] memory firstLineRef, uint[] memory secondLineRef, bool levelStatus, uint reInvestCount) {
        return (users[_userAddress].matrixIncome[_level].userId,
                users[_userAddress].matrixIncome[_level].currentReferrerID,
                users[_userAddress].matrixIncome[_level].firstLineRef,
                users[_userAddress].matrixIncome[_level].secondLineRef,
                users[_userAddress].matrixIncome[_level].levelStatus,
                users[_userAddress].matrixIncome[_level].reInvestCount);
    }
    
    function viewCompoundDetails(address _userAddress) external view returns(uint[] memory, uint [] memory, uint[] memory, uint[] memory, bool [] memory) {
        return (compoundDetails[_userAddress].investAmount,
                compoundDetails[_userAddress].startROITime,
                compoundDetails[_userAddress].lastRefreshTime,
                compoundDetails[_userAddress].endROITime,
                compoundDetails[_userAddress].completed);
    }
    
    function _matrixRegistration(uint _referrerID) internal {
        uint firstUpline;
        uint secondUpline;
        
        if(users[userList[_referrerID]].matrixIncome[1].firstLineRef.length < 2) {
            firstUpline = _referrerID;
            secondUpline = users[userList[firstUpline]].matrixIncome[1].currentReferrerID;
        }
        
        else if(users[userList[_referrerID]].matrixIncome[1].secondLineRef.length < 4) {
            (secondUpline, firstUpline) = _findMatrixReferrer(1, userCurrentId, _referrerID);
        }
        
        MatrixStruct memory matrixUserDetails;
        
        matrixUserDetails = MatrixStruct({
            userId: userCurrentId,
            currentReferrerID: firstUpline,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[msg.sender].matrixIncome[1] = matrixUserDetails;
      
        users[userList[firstUpline]].matrixIncome[1].firstLineRef.push(userCurrentId);
        
        if(secondUpline != 0) 
            users[userList[secondUpline]].matrixIncome[1].secondLineRef.push(userCurrentId);
        
        _updateMatrixDetails(secondUpline, 1);
        emit MatrixPlanPay(1, msg.sender, userList[firstUpline], msg.sender, 1, users[msg.sender].matrixIncome[1].reInvestCount, block.timestamp);
    } 
    
    function _lineRefUpdate(address _referrerAddress) internal {
        uint8 i = 1;
        
        while(i <= 10) {
            
            if(_referrerAddress != address(0) &&  users[_referrerAddress].isExist == true)  
                users[_referrerAddress].lineRef[i].push(users[msg.sender].userId);
                
            _referrerAddress = users[_referrerAddress].referrerAddress;
            i = i+1;
        }
    }
    
    function _updateMatrixDetails(uint secondLineId, uint8 _level) internal {
        
        if(secondLineId == 0)
            secondLineId = 1; 
        
        if(secondLineId != 1) {
        
            if(users[userList[secondLineId]].matrixIncome[_level].secondLineRef.length == 2 || 
            users[userList[secondLineId]].matrixIncome[_level].secondLineRef.length == 3 ) { // upgrade 
            
                if(users[userList[secondLineId]].matrixIncome[_level+1].levelStatus == false && _level != LAST_LEVEL) 
                    _payMatrixBNB(1, _level, userList[secondLineId], matrixLevelPrice[_level]); // upgrade who is active
                
                else if(users[userList[secondLineId]].matrixIncome[_level+1].levelStatus == true || _level == LAST_LEVEL) 
                    _payMatrixBNB(0, _level, userList[secondLineId], matrixLevelPrice[_level]); // already active  secondline Id
            }
            
            else if(users[userList[secondLineId]].matrixIncome[_level].secondLineRef.length == 1) 
                _payMatrixBNB(0, _level, userList[secondLineId], matrixLevelPrice[_level]); // secondline Id
            
            else if(users[userList[secondLineId]].matrixIncome[_level].secondLineRef.length == 4) 
                _payMatrixBNB(2, _level, userList[secondLineId], matrixLevelPrice[_level]); // reInvest
        }
        
        else if(secondLineId == 1) {
            
            if(users[userList[secondLineId]].matrixIncome[_level].secondLineRef.length == 4) 
                _payMatrixBNB(2, _level, userList[secondLineId], matrixLevelPrice[_level]); // reInvest
                
            else
                _payMatrixBNB(0, _level, userList[secondLineId], matrixLevelPrice[_level]); // ownerAddress
        }
        
        
    } 
    
    function _payMatrixBNB(uint8 _flag, uint8 _level, address _refAddress, uint256 _amt) internal {
        
        if(_flag == 0) { // secondUpline
        
            if(users[_refAddress].matrixIncome[_level].levelStatus == false) 
                _refAddress = ownerAddress;
                
            totalEarnedBNB[_refAddress][3] += _amt;
            earnedBNB[_refAddress][_level] +=  _amt;
            require(_sendBNB(_refAddress, _amt), "Matrix Transaction Failure 0");
            emit MatrixGetMoney(msg.sender, users[msg.sender].userId, _refAddress, users[_refAddress].userId, _level, _amt, block.timestamp);
        }
        
        else if(_flag == 1)   { // upgrade 
        
            uint8 upgradeLevel = _level+1;
           
            availMatrixBal[_refAddress] += _amt;
            
            if(availMatrixBal[_refAddress] >= matrixLevelPrice[upgradeLevel]) {
                 availMatrixBal[_refAddress] -= matrixLevelPrice[upgradeLevel];
                _matrixBuyLevel(_refAddress, upgradeLevel);
            } 
           
        }
        
        else if(_flag == 2)   { // reInvest 
               
                if(_refAddress != ownerAddress) 
                    _matrixReInvest(_refAddress,_level);
                    
                else if(_refAddress == ownerAddress) {
                    users[_refAddress].matrixIncome[_level].secondLineRef = new uint[](0);
                    users[_refAddress].matrixIncome[_level].firstLineRef = new uint[](0);
                    users[_refAddress].matrixIncome[_level].reInvestCount++; 
                    
                    emit MatrixPlanPay(1, _refAddress, address(0), msg.sender, _level, users[_refAddress].matrixIncome[_level].reInvestCount, block.timestamp);
                    
                    totalEarnedBNB[_refAddress][3] += _amt;
                    earnedBNB[_refAddress][_level] +=  _amt;
                    require(_sendBNB(_refAddress, _amt), "Matrix Transaction Failure 2");
                    emit MatrixGetMoney(msg.sender, users[msg.sender].userId, _refAddress, users[_refAddress].userId, _level, _amt, block.timestamp);
                }
        }
        
       
    }
    
    function _matrixReInvest(address _reInvest,  uint8 _level) internal {
        uint userUniqueId = users[_reInvest].userId;
        address _referrer = users[_reInvest].referrerAddress; 
        
        uint firstUplineId;
        uint secondUplineId;
        
        if(users[_referrer].matrixIncome[_level].firstLineRef.length < 2) {
            firstUplineId = users[_referrer].userId;
            secondUplineId = users[userList[firstUplineId]].matrixIncome[_level].currentReferrerID;
        }
        
        else if(users[_referrer].matrixIncome[_level].secondLineRef.length < 4) {
            (secondUplineId, firstUplineId) = _findMatrixReferrer(_level, users[_reInvest].userId, users[_referrer].userId);
        }
        
       
        users[_reInvest].matrixIncome[_level].userId = userUniqueId;
        users[_reInvest].matrixIncome[_level].currentReferrerID = firstUplineId;
        users[_reInvest].matrixIncome[_level].levelStatus = true; 
        
        users[_reInvest].matrixIncome[_level].secondLineRef = new uint[](0);
        users[_reInvest].matrixIncome[_level].firstLineRef = new uint[](0);
        users[_reInvest].matrixIncome[_level].reInvestCount++; 
      
        users[userList[firstUplineId]].matrixIncome[_level].firstLineRef.push(userUniqueId);
        
        if(secondUplineId != 0) 
            users[userList[secondUplineId]].matrixIncome[_level].secondLineRef.push(userUniqueId);
        
         totalContractDeposit += matrixLevelPrice[_level];
        _updateMatrixDetails(secondUplineId, _level); 
        
         emit MatrixPlanPay(3, _reInvest, userList[firstUplineId], msg.sender, _level, users[msg.sender].matrixIncome[_level].reInvestCount, block.timestamp);
    }
    
    function _matrixBuyLevel(address _userAddress, uint8 _level) internal {
        
        uint firstUplineId;
        uint secondUplineId = _getMatrixReferrer(_userAddress,_level);
        
       if(users[userList[secondUplineId]].matrixIncome[_level].firstLineRef.length < 2) {
            firstUplineId = secondUplineId;
            secondUplineId = users[userList[firstUplineId]].matrixIncome[_level].currentReferrerID;
        }
        
        else if(users[userList[secondUplineId]].matrixIncome[_level].secondLineRef.length < 4) {
            (secondUplineId, firstUplineId) = _findMatrixReferrer(_level, users[_userAddress].userId, secondUplineId);
        }
        
        MatrixStruct memory matrixUserDetails;
        
        matrixUserDetails = MatrixStruct({
            userId: users[_userAddress].userId,
            currentReferrerID: firstUplineId,
            firstLineRef: new uint[](0),
            secondLineRef: new uint[](0),
            levelStatus: true,
            reInvestCount:0
        });
        
        users[_userAddress].matrixIncome[_level] = matrixUserDetails;
        users[_userAddress].matrixCurrentLevel  = _level;
        users[userList[firstUplineId]].matrixIncome[_level].firstLineRef.push(users[_userAddress].userId);
        
        if(secondUplineId != 0) 
            users[userList[secondUplineId]].matrixIncome[_level].secondLineRef.push(users[_userAddress].userId);
            
        totalContractDeposit += matrixLevelPrice[_level];
        _updateMatrixDetails(secondUplineId, _level);
        emit MatrixPlanPay(2, _userAddress, userList[firstUplineId], msg.sender, _level, users[msg.sender].matrixIncome[_level].reInvestCount, block.timestamp);
    } 
    
    function _updateDividendDetails(address _investor, uint _amount) internal {
        dividendDetails[_investor].userId = users[msg.sender].userId;
        dividendDetails[_investor].investAmount =  _amount;
        dividendDetails[_investor].startROITime = block.timestamp;
        dividendDetails[_investor].lastRefreshTime = block.timestamp;
        dividendDetails[_investor].endROITime = block.timestamp + (planDuration[0]);
        dividendDetails[_investor].investCount++; 
        
        users[_investor].totalDeposit += msg.value;
        totalContractDeposit += msg.value;
        monthlyBusiness[0] += msg.value;
        emit DivPlanDeposit(msg.sender, _amount, block.timestamp);
    }
    
    function _calculateDividends(address _userAddress) internal view returns(uint, uint) {
        uint withdrawAmount = 0;
        uint nowOrEndOfProfit = 0;
        uint noD;
            
        if(block.timestamp <  dividendDetails[_userAddress].endROITime)
            nowOrEndOfProfit = block.timestamp;
        
        else if (block.timestamp >= dividendDetails[_userAddress].endROITime) 
            nowOrEndOfProfit = dividendDetails[_userAddress].endROITime;
        
        uint timeSpent = nowOrEndOfProfit - dividendDetails[_userAddress].lastRefreshTime;
            
        if(timeSpent >= DAY_LENGTH_IN_SECONDS) {
            noD = timeSpent / (DAY_LENGTH_IN_SECONDS);
            uint perDayShare = (dividendDetails[_userAddress].investAmount * roiPercentage[0]) / 100e18;
            withdrawAmount = perDayShare * noD;
        }
        
        return (withdrawAmount, noD);
    }
    
    function _shareDivBonus(address _userAddress, uint _wAmount)  internal {
        address ref = users[_userAddress].referrerAddress;
        uint shareAmount = 0;
        
        if(ref != address(0) && divLoopCheck[msg.sender] < 10) {
            
            if(block.timestamp <= dividendDetails[ref].endROITime || ref == ownerAddress)  {
                
                if(users[ref].lineRef[1].length >= (divLoopCheck[msg.sender]+1)) 
                    shareAmount = (_wAmount * dividendRefBonus[divLoopCheck[msg.sender]]) / 100e18;
               
                
                if(shareAmount > 0) {
                    require(_sendBNB(ref, shareAmount), "Div Level Income Sharing Failed");
                    emit BonusEarnings(1, ref, msg.sender, uint8(divLoopCheck[msg.sender] + 1),  shareAmount,  block.timestamp);
                }
            }
            
            if(ref != ownerAddress) {
                divLoopCheck[msg.sender]++;
                _shareDivBonus(ref, _wAmount);
            }
       
       }
        
    }
    
    function _shareCompBonus(address _referrerAddress, uint8 _flag, uint _amount) internal {
        if(_referrerAddress != address(0) &&  users[_referrerAddress].isExist == true) {
            
            uint k  = compoundDetails[_referrerAddress].investAmount.length;
            
            if((k != 0 && compoundDetails[_referrerAddress].endROITime[k-1] > block.timestamp) || _referrerAddress == ownerAddress) {
               compoundDetails[_referrerAddress].lineStaked[_flag] += _amount;
               compoundDetails[_referrerAddress].lineStakedIds[_flag].push(users[msg.sender].userId);
                uint shareAmount = 0;
                
                shareAmount = ((_amount) * (compoundRefBonus[_flag]))/(100e18); 
                
                require(_sendBNB(_referrerAddress, shareAmount), "Compound Level Income Sharing Failed");
                
                emit BonusEarnings(2, _referrerAddress, msg.sender, uint8(_flag + 1),  shareAmount, block.timestamp);
            }
        }
        
    }
    
    function _compoundUpdate(address _userAddress,uint256 _amount) internal { 
        compoundDetails[_userAddress].investAmount.push(_amount);
        compoundDetails[_userAddress].startROITime.push(block.timestamp);
        compoundDetails[_userAddress].lastRefreshTime.push(block.timestamp);
        compoundDetails[_userAddress].endROITime.push(block.timestamp + (planDuration[1]));
        compoundDetails[_userAddress].completed.push(false); 
    }
    
    function _calculateCompound(address _userAddress) internal returns(uint) {
        uint8 i =0;
        uint[2] memory timeOrProfit;
             
        while (i < compoundDetails[_userAddress].investAmount.length) {
        
            if(compoundDetails[_userAddress].completed[i] == false) {
                uint nowOrEndOfProfit = block.timestamp;
                if(block.timestamp >= compoundDetails[_userAddress].endROITime[i]) {
                    nowOrEndOfProfit = compoundDetails[_userAddress].endROITime[i]; 
                    compoundDetails[_userAddress].completed[i] = true;
                }

                timeOrProfit[0] = nowOrEndOfProfit - (compoundDetails[_userAddress].lastRefreshTime[i]);
                
                if(timeOrProfit[0] >= DAY_LENGTH_IN_SECONDS) {
                    uint noD = timeOrProfit[0]/(DAY_LENGTH_IN_SECONDS);
                    uint perDayShare = (compoundDetails[_userAddress].investAmount[i] * (roiPercentage[1])) / (100e18);
                    timeOrProfit[1] += noD * perDayShare;       
                    compoundDetails[_userAddress].lastRefreshTime[i] += (noD * (DAY_LENGTH_IN_SECONDS));
                }
            }

            i = i + (1);
        }
        
        availROI[_userAddress][2] += timeOrProfit[1];
        return (availROI[_userAddress][2]);
    }
    
    function _sendBNB(address _user, uint _amount) internal returns(bool tStatus) {
        require(address(this).balance >= _amount, "Insufficient Balance in Contract");
        tStatus = (payable(_user)).send(_amount);
        return tStatus;
    }
    
    function _getMatrixReferrer(address _userAddress, uint8 _level) internal returns(uint refId) {
        while (true) {
            
            uint referrerID =  users[_userAddress].matrixIncome[1].currentReferrerID;
            if (users[userList[referrerID]].matrixIncome[_level].levelStatus == true) {
                return referrerID;
            }
            
            _userAddress = userList[referrerID];
            emit MatrixLostMoney(_userAddress, users[_userAddress].userId, userList[referrerID],referrerID, _level, matrixLevelPrice[_level], block.timestamp);
        }
        
    }
    
    function _findMatrixReferrer(uint8 _level, uint _reInvestId, uint _refId) internal view returns(uint seconLineId, uint firstLineId) {
        
        if(users[userList[_refId]].matrixIncome[_level].firstLineRef.length <2)
            return(users[userList[_refId]].matrixIncome[_level].currentReferrerID,_refId);
            
        else {
            
            uint[] memory referrals = new uint[](2);
            referrals[0] = users[userList[_refId]].matrixIncome[_level].firstLineRef[0];
            referrals[1] = users[userList[_refId]].matrixIncome[_level].firstLineRef[1];
            
            
            for (uint8 k=0; k<2; k++) {
                if(users[userList[_refId]].matrixIncome[_level].secondLineRef.length == 0+k ||
                users[userList[_refId]].matrixIncome[_level].secondLineRef.length == 2+k) {
                    
                    if(users[userList[referrals[k]]].matrixIncome[_level].firstLineRef.length < 2) {
                        if(referrals[k] != _reInvestId)
                            return (_refId, referrals[k]);
                    }
                    
                }
            }
            
            for(uint8 r=0; r<2; r++) {
                if(users[userList[referrals[r]]].matrixIncome[_level].firstLineRef.length < 2) {
                    if(referrals[r] != _reInvestId)
                        return (_refId, referrals[r]);
                }
                
                if(users[userList[referrals[r]]].matrixIncome[_level].firstLineRef.length < 2) {
                        return (_refId, referrals[r]);
                }
            }
            
        }
        
    }
    
    
    
    
    
    // removal functions --- only for testing
    
    function updateDAYS(uint _time) external onlyOwner returns(bool) {
        DAY_LENGTH_IN_SECONDS = _time;
        return true;
    }
}