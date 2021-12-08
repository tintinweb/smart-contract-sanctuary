/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract TestStakingHelper {

    struct StakeAccount {
        address user;
        uint256 stakedTime;
    }
    StakeAccount[] public stakedAccounts;

    uint256 public LaunchTime;
    address public deployer;
    constructor () {
        deployer = msg.sender;
    }

    function stake() external {
        uint256 k = 0;
        for(k = 0; k < stakedAccounts.length; k++) {
            if(msg.sender == stakedAccounts[k].user) {
                return;
            }
        }
        StakeAccount memory oneAccount = StakeAccount(msg.sender, block.timestamp);
        stakedAccounts.push(oneAccount);
    }

    function getStakedLength() external view returns (uint256) {
        return stakedAccounts.length;
    }

    function updateLaunchTime(uint256 _newTime) public {
        require(msg.sender== deployer, "only deployer can update");
        LaunchTime = _newTime;
    }

}