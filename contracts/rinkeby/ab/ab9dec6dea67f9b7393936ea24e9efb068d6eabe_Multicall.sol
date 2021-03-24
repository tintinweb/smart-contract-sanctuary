/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity 0.5.12;

pragma experimental ABIEncoderV2;

contract Multicall {
    // Assembly call to contract
    //
    function getBalance(address addr, bytes memory data)
        internal
        view
        returns (uint256 result)
    {
        result = 0;

        assembly {
            let callSuccess := staticcall(
                7500,
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

    function getPoolInfo(address[][] calldata pools, uint256 length)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory results = new uint256[](length);
        uint256 count = 0;

        for (uint256 i = 0; i < pools.length; i++) {
            address poolAddr = pools[i][0];
            for (uint256 j = 1; j < pools[i].length; j++) {
                address tokenAddr = pools[i][j];
                results[count] = getBalance(
                    poolAddr,
                    abi.encodeWithSignature("getBalance(address)", tokenAddr)
                );
                
                count++;
            }
        }

        return results;
    }
}