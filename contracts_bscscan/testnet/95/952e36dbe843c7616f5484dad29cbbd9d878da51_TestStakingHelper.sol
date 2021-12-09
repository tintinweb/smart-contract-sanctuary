/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract TestStakingHelper {

    address[] public stakedAccounts;
    mapping(address => uint256) public stakedTime;

    uint256 public LaunchTime;
    address public deployer;
    constructor () {
        deployer = msg.sender;
    }

    function stake() external {
        uint256 k = 0;
        for(k = 0; k < stakedAccounts.length; k++) {
            if(msg.sender == stakedAccounts[k]) {
                return;
            }
        }
        stakedAccounts.push(msg.sender);
        stakedTime[msg.sender] = block.timestamp;
    }

    function getStakedLength() external view returns (uint256) {
        return stakedAccounts.length;
    }

    function updateLaunchTime(uint256 _newTime) public {
        require(msg.sender== deployer, "only deployer can update");
        LaunchTime = _newTime;
    }

}