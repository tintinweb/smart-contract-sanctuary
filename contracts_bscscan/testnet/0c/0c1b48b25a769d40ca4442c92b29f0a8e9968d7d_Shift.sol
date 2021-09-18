/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

pragma solidity =0.8.0;

contract Shift {
    function shift(uint number) external view returns(uint) {
        return number >> 128;
    }
}