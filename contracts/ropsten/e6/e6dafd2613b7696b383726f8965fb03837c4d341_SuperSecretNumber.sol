/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SuperSecretNumber {
    bytes32 answerHash = 0xf0d642dbc7517672e217238a2f008f4f8cdad0586d8ce5113e9e09dcc6860619;    // Super secret hash

    constructor() payable {
        require(msg.value == 1 ether);
    }
    
    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);

        if (keccak256(abi.encode(n)) == answerHash) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}