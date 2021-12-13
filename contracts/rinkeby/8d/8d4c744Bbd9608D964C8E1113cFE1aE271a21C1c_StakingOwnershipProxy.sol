// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Staking {
    function level1TokenIdsForAddress(address owner) external view returns (uint256[] memory);
    function level2TokenIdsForAddress(address owner) external view returns (uint256[] memory);
}

contract StakingOwnershipProxy {
    address public stakingContract;

    string public name = "StakingOwnershipProxy";
    string public symbol = "OWNED";

    constructor(address _stakingContract) {
        stakingContract = _stakingContract;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        uint256[] memory level1TokenIds = Staking(stakingContract).level1TokenIdsForAddress(owner);
        uint256[] memory level2TokenIds = Staking(stakingContract).level2TokenIdsForAddress(owner);

        return level1TokenIds.length + level2TokenIds.length;
    }
}