/**
 *Submitted for verification at polygonscan.com on 2021-08-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

contract harvestKualaLumpurResolver {

    function harvest ()
        external
        pure
        returns (bool canExec, bytes memory execPayload)
    {
        //uint256 lastExecuted = ICounter(COUNTER).lastExecuted();

        canExec = true;//(block.timestamp - lastExecuted) > 180;

        bytes4 selector = bytes4(keccak256("deposit(uint256,uint256,address"));
        execPayload = abi.encodeWithSelector(
            selector,
            uint256(2),
            uint256(0),
            address(0)
        );
    }
}