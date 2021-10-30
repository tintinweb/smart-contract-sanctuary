/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ArrayTest {
    uint16 private MAX_SUSHIMIS = 10000;
    
    uint16[10000] private remainingIDs;
    uint16 public remainingIDsLength = 10000;
    
    event NumberGenerated(uint16 number);
    
    function _getRandomID() private returns (uint16 number) {
        uint16 index = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-1)))) % remainingIDsLength);
        require(index < remainingIDsLength, "Out of bounds");
        
        number = remainingIDs[index];
        if(number == 0) {
            number = index;
        }
        uint16 lastNumber = remainingIDs[remainingIDsLength-1];
        if(lastNumber == 0) {
            lastNumber = remainingIDsLength-1;
        }
        remainingIDs[index] = lastNumber;
        remainingIDsLength = remainingIDsLength - 1;
    }
    
    function choose() public returns (uint16) {
        _getRandomID();
        _getRandomID();
    }
}