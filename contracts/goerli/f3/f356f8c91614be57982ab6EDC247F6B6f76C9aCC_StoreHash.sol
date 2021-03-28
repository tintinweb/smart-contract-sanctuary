/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StoreHash {

    uint16 count = 0;
    uint256 hashsum;
    
    event NewHash(uint256 number); 

    function Store(uint256 _number) public {
        hashsum = _number;
        count++;
        emit NewHash(_number);
    }
    
    function getCount() public view returns (uint16){
        return count;
    }
    
    function getHash() public view returns (uint256){
        return hashsum;
    }
}