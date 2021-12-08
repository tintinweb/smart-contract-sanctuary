/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/rewardvault.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

////// src/rewardvault.sol
/* pragma solidity >=0.7.6; */

interface ERC20Like {
    function approve(address usr, uint256 wad) external returns (bool);
}

contract RwaMarketRewardVault {

    address constant public wcfg = 0xc221b7E65FfC80DE234bbB6667aBDd46593D34F0;

    event Initialized(address indexed incentivesController);

    constructor(address incentivesController) {
        ERC20Like(wcfg).approve(incentivesController, type(uint256).max);
        emit Initialized(incentivesController);
    }

}