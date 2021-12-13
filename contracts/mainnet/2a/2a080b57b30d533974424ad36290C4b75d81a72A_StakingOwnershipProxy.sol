// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function level1TokenIdsForAddress(address owner) external view returns (uint256[] memory);
    function level2TokenIdsForAddress(address owner) external view returns (uint256[] memory);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract StakingOwnershipProxy {
    address public stakingContract;
    address public nftContract;

    string public name = "StakingOwnershipProxy";
    string public symbol = "OWNED";

    constructor(address _stakingContract, address _nftContract) {
        stakingContract = _stakingContract;
        nftContract = _nftContract;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        // staking contract methods to check balance
        uint256[] memory level1TokenIds = IStaking(stakingContract).level1TokenIdsForAddress(owner);
        uint256[] memory level2TokenIds = IStaking(stakingContract).level2TokenIdsForAddress(owner);

        // actual nft balance
        uint256 actualBalance = IERC721(nftContract).balanceOf(owner);

        return actualBalance + level1TokenIds.length + level2TokenIds.length;
    }
}