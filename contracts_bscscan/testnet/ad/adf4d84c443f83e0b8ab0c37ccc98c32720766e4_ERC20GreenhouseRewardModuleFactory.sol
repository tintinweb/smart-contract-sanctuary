/*
ERC20GreenhouseRewardModuleFactory

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./IModuleFactory.sol";
import "./ERC20GreenhouseRewardModule.sol";

/**
 * @title ERC20 Greenhouse reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20GreenhouseRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20GreenhouseRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(bytes calldata data)
        external
        override
        returns (address)
    {
        // validate
        require(data.length == 96, "frmf1");

        // parse constructor arguments
        address token;
        uint256 penaltyStart;
        uint256 penaltyPeriod;
        assembly {
            token := calldataload(68)
            penaltyStart := calldataload(100)
            penaltyPeriod := calldataload(132)
        }

        // create module
        ERC20GreenhouseRewardModule module =
            new ERC20GreenhouseRewardModule(
                token,
                penaltyStart,
                penaltyPeriod,
                address(this)
            );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}