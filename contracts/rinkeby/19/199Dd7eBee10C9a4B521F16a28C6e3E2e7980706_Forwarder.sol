// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Forwarder {
    function checker(bytes memory execData)
        external
        view
        returns (bool, bytes memory)
    {
        return (true, execData);
    }
}

// solhint-disable no-empty-blocks
contract MultiPoker {
    function poke() external {
        // ......
    }
}

