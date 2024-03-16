// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './ReentrancyGuard.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';

contract sgeAirdrop is Ownable, ReentrancyGuard
{
   using SafeMath for uint256;
 
   using SafeERC20 for IERC20;

   uint256 private version;

   bytes32 public DOMAIN_TYPEHASH = keccak256("EIP712Domain(uint256 version,uint256 chainId,address verifyingContract)");

   bytes32 public REWARD_TYPEHASH = keccak256("reward(address invitor,uint256 nonce,uint256 deadline)");

   bool public isInitialized;

   IERC20 public rewardToken;

   uint256 public airdropCount;

   uint256 public baseAirdropAmount;

   uint256 public sgeOffset;

   uint256 public inviteRewardRatio;

   uint256 public hasAirdropAmount;

   uint256 public hasInviteRewards;

   uint256 public hasAirdropCount;

   mapping(address => uint256) public airdropDetails;

   mapping(address => uint) public nonces;

   mapping(address => uint256) public inviteRewards;

   mapping(address => uint256) public inviteCounts;

   event OnAirdrop(address indexed user, uint256 reward);

   event InviteRewardPaid(address indexed invitor, address user, uint256 reward);

   constructor(uint256 version_) {
      version = version_;
   }

   function initialize(
       address rewardToken_,
       uint256 airdropRatio_,
       uint256 airdropCount_,
       uint256 sgeOffset_,
       uint256 inviteRewardRatio_
       ) external onlyOwner
   {
      require(!isInitialized, "Already initialized");

      IERC20 _rewardToken = IERC20(rewardToken_);

      uint256 _totalSupply = _rewardToken.totalSupply();

      uint256 _airdropAmount = _totalSupply.div(100).mul(airdropRatio_);

      isInitialized = true;

      rewardToken = _rewardToken;

      airdropCount = airdropCount_;

      baseAirdropAmount = _airdropAmount.div(airdropCount_);

      sgeOffset = sgeOffset_;

      inviteRewardRatio = inviteRewardRatio_;
   }

   function getChainId() internal view returns (uint256) {
        uint256 chainId_;

        assembly { chainId_ := chainid() }
        
        return chainId_;
    }
   
   function reward(address invitor, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) nonReentrant external 
   {
      require(isInitialized, "hasn't initialized");

      require(hasAirdropCount <= airdropCount, "airdrop is finished");

      uint256 amount = airdropDetails[_msgSender()];

      require(amount == 0, "has airdrop!");

      bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, version, getChainId(), address(this)));

      bytes32 rewardHash = keccak256(abi.encode(REWARD_TYPEHASH, invitor, nonce, deadline));

      bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, rewardHash));
     
      address signatory = ecrecover(digest, v, r, s);
      
      require(signatory == _msgSender(), " invalid signature");
    
      require(nonce == nonces[signatory]++, "invalid nonce");
    
      require(block.timestamp <= deadline, "signature expired");

      _reward(invitor);
   }

   function _reward(address invitor) private
   {
      uint256 _reward_amount = _getReward();

      airdropDetails[_msgSender()] = airdropDetails[_msgSender()].add(_reward_amount);

      rewardToken.safeTransfer(_msgSender(), _reward_amount);

      emit OnAirdrop(_msgSender(), _reward_amount);

      hasAirdropAmount = hasAirdropAmount.add(_reward_amount);

      hasAirdropCount = hasAirdropCount.add(1);

      if(invitor != address(0) && invitor != _msgSender())
      {
          uint256 _invite_reward_amount = _reward_amount.div(100).mul(inviteRewardRatio);

          hasInviteRewards = hasInviteRewards.add(_invite_reward_amount);

          inviteRewards[invitor] = inviteRewards[invitor].add(_invite_reward_amount);

          inviteCounts[invitor] = inviteCounts[invitor].add(1); 

          rewardToken.safeTransfer(invitor, _invite_reward_amount);

          emit InviteRewardPaid(invitor, _msgSender(), _invite_reward_amount);
      }
   }

   function _getReward() private view returns(uint256)
   {
     uint256 _offset = _random();

     return baseAirdropAmount.div(100).mul(100 + _offset - sgeOffset);
   }

   function _random() private view returns(uint256) { 
     if(sgeOffset == 0)
     {
         return 0;
     }

     bytes32 _blockhash = blockhash(block.number - 1);

     uint256 _gasleft = gasleft();

     bytes32 _structHash = keccak256(abi.encode(_blockhash, block.timestamp, _gasleft));
    
     uint256 _randomNumber  = uint256(_structHash);

     uint256 _maxNumber = sgeOffset.mul(661);

     assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}

     return _randomNumber % (sgeOffset + sgeOffset);
   }

   function getSummary() external view returns(
       uint256 _airdropCount,
       uint256 _hasAirdropCount,
       uint256 _baseAirdropAmount,
       uint256 _sgeOffset,
       uint256 _inviteRewardRatio,
       uint256 _hasAirdropAmount
   )
   {
      _airdropCount = airdropCount;

      _hasAirdropCount = hasAirdropCount;

      _baseAirdropAmount = baseAirdropAmount;

      _sgeOffset = sgeOffset;

      _inviteRewardRatio = inviteRewardRatio;

      _hasAirdropAmount = hasAirdropAmount;

      return ( _airdropCount,
               _hasAirdropCount,
               _baseAirdropAmount,
               _sgeOffset,
               _inviteRewardRatio,
               _hasAirdropAmount);
   }

   function getUserSummary(address sender) external view returns(
       uint256 _userAirdropAmount,
       uint256 _userInviterAmount,
       uint256 _userInviterCount
   )
   {
      _userAirdropAmount = airdropDetails[sender];

      _userInviterAmount = inviteRewards[sender];

      _userInviterCount = inviteCounts[sender];

      return (_userAirdropAmount,
                  _userInviterAmount,
                  _userInviterCount);
   }
}