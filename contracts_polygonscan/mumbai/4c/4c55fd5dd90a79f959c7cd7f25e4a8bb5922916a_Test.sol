/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

pragma solidity 0.5.16;

contract Test {
    event Tested(uint256 indexed amount, uint256 time);
    uint256 public count;

    function Tets() public {
        count++;
        emit Tested(count, block.timestamp);
    }
}