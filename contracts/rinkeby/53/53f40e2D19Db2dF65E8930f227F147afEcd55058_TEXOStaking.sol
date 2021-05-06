pragma solidity 0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./TEXOToken.sol";

/**
 * @title TEXO Token (tEXO)
 * @author Tran Quang Huy
 */
contract TEXOStaking is Ownable {
    using SafeMath for uint256;

    struct StakeHolder {
        address owner;
        uint256 stakeAmount;
        uint256 rewards;
        uint256 index;
    }

    uint256 public totalStakes;
    TEXOToken internal tEXOTokenInterface;

    // Emitted when somebody newly stakes.
    event StakerAdded(address stakerAddress, uint256 stakeAmount);

    // Emitted when somebody newly stakes.
    event StakerRemoved(address stakerAddress);

    address[] public stakeholders;

    mapping(address => StakeHolder) public stakeholdersMap;

    constructor(address texoTokenAddress) public {
        tEXOTokenInterface = TEXOToken(texoTokenAddress);
    }
    
    modifier mustBeStaker(address anyAddress) {
        require(stakeholdersMap[anyAddress].owner == msg.sender, "Only a staker allowed");
        _;
    }

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param verifyAddress The address to verify.
     * @return bool: Whether the address is a stakeholder,
     */
    function isStakeholder(address verifyAddress) public view returns (bool) {
        return stakeholdersMap[verifyAddress].owner != address(0);
    }

    /**
     * @notice A method to add a new stakeholder internally.
     * @param stakeholderAddress The stakeholder to add.
     * @param stakeAmount The amount the staker wishes to stake
     */
    function addNewStakeholder(address stakeholderAddress, uint256 stakeAmount) internal {
        uint256 stakeholderLength = stakeholders.length;
        StakeHolder memory stakeHolder = StakeHolder({
            owner: stakeholderAddress,
            stakeAmount: stakeAmount,
            index: stakeholderLength,
            rewards: 0
        });

        stakeholdersMap[stakeholderAddress] = stakeHolder;
        stakeholders.push(stakeholderAddress);
        totalStakes.add(stakeAmount);

        emit StakerAdded(stakeholderAddress, stakeAmount);
    }

    /**
     * @notice A method to remove a stakeholder internally.
     * @param stakeholderAddress The stakeholder to remove.
     */
    function removeStakeholder(address stakeholderAddress) internal {
        StakeHolder memory staker = stakeholdersMap[stakeholderAddress];
        uint256 stakerIndex = staker.index;

        uint256 stakeAmount = staker.stakeAmount;

        totalStakes.sub(stakeAmount);

        delete stakeholdersMap[stakeholderAddress];
        delete stakeholders[stakerIndex];

        emit StakerRemoved(stakeholderAddress);
    }

    /**
     * @notice A method for a stakeholder to create a stake publicly.
     * @param stakeAmount The size of the stake to be created.
     */
    function createStake(uint256 stakeAmount) public {
        if (stakeholdersMap[msg.sender].stakeAmount == 0) {
            addNewStakeholder(msg.sender, stakeAmount);
        } else {
            stakeholdersMap[msg.sender].stakeAmount.add(stakeAmount);
            totalStakes.add(stakeAmount);
        }

        tEXOTokenInterface.transferFrom(msg.sender, address(this), stakeAmount);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param stakeAmount The size of the stake to be removed.
     */
    function removeStake(uint256 stakeAmount) public mustBeStaker(msg.sender) {
        stakeholdersMap[msg.sender].stakeAmount.sub(stakeAmount);

        if (stakeholdersMap[msg.sender].stakeAmount == 0) {
            removeStakeholder(msg.sender);
        }
    }

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param stakeHolderAddress The stakeholder to check rewards for.
     */
    function rewardOf(address stakeHolderAddress) public view returns (uint256) {
        return stakeholdersMap[stakeHolderAddress].rewards;
    }

     /**
      * @notice A method to retrieve the stake for a stakeholder.
      * @param stakeHolderAddress The stakeholder to retrieve the stake for.
      * @return uint256 The amount of wei staked.
      */
    function stakeOf(address stakeHolderAddress) public view returns(uint256) {
        return stakeholdersMap[stakeHolderAddress].stakeAmount;
    }

    /**
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param stakeHolderAddresses The stakeholder to calculate rewards for.
     */
    function calculateReward(address stakeHolderAddresses) public view returns (uint256) {
        
    }

    /**
     * @notice A method to distribute rewards to all stakeholders from db.
     */
    function distributeRewards(address[] memory stakeHolderAddresses) public onlyOwner {
        
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public mustBeStaker(msg.sender) {
        
    }
}