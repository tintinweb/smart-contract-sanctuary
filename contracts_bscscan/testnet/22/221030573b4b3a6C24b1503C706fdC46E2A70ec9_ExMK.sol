// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

interface Staking {
  struct Deposit {
		uint256 amount;
    uint256 withdrawn;
    uint256 percent;
    uint256 percentPer;
    uint256 accrualPeriod;
    uint256 minTerm;
		uint256 timestamp;
    uint256 tw;
    uint256 status;
	}

  struct User {
		Deposit[] deposits;
	}
}

contract ExMK is Staking{

  address private _owner;
  Staking constant public staking = Staking(0xd5779f76724be97a0311ccFD082f5b1905366d21);

  mapping (address => Staking.User) internal users;

  function getUser(address _user) public view returns(Staking.User memory){
    User storage user = users[_user];
    return user;
  }
}