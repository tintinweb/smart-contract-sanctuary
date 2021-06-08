/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

function getBytes(uint gasLimit, uint sizeLimit, address addr, bytes memory data) view returns (uint status, bytes memory result) {
    assembly {
        result := mload(0x40)

        // Initialize as length 0 (in case things go wrong)
        mstore(result, 0)
        mstore(0x40, add(result, 32))

        // Call the target with the data
        status := staticcall(gasLimit, addr, add(data, 32), mload(data), 0, 0)

        // Success!
        if eq(status, 1) {

            // And is a reasonable length
            if lt(returndatasize(), sizeLimit) {

                // Allocate enough space to store the length of the result and the result
                let payloadSize := add(32, returndatasize())
                mstore(0x40, add(result, and(add(add(payloadSize, 0x20), 0x1f), not(0x1f))))

                // Place the length of the returned value in the result
                mstore(result, returndatasize())

                // Copy the returned value to the result
                returndatacopy(add(result, 32), 0, returndatasize())
            }
        }
    }
}

contract Multicall {
    function execute(uint gasLimit, uint sizeLimit, address[] calldata addrs, bytes[] calldata datas) external view returns (uint, uint[] memory, bytes[] memory) {
        require(addrs.length == datas.length);

        uint256[] memory statuses = new uint256[](addrs.length);
        bytes[] memory results = new bytes[](addrs.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            (statuses[i], results[i]) = getBytes(gasLimit, sizeLimit, addrs[i], datas[i]);
        }

        return (block.number, statuses, results);
    }
}