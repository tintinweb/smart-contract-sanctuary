/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IVault {

    function strategy() external view returns (address);
    
}

pragma solidity ^0.8.4;

contract BeefyStrategyMulticall {

    function getStrategy(address[] calldata vaults) external view returns (address[] memory) {
        address[] memory strategies = new address[](vaults.length);

        for (uint i = 0; i < vaults.length; i++) {
            strategies[i] = IVault(vaults[i]).strategy();
        }

        return strategies;
    }
}