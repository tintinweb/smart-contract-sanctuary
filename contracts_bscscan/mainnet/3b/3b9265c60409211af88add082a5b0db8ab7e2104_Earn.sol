/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IVault {
    function earn() external;
}

interface ISweetVault {
    function earn(uint256, uint256, uint256, uint256) external;
}

contract Earn {

    function earn(
        address[] calldata _legacyVaults,
        address[] calldata _sweetVaults,
        uint256[] calldata _minPlatformOutputs,
        uint256[] calldata _minKeeperOutputs,
        uint256[] calldata _minBurnOutputs,
        uint256[] calldata _minPacocaOutputs
    ) public {
        uint256 legacyLength = _legacyVaults.length;

        for (uint256 index = 0; index < legacyLength; ++index) {
            IVault(_legacyVaults[index]).earn();
        }

        uint256 sweetLength = _sweetVaults.length;

        for (uint256 index = 0; index < sweetLength; ++index) {
            ISweetVault(_sweetVaults[index]).earn(
                _minPlatformOutputs[index],
                _minKeeperOutputs[index],
                _minBurnOutputs[index],
                _minPacocaOutputs[index]
            );
        }
    }

}