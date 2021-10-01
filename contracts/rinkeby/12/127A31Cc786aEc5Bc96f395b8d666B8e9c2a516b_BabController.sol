/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.6;

/**
 * @title Do nothing
 * @dev Snippet used to fill governance empty proposals
 */
contract BabController {
    bool public activated;
    
    modifier onlyTimelockController {
        require(msg.sender == 0x6e0Fd8E8202e6a68e7ca9295b691bdd6df2dCb38);
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
    }


    function enableBABLMiningProgram() external onlyTimelockController {
        activated = true;
    }

}