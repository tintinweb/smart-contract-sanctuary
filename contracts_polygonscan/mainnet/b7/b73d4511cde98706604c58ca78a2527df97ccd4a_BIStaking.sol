/**
 *Submitted for verification at polygonscan.com on 2021-09-22
*/

pragma solidity 0.8.4;

interface IFace {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 reward;
        uint256 accumulatedEarned; 
    }
    function rewardPerSecond() external view returns (uint256);
    function endRewardTime() external view returns (uint256);
    function lastRewardTime() external view returns (uint256);
    function startRewardTime() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function getRewardPerSecond(uint256,uint256) external view returns (uint256);
    function userInfo(address) external view returns (UserInfo memory);
    function accRewardPerShare() external view returns (uint256);
}

contract BIStaking {
    
    address private rewardToken     = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private stakeToken      = 0xB1Bf26c7B43D2485Fa07694583d2F17Df0DDe010;
    address private stakingContract = 0xcFfc0C2a7456dE0145dEF3Aab731b36375DEf7D2;

    function pendingReward(address _account) external view returns (uint256) {
        IFace.UserInfo memory user = IFace(stakingContract).userInfo(_account);
        uint256 lpSupply = IFace(stakeToken).balanceOf(address(stakingContract));
        uint256 _endRewardTime = IFace(stakingContract).endRewardTime();
        uint256 _endRewardTimeApplicable = block.timestamp > _endRewardTime ? _endRewardTime : block.timestamp;
        uint256 _lastRewardTime = IFace(stakingContract).lastRewardTime();

        uint256 _accRewardPerShare = IFace(stakingContract).accRewardPerShare() * 1e18;
        if (_endRewardTimeApplicable > _lastRewardTime && lpSupply != 0) {
            uint256 _incRewardPerShare = IFace(stakingContract).getRewardPerSecond(_lastRewardTime, _endRewardTimeApplicable) * 1e36 / lpSupply;
            _accRewardPerShare = _accRewardPerShare + _incRewardPerShare;
        }
        return user.amount * _accRewardPerShare / 1e36 + user.reward - user.rewardDebt;
    }
}