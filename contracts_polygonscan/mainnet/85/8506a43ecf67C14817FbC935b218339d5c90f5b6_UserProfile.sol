/**
 *Submitted for verification at polygonscan.com on 2021-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserProfile 
{
	struct Profile 
	{
		string avatar;
		string name;
		string info;
	}

	mapping(address => Profile) internal userProfiles_;

	function update(string memory _avatar, string memory _name, string memory _info) public 
	{
		Profile storage userProfile = userProfiles_[msg.sender];	
		userProfile.avatar = _avatar;
		userProfile.name = _name;
		userProfile.info = _info;
	}

	function destroy() public
	{
		delete(userProfiles_[msg.sender]);
	}

	function get(address _user) external view returns (Profile memory) 
	{
		return userProfiles_[_user];
	}
}