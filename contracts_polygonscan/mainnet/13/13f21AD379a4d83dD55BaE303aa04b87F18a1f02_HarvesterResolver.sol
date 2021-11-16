// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IHarvester {
    function canHarvest(address vault) external view returns (bool);

    function harvest(address vault) external;
}

contract HarvesterResolver {
    IHarvester public immutable harvester;
    address[3] public vaults = [
        address(0xa571556C28a1197F93f5F1B3A6C0D5E5cA03E340),
        address(0xe1A33582592d43A9E9A5Ef0f78705103ae38228b),
        address(0x2B151f8dFc4270fDaC1a86b292be6f22D1184f11)
    ];

    constructor(address _harvester) {
        harvester = IHarvester(_harvester);
    }

    function checkCanHarvest()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        for (uint256 x; x < vaults.length; x++) {
            address vault = vaults[x];
            canExec = harvester.canHarvest(vault);
            execPayload = abi.encodeWithSelector(
                harvester.harvest.selector,
                vault
            );

            if (canExec) return (canExec, execPayload);
        }

        return (false, bytes("No vaults to harvest"));
    }
}