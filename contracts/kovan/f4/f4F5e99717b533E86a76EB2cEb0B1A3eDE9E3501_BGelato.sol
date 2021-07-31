/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface KeeperLike {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeepSafe(bytes calldata performData) external;
    function performUpkeep(bytes calldata performData) external;    
}

contract BGelato {
    KeeperLike immutable public proxy;

    constructor(KeeperLike _proxy) public {
        proxy = _proxy;
    }

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        (bool upkeepNeeded, bytes memory performData) = proxy.checkUpkeep(bytes(""));
        canExec = upkeepNeeded;

        execPayload = abi.encodeWithSelector(
            BGelato.doer.selector,
            performData
        );
    }

    function doer(bytes calldata performData) external {
        proxy.performUpkeepSafe(performData);
    }

    function test(bytes calldata input) external {
        address(this).call(input);
    }
}