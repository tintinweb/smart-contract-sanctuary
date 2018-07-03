pragma solidity ^0.4.24;

contract Reward {
    
    event RewardPaid(address from, address to, uint256 value, uint256 rewardId);
    
    function payReward(
        address _from, address _to, uint256 _value, uint256 _rewardId) public returns (bool) {
        emit RewardPaid(_from, _to, _value, _rewardId);
        return true;
    }
}