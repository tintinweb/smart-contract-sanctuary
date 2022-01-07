/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRebase{
    function epoch() external view returns(
        uint number,
        uint distribute,
        uint32 length,
        uint32 endTime);
}

contract Checker{
        address public staking = 0x743DE042c7be8C415effa75b960A2A7bB5fc0704;

        function available() public view returns (bool){
            (,,uint32 length,uint32 endTime) = IRebase(staking).epoch();
            return (endTime + length > block.timestamp);
        }
}