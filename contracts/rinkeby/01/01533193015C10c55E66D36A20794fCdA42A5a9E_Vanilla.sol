// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract Vanilla {
    
    
    /**
     * DIIMIIM: FOR TESTING PURPOSE ONLY !!!
     */
    function getRandomNumber(bytes memory input) external view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, input)));
    }


}