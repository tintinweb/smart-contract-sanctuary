/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity ^0.8.4;

contract StakingPool{
	uint256 public totalTokenAmount;
	uint256 public totalStakedTokenAmount;
		
	function stake(address _forUser, uint256 _amount, uint256 _lockBlockNumber) external returns (uint256) {
        return 321;
    }

	function ustake(uint256 _lockRecordId) external returns (bool success){
			return true;
	}
		
	function harvest(uint256 _lockRecordId, address _to) public returns (bool success) {
        return true;
    }
    
    function pendingReward(address _user) public view returns (uint256 sushiReward) {
        return 123;
    }
    
    
    function getUserStakeToken(address _user) public view returns(uint256 _tokenAmount, uint256 _stakedTokenAmount){
        return (1, 2);
    }
}