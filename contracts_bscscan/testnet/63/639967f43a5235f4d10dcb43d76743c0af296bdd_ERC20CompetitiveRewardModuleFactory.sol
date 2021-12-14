/*
ERC20CompetitiveRewardModuleFactory

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./IModuleFactory.sol";
import "./ERC20CompetitiveRewardModule.sol";

/**
 * @title ERC20 competitive reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20CompetitiveRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20CompetitiveRewardModuleFactory is IModuleFactory {
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
        address token = 0x48A397a03728F61aABcA00E74b42E5c746a89d8d;
        uint256 bonusMin = 1;
        uint256 bonusMax = 10;
        uint256 bonusPeriod = 5;
        // assembly {
        //     token := calldataload(0)
        //     bonusMin := calldataload(1)
        //     bonusMax := calldataload(2)
        //     bonusPeriod := calldataload(3)
        // }

        // create module
        ERC20CompetitiveRewardModule module =
            new ERC20CompetitiveRewardModule(
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