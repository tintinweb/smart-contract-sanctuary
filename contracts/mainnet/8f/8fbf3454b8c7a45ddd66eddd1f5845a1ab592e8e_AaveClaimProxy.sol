/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;  

abstract contract IStakedTokenIncentivesController {
     function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external virtual returns (uint256);
}

contract AaveClaimProxy {
    
    address public constant STAKED_CONTROLLER_ADDR = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    
    function claimRewards(
        address[] memory assets,
    uint256 amount,
    address to
    ) public {
        IStakedTokenIncentivesController(STAKED_CONTROLLER_ADDR).claimRewards(
            assets,
            amount,
            to
            );
    }
}