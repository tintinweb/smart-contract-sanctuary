/**
 *Submitted for verification at BscScan.com on 2021-08-06
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

contract Staking {
    
    /// Variables
    struct Stake {
        bool staked;
        uint totalStaked;
        uint[] stakedAmounts;
        uint tier;
    }
    
    address public owner = msg.sender;
    address private stakeTokenAddr = 0x8691BB7E4f4d299716850bE908df9F8e002dED16;
    address private buyTokenAddr;
    address private contractAddr = address(this);
    mapping(address => Stake) public user;
    bool stakeStatus;
    uint tier1count;
    uint tier2count;
    uint tier3count;
    uint tier4count;
    
    event Received(address, uint);
    event Staked(address, uint);
    event OwnershipTransferred(address);
    event BuyTokenAddressChanged(address);
    
    /** 
     * @dev constructor sets stake status to true to enable staking 
     */
    constructor() {
        stakeStatus = true;
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
        require(amount >= 650 * 10**18, "Stake minimum 650 tokens");
        
        token.approve(contractAddr, amount);
        token.transferFrom(sender, contractAddr, amount);
        
        user[sender].staked = true;
        user[sender].totalStaked += amount;
        user[sender].stakedAmounts.push(amount);
        
        if(user[sender].totalStaked >= 650*10**18 && user[sender].totalStaked <= 3000*10**18) {
            if(user[sender].tier == 0){
                user[sender].tier = 1;
                tier1count += 1;
            }
        }
        
        else if(user[sender].totalStaked > 3000*10**18 && user[sender].totalStaked <= 10000*10**18) {
            if(user[sender].tier == 0){
                user[sender].tier = 2;
                tier2count += 1;
            }
            if(user[sender].tier == 1){
                user[sender].tier = 2;
                tier1count = tier1count -1;
                tier2count += 1;
            }
        }
        
        else if(user[sender].totalStaked > 10000*10**18 && user[sender].totalStaked <= 30000*10**18) {
            if(user[sender].tier == 0){
                user[sender].tier = 3;
                tier3count += 1;
            }
            if(user[sender].tier == 1){
                user[sender].tier = 3;
                tier1count = tier1count -1;
                tier3count += 1;
            }
            if(user[sender].tier == 2){
                user[sender].tier = 3;
                tier2count = tier2count -1;
                tier3count += 1;
            }
        }
        
        else if(user[sender].totalStaked > 30000*18){
            if(user[sender].tier == 0){
                user[sender].tier = 4;
                tier4count += 1;
            }
            if(user[sender].tier == 1){
                user[sender].tier = 4;
                tier1count = tier1count -1;
                tier4count += 1;
            }
            if(user[sender].tier == 2){
                user[sender].tier = 4;
                tier2count = tier2count -1;
                tier4count += 1;
            }
            if(user[sender].tier == 3){
                user[sender].tier = 4;
                tier3count = tier3count -1;
                tier4count += 1;
            }
        }
        
        emit Staked(sender, amount);
        return true;
    }
    
    /// Show Staking Details
    function stakingDetails(address addr) public view returns(bool, uint, uint[] memory){
        uint len = user[addr].stakedAmounts.length;
        bool staked = user[addr].staked;
        uint totalStake_ = user[addr].totalStaked;
        uint[] memory stakedAmount = new uint[](len);
        for(uint i = 0; i < len; i++){
            stakedAmount[i] = user[addr].stakedAmounts[i];
        }
        return (staked, totalStake_, stakedAmount);
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
    
    /// User stake status 
    function userStakeStatus(address addr) public view returns (bool) {
        return user[addr].staked;
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