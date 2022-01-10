/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.11;

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

contract PlayrStaking {
    
    /// Variables
    struct Stake {
        bool staked;
        Deposit[] deposits;
        uint topTier;
        uint stakedAmount;
        uint stakedAt;
        bool stakedWithdrawn;
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
    address public stakeTokenAddr=0x698B1095Bc53d76b51849706500B9D865E71967A;
    address public buyTokenAddr;
    address public contractAddr = address(this);
    mapping(address => Stake) public user;
    mapping(address=>bool) public userRegister;
    bool public stakeStatus;
    uint tier1count;
    uint tier2count;
    uint tier3count;
    uint tier4count;
    uint oneDay = 600;

    uint public burnPercent = 10;
    address public burnAddress;
    
   
    address[] public saleAddressArr;
    address[] public userAddressArr;
    event Received(address, uint);
    event Staked(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets stake status to true to enable staking 
     */
    constructor() {
        /*tiers.push(Tier(365 days, 275, 60 days));
        tiers.push(Tier(365 days, 350, 75 days));
        tiers.push(Tier(365 days, 400, 90 days));
        tiers.push(Tier(365 days, 450, 100 days));*/


        tiers.push(Tier(365*oneDay, 275, 60*oneDay));
        tiers.push(Tier(365*oneDay, 350, 75*oneDay));
        tiers.push(Tier(365*oneDay, 400, 90*oneDay));
        tiers.push(Tier(365*oneDay, 450, 100*oneDay));
        
        stakeStatus = true;
    }
    
    /**
     * @dev Start or stop staking
     * 
     * Requirements: 
     * 
     * Only owner can change the state 
     */
    function updateStakeTokenAddr(address _stakeTokenAddr) public {
        require(msg.sender == owner, "Only owner");
        stakeTokenAddr = _stakeTokenAddr;
    }



    function changeOneDay(uint _oneDay) external {
        require(msg.sender == owner, "Only owner");
        oneDay = _oneDay;
    }

    function changeBurnPercent(uint newBurnPercent) external {
        require(msg.sender == owner, "Only owner");
        burnPercent = newBurnPercent;
    }

     function changeBurnAddress(address newBurnAddress) external {
        require(msg.sender == owner, "Only owner");
        burnAddress = newBurnAddress;
    }


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
    function stake(uint amt) public returns(bool) {        
        
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
        
        require(token.balanceOf(sender) >= amt, "Insufficient balance of user");
        require(stakeStatus == true, "Staking disabled");
        require(amt >= 30000 * 10**18, "Stake minimum 30000 tokens");
        
        token.transferFrom(sender, contractAddr, amt);
        
        uint amount = user[sender].stakedAmount + amt + withdrawableTillNow(sender);
       // At Restack Remove user from current tier
        if(user[sender].staked==true){
            if(user[sender].topTier==0){
                tier1count -= 1;
            }
            else if(user[sender].topTier==1){
                tier2count -= 1;
            }
            else if(user[sender].topTier==2){
                tier3count -= 1;
            }
            if(user[sender].topTier==3){
                tier4count -= 1;
            }
        }
        // assign user to tier and increase tier count
        if(amount >= 30000*10**18 && amount < 99999*10**18){
            user[sender].deposits.push(Deposit(0, amt, block.timestamp, false));
            if(user[sender].topTier <=0){
                tier1count += 1;
                user[sender].topTier = 0;
            }
        }
        
        else if(amount >= 100000*10**18 && amount < 299999*10**18){
            user[sender].deposits.push(Deposit(1, amt, block.timestamp, false));
            if(user[sender].topTier <= 1){
                tier2count += 1;
                user[sender].topTier = 1;
            }
        }
        
        else if(amount >= 300000*10**18 && amount < 499999*10**18){
            user[sender].deposits.push(Deposit(2, amt, block.timestamp, false));
            if(user[sender].topTier <= 2){
                tier3count += 1;
                user[sender].topTier = 2;
            }
        }
        else if(amount >= 500000*10**18){
            user[sender].deposits.push(Deposit(3, amt, block.timestamp, false));
            if(user[sender].topTier <= 3){
                tier4count += 1;
                user[sender].topTier = 3;
            }
        }
        user[sender].stakedAmount = amount;
        user[sender].stakedAt = block.timestamp;
        
        user[sender].staked = true;
        user[sender].stakedWithdrawn = false;
        if(userRegister[sender]==false){
            userRegister[sender]==true;
            userAddressArr.push(sender);
        }
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
    
     /// Withdrawable view function
    function userEndTimeFuncIndex(address uAddr, uint uIndex) public view returns(uint) {
        
        Stake storage stake_ = user[uAddr];
        Deposit storage dep = stake_.deposits[uIndex];
        Tier storage tier = tiers[dep.tier];
        
        uint endTime = dep.at + tier.endTime;
        uint normalEndTime = dep.at + tier.endTime;
        if(saleAddressArr.length > 0){
            for(uint i = 0;  i < saleAddressArr.length; i++){
                address saleAddr = saleAddressArr[i];
                SALE sale = SALE(saleAddr);   
                if(sale.showSaleStatus()==false && sale.userBuyStatus(uAddr)==false && normalEndTime > sale.viewSaleEndTime()){
					endTime = sale.viewSaleEndTime();
				}
            }
        }
        else {
            endTime = dep.at + tier.endTime;
        }
         // if user stacked after ido ends
        endTime = dep.at > endTime ? normalEndTime : endTime;
        return endTime;
    }
   
    
    /// Withdrawable view function
    function userEndTimeFunc(address uAddr) public view returns(uint) {
        
        Stake storage stake_ = user[uAddr];
        Tier storage tier = tiers[stake_.topTier];
        uint endTime = stake_.stakedAt + tier.endTime;
        uint normalEndTime = stake_.stakedAt + tier.endTime;
        if(saleAddressArr.length > 0){
            for(uint i = 0;  i < saleAddressArr.length; i++){
                address saleAddr = saleAddressArr[i];
                SALE sale = SALE(saleAddr);   
                if(sale.showSaleStatus()==false && sale.userBuyStatus(uAddr)==false && normalEndTime > sale.viewSaleEndTime()){
					endTime = sale.viewSaleEndTime();
				}
            }
        }
        
        // if user stacked after ido ends
        endTime = stake_.stakedAt > endTime ? normalEndTime : endTime;
        return endTime;
    }
    
    function withdrawableTillNow(address addr) public view returns(uint amount) {
        
        Stake storage stake_ = user[addr];
        Tier storage tier = tiers[stake_.topTier];
        uint end = userEndTimeFunc(addr);
        end = (end > block.timestamp) ? block.timestamp : end;
        uint since = stake_.stakedAt;
        if(stake_.stakedWithdrawn == false){
            amount += stake_.stakedAmount * (end - since) * tier.percent / tier.time / 100;
        }
        else{
            amount = 0;
        }
       
    }
    
    /// Withdrawable view function
    function withdrawable(address addr) public view returns(uint amount) {
        
        Stake storage stake_ = user[addr];
        Tier storage tier = tiers[stake_.topTier];
        uint end = userEndTimeFunc(addr);
        uint since = stake_.stakedAt;
        if(stake_.stakedWithdrawn == false){
            amount += stake_.stakedAmount * (end - since) * tier.percent / tier.time / 100;
        }
        else{
            amount = 0;
        }
    }
    

    /// Withdraw 
    function withdraw() public returns (bool) {
        BEP20 token = BEP20(stakeTokenAddr);
        
        address addr = msg.sender;
        
        require(user[addr].staked == true, "User has not staked");
        require(user[addr].stakedWithdrawn == false, "Already withdrawn");
       
        
        Stake storage stake_ = user[addr];
        Tier storage tier = tiers[stake_.topTier];
        
        uint amount = stake_.stakedAmount;
        uint end = userEndTimeFunc(addr);
        
        uint since = stake_.stakedAt;
        if(stake_.stakedWithdrawn == false){
            amount += stake_.stakedAmount * (end - since) * tier.percent / tier.time / 100;
        }
        else{
            amount = 0;
        }


        uint tierEndTime = since + tier.endTime;
        
        if(block.timestamp < tierEndTime){
            uint earlyUnlockDays = 85;
            if(stake_.topTier==0){
                earlyUnlockDays = 45 ;
            }
            else if(stake_.topTier==1){
                earlyUnlockDays = 60;
            }
            else if(stake_.topTier==2){
                earlyUnlockDays = 75;
            }
            else if(stake_.topTier==3){
                earlyUnlockDays = 85;
            }

            uint earlyUnlockTime = since + (earlyUnlockDays * oneDay);
            require(block.timestamp >= earlyUnlockTime, "Early Unlock Time not reached");

            uint burnAmt = amount*burnPercent/100;
            amount = amount - burnAmt; // burn 
            token.transfer(burnAddress, amount); // burn transfer
        }
        
        //require(block.timestamp >= tierEndTime, "End Time not reached");
     
        token.transfer(addr, amount);
        
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
        user[addr].stakedWithdrawn = true;
        user[addr].stakedAmount = 0;
        user[addr].staked = false;
        user[addr].topTier = 0;
      
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
            claimBtnStatus[i] = (block.timestamp > userEndTimeFuncIndex(addr,i)) ? true : false;
        }
        
        return(topTier_, amounts, times, status,claimBtnStatus,tier);
    }
    
    function userdetails(address addr) public view returns(uint topTier, uint stakedAmount, uint stakedAt, bool stakedWithdrawn, bool claimBtnStatus, uint unlockTime, uint stackingEndTime) {
        
        topTier = user[addr].topTier;
        stakedAmount = user[addr].stakedAmount;
        stakedAt = user[addr].stakedAt;
        stakedWithdrawn = user[addr].stakedWithdrawn;
        
        Tier storage tier = tiers[topTier];
        unlockTime = stakedAt + tier.endTime; 
        stackingEndTime = userEndTimeFunc(addr);
        claimBtnStatus = (block.timestamp > unlockTime) ? true : false;
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
    function updateUserDetails(address addr, uint topTier_, uint amounts, uint times, bool withdrawnStat) public {
        require(msg.sender == owner, "Only owner");
        require(topTier_ < 4, "topTier_ value cannot be greater than 3");
 
        user[addr].staked = true;
        user[addr].topTier = topTier_;
        user[addr].stakedAmount = amounts;
        user[addr].stakedAt = times;
        user[addr].stakedWithdrawn = withdrawnStat;
 
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
        user[addr].deposits.push(Deposit(topTier_, amounts, times, withdrawnStat));
        
    }
    
    
    function saleIdoList() public view returns(address[] memory idoAddrList) {
        idoAddrList = saleAddressArr;
    }
    
    function userAddressList() public view returns(address[] memory userAddrList) {
        userAddrList = userAddressArr;
    }
    
    
   function unstakeByOwner(address addr) public returns(bool)  {
        require(msg.sender == owner, "Only owner");
        
       BEP20 token = BEP20(stakeTokenAddr);
       
        require(user[addr].staked == true, "User has not staked");
        require(user[addr].stakedWithdrawn == false, "Already withdrawn");
       
        
        Stake storage stake_ = user[addr];
        Tier storage tier = tiers[stake_.topTier];
        
        uint amount = stake_.stakedAmount;
        uint end = block.timestamp;
        
        uint since = stake_.stakedAt;
        if(stake_.stakedWithdrawn == false){
            amount += stake_.stakedAmount * (end - since) * tier.percent / tier.time / 100;
        }
        else{
            amount = 0;
        }
        
        token.transfer(addr, amount);
        
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
        user[addr].stakedWithdrawn = true;
        user[addr].stakedAmount = 0;
        user[addr].staked = false;
        user[addr].topTier = 0;
      
        return true;
       
        
    }    
    ////set one day limit
    function updateoneDayLimit(uint oneDayLimit) public {
        require(msg.sender == owner, "Only owner");
        oneDay  = oneDayLimit;
    }
    /// Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}