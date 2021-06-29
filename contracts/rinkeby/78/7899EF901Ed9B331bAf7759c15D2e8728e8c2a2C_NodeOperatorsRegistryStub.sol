/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// File: NodeOperatorsRegistryStub.sol

contract NodeOperatorsRegistryStub {
    uint256 public id = 1;
    bool public active = true;
    address public rewardAddress;
    uint64 public stakingLimit = 200;
    uint64 public totalSigningKeys = 400;

    constructor(address _rewardAddress) {
        rewardAddress = _rewardAddress;
    }

    function getNodeOperator(uint256 _id, bool _fullInfo)
        external
        view
        returns (
            bool _active,
            string memory _name,
            address _rewardAddress,
            uint64 _stakingLimit,
            uint64 _stoppedValidators,
            uint64 _totalSigningKeys,
            uint64 _usedSigningKeys
        )
    {
        _active = active;
        _rewardAddress = rewardAddress;
        _stakingLimit = stakingLimit;
        _totalSigningKeys = totalSigningKeys;
    }

    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external {
        stakingLimit = _stakingLimit;
    }

    function setId(uint256 _id) public {
        id = _id;
    }

    function setActive(bool _active) public {
        active = _active;
    }

    function setRewardAddress(address _rewardAddress) public {
        rewardAddress = _rewardAddress;
    }

    function setStakingLimit(uint64 _stakingLimit) public {
        stakingLimit = _stakingLimit;
    }

    function setTotalSigningKeys(uint64 _totalSigningKeys) public {
        totalSigningKeys = _totalSigningKeys;
    }
}