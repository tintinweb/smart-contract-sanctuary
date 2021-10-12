/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface BEP20 {
             function totalSupply() external view returns (uint theTotalSupply);
             function balanceOf(address _owner) external view returns (uint balance);
             function transfer(address _to, uint _value) external returns (bool success);
             function transferFrom(address _from, address _to, uint _value) external returns (bool success);
             function approve(address _spender, uint _value) external returns (bool success);
             function allowance(address _owner, address _spender) external view returns (uint remaining);
             event Transfer(address indexed _from, address indexed _to, uint _value);
             event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface SALE {
    function showSaleStatus() external view returns (bool);
    function viewSaleEndTime() external view returns(uint);
    function userBuyStatus(address) external view returns (bool);
}

contract gameZillaStaking {
    
    /// Variables
    struct Stake {
        bool staked;
        Deposit[] deposits;
        uint topTier;
    }
    
    struct Tier {
        uint time;
        uint percent;
        uint endTime;
    }
    
    struct Deposit {
        uint tier;
        uint amount;
        uint at;
        bool withdrawn;
    }
    
    Tier[] public tiers;
    address public owner = msg.sender;
    address public stakeTokenAddr = 0x3cc97b7fcE42d372d3f5f08ED8121245B1a66fFF;
    address public buyTokenAddr;
    address public contractAddr = address(this);
    mapping(address => Stake) public user;
    bool private stakeStatus;
    uint tier1count;
    uint tier2count;
    uint tier3count;
    uint tier4count;
    
   
    address[] public saleAddressArr;
    event Received(address, uint);
    event Staked(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets stake status to true to enable staking 
     */
    constructor() {
        /*tiers.push(Tier(365 days, 40, 14 days));
        tiers.push(Tier(365 days, 100, 30 days));
        tiers.push(Tier(365 days, 150, 90 days));
        tiers.push(Tier(365 days, 200, 180 days));*/
        tiers.push(Tier(365 days, 40, 5 minutes));
        tiers.push(Tier(365 days, 100, 10 minutes));
        tiers.push(Tier(365 days, 150, 15 minutes));
        tiers.push(Tier(365 days, 200, 20 minutes));
        
        stakeStatus = true;
    }
    
    /**
     * @dev Start or stop staking
     * 
     * Requirements: 
     * 
     * Only owner can change the state 
     */
    function setStakeStatus(bool state) public {
        require(msg.sender == owner, "Only owner");
        stakeStatus = state;
    }
    
    /**
     * @dev Stake tokens on the contract
     * 
     * Requirements:
     * Minimum amount to stake is 650 tokens 
     * timestamp has to be between start and end time 
     */
    function stake(uint amount) public returns(bool) {
        
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
        
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        require(stakeStatus == true, "Staking disabled");
        require(amount >= 5000 * 10**18, "Stake minimum 5000 tokens");
        
        token.approve(contractAddr, amount);
        token.transferFrom(sender, contractAddr, amount);
        
        uint previousCount = user[sender].topTier;
        
        if(amount >= 5000*10**18 && amount < 25000*10**18){
            user[sender].deposits.push(Deposit(0, amount, block.timestamp, false));
            if(user[sender].topTier > 0){
                user[sender].topTier = user[sender].topTier;
            }
            else{
                if(user[sender].staked == false){
                    tier1count += 1;
                    user[sender].topTier = 0;
                }
            }
        }
        
        else if(amount >= 25000*10**18 && amount < 100000*10**18){
            user[sender].deposits.push(Deposit(1, amount, block.timestamp, false));
            if(user[sender].topTier < 1){
                user[sender].topTier =1;
                if(user[sender].staked == false){
                    tier2count += 1;
                }
                else{
                    tier1count -= 1;
                    tier2count += 1;
                }
            }
            if(user[sender].topTier > 1){
                user[sender].topTier = user[sender].topTier;
            }
        }
        
        else if(amount >= 100000*10**18 && amount < 250000*10**18){
            user[sender].deposits.push(Deposit(2, amount, block.timestamp, false));
            if(user[sender].topTier < 2){
                user[sender].topTier =2;
                if(user[sender].staked == false){
                    tier3count += 1;
                }
                else{
                    if(previousCount == 0){
                        tier1count -= 1;
                        tier3count += 1;
                    }
                    else if(previousCount == 1){
                        tier2count -= 1;
                        tier3count += 1;
                    }
                    
                }
            }
            if(user[sender].topTier > 2){
                user[sender].topTier = user[sender].topTier;
            }
        }
        
        else if(amount >= 250000*10**18){
            user[sender].deposits.push(Deposit(3, amount, block.timestamp, false));
            if(user[sender].topTier < 3){
                user[sender].topTier =3;
                if(user[sender].staked == false){
                    tier4count += 1;
                }
                else{
                    if(previousCount == 0){
                        tier1count -= 1;
                        tier4count += 1;
                    }
                    else if(previousCount == 1){
                        tier2count -= 1;
                        tier4count += 1;
                    }
                    else if(previousCount == 2){
                        tier3count -= 1;
                        tier4count += 1;
                    }
                    
                }
            }
            else{
                user[sender].topTier = user[sender].topTier;
            }
        }
        
        user[sender].staked = true;
        emit Staked(sender, amount);
        return true;
    }
    
    /** 
     * @dev Set address for SALE interface
     * 
     * Requirements:
     * 
     * Only owner can call this function
     */
    function setSaleInterfaceAddress(address saleAddr) public {
        require(msg.sender == owner, "Only owner");
        saleAddressArr.push(saleAddr);
    }
    
    function userEndTime(address useAddr, uint userIndex) public view returns(uint){
        Stake storage stake_ = user[useAddr];
        Deposit storage dep = stake_.deposits[userIndex];
        Tier storage tier = tiers[dep.tier];
        uint endTime = dep.at + tier.endTime;
        if(saleAddressArr.length > 0){
            for(uint i = 0;  i < saleAddressArr.length; i++){
                address saleAddr = saleAddressArr[i];
                SALE sale = SALE(saleAddr);   
                endTime =  (sale.userBuyStatus(useAddr) == true || sale.showSaleStatus() == true) ?  dep.at + tier.endTime : sale.viewSaleEndTime() ;
               
            }
        }
        return endTime;
        
    }
    
    
     /// Withdrawable view function
    function userEndTimeFunc(address uAddr, uint uIndex) public view returns(uint) {
        
        Stake storage stake_ = user[uAddr];
        Deposit storage dep = stake_.deposits[uIndex];
        Tier storage tier = tiers[dep.tier];
        uint endTime = 0;
        if(saleAddressArr.length > 0){
            for(uint i = 0;  i < saleAddressArr.length; i++){
                address saleAddr = saleAddressArr[i];
                SALE sale = SALE(saleAddr);   
                if(sale.userBuyStatus(uAddr) == true){
                   endTime = dep.at + tier.endTime;
                }
                else if(sale.showSaleStatus() == true){
                    endTime = (endTime==0) ? dep.at + tier.endTime : endTime;
                }
                else {
                    endTime = sale.viewSaleEndTime();
                }
            }
        }
        else {
            endTime = dep.at + tier.endTime;
        }
        return endTime;
    }
    
    /// Withdrawable view function
    function withdrawable(address addr, uint index) public view returns(uint amount) {
        
        Stake storage stake_ = user[addr];
        Deposit storage dep = stake_.deposits[index];
        Tier storage tier = tiers[dep.tier];
        uint end = userEndTimeFunc(addr,index);
        uint since = dep.at;
        if(dep.withdrawn == false){
            amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
        }
        else{
            amount = 0;
        }
       
    }
    
    function checkTierAmountWithdrawal() public view returns (bool){
        uint userTopTier_ = user[msg.sender].topTier;
        Stake storage stake_ = user[msg.sender];
        bool existInTier = false;
        for(uint i =0; i < stake_.deposits.length; i++){
            Deposit storage dep = stake_.deposits[i];
            uint tierNum = dep.tier;
            if(tierNum==userTopTier_ && dep.withdrawn==false){
                existInTier = true;
            }
        }
        
        return existInTier;
    }
    
     function checkTierAmountWithdrawal2(address addr) public view returns (bool,bool){
        uint userTopTier_ = user[addr].topTier;
        Stake storage stake_ = user[addr];
        bool existInTier = false;
        for(uint i =0; i < stake_.deposits.length; i++){
            Deposit storage dep = stake_.deposits[i];
            uint tierNum = dep.tier;
            if(tierNum==userTopTier_ && dep.withdrawn==false){
                existInTier = true;
            }
        }
        
        return (existInTier,existInTier);
    }
    
    
     function checkTierAmountWithdrawal3(uint index) public view returns (bool,uint,uint,bool,bool){
        uint userTopTier_ = user[msg.sender].topTier;
        Stake storage stake_ = user[msg.sender];
        bool existInTier = false;
            Deposit storage dep = stake_.deposits[index];
            uint tierNum = dep.tier;
            if(tierNum==userTopTier_ && dep.withdrawn==false){
                existInTier = true;
            }
        
        
        return (existInTier,userTopTier_,tierNum,dep.withdrawn,existInTier);
    }
    
    /// Withdraw 
    function withdraw(uint index) public returns (bool) {
        BEP20 token = BEP20(stakeTokenAddr);
        
        address addr = msg.sender;
        uint amount;
        require(user[addr].staked == true, "User has not staked");
        require(user[addr].deposits[index].withdrawn == false, "Already withdrawn");
        
        
        Stake storage stake_ = user[addr];
        Deposit storage dep = stake_.deposits[index];
        Tier storage tier = tiers[dep.tier];
        uint end = userEndTimeFunc(addr,index);
        
        uint since = dep.at;
        if(dep.withdrawn == false){
            amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
        }
        else{
            amount = 0;
        }
        
        require(block.timestamp >= end, "End Time not reached");
        token.transfer(addr, amount);
        user[addr].deposits[index].withdrawn = true;
        if(checkTierAmountWithdrawal()==false){
            uint userTopTier = user[msg.sender].topTier;
            if(userTopTier==0 && tier1count!=0){
                tier1count-=1;
            }
            else if(userTopTier==1 && tier2count!=0){
                tier2count-=1;
            }
            else if(userTopTier==2 && tier3count!=0){
                tier3count-=1;
            }
            else if(userTopTier==3 && tier4count!=0){
                tier4count-=1;
            }
        }
        return true;
        
    }
    
    /// View user details
    function details(address addr) public view returns(uint topTier_, uint[] memory amounts, uint[] memory times, bool[] memory status, bool[] memory claimBtnStatus, uint[] memory tier) {
        uint length = user[addr].deposits.length;
        topTier_ = user[addr].topTier;
        amounts = new uint[](length);
        times = new uint[](length);
        status = new bool[](length);
        claimBtnStatus = new bool[](length);
        tier = new uint[](length);
        for(uint i = 0; i < length; i++){
            
            Stake storage stake_ = user[addr];
            Deposit storage dep = stake_.deposits[i];
            amounts[i] = dep.amount;
            times[i] = dep.at;
            status[i] = dep.withdrawn;
            tier[i] = dep.tier;
            claimBtnStatus[i] = (block.timestamp > userEndTimeFunc(addr,i)) ? true : false;
        }
        
        return(topTier_, amounts, times, status,claimBtnStatus,tier);
    }
    
    /// Tier counts
    function tierCount1() public view returns (uint) {
        return tier1count;
    }
    
    function tierCount2() public view returns (uint) {
        return tier2count;
    }
    
    function tierCount3() public view returns (uint) {
        return tier3count;
    }
    
    function tierCount4() public view returns (uint) {
        return tier4count;
    }
    
    /// View presale status
    function presaleStatus(address saleAddr) public view returns(bool) {
        SALE sale = SALE(saleAddr);
        return sale.showSaleStatus();
    }
    
    /// View sale end time 
    function viewSaleEndTime(address saleAddr) public view returns (uint) {
        SALE sale = SALE(saleAddr);
        return sale.viewSaleEndTime();
    }
    
    
    /// User stake status 
    function userStakeStastus(address addr) public view returns (bool) {
        return user[addr].staked;
    }
    
    /// Staking status of contract 
    function ongoingStakingStatus() public view returns (bool) {
        return stakeStatus;
    }
    
    /** Owner Token Withdraw    
     * 
     * Requirements:
     * Only owner can call this function 
     */
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot withdraw to zero address");
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    /** Owner BNB Withdraw
     * 
     * Requirements:
     * Only owner can call this function
     */
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot withdraw to zero address");
        to.transfer(amount);
        return true;
    }
    
    /** 
     * @dev Ownership Transfer to "to" address
     * 
     * Requirements:
     * Only owner can call this function
     */
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    /// Update user Details
    function updateUserDetails(address addr, uint topTier_, uint[] memory tiers_, uint[] memory amounts, uint[] memory times, bool[] memory withdrawnStat) public {
        require(msg.sender == owner, "Only owner");
        require(topTier_ < 4, "topTier_ value cannot be greater than 3");
        uint tierLen = tiers_.length;
        uint amountLen = amounts.length;
        uint timeLen = times.length;
        uint withdrawnStatLen = withdrawnStat.length;
        user[addr].staked = true;
        user[addr].topTier = topTier_;
        if(topTier_ == 0){
            tier1count += 1;
        }
        else if(topTier_ == 1){
            tier2count += 1;
        }
        else if(topTier_ == 2){
            tier3count += 1;
        }
        else if(topTier_ == 3){
            tier4count += 1;
        }
        require(tierLen == amountLen && tierLen == timeLen && tierLen == withdrawnStatLen, "Array length error");
        for(uint i = 0; i < tierLen; i++){
            amounts[i] = amounts[i] * 10**18;
            user[addr].deposits.push(Deposit(tiers_[i], amounts[i], times[i], withdrawnStat[i]));
        }
    }
    
    
    /// Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}