/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract RandomFactory {
    function random(uint8 _action, uint256[] memory _data) public returns (uint256[] memory){
        uint256[] memory data = new uint256[](_data[0]);
        
        // Random _data[0] number from _data[1] to _data[2];
        if(_action == 0) {
            for(uint i=0; i<_data[0]; i++) {
                data[i] = uint256(keccak256(abi.encodePacked((i+block.timestamp + block.difficulty) + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (i+block.timestamp)) + (i+block.gaslimit) + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (i+block.timestamp)) + (i+block.number))));
                data[i] = data[i] - ((data[i] / _data[2]) * _data[2]);
            }
            return data;
        }
        else {
            revert("This action not available");
        }
    }
}