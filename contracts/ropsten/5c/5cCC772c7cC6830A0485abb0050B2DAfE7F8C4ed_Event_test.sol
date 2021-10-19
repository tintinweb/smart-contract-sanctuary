// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Event_test {

    uint256 currentBlockNumber;
    uint256 finalBlockNumber;


    function test(uint256 _finalBlockNumber) public returns(bool){
        currentBlockNumber = block.number;
        require(finalBlockNumber < currentBlockNumber);
        return true;
    }

    function hashTransaction(address sender, uint256 qty, string memory nonce,bytes[] memory byteArray) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(sender, qty, nonce , byteArray))
            )
        );
        return hash;
    }



}