/**
 *Submitted for verification at BscScan.com on 2021-11-16
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


contract StakeKclpEarnGamezila {
    
    /// Variables
    struct Stake {
        bool staked;
        Deposit[] deposits;
        uint topTier;
        uint stakedAmount;
        uint earnedAmount;
        uint stakedAt;
        bool stakedWithdrawn;
        bool initiateUnstake;
        uint initiateUnstakeTime;
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
    //address public stakeTokenAddr = 0x4178934c6E313a062c5addD66ab0D9B8d858347a; // mainnet
    address public stakeTokenAddr = 0x3cc97b7fcE42d372d3f5f08ED8121245B1a66fFF; // testnet
    
    address public earnTokenAddr = 0x824948cFF483FDe7518d83723Ad49A3F4C61c5e9; // testnet
  
    address public contractAddr = address(this);
    mapping(address => Stake) public user;
    mapping(address=>bool) public userRegister;
    bool public stakeStatus;
    uint gamezilaPrice = 13;
    uint gamezilaPriceDecimal = 1000;
    
    uint kclpPrice = 25;
    uint kclpPriceDecimal = 1000;
    
   
    address[] public userAddressArr;
    event Received(address, uint);
    event Staked(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets stake status to true to enable staking 
     */
    constructor() {
        tiers.push(Tier(365 days, 150, 365 days));
        tiers.push(Tier(365 days, 180, 365 days));
        
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
     * Minimum amount to stake is 1 tokens 
     * timestamp has to be between start and end time 
     */
    function stake(uint amt) public returns(bool) {
        
        
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
        
        require(token.balanceOf(sender) >= amt, "Insufficient balance of user");
        require(token.allowance(sender,contractAddr) >= amt, "Insufficient allowance");
        require(stakeStatus == true, "Staking disabled");
        
        require(amt >= 1 * 10**18, "Stake minimum 1 tokens");
        
        token.transferFrom(sender, contractAddr, amt);
        uint gamezilaAmount = (user[sender].staked==true) ? withdrawable(sender) : 0;
        uint amount = user[sender].stakedAmount + amt;
        user[sender].deposits.push(Deposit(0, amt, block.timestamp, false));
        
        user[sender].stakedAmount = amount;
        user[sender].stakedAt = block.timestamp;
        
        user[sender].staked = true;
        user[sender].stakedWithdrawn = false;
        if(userRegister[sender]==false){
            userRegister[sender]==true;
            userAddressArr.push(sender);
        }
        user[sender].topTier = 0;
        user[sender].earnedAmount = gamezilaAmount;
        user[sender].initiateUnstake = false;
        user[sender].initiateUnstakeTime = 0;
        emit Staked(sender, amount);
        return true;
    }

    function initiateUnstake() public returns(bool){
        require(user[msg.sender].staked == true,"Not Registered");
        user[msg.sender].initiateUnstake = true;
        user[msg.sender].initiateUnstakeTime = block.timestamp;
        return true;
    }
    

    /// Withdrawable view function
    function withdrawable(address addr) public view returns(uint gamezilaAmount) {
        
        Stake storage stake_ = user[addr];
        // for first 45 days 
        uint firstMilestone = stake_.stakedAt + 10 minutes;
        
        Tier storage tier = tiers[0];
        //uint end = stake_.stakedAt + tier.endTime;
        uint end = (firstMilestone > block.timestamp) ? block.timestamp : firstMilestone;
        uint since = stake_.stakedAt;
        uint  amount = 0;
        if(stake_.stakedWithdrawn == false){
            amount += stake_.stakedAmount * (end - since) * tier.percent / tier.time / 100;
        }
        
        uint usdFromKclp = (amount*kclpPrice)/kclpPriceDecimal;
        gamezilaAmount = (usdFromKclp*gamezilaPriceDecimal)/gamezilaPrice;
        
        // for after 45 days
        if(block.timestamp > firstMilestone){
            Tier storage tierAfter = tiers[1];
            //uint end = stake_.stakedAt + tier.endTime;
            uint endAfter = block.timestamp;
            uint sinceAfter = firstMilestone;
            uint amountAfter = 0;
            if(stake_.stakedWithdrawn == false){
                amountAfter += stake_.stakedAmount * (endAfter - sinceAfter) * tierAfter.percent / tierAfter.time / 100;
            }
            
            uint usdFromKclpAfter = (amountAfter*kclpPrice)/kclpPriceDecimal;
            gamezilaAmount += (usdFromKclpAfter*gamezilaPriceDecimal)/gamezilaPrice;
        }
       
    }
    

    /// Withdraw 
    function withdraw() public returns (bool) {
        BEP20 token = BEP20(stakeTokenAddr);
        BEP20 gamezilaToken = BEP20(earnTokenAddr);
        
        address addr = msg.sender;
        
        require(user[addr].staked == true, "User has not staked");
        require(user[addr].stakedWithdrawn == false, "Already withdrawn");
       
        
        Stake storage stake_ = user[addr];
        
        uint kclpAmount = stake_.stakedAmount;
        uint gamezilaAmount = withdrawable(addr);
        
        
        token.transfer(addr, kclpAmount); // kclp transfer
        gamezilaToken.transfer(addr, gamezilaAmount); // gamezilaToken transfer
        
        
        user[addr].stakedWithdrawn = true;
        user[addr].stakedAmount = 0;
        user[addr].earnedAmount = 0;
        user[addr].staked = false;
        user[addr].topTier = 0;
      
        return true;
        
    }
   
    function userdetails(address addr) public view returns(uint topTier, 
                                                            uint stakedAmount, 
                                                            uint stakedAt, 
                                                            bool stakedWithdrawn, 
                                                            uint earnedAmt,
                                                            bool initiateUnstakeTimeBtn,
                                                            bool withdrawlBtn,
                                                            uint initiateUnstakeTime,
                                                            bool initiateUnstakeStatus) {
        
        Stake storage stake_ = user[addr];
        
        topTier = stake_.topTier;
        stakedAmount = stake_.stakedAmount;
        stakedAt = stake_.stakedAt;
        stakedWithdrawn = stake_.stakedWithdrawn;
        
        earnedAmt = withdrawable(addr);
        earnedAmt += user[addr].earnedAmount;
        initiateUnstakeTime = stake_.initiateUnstakeTime;
        initiateUnstakeStatus = stake_.initiateUnstake;
        initiateUnstakeTimeBtn = stake_.initiateUnstake==false ? true : false;
        // 10 minutes Cool down period of 5 days (if you wanna unstake)
        withdrawlBtn = (stake_.initiateUnstake == true && (block.timestamp - stake_.initiateUnstakeTime) >= 10 minutes && stakedWithdrawn==false) ? true : false;
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
    
    function userAddressList() public view returns(address[] memory userAddrList) {
        userAddrList = userAddressArr;
    }

    /// Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}