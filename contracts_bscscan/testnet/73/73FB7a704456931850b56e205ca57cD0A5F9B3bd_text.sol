/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

pragma solidity ^0.6.0;

contract text {
    uint count;

    function getcount() public view returns(uint) {
        return count + 1;
    }
}