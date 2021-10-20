// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

contract SupportReward {
    
    struct Balance {
        address recipient;
        uint256 value;
    }

    function generateMessageToSign(Balance memory _balances) public pure returns (string memory) {
        return prepareMessage(_balances);
    }
    
    function prepareMessage(Balance memory _balances) internal pure returns (string memory) {
        return toString(keccak256(abi.encode(_balances)));
    }
    
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}