/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IdQuick {
    function QUICKBalance(address _account) external view returns (uint256 quickAmount_);
     //returns how much QUICK someone gets for depositing dQUICK
    function dQUICKForQUICK(uint256 _dQuickAmount) external view returns (uint256 quickAmount_);

}


interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

struct StakingRewardsInfo {
    address stakingRewards;
    uint rewardAmount;
    uint duration;
}

interface IStakingRewardsFactory {

  function rewardTokens(uint256 _index) view external returns (address);
  function stakingRewardsInfoByRewardToken(address _rewardToken) view external returns(StakingRewardsInfo memory);

}

contract QuickswapVoting {
  IERC20 constant public QUICK = IERC20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  IdQuick constant public DRAGONLAIR = IdQuick(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
  IStakingRewardsFactory constant public SRF = IStakingRewardsFactory(0x5D7284e0aCF4dc3b623c93302Ed490fC97aCA8A4);
  // rewardTokens(uint256)
  bytes4 REWARD_TOKENS_SELECTOR = 0x7bb7bed1;


  function balanceOf(address _owner) external view returns (uint256 balance_) {
    balance_ = QUICK.balanceOf(_owner) + DRAGONLAIR.QUICKBalance(_owner);
    uint256 dQuick;
    for(uint256 i; true; i++) {      
      (bool success, bytes memory result) = address(SRF).staticcall(abi.encodeWithSelector(REWARD_TOKENS_SELECTOR, i));
      if(success == true) {
        address rewardTokenAddress = abi.decode(result, (address));
        StakingRewardsInfo memory stakingRewardsInfo = SRF.stakingRewardsInfoByRewardToken(rewardTokenAddress);        
        dQuick += IERC20(stakingRewardsInfo.stakingRewards).balanceOf(_owner);
      }
      else {
        break;
      }
    }
    balance_ += DRAGONLAIR.dQUICKForQUICK(dQuick);
  }
 
}