// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IDSPause.sol";

/**
 * @title ChangeTimelockOwnerSpell
 * @author Alexander Schlindwein
 *
 * Spell to change the owner of the DSPause timelock
 */
contract ChangeTimelockOwnerSpell {

    /**
     * Changes the owner of the DSPause timelock
     *
     * @param dsPause The address of the DSPause contract
     * @param newOwner The new owner of the timelock
     */
    function execute(address dsPause, address newOwner) external {
        IDSPause(dsPause).setOwner(newOwner);
    }
}