pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./FLAM.sol";

contract Flame_Maker_1 is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event RewardsTransferred(address holder, uint256 amount);
    
    // Dev address...
    address public devAddress = 0x2f3b686576F5eb838414D7D27A6b8F2518Bfe7Ac;
    
    // FLAME token contract...
    address public tokenAddress = 0x56B1Ba7ec1d061BCBB4377842D1E17a2007D6085;
    
    // ZARD token contract...
    address public ZARDtoken = 0xcF663a0ef9155BdC35a4B918BbEC75E9bFE40D2a;
    
    // unstaking possible after 10 days
    uint public constant cliffTime = 0 days;
    
    // reward rate 100 % per year
    uint256 public rewardRate = 1e2;
    
    // reward interval 365 days
    uint256 public rewardInterval = 365 days;
    
    uint256 public MinimumWithdrawTime = 5 days;
    
    uint256 public totalClaimedRewards;
    uint256 private stakingAndDaoTokens = 1e7; // Maximum token amount can be farmed.
    
    bool public farmEnabled = false;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint256) public depositedTokens;
    mapping (address => uint256) public stakingTime;
    mapping (address => uint256) public lastClaimedTime;
    mapping (address => uint256) public totalEarnedTokens;
    
    function updateAccount(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
        
        if (pendingDivs != 0) {
            FLAME_Token(tokenAddress).mint(account, pendingDivs);
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        
        lastClaimedTime[account] = block.timestamp;
    }
    
    function getPendingDivs(address _holder) public view returns (uint256 _pendingDivs) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;
        
        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 stakedAmount = depositedTokens[_holder];
        
        uint256 pendingDivs = stakedAmount.mul(rewardRate).mul(timeDiff).div(rewardInterval).div(1e4);
        
        return pendingDivs;
    }
    
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }
    
    function deposit(uint256 amountToStake) public {
        require(farmEnabled, "Farming not enabled yet");
        
        FLAME_Token(ZARDtoken).transferFrom(msg.sender, address(this), amountToStake);
        
        updateAccount(msg.sender);
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToStake);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
        }
    }
    
    function withdraw(uint256 amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        uint256 _lastClaimedTime = block.timestamp.sub(lastClaimedTime[msg.sender]);
        require(block.timestamp.sub(stakingTime[msg.sender]) > cliffTime, "You recently staked, please wait before withdrawing.");
        
        if (_lastClaimedTime >= MinimumWithdrawTime) {
            require(Token(ZARDtoken).transfer(msg.sender, amountToWithdraw), "Could not transfer tokens.");
        }
        
        if (_lastClaimedTime < MinimumWithdrawTime) {
            uint256 WithdrawFee = amountToWithdraw.div(1e2).mul(5);
            uint256 amountAfterFee = amountToWithdraw.sub(WithdrawFee);
            require(Token(ZARDtoken).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
            require(Token(ZARDtoken).transfer(devAddress, WithdrawFee), "Could not transfer tokens.");
        }
        
        updateAccount(msg.sender);
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function Emergency_Withdraw(uint256 amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        
        uint256 _lastClaimedTime = block.timestamp.sub(lastClaimedTime[msg.sender]);
        require(block.timestamp.sub(stakingTime[msg.sender]) > cliffTime, "You recently staked, please wait before withdrawing.");
        
        if (_lastClaimedTime >= MinimumWithdrawTime) {
            require(Token(ZARDtoken).transfer(msg.sender, amountToWithdraw), "Could not transfer tokens.");
        } else
        
        if (_lastClaimedTime < MinimumWithdrawTime) {
            uint256 WithdrawFee = amountToWithdraw.div(1e2).mul(5);
            uint256 amountAfterFee = amountToWithdraw.sub(WithdrawFee);
            require(Token(ZARDtoken).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");
            require(Token(ZARDtoken).transfer(devAddress, WithdrawFee), "Could not transfer tokens.");
        }
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        
        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function claimDivs() public {
        updateAccount(msg.sender);
    }
    
    function getStakingAndDaoAmount() public view returns (uint256) {
        if (totalClaimedRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint256 remaining = stakingAndDaoTokens.sub(totalClaimedRewards);
        return remaining;
    }
    
    // function to allow admin to set token address..
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    
    // function to allow admin to set ZARD token address..
    function setZARDTokenAddress(address _ZardAadd) public onlyOwner {
        require(farmEnabled, "Not possible to change after farm enabled, SORRY.");
        ZARDtoken = _ZardAadd;
    }
    
    // function to allow admin to set dev address..
    function setDevaddress(address _devAadd) public onlyOwner {
        devAddress = _devAadd;
    }
    
    // function to allow admin to set reward interval..
    function setRewardInterval(uint256 _rewardInterval) public onlyOwner {
        rewardInterval = _rewardInterval;
    }
    
    // function to allow admin to set Minimum Withdraw Time..
    function setMinimumWithdrawTime(uint256 _sec) public onlyOwner {
        require(_sec <= 30 days);
        MinimumWithdrawTime = _sec;
    }
    
    // function to allow admin to set staking and dao tokens amount..
    function setStakingAndDaoTokens(uint256 _stakingAndDaoTokens) public onlyOwner {
        stakingAndDaoTokens = _stakingAndDaoTokens;
    }
    
    // function to allow admin to set reward rate..
    function setRewardRate(uint256 _rewardRate) public onlyOwner {
        rewardRate = _rewardRate;
    }
    
     // function to allow admin to enable farming..
    function enableFarming() external onlyOwner {
        farmEnabled = true;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_tokenAddress != ZARDtoken, "You can't transfer ZARD token.");
        
        Token(_tokenAddress).transfer(_to, _amount);
    }
}