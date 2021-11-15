// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Kek {
    function kek(string memory txretard) external pure returns(bytes32) {
        return keccak256(abi.encode(txretard));
    }
}

