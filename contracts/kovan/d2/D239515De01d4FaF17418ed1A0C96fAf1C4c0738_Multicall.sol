pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

// Kalancer Multicall contract
contract Multicall {
    // Assembly call to contract
    // More precise and parse from bytes / string
    function getBalance(address addr, bytes memory data)
        internal
        view
        returns (uint256 result)
    {
        result = 0;

        assembly {
            let callSuccess := staticcall(
                15000,
                addr,
                add(data, 32),
                mload(data),
                0,
                0
            )

            if eq(callSuccess, 1) {
                if eq(returndatasize(), 32) {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
            }
        }
    }

    /**
     * @notice Get pools info from Pool contract
     * @return Returns the array amount come from contract
     * @param pools Pools array. Format: [[Pool1, token1, token2], [Pool2, token1, token3]]
     * @param length Length of all element in array. Length must greater than number of tokens
     */
    function getPoolInfo(address[][] calldata pools, uint256 length)
        external
        view
        returns (uint256[] memory)
    {
        // Create array of result that return from contract
        uint256[] memory results = new uint256[](length);

        // Create count for iterate
        uint256 count = 0;
        // Loop from pools array
        for (uint256 i = 0; i < pools.length; i++) {
            // Pool address is the first element in nested array
            address poolAddr = pools[i][0];
            // Loop from all tokens and get balannce
            for (uint256 j = 1; j < pools[i].length; j++) {
                // Get tokens address from nested array
                address tokenAddr = pools[i][j];
                // The result come from assembly function
                results[count] = getBalance(
                    poolAddr,
                    abi.encodeWithSignature("getBalance(address)", tokenAddr)
                );
                // Increase count for next run
                count++;
            }
        }
        // Return the result
        return results;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}