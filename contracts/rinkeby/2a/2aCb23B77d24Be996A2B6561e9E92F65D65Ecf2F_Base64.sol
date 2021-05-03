// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin public expiriment
// @dev see https://github.com/OpenZeppelin/solidity-jwt/blob/2a787f1c12c50da649eed1670b3a6d9c0221dd8e/contracts/Base64.sol for original
pragma solidity ^0.8.0;

library Base64 {

    bytes constant private BASE_64_URL_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

    function encode(uint256 bigint) external pure returns (string memory) {
        bytes32 buffer = bytes32(bigint);
        bytes memory res = new bytes(43);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= 32; i += 3) {
            (res[j], res[j+1], res[j+2], res[j+3]) = encode3(
                uint8(buffer[i]),
                uint8(buffer[i+1]),
                uint8(buffer[i+2])
            );

            j += 4;
        }
        (res[j], res[j+1], res[j+2], ) = encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
        return string(res);
    }

    function encode3(uint256 a0, uint256 a1, uint256 a2)
        private
        pure
        returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
    {

        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >>  6) & 63;
        uint256 c3 = (n      ) & 63;

        b0 = BASE_64_URL_CHARS[c0];
        b1 = BASE_64_URL_CHARS[c1];
        b2 = BASE_64_URL_CHARS[c2];
        b3 = BASE_64_URL_CHARS[c3];
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}