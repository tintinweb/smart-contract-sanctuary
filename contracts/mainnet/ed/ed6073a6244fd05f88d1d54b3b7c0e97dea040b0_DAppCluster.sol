/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: MIT

/**
 *  Program Name    : DAppCluster
 *  Website         : https://dappcluster.com/
 *  Telegram        : https://t.me/dappcluster
 *  Concept         : High Return On Investment Contract
 *  Category        : Passive Income
 *  Risk Category   : High Risk
 **/

pragma solidity >=0.6.0 <0.8.1;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract DAppCluster  is Ownable {
    using SafeMath for uint256;
    
    //Custom datatype to store investment details
    struct Investment {
        uint256 investmentAmount;
        uint256 interestEarned;
        uint256 investmentDate;
        uint256 referralBonus;
        uint256 expiryDate;
        bool isExpired;
        
        uint256 level1RefId;
        uint256 level2RefId;
        uint256 level3RefId;
    }
    
    uint256 public constant DEVELOPER_FEES = 4;
    uint256 public constant MARKETING_FEES = 4;
    uint256 public constant REFERRAL_LEVEL1_RATE = 8;
    uint256 public constant REFERRAL_LEVEL2_RATE = 4;
    uint256 public constant REFERRAL_LEVEL3_RATE = 2;
    uint256 public constant MINIMUM_INVESTMENT = 10000000000000000;
    uint256 public constant DAILY_INTEREST = 2;
    uint256 public constant HARD_LOCKPERIOD_DAYS = 50;
    uint256 public constant SOFT_LOCKPERIOD_DAYS = 11;
    uint256 private constant START_USERCODE = 1000;
    
    uint256 private latestUserCode;
    uint256 private totalInvestment;
    uint256 private totalWithdrawal;
    uint256 private totalInterestPaid;
    uint256 private totalReferralBonusPaid;
    
    address private developerAccount;
    address private marketingAccount;
    
    // mapping to store UserId of address
    mapping(address => uint256) private UID;
    
    // mapping to store investment details of UserId
    mapping(uint256 => Investment) private investment;
    
    // events to log action
    event onInvest(address investor, uint256 amount, uint256 referral_Level1, uint256 referral_Level2, uint256 referral_Level3);
    event onWithdraw(address investor, uint256 amount, uint256 interest, uint256 referralBonus, uint256 totalAmount);
    
    // constructor to initiate variables
    constructor() {
        
        latestUserCode = START_USERCODE;
        
    }
    
    // function to get UserID if address is already part of system and generate new UserId if address is new in system
    function getUserID(address _addr) internal returns(uint256 UserId){
        uint256 uid = UID[_addr];
        
        if (uid == 0){
            latestUserCode = latestUserCode.add(1);
            UID[_addr] = latestUserCode;
            uid = latestUserCode;
        }
        
        return uid;
    }
    
    // function to change marketing account
    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner returns(bool) {
        require(_newMarketingAccount != address(0));
        
        // marketing account able to withdraw bonus without locking as this money needs to pay for advertising & enhancement
        
        uint256 uid = getUserID(_newMarketingAccount);
        
        // make sure marketing account has not invested because locking doesn't get applied on it and eligible only to get bonus
        require(investment[uid].investmentAmount == 0);
        
        marketingAccount = _newMarketingAccount;
        
        return true;
    }
    
    // function to get marketing account
    function getMarketingAccount() public view returns (address) {
        return marketingAccount;
    }
    
    // function to change developer account
    function setDeveloperAccount(address payable _newDeveloperAccount) public onlyOwner returns(bool) {
        require(_newDeveloperAccount != address(0));
        
        // developer account able to withdraw bonus without locking as this money needs to pay for advertising & enhancement
        uint256 uid = getUserID(_newDeveloperAccount);
        
        // make sure developer account has not invested because locking doesn't get applied on it and eligible only to get bonus
        require(investment[uid].investmentAmount == 0);
        
        developerAccount = _newDeveloperAccount;
        
        return true;
    }
    
    // function to get developer account
    function getDeveloperAccount() public view returns (address) {
        return developerAccount;
    }
    
    // function to get contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // fallback function to handle accidently send investment
    fallback() payable external{
        _invest(msg.sender, 0, msg.value);
    }
    
    // receive function to handle received coin
    receive() payable external{
        _invest(msg.sender, 0, msg.value);
    }
    
    // invest function to handle investment using referral code
    function invest(uint256 _referrerCode) public payable{
        _invest(msg.sender, _referrerCode, msg.value);
    }
    
    // _invest function to process received investment
    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) internal returns(bool){
     
        require(_amount >= MINIMUM_INVESTMENT, "Less than the minimum amount of deposit requirement");
        
        // Restricting marketing & developer account from investment as locking doesn't get applied on it and they can only earn bonus
        require(_addr != marketingAccount && _addr != developerAccount, "Marketing & Developement Account Are Not Allowed To Invest");
     
        uint256 uid = getUserID(_addr);
        
        // assign development fees & marketing fees as bonus
        investment[UID[developerAccount]].referralBonus = investment[UID[developerAccount]].referralBonus.add(_amount.mul(DEVELOPER_FEES).div(100));
        investment[UID[marketingAccount]].referralBonus = investment[UID[marketingAccount]].referralBonus.add(_amount.mul(MARKETING_FEES).div(100));
        
        // assign referral level if user invested via referral link
        if (_referrerCode != 0 && _referrerCode != uid && investment[uid].investmentAmount == 0){
            
            investment[uid].level1RefId = _referrerCode;
            
            if (investment[_referrerCode].level1RefId !=0){
                investment[uid].level2RefId = investment[_referrerCode].level1RefId;
                
                if (investment[_referrerCode].level2RefId != 0){
                    investment[uid].level3RefId = investment[_referrerCode].level2RefId;
                }
                else{
                    investment[uid].level3RefId = 0;
                }
            }
            else{
                investment[uid].level2RefId = 0;
                investment[uid].level3RefId = 0;
            }
        }
        
        // assign level1 referral bonus only if still invested in system
        if (investment[uid].level1RefId != 0 && (investment[uid].level1RefId > START_USERCODE && investment[uid].level1RefId <= latestUserCode) && investment[investment[uid].level1RefId].isExpired != true){
            investment[investment[uid].level1RefId].referralBonus = investment[investment[uid].level1RefId].referralBonus.add(_amount.mul(REFERRAL_LEVEL1_RATE).div(100));    
                
            // Assign Level2 Referral Bonus Only If Level1 & Level2 Still Invested In System
            if (investment[uid].level2RefId != 0 && (investment[uid].level2RefId > START_USERCODE && investment[uid].level2RefId <= latestUserCode) && investment[investment[uid].level2RefId].isExpired != true){
                investment[investment[uid].level2RefId].referralBonus = investment[investment[uid].level2RefId].referralBonus.add(_amount.mul(REFERRAL_LEVEL2_RATE).div(100));    
                    
                // Assign Level3 Referral Bonus Only If Level1, Level2 & Level3 Still Invested In System
                if (investment[uid].level3RefId != 0 && (investment[uid].level3RefId > START_USERCODE && investment[uid].level3RefId <= latestUserCode) && investment[investment[uid].level3RefId].isExpired != true){
                    investment[investment[uid].level3RefId].referralBonus = investment[investment[uid].level3RefId].referralBonus.add(_amount.mul(REFERRAL_LEVEL3_RATE).div(100));    
                }
            }
        }
        
        // if user is already part of system & investing additional fund then calculate interest for previous investment and update balance with new fund 
        if (investment[uid].isExpired != true && investment[uid].investmentAmount != 0){
            uint256 day = block.timestamp.sub(investment[uid].investmentDate).div(60).div(60).div(24);
            investment[uid].interestEarned = investment[uid].interestEarned.add(investment[uid].investmentAmount.mul(DAILY_INTEREST).div(100).mul(day));
        }
        
        // if user is already part of system with endParticipation & investing additional fund then calculate interest for previous investment and update balance with new fund 
        if (investment[uid].isExpired == true && investment[uid].investmentAmount != 0){
            uint256 day = investment[uid].expiryDate.sub(investment[uid].investmentDate).div(60).div(60).div(24);
            investment[uid].interestEarned = investment[uid].interestEarned.add(investment[uid].investmentAmount.mul(DAILY_INTEREST).div(100).mul(day));
        }
            
        investment[uid].investmentAmount = investment[uid].investmentAmount.add(_amount);
        
        // update investment date & activate participation
        investment[uid].investmentDate = block.timestamp;
        investment[uid].expiryDate = 0;
        investment[uid].isExpired = false;
        
        totalInvestment = totalInvestment.add(_amount);
        
        emit onInvest(_addr, _amount, investment[uid].level1RefId, investment[uid].level2RefId, investment[uid].level3RefId);
        
        return true;
    }
    
    // endParticipation function to apply for SOFT_LOCKPERIOD
    function endParticipation() public returns(bool){
        address _addr = msg.sender;
        uint256 uid = UID[_addr];
        uint256 day = block.timestamp.sub(investment[uid].investmentDate).div(60).div(60).div(24);
        
        // user must be part of system
        require(uid != 0);
        
        // check HARD_LOCKPERIOD if finished
        require(day > HARD_LOCKPERIOD_DAYS, "Hard locking period is not finished");
        
        // enable SOFT_LOCKPERIOD and update time
        investment[uid].isExpired = true;
        investment[uid].expiryDate = block.timestamp;
        
        return true;
    }
    
    // withdraw function to get investmentAmount, interest, referralBonus after SOFT_LOCKPERIOD completion
    function withdraw() public returns(bool){
        address _addr = msg.sender;
        uint256 uid = UID[_addr];
        uint256 day = 0 ;
        
        // user must be part of system
        require(uid != 0);
        
        // locking is not applicable on marketing & developer account and they will be only eligible to withdraw bonus.
        // Investement using Developement & marketing accounts are restricted via _invest function
        
        if (_addr != developerAccount && _addr != marketingAccount){
            // check SOFT_LOCKPERIOD is enabled
            require(investment[uid].isExpired == true, "End participation & wait for soft locking period before withdrawing");
            require(investment[uid].expiryDate != 0, "End participation & wait for soft locking period before withdrawing");
        
            day = block.timestamp.sub(investment[uid].expiryDate).div(60).div(60).div(24);
        
            // check SOFT_LOCKPERIOD is completed
            require(day > SOFT_LOCKPERIOD_DAYS,"Wait for soft locking period before withdrawing");
        }
        
        uint256 amountToSend;
        
        // calculate days to pay interest
        day = investment[uid].expiryDate.sub(investment[uid].investmentDate).div(60).div(60).div(24);
        
        //calculate amount to pay
        uint256 interest = investment[uid].investmentAmount.mul(DAILY_INTEREST).div(100).mul(day);
        amountToSend = investment[uid].investmentAmount.add(investment[uid].interestEarned).add(investment[uid].referralBonus).add(interest);
        
        // set global variables to keep record of totalWithdrawal, totalInterestPaid & totalReferralBonusPaid
        totalWithdrawal = totalWithdrawal.add(investment[uid].investmentAmount);
        totalInterestPaid = totalInterestPaid.add(investment[uid].interestEarned).add(interest);
        totalReferralBonusPaid = totalReferralBonusPaid.add(investment[uid].referralBonus);
        
        // log event for withdrawal
        emit onWithdraw(_addr, investment[uid].investmentAmount, interest.add(investment[uid].interestEarned), investment[uid].referralBonus, amountToSend);
        
        // update user balance details
        investment[uid].investmentAmount = 0;
        investment[uid].interestEarned = 0;
        investment[uid].investmentDate = 0;
        investment[uid].referralBonus = 0;
        investment[uid].expiryDate = 0;
        investment[uid].isExpired = false;
        
        // transfer fund to user wallet
        payable(address(_addr)).transfer(amountToSend);
        
        return true;
    }
    
    // function to get user balance ddetails
    function getUserInformation(address _walletAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool){
        require(msg.sender == _walletAddress || msg.sender == owner(),"User can only check own balance");
        
        uint256 investmentAmount;
        uint256 interestEarned;
        uint256 referralBonus;
        uint256 investmentDate;
        uint256 expiryDate;
        bool isExpired;
        uint day;
        
        address _addr = _walletAddress;
        
        uint256 uid = UID[_addr];
        
        investmentAmount = investment[uid].investmentAmount;
        
        // calculate days invested
        if (investment[uid].isExpired != true){
            day = block.timestamp.sub(investment[uid].investmentDate).div(60).div(60).div(24);
        }
        
        if (investment[uid].isExpired == true){
            day = investment[uid].expiryDate.sub(investment[uid].investmentDate).div(60).div(60).div(24);
        }
        
        // calculate interest earned
        interestEarned = investment[uid].interestEarned.add(investment[uid].investmentAmount.mul(DAILY_INTEREST).div(100).mul(day));
        referralBonus = investment[uid].referralBonus;
        investmentDate = investment[uid].investmentDate;
        expiryDate = investment[uid].expiryDate;
        isExpired = investment[uid].isExpired;
        
        return (uid, investmentAmount, interestEarned, referralBonus, investmentDate, expiryDate, isExpired);
    }
    
    // function to get contract holding details
    function getContractInformation() public view returns(uint256, uint256, uint256, uint256, uint256, uint256){
        uint256 contractBalance;
        contractBalance = address(this).balance;
        
        return (contractBalance, totalInvestment, totalWithdrawal, totalInterestPaid, totalReferralBonusPaid, latestUserCode - START_USERCODE);
    }
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}