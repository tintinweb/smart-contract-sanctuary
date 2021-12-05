/**
 *Submitted for verification at BscScan.com on 2021-12-04
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


contract StakeCgazEarnKclp {
    
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
    address public stakeTokenAddr = 0x7182Bc441b0ef15C965117f1EdF9B879499E38AC; // stakeToken (chq) testnet
    address public earnTokenAddr = 0x3cc97b7fcE42d372d3f5f08ED8121245B1a66fFF; // earnToken (gamezlla) testnet
  
    address public contractAddr = address(this);
    mapping(address => Stake) public user;
    mapping(address=>bool) public userRegister;
    bool public stakeStatus;
    uint earnTokenPrice = 2;
    uint earnTokenPriceDecimal = 100;
    
    uint stakeTokenPrice = 3;
    uint stakeTokenPriceDecimal = 1;
    
   
    address[] public userAddressArr;
    event Received(address, uint);
    event Staked(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets stake status to true to enable staking 
     */
    constructor() {
        tiers.push(Tier(365 days, 120, 365 days));
        
        stakeStatus = true;
    }
    
    /**
     * @dev Start or stop staking
     * 
     * Requirements: 
     * 
     * Only owner can change the state 
     */
    function setStakeStatus(bool state) external {
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
    function stake(uint amt) external returns(bool) {
        
        
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
        
        require(token.balanceOf(sender) >= amt, "Insufficient balance of user");
        require(token.allowance(sender,contractAddr) >= amt, "Insufficient allowance");
        require(stakeStatus == true, "Staking disabled");
        
        require(amt >= 100 * 10**18, "Stake minimum 100 tokens");
        require(amt <= 1000 * 10**18, "Stake maximum 1000 tokens");
        
        token.transferFrom(sender, contractAddr, amt);
        uint earnTokenAmount = (user[sender].staked==true) ? withdrawable(sender) : 0;
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
        user[sender].earnedAmount = earnTokenAmount;
        user[sender].initiateUnstake = false;
        user[sender].initiateUnstakeTime = 0;
        emit Staked(sender, amount);
        return true;
    }

    function initiateUnstake() external returns(bool){
        require(user[msg.sender].staked == true,"Not Registered");
        user[msg.sender].initiateUnstake = true;
        user[msg.sender].initiateUnstakeTime = block.timestamp;
        return true;
    }
    

    /// Withdrawable view function
    function withdrawable(address addr) public view returns(uint earnTokenAmount) {
        
        Stake storage stake_ = user[addr];
        // for first 45 days 
       
        Tier storage tier = tiers[0];
        uint endTime = stake_.stakedAt + tier.endTime;
        uint end = endTime > block.timestamp ? block.timestamp : endTime;
        uint since = stake_.stakedAt;
        uint  amount = 0;
        if(stake_.stakedWithdrawn == false){
            amount += stake_.stakedAmount * (end - since) * tier.percent / tier.time / 100;
        }
        
        uint usdFromstakeToken = (amount*stakeTokenPrice)/stakeTokenPriceDecimal;
        earnTokenAmount = (usdFromstakeToken*earnTokenPriceDecimal)/earnTokenPrice;
        earnTokenAmount += stake_.earnedAmount;
    }
    

    /// Withdraw 
    function withdraw() external returns (bool) {
        
        
        BEP20 token = BEP20(stakeTokenAddr);
        BEP20 earnTokenToken = BEP20(earnTokenAddr);
        
        address addr = msg.sender;
        
        require(user[addr].staked == true, "User has not staked");
        require(user[addr].stakedWithdrawn == false, "Already withdrawn");
        require(user[addr].initiateUnstake == true, "Unstake Not Initiated");
        //require((block.timestamp - user[addr].initiateUnstakeTime) >= 5 days ,"cool down has not completed yet");
       
        
        Stake storage stake_ = user[addr];
        
        uint stakeTokenAmount = stake_.stakedAmount;
        // deduct 10% from stake Amount if withdrawal before cooldown period
        if((block.timestamp - user[addr].initiateUnstakeTime) < 5 minutes) {
            stakeTokenAmount = stakeTokenAmount - (stakeTokenAmount*10/100); // duduct 10 % 
        }
        
        uint earnTokenAmount = withdrawable(addr);
        
        token.transfer(addr, stakeTokenAmount); // stakeToken transfer
        earnTokenToken.transfer(addr, earnTokenAmount); // earnTokenToken transfer
        
        
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
        initiateUnstakeTime = stake_.initiateUnstakeTime;
        initiateUnstakeStatus = stake_.initiateUnstake;
        initiateUnstakeTimeBtn = stake_.initiateUnstake==false ? true : false;
        //  Cool down period of 5 days (if you wanna unstake)
        //withdrawlBtn = (stake_.initiateUnstake == true && (block.timestamp - stake_.initiateUnstakeTime) >= 5 days && stakedWithdrawn==false) ? true : false;
        withdrawlBtn = (stake_.initiateUnstake == true && (block.timestamp - stake_.initiateUnstakeTime) >= 5 minutes && stakedWithdrawn==false) ? true : false;
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
    function withdrawToken(address tokenAddress, address to, uint amount) external returns(bool) {
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
    function withdrawBNB(address payable to, uint amount) external returns(bool) {
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
    function transferOwnership(address to) external returns(bool) {
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