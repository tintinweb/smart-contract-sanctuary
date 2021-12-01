/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

pragma solidity 0.5.7;
contract IStaking{
  function getStatsData(address _staker) external view returns(uint, uint, uint, uint, uint);
  function getStakerData(address _staker) public view returns(uint256, uint256);
  uint public stakingStartTime;
  uint256 public stakingPeriod;
}
contract CombinedDataForStaking {
  function getData(address _user, address[] memory _stakingContract) public
  view
  returns
  (uint[] memory userStaked,
    uint[] memory userAccuredRewards,
    uint[] memory totalStaked,
    uint[] memory totalRewards,
    uint[] memory stakingStartTime,
    uint[] memory stakingPeriod)
  {
    userStaked = new uint[](_stakingContract.length);
    userAccuredRewards = new uint[](_stakingContract.length);
    totalStaked = new uint[](_stakingContract.length);
    totalRewards = new uint[](_stakingContract.length);
    stakingStartTime = new uint[](_stakingContract.length);
    stakingPeriod = new uint[](_stakingContract.length);
    for(uint i=0;i<_stakingContract.length;i++) {
      IStaking staking = IStaking(_stakingContract[i]);
      (totalStaked[i],totalRewards[i],,,userAccuredRewards[i]) = staking.getStatsData(_user);
      (userStaked[i],) = staking.getStakerData(_user);
      stakingStartTime[i] = staking.stakingStartTime();
      stakingPeriod[i] = staking.stakingPeriod();
    }
  }
}