/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

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
pragma experimental ABIEncoderV2;

contract BatchExecutor {

    function execute(
        address[] calldata _targets,
        bytes[] calldata _data
    ) public {
        uint256 length = _targets.length;

        for (uint256 index = 0; index < length; ++index) {
            (bool success, bytes memory returnData) = _targets[index].call(_data[index]);

            require(success, string(returnData));
        }
    }

}