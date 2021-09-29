// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IProxyAdmin.sol";

/**
 * @title ChangeLogicAndCallSpell
 * @author Alexander Schlindwein
 *
 * Spell to change the logic of a proxy contract and call an initializer
 */
contract ChangeLogicAndCallSpell {

    /**
     * Changes the logic contract of a proxy contract
     *
     * @param proxyAdmin The address of the proxy admin contract
     * @param proxy The address of the proxy contract
     * @param newLogic The address of the new logic contract
     * @param data The calldata for the call
     */
    function execute(address proxyAdmin, address payable proxy, address newLogic, bytes calldata data) external {
        IProxyAdmin(proxyAdmin).upgradeAndCall(proxy, newLogic, data);
    }
}