/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract StakeRewardsStorage is Ownable {
    
    address public rewardsContract;
    
    struct RewardClaim {
        uint256 claimDate;
        address walletAddress;
        uint256 calcBase;
        uint32 assetType;
        uint32 monthStep;
    }
    
    mapping (bytes32 => RewardClaim) public paidRewards;
    mapping (uint256 => bytes32) public rewardByIndex;
    uint256 public rewardIndex;

    function checkClaim (address _wallet, uint256 _calcBase, uint32 _assetType, uint32 _monthStep) public view returns (bool _paid) {
        bytes32 rewardHash = (keccak256(abi.encode(_wallet, _calcBase, _assetType, _monthStep)));
        if (paidRewards[rewardHash].claimDate > 0) {
            return (true);
        } else {
            return (false);
        }
    }
    
    function storeClaim (address _wallet, uint256 _calcBase, uint32 _assetType, uint32 _monthStep) public returns (bool success) {
        require(msg.sender == rewardsContract, "Invalid caller");
        bytes32 rewardHash = (keccak256(abi.encode(_wallet, _calcBase, _assetType, _monthStep)));
        require(paidRewards[rewardHash].claimDate == 0, "Already on storage");
        paidRewards[rewardHash] = RewardClaim(block.timestamp, _wallet, _calcBase, _assetType, _monthStep);
        rewardByIndex[rewardIndex] = rewardHash;
        rewardIndex += 1;
        return (true);
    }
    
    function setRewardsContract(address _rewardsContract) public onlyOwner {
        rewardsContract = _rewardsContract;
    }
    
}