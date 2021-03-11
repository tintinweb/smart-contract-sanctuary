// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IStakingRewards.sol";
import "./interfaces/IAlchemyFactory.sol";

contract AlchemyRouter {

    // event for distribution
    event FeeDistribution(address treasury, address stakingrewards, uint256 amount);

    IStakingRewards public stakingRewards;
    address payable public treasury;
    address public owner;
    address public alchemyFactory;

    constructor(IStakingRewards _stakingRewards, address payable _treasury, address _alchemyFactory) {
        stakingRewards = _stakingRewards;
        treasury = _treasury;
        alchemyFactory = _alchemyFactory;
        owner = msg.sender;
    }

    function distribute() internal {
        uint256 amount = msg.value;
        treasury.transfer(amount / 2);
        payable(address(stakingRewards)).transfer(amount / 2);
        stakingRewards.notifyRewardAmount(amount / 2);
    }

    /**
    * fallback function for collection funds
    */
    fallback() external payable {
        distribute();
    }

    receive() external payable {
        distribute();
    }

    function newStakingrewards(IStakingRewards newRewards) public {
        require(msg.sender == owner, "Only owner");
        stakingRewards = newRewards;
    }

    function newTreasury(address payable newTrewasury) public {
        require(msg.sender == owner, "Only owner");
        treasury = newTrewasury;
    }

    function newAlchemyFactory(address newAlchemyAddress) public {
        require(msg.sender == owner, "Only owner");
        alchemyFactory = newAlchemyAddress;
    }

    function newAlchemyFactoryOwner(address payable newFactoryOwner) public {
        require(msg.sender == owner, "Only owner");
        IAlchemyFactory(alchemyFactory).newFactoryOwner(newFactoryOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IAlchemyFactory {

    function newFactoryOwner(address payable newOwner) external;
}