// SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

import './IGetStakingPower.sol';

contract DefaultGetStakingPower is IGetStakingPower {
    constructor() public {}

    function getStakingPower(
        address, /* _erc721 */
        uint256 /* _tokenId */
    ) external view override returns (uint256) {
        return 1E2;
    }
}