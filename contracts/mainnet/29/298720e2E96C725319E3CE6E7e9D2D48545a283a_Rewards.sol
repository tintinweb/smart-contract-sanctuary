// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Token.sol";
import "./VerifySignature.sol";

contract Rewards is Context, Ownable {
  using SafeMath for uint256;
  
  struct RewardClaim {
    /* Account Key & Signature */
    address accountKey;
    uint128 gameUuid;
    uint256 oldBalance;
    uint256 newBalance;
    string signature;
  }
  
  // Game UUID > Rewarded
  mapping (uint128 => uint256) private _gameRewarded;
  
  // Account > Running Balance
  mapping (address => uint256) private _balances;
  
  Token _rewardToken;
  
  // Total Reward Supply (All Games)
  uint256 private _totalRewardSupply;
  
  // Total Rewarded (All Games)
  uint256 private _totalRewarded;

  /**
   * Event for a Reward Claim
   */
  event RewardClaimed(address indexed receiver, address indexed account, uint256 value);

  /**
   * Event for a Reward Withdrawal
   */
  event RewardWithdrawn(address indexed receiver, uint256 value);

  constructor(address rewardToken, uint256 totalSupply) {
    _rewardToken = Token(rewardToken);
    _totalRewardSupply = totalSupply;
  }
  
  /**
   * @dev Returns the contract owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }
  
  /**
   * Claim Reward via Hash & Signature
   */
  function claimReward(RewardClaim[] memory rewardClaims) public returns (uint256) {
    // Owner of the contract
    address contractOwner = owner();
      
    // Receiver of Reward Tokens
    address receiver = _msgSender();
    
    // For transfer at the end
    uint256 totalReward = 0;
    
    for (uint i=0; i<rewardClaims.length; i++) {
        RewardClaim memory rewardClaim = rewardClaims[i];
        
        bool signatureVerified = VerifySignature.verify(
            contractOwner,
            rewardClaim.accountKey,
            receiver,
            rewardClaim.gameUuid,
            rewardClaim.oldBalance,
            rewardClaim.newBalance,
            rewardClaim.signature
        );
        
        // New Balance must be Greater than the Old
        require(
            rewardClaim.newBalance > rewardClaim.oldBalance, 
            "Rewards: New Balance must be Greater than Old Balance"
        );
        
        // Verify that the Signature Matches
        require(
            signatureVerified, 
            "Rewards: Signature Invalid"
        );
        
        // Verify that the balance hasn't changed since the hash was generated.
        require(
            _balances[rewardClaim.accountKey] == rewardClaim.oldBalance, 
            "Rewards: Balance Changed Since Hash Generated"
        );
        
        // Get Reward (newBalance - oldBalance)
        uint256 reward = rewardClaim.newBalance.sub(rewardClaim.oldBalance);
        
        // Update Total Rewarded
        _totalRewarded = _totalRewarded.add(reward);
        
        // Update Game Rewarded Total
        _gameRewarded[rewardClaim.gameUuid] = _gameRewarded[rewardClaim.gameUuid].add(reward);
        
        // Add to Historical Balances
        _balances[rewardClaim.accountKey] = _balances[rewardClaim.accountKey].add(reward);
        
        // Verify that the new Balance is in expected state 
        require(
            _balances[rewardClaim.accountKey] == rewardClaim.newBalance, 
            "Rewards: New Balance is not in Expected State"
        );
        
        // Add to Total Reward (for Transfer at the end)
        totalReward = totalReward.add(reward);
    
        // Emit Success Claimed (for Account & Receiver)
        emit RewardClaimed(receiver, rewardClaim.accountKey, reward);
    }
        
    // Emit Success (for Receiver)
    emit RewardWithdrawn(receiver, totalReward);
    
    _rewardToken.transfer(receiver, totalReward);
    
    return totalReward;
  }
  
  /**
   * Total Rewards Claimed by Account
   */
  function accountBalance(address accountKey) external view returns (uint256) {
    return _balances[accountKey];
  }
  
  /**
   * Retrieve Game Rewarded Supply
   */
  function gameRewardedSupply(uint128 gameUuid) external view returns (uint256) {
    return _gameRewarded[gameUuid];
  }
  
  /**
   * Retrieve Total Token Reward Supply
   */
  function totalRewardSupply() external view returns (uint256) {
    return _totalRewardSupply;
  }
  
  /**
   * Retrieve Total Tokens Rewarded
   */
  function totalRewarded() external view returns (uint256) {
    return _totalRewarded;
  }
  
  /**
   * Retrieve Total Game Remaining Supply
   */
  function totalRemainingSupply() external view returns (uint256) {
    return _totalRewardSupply.sub(_totalRewarded);
  }
  
  /*
   * Return Tokens back to Owner (useful if a contract upgrade takes place)
   */
  function transferBackToOwner() public onlyOwner returns (uint256) {
    address selfAddress = address(this);
    uint256 balanceOfContract = _rewardToken.balanceOf(selfAddress);
    _rewardToken.transfer(owner(), balanceOfContract);
    return balanceOfContract;
  }
}