// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.5;

//import "@openzeppelin/contracts/math/SafeMath.sol";
        
contract FarmMath {
    //using SafeMath for uint256;

    event UpdatedReward(uint256 currentRewardRate_);        
    event UpdatedTotalStaked(uint256 totalStaked_);        

    uint256 public blockReward = 842415627000000000000000000;
    uint256 public currentRewardRate;
    uint256 public totalStaked;
    
    string public name;
    
    constructor(
        string memory _name
    ) public {
        name = _name;
    }

    function updateReward() public {
        // Block reward divided by total staked
        currentRewardRate = blockReward / totalStaked;
        emit UpdatedReward(currentRewardRate);
    }
    
    function newTotalStaked(uint256 newTotal) public {
        // Block reward divided by total staked
        totalStaked = newTotal;
        updateReward();
        emit UpdatedTotalStaked(totalStaked);
    }
    
        

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}