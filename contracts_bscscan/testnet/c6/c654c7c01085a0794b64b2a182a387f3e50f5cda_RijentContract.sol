/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.10;

interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RijentContract {    
    address private owner;
    uint  calculteDecimal = 9;
    uint  calculteValue   = 386;
    uint public MIN_DEPOSIT = 10 ;
    uint public MAX_DEPOSIT = 40000 ;

    uint packageWithdrawCount    = 0;
    uint packageLastWithdrawDate = 0;
    address private contractAddr = address(this);
    bool private claimStatus;
    bool private depositStatus;
    uint public totalUsers;

    BEP20 token;
    struct Package {
        address walletAddr; 
        uint packageAmt; 
        uint lockingType;
        uint packagePer; 
        uint packageDate; 
        uint packageExpiry; 
        uint packagetimeDiff; 
        uint packageForMonth; 
        uint packageWithdrawCount; 
        uint packageLastWithdrawDate; 
    }
    struct User {
        bool registered;
        uint totalInvestAmount; 
        uint balance; 
        uint withdrawRoi; 
        uint withdrawPrinciple; 
        Package[] packages;
    }
    Package[] packages;
    mapping(address => User) private user;
    mapping(address => Package) private package;
    event Received(address, uint);
    event UserRegistered(address user);
    event DepositAt(address user, uint packageAmt, uint lockingType, uint packagePer, uint packageDate, uint packageExpiry, uint timeDiff, uint packageForMonth, uint packageWithdrawCount, uint packageLastWithdrawDate);
    constructor() {
        token         = BEP20(0x1C3E03875839009dd6dE9eA0aAc4bD516e61cA71); // RTC Token
        claimStatus   = false;
        owner         = msg.sender;
        depositStatus = true;
    }    
    // Deposit Boutspro token for Bouts9 allocation
    function deposit(uint amount, uint lockingType) public {
        require( (amount >= (MIN_DEPOSIT* 10**18 )), "Minimum limit is 10");
        require( (amount <= (MAX_DEPOSIT* 10**18 )), "Maximum limit is 40000");
        require(depositStatus == true, "Deposit not enabled");
        address sender = msg.sender;
        uint time      = block.timestamp;
        uint contractAmt = amount ;
        amount           = amount / 10**18;
        
        User storage dep  = user[sender];
        ////User Struct update
        dep.registered         = true;
        dep.totalInvestAmount += amount;
        
        ////Package Struct update
        uint packagePer       = 0;
        uint packageForMonth  = 0;
        uint packageExpiry    = 0;

        if(lockingType==0){
            packagePer      = 3;
            packageForMonth = 12;
            packageExpiry   = time + (1 hours); 
        }
        else if(lockingType==1){
            packagePer      = 4;
            packageForMonth = 18;
            packageExpiry   = time + (2 hours);
        }
        else if(lockingType==2){
            packagePer       = 5;
            packageForMonth  = 24;
            packageExpiry    = time + ( 3 hours);
        }
        else if(lockingType==3){
            packagePer      = 7;
            packageForMonth = 36;
            packageExpiry   = time + (4 hours);
        }
        else{
            packagePer      = 9;
            packageForMonth = 60;
            packageExpiry   = time + (5 hours);
        }
        uint timeDiff     = time- packageExpiry;
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        token.transferFrom(sender, contractAddr, contractAmt );
        totalUsers++;
        dep.packages.push( Package( sender, amount, lockingType, packagePer, time, packageExpiry, timeDiff, packageForMonth,packageWithdrawCount,packageLastWithdrawDate ) );		
        emit DepositAt(sender, amount, lockingType, packagePer, time, packageExpiry, timeDiff, packageForMonth,packageWithdrawCount,packageLastWithdrawDate);
    }
    ////get packages
    function getPackages(address addr) external view returns(Package[] memory) {
        User storage userData = user[addr];
        return userData.packages;
    }
    // calculate roi depends on your invest
    function roiCalculate(address addr) public view returns (uint totalInvest,uint roiAmount, uint withdrawRoi, uint withdrawablePrinciple, uint withdrawPrinciple) {
        User storage userData = user[addr];
        roiAmount   = 0;
        totalInvest = 0;
        withdrawRoi = 0;
        withdrawablePrinciple = 0;
        for (uint i = 0; i < userData.packages.length; i++) {
            Package storage dep = userData.packages[i];
            totalInvest      += dep.packageAmt;
            uint timeDiff     = block.timestamp- dep.packageDate;
            uint maxTime      = dep.packagetimeDiff;
            if( maxTime >= timeDiff ){
                roiAmount          += (  dep.packageAmt * timeDiff*calculteValue*dep.packagePer)/( 10**calculteDecimal );
            }else{
                uint withdrawDaysDiff = (block.timestamp - dep.packageLastWithdrawDate) / 60 / 60 / 24; // 40 days 
                uint withMultiplier   = 0; 
                if( withdrawDaysDiff >=7 && withdrawDaysDiff <14 ){
                    withMultiplier    = 1;
                }else if( withdrawDaysDiff >=14 && withdrawDaysDiff <21 ){
                    withMultiplier    = 2;
                }else if( withdrawDaysDiff >=21 && withdrawDaysDiff <28 ){
                    withMultiplier    = 3;
                }else if( withdrawDaysDiff >=28 && withdrawDaysDiff <35 ){
                    withMultiplier    = 4;
                }else if( withdrawDaysDiff >=35 && withdrawDaysDiff <42 ){
                    withMultiplier    = 5;
                }else if( withdrawDaysDiff >=42 && withdrawDaysDiff <49 ){
                    withMultiplier    = 6;
                }else if( withdrawDaysDiff >=49 && withdrawDaysDiff <56 ){
                    withMultiplier    = 7;
                }else if( withdrawDaysDiff >=56 && withdrawDaysDiff <63 ){
                    withMultiplier    = 8;
                }else if( withdrawDaysDiff >=63 && withdrawDaysDiff <70 ){
                    withMultiplier    = 9;
                }else if( withdrawDaysDiff >=70 ){
                    withMultiplier    = 10;
                }                 
                withdrawablePrinciple     +=  (dep.packageAmt* 10*withMultiplier)/100 ;              
            }            
        }        
        withdrawRoi        = userData.withdrawRoi;
        withdrawPrinciple  = userData.withdrawPrinciple;
    }  
    ////withdrawal roi
    function roiWithdraw() external returns (bool) {
        BEP20 _token      = BEP20(token);
        address sender = msg.sender;
        uint roiAmount = 0;
        User storage userData = user[sender];
        for (uint i = 0; i < userData.packages.length; i++) {
            Package storage dep = userData.packages[i];
            uint timeDiff     = block.timestamp- dep.packageDate;
            uint maxTime      = dep.packagetimeDiff;
            if( maxTime >= timeDiff ){
                roiAmount         += (  dep.packageAmt * timeDiff*calculteValue*dep.packagePer)/( 10**calculteDecimal );            
            }
        }
        uint withAmt      = roiAmount-userData.withdrawRoi;
        uint donewithdrawRoi   = userData.withdrawRoi+withAmt;
        userData.withdrawRoi    = donewithdrawRoi;        
        userData.balance        = userData.totalInvestAmount + roiAmount-donewithdrawRoi ;

        _token.transfer(sender, withAmt * 10**18 );
        return true;
    }  
    // calculate Invest withdrawal after time over
    function investrWithdrawCalculate(address addr) public view returns (uint totalInvest,uint roiAmount, uint withdrawRoi) {
        User storage userData = user[addr];
        roiAmount   = 0;
        totalInvest = 0;
        withdrawRoi = 0;
        for (uint i = 0; i < userData.packages.length; i++) {
            Package storage dep = userData.packages[i];
            totalInvest      += dep.packageAmt;
            uint timeDiff     = block.timestamp- dep.packageDate;
            uint maxTime      = dep.packagetimeDiff;
            if( maxTime >= timeDiff ){
                roiAmount         += (  dep.packageAmt * timeDiff*calculteValue*dep.packagePer)/( 10**calculteDecimal );
            }            
        }
        withdrawRoi  = userData.withdrawRoi;
    } 
    // Set depositStatus
    function setDepositStatus(bool val) public {
        require(msg.sender == owner, "Only owner");
        depositStatus = val;
    }
    // View deposit status 
    function getDepositStatus() public view returns(bool) {
        return depositStatus;
    }    
    // View Deposit Amount
    function getDepositAmount(address addr) public view returns (uint) {
        return user[addr].totalInvestAmount;
    }    
    // View owner 
    function getOwner() public view returns (address) {
        return owner;
    } 
    // Transfer ownership 
    // Only owner can call 
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
    }    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }    
    // Owner BNB withdrawal
    function ownerBnbWithdraw(uint amount) public {
        require(msg.sender == owner, "Only owner can call this function");
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }    
    // Set minimum buy token
    function setMinDeposit(uint _minAmt) public {
      require(msg.sender == owner, "Only owner");
      MIN_DEPOSIT = _minAmt;
    }
    // Set maximum buy token
    function setMaxDeposit(uint _maxAmt) public {
      require(msg.sender == owner, "Only owner");
      MAX_DEPOSIT = _maxAmt;
    }
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}