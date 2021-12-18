/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: Unlincesed
pragma solidity ^ 0.8.7;

contract Keccak {
    bytes32 hashed = keccak256("[email protected]");
    bytes32 nn;

    modifier onlyHahsed(string memory key){
        require(hashed == keccak256(bytes(key)), "Wrong key!");
        _;
    }

    function withdraw(string memory key) onlyHahsed(key) public view returns (bytes32){
        return keccak256(bytes(key));
    }

    function isKeyCorrect(string memory key) public returns(bool){
        nn = keccak256(bytes(key));
        return (hashed == keccak256(bytes(key)));
    }
}