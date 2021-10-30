/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ArrayTest {
    uint16[5] private items;
    uint16 public itemsLength = 5;
    
    event NumberChosen(uint16 number);
    
    function choose() public {
        uint16 index = genRandom();
        require(index < itemsLength, "Out of bounds");
        
        uint16 number = items[index];
        if(number == 0) {
            number = index;
        }
        uint16 lastNumber = items[itemsLength-1];
        if(lastNumber == 0) {
            lastNumber = itemsLength-1;
        }
        itemsLength = itemsLength - 1;
        items[index] = lastNumber;
        
        emit NumberChosen(number);
    }
    
    function getItem(uint16 index) public view returns (uint16) {
        require(index < itemsLength, "Out of bounds");
        
        if(items[index] == 0) {
            return index;
        }
        return items[index];
    }
    
    function genRandom() public view returns (uint16) {
        uint rand = uint(keccak256(abi.encodePacked(blockhash(block.number-1))));
        return uint16(rand % itemsLength);
    }
}