/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IGetStakingPower {
    function getStakingPower(address _erc721, uint256 _tokenId) external view returns (uint256);
}

// File: contracts/StakingPower.sol

pragma solidity =0.8.0;


contract DefaultGetStakingPower is IGetStakingPower {
    constructor() public {}

    function getStakingPower(
        address, /* _erc721 */
        uint256 /* _tokenId */
    ) external view override returns (uint256) {
        return 1;
    }
}