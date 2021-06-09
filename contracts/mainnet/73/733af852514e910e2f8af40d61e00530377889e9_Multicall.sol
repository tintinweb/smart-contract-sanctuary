/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ReverseRegistrar {
    function setName(string memory name) external returns (bytes32);
}

function getBytes(uint gasLimit, uint sizeLimit, address addr, bytes memory data) view returns (uint status, bytes memory result) {
    assembly {
        // Allocate a new slot for the output
        result := mload(0x40)

        // Initialize the output as length 0 (in case things go wrong)
        mstore(result, 0)
        mstore(0x40, add(result, 32))

        // Call the target address with the data, limiting gas usage
        status := staticcall(gasLimit, addr, add(data, 32), mload(data), 0, 0)

        // If the result (return or revert) is a reasonable length...
        if lt(returndatasize(), sizeLimit) {

            // Allocate enough space to store the ceil_32(len_32(result) + result)
            mstore(0x40, add(result, and(add(add(returndatasize(), 0x20), 0x1f), not(0x1f))))

            // Place the length of the result value into the output
            mstore(result, returndatasize())

            // Copy the result value into the output
            returndatacopy(add(result, 32), 0, returndatasize())
        }
    }
}

contract Multicall {

    // Call this with the result of ens.owner(namehash("addr.reverse"))
    constructor(address reverseRegistrar) {

        // Make sure the reverse record is correct
        ReverseRegistrar(reverseRegistrar).setName("multicall.eth");
    }

    function execute(uint gasLimit, uint sizeLimit, address[] calldata addrs, bytes[] calldata datas) external view returns (uint blockNumber, uint[] memory statuses, bytes[] memory results) {
        require(addrs.length == datas.length);

        statuses = new uint256[](addrs.length);
        results = new bytes[](addrs.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            (statuses[i], results[i]) = getBytes(gasLimit, sizeLimit, addrs[i], datas[i]);
        }

        return (block.number, statuses, results);
    }
}