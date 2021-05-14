/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

library CloneLibrary {

    function createClone(address target) internal returns (address result) {
        // Reserve 55 bytes for the deploy code + 17 bytes as a buffer to prevent overwriting
        // other memory in the final mstore
        bytes memory cloneBuffer = new bytes(72);
        assembly {
            let clone := add(cloneBuffer, 32)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), shl(96, target))
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }


    function isClone(address target, address query) internal view returns (bool result) {
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), shl(96, target))
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

/// @author Conjure Finance Team
/// @title StakingRewardsFactory
/// @notice Factory contract to create new instances of StakingRewards
contract StakingRewardsFactory {
    using CloneLibrary for address;

    event NewStakingRewards(address stakingRewards);
    event FactoryOwnerChanged(address newowner);

    address payable public factoryOwner;
    address public stakingRewardsImplementation;

    constructor(
        address _stakingRewardsImplementation
    )
    {
        require(_stakingRewardsImplementation != address(0), "No zero address for stakingRewardsImplementation");

        factoryOwner = msg.sender;
        stakingRewardsImplementation = _stakingRewardsImplementation;
    }

    /**
     * @dev lets anyone mint a new StakingRewards contract
    */
    function stakingRewardsMint(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    )
    external
    returns (address stakingRewardsAddress)
    {
        stakingRewardsAddress = stakingRewardsImplementation.createClone();

        emit NewStakingRewards(stakingRewardsAddress);

        IStakingRewards(stakingRewardsAddress).initialize(
            _owner,
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _rewardsDuration,
            address(this)
        );
    }

    /**
     * @dev lets the owner change the current conjure implementation
     *
     * @param stakingRewardsImplementation_ the address of the new implementation
    */
    function newStakingRewardsImplementation(address stakingRewardsImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(stakingRewardsImplementation_ != address(0), "No zero address for stakingRewardsImplementation_");

        stakingRewardsImplementation = stakingRewardsImplementation_;
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(newOwner != address(0), "No zero address for newOwner");

        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }
}

interface IStakingRewards {
    function initialize(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration,
        address _factoryContract
    ) external;
}