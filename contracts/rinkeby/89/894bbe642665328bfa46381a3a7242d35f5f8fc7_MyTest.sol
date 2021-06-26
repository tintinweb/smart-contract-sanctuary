/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyTest {
    uint256 count;
    
    function getCount() public view returns(uint256){
        return count;
    }
    
    function setCount(uint256 _count) public {
        count = _count;
    }
}