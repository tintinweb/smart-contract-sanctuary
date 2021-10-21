/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ItemsCounter{
    uint8 itemsCount;
    uint8 maxCount = 100;
    event ItemsCounterChanged(uint8 _count);
    
    function addItem() public{
        require(itemsCount<maxCount,'Item counter is full');
        itemsCount+=1;
        emit ItemsCounterChanged(itemsCount);
    }
    
    function removeItem()public{
        require(itemsCount>0,'Total items is 0');
        itemsCount-=1;
        emit ItemsCounterChanged(itemsCount);
    }
}