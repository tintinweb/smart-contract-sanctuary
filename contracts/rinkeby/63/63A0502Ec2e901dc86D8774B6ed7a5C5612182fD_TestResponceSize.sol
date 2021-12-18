//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestResponceSize {
    function generateByte32Array(uint256 size) public view returns(bytes32[] memory arr){
        arr = new bytes32[](size);
        for(uint256 i=0; i<size; i++){
            arr[i] = keccak256(abi.encodePacked(msg.sender, i));
        }
    }

}