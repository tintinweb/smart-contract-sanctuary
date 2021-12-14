/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Delegator {
    function executeCall(address destination, bytes memory callData)
        external
        returns (bytes memory)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = destination.call(callData);
        require(success, "Delegator: call failed");
        return returnData;
    }

    function transferTokens(
        address tokenAddress,
        address tokenDestination,
        uint256 amount
    ) external returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                tokenDestination,
                amount
            )
        );
        require(success, "Delegator: call failed");
        return returnData;
    }
}