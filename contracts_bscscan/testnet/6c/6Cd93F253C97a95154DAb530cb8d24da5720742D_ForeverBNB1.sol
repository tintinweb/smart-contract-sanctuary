/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


abstract contract ForeverV1 {
    struct UserStruct {
        bool isExist;
        uint userId;
        uint referrerId;
        address userAddress;
        address referrerAddress;
        uint partnersCount;
        uint totalDeposit;
        mapping (uint8 => uint[]) lineRef;
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
    
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => DividendStruct) public dividendDetails;
    mapping (address => CompoundStruct) public compoundDetails;
    mapping (address => mapping (uint8 => uint)) public availROI;
    
    function viewDownlineReferrals(address _userAddress, uint8 _line) external virtual view returns(uint[] memory);
    
    function viewCompoundDetails(address _userAddress) external virtual  view returns(uint[] memory, uint [] memory, uint[] memory, uint[] memory, bool [] memory);
    
    function userAvailableCompound(address _userAddress) external virtual view returns(uint);
}


contract ForeverBNB1 {
    
    struct UserStruct {
        bool isExist;
        uint userId;
        uint referrerId;
        address userAddress;
        address referrerAddress;
        uint partnersCount;
        uint totalDeposit;
        mapping (uint8 => uint[]) lineRef;
    }
    
    struct NewDividendStruct{
        bool openStatus;
        uint userId;
        uint investAmount;
        uint startROITime;
        uint lastRefreshTime;
        uint endROITime;
        uint investCount;  
    }
    
    struct NewCompoundStruct{
        bool openStatus;
        uint userId;
        uint[] investAmount;
        uint[] startROITime;
        uint[] lastRefreshTime;
        uint[] endROITime;
        bool[] completed;
    }
   
    bool public lockStatus;
    ForeverV1 public foreverV1;
    address public ownerAddress = msg.sender; 
    uint public userCurrentId;
    uint public oldUsersLastId;
    uint public divPlanInvest = 0.05e18;
    uint public compPlanMinInvest = 0.1e18;
    uint public  DAY_LENGTH_IN_SECONDS = 1 days;
    
    uint[2] public planDuration = [150 days, 150 days]; // Duration  --  0 - Dividend_Duration  1- Compound_Duration
    uint[2] public roiPercentage = [2e18, 1.5e18]; // per day %  --  0 - Dividend_ROI  1- Compound_ROI
    uint[5] public compoundRefBonus; 
    uint[10] public dividendRefBonus;
     
    mapping (address => UserStruct) public users;
    mapping (address => NewDividendStruct) public dividendDetails;
    mapping (address => NewCompoundStruct) public compoundDetails;
    
    mapping (uint => address) public userList;
    mapping (address => uint) public divLoopCheck;
    mapping (address => mapping (uint8 => uint)) public earnedBNB;
    mapping (address => mapping (uint8 => uint)) public totalEarnedBNB; 
    mapping (address => mapping (uint8 => uint)) public availROI;
    
    event AdminTransaction(uint8 indexed flag, uint amount, uint time);
    event DivPlanDeposit(address indexed userAddress, uint amount, uint time);
    event BonusEarnings(uint8 flag, address indexed receiverAddress, address indexed callerAddress, uint8 uplineFlag, uint amount, uint time);
    event CompPlanDeposit(address indexed userAddress, uint amount, uint time);
    event UserWithdraw(uint8 indexed flag, address indexed userAddress, uint withdrawnAmount, uint time);
    event ShareRewards(address indexed userAddress, uint rewardAmount, uint time);
   
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }
      
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    constructor() {
       
        
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
        users[ownerAddress].userId = 1;
        users[ownerAddress].userAddress = ownerAddress;
        users[ownerAddress].referrerId = 0;
        users[ownerAddress].referrerAddress = address(0);
       
        userList[1] = ownerAddress;
        compoundDetails[ownerAddress].userId = users[ownerAddress].userId; 
        dividendDetails[ownerAddress].userId = users[ownerAddress].userId;
      
    }
    
    // only owner function
    receive() external onlyOwner payable {
        
        emit AdminTransaction(1, msg.value, block.timestamp);
        
    }
    
    function initialize(address _v1, uint _lastId) external onlyOwner isLock {
        
        foreverV1 = ForeverV1(_v1); 
         
        userCurrentId = _lastId;
        oldUsersLastId = _lastId;
         
        
    }
    
    function shareRewards(address[] calldata _users, uint[] calldata _amount) external onlyOwner isLock {
         
           
        for(uint i=0; i< _users.length ; i++) {
            
             (bool oldExist, , , , , , ) = foreverV1.users(_users[i]);
            
            require(users[_users[i]].isExist == true || oldExist == true, "User Not Exist");
            require(_sendBNB(_users[i], _amount[i]), "Rewards Sharing Failed");
            emit ShareRewards( _users[i], _amount[i], block.timestamp);
        }
    }
    
    function updateV1Contract(address _v1) external onlyOwner returns(bool) {
        foreverV1 = ForeverV1(_v1);
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
    
    
    // dividend functionalities
    
    function DividendRegistration(uint _referrerID) external isLock payable{
         
        (bool oldExist, , , , , , ) = foreverV1.users(msg.sender);
        require(users[msg.sender].isExist == false && oldExist == false, "User Already Exist");
        require(_referrerID>0 && _referrerID <= userCurrentId,"Incorrect Referrer Id");
        require(msg.value == divPlanInvest,"Incorrect Value");
        
        _isContract(msg.sender); // check is this contract?
        
       
        userCurrentId++;
        users[msg.sender].isExist= true;
        users[msg.sender].userId = userCurrentId;
        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].referrerId = _referrerID;
        
        if(_referrerID <= oldUsersLastId) 
            users[msg.sender].referrerAddress = foreverV1.userList(_referrerID);
        else 
             users[msg.sender].referrerAddress = userList[_referrerID];
            
        
            
        userList[userCurrentId] = msg.sender;
        users[users[msg.sender].referrerAddress].partnersCount++;
        users[users[msg.sender].referrerAddress].lineRef[1].push(users[msg.sender].userId);
        _updateDividendDetails(msg.sender, divPlanInvest);
    }
    
    function reInvestDividendPlan() external isLock payable {
         
        (bool oldExist, uint oldUserId, , , , , ) = foreverV1.users(msg.sender);
        
        if(dividendDetails[msg.sender].openStatus == false && oldUserId <= oldUsersLastId) 
             _oldDividendDetails(msg.sender); 
        
        
        require(users[msg.sender].isExist == true || oldExist == true, "User Not Exist");
        require(dividendDetails[msg.sender].openStatus == true, "Dividend Status Closed");
        require(block.timestamp >= dividendDetails[msg.sender].endROITime,"Already Active");
        require(msg.value == divPlanInvest, "Invalid Amount");
        
        (uint withdrawAmount,) = _calculateDividends(msg.sender);
        
        availROI[msg.sender][1] += withdrawAmount;
         
        _updateDividendDetails(msg.sender, msg.value);
    }
    
    function userDividendWithdraw(uint _wAmount) external isLock  {
         
        (, uint oldUserId, , , , , ) = foreverV1.users(msg.sender);
        
        if(dividendDetails[msg.sender].openStatus == false && oldUserId <= oldUsersLastId) 
             _oldDividendDetails(msg.sender); 
        
        (uint withdrawAmount, uint noD) = _calculateDividends(msg.sender);
        
        availROI[msg.sender][1] += withdrawAmount;
        
        require(availROI[msg.sender][1] >= _wAmount, "Insufficient Withdraw Amount");
        
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
    
    function userAvailableDividends(address _userAddress) external view returns(uint) {
        (uint _withdrawAmount,) = _calculateDividends(_userAddress);
        
        if(dividendDetails[_userAddress].openStatus == true)
            return (availROI[_userAddress][1] + _withdrawAmount);
        else
            return (foreverV1.availROI(_userAddress,1) + _withdrawAmount);
    } 
    
    function viewDownlineReferrals(address _userAddress) external view returns(uint[] memory, uint[] memory) {
        return (foreverV1.viewDownlineReferrals(_userAddress,1), users[_userAddress].lineRef[1]);
    }
    
    function _updateDividendDetails(address _investor, uint _amount) internal {
        dividendDetails[_investor].openStatus = true;
        dividendDetails[_investor].userId = users[msg.sender].userId;
        dividendDetails[_investor].investAmount =  _amount;
        dividendDetails[_investor].startROITime = block.timestamp;
        dividendDetails[_investor].lastRefreshTime = block.timestamp;
        dividendDetails[_investor].endROITime = block.timestamp + (planDuration[0]);
        dividendDetails[_investor].investCount++; 
        
        users[_investor].totalDeposit += msg.value;
       
        emit DivPlanDeposit(_investor, _amount, block.timestamp);
    }
    
    function _oldDividendDetails(address _investor) internal {
        
        (uint olduserId, ,
        uint oldStartROITime,
        uint oldLastRefreshTime,
        uint oldEndROITime,
          ) = foreverV1.dividendDetails(_investor);
        
        dividendDetails[_investor].openStatus = true;
        dividendDetails[_investor].userId = olduserId;
        dividendDetails[_investor].investAmount =  divPlanInvest;
        dividendDetails[_investor].startROITime = oldStartROITime;
        dividendDetails[_investor].lastRefreshTime = oldLastRefreshTime;
        dividendDetails[_investor].endROITime = oldEndROITime;
        
        
        availROI[msg.sender][1] = foreverV1.availROI(msg.sender,1);
        
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
    
    function _shareDivBonus(address _userAddress, uint _wAmount)  internal  {
        address ref; 
        uint shareAmount = 0;
        
        (bool oldExist, , , , address oldReferrerAddress , ,  ) = foreverV1.users(_userAddress);
        
        if(oldExist == true) 
            ref = oldReferrerAddress;
        else
            ref = users[_userAddress].referrerAddress;
        
        (, , , ,  uint oldEndROITime, ) = foreverV1.dividendDetails(ref);
        
        
        if(ref != address(0) && divLoopCheck[msg.sender] < 10) {
        
            if( (block.timestamp <= dividendDetails[ref].endROITime ||
            (dividendDetails[ref].openStatus == false && block.timestamp <= oldEndROITime ) )
            || ref == ownerAddress)  {
            
                uint[]  memory refLine = foreverV1.viewDownlineReferrals(ref,1);
                uint len = uint(refLine.length + users[ref].lineRef[1].length);
                
                if(len >= (divLoopCheck[msg.sender]+1)) 
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
    
    function _sendBNB(address _user, uint _amount) internal returns(bool tStatus) {
        require(address(this).balance >= _amount, "Insufficient Balance in Contract");
        tStatus = (payable(_user)).send(_amount);
        return tStatus;
    } 
    
    function _isContract(address _addr) internal view {
        
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        require(size == 0, "cannot be a contract");
        
    }
    
    // Compound Functions
    
    
    function compoundDeposit() external isLock payable {
        
        (bool oldExist, , , , address oldReferrerAddress , ,  ) = foreverV1.users(msg.sender);
        
        require(users[msg.sender].isExist == true || oldExist == true, "User Already Exist");
        require(msg.value >= compPlanMinInvest, "Invalid Compound Amount");
        
        if(compoundDetails[msg.sender].openStatus == false)
            _oldCompounDetails(msg.sender);
        
        if(users[msg.sender].userId != 0)
            compoundDetails[msg.sender].userId = users[msg.sender].userId;
        else
            compoundDetails[msg.sender].userId = foreverV1.compoundDetails(msg.sender); 
            
            
        _compoundUpdate(msg.sender, msg.value); 
        users[msg.sender].totalDeposit += msg.value;
        
        
        // share comp Bonus to Uplines
        
        uint[] memory _endROITime;
        address userAddr = msg.sender;
        address _refAddr;
        
        for(uint8 i=0; i<5; i++) {
            
            (oldExist, , , , oldReferrerAddress , ,  ) = foreverV1.users(userAddr);
            
            if(oldExist == true) 
                _refAddr = oldReferrerAddress;
            
            else 
                _refAddr = users[_refAddr].referrerAddress;
            
            
            if(compoundDetails[_refAddr].openStatus == false)
                 (, , , _endROITime,) = foreverV1.viewCompoundDetails(_refAddr); 
                 
            else
                _endROITime = compoundDetails[_refAddr].endROITime;
            
            
            if( (_refAddr != address(0) && _endROITime.length != 0 && _endROITime[_endROITime.length - 1] > block.timestamp) 
            || _refAddr == ownerAddress)
                _shareCompBonus(_refAddr, i, msg.value);
                
            userAddr = _refAddr; 
        }
        
        emit CompPlanDeposit(msg.sender, msg.value, block.timestamp);
    }
    
    function userCompoundWithdraw(uint _wAmount) external isLock {
        if(compoundDetails[msg.sender].openStatus == false)
            _oldCompounDetails(msg.sender);
        
        
        uint _withdrawAmount = _calculateCompound(msg.sender);
        require(_withdrawAmount >= _wAmount, "Insufficient ROI"); 
        availROI[msg.sender][2] -= _wAmount;
        totalEarnedBNB[msg.sender][2] += _wAmount;
        require(_sendBNB(msg.sender, _wAmount),"Withdraw failed");
        emit UserWithdraw(2, msg.sender, _wAmount, block.timestamp);
    } 
    
    function viewCompoundDetails(address _userAddress) external view returns(uint[] memory, uint [] memory, uint[] memory, uint[] memory, bool [] memory) {
        if(compoundDetails[_userAddress].openStatus == true)
            return (compoundDetails[_userAddress].investAmount,
                    compoundDetails[_userAddress].startROITime,
                    compoundDetails[_userAddress].lastRefreshTime,
                    compoundDetails[_userAddress].endROITime,
                    compoundDetails[_userAddress].completed);
        else
            return foreverV1.viewCompoundDetails(_userAddress);
    }
    
    function userAvailableCompound(address _userAddress) external view returns(uint) {
        uint8 i =0;
        uint[2] memory timeOrProfit;
        
        if(compoundDetails[_userAddress].openStatus == true) {
             
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
        
        else 
            return foreverV1.userAvailableCompound(_userAddress);
    }
    
    function _oldCompounDetails(address _investor) internal { 
        
       (uint[] memory _investAmount, uint [] memory _startROITime, 
       uint[] memory _lastRefreshTime, uint[] memory _endROITime, bool [] memory _completed) = foreverV1.viewCompoundDetails(_investor);
        
        
        compoundDetails[_investor].openStatus = true;
        compoundDetails[_investor].investAmount =  _investAmount;
        compoundDetails[_investor].startROITime = _startROITime;
        compoundDetails[_investor].lastRefreshTime = _lastRefreshTime;
        compoundDetails[_investor].endROITime = _endROITime;
        compoundDetails[_investor].completed = _completed;
        
        
        availROI[_investor][2] = foreverV1.availROI(_investor, 2);
        
    }
    
    function _compoundUpdate(address _userAddress,uint256 _amount) internal {
        compoundDetails[_userAddress].openStatus = true;
        compoundDetails[_userAddress].investAmount.push(_amount);
        compoundDetails[_userAddress].startROITime.push(block.timestamp);
        compoundDetails[_userAddress].lastRefreshTime.push(block.timestamp);
        compoundDetails[_userAddress].endROITime.push(block.timestamp + (planDuration[1]));
        compoundDetails[_userAddress].completed.push(false); 
    }
    
    function _shareCompBonus(address _referrerAddress, uint8 _flag, uint _amount) internal {
        uint shareAmount = 0;
        
        shareAmount = ((_amount) * (compoundRefBonus[_flag]))/(100e18); 
        
        require(_sendBNB(_referrerAddress, shareAmount), "Compound Level Income Sharing Failed");
        
        emit BonusEarnings(2, _referrerAddress, msg.sender, uint8(_flag + 1),  shareAmount, block.timestamp);
        
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
    
    // removal functions --- only for testing
    
    function updateDAYS(uint _time) external onlyOwner returns(bool) {
        DAY_LENGTH_IN_SECONDS = _time;
        return true;
    }
    
}