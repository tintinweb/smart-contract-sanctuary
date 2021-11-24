// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./ChildERC20.sol";

/**
 * @title ChildMechanium - Official $MECHA child ERC20 for MechaChain play to earn project (https://mechachain.io/)
 * @notice The total amount of tokens across Ethereum and Polygon networks is 100 000 000 $MECHA
 * @author EthernalHorizons - <https://ethernalhorizons.com/> <[email protected]>
 */
contract ChildMechanium is ChildERC20 {

    /**
     * @dev Contract constructor
     * @param adminWallet address of the MechaChain admin wallet
     * @param childChainManager the ChildChainManagerProxy address that has the right to call the deposit function.
     */
    constructor(address adminWallet, address childChainManager) public 
        ChildERC20("Mechanium", "$MECHA", 18, childChainManager)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, adminWallet);
    }
}