/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.5.0;

contract Arrays {
    
    function getArraySum(uint[] memory _array) 
        public 
        pure 
        returns (uint sum_) 
    {
        sum_ = 0;
        for (uint i = 0; i < _array.length; i++) {
            sum_ += _array[i];
        }
    }
}