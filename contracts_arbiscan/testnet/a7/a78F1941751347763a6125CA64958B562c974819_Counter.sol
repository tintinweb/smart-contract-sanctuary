/**
 *Submitted for verification at arbiscan.io on 2021-12-07
*/

pragma solidity ^0.5.17;

contract Counter {
    uint256 count;  // persistent contract storage

    constructor(uint256 _count) public {
        count = _count;
    }

    event Incremented(uint indexed _counterVal, uint indexed _blockNumber);

    function increment() public {
        count += 1;

        emit Incremented(count, block.number);
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function currentBlock() public view returns (uint256) {
        return block.number;
    }
}