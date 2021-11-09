// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract RepUSDVault is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using Address for address;
    
    //RepUSD Token Interface
    IBEP20 public repUSDToken;
    
    struct UserInfo {
        uint256 reputation;     // User Reputation Amount
        uint256 rewards;        // User Rewards Amount
        bool rewardMethod;      // User Rewards Method: APY | Profit
        uint256 lastRewardDate; // Last Reward Date
    }
    
    uint256 public totalBorrowedAmount;     // total Borrowed Amount of users
    uint256 private operatorWithdrawAmount;      // Amount of RepUSD which operator used
    mapping(address => UserInfo) public userInfo;   // userInfo
    
    uint256 public REWARD_MINT_RATE = 70;       // Reward Minting Rate: 70%
    
    uint256 public REWARD_INTEREST_RATE = 180;  // Interest Mode: 18%
    uint256 public REWARD_PROFIT_RATE = 165;    // Profit Mode: 16.5%
    
    address public adminAddress;    // Admin Wallet Address which pays gas fee
    address public operatorAddress; // Operator Address
    
    event UserBorrowed(address user, uint256 amount);   // Emits when user borrowed RepUSD
    event UserRedeemed(address user, uint256 amount);   // Emits when user withdraw his investments in other dapps
    event ClaimReward(address user, uint256 amount);    // Emits when user claim his rewards
    event ChangeRewardMethod(address user, bool method);    // Emits when user changed his reward method
    event OperatorWithdraw(uint256 amount);     // Emits when operator withdrawed RepUSD from Vault
    
    /**
        @dev constructor
        @param _repUSDToken RepUSD Token Contract Address
        @param _adminAddress Address of Admin Wallet 
        @param _operatorAddress Address of Operator
    */
    constructor(IBEP20 _repUSDToken, address _adminAddress, address _operatorAddress) {
        repUSDToken = _repUSDToken;
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }
    
    /**
     * @dev set admin address
     * @ callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;
    }

    /**
     * @dev set operator address
     * @ callable by owner
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }
    
    /**
        @dev set minting rate of user reward
        @param rate Minting rate
        @ rate <= 100% & callable by owner
    */
    function setRewardMintRate(uint256 rate) external onlyOwner {
        require(rate <= 100, "Mint Rate couldn't more than 100%");
        REWARD_MINT_RATE = rate;
    }
    
    /**
        @dev set reward rate of Interest Method
        @param rate Reward rate
        @ rate <= 1000(100%) & callable by owner
    */
    function setRewardInterestRate(uint256 rate) external onlyOwner {
        require(rate <= 1000, "Mint Rate couldn't more than 100%");
        REWARD_INTEREST_RATE = rate;
    }
    
    /**
        @dev set reward rate of Profit Method
        @param rate Reward rate
        @ rate <= 1000(100%) & callable by owner
    */
    function setRewardProfitRate(uint256 rate) external onlyOwner {
        require(rate <= 1000, "Mint Rate couldn't more than 100%");
        REWARD_PROFIT_RATE = rate;
    }
    
    /**
        @dev borrows reputation amount of RepUSD and send 0.5% fee to admin wallet
        @param userAddress address of user who borrow RepUSD
        @param reputation  user's calculated reputation amount in other pools. 75% for normal pool and 90% for RepUSD pools
        @param adminFeeAmount calculated adminFeeAmount for the borrow. 0.5% for each pool.
        @ user's current reputation < reputation & callable by adminAddress & not paused
    */
    function borrow(address userAddress, uint256 reputation, uint256 adminFeeAmount) external whenNotPaused onlyAdmin returns(uint256) {
        require(userInfo[userAddress].reputation < reputation, "Cannot borrow less than current borrow amount.");
        
        _updateReward(userAddress);
        
        UserInfo storage user = userInfo[userAddress];
        uint256 amountToMint = reputation.sub(user.reputation);
        repUSDToken.mint(amountToMint);
        repUSDToken.mint(adminFeeAmount);
        repUSDToken.safeTransfer(adminAddress, adminFeeAmount);
        user.reputation = user.reputation.add(amountToMint);
        totalBorrowedAmount = totalBorrowedAmount.add(amountToMint);
        emit UserBorrowed(userAddress, amountToMint);
        return amountToMint;
    }
    
    /**
        @dev deduct reputation amount of RepUSD
        @param userAddress address of user who borrowed RepUSD
        @param reputation  user's calculated reputation amount in other pools. 75% for normal pool and 90% for RepUSD pools
        @ user's current reputation > reputation & balanceOf(vault) > amountToBurn & callable by adminAddress & not paused
    */
    function deduct(address userAddress, uint256 reputation) external whenNotPaused onlyAdmin returns(uint256) {
        require(userInfo[userAddress].reputation > reputation, "Cannot deduct more than current borrow amount.");
        
        _updateReward(userAddress);
        
        UserInfo storage user = userInfo[userAddress];
        uint256 amountToBurn = user.reputation.sub(reputation);
    
        require(repUSDToken.balanceOf(address(this)) >= amountToBurn, "Cannot deduct more than current vault balance");
        
        repUSDToken.burn(amountToBurn);
        user.reputation = user.reputation.sub(amountToBurn);
        totalBorrowedAmount = totalBorrowedAmount.sub(amountToBurn);
        emit UserRedeemed(userAddress, amountToBurn);
        return amountToBurn;
    }
    
    /**
        @dev changes reward method of user
        @param method reward method. false: interest, true: profit
        @ user's current reward method != newMethod
    */
    function changeRewardMethod(bool method) external {
        require(userInfo[msg.sender].rewardMethod != method, "Reward Method is same.");
        
        _updateReward(msg.sender);
        
        userInfo[msg.sender].rewardMethod = method;
        emit ChangeRewardMethod(msg.sender, method);
    }
    
    /**
        @dev claim Reward of user
        @param amount claim amount
        @ user's current rewards amount >= amount & vault balance >= amount & not paused
    */
    function claimReward(uint256 amount) external whenNotPaused returns(uint256) {
        _updateReward(msg.sender);
        require(userInfo[msg.sender].rewards >= amount, "Cannot claim more than reward amount.");
        require(repUSDToken.balanceOf(address(this)) >= amount, "Vault has low balance than amount.");
        
        repUSDToken.safeTransfer(msg.sender, amount);
        userInfo[msg.sender].rewards = userInfo[msg.sender].rewards.sub(amount);
        emit ClaimReward(msg.sender, amount);
        return amount;
    }
    
    /**
        @dev withdraw amount of RepUSD from vault
        @param amount withdraw amount
        @ withdrawable amount >= amount
    */
    function withdraw(uint256 amount) external onlyOperator returns(uint256) {
        require(getAvailableWithdrawAmount() >= amount, "Operator can't withdraw more than available amount");
        
        repUSDToken.safeTransfer(msg.sender, amount);
        operatorWithdrawAmount = operatorWithdrawAmount.add(amount);
        emit OperatorWithdraw(amount);
        return amount;
    }
    
    /**
        @dev get available withdraw amount for the operator
        @ calculated available amount > balanceOfVault then make it as balanceOfVault for the safety
    */
    function getAvailableWithdrawAmount() public onlyOperator view returns(uint256) {
        uint256 withdrawableAmount = totalBorrowedAmount.sub(operatorWithdrawAmount);
        uint256 balanceOfVault = repUSDToken.balanceOf(address(this));
        
        return withdrawableAmount < balanceOfVault ? withdrawableAmount : balanceOfVault;
    }
    
    /**
        @dev get user's daily reward amount
        @param userAddress user wallet address
    */
    function getUserDayReward(address userAddress) external view returns(uint256) {
        return _calcDayReward(userAddress);
    }
    
    /**
        @dev get user's current claimable amount
        @param userAddress user wallet address
    */
    function getUserTotalReward(address userAddress) external view returns(uint256) {
        UserInfo storage user = userInfo[userAddress];
        uint256 calcedReward = _calcTotalReward(userAddress);
        uint256 totalReward = user.rewards.add(calcedReward);
        return totalReward;
    }
    
    /**
        @dev update user's reward
        @param userAddress user wallet address
    */
    function _updateReward(address userAddress) internal whenNotPaused {
        UserInfo storage user = userInfo[userAddress];
        uint256 reward = _calcTotalReward(userAddress);
        if (reward > 0) {
            repUSDToken.mint(reward.mul(REWARD_MINT_RATE).div(100));
            user.rewards = user.rewards.add(reward);
        }
        user.lastRewardDate = block.timestamp;
    }
    
    /**
        @dev calculate user's total reward
        @param userAddress user wallet address
    */
    function _calcTotalReward(address userAddress) internal view returns(uint256) {
        UserInfo storage user = userInfo[userAddress];
        uint256 secondsElapsed = block.timestamp.sub(user.lastRewardDate);
        uint256 rewardDays = secondsElapsed.sub(secondsElapsed.mod(1 days)).div(1 days);
        uint256 rewardRate = _calcDayReward(userAddress);
        uint256 reward = rewardRate.mul(rewardDays);
        return reward;
    }
    
    /**
        @dev calculate user's daily reward
        @param userAddress user wallet address
    */
    function _calcDayReward(address userAddress) internal view returns(uint256) {
        UserInfo storage user = userInfo[userAddress];
        uint256 dayReward = user.reputation;
        if (user.rewardMethod == false) {   //Interest : 18% APY
            dayReward = dayReward.mul(REWARD_INTEREST_RATE).div(1000).div(365);
        }
        else {  //Profit Share: 16.5%
            dayReward = dayReward.mul(REWARD_PROFIT_RATE).div(1000).div(365);
        }
        return dayReward;
    }
}