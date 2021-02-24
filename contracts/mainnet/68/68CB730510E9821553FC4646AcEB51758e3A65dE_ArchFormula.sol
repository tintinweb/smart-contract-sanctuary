// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../lib/VotingPowerFormula.sol";

/**
 * @title ArchFormula
 * @dev Convert ARCH to voting power
 */
contract ArchFormula is VotingPowerFormula {
    /**
     * @notice Convert ARCH amount to voting power
     * @dev Always converts 1-1
     * @param amount token amount
     * @return voting power amount
     */
    function convertTokensToVotingPower(uint256 amount) external pure override returns (uint256) {
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract VotingPowerFormula {
   function convertTokensToVotingPower(uint256 amount) external view virtual returns (uint256);
}