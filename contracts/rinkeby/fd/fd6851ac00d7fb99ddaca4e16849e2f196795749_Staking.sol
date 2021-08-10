/**
 *Submitted for verification at Etherscan.io on 2021-08-10
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

contract Staking {
    
    /// Variables
    struct Stake {
        bool staked;
        uint totalStaked;
        uint lastStakeTime;
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
    address private stakeTokenAddr = 0x8dc05F2d60647c9Ea4BCdB52f889aBBA14CbA9E2;
    address private buyTokenAddr;
    address private contractAddr = address(this);
    mapping(address => Stake) public user;
    bool private stakeStatus;
    uint tier1count;
    uint tier2count;
    uint tier3count;
    uint tier4count;
    
    address private saleAddress;
    
    event Received(address, uint);
    event Staked(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets stake status to true to enable staking 
     */
    constructor() {
        tiers.push(Tier(365 days, 25, 7 days));
        tiers.push(Tier(365 days, 100, 30 days));
        tiers.push(Tier(365 days, 150, 90 days));
        tiers.push(Tier(365 days, 200, 180 days));
        
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
        require(amount >= 625 * 10**18, "Stake minimum 625 tokens");
        
        token.approve(contractAddr, amount);
        token.transferFrom(sender, contractAddr, amount);
        
        user[sender].staked = true;
        user[sender].totalStaked += amount;
       // user[sender].stakedAmounts.push(amount);
        user[sender].lastStakeTime = block.timestamp;
        
        if(amount >= 625*10**18 && amount <= 3000*10**18){
            user[sender].deposits.push(Deposit(0, amount, block.timestamp, false));
        }
        
        else if(amount >= 3000*10**18 && amount <= 10000*10**18){
            user[sender].deposits.push(Deposit(1, amount, block.timestamp, false));
        }
        
        else if(amount >= 10000*10**18 && amount <= 30000*10**18){
            user[sender].deposits.push(Deposit(2, amount, block.timestamp, false));
        }
        
        else if(amount > 30000*18){
            user[sender].deposits.push(Deposit(3, amount, block.timestamp, false));
        }
        
        if(user[sender].totalStaked >= 625*10**18 && user[sender].totalStaked <= 3000*10**18) {
            if(user[sender].topTier == 0){
                user[sender].topTier = 1;
                tier1count += 1;
            }
        }
        
        else if(user[sender].totalStaked > 3000*10**18 && user[sender].totalStaked <= 10000*10**18) {
            if(user[sender].topTier == 0){
                user[sender].topTier = 2;
                tier2count += 1;
            }
            if(user[sender].topTier == 1){
                user[sender].topTier = 2;
                tier1count = tier1count -1;
                tier2count += 1;
            }
        }
        
        else if(user[sender].totalStaked > 10000*10**18 && user[sender].totalStaked <= 30000*10**18) {
            if(user[sender].topTier == 0){
                user[sender].topTier = 3;
                tier3count += 1;
            }
            if(user[sender].topTier == 1){
                user[sender].topTier = 3;
                tier1count = tier1count -1;
                tier3count += 1;
            }
            if(user[sender].topTier == 2){
                user[sender].topTier = 3;
                tier2count = tier2count -1;
                tier3count += 1;
            }
        }
        
        else if(user[sender].totalStaked > 30000*18){
            if(user[sender].topTier == 0){
                user[sender].topTier = 4;
                tier4count += 1;
            }
            if(user[sender].topTier == 1){
                user[sender].topTier = 4;
                tier1count = tier1count -1;
                tier4count += 1;
            }
            if(user[sender].topTier == 2){
                user[sender].topTier = 4;
                tier2count = tier2count -1;
                tier4count += 1;
            }
            if(user[sender].topTier == 3){
                user[sender].topTier = 4;
                tier3count = tier3count -1;
                tier4count += 1;
            }
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
        saleAddress = saleAddr;
    }
    
    /// Withdrawable
    function withdrawable(address addr, uint index) public view returns(uint amount) {
        
        SALE sale = SALE(saleAddress);
        // if sale address is not set
        if(saleAddress == address(0)){
            Stake storage stake_ = user[addr];
            Deposit storage dep = stake_.deposits[index];
            Tier storage tier = tiers[dep.tier];
            uint end = dep.at + tier.endTime;
            uint since = dep.at;
            if(dep.withdrawn == false){
                amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
            }
            else{
                amount = 0;
            }
        }
        
        //if sale address is not zero address
        else{
            
            if(sale.userBuyStatus(addr) == true){
                Stake storage stake_ = user[addr];
                Deposit storage dep = stake_.deposits[index];
                Tier storage tier = tiers[dep.tier];
                uint end = dep.at + tier.endTime;
                uint since = dep.at;
                if(dep.withdrawn == false){
                    amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                }
                else{
                    amount = 0;
                }
            }
            else{
                if(sale.showSaleStatus() == true){
                    Stake storage stake_ = user[addr];
                    Deposit storage dep = stake_.deposits[index];
                    Tier storage tier = tiers[dep.tier];
                    uint end = dep.at + tier.endTime;
                    uint since = dep.at;
                    if(dep.withdrawn == false){
                        amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                    }
                    else{
                        amount = 0;
                    }
                }
                else{
                    Stake storage stake_ = user[addr];
                    Deposit storage dep = stake_.deposits[index];
                    Tier storage tier = tiers[dep.tier];
                    uint saleEndTime = sale.viewSaleEndTime();
                    uint end = dep.at + (saleEndTime - dep.at);
                    uint since = dep.at;
                    if(dep.withdrawn == false){
                        amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                    }
                    else{
                        amount = 0;
                    }
                }
            }
        }
    }
    
    /// Withdraw 
    function withdraw(uint index) public returns (bool) {
        BEP20 token = BEP20(stakeTokenAddr);
        SALE sale = SALE(saleAddress);
        address addr = msg.sender;
        uint amount;
        require(user[addr].staked == true, "User has not staked");
        require(user[addr].deposits[index].withdrawn == false, "Already withdrawn");
        
        // if sale address is not set
        if(saleAddress == address(0)){
            Stake storage stake_ = user[addr];
            Deposit storage dep = stake_.deposits[index];
            Tier storage tier = tiers[dep.tier];
            uint end = dep.at + tier.endTime;
            uint since = dep.at;
            if(dep.withdrawn == false){
                amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                amount += dep.amount;
            }
            else{
                amount = 0;
            }
            require(block.timestamp >= end, "End Time not reached");
            token.transfer(addr, amount);
            user[addr].deposits[index].withdrawn = true;
            return true;
        }
        
        //if sale address is not zero address
        else{
            
            if(sale.userBuyStatus(addr) == true){
                Stake storage stake_ = user[addr];
                Deposit storage dep = stake_.deposits[index];
                Tier storage tier = tiers[dep.tier];
                uint end = dep.at + tier.endTime;
                uint since = dep.at;
                if(dep.withdrawn == false){
                    amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                    amount += dep.amount;
                }
                else{
                    amount = 0;
                }
                require(block.timestamp >= end, "End Time not reached");
                token.transfer(addr, amount);
                user[addr].deposits[index].withdrawn = true;
                return true;
            }
            else{
                if(sale.showSaleStatus() == true){
                    Stake storage stake_ = user[addr];
                    Deposit storage dep = stake_.deposits[index];
                    Tier storage tier = tiers[dep.tier];
                    uint end = dep.at + tier.endTime;
                    uint since = dep.at;
                    if(dep.withdrawn == false){
                        amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                        amount += dep.amount;
                    }
                    else{
                        amount = 0;
                    }
                    require(block.timestamp >= end, "End Time not reached");
                    token.transfer(addr, amount);
                    user[addr].deposits[index].withdrawn = true;
                    return true;
                }
                else{
                    Stake storage stake_ = user[addr];
                    Deposit storage dep = stake_.deposits[index];
                    Tier storage tier = tiers[dep.tier];
                    uint saleEndTime = sale.viewSaleEndTime();
                    uint end = dep.at + (saleEndTime - dep.at);
                    uint since = dep.at;
                    if(dep.withdrawn == false){
                        amount += dep.amount * (end - since) * tier.percent / tier.time / 100;
                        amount += dep.amount;
                    }
                    else{
                        amount = 0;
                    }
                    require(block.timestamp >= end, "End Time not reached");
                    token.transfer(addr, amount);
                    user[addr].deposits[index].withdrawn = true;
                    return true;
                }
            }
        }
    }
    
    /// Show Staking Details
 /*   function stakingDetails(address addr) public view returns(bool, uint, uint, uint, uint[] memory){
        uint len = user[addr].stakedAmounts.length;
        bool staked = user[addr].staked;
        uint tier = user[addr].tier;
        uint totalStake_ = user[addr].totalStaked;
        uint lastStakeTime = user[addr].lastStakeTime;
        uint[] memory stakedAmount = new uint[](len);
        for(uint i = 0; i < len; i++){
            stakedAmount[i] = user[addr].stakedAmounts[i];
        }
        return (staked, tier, lastStakeTime, totalStake_, stakedAmount);
    } */
    
    /// View user end time 
    function viewUserEndTime(address addr) public view returns(uint) {
        
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
    function presaleStatus() public view returns(bool) {
        SALE sale = SALE(saleAddress);
        return sale.showSaleStatus();
    }
    
    /// View sale end time 
    function viewSaleEndTime() public view returns (uint) {
        SALE sale = SALE(saleAddress);
        return sale.viewSaleEndTime();
    }
    
    /// Withdraw Stake amount with interest
   /* function withdraw() public returns (bool) {
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
        SALE sale = SALE(saleAddress);
        require(user[sender].staked == true, "User has not staked");
        uint endTime;
        uint amount;
        uint since;
        
        // if saleAddress is not set
        if(saleAddress == address(0)){
            
            if(user[sender].tier == 1){
                    endTime = user[sender].lastStakeTime + 7 days;
                    require(block.timestamp >= endTime, "Time limit not reached");
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 25 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    token.transfer(sender, amount);
                    user[sender].staked = false;
            }
    
            else if(user[sender].tier == 2){
                    endTime = user[sender].lastStakeTime + 30 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 100 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
            }
    
            else if(user[sender].tier == 3){
                    endTime = user[sender].lastStakeTime + 90 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 150 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
            }
    
            else if(user[sender].tier == 4){
                    endTime = user[sender].lastStakeTime + 180 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 200 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
                }
        }
        
        // after setting saleAddress
        else{
            
            if(user[sender].tier == 1){
                
                if(sale.userBuyStatus(sender) == true){
                    
                    endTime = user[sender].lastStakeTime + 7 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 25 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached 1");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
                }
                else{

                    if(sale.showSaleStatus() == true){
                        endTime = user[sender].lastStakeTime + 7 days;
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 25 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 2");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                    else{
                        uint saleEndTime = sale.viewSaleEndTime();
                        endTime = user[sender].lastStakeTime + (saleEndTime - user[sender].lastStakeTime);
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 25 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 3");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                }
            }
    
            else if(user[sender].tier == 2){
                
                if(sale.userBuyStatus(sender) == true){
                    
                    endTime = user[sender].lastStakeTime + 30 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 100 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached 1");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
                }
                else{

                    if(sale.showSaleStatus() == true){
                        endTime = user[sender].lastStakeTime + 30 days;
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 100 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 2");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                    else{
                        uint saleEndTime = sale.viewSaleEndTime();
                        endTime = user[sender].lastStakeTime + (saleEndTime - user[sender].lastStakeTime);
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 100 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 3");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                }
            }
    
            else if(user[sender].tier == 3){
                
                if(sale.userBuyStatus(sender) == true){
                    
                    endTime = user[sender].lastStakeTime + 90 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 150 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached 1");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
                }
                else{

                    if(sale.showSaleStatus() == true){
                        endTime = user[sender].lastStakeTime + 90 days;
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 150 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 2");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                    else{
                        uint saleEndTime = sale.viewSaleEndTime();
                        endTime = user[sender].lastStakeTime + (saleEndTime - user[sender].lastStakeTime);
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 150 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 3");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                }
            }
    
            else if(user[sender].tier == 4){
                
                if(sale.userBuyStatus(sender) == true){
                    
                    endTime = user[sender].lastStakeTime + 180 days;
                    since = user[sender].lastStakeTime ;
                    amount += user[sender].totalStaked * (endTime - since) * 200 / 365 days / 100;
                    amount += user[sender].totalStaked;
                    require(block.timestamp >= endTime, "Time limit not reached 1");
                    token.transfer(sender, amount);
                    user[sender].staked = false;
                }
                else{

                    if(sale.showSaleStatus() == true){
                        endTime = user[sender].lastStakeTime + 180 days;
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 200 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 2");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                    else{
                        uint saleEndTime = sale.viewSaleEndTime();
                        endTime = user[sender].lastStakeTime + (saleEndTime - user[sender].lastStakeTime);
                        since = user[sender].lastStakeTime ;
                        amount += user[sender].totalStaked * (endTime - since) * 200 / 365 days / 100;
                        amount += user[sender].totalStaked;
                        require(block.timestamp >= endTime, "Time limit not reached 3");
                        token.transfer(sender, amount);
                        user[sender].staked = false;
                    }
                }
            }
        }
        
        return true;
    } */
    
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
    
    /// Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}