/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

pragma solidity 0.5.8;

/**
 *
 * https://moonshots.farm
 * 
 * Want to own the next 1000x SHIB/DOGE/HEX token? Farm a new/trending moonshot every other day, automagically!
 *
 */

contract MoonshotGovernance {

    BonesToken public bonesToken;
    address blobby = msg.sender;

    mapping(address => Farm) public farms;
    mapping(uint256 => uint256) public newFarmsCount;
    mapping(address => PendingUpdate) public pendingRewards;

    struct PendingUpdate {
        uint256 amount;
        uint256 timelock;
    }

    struct Farm {
        uint256 weeklyRewards;
        uint256 lastClaimed;
    }

    function initiate(address bones) external {
        require(address(bonesToken) == address(0));
        bonesToken = BonesToken(bones);
    }

    function setupFarm(address farm, uint256 rewards) external {
        require(msg.sender == blobby);
        require(rewards > 0 && rewards <= 20000 * (10 ** 18)); // Max 20k BONES (safety)
        require(newFarmsCount[epochDay()] < 2); // Max 2 farms daily (safety)
        require(farms[farm].lastClaimed == 0); // New farm only
        farms[farm] = Farm(rewards, 0);
        newFarmsCount[epochDay()]++;
    }

    function pullWeeklyRewards() external {
        Farm memory farm = farms[msg.sender];
        require(farm.weeklyRewards > 0);
        require(farm.lastClaimed + 7 <= epochDay());
        farms[msg.sender].lastClaimed = epochDay();
        bonesToken.mint(farm.weeklyRewards, msg.sender);
    }

    function updateWeeklyFarmIncentives(address farm, uint256 rewards) external {
        require(msg.sender == blobby);
        if (rewards <= farms[farm].weeklyRewards) { // Lower rewards doesnt require 48 hour timelock
            farms[farm].weeklyRewards = rewards;
        } else {
            pendingRewards[farm] = PendingUpdate(rewards, now + 48 hours);
        }
    }

    // Requires 48 hours to pass
    function triggerPendingFarmRewardsUpdate(address farm) external {
        PendingUpdate memory pending = pendingRewards[farm];
        require(pending.timelock > 0 && pending.timelock < now);
        farms[farm].weeklyRewards = pending.amount;
        delete pendingRewards[farm];
    }

    // Can transition to DAO (after below timelock upgrade)
    address public nextGov;
    uint256 public nextGovTime;

    function beginGovernanceRequest(address newGovernance) external {
        require(msg.sender == blobby);
        nextGov = newGovernance;
        nextGovTime = now + 48 hours;
    }

    // Requires 48 hours to pass
    function triggerGovernanceUpdate() external {
        require(now > nextGovTime && nextGov != address(0));
        bonesToken.updateGovernance(nextGov);
    }

    function epochDay() public view returns (uint256) {
        return now / 86400;
    }

}

interface Farm {
    function setWeeksRewards(uint256 amount) external;
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

interface BonesToken {
    function updateGovernance(address newGovernance) external;
    function mint(uint256 amount, address recipient) external;
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}