/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// NOTE: This is just a test contract, please delete me

contract ETHPool {

    /**
     * @notice Dynamic array with all the stakeholders.
     */
    address[] internal stakeholders;
    /**
    * @notice The stakes for each stakeholder.
    */
    mapping (address => uint256) stakes;
    /**
    * @notice The accumulated rewards for each stakeholder.
    */
    mapping(address => uint256) internal rewards;
    /**
    * @notice The total stake in the contract.
    */
    uint256 totalStake;
    /**
    * @notice The address of th Team.
    */
    address owner;

    constructor() {
      owner = msg.sender;
    }


    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
   function isStakeholder(address _address) public view returns(bool, uint256) {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder) private {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }
   
   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder) private {
       (bool _isStakeholder, uint256 idx) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[idx] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

    /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of wei staked.
    */
   function stakeOf(address _stakeholder) public view returns(uint256) {
       return stakes[_stakeholder];
   }
   
   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes() public view returns(uint256) {
       return totalStake;
   }

   /**
    * @notice A method for a stakeholder to create a stake.
    */
   function deposit() external payable {
       assert(msg.value > 0);
       if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender] + msg.value;
       totalStake = totalStake + msg.value;
   }  
  
   /**
    * @notice A method to allow a stakeholder to check his rewards.
    * @param _stakeholder The stakeholder to check rewards for.
    */
   function rewardOf(address _stakeholder) public view returns(uint256) {
       return rewards[_stakeholder];
   }
   /**
    * @notice A simple method that calculates the rewards for each stakeholder.
    * @param _stakeholder The stakeholder to calculate rewards for.
    */
   function calculateReward(address _stakeholder) public view returns(uint256) {
       return stakes[_stakeholder] * 100 / totalStake;
   }
   /**
    * @notice A method to distribute rewards to all stakeholders.
    */
   function distributeRewards() external payable onlyOwner {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];  
           uint256 reward = calculateReward(stakeholder);
           rewards[stakeholder] = rewards[stakeholder] + (msg.value / 100 * reward);
       }
   } 
   /**
    * @notice A method to allow a stakeholder to withdraw.
    */
   function withdraw() external {
        assert(stakes[msg.sender]>0);
        uint256 userStake = stakes[msg.sender];
        uint256 userCashout = userStake + rewards[msg.sender];
        removeStakeholder(msg.sender);
        stakes[msg.sender] = 0;
        rewards[msg.sender] = 0;
        totalStake = totalStake - userStake;
        address payable user = payable(msg.sender);
        user.transfer(userCashout);
   }

}