//SourceUnit: ForexTron.sol

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
}


contract ForexTron {
    using SafeMath for uint256;
    
    struct PlanStruct {
        uint8 plan;
        uint minInvestment;
        uint durationPeriod;
        uint ROIPercentage;
    }
    
    struct Users {
        bool isExist;
        uint userId;
        uint refEarnings;
        uint totalAvailRefBalance;
        address referrer;
        uint refCount;
        mapping (uint8 => Investment) invest;
    }
    
    struct Investment {
        bool isExpired;
        uint investedTime;
        uint lastPayOutTime;
        address[] firstLineRef;
        address[] secondLineRef;
        address[] thirdLineRef;
        address[] fourthLineRef;
    }
    
    bool public lockStatus;
    address public admin;
    uint public currentId =  0;
    uint public admindDepositBalance;
    uint public totalInvest;
    
    mapping (uint => address) public userList;
    mapping (uint8 => uint) public uplinePercentage; // (in trx)
    mapping (uint8 => uint) public refPercentage;
    mapping (uint8 => PlanStruct) public planDetails;
    mapping (address => Users) public userDetails;
    mapping (address => mapping (uint8 => uint)) public investBal;
    mapping (address => mapping (uint8 => uint)) private dailyROIBal;
    
    event onInvest(address investor, address referrer, uint8 plan, uint amount, uint time);
    event onWithdraw(address investor, uint amount, uint time);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }
    
     modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
        
        init();
        currentId = currentId.add(1);
        userList[currentId] = admin;
        userDetails[admin].isExist = true;
        userDetails[admin].userId = currentId;
    }
    
    function init() internal  {
        
        planDetails[1].plan = 1;
        planDetails[1].durationPeriod = 30 days;
        planDetails[1].minInvestment = 0.10 trx;
        planDetails[1].ROIPercentage = 3.67 trx;
        
        planDetails[2].plan = 2;
        planDetails[2].durationPeriod = 60 days;
        planDetails[2].minInvestment = 10000 trx;
        planDetails[2].ROIPercentage = 2.17 trx;
        
        planDetails[3].plan = 3;
        planDetails[3].durationPeriod = 90 days;
        planDetails[3].minInvestment = 100000 trx;
        planDetails[3].ROIPercentage = 1.78 trx;
        
        planDetails[4].plan = 4;
        planDetails[4].durationPeriod = 180 days;
        planDetails[4].minInvestment = 1000000 trx;
        planDetails[4].ROIPercentage = 1.56 trx;
        
        uplinePercentage[0] = 10 trx;
        uplinePercentage[1] = 7.5 trx;
        uplinePercentage[2] = 5 trx;
        uplinePercentage[3] = 2.5 trx;
        
        refPercentage[0] = 5 trx;
        refPercentage[1] = 2 trx;
        refPercentage[2] = 0.5 trx;
    }
    
    function adminDeposit() public onlyAdmin payable returns(bool) {
        require(msg.value > 0, "Invalid Amount");
        admindDepositBalance=admindDepositBalance.add(msg.value);
        return true;
    }
 
    function invest(uint8 _plan, address _referrer) isLock public payable {
        require(_plan >= 1 && _plan <= 4, "Invalid Plan");
        require(_referrer != msg.sender, "Self Refferer Not Allowed");
        require(msg.value >= planDetails[_plan].minInvestment, "Invalid Investment");
        
        if(_referrer != address(0))
            require(userDetails[_referrer].isExist == true, "Referrer Not Exists" );
            
        if(userDetails[msg.sender].isExist ==  false) {
                
            // check 
            address UserAddress = msg.sender;
            uint32 size;
            assembly {
                size := extcodesize(UserAddress)
            }
            require(size == 0, "cannot be a contract");
        
            currentId = currentId.add(1);
            userDetails[msg.sender].isExist = true;
            userDetails[msg.sender].userId = currentId;
            userDetails[msg.sender].referrer = _referrer;
            userList[currentId] = msg.sender;
            userDetails[msg.sender].invest[_plan].lastPayOutTime = now;
            
        
            if(_referrer != address(0)) {
                userDetails[_referrer].refCount = userDetails[_referrer].refCount.add(1);
                
                if(userDetails[_referrer].refCount == 1) {
                    userDetails[_referrer].refEarnings = userDetails[_referrer].refEarnings.add(refBalCalc(msg.value,0,1));
                    userDetails[_referrer].totalAvailRefBalance = userDetails[_referrer].totalAvailRefBalance.add(refBalCalc(msg.value,0,1));
                }
                if(userDetails[_referrer].refCount == 2) {
                     userDetails[_referrer].refEarnings = userDetails[_referrer].refEarnings.add(refBalCalc(msg.value,1,1));
                     userDetails[_referrer].totalAvailRefBalance = userDetails[_referrer].totalAvailRefBalance.add(refBalCalc(msg.value,1,1));
                }
                if(userDetails[_referrer].refCount >= 3) {
                     userDetails[_referrer].refEarnings = userDetails[_referrer].refEarnings.add(refBalCalc(msg.value,2,1));
                     userDetails[_referrer].totalAvailRefBalance = userDetails[_referrer].totalAvailRefBalance.add(refBalCalc(msg.value,2,1));
                }
            }
        }
        
        
        if(_plan == 4) {
            address[4] memory uplines;
            
            uplines[0] = userDetails[msg.sender].referrer;
            uplines[1] = userDetails[uplines[0]].referrer;
            uplines[2] = userDetails[uplines[1]].referrer;
            uplines[3] = userDetails[uplines[2]].referrer;
            
            if(uplines[0] != address(0)) {
                userDetails[uplines[0]].invest[_plan].firstLineRef.push(msg.sender);
                userDetails[uplines[0]].refEarnings = userDetails[uplines[0]].refEarnings.add(refBalCalc(msg.value,0,2));
                userDetails[uplines[0]].totalAvailRefBalance = userDetails[uplines[0]].totalAvailRefBalance.add(refBalCalc(msg.value,0,2));                    
            }
            else if(uplines[1] != address(0)) {
                userDetails[uplines[1]].invest[_plan].secondLineRef.push(msg.sender);
                userDetails[uplines[0]].refEarnings = userDetails[uplines[0]].refEarnings.add(refBalCalc(msg.value,1,2));
                userDetails[uplines[0]].totalAvailRefBalance = userDetails[uplines[0]].totalAvailRefBalance.add(refBalCalc(msg.value,1,2));                    
            }
            else if(uplines[2] != address(0)) {
                userDetails[uplines[2]].invest[_plan].thirdLineRef.push(msg.sender);
                userDetails[uplines[0]].refEarnings = userDetails[uplines[0]].refEarnings.add(refBalCalc(msg.value,2,2));
                userDetails[uplines[0]].totalAvailRefBalance = userDetails[uplines[0]].totalAvailRefBalance.add(refBalCalc(msg.value,2,2));                    
            }
            else if(uplines[3] != address(0)) {
                userDetails[uplines[3]].invest[_plan].fourthLineRef.push(msg.sender);
                userDetails[uplines[0]].refEarnings = userDetails[uplines[0]].refEarnings.add(refBalCalc(msg.value,3,2));
                userDetails[uplines[0]].totalAvailRefBalance = userDetails[uplines[0]].totalAvailRefBalance.add(refBalCalc(msg.value,3,2));                    
            }
        }
    
    
        userDetails[msg.sender].invest[_plan].investedTime = now;
        dailyROIBal[msg.sender][_plan] = dailyROIBal[msg.sender][_plan].add(getAvailROI(_plan));
        userDetails[msg.sender].invest[_plan].lastPayOutTime = now;
        investBal[msg.sender][_plan] = investBal[msg.sender][_plan].add(msg.value);
        totalInvest = totalInvest.add(msg.value);
        userDetails[msg.sender].invest[_plan].isExpired =  false;
        
        emit onInvest(msg.sender, _referrer, _plan, msg.value, userDetails[msg.sender].invest[_plan].investedTime);
    
    }
    
    function refBalCalc(uint _value, uint8 _line, uint8 _flag) internal returns(uint) {
        if(_flag == 1)
            return (_value.mul(refPercentage[_line])).div(10**8);
        
        if(_flag == 2)
            return (_value.mul(uplinePercentage[_line])).div(10**8);
    }
    
    function getAvailROI(uint8 _plan) isLock public view returns(uint) {
        uint256 result = 0;
        
        if(investBal[msg.sender][_plan] > 0) {
            
            uint256 numberOfDays =  (now.sub(userDetails[msg.sender].invest[_plan].lastPayOutTime)) / 1 days ;
            uint256 secondsLeft = (now.sub(userDetails[msg.sender].invest[_plan].lastPayOutTime));
            uint256 index = 0;
            
            if(numberOfDays > 0){
                
                for (index; index < numberOfDays; index++) {
                    secondsLeft = secondsLeft.sub(1 days);
                    result = result.add(( investBal[msg.sender][_plan].mul( (planDetails[_plan].ROIPercentage)) / (1*10**8) * 1 days) / (60*60*24));
                }
                
                result = result.add(( investBal[msg.sender][_plan].mul( (planDetails[_plan].ROIPercentage)) / (1*10**8) * secondsLeft) / (60*60*24));
                result = result.add(dailyROIBal[msg.sender][_plan]);
            }
            else {
                result = result.add( (investBal[msg.sender][_plan].mul( planDetails[_plan].ROIPercentage) / (1*10**8) * secondsLeft) / (60*60*24));
                result = result.add(dailyROIBal[msg.sender][_plan]);
            } 
        }
            
        return result;
    }
    
    function withDraw() isLock public returns(bool) {
        require(userDetails[msg.sender].isExist==true, "Not Exist");
        
        uint _availROI;
        
        for(uint8 i=1; i<=4; i++) {
        
            uint _investTime = userDetails[msg.sender].invest[i].investedTime;
            uint _duration =  planDetails[i].durationPeriod;
                
            if(investBal[msg.sender][i] > 0) {
                _availROI = _availROI.add(getAvailROI(i));
                userDetails[msg.sender].invest[i].lastPayOutTime = now;
            }
            
            if(_investTime > 0 && _investTime.add(_duration) <= now ) {
                userDetails[msg.sender].invest[i].isExpired = true;
                investBal[msg.sender][i] = 0;
            }
            
        }
        
        uint withdrawAmount = _availROI.add(userDetails[msg.sender].totalAvailRefBalance);
        require(msg.sender.send(withdrawAmount), "Transaction Failed");
        userDetails[msg.sender].totalAvailRefBalance = 0;
        
        emit onWithdraw(msg.sender, withdrawAmount, now);
        return true;
    }
    
    function getContractBalance() public view returns(uint) {
        return(address(this).balance);
    }
    
    function getInvestDetails(address _investor, uint8 _plan) public view returns(bool,uint,uint){
        return (userDetails[_investor].invest[_plan].isExpired,
            userDetails[_investor].invest[_plan].investedTime,
            userDetails[_investor].invest[_plan].lastPayOutTime);
            
    }
    
    function getDownlineDetails(address _investor, uint8 _plan) public view returns(address[] memory, address[] memory, address[] memory, address[] memory){
        return (userDetails[_investor].invest[_plan].firstLineRef, userDetails[_investor].invest[_plan].secondLineRef,
            userDetails[_investor].invest[_plan].thirdLineRef, userDetails[_investor].invest[_plan].fourthLineRef);
            
    }
    
    function failSafe(address payable _toUser, uint _amount) public onlyAdmin returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    function contractLock(bool _lockStatus) public onlyAdmin returns (bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
}