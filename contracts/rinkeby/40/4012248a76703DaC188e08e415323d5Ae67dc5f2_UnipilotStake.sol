//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IUnipilotStake {
    function getBoostMultiplier(address userAddress, address poolAddress, uint256 tokenId) external view returns (uint256);
    function userMultipliers(address userAddress, address poolAddress) external view returns (uint256);
}

contract UnipilotStake is IUnipilotStake {
    mapping (address=> mapping(address=> uint256)) public override userMultipliers;

    function getBoostMultiplier(address userAddress, address poolAddress, uint256 tokenId)
        external
        view
        override
        returns (uint256){
            return userMultipliers[userAddress][poolAddress];
        }

    function insertMultiplier (address user, address pool, uint256 multiplier) external {
        userMultipliers[user][pool] = multiplier;
    }
}