/*
ERC20GardenRewardModuleFactory

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./IModuleFactory.sol";
import "./ERC20GardenRewardModule.sol";

/**
 * @title ERC20 Garden reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20GardenRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20GardenRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(bytes calldata data)
        external
        override
        returns (address)
    {
        // validate
        require(data.length == 128, "crmf1");

        // parse constructor arguments
        address token;
        uint256 bonusMin;
        uint256 bonusMax;
        uint256 bonusPeriod;
        assembly {
            token := calldataload(68)
            bonusMin := calldataload(100)
            bonusMax := calldataload(132)
            bonusPeriod := calldataload(164)
        }

        // create module
        ERC20GardenRewardModule module =
            new ERC20GardenRewardModule(
                token,
                bonusMin,
                bonusMax,
                bonusPeriod,
                address(this)
            );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}