/**
 *Submitted for verification at snowtrace.io on 2021-12-22
*/

pragma solidity ^0.8.0;

interface IRebase{
    function rebase() external;
    function epoch() external view returns(
        uint number,
        uint distribute,
        uint32 length,
        uint32 endTime);
}

contract AAHIMREBASING{
    address public staking = 0x743DE042c7be8C415effa75b960A2A7bB5fc0704;

    function rebase() external{
        (,,, uint32 endTime) = epoch();
        while(endTime < block.timestamp){
            IRebase(staking).rebase();
            (,,, endTime) = epoch();
        }
    }

    function epoch() public view returns(
        uint number,
        uint distribute,
        uint32 length,
        uint32 endTime){
            return IRebase(staking).epoch();
    }
}